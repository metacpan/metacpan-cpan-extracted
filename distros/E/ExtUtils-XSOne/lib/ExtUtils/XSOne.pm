package ExtUtils::XSOne;

use 5.008003;
use strict;
use warnings;

use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Carp qw(croak);

our $VERSION = '0.01';

sub combine {
    my ($class, %opts) = @_;

    my $src_dir = $opts{src_dir} or croak "src_dir is required";
    my $output  = $opts{output}  or croak "output is required";
    my $order   = $opts{order};
    my $verbose = $opts{verbose} || 0;
    my $dedup   = exists $opts{deduplicate} ? $opts{deduplicate} : 1;

    my @xs_files = $class->_find_xs_files($src_dir);

    # Sort files
    my @sorted = $class->_sort_files(\@xs_files, $order);

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

    for my $file (@sorted) {
        my $path = File::Spec->catfile($src_dir, $file);
        warn "ExtUtils::XSOne: Reading $path\n" if $verbose;

        my $content = $class->_read_file($path);

        if ($dedup) {
            # Parse and extract C preamble (before MODULE =)
            my ($preamble, $xs_part) = $class->_split_preamble($content);

            # Extract includes, defines, and other C code from preamble
            my ($includes, $defines, $other_c) = $class->_parse_preamble($preamble);

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
            push @collected_c_code, { file => $file, path => $path, code => $other_c }
                if $other_c =~ /\S/;

            # Store just the XS part
            push @file_contents, { file => $file, path => $path, content => $xs_part };
        } else {
            push @file_contents, { file => $file, path => $path, content => $content };
        }
    }

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

Version 0.01

=head1 SYNOPSIS

    # In Makefile.PL
    use ExtUtils::MakeMaker;
    use ExtUtils::XSOne;

    # Combine XS files before WriteMakefile
    ExtUtils::XSOne->combine(
        src_dir => 'lib/MyModule/xs',
        output  => 'lib/MyModule.xs',
    );

    WriteMakefile(
        NAME => 'MyModule',
        # ... other options
    );

Or use the command-line tool:

    xsone --src lib/MyModule/xs --out lib/MyModule.xs

=head1 DESCRIPTION

C<ExtUtils::XSOne> solves a fundamental limitation of Perl's XSMULTI feature:
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

With ExtUtils::XSOne, you organize code like this:

    lib/
    └── Foo/
        └── xs/
            ├── _header.xs    # Common includes, types, static vars
            ├── context.xs    # MODULE = Foo PACKAGE = Foo::Context
            ├── tensor.xs     # MODULE = Foo PACKAGE = Foo::Tensor
            └── _footer.xs    # BOOT section

These are combined at build time into a single C<lib/Foo.xs>, which compiles
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

Combines multiple XS files into a single output file.

B<Options:>

=over 4

=item C<src_dir> (required)

Directory containing the source C<.xs> files.

=item C<output> (required)

Path to the output combined C<.xs> file.

=item C<order> (optional)

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

=item 5. Outputs the deduplicated preamble followed by the XS sections

=back

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
        output  => 'lib/MyModule.xs',
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

=head1 EXAMPLE DIRECTORY STRUCTURE

    lib/
    └── MyModule/
        ├── xs/
        │   ├── _header.xs      # Includes, types, static vars
        │   ├── context.xs      # Lugh::Context methods
        │   ├── tensor.xs       # Lugh::Tensor methods
        │   ├── inference.xs    # Lugh::Inference methods
        │   └── _footer.xs      # BOOT section
        └── MyModule.pm         # Perl module

=head2 _header.xs example

    #define PERL_NO_GET_CONTEXT
    #include "EXTERN.h"
    #include "perl.h"
    #include "XSUB.h"

    /* Shared static registry - accessible from all modules */
    static void *registry[1024];
    static int registry_count = 0;

=head2 context.xs example

    MODULE = MyModule    PACKAGE = MyModule::Context

    SV *
    new(class, ...)
        char *class
    CODE:
        /* Can access registry from _header.xs */
        registry[registry_count++] = create_context();
        /* ... */
    OUTPUT:
        RETVAL

=head2 _footer.xs example

    MODULE = MyModule    PACKAGE = MyModule

    BOOT:
        /* Initialize shared state */
        memset(registry, 0, sizeof(registry));

=head1 WHY NOT JUST USE XSMULTI?

XSMULTI is great when your XS modules are truly independent. Use XSMULTI when:

=over 4

=item * Each module has no shared C state with other modules

=item * Modules only depend on external libraries (like ggml, OpenSSL, etc.)

=item * You want separate compilation for faster incremental builds

=back

Use ExtUtils::XSOne when:

=over 4

=item * Modules need to share C registries, caches, or static variables

=item * You have a monolithic XS file that's grown too large to maintain

=item * You want modular source organization with single-library deployment

=back

You can also combine both approaches: use XSMULTI for truly independent
modules while using XSOne for modules that need to share state.

=head1 DEBUGGING

The combined file includes C<#line> preprocessor directives that point
back to the original source files. This means:

=over 4

=item * Compiler errors show the original file and line number

=item * Debuggers (gdb, lldb) can step through original source files

=item * Stack traces reference the original files

=back

=head1 AUTHOR

LNATION email@lnation.org

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
