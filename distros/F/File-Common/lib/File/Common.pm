package File::Common;

our $DATE = '2019-04-16'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::chdir;
use File::Find;

use Exporter qw(import);
our @EXPORT_OK = qw(list_common_files);

our %SPEC;

$SPEC{list_common_files} = {
    v => 1.1,
    summary => 'List files that are found in {all,more than one} directories',
    description => <<'_',

This routine lists files that are found in all specified directories (or, when
`min_occurrences` option is specified, files that are found in at least a
certain number of occurrences. Note that only filenames are compared, not
content/checksum. Directories are excluded.

_
    args => {
        dirs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dir',
            schema => ['array*', of=>'dirname*', min_len=>2],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        min_occurrence => {
            schema => 'posint*',
        },
        detail => {
            summary => 'Whether to return detailed result per file',
            schema => 'bool*',
            description => <<'_',

If set to true, instead of an array of filenames:

    ["file1", "file2"]

it will instead return a hash with filename as key and another hash containing
detailed information:

    {
        "file1" => {
            dirs => ["dir1", "dir2"], # in which dirs the file is found
        },
        "file2" => {
            ...
        },
    }


_
        }
    },
    result_naked => 1,
};
sub list_common_files {
    my %args = @_;

    my $dirs = $args{dirs} or die "Please specify 'dirs'";
    @$dirs >= 2 or die "Please specify at least 2 directories";
    my $min_occurrence = $args{min_occurrence};
    my $detail = $args{detail};

    my @all_files; # index = dir index, elem = hash of path=>1
    for my $i (0..$#{$dirs}) {
        my $dir = $dirs->[$i];
        (-d $dir) or die "No such directory: $dir";
        local $CWD = $dir;
        my %files;
        find(
            sub {
                return unless -f;
                my $path = "$File::Find::dir/$_";
                $path =~ s!\A\./!!;
                $files{$path} = 1;
            },
            ".",
        );
        push @all_files, \%files;
    }

    my %res;
    if (defined $min_occurrence) {
        for my $i (0..$#all_files) {
            for my $f (keys %{ $all_files[$i] }) {
                if ($detail) {
                    push @{ $res{$f}{dirs} }, $dirs->[$i];
                } else {
                    $res{$f}++;
                }
            }
        }
        if ($detail) {
            for my $k (keys %res) {
                delete $res{$k} unless @{ $res{$k}{dirs} } >= $min_occurrence;
            }
            return \%res;
        } else {
            return [sort grep { $res{$_} >= $min_occurrence } keys %res];
        }
    } else {
      FILE:
        for my $f0 (keys %{ $all_files[0] }) {
            for my $i (1..$#all_files) {
                next FILE unless $all_files[$i]{$f0};
            }
            if ($detail) {
                $res{$f0}{dirs} = $dirs;
            } else {
                $res{$f0}++;
            }
        }
        return $detail ? \%res : [sort keys %res];
    }
}

1;
# ABSTRACT: List files that are found in {all,more than one} directories

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Common - List files that are found in {all,more than one} directories

=head1 VERSION

This document describes version 0.003 of File::Common (from Perl distribution File-Common), released on 2019-04-16.

=head1 SYNOPSIS

 use File::Common qw(list_common_files);

 my $res = list_common_files(
     dirs => ["dir1", "dir2"],
     # min_occurrence => 2, # optional, the default if unset is to return files that exist in all dirs
 );

Given this tree:

 dir1/
   file1
   sub1/
     file2
     file3

 dir2/
   file2
   sub1/
     file3
   file3
   file4

Will return:

 ["file1", "sub1/file3"]

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 list_common_files

Usage:

 list_common_files(%args) -> any

List files that are found in {all,more than one} directories.

This routine lists files that are found in all specified directories (or, when
C<min_occurrences> option is specified, files that are found in at least a
certain number of occurrences. Note that only filenames are compared, not
content/checksum. Directories are excluded.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Whether to return detailed result per file.

If set to true, instead of an array of filenames:

 ["file1", "file2"]

it will instead return a hash with filename as key and another hash containing
detailed information:

 {
     "file1" => {
         dirs => ["dir1", "dir2"], # in which dirs the file is found
     },
     "file2" => {
         ...
     },
 }

=item * B<dirs>* => I<array[dirname]>

=item * B<min_occurrence> => I<posint>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Common>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Common>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Common>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Find::Duplicate>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
