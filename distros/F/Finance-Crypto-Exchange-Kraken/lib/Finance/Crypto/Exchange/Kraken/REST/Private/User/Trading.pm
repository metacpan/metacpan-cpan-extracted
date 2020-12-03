package Finance::Crypto::Exchange::Kraken::REST::Private::User::Trading;
our $VERSION = '0.002';
use Moose::Role;

# ABSTRACT: Role for Kraken "Prive user trading" API calls

requires qw(
    call
    _private
);

sub add_standard_order {
    my $self = shift;
    my $req = $self->_private('AddOrder', @_);
    return $self->call($req);
}

sub cancel_open_order {
    my $self = shift;
    my $req = $self->_private('CancelOrder', @_);
    return $self->call($req);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Crypto::Exchange::Kraken::REST::Private::User::Trading - Role for Kraken "Prive user trading" API calls

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package Foo;
    use Moose;
    with qw(Finance::Crypto::Exchange::Kraken::REST::Private::User::Trading);

=head1 DESCRIPTION

This role implements the Kraken REST API for I<private user trading>. For
extensive information please have a look at the L<Kraken API
manual|https://www.kraken.com/features/api#private-user-trading>

=head1 METHODS

=head2 add_standard_order

L<https://api.kraken.com/0/private/AddOrder>

=head2 cancel_open_order

L<https://api.kraken.com/0/private/CancelOrder>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
