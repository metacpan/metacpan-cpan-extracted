package Finance::SE::IDX;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-22'; # DATE
our $DIST = 'Finance-SE-IDX'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use HTTP::Tiny::Cache;

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

my $urlprefix = "http://www.idx.co.id/umbraco/Surface/";

sub _get_json {
    my $url = shift;

    my $res = HTTP::Tiny::Cache->new->get($url);
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

1;
# ABSTRACT: Get information from Indonesian Stock Exchange

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::SE::IDX - Get information from Indonesian Stock Exchange

=head1 VERSION

This document describes version 0.005 of Finance::SE::IDX (from Perl distribution Finance-SE-IDX), released on 2020-12-22.

=head1 FUNCTIONS


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

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
