package Finance::Currency::Convert::GMC;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
our @EXPORT_OK = qw(get_currencies convert_currency);

our %SPEC;

my $url = "https://www.gmc.co.id/";

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Convert currency using GMC (Golden Money Changer) website',
    description => <<"_",

This module can extract currency rates from the Golden Money Changer website:

    $url

Currently only conversions from a few currencies to Indonesian Rupiah (IDR) are
available.

_
};

$SPEC{get_currencies} = {
    v => 1.1,
    summary => 'Extract data from GMC page',
    result => {
        description => <<'_',
Will return a hash containing key `currencies`.

The currencies is a hash with currency symbols as keys and prices as values.

Tha values is a hash with these keys: `buy` and `sell`.

_
    },
};
sub get_currencies {
    require Mojo::DOM;
    #require Parse::Number::ID;
    require Parse::Number::EN;

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
            return [500, "Can't retrieve GMC page ($url): ".
                        "$err->{code} - $err->{message}"];
        }
        $page = $tx->res->body;
    }

    my $dom  = Mojo::DOM->new($page);

    my %currencies;
    my $tbody = $dom->find("table#rate-table tbody")->[0];
    $tbody->find("tr")->each(
        sub {
            my $row0 = shift;
            my $row = $row0->find("td")->map(
                sub { $_->text })->to_array;
            #use DD; dd $row;
            next unless $row->[0] =~ /\A[A-Z]{3}\z/;
            $currencies{$row->[0]} = {
                buy  => Parse::Number::EN::parse_number_en(text=>$row->[1]),
                sell => Parse::Number::EN::parse_number_en(text=>$row->[2]),
            };
        }
    );

    if (keys %currencies < 3) {
        return [543, "Check: no/too few currencies found"];
    }

    # XXX parse update dates (mtime_er, mtime_ttc, mtime_bn)
    [200, "OK", {currencies=>\%currencies}];
}

# used for testing only
our $_get_res;

$SPEC{convert_currency} = {
    v => 1.1,
    summary => 'Convert currency using GMC',
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
            summary => 'Select which rate to use (default is `sell`)',
            schema => ['str*', in=>['buy', 'sell']],
            default => 'sell',
            pos => 3,
        },
    },
    args_as => 'array',
    result_naked => 1,
};
sub convert_currency {
    my ($n, $from, $to, $which) = @_;

    $which //= 'sell';

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
    #if ($which =~ /\Aavg_(.+)/) {
    #    $rate = ($c->{"buy_$1"} + $c->{"sell_$1"}) / 2;
    #} else {
    $rate = $c->{$which};
    #}

    $n * $rate;
}

1;
# ABSTRACT: Convert currency using GMC (Golden Money Changer) website

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::Convert::GMC - Convert currency using GMC (Golden Money Changer) website

=head1 VERSION

This document describes version 0.003 of Finance::Currency::Convert::GMC (from Perl distribution Finance-Currency-Convert-GMC), released on 2017-07-10.

=head1 SYNOPSIS

 use Finance::Currency::Convert::GMC qw(convert_currency);

 printf "1 USD = Rp %.0f\n", convert_currency(1, 'USD', 'IDR');

=head1 DESCRIPTION


This module can extract currency rates from the Golden Money Changer website:

 https://www.gmc.co.id/

Currently only conversions from a few currencies to Indonesian Rupiah (IDR) are
available.

=head1 FUNCTIONS


=head2 convert_currency

Usage:

 convert_currency($n, $from, $to, $which) -> any

Convert currency using GMC.

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

=item * B<$which> => I<str> (default: "sell")

Select which rate to use (default is `sell`).

=back

Return value:  (any)


=head2 get_currencies

Usage:

 get_currencies() -> [status, msg, result, meta]

Extract data from GMC page.

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

Tha values is a hash with these keys: C<buy> and C<sell>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Currency-Convert-GMC>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-Currency-Convert-GMC>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Currency-Convert-GMC>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
