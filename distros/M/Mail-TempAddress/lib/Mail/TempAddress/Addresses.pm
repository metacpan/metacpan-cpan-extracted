package Mail::TempAddress::Addresses;

use strict;
use base 'Mail::Action::Storage';

use Mail::TempAddress::Address;
use File::Spec;

sub new
{
	my ($class, $directory) = @_;
	$directory ||= File::Spec->catdir( $ENV{HOME}, '.addresses' );
	$class->SUPER::new( $directory );
}

sub stored_class
{
	'Mail::TempAddress::Address';
}

sub storage_extension
{
	'mta'
}

sub generate_address
{
	my ($self, $id) = @_;

	$id ||= sprintf '%x', reverse scalar time;

	while ($self->exists( $id ))
	{
		$id = sprintf '%x', ( reverse ( time() + rand($$) ));
	}

	return $id;
}

sub create
{
	my ($self, $from_address) = @_;
	Mail::TempAddress::Address->new( owner => $from_address );
}

1;
__END__

=head1 NAME

Mail::TempAddress::Addresses - manages Mail::TempAddress::Address objects

=head1 SYNOPSIS

use Mail::TempAddress::Addresses;
	my $addresses = Mail::TempAddress::Addresses->new( '.addresses' );

=head1 DESCRIPTION

Mail::TempAddress::Addresses manages the creation, loading, and saving of
Mail::TempAddress::Address objects.  If you'd like to change how these objects
are managed on your system, subclass or reimplement this module.

=head1 METHODS

=over 4

=item * new( [ $address_directory ] )

Creates a new Mail::TempAddress::Addresses object.  The single argument is
optional but highly recommended.  It should be the path to where Address data
files are stored.  Beware that in filter mode, relative paths can be terribly
ambiguous.

If no argument is provided, this will default to C<~/.addresses> for the
invoking user.

=item * storage_dir()

Returns the directory where this object's Address data files are stored.

=item * storage_extension()

Returns the extension of the generated address files.  By default, this is
C<mta>.  Note that the leading period is not part of the extension.

=item * exists( $address_id )

Returns true or false if an address with this id exists.

=item * generate_address([ $address_id ])

Generates and returns a new, unique address id.  If provided, C<$address_id>
will be used as a starting point for the id.  It may not be used, though, if an
address already exists with that id.

=item * create( $owner )

Creates and returns a new Mail::TempAddress::Address object, setting the owner.
Note that you will need to C<save()> the object yourself, if that's important
to you.

=item * save( $address, $address_name )

Saves a Mail::TempAddress::Address object provided as C<$address> with the
given name in C<$address_name>.

=item * fetch( $address_id )

Creates and returns a Mail::TempAddress::Address object representing this
address id.  This will return nothing if the address does not exist.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>, with helpful suggestions from friends, family,
and peers.

=head1 BUGS

None known.

=head1 TODO

No plans.  It's pretty nice as it is.

=head1 SEE ALSO

L<Mail::Action::Storage>, the parent class of this module.

James FitzGibbon's L<Mail::TempAddress::Addresses::Purgeable>, an example of
subclassing this class.

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself.  Convenient for you!
