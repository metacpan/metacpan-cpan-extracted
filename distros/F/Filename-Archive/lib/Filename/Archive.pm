package Filename::Archive;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-15'; # DATE
our $DIST = 'Filename-Archive'; # DIST
our $VERSION = '0.033'; # VERSION

our @EXPORT_OK = qw(check_archive_filename);
#list_archive_suffixes

# XXX multi-part archive?

our %SUFFIXES = (
    '.7z'  => {name=>'7-zip'},
    '.cb7'  => {name=>'7-zip'},

    '.zip' => {name=>'Zip'},
    '.cbz' => {name=>'Zip'},

    '.rar' => {name=>'RAR'},
    '.cbr' => {name=>'RAR'},

    '.tar' => {name=>'tar'},
    '.cbt' => {name=>'tar'},

    '.tgz' => {name=>'tar+gzip'},
    '.tbz' => {name=>'tar+bzip2'},

    '.ace' => {name=>'ACE'},
    '.cba' => {name=>'ACE'},

    '.arj' => {name=>'arj'},
    # XXX other older/less popular: lha, zoo
    # XXX windows: cab
    # XXX zip-based archives: war, etc
    # XXX tar-based archives: linux packages
);

our %ARCHIVES = (
    'arj' => {
    },
    '7-zip' => {
    },
    Zip => {
        # all programs mentioned here must accept filename(s) as arguments.
        # preferably CLI. XXX specify capabilities (password-protection, unix
        # permission, etc). XXX specify how to create (with password, etc). XXX
        # specify how to extract.
        archiver_programs => [
            {name => 'zip', opts => ''},
        ],
        extractor_programs => [
            {name => 'zip', opts => ''},
            {name => 'unzip', opts => ''},
        ],
    },
    RAR => {
    },
    tar => {
    },
    'tar+gzip' => {
    },
    'tar+bzip2' => {
    },
    ace => {
        extractor_programs => [
            {name => 'unace', opts => ''},
        ],
    },
);

our %SPEC;

$SPEC{check_archive_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being an archive file',
    description => <<'_',


_
    args => {
        filename => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        # XXX recurse?
        ignore_case => {
            summary => 'Whether to match case-insensitively',
            schema  => 'bool',
            default => 1,
        },
    },
    result_naked => 1,
    result => {
        schema => ['any*', of=>['bool*', 'hash*']],
        description => <<'_',

Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: `archive_name`, `archive_suffix`,
`compressor_info`, `filename_without_suffix`.

_
    },
    examples => [
        {
            args => {filename=>'foo.tar.bz2'},
        },
        {
            args => {filename=>'bar.Zip', ignore_case=>1},
        },
    ],
};
sub check_archive_filename {
    require Filename::Compressed;

    my %args = @_;

    my $filename = $args{filename};
    my $ci = $args{ignore_case} // 1;

    my @compressor_info;
    while (1) {
        my $res = Filename::Compressed::check_compressed_filename(
            filename => $filename, ci => $ci);
        if ($res) {
            push @compressor_info, $res;
            $filename = $res->{uncompressed_filename};
            next;
        } else {
            last;
        }
    }

    $filename =~ /(.+)(\.\w+)\z/ or return 0;
    my ($filename_without_suffix, $suffix) = ($1, $2);

    my $spec;
    if ($ci) {
        my $suffix_lc = lc($suffix);
        for (keys %SUFFIXES) {
            if (lc($_) eq $suffix_lc) {
                $spec = $SUFFIXES{$_};
                last;
            }
        }
    } else {
        $spec = $SUFFIXES{$suffix};
    }
    return 0 unless $spec;

    return {
        archive_name       => $spec->{name},
        archive_suffix     => $suffix,
        filename_without_suffix => $filename_without_suffix,
        (compressor_info    => \@compressor_info) x !!@compressor_info,
    };
}

1;
# ABSTRACT: Check whether filename indicates being an archive file

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Archive - Check whether filename indicates being an archive file

=head1 VERSION

This document describes version 0.033 of Filename::Archive (from Perl distribution Filename-Archive), released on 2023-12-15.

=head1 SYNOPSIS

 use Filename::Archive qw(check_archive_filename);
 my $res = check_archive_filename(filename => "foo.tar.gz");
 if ($res) {
     printf "File is an archive (type: %s, compressed: %s)\n",
         $res->{archive_name},
         $res->{compressor_info} ? "yes":"no";
 } else {
     print "File is not an archive\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_archive_filename

Usage:

 check_archive_filename(%args) -> bool|hash

Check whether filename indicates being an archive file.

Examples:

=over

=item * Example #1:

 check_archive_filename(filename => "foo.tar.bz2");

Result:

 {
   archive_name            => "tar",
   archive_suffix          => ".tar",
   compressor_info         => [
                                {
                                  compressor_name       => "Bzip2",
                                  compressor_suffix     => ".bz2",
                                  uncompressed_filename => "foo.tar",
                                },
                              ],
   filename_without_suffix => "foo",
 }

=item * Example #2:

 check_archive_filename(filename => "bar.Zip", ignore_case => 1);

Result:

 {
   archive_name => "Zip",
   archive_suffix => ".Zip",
   filename_without_suffix => "bar",
 }

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<str>

(No description)

=item * B<ignore_case> => I<bool> (default: 1)

Whether to match case-insensitively.


=back

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: C<archive_name>, C<archive_suffix>,
C<compressor_info>, C<filename_without_suffix>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Archive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Archive>.

=head1 SEE ALSO

L<Filename::Compressed>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2020, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Archive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
