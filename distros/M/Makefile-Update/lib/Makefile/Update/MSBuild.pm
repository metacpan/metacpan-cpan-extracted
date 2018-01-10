package Makefile::Update::MSBuild;
# ABSTRACT: Update list of sources and headers in MSBuild projects.

use Exporter qw(import);
our @EXPORT = qw(update_msbuild_project update_msbuild update_msbuild_filters);

use strict;
use warnings;

our $VERSION = '0.4'; # VERSION



sub update_msbuild_project
{
    my ($file_or_options, $sources, $headers) = @_;

    use Makefile::Update;

    if (!Makefile::Update::upmake($file_or_options,
                \&update_msbuild, $sources, $headers
            )) {
        return 0;
    }

    my $args;
    if (ref $file_or_options eq 'HASH') {
        # Need to make a copy to avoid modifying the callers hash.
        $args = { %$file_or_options };
        $args->{file} .= ".filters"
    } else {
        $args = "$file_or_options.filters"
    }

    return Makefile::Update::upmake($args,
                \&update_msbuild_filters, $sources, $headers
            );
}



sub update_msbuild
{
    my ($in, $out, $sources, $headers) = @_;

    # Hashes mapping the sources/headers names to 1 if they have been seen in
    # the project or 0 otherwise.
    my %sources = map { $_ => 0 } @$sources;
    my %headers = map { $_ => 0 } @$headers;

    # Reference to the hash corresponding to the files currently being
    # processed.
    my $files;

    # Set to 1 when we are inside any <ItemGroup> tag.
    my $in_group = 0;

    # Set to 1 when we are inside an item group containing sources or headers
    # respectively.
    my ($in_sources, $in_headers) = 0;

    # Set to 1 if we made any changes.
    my $changed = 0;
    while (my $line_with_eol = <$in>) {
        (my $line = $line_with_eol) =~ s/\r?\n?$//;

        if ($line =~ /^\s*<ItemGroup>$/) {
            $in_group = 1;
        } elsif ($line =~ m{^\s*</ItemGroup>$}) {
            if (defined $files) {
                my $kind = $in_sources ? 'Compile' : 'Include';

                # Check if we have any new files.
                #
                # TODO Insert them in alphabetical order.
                while (my ($file, $seen) = each(%$files)) {
                    if (!$seen) {
                        # Convert path separator to the one used by MSBuild.
                        $file =~ s@/@\\@g;

                        print $out qq{    <Cl$kind Include="$file" />\r\n};

                        $changed = 1;
                    }
                }

                $in_sources = $in_headers = 0;
                $files = undef;
            }

            $in_group = 0;
        } elsif ($in_group) {
            if ($line =~ m{^\s*<Cl(?<kind>Compile|Include) Include="(?<file>[^"]+)"\s*(?<slash>/)?>$}) {
                my $kind = $+{kind};
                if ($kind eq 'Compile') {
                    warn "Mix of sources and headers at line $.\n" if $in_headers;
                    $in_sources = 1;
                    $files = \%sources;
                } else {
                    warn "Mix of headers and sources at line $.\n" if $in_sources;
                    $in_headers = 1;
                    $files = \%headers;
                }

                my $closed_tag = defined $+{slash};

                # Normalize the path separator, we always use Unix ones but the
                # project files use Windows one.
                my $file = $+{file};
                $file =~ s@\\@/@g;

                if (not exists $files->{$file}) {
                    # This file was removed.
                    $changed = 1;

                    if (!$closed_tag) {
                        # We have just the opening <ClCompile> or <ClInclude>
                        # tag, ignore everything until the matching closing one.
                        my $tag = "Cl$kind";
                        while (<$in>) {
                            last if m{^\s*</$tag>\r?\n$};
                        }
                    }

                    # In any case skip either this line containing the full
                    # <ClCompile/> tag or the line with the closing tag.
                    next;
                } else {
                    if ($files->{$file}) {
                        warn qq{Duplicate file "$file" in the project at line $.\n};
                    } else {
                        $files->{$file} = 1;
                    }
                }
            }
        }

        print $out $line_with_eol;
    }

    $changed
}


sub update_msbuild_filters
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

    # Hashes mapping the sources/headers names to the text representing them in
    # the input file if they have been seen in it or nothing otherwise.
    my %sources = map { $_ => undef } @$sources;
    my %headers = map { $_ => undef } @$headers;

    # Reference to the hash corresponding to the files currently being
    # processed.
    my $files;

    # Set to 1 when we are inside any <ItemGroup> tag.
    my $in_group = 0;

    # Set to 1 when we are inside an item group containing sources or headers
    # respectively.
    my ($in_sources, $in_headers) = 0;

    # Set to 1 if we made any changes.
    my $changed = 0;
    while (my $line_with_eol = <$in>) {
        (my $line = $line_with_eol) =~ s/\r?\n?$//;

        if ($line =~ /^\s*<ItemGroup>?$/) {
            $in_group = 1;
        } elsif ($line =~ m{^\s*</ItemGroup>?$}) {
            if (defined $files) {
                # Output the group contents now, all at once, inserting any new
                # files: we must do it like this to ensure that they are
                # inserted in alphabetical order.
                my $kind = $in_sources ? 'Compile' : 'Include';

                foreach my $file (sort keys %$files) {
                    if (defined $files->{$file}) {
                        print $out $files->{$file};
                    } else {
                        my $filter = $filter_cb->($file);

                        # Convert path separator to the one used by MSBuild.
                        $file =~ s@/@\\@g;

                        my $indent = ' ' x 2;

                        print $out qq{$indent$indent<Cl$kind Include="$file"};
                        if (defined $filter) {
                            print $out ">\r\n$indent$indent$indent<Filter>$filter</Filter>\r\n$indent$indent</Cl$kind>\r\n";
                        } else {
                            print $out " />\r\n";
                        }

                        $changed = 1;
                    }
                }

                $in_sources = $in_headers = 0;
                $files = undef;
            }

            $in_group = 0;
        } elsif ($in_group &&
                 $line =~ m{^\s*<Cl(?<kind>Compile|Include) Include="(?<file>[^"]+)"\s*(?<slash>/)?>?$}) {
            my $kind = $+{kind};
            if ($kind eq 'Compile') {
                warn "Mix of sources and headers at line $.\n" if $in_headers;
                $in_sources = 1;
                $files = \%sources;
            } else {
                warn "Mix of headers and sources at line $.\n" if $in_sources;
                $in_headers = 1;
                $files = \%headers;
            }

            my $closed_tag = defined $+{slash};

            # Normalize the path separator, we always use Unix ones but the
            # project files use Windows one.
            my $file = $+{file};
            $file =~ s@\\@/@g;

            my $text = $line_with_eol;
            if (!$closed_tag) {
                # We have just the opening <ClCompile> tag, get everything
                # until the next </ClCompile>.
                while (<$in>) {
                    $text .= $_;
                    last if m{^\s*</Cl$kind>\r?\n?$};
                }
            }

            if (not exists $files->{$file}) {
                # This file was removed.
                $changed = 1;
            } else {
                if ($files->{$file}) {
                    warn qq{Duplicate file "$file" in the project at line $.\n};
                } else {
                    $files->{$file} = $text;
                }
            }

            # Don't output this line yet, wait until the end of the group.
            next
        }

        print $out $line_with_eol;
    }

    $changed
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Makefile::Update::MSBuild - Update list of sources and headers in MSBuild projects.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

Given an MSBuild project C<project.vcxproj> and its associated filters file
C<projects.vcxproj.filters>, the functions in this module can be used to update
the list of files in them to correspond to the given ones.

    use Makefile::Update::MSBuild;
    upmake_msbuild_project('project.vcxproj', \@sources, \@headers);

=head1 FUNCTIONS

=head2 update_msbuild_project

Update sources and headers in an MSBuild project and filter files.

Pass the path of the project to update or a hash with the same keys as used by
C<Makefile::Update::upmake> as the first parameter and the references to the
sources and headers arrays as the subsequent ones.

Returns 1 if any changes were made, either to the project itself or to its
associated C<.filters> file.

=head2 update_msbuild

Update sources and headers in an MSBuild project.

Parameters: input and output file handles and array references to the sources
and the headers to be used in this project.

Returns 1 if any changes were made.

=head2 update_msbuild_filters

Update sources and headers in an MSBuild filters file.

Parameters: input and output file handles, array references to the sources
and the headers to be used in this project and a callback used to determine
the filter for the new files.

Returns 1 if any changes were made.

=head1 SEE ALSO

Makefile::Update, Makefile::Update::VCProj

=head1 AUTHOR

Vadim Zeitlin <vz-cpan@zeitlins.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Vadim Zeitlin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
