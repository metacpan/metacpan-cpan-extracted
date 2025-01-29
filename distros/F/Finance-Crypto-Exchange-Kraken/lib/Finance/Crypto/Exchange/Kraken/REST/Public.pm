package Finance::Crypto::Exchange::Kraken::REST::Public;
our $VERSION = '0.004';
use Moose::Role;

# ABSTRACT: Role for Kraken "public" API calls

requires qw(call);

use HTTP::Request::Common qw(POST);
use Types::Standard qw( Int Str Enum);
use Params::ValidationCompiler qw(validation_for);

sub _public {
    my ($self, $call, %payload) = @_;

    my $uri = $self->_uri->clone;
    $uri->path_segments(0, 'public', $call);

    return POST(
        $uri,
        %payload ? (Content => [%payload]) : (),
    );
}

sub get_server_time {
    my $self = shift;
    my $req  = $self->_public('Time');
    return $self->call($req);
}

sub get_system_status {
    my $self = shift;
    my $req  = $self->_public('SystemStatus');
    return $self->call($req);
}

{
    my $validator = validation_for(
        name   => 'get_asset_info',
        params => {
            info => {
                type     => Enum [qw(info)],
                optional => 1,
            },
            aclass => {
                type     => Enum [qw(currency)],
                optional => 1,
            },
            asset => {
                type     => Str,
                optional => 1,
            },
        },
    );

    sub get_asset_info {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_public('Assets', %args);
        return $self->call($req);
    }
}

{

    my $validator = validation_for(
        name   => 'get_tradable_asset_pairs',
        params => {
            info => {
                type     => Enum [qw(info leverage fees margin)],
                optional => 1,
            },
            pair => {
                type     => Str,
                optional => 1,
            },
        },
    );

    sub get_tradable_asset_pairs {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_public('AssetPairs', %args);
        return $self->call($req);
    }

}

{

    my $validator = validation_for(
        name   => 'get_ticker_information',
        params => { pair => { type => Str, }, },
    );

    sub get_ticker_information {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_public('Ticker', %args);
        return $self->call($req);
    }
}

{
    my $validator = validation_for(
        name   => 'get_ohlc_data',
        params => {
            pair     => { type => Str, },
            interval => {
                optional => 1,
                type     => Enum [qw(1 5 15 30 60 240 1440 10080 21600)]
            },
            since => { optional => 1, }
        },
    );

    sub get_ohlc_data {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_public('OHLC', %args);
        return $self->call($req);
    }
}

{
    my $validator = validation_for(
        name   => 'get_order_book',
        params => {
            pair  => { type => Str, },
            count => {
                optional => 1,
                type     => Int,
            },
        },
    );

    sub get_order_book {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_public('Depth', %args);
        return $self->call($req);
    }
}

{
    my $validator = validation_for(
        name   => 'get_recent_trades',
        params => {
            pair  => { type     => Str, },
            since => { optional => 1, },
        },
    );

    sub get_recent_trades {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_public('Trades', %args);
        return $self->call($req);
    }
}

{

    my $validator = validation_for(
        name   => 'get_recent_spread_data',
        params => {
            pair  => { type     => Str, },
            since => { optional => 1, },
        },
    );

    sub get_recent_spread_data {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_public('Spread', %args);
        return $self->call($req);
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Crypto::Exchange::Kraken::REST::Public - Role for Kraken "public" API calls

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package Foo;
    use Moose;
    with qw(Finance::Crypto::Exchange::Kraken::REST::Public);

=head1 DESCRIPTION

This role introduces all the public API calls Kraken supports.  For extensive
information please have a look at the
L<Kraken API manual|https://www.kraken.com/features/api#public-market-data>

=head1 METHODS

=head2 get_server_time

L<https://api.kraken.com/0/public/Time>

=head2 get_system_status

L<https://api.kraken.com/0/public/SystemStatus>

=head2 get_asset_info

L<https://api.kraken.com/0/public/Asset>

=head3 Accepted parameters

=over

=item info (optional)

C<info> all info (default)

=item aclass (optional)

C<currency> (default)

=item asset (optional)

C<all> (default)

=back

=head2 get_tradable_asset_pairs

L<https://api.kraken.com/0/public/AssetPairs>

=head2 get_ticker_information

L<https://api.kraken.com/0/public/Ticker>

=head2 get_ohlc_data

L<https://api.kraken.com/0/public/OHLC>

=head2 get_order_book

L<https://api.kraken.com/0/public/Depth>

=head2 get_recent_trades

L<https://api.kraken.com/0/public/Trades>

=head2 get_recent_spread_data

L<https://api.kraken.com/0/public/Spread>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
