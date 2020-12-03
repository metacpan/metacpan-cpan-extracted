package Finance::Crypto::Exchange::Kraken::REST::Private::User::Funding;
our $VERSION = '0.002';
use Moose::Role;

# ABSTRACT: Role for Kraken "Prive user funding" API calls

requires qw(
    _private
    call
);

sub get_deposit_methods {
    my $self = shift;
    my $req = $self->_private('DepositMethods', @_);
    return $self->call($req);
}

sub get_deposit_addresses {
    my $self = shift;
    my $req = $self->_private('DepositAddresses', @_);
    return $self->call($req);
}

sub get_recent_deposit_status {
    my $self = shift;
    my $req = $self->_private('DepositStatus', @_);
    return $self->call($req);
}

sub get_withdrawal_info {
    my $self = shift;
    my $req = $self->_private('WithdrawInfo', @_);
    return $self->call($req);
}

sub withdraw_funds {
    my $self = shift;
    my $req = $self->_private('Withdraw', @_);
    return $self->call($req);
}

sub get_recent_withdrawal_status {
    my $self = shift;
    my $req = $self->_private('WithdrawStatus', @_);
    return $self->call($req);
}

sub request_withdrawal_cancel {
    my $self = shift;
    my $req = $self->_private('WithdrawCancel', @_);
    return $self->call($req);
}

sub wallet_transfer {
    my $self = shift;
    my $req = $self->_private('WalletTransfer', @_);
    return $self->call($req);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Crypto::Exchange::Kraken::REST::Private::User::Funding - Role for Kraken "Prive user funding" API calls

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package Foo;
    use Moose;
    with qw(Finance::Crypto::Exchange::Kraken::REST::Private::User::Funding);

=head1 DESCRIPTION

This role implements the Kraken REST API for I<private user funding>. For
extensive information please have a look at the L<Kraken API
manual|https://www.kraken.com/features/api#private-user-funding>

=head1 METHODS

=head2 get_deposit_methods

L<https://api.kraken.com/0/private/DepositMethods>

=head2 get_deposit_addresses

L<https://api.kraken.com/0/private/DepositAddresses>

=head2 get_recent_deposit_status

L<https://api.kraken.com/0/private/DepositStatus>

=head2 get_withdrawal_info

L<https://api.kraken.com/0/private/WithdrawInfo>

=head2 withdraw_funds

L<https://api.kraken.com/0/private/Withdraw>

=head2 get_recent_withdrawal_status

L<https://api.kraken.com/0/private/WithdrawStatus>

=head2 request_withdrawal_cancel

L<https://api.kraken.com/0/private/WithdrawCancel>

=head2 wallet_transfer

L<https://api.kraken.com/0/private/WalletTransfer>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
