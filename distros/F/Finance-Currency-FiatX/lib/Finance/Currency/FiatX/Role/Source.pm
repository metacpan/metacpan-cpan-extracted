package Finance::Currency::FiatX::Role::Source;

our $DATE = '2018-06-19'; # DATE
our $VERSION = '0.005'; # VERSION

use Role::Tiny;

requires 'get_all_spot_rates';
requires 'get_spot_rate';

1;
# ABSTRACT: Role for FiatX sources

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::FiatX::Role::Source - Role for FiatX sources

=head1 VERSION

This document describes version 0.005 of Finance::Currency::FiatX::Role::Source (from Perl distribution Finance-Currency-FiatX), released on 2018-06-19.

=head1 DESCRIPTION

All routines must return enveloped result.

 [$status, $reason, $payload, \%extra]

This result is analogous to an HTTP response; in fact $status mostly uses HTTP
response codes. C<$reason> is analogous to HTTP status message. C<$payload> is
the actual content (optional if C<$status> is error status). C<%extra> is
optional and analogous to HTTP response headers to specify flags or attributes
or other metadata.

Some examples of enveloped result:

 [200, "OK", 14000]
 [404, "Not found"]

For more details about enveloped result, see L<Rinci::function>.

=head1 REQUIRED ROUTINES

=head2 get_all_spot_rates

Usage:

 get_all_spot_rates() -> [$status, $reason, $payload [ , \%extra ] ]

Return spot rate for all currency pairs available for this sources. If the
source provides a way to list all supported rates in a single API call or
webpage, then this routine should return them. Otherwise, this routine should
return status 412, e.g.

 [501, "Source does not offer a way to list all spot rates"]

Result payload is an array of hashes, where each hash must contain these keys:
C<pair> (str in the format of C<< <from_currency>/<to_currency> >>, e.g.
C<USD/IDR>), C<rate> (num, the rate), C<mtime> (Unix epoch, last updated time
for the rate, according to the source). C<type> ("buy" or "sell").

=head2 get_spot_rate

Return spot (the latest) rate for a currency pair.

Usage:

 get_spot_rate($from, $to, $type) -> [$status, $reason, $payload [ , \%extra ] ]

C<$from> and C<$to> are currency codes, C<$type> is either "buy" or "sell". If a
source does not support the currency pair, routine must return status 501.

Result payload is hash that must contain these keys: C<pair> (str in the format
of C<< <from_currency>/<to_currency> >>, e.g. C<USD/IDR>), C<rate> (num, the
rate), C<mtime> (Unix epoch, last updated time for the rate, according to the
source). C<type> ("buy" or "sell").

=head2 get_historical_rates

Usage:

 get_historical_rates($from, $to, $from_date, $to_date) -> [$status, $reason, $payload [ , \%extra ] ]

If source does not support historical rates, routine must return status 501.

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
