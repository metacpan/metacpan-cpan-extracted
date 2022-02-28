package Finance::Currency::Convert::BCA;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use List::Util qw(min);

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-26'; # DATE
our $DIST = 'Finance-Currency-Convert-BCA'; # DIST
our $VERSION = '0.156'; # VERSION

our @EXPORT_OK = qw(get_currencies convert_currency);

our %SPEC;

my $url = "https://www.bca.co.id/en/informasi/kurs?";

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Convert currency using BCA (Bank Central Asia)',
    description => <<"_",

This module can extract currency rates from the BCA/KlikBCA (Bank Central Asia's
internet banking) website:

    $url

Currently only conversions from a few currencies to Indonesian Rupiah (IDR) are
supported.

_
};

$SPEC{get_currencies} = {
    v => 1.1,
    summary => 'Extract data from KlikBCA/BCA page',
    result => {
        description => <<'_',
Will return a hash containing key `currencies`.

The currencies is a hash with currency symbols as keys and prices as values.

Tha values is a hash with these keys: `buy_bn` and `sell_bn` (Bank Note buy/sell
rates), `buy_er` and `sell_er` (e-Rate buy/sell rates), `buy_ttc` and `sell_ttc`
(Telegraphic Transfer Counter buy/sell rates).

_
    },
};
sub get_currencies {
    require Mojo::DOM;
    require Parse::Date::Month::ID;
    require Parse::Number::ID;
    require Time::Local;

    my %args = @_;

    #return [543, "Test parse failure response"];

    my $page;
    if ($args{_page_content}) {
        $page = $args{_page_content};
    } else {
        require Mojo::UserAgent;
        my $ua = Mojo::UserAgent->new;
        my $res = $ua->get($url)->result;
        unless ($res->is_success) {
            return [500, "Can't retrieve URL $url: ".$res->code." - ".$res->message];
        }
        $page = $res->body;
    }

    #my $dom  = Mojo::DOM->new($page);

    my %currencies;
    while ($page =~ m!<tr code="(\w{3})">!g) {
        $currencies{$1} //= {};
    }
    if (keys %currencies < 3) {
        return [543, "Check: no/too few currencies (".scalar(keys %currencies).") found"];
    }

    for my $currency (keys %currencies) {
        my ($tr) = $page =~ m!<tr code="$currency">(.+?)</tr>!s;
        $tr =~ m!<p[^>]*rate-type="ERate-sell">([0-9,.]+)</p>!
            and defined($currencies{$currency}{sell_er} = Parse::Number::ID::parse_number_id(text=>$1))
            or return [543, "Can't extract sell_er rate for $currency"];
        $tr =~ m!<p[^>]*rate-type="ERate-buy">([0-9,.]+)</p>!
            and defined($currencies{$currency}{buy_er} = Parse::Number::ID::parse_number_id(text=>$1))
            or return [543, "Can't extract buy_er rate for $currency"];

        $tr =~ m!<p[^>]*rate-type="TT-sell">([0-9,.]+)</p>!
            and defined($currencies{$currency}{sell_ttc} = Parse::Number::ID::parse_number_id(text=>$1))
            or return [543, "Can't extract sell_ttc rate for $currency"];
        $tr =~ m!<p[^>]*rate-type="TT-buy">([0-9,.]+)</p>!
            and defined($currencies{$currency}{buy_ttc} = Parse::Number::ID::parse_number_id(text=>$1))
            or return [543, "Can't extract buy_ttc rate for $currency"];

        $tr =~ m!<p[^>]*rate-type="BN-sell">([0-9,.]+)</p>!
            and defined($currencies{$currency}{sell_bn} = Parse::Number::ID::parse_number_id(text=>$1))
            or return [543, "Can't extract sell_bn rate for $currency"];
        $tr =~ m!<p[^>]*rate-type="BN-buy">([0-9,.]+)</p>!
            and defined($currencies{$currency}{buy_bn} = Parse::Number::ID::parse_number_id(text=>$1))
            or return [543, "Can't extract buy_bn rate for $currency"];
    }

    my ($mtime, $mtime_er, $mtime_ttc, $mtime_bn);
  GET_MTIME_ER:
    {
        unless ($page =~ m!e-Rate <br /><span[^>]+>((\d+) (\w+) (\d{4}) / (\d+):(\d+) WIB)</span>!) {
            log_warn "Cannot extract last update time for e-Rate";
            last;
        }
        my $mon = Parse::Date::Month::ID::parse_date_month_id(text=>$3) or do {
            log_warn "Cannot recognize month name '$3' in last update time '$1'";
            last;
        };
        $mtime_er = Time::Local::timegm(0, $6, $5, $2, $mon-1, $4) - 7*3600;
    }
  GET_MTIME_TTC:
    {
        unless ($page =~ m!TT Counter <br /><span[^>]+>((\d+) (\w+) (\d{4}) / (\d+):(\d+) WIB)</span>!) {
            log_warn "Cannot extract last update time for TT";
            last;
        }
        my $mon = Parse::Date::Month::ID::parse_date_month_id(text=>$3) or do {
            log_warn "Cannot recognize month name '$3' in last update time '$1'";
            last;
        };
        $mtime_ttc = Time::Local::timegm(0, $6, $5, $2, $mon-1, $4) - 7*3600;
    }
  GET_MTIME_BN:
    {
        unless ($page =~ m!Bank Notes <br /><span[^>]+>((\d+) (\w+) (\d{4}) / (\d+):(\d+) WIB)</span>!) {
            log_warn "Cannot extract last update time for BN";
            last;
        }
        my $mon = Parse::Date::Month::ID::parse_date_month_id(text=>$3) or do {
            log_warn "Cannot recognize month name '$3' in last update time '$1'";
            last;
        };
        $mtime_bn = Time::Local::timegm(0, $6, $5, $2, $mon-1, $4) - 7*3600;
    }

    $mtime = min(grep {defined} ($mtime_er, $mtime_ttc, $mtime_bn));

    [200, "OK", {
        mtime => $mtime,
        mtime_er => $mtime_er,
        mtime_ttc => $mtime_ttc,
        mtime_bn => $mtime_bn,
        currencies => \%currencies,
    }];
}

# used for testing only
our $_get_res;

$SPEC{convert_currency} = {
    v => 1.1,
    summary => 'Convert currency using BCA',
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
            schema => ['str*', in=>[map { my $bsa = $_; map {"${bsa}_$_"} qw(bn er ttc) } qw(buy sell avg)]],
            description => <<'_',

{buy,sell,avg}_{bn,er,ttc}.

_
            default => 'avg_er',
            pos => 3,
        },
    },
    args_as => 'array',
    result_naked => 1,
};
sub convert_currency {
    my ($n, $from, $to, $which) = @_;

    $which //= 'avg_er';

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
# ABSTRACT: Convert currency using BCA (Bank Central Asia)

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::Convert::BCA - Convert currency using BCA (Bank Central Asia)

=head1 VERSION

This document describes version 0.156 of Finance::Currency::Convert::BCA (from Perl distribution Finance-Currency-Convert-BCA), released on 2022-02-26.

=head1 SYNOPSIS

 use Finance::Currency::Convert::BCA qw(convert_currency);

 printf "1 USD = Rp %.0f\n", convert_currency(1, 'USD', 'IDR');

=head1 DESCRIPTION


This module can extract currency rates from the BCA/KlikBCA (Bank Central Asia's
internet banking) website:

 https://www.bca.co.id/en/informasi/kurs?

Currently only conversions from a few currencies to Indonesian Rupiah (IDR) are
supported.

=head1 FUNCTIONS


=head2 convert_currency

Usage:

 convert_currency($n, $from, $to, $which) -> any

Convert currency using BCA.

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

=item * B<$which> => I<str> (default: "avg_er")

Select which rate to use (default is average buy+sell for e-Rate).

{buy,sell,avg}_{bn,er,ttc}.


=back

Return value:  (any)



=head2 get_currencies

Usage:

 get_currencies() -> [$status_code, $reason, $payload, \%result_meta]

Extract data from KlikBCAE<sol>BCA page.

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
rates), C<buy_er> and C<sell_er> (e-Rate buy/sell rates), C<buy_ttc> and C<sell_ttc>
(Telegraphic Transfer Counter buy/sell rates).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Currency-Convert-BCA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-Currency-Convert-BCA>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2022, 2021, 2018, 2017, 2016, 2015, 2014, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Currency-Convert-BCA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
