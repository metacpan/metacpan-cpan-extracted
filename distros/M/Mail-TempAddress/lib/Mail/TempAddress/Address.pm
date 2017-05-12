package Mail::TempAddress::Address;

use strict;

use Mail::Action::Address;
use Class::Roles
	does => 'address_expires',
	does => 'address_named',
	does => 'address_described';

sub new
{
	my $class = shift;
	bless { 
		expires     => 0,
		@_,
	}, $class;
}

sub owner
{
	my $self = shift;
	return $self->{owner};
}

sub attributes
{
	{ expires => 1, description => 1 }
}

sub add_sender
{
	my ($self, $sender) = @_;

	my $key                  = $self->get_key( $sender ); 
	$self->{senders}{ $key } = $sender;

	return $key;
}

sub get_key
{
	my ($self, $sender) = @_;
	return $self->{keys}{ $sender } if exists $self->{keys}{ $sender };

	my $key  = sprintf '%x', reverse scalar time();

	do
	{
		$key = sprintf '%x', reverse( time() + rand( $$ ) );
	} while ( exists $self->{keys}{ $key } );

	return $self->{keys}{ $sender } = $key;
}

sub get_sender
{
	my ($self, $key) = @_;

	return unless exists $self->{senders}{ $key };
	return $self->{senders}{ $key };
}

1;

__END__

=head1 NAME

Mail::TempAddress::Address - object representing a temporary mailing address

=head1 SYNOPSIS

	use Mail::TempAddress::Address;
	my $address     =  Mail::TempAddress::Address->new(
		description => 'not my real address',
	);

=head1 DESCRIPTION

A Mail::TempAddress::Address object represents a temporary mailing address
within Mail::TempAddress.  It contains all of the attributes of the address and
provides methods to query and to set them.  The current attributes are
C<expires> and C<description>.

=head1 METHODS

=over 4

=item * new( %options )

C<new()> creates a new Mail::TempAddress::Address object.  Pass in a hash of
attribute options to set them.  By default, C<expires> is false and
C<description> is empty.

=item * attributes()

Returns a reference to a hash of valid attributes for Address objects.  This
allows you to see which attributes you should actually care about.

=item * owner()

Returns the e-mail address of the owner of this Address.

=item * add_sender( $sender )

Given C<$sender>, the e-mail address of someone who sent a message to this
Address, generates and returns a key for that sender.  The key can be used to
retrieve the sender's address later.

=item * get_sender( $key )

Given C<$key>, returns an e-mail address which has previously sent e-mail to
this Address.  This method will return a false value if there is no sender
associated with the key.

=item * name( [ $new_name   ] )

Given C<$new_name>, updates the associated name of the Address and returns the
new value.  If the argument is not provided, returns the current value.  You
probably don't want to change an existing Address' name.

=item * expires( [ $new_expires   ] )

Given C<$new_expires>, updates the C<expires> attribute of the Address and
returns the new value.  If the argument is not provided, returns the current
value.

=item * description( [ $new_description ] )

Given C<$new_description>, updates the C<description> attribute of the Address
and returns the new value.  If the argument is not provided, returns the
current value.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>.

=head1 BUGS

None known.

=head1 TODO

No plans.  It's pretty nice as it is.

=head1 SEE ALSO

L<Mail::Action::Address>, the parent class.

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself.  How nice.
