package Finance::Crypto::Exchange::Kraken::REST::Private::User::Data;
our $VERSION = '0.004';
# ABSTRACT: Role for Kraken "Prive user data" API calls

use Moose::Role;

requires qw(
    _private
    call
);

use Types::Standard qw(Bool Int Str Enum);
use Params::ValidationCompiler qw(validation_for);

sub get_account_balance {
    my $self = shift;
    my $req  = $self->_private('Balance', @_);
    return $self->call($req);
}

{

    my $validator = validation_for(
        name   => 'get_trade_balance',
        params => {
            aclass => {
                type     => Enum [qw(currency)],
                optional => 1,
            },
            asset => { type => Str, optional => 1 },
        },
    );

    sub get_trade_balance {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_private('TradeBalance', %args);
        return $self->call($req);
    }
}

{

    my $validator = validation_for(
        name   => 'get_open_orders',
        params => {
            trades => {
                type     => Bool,
                optional => 1,
            },
            userref => {
                type     => Str,
                optional => 1,
            },
        },
    );

    sub get_open_orders {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_private('OpenOrders', %args);
        return $self->call($req);
    }
}

{
    my $validator = validation_for(
        name   => 'get_closed_orders',
        params => {
            ofs    => { type => Int, },
            trades => {
                type     => Bool,
                optional => 1,
            },
            userref => {
                type     => Str,
                optional => 1,
            },
            start => {
                type     => Int,
                optional => 1,
            },
            end => {
                type     => Int,
                optional => 1,
            },
            closetime => {
                type     => Enum [qw(open close both)],
                optional => 1,
            }
        },
    );

    sub get_closed_orders {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_private('ClosedOrders', %args);
        return $self->call($req);
    }
}

{
    my $validator = validation_for(
        name   => 'query_orders_info',
        params => {
            trades => {
                type     => Bool,
                optional => 1,
            },
            userref => {
                type     => Str,
                optional => 1,
            },
            txid => {
                type     => Str,
                optional => 1,
            },
        },
    );

    sub query_orders_info {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_private('QueryOrders', %args);
        return $self->call($req);
    }
}

{

    my $validator = validation_for(
        name   => 'get_trades_history',
        params => {
            ofs   => { type => Int, },
            types => {
                type => Enum [
                    (
                        'all',
                        'any position',
                        'closed position',
                        'closing position',
                        'no position',
                    )
                ],
                optional => 1,
            },
            trades => {
                type     => Bool,
                optional => 1,
            },
            start => {
                type     => Int,
                optional => 1,
            },
            end => {
                type     => Int,
                optional => 1,
            },
        },
    );

    sub get_trades_history {
        my $self = shift;
        my %args = $validator->(@_);
        my $req  = $self->_private('TradesHistory', %args);
        return $self->call($req);
    }

}

sub query_trades_info {
    my $self = shift;
    my $req  = $self->_private('QueryTrades', @_);
    return $self->call($req);
}

sub get_open_positions {
    my $self = shift;
    my $req  = $self->_private('OpenPositions', @_);
    return $self->call($req);
}

sub get_ledger_info {
    my $self = shift;
    my $req  = $self->_private('Ledgers', @_);
    return $self->call($req);
}

sub query_ledgers {
    my $self = shift;
    my $req  = $self->_private('QueryLedgers', @_);
    return $self->call($req);
}

sub get_trade_volume {
    my $self = shift;
    my $req  = $self->_private('TradeVolume', @_);
    return $self->call($req);
}

sub request_export_report {
    my $self = shift;
    my $req  = $self->_private('AddExport', @_);
    return $self->call($req);
}

sub get_export_status {
    my $self = shift;
    my $req  = $self->_private('ExportStatus', @_);
    return $self->call($req);
}

sub get_export_report {
    my $self = shift;
    my $req  = $self->_private('RetrieveExport', @_);
    return $self->call($req);
}

sub remove_export_report {
    my $self = shift;
    my $req  = $self->_private('RemoveExport', @_);
    return $self->call($req);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Crypto::Exchange::Kraken::REST::Private::User::Data - Role for Kraken "Prive user data" API calls

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package Foo;
    use Moose;
    with qw(Finance::Crypto::Exchange::Kraken::REST::Private::User::Data);

=head1 DESCRIPTION

This role implements the Kraken REST API for I<private user data>. For
extensive information please have a look at the L<Kraken API
manual|https://www.kraken.com/features/api#private-user-data>

=head1 METHODS

=head2 get_account_balance

L<https://api.kraken.com/0/private/Balance>

=head2 get_trade_balance

L<https://api.kraken.com/0/private/TradeBalance>

=head2 get_open_orders

L<https://api.kraken.com/0/private/OpenOrders>

=head2 get_closed_orders

L<https://api.kraken.com/0/private/ClosedOrders>

=head2 query_orders_info

L<https://api.kraken.com/0/private/QueryOrders>

=head2 get_trades_history

L<https://api.kraken.com/0/private/TradesHistory>

=head2 query_trades_info

L<https://api.kraken.com/0/private/QueryTrades>

=head2 get_open_positions

L<https://api.kraken.com/0/private/OpenPositions>

=head2 get_ledger_info

L<https://api.kraken.com/0/private/Ledgers>

=head2 query_ledgers

L<https://api.kraken.com/0/private/QueryLedgers>

=head2 get_trade_volume

L<https://api.kraken.com/0/private/TradeVolume>

=head2 request_export_report

L<https://api.kraken.com/0/private/AddExport>

=head2 get_export_status

L<https://api.kraken.com/0/private/ExportStatus>

=head2 get_export_report

L<https://api.kraken.com/0/private/RetrieveExport>

=head2 remove_export_report

L<https://api.kraken.com/0/private/RemoveExport>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
