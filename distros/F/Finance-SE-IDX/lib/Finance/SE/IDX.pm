package Finance::SE::IDX;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-17'; # DATE
our $DIST = 'Finance-SE-IDX'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       list_idx_boards
                       list_idx_brokers
                       list_idx_firms
                       list_idx_sectors
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Get information from Indonesian Stock Exchange',
};

my $urlprefix = "https://www.idx.co.id/umbraco/Surface/";

sub _get_json {
    require HTTP::Tiny::Cache;

    my $url = shift;

    my $res = HTTP::Tiny::Cache->new->get($url);
    return [$res->{status}, $res->{reason}] unless $res->{status} == 200;
    require JSON::MaybeXS;
    [200, "OK", JSON::MaybeXS::decode_json($res->{content})];
}

#sub _get_json_with_lwp {
#    state $ua = do { require LWP::UserAgent::Plugin; LWP::UserAgent::Plugin->new };
#
#    my $url = shift;
#
#    my $res = $ua->get($url);
#    return [$res->code, $res->message] unless $res->is_success;
#    require JSON::MaybeXS;
#    [200, "OK", JSON::MaybeXS::decode_json($res->content)];
#}

sub _get_json_with_curl {
    require HTTP::Tinyish;
    local $HTTP::Tinyish::PreferredBackend = 'HTTP::Tinyish::Curl';

    my $url = shift;

    my $res = HTTP::Tinyish->new->get($url);
    return [$res->{status}, $res->{reason}] unless $res->{status} == 200;
    require JSON::MaybeXS;
    [200, "OK", JSON::MaybeXS::decode_json($res->{content})];
}

$SPEC{list_idx_sectors} = {
    v => 1.1,
    summary => 'List sectors',
    description => <<'_',

By default caches results for 8 hours (by locally setting CACHE_MAX_AGE). Can be
overriden by using HTTP_TINY_CACHE_MAX_AGE.

_
    args => {
    },
};
sub list_idx_sectors {
    local $ENV{CACHE_MAX_AGE} = 8*3600;
    _get_json("${urlprefix}Helper/GetSectors");
}

$SPEC{list_idx_boards} = {
    v => 1.1,
    summary => 'List boards',
    description => <<'_',

By default caches results for 8 hours (by locally setting CACHE_MAX_AGE). Can be
overriden by using HTTP_TINY_CACHE_MAX_AGE.

_
    args => {
    },
};
sub list_idx_boards {
    local $ENV{CACHE_MAX_AGE} = 8*3600;
    my $res = _get_json("${urlprefix}Helper/GetBoards");
    return $res unless $res->[0] == 200;
    $res->[2] = [grep {$_ ne ''} @{ $res->[2] }];
    $res;
}

$SPEC{list_idx_firms} = {
    v => 1.1,
    summary => 'List firms',
    description => <<'_',

By default caches results for 8 hours (by locally setting CACHE_MAX_AGE). Can be
overriden by using HTTP_TINY_CACHE_MAX_AGE.

_
    args => {
        board => {
            schema => ['str*', match=>qr/\A\w+\z/],
            tags => ['category:filtering'],
        },
        sector => {
            schema => ['str*', match=>qr/\A[\w-]+\z/],
            tags => ['category:filtering'],
        },
    },
};
sub list_idx_firms {
    local $ENV{CACHE_MAX_AGE} = 8*3600;
    my %args = @_;

    my $sector = $args{sector} // '';
    my $board  = $args{board} // '';

    my @rows;

    # there's a hard limit of 150, let's be nice and ask 100 at a time
    my $start = 0;
    while (1) {
        my $res = _get_json("${urlprefix}StockData/GetSecuritiesStock?code=&sector=$sector&board=$board&draw=3&columns[0][data]=Code&columns[0][name]=&columns[0][searchable]=true&columns[0][orderable]=false&columns[0][search][value]=&columns[0][search][regex]=false&columns[1][data]=Code&columns[1][name]=&columns[1][searchable]=true&columns[1][orderable]=false&columns[1][search][value]=&columns[1][search][regex]=false&columns[2][data]=Name&columns[2][name]=&columns[2][searchable]=true&columns[2][orderable]=false&columns[2][search][value]=&columns[2][search][regex]=false&columns[3][data]=ListingDate&columns[3][name]=&columns[3][searchable]=true&columns[3][orderable]=false&columns[3][search][value]=&columns[3][search][regex]=false&columns[4][data]=Shares&columns[4][name]=&columns[4][searchable]=true&columns[4][orderable]=false&columns[4][search][value]=&columns[4][search][regex]=false&columns[5][data]=ListingBoard&columns[5][name]=&columns[5][searchable]=true&columns[5][orderable]=false&columns[5][search][value]=&columns[5][search][regex]=false&start=$start&length=100&search[value]=&search[regex]=false");
        return $res unless $res->[0] == 200;
        for my $row0 (@{ $res->[2]{data} }) {
            my $listing_date = $row0->{ListingDate}; $listing_date =~ s/T.+//;
            my $row = {
                code  => $row0->{Code},
                name  => $row0->{Name},
                listing_date => $listing_date,
                shares => $row0->{Shares},
                board => $row0->{ListingBoard},
            };
            push @rows, $row;
        }
        if (@{ $res->[2]{data} } == 100) {
            $start += 100;
            next;
        } else {
            last;
        }
    }
    [200, "OK", \@rows, {'table.fields'=>[qw/code name listing_date shares board/]}];
}

$SPEC{list_idx_brokers} = {
    v => 1.1,
    summary => 'List brokers',
    description => <<'_',

By default caches results for 8 hours (by locally setting CACHE_MAX_AGE). Can be
overriden by using HTTP_TINY_CACHE_MAX_AGE.

_
    args => {
    },
};
sub list_idx_brokers {
    local $ENV{CACHE_MAX_AGE} = 8*3600;
    my %args = @_;

    my @rows;

    # like in firms, there's probably a hard limit of 150, let's be nice and ask
    # 100 at a time
    my $start = 0;
    while (1) {
        my $res = _get_json("${urlprefix}ExchangeMember/GetBroker?start=$start&length=100");
        return $res unless $res->[0] == 200;
        for my $row0 (@{ $res->[2]{data} }) {
            my $row = {
                code        => $row0->{Code},
                name        => $row0->{Name},
                license     => $row0->{License},
                status_name => $row0->{StatusName},
                city        => $row0->{City},
            };
            push @rows, $row;
        }
        if (@{ $res->[2]{data} } == 100) {
            $start += 100;
            next;
        } else {
            last;
        }
    }
    [200, "OK", \@rows, {'table.fields'=>[qw/code name license status_name city/]}];
}

$SPEC{get_idx_daily_trading_summary} = {
    v => 1.1,
    summary => 'Get daily trading summary',
    description => <<'_',

This will retrieve end-of-day data for a single trading day, containing list of
stock names along with their opening price, closing price, highest price, lowest
price, volume, frequency, foreign buy & sell volume, etc.

To specify date you can either specify `date` (epoch, or YYYY-MM-DD string in
command-line, which will be coerced to epoch) or `day`, `month`, `year`.

The data for still-trading current day will not be available, so if you are
looking for intraday data, this is not it.

At the time of this writing (2021-01-17), the data goes back to Jan 1st, 2015.
If you are looking for older data, you can visit one of the financial data
websites like Bloomberg.

_
    args => {
        date   => {schema => 'date*', pos=>0},
        day    => {schema => ['int*', between=>[1,31]]},
        month  => {schema => ['int*', between=>[1,12]]},
        year   => {schema => ['int*', between=>[1990,2100]]},
    },
    args_rels => {
        req_one => [qw/date day/],
        choose_all => [qw/day month year/],
    },
};
sub get_idx_daily_trading_summary {
    local $ENV{CACHE_MAX_AGE} = 8*3600;
    my %args = @_;

    my $date;
    if ($args{day}) {
        $date = sprintf("%04d%02d%02d", $args{year}, $args{month}, $args{day});
    } else {
        my @lt = localtime($args{date});
        $date = sprintf("%04d%02d%02d", $lt[5]+1900, $lt[4]+1, $lt[3]);
    }

    # currently we request 1000 data. when stocks exceed 1000, we will need to
    # do some paging. we use Curl backend because both HTTP::Tiny & LWP don't
    # seem to like long request URL.

    my $res = _get_json_with_curl("${urlprefix}TradingSummary/GetStockSummary?date=$date&start=0&length=1000&draw=6&columns[0][data]=StockCode&columns[0][name]=&columns[0][searchable]=true&columns[0][orderable]=false&columns[0][search][value]=&columns[0][search][regex]=false&columns[1][data]=StockCode&columns[1][name]=&columns[1][searchable]=true&columns[1][orderable]=false&columns[1][search][value]=&columns[1][search][regex]=false&columns[2][data]=StockName&columns[2][name]=&columns[2][searchable]=true&columns[2][orderable]=false&columns[2][search][value]=&columns[2][search][regex]=false&columns[3][data]=Remarks&columns[3][name]=&columns[3][searchable]=true&columns[3][orderable]=false&columns[3][search][value]=&columns[3][search][regex]=false&columns[4][data]=Previous&columns[4][name]=&columns[4][searchable]=true&columns[4][orderable]=false&columns[4][search][value]=&columns[4][search][regex]=false&columns[5][data]=OpenPrice&columns[5][name]=&columns[5][searchable]=true&columns[5][orderable]=false&columns[5][search][value]=&columns[5][search][regex]=false&columns[6][data]=FirstTrade&columns[6][name]=&columns[6][searchable]=true&columns[6][orderable]=false&columns[6][search][value]=&columns[6][search][regex]=false&columns[7][data]=High&columns[7][name]=&columns[7][searchable]=true&columns[7][orderable]=false&columns[7][search][value]=&columns[7][search][regex]=false&columns[8][data]=Low&columns[8][name]=&columns[8][searchable]=true&columns[8][orderable]=false&columns[8][search][value]=&columns[8][search][regex]=false&columns[9][data]=Close&columns[9][name]=&columns[9][searchable]=true&columns[9][orderable]=false&columns[9][search][value]=&columns[9][search][regex]=false&columns[10][data]=Change&columns[10][name]=&columns[10][searchable]=true&columns[10][orderable]=false&columns[10][search][value]=&columns[10][search][regex]=false&columns[11][data]=Volume&columns[11][name]=&columns[11][searchable]=true&columns[11][orderable]=false&columns[11][search][value]=&columns[11][search][regex]=false&columns[12][data]=Value&columns[12][name]=&columns[12][searchable]=true&columns[12][orderable]=false&columns[12][search][value]=&columns[12][search][regex]=false&columns[13][data]=Frequency&columns[13][name]=&columns[13][searchable]=true&columns[13][orderable]=false&columns[13][search][value]=&columns[13][search][regex]=false&columns[14][data]=IndexIndividual&columns[14][name]=&columns[14][searchable]=true&columns[14][orderable]=false&columns[14][search][value]=&columns[14][search][regex]=false&columns[15][data]=ListedShares&columns[15][name]=&columns[15][searchable]=true&columns[15][orderable]=false&columns[15][search][value]=&columns[15][search][regex]=false&columns[16][data]=Offer&columns[16][name]=&columns[16][searchable]=true&columns[16][orderable]=false&columns[16][search][value]=&columns[16][search][regex]=false&columns[17][data]=OfferVolume&columns[17][name]=&columns[17][searchable]=true&columns[17][orderable]=false&columns[17][search][value]=&columns[17][search][regex]=false&columns[18][data]=Bid&columns[18][name]=&columns[18][searchable]=true&columns[18][orderable]=false&columns[18][search][value]=&columns[18][search][regex]=false&columns[19][data]=BidVolume&columns[19][name]=&columns[19][searchable]=true&columns[19][orderable]=false&columns[19][search][value]=&columns[19][search][regex]=false&columns[20][data]=Date&columns[20][name]=&columns[20][searchable]=true&columns[20][orderable]=false&columns[20][search][value]=&columns[20][search][regex]=false&columns[21][data]=TradebleShares&columns[21][name]=&columns[21][searchable]=true&columns[21][orderable]=false&columns[21][search][value]=&columns[21][search][regex]=false&columns[22][data]=WeightForIndex&columns[22][name]=&columns[22][searchable]=true&columns[22][orderable]=false&columns[22][search][value]=&columns[22][search][regex]=false&columns[23][data]=ForeignSell&columns[23][name]=&columns[23][searchable]=true&columns[23][orderable]=false&columns[23][search][value]=&columns[23][search][regex]=false&columns[24][data]=ForeignBuy&columns[24][name]=&columns[24][searchable]=true&columns[24][orderable]=false&columns[24][search][value]=&columns[24][search][regex]=false&columns[25][data]=NonRegularVolume&columns[25][name]=&columns[25][searchable]=true&columns[25][orderable]=false&columns[25][search][value]=&columns[25][search][regex]=false&columns[26][data]=NonRegularValue&columns[26][name]=&columns[26][searchable]=true&columns[26][orderable]=false&columns[26][search][value]=&columns[26][search][regex]=false&columns[27][data]=NonRegularFrequency&columns[27][name]=&columns[27][searchable]=true&columns[27][orderable]=false&columns[27][search][value]=&columns[27][search][regex]=false&search[value]=&search[regex]=false");
    return $res unless $res->[0] == 200;
    return [500, "JSON response does not contain 'data' key"]
        unless ref $res->[2] eq 'HASH' && $res->[2]{data};
    $res->[2] = $res->[2]{data};
    $res;
}

1;
# ABSTRACT: Get information from Indonesian Stock Exchange

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::SE::IDX - Get information from Indonesian Stock Exchange

=head1 VERSION

This document describes version 0.006 of Finance::SE::IDX (from Perl distribution Finance-SE-IDX), released on 2021-01-17.

=head1 FUNCTIONS


=head2 get_idx_daily_trading_summary

Usage:

 get_idx_daily_trading_summary(%args) -> [status, msg, payload, meta]

Get daily trading summary.

This will retrieve end-of-day data for a single trading day, containing list of
stock names along with their opening price, closing price, highest price, lowest
price, volume, frequency, foreign buy & sell volume, etc.

To specify date you can either specify C<date> (epoch, or YYYY-MM-DD string in
command-line, which will be coerced to epoch) or C<day>, C<month>, C<year>.

The data for still-trading current day will not be available, so if you are
looking for intraday data, this is not it.

At the time of this writing (2021-01-17), the data goes back to Jan 1st, 2015.
If you are looking for older data, you can visit one of the financial data
websites like Bloomberg.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date> => I<date>

=item * B<day> => I<int>

=item * B<month> => I<int>

=item * B<year> => I<int>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_idx_boards

Usage:

 list_idx_boards() -> [status, msg, payload, meta]

List boards.

By default caches results for 8 hours (by locally setting CACHE_MAX_AGE). Can be
overriden by using HTTP_TINY_CACHE_MAX_AGE.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_idx_brokers

Usage:

 list_idx_brokers() -> [status, msg, payload, meta]

List brokers.

By default caches results for 8 hours (by locally setting CACHE_MAX_AGE). Can be
overriden by using HTTP_TINY_CACHE_MAX_AGE.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_idx_firms

Usage:

 list_idx_firms(%args) -> [status, msg, payload, meta]

List firms.

By default caches results for 8 hours (by locally setting CACHE_MAX_AGE). Can be
overriden by using HTTP_TINY_CACHE_MAX_AGE.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<board> => I<str>

=item * B<sector> => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_idx_sectors

Usage:

 list_idx_sectors() -> [status, msg, payload, meta]

List sectors.

By default caches results for 8 hours (by locally setting CACHE_MAX_AGE). Can be
overriden by using HTTP_TINY_CACHE_MAX_AGE.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-SE-IDX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-SE-IDX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Finance-SE-IDX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Finance::SE::IDX::Static> for the static (offline) version

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
