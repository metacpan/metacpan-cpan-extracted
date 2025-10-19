package Filename::Timestamp;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
use Time::Local qw(timelocal_posix);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'Filename-Timestamp'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(extract_timestamp_from_filename);

our %SPEC;

$SPEC{extract_timestamp_from_filename} = {
    v => 1.1,
    summary => 'Extract date/timestamp from filename, if any',
    description => <<'MARKDOWN',


MARKDOWN
    args => {
        filename => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        all => {
            schema => 'bool',
            summary => 'Find all timestamps instead of the first found only',
            description => <<'MARKDOWN',

Not yet implemented.

MARKDOWN
        },
    },
    result_naked => 1,
    result => {
        schema => ['any*', of=>['bool*', 'hash*']],
        description => <<'MARKDOWN',

Return false if no timestamp is detected. Otherwise return a hash of
information, which contains these keys: `epoch`, `year`, `month`, `day`, `hour`,
`minute`, `second`.

MARKDOWN
    },
    examples => [
        {
            args => {filename=>'2024-09-08T12_35_48+07_00.JPEG'},
        },
        {
            args => {filename=>'IMG_20240908_095444.jpg'},
        },
        {
            args => {filename=>'VID_20240908_092426.mp4'},
        },
        {
            args => {filename=>'Screenshot_2024-09-01-11-40-44-612_org.mozilla.firefox.jpg'},
        },
        {
            args => {filename=>'IMG-20241204-WA0001.jpg'},
        },
        {
            args => {filename=>'foo.txt'},
        },
    ],
};
sub extract_timestamp_from_filename {
    my %args = @_;

    my $filename = $args{filename};

    my $res = {};
    if ($filename =~ /(\d{4})[_.-](\d{2})[_.-](\d{2})
                      (?:
                          [T-]
                          (\d{2})[_.-](\d{2})[_.-](\d{2})
                      )?
                     /x) {
        $res->{year} = $1+0;
        $res->{month} = $2+0;
        $res->{day} = $3+0;
        if (defined $4) {
            $res->{hour} = $4+0;
            $res->{minute} = $5+0;
            $res->{second} = $6+0;
        } else {
            $res->{hour} = 0;
            $res->{minute} = 0;
            $res->{second} = 0;
        }
    } elsif ($filename =~ /(\d{4})(\d{2})(\d{2})
                           (?:
                               [_-]
                               (\d{2})(\d{2})(\d{2})
                           )?
                          /x) {
        $res->{year} = $1+0;
        $res->{month} = $2+0;
        $res->{day} = $3+0;
        if (defined $4) {
            $res->{hour} = $4+0;
            $res->{minute} = $5+0;
            $res->{second} = $6+0;
        } else {
            $res->{hour} = 0;
            $res->{minute} = 0;
            $res->{second} = 0;
        }
    } else {
        return 0;
    }

    $res->{epoch} = timelocal_posix(
        $res->{second},
        $res->{minute},
        $res->{hour},
        $res->{day},
        $res->{month} - 1,
        $res->{year} - 1900,
    );

    $res;
}

1;
# ABSTRACT: Extract date/timestamp from filename, if any

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Timestamp - Extract date/timestamp from filename, if any

=head1 VERSION

This document describes version 0.001 of Filename::Timestamp (from Perl distribution Filename-Timestamp), released on 2024-12-21.

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


=head2 extract_timestamp_from_filename

Usage:

 extract_timestamp_from_filename(%args) -> bool|hash

Extract dateE<sol>timestamp from filename, if any.

Examples:

=over

=item * Example #1:

 extract_timestamp_from_filename(filename => "2024-09-08T12_35_48+07_00.JPEG");

Result:

 {
   day    => 8,
   epoch  => 1725773748,
   hour   => 12,
   minute => 35,
   month  => 9,
   second => 48,
   year   => 2024,
 }

=item * Example #2:

 extract_timestamp_from_filename(filename => "IMG_20240908_095444.jpg");

Result:

 {
   day    => 8,
   epoch  => 1725764084,
   hour   => 9,
   minute => 54,
   month  => 9,
   second => 44,
   year   => 2024,
 }

=item * Example #3:

 extract_timestamp_from_filename(filename => "VID_20240908_092426.mp4");

Result:

 {
   day    => 8,
   epoch  => 1725762266,
   hour   => 9,
   minute => 24,
   month  => 9,
   second => 26,
   year   => 2024,
 }

=item * Example #4:

 extract_timestamp_from_filename(filename => "Screenshot_2024-09-01-11-40-44-612_org.mozilla.firefox.jpg");

Result:

 {
   day    => 1,
   epoch  => 1725165644,
   hour   => 11,
   minute => 40,
   month  => 9,
   second => 44,
   year   => 2024,
 }

=item * Example #5:

 extract_timestamp_from_filename(filename => "IMG-20241204-WA0001.jpg");

Result:

 {
   day    => 4,
   epoch  => 1733245200,
   hour   => 0,
   minute => 0,
   month  => 12,
   second => 0,
   year   => 2024,
 }

=item * Example #6:

 extract_timestamp_from_filename(filename => "foo.txt"); # -> 0

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

Find all timestamps instead of the first found only.

Not yet implemented.

=item * B<filename>* => I<str>

(No description)


=back

Return value:  (bool|hash)


Return false if no timestamp is detected. Otherwise return a hash of
information, which contains these keys: C<epoch>, C<year>, C<month>, C<day>, C<hour>,
C<minute>, C<second>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Timestamp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Timestamp>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Timestamp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
