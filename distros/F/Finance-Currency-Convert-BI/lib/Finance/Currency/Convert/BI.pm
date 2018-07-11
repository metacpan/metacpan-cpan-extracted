package Finance::Currency::Convert::BI;

our $DATE = '2018-07-10'; # DATE
our $VERSION = '0.063'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use DateTime::Format::Indonesian;
use Parse::Number::ID qw(parse_number_id);

use Exporter::Rinci qw(import);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Get/convert currencies from website of Indonesian Central Bank (BI)',
};

$SPEC{get_jisdor_rates} = {
    v => 1.1,
    summary => 'Get JISDOR USD-IDR rates',
    description => <<'_',
_
    args => {
        from_date => {
            schema => 'date*',
        },
        to_date => {
            schema => 'date*',
        },
    },
};
sub get_jisdor_rates {
    my %args = @_;

    #return [543, "Test parse failure response"];

    my $page;
    if ($args{_page_content}) {
        $page = $args{_page_content};
    } else {
        require Mojo::UserAgent;
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->get("https://www.bi.go.id/id/moneter/informasi-kurs/referensi-jisdor/Default.aspx",
                      {'User-Agent' => 'Mozilla/4.0'});
        my $res = $tx->success;
        if ($res) {
            $page = $res->body;
        } else {
            my $err = $tx->error;
            return [500, "Can't retrieve BI page: $err->{message}"];
        }
    }

    # XXX submit form if we want to set from_date & to_date

    my @res;
    {
        my ($table) = $page =~ m!<table class="table1">(.+?)</table>!s
            or return [543, "Can't extract data table (table1)"];
        while ($table =~ m!<tr>\s*<td>\s*(.+?)\s*</td>\s*<td>\s*(.+?)\s*</td>!gs) {
            my $date = eval { DateTime::Format::Indonesian->parse_datetime($1) };
            $@ and return [543, "Can't parse date '$1'"];
            my $rate = parse_number_id(text=>$2);
            push @res, {date=>$date->ymd, rate=>$rate};
        }
    }
    [200, "OK", \@res];
}

$SPEC{get_currencies} = {
    v => 1.1,
    summary => "Extract currency data from Bank Indonesia's page",
    result => {
        description => <<'_',

Will return a hash containing key `currencies`.

The currencies is a hash with currency symbols as keys and prices as values.

Tha values is a hash with these keys: `buy` and `sell`.

_
    },
};
sub get_currencies {
    #require Mojo::DOM;
    require Parse::Date::Month::ID;
    require Parse::Number::EN;
    #require Parse::Number::ID;
    require Time::Local;

    my %args = @_;

    #return [543, "Test parse failure response"];

    my $url = "https://www.bi.go.id/id/moneter/informasi-kurs/transaksi-bi/Default.aspx";

    my $page;
    if ($args{_page_content}) {
        $page = $args{_page_content};
    } else {
        require Mojo::UserAgent;
        my $ua = Mojo::UserAgent->new;
        $ua->transactor->name("Mozilla/4.0");
        my $tx = $ua->get($url);
        unless ($tx->success) {
            my $err = $tx->error;
            return [500, "Can't retrieve BCA page ($url): ".
                        "$err->{code} - $err->{message}"];
        }
        $page = $tx->res->body;
    }

    my %currencies;
    my @recs;
    while ($page =~ m!<td>(\w{3})  </td><td class="alignRight">(\d(?:\.\d+)?)</td><td style="text-align:right;">($Parse::Number::EN::Pat)</td><td style="text-align:right;">($Parse::Number::EN::Pat)</td>!g) {
        push @recs, [$1, $2, $3, $4];
    }

    for (@recs) {
        my $mult = Parse::Number::EN::parse_number_en(text => $_->[1])
            or return [543, "Can't parse number '$_->[1]'"];
        my $sell = Parse::Number::EN::parse_number_en(text => $_->[2])
            or return [543, "Can't parse number '$_->[2]'"];
        my $buy  = Parse::Number::EN::parse_number_en(text => $_->[3])
            or return [543, "Can't parse number '$_->[3]'"];
        $currencies{$_->[0]} = {
            sell => $sell / $mult,
            buy =>  $buy  / $mult,
        };
    }

    if (keys %currencies < 3) {
        return [543, "Check: no/too few currencies found"];
    }

    my $mtime;
  GET_MTIME:
    {
        unless ($page =~ m!Update Terakhir.+>((\d+) (\w+) (\d{4}))<!) {
            log_warn "Cannot extract last update time";
            last;
        }
        my $mon = Parse::Date::Month::ID::parse_date_month_id(text=>$3) or do {
            log_warn "Cannot recognize month name '$3' in last update time '$1'";
            last;
        };
        $mtime = Time::Local::timegm(0, 0, 0, $2, $mon-1, $4) - 7*3600;
    }

    [200, "OK", {
        mtime => $mtime,
        currencies => \%currencies,
    }];
}

1;
# ABSTRACT: Get/convert currencies from website of Indonesian Central Bank (BI)

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::Convert::BI - Get/convert currencies from website of Indonesian Central Bank (BI)

=head1 VERSION

This document describes version 0.063 of Finance::Currency::Convert::BI (from Perl distribution Finance-Currency-Convert-BI), released on 2018-07-10.

=head1 SYNOPSIS

 use Finance::Currency::Convert::BI qw(get_currencies get_jisdor_rates);

 my $res = get_jisdor_rates();

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 get_currencies

Usage:

 get_currencies() -> [status, msg, result, meta]

Extract currency data from Bank Indonesia's page.

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


=head2 get_jisdor_rates

Usage:

 get_jisdor_rates(%args) -> [status, msg, result, meta]

Get JISDOR USD-IDR rates.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<from_date> => I<date>

=item * B<to_date> => I<date>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Currency-Convert-BI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-Currency-Convert-BI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Currency-Convert-BI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<http://www.bi.go.id/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
