package Makefile::Update::VCProj;
# ABSTRACT: Update list of sources and headers in Visual C++ projects.

use Exporter qw(import);
our @EXPORT = qw(update_vcproj);

use strict;
use warnings;

our $VERSION = '0.3'; # VERSION



sub update_vcproj
{
    my ($in, $out, $sources, $headers, $filter_cb) = @_;

    # Use standard/default classifier for the files if none is explicitly
    # specified.
    if (!defined $filter_cb) {
        $filter_cb = sub {
            my ($file) = @_;

            return 'Source Files' if $file =~ q{\.c(c|pp|xx|\+\+)?$};
            return 'Header Files' if $file =~ q{\.h(h|pp|xx|\+\+)?$};

            warn qq{No filter defined for the file "$file".\n};

            undef
        }
    }

    # Hash mapping the filter to all the files using it (whether sources or
    # headers).
    my %files_by_filter;
    foreach my $file (@$sources, @$headers) {
        my $filter = $filter_cb->($file);
        if (defined $filter) {
            push @{$files_by_filter{$filter}}, $file
        }
    }

    # Name of the current filter, if any.
    my $filter;

    # Hash containing 0 or 1 for each file using the current filter.
    my %seen;

    # Indicates whether the closing angle bracket of "<File>" tags is on its
    # own line (which is how MSVS 2005 and 2008 format their files) or on the
    # same line as "RelativePath" attribute (which is how MSVS 2003 does it).
    my $angle_bracket_on_same_line = 0;

    # Set to 1 if we made any changes.
    my $changed = 0;

    while (defined (my $line_with_eol = <$in>)) {
        (my $line = $line_with_eol) =~ s/\r?\n$//;

        if ($line =~ /^\s*<Filter$/) {
            if (defined($filter)) {
                warn qq{Nested <Filter> tag at line $. while parsing filter } .
                     qq{"$filter" is not supported.\n};
                next;
            }

            print $out $line_with_eol;
            $line_with_eol = <$in>;
            if (defined $line_with_eol &&
                    $line_with_eol =~ /^\s*Name="(.*)"\r?\n$/) {
                $filter = $1;
                if (!exists $files_by_filter{$filter}) {
                    # If we don't have any files for this filter, don't remove
                    # all the files from it, just skip it entirely instead.
                    undef $filter;
                } else {
                    %seen = map { $_ => 0 } @{$files_by_filter{$filter}};
                }
            } else {
                warn qq{Unrecognized format for <Filter> tag at line $..\n};
            }
        } elsif (defined $filter) {
            if ($line =~ /^\s*<File$/) {
                my $line_file_start = $line_with_eol;

                $line_with_eol = <$in>;
                if (defined $line_with_eol &&
                        $line_with_eol =~ /^\s*RelativePath="(.*)"(>?)\r?\n$/) {
                    $angle_bracket_on_same_line = $2 eq '>';

                    # Normalize path separators to Unix and remove the leading
                    # dot which MSVC likes to use for some reason.
                    (my $file = $1) =~ s@\\@/@g;
                    $file =~ s@^\./@@;

                    # Special hack for resource files that sometimes occur in
                    # the "Source Files" section of MSVC projects too: don't
                    # remove them, even if they don't appear in the master
                    # files list, because they are never going to appear in it.
                    if ($file !~ /\.rc$/) {
                        if (!exists $seen{$file}) {
                            # This file is not in the master file list any
                            # more, delete it from the project file as well by
                            # not copying the lines corresponding to it to the
                            # output.
                            $changed = 1;

                            # Skip the next line unless we had already seen
                            # the angle bracket.
                            if (!$angle_bracket_on_same_line) {
                                if (<$in> !~ /^\s*>\r?\n$/) {
                                    warn qq{Expected closing '>' on the line $.\n}
                                }
                            }

                            # And skip everything up to and including the
                            # closing </File> tag in any case.
                            while (<$in>) {
                                last if qr{^\s*</File>\r?\n$}
                            }

                            next;
                        }

                        # This file is still in the files list, mark it as seen.
                        if ($seen{$file}) {
                            warn qq{Duplicate file "$file" in the project at line $.\n};
                        } else {
                            $seen{$file} = 1;
                        }
                    }
                } else {
                    warn qq{Unrecognized format for <File> tag inside filter } .
                         qq{"$filter" at line $..\n};
                }

                # Don't lose the original line, it won't be printed at the
                # end of the loop any more.
                print $out $line_file_start;
            } elsif ($line =~ qr{^\s*</Filter>$}) {
                my $angle_bracket = $angle_bracket_on_same_line
                                        ? '>'
                                        : "\n\t\t\t\t>";

                # Add new files, if any.
                #
                # TODO Insert them in alphabetical order.
                while (my ($file, $seen) = each(%seen)) {
                    if (!$seen) {
                        # Convert path separator to the one used by MSVC.
                        $file =~ s@/@\\@g;

                        # And use path even for the files in this directory.
                        $file = ".\\$file" if $file !~ /\\/;

                        print $out <<END
\t\t\t<File
\t\t\t\tRelativePath="$file"$angle_bracket
\t\t\t</File>
END
;

                        $changed = 1;
                    }
                }

                undef $filter;
            }
        }

        print $out $line_with_eol;
    }

    $changed
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Makefile::Update::VCProj - Update list of sources and headers in Visual C++ projects.

=head1 VERSION

version 0.3

=head1 SYNOPSIS

The function L<update_vcproj()> can be used to update the list of headers and
sources in the given Visual C++ project file C<project.vcproj>:

    use Makefile::Update::VCProj;
    upmake_msbuild_project('project.vcproj', \@sources, \@headers);

=head1 FUNCTIONS

=head2 update_vcproj

Update sources and headers in a VC++ project.

Parameters: input and output file handles, array references to the sources
and the headers to be used in this project and a callback used to determine
the filter for the new files.

Returns 1 if any changes were made.

=head1 SEE ALSO

Makefile::Update, Makefile::Update::MSBuild

=head1 AUTHOR

Vadim Zeitlin <vz-cpan@zeitlins.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Vadim Zeitlin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
