package Finance::Currency::Convert::Mandiri;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
use List::Util qw(min);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-27'; # DATE
our $DIST = 'Finance-Currency-Convert-Mandiri'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(get_currencies convert_currency);

our %STATS = (
    supported_pairs => [qw(
                              AUD/IDR IDR/AUD
                              CAD/IDR IDR/CAD
                              CHF/IDR IDR/CHF
                              CNY/IDR IDR/CNY
                              DKK/IDR IDR/DKK
                              EUR/IDR IDR/EUR
                              GBP/IDR IDR/GBP
                              HKD/IDR IDR/HKD
                              JPY/IDR IDR/JPY
                              MYR/IDR IDR/MYR
                              NOK/IDR IDR/NOK
                              NZD/IDR IDR/NZD
                              SAR/IDR IDR/SAR
                              SGD/IDR IDR/SGD
                              THB/IDR IDR/THB
                              USD/IDR IDR/USD
                      )],
);

our %SPEC;

my $url = "https://www.bankmandiri.co.id/kurs/";

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Convert currency using Bank Mandiri',
    description => <<"_",

This module can extract currency rates from the Bank Mandiri website:

    $url

Currently only conversions from a few currencies to Indonesian Rupiah (IDR) are
supported.

_
};

$SPEC{get_currencies} = {
    v => 1.1,
    summary => 'Extract data from Bank Mandiri page',
    result => {
        description => <<'_',
Will return a hash containing key `currencies`.

The currencies is a hash with currency symbols as keys and prices as values.

Tha values is a hash with these keys: `buy_bn` and `sell_bn` (Bank Note buy/sell
rates), `buy_sr` and `sell_sr` (Special Rate buy/sell rates), `buy_ttc` and
`sell_ttc` (Telegraphic Transfer Counter buy/sell rates).

_
    },
};
sub get_currencies {
    #require Mojo::DOM;
    require HTTP::Tiny::Plugin;
    require Parse::Number::ID;
    require Time::Local;

    my %args = @_;

    #return [543, "Test parse failure response"];

    my $page;
    if ($args{_page_content}) {
        $page = $args{_page_content};
    } else {
        #require Mojo::UserAgent;
        #my $ua = Mojo::UserAgent->new;
        #my $res = $ua->get($url)->result;
        #unless ($res->is_success) {
        #    return [500, "Can't retrieve URL $url: ".$res->code." - ".$res->message];
        #}
        #$page = $res->body;

        require HTTP::Tiny::Plugin;
        my @old_plugins = HTTP::Tiny::Plugin->set_plugins('NewestFirefox');
        my $res = HTTP::Tiny::Plugin->new->get($url);
        unless ($res->{success}) {
            return [500, "Can't retrieve URL $url: ".$res->{status}." - ".$res->{reason}];
        }
        $page = $res->{content};
        HTTP::Tiny::Plugin->set_plugins(@old_plugins);
    }

    #my $dom  = Mojo::DOM->new($page);

    my %currencies;

    while ($page =~ m!
                     <tr>\s*
                     <td\s*>([A-Z]{3})</td>\s*
                     <td\s*>([0-9,.]+)</td>\s*
                     <td\s*><strong>([0-9,.]+)</strong></td>\s*
                     <td\s*>([0-9,.]+)</td>\s*
                     <td\s*><strong>([0-9,.]+)</strong></td>\s*
                     <td\s*>([0-9,.]+)</td>\s*
                     <td\s*><strong>([0-9,.]+)</strong></td>\s*
                     </tr>
                     !gsx) {
        $currencies{$1} = {
            buy_sr    => Parse::Number::ID::parse_number_id(text=>$2),
            sell_sr   => Parse::Number::ID::parse_number_id(text=>$3),
            buy_ttc   => Parse::Number::ID::parse_number_id(text=>$4),
            sell_ttc  => Parse::Number::ID::parse_number_id(text=>$5),
            buy_bn    => Parse::Number::ID::parse_number_id(text=>$6),
            sell_bn   => Parse::Number::ID::parse_number_id(text=>$7),
        };
    }

    if (keys %currencies < 3) {
        return [543, "Check: no/too few currencies found"];
    }

    my ($mtime, $mtime_sr, $mtime_ttc, $mtime_bn);
  GET_MTIME_SR:
    {
        unless ($page =~ m!<strong>Special Rate\*?</strong>\s*<br/>\s*((\d+)/(\d+)/(\d{2}) - (\d+):(\d+) WIB)\s*</th>!s) {
            log_warn "Cannot extract last update time for Special Rate";
            last;
        }
        $mtime_sr = Time::Local::timegm(0, $6, $5, $2, $3-1, $4+2000) - 7*3600;
    }
  GET_MTIME_TTC:
    {
        unless ($page =~ m!<strong>TT Counter\*?</strong>\s*<br/>\s*((\d+)/(\d+)/(\d{2}) - (\d+):(\d+) WIB)\s*</th>!s) {
            log_warn "Cannot extract last update time for TT Counter";
            last;
        }
        $mtime_ttc = Time::Local::timegm(0, $6, $5, $2, $3-1, $4+2000) - 7*3600;
    }
  GET_MTIME_BN:
    {
        unless ($page =~ m!<strong>Bank Notes\*?</strong>\s*<br/>\s*((\d+)/(\d+)/(\d{2}) - (\d+):(\d+) WIB)\s*</th>!) {
            log_warn "Cannot extract last update time for Bank Notes";
            last;
        }
        $mtime_bn = Time::Local::timegm(0, $6, $5, $2, $3-1, $4+2000) - 7*3600;
    }

    $mtime = min(grep {defined} ($mtime_sr, $mtime_ttc, $mtime_bn));

    [200, "OK", {
        mtime => $mtime,
        mtime_sr => $mtime_sr,
        mtime_ttc => $mtime_ttc,
        mtime_bn => $mtime_bn,
        currencies => \%currencies,
    }];
}

# used for testing only
our $_get_res;

$SPEC{convert_currency} = {
    v => 1.1,
    summary => 'Convert currency using Bank Mandiri',
    description => <<'_',

Currently can only handle conversion `to` IDR. Dies if given other currency.

Will warn if failed getting currencies from the webpage.

Currency rate is not cached (retrieved from the website every time). Employ your
own caching.

Will return undef if no conversion rate is available for the requested currency.

Use `get_currencies()`, which actually retrieves and scrapes the source web
page, if you need the more complete result.

_
    args => {
        n => {
            schema=>'float*',
            req => 1,
            pos => 0,
        },
        from => {
            schema=>'str*',
            req => 1,
            pos => 1,
        },
        to => {
            schema=>'str*',
            req => 1,
            pos => 2,
        },
        which => {
            summary => 'Select which rate to use (default is average buy+sell for e-Rate)',
            schema => ['str*', in=>[map { my $bsa = $_; map {"${bsa}_$_"} qw(bn sr ttc) } qw(buy sell avg)]],
            description => <<'_',

{buy,sell,avg}_{bn,er,ttc}.

_
            default => 'avg_sr',
            pos => 3,
        },
    },
    args_as => 'array',
    result_naked => 1,
};
sub convert_currency {
    my ($n, $from, $to, $which) = @_;

    $which //= 'avg_sr';

    if (uc($to) ne 'IDR') {
        die "Currently only conversion to IDR is supported".
            " (you asked for conversion to '$to')\n";
    }

    unless ($_get_res) {
        $_get_res = get_currencies();
        unless ($_get_res->[0] == 200) {
            warn "Can't get currencies: $_get_res->[0] - $_get_res->[1]\n";
            return;
        }
    }

    my $c = $_get_res->[2]{currencies}{uc $from} or return;

    my $rate;
    if ($which =~ /\Aavg_(.+)/) {
        $rate = ($c->{"buy_$1"} + $c->{"sell_$1"}) / 2;
    } else {
        $rate = $c->{$which};
    }

    $n * $rate;
}

1;
# ABSTRACT: Convert currency using Bank Mandiri

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::Convert::Mandiri - Convert currency using Bank Mandiri

=head1 VERSION

This document describes version 0.002 of Finance::Currency::Convert::Mandiri (from Perl distribution Finance-Currency-Convert-Mandiri), released on 2022-02-27.

=head1 SYNOPSIS

 use Finance::Currency::Convert::Mandiri qw(convert_currency);

 printf "1 USD = Rp %.0f\n", convert_currency(1, 'USD', 'IDR');

=head1 DESCRIPTION


This module can extract currency rates from the Bank Mandiri website:

 https://www.bankmandiri.co.id/kurs/

Currently only conversions from a few currencies to Indonesian Rupiah (IDR) are
supported.

=head1 CURRENCY MODULE STATISTICS

Supported pairs:

                              AUD/IDR IDR/AUD
                              CAD/IDR IDR/CAD
                              CHF/IDR IDR/CHF
                              CNY/IDR IDR/CNY
                              DKK/IDR IDR/DKK
                              EUR/IDR IDR/EUR
                              GBP/IDR IDR/GBP
                              HKD/IDR IDR/HKD
                              JPY/IDR IDR/JPY
                              MYR/IDR IDR/MYR
                              NOK/IDR IDR/NOK
                              NZD/IDR IDR/NZD
                              SAR/IDR IDR/SAR
                              SGD/IDR IDR/SGD
                              THB/IDR IDR/THB
                              USD/IDR IDR/USD

=head1 FUNCTIONS


=head2 convert_currency

Usage:

 convert_currency($n, $from, $to, $which) -> any

Convert currency using Bank Mandiri.

Currently can only handle conversion C<to> IDR. Dies if given other currency.

Will warn if failed getting currencies from the webpage.

Currency rate is not cached (retrieved from the website every time). Employ your
own caching.

Will return undef if no conversion rate is available for the requested currency.

Use C<get_currencies()>, which actually retrieves and scrapes the source web
page, if you need the more complete result.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$from>* => I<str>

=item * B<$n>* => I<float>

=item * B<$to>* => I<str>

=item * B<$which> => I<str> (default: "avg_sr")

Select which rate to use (default is average buy+sell for e-Rate).

{buy,sell,avg}_{bn,er,ttc}.


=back

Return value:  (any)



=head2 get_currencies

Usage:

 get_currencies() -> [$status_code, $reason, $payload, \%result_meta]

Extract data from Bank Mandiri page.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)


Will return a hash containing key C<currencies>.

The currencies is a hash with currency symbols as keys and prices as values.

Tha values is a hash with these keys: C<buy_bn> and C<sell_bn> (Bank Note buy/sell
rates), C<buy_sr> and C<sell_sr> (Special Rate buy/sell rates), C<buy_ttc> and
C<sell_ttc> (Telegraphic Transfer Counter buy/sell rates).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Currency-Convert-Mandiri>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-Currency-Convert-Mandiri>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Currency-Convert-Mandiri>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
