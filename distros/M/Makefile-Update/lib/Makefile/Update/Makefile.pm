package Makefile::Update::Makefile;
# ABSTRACT: Update lists of files in makefile variables.

use Exporter qw(import);
our @EXPORT = qw(update_makefile);

use strict;
use warnings;

our $VERSION = '0.4'; # VERSION



sub update_makefile
{
    my ($in, $out, $vars) = @_;

    # Variable whose contents is being currently replaced and its original
    # name in the makefile.
    my ($var, $makevar);

    # Hash with files defined for the specified variable as keys and 0 or 1
    # depending on whether we have seen them in the input file as values.
    my %files;

    # Array of lines in the existing makefile.
    my @values;

    # True if the values are in alphabetical order: we use this to add new
    # entries in alphabetical order too if the existing ones use it, otherwise
    # we just append them at the end.
    my $sorted = 1;

    # Extensions of the files in the files list (they're keys of this hash,
    # the values are not used), there can be more than one (e.g. ".c" and
    # ".cpp").
    my %src_exts;

    # Extension of the files in the makefiles: here there can also be more
    # than one, but in this case we just give up and don't perform any
    # extensions translation because we don't have enough information to do it
    # (e.g. which extension should be used for the new files in the makefile?).
    # Such case is indicated by make_ext being empty (as opposed to its
    # initial undefined value).
    my $make_ext;

    # Helper to get the extension. Note that the "extension" may be a make
    # variable, e.g. the file could be something like "foo.$(obj)", so don't
    # restrict it to just word characters.
    sub _get_ext { $_[0] =~ /(\.\S+)$/ ? $1 : undef }

    # Indent and the part after the value (typically some amount of spaces and
    # a backslash) for normal lines and, separately, for the last one, as it
    # may or not have backslash after it.
    my ($indent, $tail, $last_tail);

    # We can't use the usual check for EOF inside while itself because this
    # wouldn't work for files with no new line after the last line, so check
    # for the EOF manually.
    my $eof = 0;

    # Set to 1 if we made any changes.
    my $changed = 0;
    while (1) {
        my $line = <$in>;
        if (defined $line) {
            chomp $line;
        } else {
            $line = '';
            $eof = 1;
        }

        # If we're inside the variable definition, parse the current line as
        # another file name,
        if (defined $var) {
            if ($line =~ /^(?<indent>\s*)(?<file>[^ ]+)(?<tail>\s*\\?)$/) {
                if (defined $indent) {
                    warn qq{Inconsistent indent at line $. in the } .
                         qq{definition of the variable "$makevar".\n}
                        if $+{indent} ne $indent;
                } else {
                    $indent = $+{indent};
                }

                $last_tail = $+{tail};
                my $file_orig = $+{file};

                $tail = $last_tail if !defined $tail;

                # Check if we have something with the correct extension and
                # preserve unchanged all the rest -- we don't want to remove
                # expansions of other makefile variables from this one, for
                # example, but such expansions would never be in the files
                # list as they don't make sense for the other formats.
                my $file = $file_orig;
                if (defined (my $file_ext = _get_ext($file))) {
                    if (defined $make_ext) {
                        if ($file_ext ne $make_ext) {
                            # As explained in the comment before make_ext
                            # definition, just don't do anything in this case.
                            $make_ext = '';
                        }
                    } else {
                        $make_ext = $file_ext;
                    }

                    # We need to try this file with all of the source
                    # extensions we have as it can correspond to any of them.
                    for my $src_ext (keys %src_exts) {
                        if ($file_ext ne $src_ext) {
                            (my $file_try = $file) =~ s/\Q$file_ext\E$/$src_ext/;
                            if (exists $files{$file_try}) {
                                $file = $file_try;
                                last
                            }
                        }
                    }

                    if (!exists $files{$file}) {
                        # This file was removed.
                        $changed = 1;

                        # Don't store this line in @values below.
                        next;
                    }
                }

                if (exists $files{$file}) {
                    if ($files{$file}) {
                        warn qq{Duplicate file "$file" in the definition of the } .
                             qq{variable "$makevar" at line $.\n}
                    } else {
                        $files{$file} = 1;
                    }
                }

                # Are we still sorted?
                if (@values && lc $line lt $values[-1]) {
                    $sorted = 0;
                }

                push @values, $line;
                next;
            }

            # If the last line had a continuation character, the file list
            # should only end if there is nothing else on the following line.
            if ($last_tail =~ /\\$/ && $line =~ /\S/) {
                warn qq{Expected blank line at line $..\n};
            }

            # End of variable definition, add new lines.

            # We can only map the extensions if we have a single extension to
            # map them to (i.e. make_ext is not empty) and we only need to do
            # it if are using more than one extension in the source files list
            # or the single extension that we use is different from make_ext.
            if (defined $make_ext) {
                if ($make_ext eq '' ||
                        (keys %src_exts == 1 && exists $src_exts{$make_ext})) {
                    undef $make_ext
                }
            }

            my $new_files = 0;
            while (my ($file, $seen) = each(%files)) {
                next if $seen;

                # This file was wasn't present in the input, add it.

                # If this is the first file we add, ensure that the last line
                # present in the makefile so far has the line continuation
                # character at the end as this might not have been the case.
                if (!$new_files) {
                    $new_files = 1;

                    if (@values && $values[-1] !~ /\\$/) {
                        $values[-1] .= $tail;
                    }
                }

                # Next give it the right extension.
                if (defined $make_ext) {
                    $file =~ s/\.\S+$/$make_ext/
                }

                # Finally store it.
                push @values, "$indent$file$tail";
            }

            if ($new_files) {
                $changed = 1;

                # Sort them if necessary using the usual Schwartzian transform.
                if ($sorted) {
                    @values = map { $_->[0] }
                              sort { $a->[1] cmp $b->[1] }
                              map { [$_, lc $_] } @values;
                }

                # Fix up the tail of the last line to be the same as that of
                # the previous last line.
                $values[-1] =~ s/\s*\\$/$last_tail/;
            }

            undef $var;

            print $out join("\n", @values), "\n";
        }

        # We're only interested in variable or target declarations, and does
        # not look like target-specific variable (this would contain an equal
        # sign after the target).
        if ($line =~ /^\s*(?<var>\S+)\s*(?::?=|:)(?<tail>[^=]*)$/) {
            $makevar = $+{var};
            my $tail = $+{tail};

            # And only those of them for which we have values, but this is
            # where it gets tricky as we try to be smart to accommodate common
            # use patterns with minimal effort.
            if (exists $vars->{$makevar}) {
                $var = $makevar;
            } else {
                # Helper: return name if a variable with such name exists or
                # undef otherwise.
                my $var_if_exists = sub { exists $vars->{$_[0]} ? $_[0] : undef };

                if ($makevar =~ /^objects$/i || $makevar =~ /^obj$/i) {
                    # Special case: map it to "sources" as we work with the
                    # source, not object, files.
                    $var = $var_if_exists->('sources');
                } elsif ($makevar =~ /^(\w+)_(objects|obj|sources|src)$/i) {
                    # Here we deal with "foo_sources" typically found in
                    # hand-written makefiles but also "foo_SOURCES" used in
                    # automake ones, but the latter also uses libfoo_a_SOURCES
                    # for static libraries and libfoo_la_SOURCES for the
                    # libtool libraries, be smart about it to allow defining
                    # just "foo" or "foo_sources" variables usable with all
                    # kinds of make/project files.
                    $var = $var_if_exists->($1) || $var_if_exists->("$1_sources");
                    if (!defined $var && $2 eq 'SOURCES' && $1 =~ /^(\w+)_l?a$/) {
                        $var = $var_if_exists->($1) || $var_if_exists->("$1_sources");
                        if (!defined $var && $1 =~ /^lib(\w+)$/) {
                            $var = $var_if_exists->($1) || $var_if_exists->("$1_sources");
                        }
                    }
                } elsif ($makevar =~ /^(\w+)\$\(\w+\)/) {
                    # This one is meant to catch relatively common makefile
                    # constructions like "target$(exe_ext)".
                    $var = $var_if_exists->($1);
                }
            }

            if (defined $var) {
                if ($tail !~ /\s*\\$/) {
                    warn qq{Unsupported format for variable "$makevar" at line $..\n};
                    undef $var;
                } else {
                    %files = map { $_ => 0 } @{$vars->{$var}};

                    @values = ();

                    # Find all the extensions used by files in this variable.
                    for my $file (@{$vars->{$var}}) {
                        if (defined (my $src_ext = _get_ext($file))) {
                            $src_exts{$src_ext} = 1;
                        }
                    }

                    # Not known yet.
                    undef $make_ext;

                    undef $indent;
                    $tail = $tail;
                    undef $last_tail;

                    # Not unsorted so far.
                    $sorted = 1;
                }
            }
        }

        print $out "$line";

        # Don't add an extra new line at the EOF if it hadn't been there.
        last if $eof;

        print $out "\n";
    }

    $changed
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Makefile::Update::Makefile - Update lists of files in makefile variables.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This can be used to update the contents of a variable containing a list of
files in a makefile.

    use Makefile::Update::Makefile;
    Makefile::Update::upmake('GNUmakefile', \&update_makefile, $vars);

=head1 FUNCTIONS

=head2 update_makefile

Update variable definitions in a makefile format with the data from the hash
ref containing all the file lists.

Only most straightforward cases of variable or target definitions are
recognized here, i.e. just "var := value", "var = value" or "target: value".
In particular we don't support any GNU make extensions such as "export" or
"override" without speaking of anything more complex.

On top of it, currently the value should contain a single file per line with
none at all on the first line (but this restriction could be relaxed later if
needed), i.e. the only supported case is

    var = \
          foo \
          bar \
          baz

and it must be followed by an empty line, too.

Notice that if any of the "files" in the variable value looks like a makefile
variable, i.e. has "$(foo)" form, it is ignored by this function, i.e. not
removed even if it doesn't appear in the list of files (which will never be
the case normally).

Takes the (open) file handles of the files to read and to write and the file
lists hash ref as arguments.

Returns 1 if any changes were made.

=head1 SEE ALSO

Makefile::Update

=head1 AUTHOR

Vadim Zeitlin <vz-cpan@zeitlins.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Vadim Zeitlin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
