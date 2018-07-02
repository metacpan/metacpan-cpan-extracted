package Finance::Currency::Convert::BCA;

our $DATE = '2018-06-27'; # DATE
our $VERSION = '0.152'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use List::Util qw(min);

use Exporter 'import';
our @EXPORT_OK = qw(get_currencies convert_currency);

our %SPEC;

my $url = "https://www.bca.co.id/id/Individu/Sarana/Kurs-dan-Suku-Bunga/Kurs-dan-Kalkulator";

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
        my $tx = $ua->get($url);
        unless ($tx->success) {
            my $err = $tx->error;
            return [500, "Can't retrieve BCA page ($url): $err->{message}"];
        }
        $page = $tx->res->body;
    }

    my $dom  = Mojo::DOM->new($page);

    my %currencies;
    my $tbody = $dom->find("tbody.text-right")->[0];
    $tbody->find("tr")->each(
        sub {
            my $row0 = shift;
            my $row = $row0->find("td")->map(
                sub { $_->text })->to_array;
            #use DD; dd $row;
            next unless $row->[0] =~ /\A[A-Z]{3}\z/;
            $currencies{$row->[0]} = {
                sell_er  => Parse::Number::ID::parse_number_id(text=>$row->[1]),
                buy_er   => Parse::Number::ID::parse_number_id(text=>$row->[2]),
                sell_ttc => Parse::Number::ID::parse_number_id(text=>$row->[3]),
                buy_ttc  => Parse::Number::ID::parse_number_id(text=>$row->[4]),
                sell_bn  => Parse::Number::ID::parse_number_id(text=>$row->[5]),
                buy_bn   => Parse::Number::ID::parse_number_id(text=>$row->[6]),
            };
        }
    );

    if (keys %currencies < 3) {
        return [543, "Check: no/too few currencies found"];
    }

    my ($mtime, $mtime_er, $mtime_ttc, $mtime_bn);
  GET_MTIME_ER:
    {
        unless ($page =~ m!<th[^>]*>e-Rate\*?<br />((\d+) (\w+) (\d{4}) / (\d+):(\d+) WIB)</th>!) {
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
        unless ($page =~ m!<th[^>]*>TT Counter\*?<br />((\d+) (\w+) (\d{4}) / (\d+):(\d+) WIB)</th>!) {
            log_warn "Cannot extract last update time for TT Counter";
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
        unless ($page =~ m!<th[^>]*>Bank Notes\*?<br />((\d+) (\w+) (\d{4}) / (\d+):(\d+) WIB)</th>!) {
            log_warn "Cannot extract last update time for Bank Note";
            last;
        }
        my $mon = Parse::Date::Month::ID::parse_date_month_id(text=>$3) or do {
            log_warn "Cannot recognize month name '$3' in last update time '$1'";
            last;
        };
        $mtime_bn = Time::Local::timegm(0, $6, $5, $2, $mon-1, $4) - 7*3600;
    }

    $mtime = min(grep {defined} ($mtime_er, $mtime_ttc, $mtime_bn));

    # XXX parse update dates (mtime_er, mtime_ttc, mtime_bn)
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
            return undef;
        }
    }

    my $c = $_get_res->[2]{currencies}{uc $from} or return undef;

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

This document describes version 0.152 of Finance::Currency::Convert::BCA (from Perl distribution Finance-Currency-Convert-BCA), released on 2018-06-27.

=head1 SYNOPSIS

 use Finance::Currency::Convert::BCA qw(convert_currency);

 printf "1 USD = Rp %.0f\n", convert_currency(1, 'USD', 'IDR');

=head1 DESCRIPTION


This module can extract currency rates from the BCA/KlikBCA (Bank Central Asia's
internet banking) website:

 https://www.bca.co.id/id/Individu/Sarana/Kurs-dan-Suku-Bunga/Kurs-dan-Kalkulator

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

 get_currencies() -> [status, msg, result, meta]

Extract data from KlikBCA/BCA page.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Currency-Convert-BCA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
