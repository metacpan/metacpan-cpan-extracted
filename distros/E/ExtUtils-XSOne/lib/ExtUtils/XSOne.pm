package ExtUtils::XSOne;

use 5.008003;
use strict;
use warnings;

use File::Spec;
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use File::Find qw(find);
use Carp qw(croak);

our $VERSION = '0.03';

sub combine {
    my ($class, %opts) = @_;

    my $src_dir   = $opts{src_dir} or croak "src_dir is required";
    my $output    = $opts{output}  or croak "output is required";
    my $order     = $opts{order};
    my $verbose   = $opts{verbose} || 0;
    my $dedup     = exists $opts{deduplicate} ? $opts{deduplicate} : 1;
    my $recursive = $opts{recursive} || 0;

    my @sorted;
    if ($recursive) {
        @sorted = $class->_find_xs_files_recursive($src_dir);
    } else {
        my @xs_files = $class->_find_xs_files($src_dir);
        @sorted = $class->_sort_files(\@xs_files, $order);
    }

    if ($verbose) {
        warn "ExtUtils::XSOne: Processing files in order:\n";
        warn "  $_\n" for @sorted;
    }

    # Read all files and extract/deduplicate C preamble
    my @file_contents;
    my %seen_includes;
    my %seen_defines;
    my @collected_includes;
    my @collected_defines;
    my @collected_c_code;
    my @header_c_code;  # C code from _header.xs files (processed first)

    for my $file (@sorted) {
        # In recursive mode, $file is already a relative path from src_dir
        # In non-recursive mode, $file is just the filename
        my $path = File::Spec->catfile($src_dir, $file);
        my $display_file = $recursive ? $file : basename($file);
        warn "ExtUtils::XSOne: Reading $path\n" if $verbose;

        my $content = $class->_read_file($path);
        my $filename = basename($file);
        my $is_header = ($filename eq '_header.xs');

        if ($dedup) {
            # Parse and extract C preamble (before MODULE =)
            my ($preamble, $xs_part) = $class->_split_preamble($content);

            # For _header.xs files without MODULE, the entire content is in xs_part
            # We need to treat it as preamble C code
            my $c_content = $preamble;
            if ($is_header && $preamble eq '' && $xs_part =~ /\S/) {
                $c_content = $xs_part;
                $xs_part = '';
            }

            # Extract includes, defines, and other C code from preamble
            my ($includes, $defines, $other_c) = $class->_parse_preamble($c_content);

            # Deduplicate includes
            for my $inc (@$includes) {
                my $normalized = $class->_normalize_include($inc);
                unless ($seen_includes{$normalized}++) {
                    push @collected_includes, $inc;
                }
            }

            # Deduplicate defines (by macro name)
            for my $def (@$defines) {
                my $name = $class->_extract_define_name($def);
                unless ($seen_defines{$name}++) {
                    push @collected_defines, $def;
                }
            }

            # Collect other C code (functions, structs, etc.)
            # _header.xs code goes first to ensure definitions are available
            if ($other_c =~ /\S/) {
                if ($is_header) {
                    push @header_c_code, { file => $file, path => $path, code => $other_c };
                } else {
                    push @collected_c_code, { file => $file, path => $path, code => $other_c };
                }
            }

            # Store just the XS part (empty for pure _header.xs files)
            push @file_contents, { file => $file, path => $path, content => $xs_part }
                if $xs_part =~ /\S/;
        } else {
            push @file_contents, { file => $file, path => $path, content => $content };
        }
    }

    # Merge header C code first, then other C code
    @collected_c_code = (@header_c_code, @collected_c_code);

    # Build combined content
    my $combined = $class->_build_header($src_dir, \@sorted);

    if ($dedup && (@collected_includes || @collected_defines || @collected_c_code)) {
        # Add deduplicated preamble
        $combined .= "/* ========== COMBINED C PREAMBLE ========== */\n\n";

        # Includes first
        if (@collected_includes) {
            $combined .= join("\n", @collected_includes) . "\n\n";
        }

        # Then defines
        if (@collected_defines) {
            $combined .= join("\n", @collected_defines) . "\n\n";
        }

        # Then other C code with source markers
        for my $c_block (@collected_c_code) {
            $combined .= "/* C code from: $c_block->{file} */\n";
            $combined .= "#line 1 \"$c_block->{path}\"\n";
            $combined .= $c_block->{code} . "\n";
        }

        $combined .= "/* ========== END COMBINED C PREAMBLE ========== */\n";
    }

    # Add XS parts
    for my $fc (@file_contents) {
        $combined .= $class->_wrap_file($fc->{file}, $fc->{path}, $fc->{content});
    }

    # Write output
    $class->_write_file($output, $combined, $verbose);

    warn "ExtUtils::XSOne: Generated $output from " . scalar(@sorted) . " files\n"
        if $verbose;

    return scalar(@sorted);
}

sub files_in_order {
    my ($class, $src_dir, $order) = @_;

    my @xs_files = $class->_find_xs_files($src_dir);
    return $class->_sort_files(\@xs_files, $order);
}

#
# Internal methods
#

sub _find_xs_files {
    my ($class, $src_dir) = @_;

    croak "Source directory '$src_dir' does not exist" unless -d $src_dir;

    opendir(my $dh, $src_dir) or croak "Cannot open $src_dir: $!";
    my @xs_files = grep { /\.xs$/ } readdir($dh);
    closedir($dh);

    croak "No .xs files found in $src_dir" unless @xs_files;

    return @xs_files;
}

sub _find_xs_files_recursive {
    my ($class, $src_dir) = @_;

    croak "Source directory '$src_dir' does not exist" unless -d $src_dir;

    my @headers;   # { path => relative_path, depth => N }
    my @footers;   # { path => relative_path, depth => N }
    my @packages;  # relative paths to package XS files

    # Normalize src_dir for consistent path handling
    $src_dir = File::Spec->canonpath($src_dir);
    my $src_dir_len = length($src_dir);

    find({
        wanted => sub {
            return unless -f && /\.xs$/;

            my $full_path = $File::Find::name;
            my $dir = $File::Find::dir;

            # Get path relative to src_dir
            my $rel_path = substr($full_path, $src_dir_len);
            $rel_path =~ s{^[/\\]}{};  # Remove leading separator

            # Calculate depth (number of directory separators)
            my $depth = ($rel_path =~ tr!/\\!!);

            my $filename = basename($full_path);

            if ($filename eq '_header.xs') {
                push @headers, { path => $rel_path, depth => $depth };
            } elsif ($filename eq '_footer.xs') {
                push @footers, { path => $rel_path, depth => $depth };
            } else {
                push @packages, $rel_path;
            }
        },
        no_chdir => 1,
    }, $src_dir);

    croak "No .xs files found in $src_dir" unless @headers || @footers || @packages;

    # Sort headers by depth (shallow first), then alphabetically
    @headers = map { $_->{path} }
               sort { $a->{depth} <=> $b->{depth} || $a->{path} cmp $b->{path} }
               @headers;

    # Sort footers by depth (deep first - reverse of headers), then alphabetically
    @footers = map { $_->{path} }
               sort { $b->{depth} <=> $a->{depth} || $a->{path} cmp $b->{path} }
               @footers;

    # Sort package files alphabetically
    @packages = sort @packages;

    return (@headers, @packages, @footers);
}

sub _sort_files {
    my ($class, $files, $order) = @_;

    if ($order && @$order) {
        # Use explicit order
        my %available = map { $_ => 1 } @$files;
        my @sorted;

        for my $name (@$order) {
            my $file = "$name.xs";
            if ($available{$file}) {
                push @sorted, $file;
                delete $available{$file};
            }
        }

        # Append any remaining files
        push @sorted, sort keys %available;
        return @sorted;
    }

    # Default ordering: _header first, _footer last, others alphabetically
    my @header = grep { /^_header\.xs$/ } @$files;
    my @footer = grep { /^_footer\.xs$/ } @$files;
    my @middle = sort grep { !/^_/ } @$files;
    my @other_underscore = sort grep { /^_/ && !/^_(header|footer)\.xs$/ } @$files;

    return (@header, @middle, @other_underscore, @footer);
}

sub _split_preamble {
    my ($class, $content) = @_;

    # Find the first MODULE = declaration
    if ($content =~ /^(.*?)(^MODULE\s*=\s*.+)$/ms) {
        return ($1, $2);
    }

    # No MODULE found - entire content is C preamble (e.g., _header.xs)
    return ('', $content);
}

sub _parse_preamble {
    my ($class, $preamble) = @_;

    my @includes;
    my @defines;
    my @other_lines;

    for my $line (split /\n/, $preamble) {
        if ($line =~ /^\s*#\s*include\s/) {
            push @includes, $line;
        } elsif ($line =~ /^\s*#\s*define\s/) {
            push @defines, $line;
        } else {
            push @other_lines, $line;
        }
    }

    my $other_c = join("\n", @other_lines);

    # Remove leading/trailing whitespace
    $other_c =~ s/^\s+//;
    $other_c =~ s/\s+$//;

    return (\@includes, \@defines, $other_c);
}

sub _normalize_include {
    my ($class, $include) = @_;

    # Extract the actual include path/name
    if ($include =~ /#\s*include\s*[<"]([^>"]+)[>"]/) {
        return $1;
    }
    return $include;
}

sub _extract_define_name {
    my ($class, $define) = @_;

    if ($define =~ /#\s*define\s+(\w+)/) {
        return $1;
    }
    return $define;
}

sub _build_header {
    my ($class, $src_dir, $files) = @_;

    my $header = <<"HEADER";
/*
 * THIS FILE IS AUTO-GENERATED BY ExtUtils::XSOne
 * DO NOT EDIT DIRECTLY - edit files in $src_dir/ instead
 *
 * Generated from:
HEADER

    $header .= " *   $_\n" for @$files;
    $header .= " */\n\n";

    return $header;
}

# Note: xsubpp cannot handle comments or #line directives between MODULE
# declarations - they cause parsing errors. We only add markers for pure
# C code sections (like _header.xs without MODULE), not for XS sections.
sub _wrap_file {
    my ($class, $file, $path, $content) = @_;

    my $wrapped = "\n";

    # Check if content starts with MODULE declaration (XS code)
    if ($content =~ /^\s*MODULE\s*=/m) {
        # For XS content, don't add any comments or #line directives
        # xsubpp can't handle them between MODULE sections
        $wrapped .= $content;
    } else {
        # For non-MODULE content (like _header.xs or pure C preamble),
        # add a marker comment and #line directive for debugging
        $wrapped .= "/* ========== BEGIN: $file ========== */\n";
        $wrapped .= "#line 1 \"$path\"\n";
        $wrapped .= $content;
    }

    $wrapped .= "\n";

    return $wrapped;
}

sub _read_file {
    my ($class, $path) = @_;

    open(my $fh, '<', $path) or croak "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close($fh);

    return $content;
}

sub _write_file {
    my ($class, $path, $content, $verbose) = @_;

    # Create directory if needed
    my $dir = dirname($path);
    if ($dir && $dir ne '.' && !-d $dir) {
        make_path($dir);  # throws on failure
    }

    warn "ExtUtils::XSOne: Writing $path\n" if $verbose;

    open(my $fh, '>', $path) or croak "Cannot write $path: $!";
    print $fh $content;
    close($fh);
}

1;

__END__

=head1 NAME

ExtUtils::XSOne - Combine multiple XS files into a single shared library

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    # In Makefile.PL
    use ExtUtils::MakeMaker;
    use ExtUtils::XSOne;

    # Combine XS files before WriteMakefile
    ExtUtils::XSOne->combine(
        src_dir => 'lib/MyModule/xs',
        output  => 'MyModule.xs',
    );

    WriteMakefile(
        NAME => 'MyModule',
        # ... other options
    );

Or use the command-line tool:

    xsone --src lib/MyModule/xs --out lib/MyModule.xs

=head1 DESCRIPTION

C<ExtUtils::XSOne> solves a limitation of Perl's XSMULTI feature:
when using C<XSMULTI =E<gt> 1> in ExtUtils::MakeMaker, each C<.xs> file compiles
into a separate shared library (C<.so>/C<.bundle>/C<.dll>), which means they
cannot share C static variables, registries, or internal state.

This module allows you to organize your XS code into multiple files for
maintainability while still producing a single shared library that can
share all C-level state.

=head2 The Problem

With XSMULTI, this structure:

    lib/
    ├── Foo.xs           → blib/arch/auto/Foo/Foo.bundle
    └── Foo/
        └── Bar.xs       → blib/arch/auto/Foo/Bar/Bar.bundle

Creates two separate shared libraries. If C<Foo.xs> has:

    static int my_registry[100];

Then C<Foo/Bar.xs> cannot access C<my_registry> - each bundle has its own
copy of static variables.

=head2 The Solution

With ExtUtils::XSOne, you can organize code in two ways:

B<Traditional layout> - all XS in a single C<xs/> subdirectory:

    lib/
    └── Foo/
        └── xs/
            ├── _header.xs    # Common includes, types, static vars
            ├── context.xs    # MODULE = Foo PACKAGE = Foo::Context
            ├── tensor.xs     # MODULE = Foo PACKAGE = Foo::Tensor
            └── _footer.xs    # BOOT section

B<Hierarchical layout> - XS files alongside their C<.pm> files:

    lib/
    └── Foo/
        ├── _header.xs        # Common includes, types, static vars
        ├── _footer.xs        # BOOT section
        ├── Context.pm
        ├── Context.xs        # MODULE = Foo PACKAGE = Foo::Context
        ├── Tensor.pm
        └── Tensor.xs         # MODULE = Foo PACKAGE = Foo::Tensor

Both are combined at build time into a single C<Foo.xs>, which compiles
to one shared library where all modules share the same C state.

=head1 FILE NAMING CONVENTION

Files in the source directory are processed in this order:

=over 4

=item 1. C<_header.xs> - Always first (if present)

Contains C<#include> directives, type definitions, static variables,
and helper functions shared by all modules.

=item 2. Other C<.xs> files - Alphabetically sorted

Each file typically contains one C<MODULE = ... PACKAGE = ...> section
with XS function definitions.

=item 3. C<_footer.xs> - Always last (if present)

Contains the C<BOOT:> section and any final initialization code.

=back

Files starting with C<_> (other than C<_header.xs> and C<_footer.xs>) are
processed after regular files but before C<_footer.xs>.

=head1 METHODS

=head2 combine

    ExtUtils::XSOne->combine(
        src_dir => 'lib/MyModule/xs',
        output  => 'lib/MyModule.xs',
        order   => [qw(_header context tensor model _footer)],  # optional
        verbose => 1,                                            # optional
    );

Or with recursive mode for hierarchical layouts:

    ExtUtils::XSOne->combine(
        src_dir   => 'lib/MyModule',
        output    => 'MyModule.xs',
        recursive => 1,
        verbose   => 1,
    );

Combines multiple XS files into a single output file.

B<Options:>

=over 4

=item C<src_dir> (required)

Directory containing the source C<.xs> files. In recursive mode, this is
the base directory to scan recursively.

=item C<output> (required)

Path to the output combined C<.xs> file.

=item C<recursive> (optional, default: false)

If true, recursively scans subdirectories for C<.xs> files. This allows
XS files to be placed alongside their corresponding C<.pm> files rather
than in a single C<xs/> subdirectory.

In recursive mode:

=over 4

=item * C<_header.xs> files are processed first, ordered by directory depth
(shallowest first)

=item * Package C<.xs> files are then processed alphabetically by full path

=item * C<_footer.xs> files are processed last, ordered by directory depth
(deepest first, reverse of headers)

=back

This enables hierarchical layouts like:

    lib/
    └── MyModule/
        ├── _header.xs          # Top-level shared state
        ├── Context.pm
        ├── Context.xs          # Context package
        ├── Tensor.pm
        ├── Tensor.xs           # Tensor package
        └── _footer.xs          # BOOT section

=item C<order> (optional, ignored in recursive mode)

Array reference specifying the order of files (without C<.xs> extension).
If not provided, files are sorted alphabetically with C<_header> first
and C<_footer> last.

=item C<verbose> (optional)

If true, prints progress messages to STDERR.

=item C<deduplicate> (optional, default: true)

If true (the default), automatically deduplicates C<#include> and C<#define>
directives across all files. This allows each XS file to have its own
includes for standalone development while producing a clean combined file.

The deduplication process:

=over 4

=item 1. Extracts all C<#include> and C<#define> directives from the C preamble
(code before the first C<MODULE => declaration)

=item 2. Removes duplicate includes (based on the included file path)

=item 3. Removes duplicate defines (based on the macro name)

=item 4. Collects remaining C code (structs, functions, etc.) with source markers

=item 5. B<C code from C<_header.xs> is placed first> in the combined preamble,
ensuring that types, macros, and static variables defined in the header are
available to C code in other XS files

=item 6. Outputs the deduplicated preamble followed by the XS sections

=back

This ordering is important: helper functions in package XS files (e.g.,
C<Memory.xs>) can access definitions from C<_header.xs> because the header's
C code appears first in the combined output.

Set to false to disable deduplication and combine files verbatim.

=back

Returns the number of files combined.

=head2 files_in_order

    my @files = ExtUtils::XSOne->files_in_order($src_dir);
    my @files = ExtUtils::XSOne->files_in_order($src_dir, \@order);

Returns the list of C<.xs> files in the order they would be combined.
Useful for debugging or generating dependency lists.

=head1 INTEGRATION WITH EXTUTILS::MAKEMAKER

For seamless integration, add a C<MY::postamble> section to regenerate
the combined XS file when source files change:

    # In Makefile.PL
    use ExtUtils::MakeMaker;
    use ExtUtils::XSOne;

    # Generate initially
    ExtUtils::XSOne->combine(
        src_dir => 'lib/MyModule/xs',
        output  => 'MyModule.xs',
    );

    WriteMakefile(
        NAME => 'MyModule',
        # ...
    );

    sub MY::postamble {
        my @src_files = ExtUtils::XSOne->files_in_order('lib/MyModule/xs');
        my $deps = join(' ', map { "lib/MyModule/xs/$_" } @src_files);

        return <<"MAKE_FRAG";
    lib/MyModule.xs : $deps
    \t\$(PERLRUN) -MExtUtils::XSOne -e 'ExtUtils::XSOne->combine(src_dir => "lib/MyModule/xs", output => "lib/MyModule.xs")'
    MAKE_FRAG
    }

=head1 EXAMPLE DIRECTORY STRUCTURES

=head2 Traditional Layout (non-recursive)

All XS files in a single C<xs/> subdirectory:

    lib/
    └── MyModule/
        ├── xs/
        │   ├── _header.xs      # Includes, types, static vars
        │   ├── context.xs      # MyModule::Context methods
        │   ├── tensor.xs       # MyModule::Tensor methods
        │   ├── inference.xs    # MyModule::Inference methods
        │   └── _footer.xs      # BOOT section
        └── MyModule.pm         # Perl module

=head2 Hierarchical Layout (recursive mode)

XS files alongside their corresponding C<.pm> files:

    lib/
    └── MyModule/
        ├── _header.xs          # Shared includes, types, static vars
        ├── _footer.xs          # BOOT section
        ├── MyModule.pm         # Main module
        ├── Context.pm          # Context module
        ├── Context.xs          # Context XS code
        ├── Tensor.pm           # Tensor module
        ├── Tensor.xs           # Tensor XS code
        └── Inference.pm        # Inference module
            └── Inference.xs    # Inference XS code

Use C<< recursive => 1 >> in C<combine()> for this layout.

=head2 _header.xs example

    #define PERL_NO_GET_CONTEXT
    #include "EXTERN.h"
    #include "perl.h"
    #include "XSUB.h"

    /* Shared constants and static variables - accessible from all modules */
    #define MAX_SLOTS 10
    static double slots[MAX_SLOTS];
    static int slot_count = 0;

    /* Shared helper function */
    static int is_valid_slot(int slot) {
        return (slot >= 0 && slot < MAX_SLOTS);
    }

Note: C<_header.xs> typically has B<no> C<MODULE => line - its entire content
is treated as C preamble code that gets placed first in the combined output.

=head2 context.xs example

Package XS files can define their own C helper functions that use definitions
from C<_header.xs>:

    /*
     * Context-specific helpers using shared state from _header.xs
     */

    /* This function can use MAX_SLOTS, slots[], and is_valid_slot()
       because _header.xs C code is placed first in the combined preamble */
    static int ctx_count_used(void) {
        int count = 0;
        for (int i = 0; i < MAX_SLOTS; i++) {
            if (slots[i] != 0.0) count++;
        }
        return count;
    }

    MODULE = MyModule    PACKAGE = MyModule::Context

    int
    used_slots()
    CODE:
        RETVAL = ctx_count_used();
    OUTPUT:
        RETVAL

=head2 _footer.xs example

    MODULE = MyModule    PACKAGE = MyModule

    BOOT:
        /* Initialize shared state */
        memset(registry, 0, sizeof(registry));


You can also combine both approaches: use XSMULTI for truly independent
modules while using XSOne for modules that need to share state.

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-extutils-xsone at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtUtils-XSOne>.

=head1 SEE ALSO

L<ExtUtils::MakeMaker>, L<perlxs>, L<perlxstut>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
