package Finance::Bitcoin::Address;

BEGIN {
	$Finance::Bitcoin::Address::AUTHORITY = 'cpan:TOBYINK';
	$Finance::Bitcoin::Address::VERSION   = '0.902';
}

use 5.010;
use Moo;
use Carp;
use Finance::Bitcoin;
use Scalar::Util qw( blessed );

with "Finance::Bitcoin::Role::HasAPI";

has address => (is => "ro");

sub label
{
	my $self = shift;
	$self->api->call(setlabel => $self->address, @_) if @_;
	return $self->api->call(getlabel => $self->address);
}

sub received
{
	my $self = shift;
	my ($minconf) = @_;
	return $self->api->call(getreceivedbyaddress => $self->address, ($minconf//1));
}

1;

__END__

=head1 NAME

Finance::Bitcoin::Address - a bitcoin address

=head1 SYNOPSIS

 use Finance::Bitcoin;
 
 my $uri     = 'http://user:password@127.0.0.1:8332/';
 my $wallet  = Finance::Bitcoin::Wallet->new($uri);
 
 foreach my $address ($wallet->addresses)
 {
   print $address->address . "\n";
   print $address->label . "\n";
   print $address->received . "\n\n";
 }

=head1 DESCRIPTION

This module is part of the high-level API for accessing a running
Bitcoin instance.

=over 4

=item C<< new($endpoint, $string) >>

Constructor. $endpoint may be the JSON RPC endpoint URL, or may be a
Finance::Bitcoin::API object; $string is an address string.

=begin trustme

=item BUILDARGS

=end trustme

=item C<< address >>

Returns the address string.

=item C<< label >>

Get/set the address label.

=item C<< received($minconf) >>

Returns the total amount received via this address, with at least $minconf
confirmations. $minconf defaults to 1.

=item C<< api >>

Retrieve a reference to the L<Finance::Bitcoin::API> object being used.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<Finance::Bitcoin>, L<Finance::Bitcoin::Wallet>.

L<http://www.bitcoin.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010, 2011, 2013, 2014 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
