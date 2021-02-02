package Finance::ID::KSEI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-01'; # DATE
our $DIST = 'Finance-ID-KSEI'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       get_ksei_sec_ownership
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Get information from KSEI (Kustodian Sentral Efek Indonesia) (Indonesian Central Securities Depository)',
};

$SPEC{get_ksei_sec_ownership_url} = {
    v => 1.1,
    summary => 'Get KSEI securities ownership information',
    description => <<'_',

KSEI provides this in the form of monthly ZIP file. This function will just try
to search the URL and return it.

_
    args => {
        year => {
            schema => 'date::year*',
            req => 1,
            pos => 0,
        },
        month => {
            schema => 'date::month_num*',
            req => 1,
            pos => 1,
        },
    },
};
sub get_ksei_sec_ownership_url {
    require DateTime;
    require HTTP::Tiny;

    my %args = @_;

    # get the last weekday of the month
    my $dt = DateTime->new(year => $args{year}, month => $args{month}, day => 1);
    $dt->add(months => 1)->subtract(days => 1);
    while ($dt->day_of_week > 5) { $dt->subtract(days => 1) }

    # it may be a holiday, we don't consult Calendar::Indonesian::Holiday
    # because IDX holiday might be slightly different. so we just try to probe
    # for the URL for two weeks before giving up.
    for (1..14) {
        my $url = sprintf(
            "https://www.ksei.co.id/Download/BalanceposEfek%04d%02d%02d.zip",
            $dt->year, $dt->month, $dt->day,
        );
        log_trace "Trying $url ...";
        my $res = HTTP::Tiny->new->head($url);
        if ($res->{status} == 404) {
            while (1) { $dt->subtract(days => 1); last unless $dt->day_of_week > 5 }
            next;
        } elsif ($res->{status} == 200) {
            return [200, "OK", $url];
        } else {
            return [500, "Failed when trying URL '$url': $res->{status} - $res->{reason}"];
        }
    }
    return [500, "Giving up after not finding the URL for 14 dates"];
}

1;
# ABSTRACT: Get information from KSEI (Kustodian Sentral Efek Indonesia) (Indonesian Central Securities Depository)

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::ID::KSEI - Get information from KSEI (Kustodian Sentral Efek Indonesia) (Indonesian Central Securities Depository)

=head1 VERSION

This document describes version 0.002 of Finance::ID::KSEI (from Perl distribution Finance-ID-KSEI), released on 2021-02-01.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 get_ksei_sec_ownership_url

Usage:

 get_ksei_sec_ownership_url(%args) -> [status, msg, payload, meta]

Get KSEI securities ownership information.

KSEI provides this in the form of monthly ZIP file. This function will just try
to search the URL and return it.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<month>* => I<date::month_num>

=item * B<year>* => I<date::year>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-ID-KSEI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-ID-KSEI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Finance-ID-KSEI/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Finance::SE::IDX>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
