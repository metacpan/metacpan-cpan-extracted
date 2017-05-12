=encoding utf8

=cut

package Email::ExactTarget::Subscriber;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use Data::Validate::Type;
use Try::Tiny;
use URI::Escape;


=head1 NAME

Email::ExactTarget::Subscriber - Object representing ExactTarget subscribers.


=head1 VERSION

Version 1.6.2

=cut

our $VERSION = '1.6.2';


=head1 SYNOPSIS

	# Create a new subscriber object.
	my $subscriber = Email::ExactTarget::Subscriber->new();

	# Set attributes.
	$subscriber->set_attributes(
		{
			'First Name' => 'John',
			'Last Name'  => 'Doe',
		}
	);

	# Get attributes.
	my $first_name = $subscriber->get_attribute('First Name');

	# ExactTarget's subscriber ID, if applicable.
	my $subscriber_id = $subscriber->id();


=head1 METHODS

=head2 new()

Creates a new Subscriber object.

	my $subscriber = Email::ExactTarget::Subscriber->new();

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Create the object.
	my $self = bless(
		{
			'attributes'        => {},
			'staged_attributes' => {},
			'lists'             => {},
			'staged_lists'      => {},
			'properties'        => {},
			'staged_properties' => {},
		},
		$class
	);

	return $self;
}


=head2 id()

Returns the Subscriber ID associated to the current Subscriber in Exact Target's
database.

	$subscriber->id( 123456789 );

	my $subscriber_id = $subscriber->id();

This will return undef if the object hasn't loaded the subscriber information
from the database, or if a new subscriber hasn't been committed to the database.

=cut

sub id
{
	my ( $self, $id ) = @_;

	if ( defined( $id ) )
	{
		confess 'Subscriber ID format is incorrect'
			unless $id =~ m/^\d+$/;

		confess 'The subscriber ID is already set on this object'
			if defined( $self->{'id'} );

		confess 'Cannot modify an object flagged as permanently deleted'
			if $self->is_deleted_permanently();

		$self->{'id'} = $id;
	}

	return $self->{'id'};
}


=head1 MANAGING ATTRIBUTES

=head2 get_attributes()

Retrieve a hashref containing all the attributes of the current object.

By default, it retrieves the live data (i.e., attributes synchronized with
ExactTarget). If you want to retrieve the staged data, you can set
I<is_live> to 0 in the parameters.

	# Retrieve staged attributes (i.e., not synchronized yet with ExactTarget).
	my $attributes = $subscriber->get_attributes( 'is_live' => 0 );

	# Retrieve live attributes.
	my $attributes = $subscriber->get_attributes( 'is_live' => 1 );
	my $attributes = $subscriber->get_attributes();

=cut

sub get_attributes
{
	my ( $self, %args ) = @_;
	my $is_live = delete( $args{'is_live'} );
	$is_live = 1 unless defined( $is_live );

	my $storage_key = $is_live
		? 'attributes'
		: 'staged_attributes';

	# Make a copy of the attributes before returning them, in case the caller
	# needs to modify the hash.
	return { %{ $self->{ $storage_key } || {} } };
}


=head2 get_attribute()

Retrieve the value corresponding to the attribute name passed as first
parameter.

	# Retrieve staged (non-synchronized with ExactTarget) attribute named
	# 'Email Address'.
	my $staged_email_address = $subscriber->get_attribute(
		'Email Address',
		is_live => 0,
	);

	# If you've retrieved the subscriber object from ExactTarget, this
	# retrieves the live attribute that was returned by the webservice.
	my $live_email_address = $subscriber->get_attribute(
		'Email Address',
		is_live => 1,
	);

=cut

sub get_attribute
{
	my ( $self, $attribute, %args ) = @_;
	my $is_live = delete( $args{'is_live'} );
	$is_live = 1 unless defined( $is_live );

	confess 'An attribute name is required to retrieve the corresponding value'
		if !defined( $attribute ) || ( $attribute eq '' );

	my $storage_key = $is_live
		? 'attributes'
		: 'staged_attributes';

	carp "The attribute '$attribute' does not exist on the Subscriber object"
		unless exists( $self->{ $storage_key }->{ $attribute } );

	return $self->{ $storage_key }->{ $attribute };
}


=head2 set_attributes()

Sets the attributes and values for the current subscriber object.

	$subscriber->set_attributes(
		{
			'Email Address' => $email,
			'First Name'    => $first_name,
		},
		'is_live' => $boolean, #default 0
	);

The I<is_live> parameter allows specifying whether the data in the hashref are
local only or if they are already synchronized with ExactTarget's database. By
default, changes are considered local only and you will explicitely have to
synchronize them using the functions of
Email::ExactTarget::SubscriberOperations.

=cut

sub set_attributes
{
	my ( $self, $attributes, %args ) = @_;
	my $is_live = delete( $args{'is_live'} ) || 0;

	confess 'Cannot modify an object flagged as permanently deleted'
		if $self->is_deleted_permanently();

	my $storage_key = $is_live
		? 'attributes'
		: 'staged_attributes';

	while ( my ( $name, $value ) = each( %$attributes ) )
	{
		$self->{ $storage_key }->{ $name } = $value;
	}

	return 1;
}


=head2 apply_staged_attributes()

Moves the staged attribute changes onto the current object, effectively
'applying' the changes.

	$subscriber->apply_staged_attributes(
		[
			'Email Address',
			'First Name',
		]
	) || confess Dumper( $subscriber->errors() );

=cut

sub apply_staged_attributes
{
	my ( $self, $fields ) = @_;

	confess 'The first parameter needs to be an arrayref of fields to apply'
		if !Data::Validate::Type::is_arrayref( $fields );

	confess 'Cannot modify an object flagged as permanently deleted'
		if $self->is_deleted_permanently();

	my $errors_count = 0;
	foreach my $field ( @$fields )
	{
		try
		{
			$self->set_attributes(
				{
					$field => $self->{'staged_attributes'}->{ $field },
				},
				'is_live' => 1,
			);

			delete( $self->{'staged_attributes'}->{ $field } );
		}
		catch
		{
			$errors_count++;
			$self->add_error( "Failed to apply the staged values for the following attribute: $field." );
		};
	}

	return $errors_count > 0 ? 0 : 1;
}


=head1 MANAGING LIST SUBSCRIPTIONS

=head2 get_lists_status()

Returns the subscription status for the lists on the current object.

By default, it retrieves the live data (i.e., list subscriptions synchronized
with ExactTarget). If you want to retrieve the staged data, you can set
I<is_live> to 0 in the parameters.

This function takes one mandatory parameter, which indicates whether you want
the staged list information (lists subscribed to locally but not yet
synchronized with ExactTarget) or the live list information (lists subscribed to
in ExactTarget's database). The respective options are I<staged> for the staged
information, and I<live> for the live information.

	# Retrieve staged attributes (i.e., not synchronized yet with ExactTarget).
	my $lists_status = $self->get_lists_status( 'is_live' => 0 );

	# Retrieve live attributes.
	my $lists_status = $self->get_lists_status( 'is_live' => 1 );
	my $lists_status = $self->get_lists_status();

=cut

sub get_lists_status
{
	my ( $self, %args ) = @_;
	my $is_live = delete( $args{'is_live'} );
	$is_live = 1 unless defined( $is_live );

	my $storage_key = $is_live
		? 'lists'
		: 'staged_lists';

	return { %{ $self->{ $storage_key } || {} } };
}


=head2 set_lists_status()

Stores the list IDs and corresponding subscription status.

	$subscriber->set_lists_status(
		{
			'1234567' => 'Active',
			'1234568' => 'Unsubscribed',
		},
		'is_live' => $boolean, #default 0
	);

The I<is_live> parameter allows specifying whether the data in the hashref are
local only or if they are already synchronized with ExactTarget's database. By
default, changes are considered local only and you will explicitely have to
synchronize them using the functions of
Email::ExactTarget::SubscriberOperations.

'Active' and 'Unsubscribed' are the two valid statuses for list subscriptions.

=cut

sub set_lists_status
{
	my ( $self, $statuses, %args ) = @_;
	my $is_live = delete( $args{'is_live'} ) || 0;

	confess 'Cannot modify an object flagged as permanently deleted'
		if $self->is_deleted_permanently();

	# Verify the new status for each list.
	while ( my ( $list_id, $status ) = each( %$statuses ) )
	{
		confess "The status for list ID >$list_id< must be defined"
			unless defined( $status );

		# See the following page for an explanation of the valid statuses:
		# http://wiki.memberlandingpages.com/System_Guides/Bounce_Mail_Management#Subscriber_Status
		confess "The status >$status< for list ID >$list_id< is incorrect"
			unless $status =~ m/^(?:Active|Unsubscribed|Held|Bounced|Deleted)$/x;
	}

	# If all the status passed are valid, we can now proceed with updating the
	# subscriber object (we want all updates or none).
	my $storage_key = $is_live ? 'lists' : 'staged_lists';
	while ( my ( $list_id, $status ) = each( %$statuses ) )
	{
		$self->{ $storage_key }->{ $list_id } = $status;
	}

	return 1;
}


=head2 apply_staged_lists_status()

Moves the staged list subscription changes onto the current object, effectively
'applying' the changes.

	$subscriber->apply_staged_lists_status(
		[
			'1234567'
			'1234568',
		]
	) || confess Dumper( $subscriber->errors() );

=cut

sub apply_staged_lists_status
{
	my ( $self, $lists_status ) = @_;

	confess 'The first parameter needs to be an hashref of list IDs and statuses to apply'
		if !Data::Validate::Type::is_hashref( $lists_status );

	confess 'Cannot modify an object flagged as permanently deleted'
		if $self->is_deleted_permanently();

	my $errors_count = 0;
	while ( my ( $list_id, $status ) = each( %$lists_status ) )
	{
		try
		{
			$self->set_lists_status(
				{
					$list_id => $status,
				},
				'is_live' => 1,
			);

			delete( $self->{'staged_lists'}->{ $list_id } );
		}
		catch
		{
			$errors_count++;
			$self->add_error( "Failed to apply the staged list statuses for the following list ID: $list_id." );
		};
	}

	return $errors_count > 0 ? 0 : 1;
}


=head1 MANAGING PROPERTIES

=head2 get_properties()

Retrieve a hashref containing all the properties of the current object.

By default, it retrieves the live data (i.e., properties synchronized with
ExactTarget). If you want to retrieve the staged data, you can set
I<is_live> to 0 in the parameters.

	# Retrieve staged properties (i.e., not synchronized yet with ExactTarget).
	my $properties = $subscriber->get_properties( 'is_live' => 0 );

	# Retrieve live properties.
	my $properties = $subscriber->get_properties( 'is_live' => 1 );
	my $properties = $subscriber->get_properties();

=cut

sub get_properties
{
	my ( $self, %args ) = @_;
	my $is_live = delete( $args{'is_live'} );
	$is_live = 1 unless defined( $is_live );

	my $storage_key = $is_live
		? 'properties'
		: 'staged_properties';

	# Make a copy of the attributes before returning them, in case the caller
	# needs to modify the hash.
	return { %{ $self->{ $storage_key } || {} } };
}


=head2 get_property()

Retrieve the value corresponding to the property name passed as first
parameter.

	# Retrieve staged (non-synchronized with ExactTarget) property named
	# EmailTypePreference.
	my $staged_email_type_preference = $subscriber->get_property(
		'EmailTypePreference',
		is_live => 0,
	);

	# If you've retrieved the subscriber object from ExactTarget, this
	# retrieves the live property that was returned by the webservice.
	my $live_email_type_preference = $subscriber->get_property(
		'EmailTypePreference',
		is_live => 1,
	);

=cut

sub get_property
{
	my ( $self, $property, %args ) = @_;
	my $is_live = delete( $args{'is_live'} );
	$is_live = 1 unless defined( $is_live );

	confess 'An property name is required to retrieve the corresponding value'
		if !defined( $property ) || ( $property eq '' );

	my $storage_key = $is_live
		? 'properties'
		: 'staged_properties';

	carp "The property '$property' does not exist on the Subscriber object"
		unless exists( $self->{ $storage_key }->{ $property } );

	return $self->{ $storage_key }->{ $property };
}


=head2 set_properties()

Sets the properties and corresponding values for the current subscriber object.

	$subscriber->set_properties(
		{
			EmailTypePreference => 'Text',
		},
		'is_live' => $boolean, #default 0
	);

The I<is_live> parameter allows specifying whether the data in the hashref are
local only or if they are already synchronized with ExactTarget's database. By
default, changes are considered local only and you will explicitely have to
synchronize them using the functions of
L<Email::ExactTarget::SubscriberOperations>.

=cut

sub set_properties
{
	my ( $self, $properties, %args ) = @_;
	my $is_live = delete( $args{'is_live'} ) || 0;

	confess 'Cannot modify an object flagged as permanently deleted'
		if $self->is_deleted_permanently();

	my $storage_key = $is_live
		? 'properties'
		: 'staged_properties';

	while ( my ( $name, $value ) = each( %$properties ) )
	{
		$self->{ $storage_key }->{ $name } = $value;
	}

	return 1;
}


=head1 MANAGING ERRORS

=head2 add_error()

Adds a new error message to the current object.

	$subscriber->add_error( 'Cannot update object.' ) || confess 'Failed to add error';

=cut

sub add_error
{
	my ( $self, $error ) = @_;

	if ( !defined( $error ) || ( $error eq '' ) )
	{
		carp 'No error text specified';
		return 0;
	}

	$self->{'errors'} ||= [];
	push( @{ $self->{'errors'} }, $error );
	return 1;
}


=head2 errors()

Returns the errors stored on the current object as an arrayref if there is any,
otherwise returns undef.

	# Retrieve the errors.
	my $errors = $subscriber->errors();
	if ( defined( $errors ) )
	{
		print Dumper( $errors );
	}

	# Retrieve and remove the errors.
	my $errors = $subscriber->errors( reset => 1 );
	if ( defined( $errors ) )
	{
		print Dumper( $errors );
	}

=cut

sub errors
{
	my ( $self, %args ) = @_;
	my $reset = delete( $args{'reset'} ) || 0;

	my $errors = $self->{'errors'};

	# If the options require it, removes the errors on the current object.
	$self->{'errors'} = []
		if $reset;

	return $errors;
}


=head1 MANAGING DELETED SUBSCRIBERS

=head2 flag_as_deleted_permanently()

Flags the subscriber as having been deleted in ExactTarget's database. Any
subsequent operation on this object will be denied.

	$subscriber->flag_as_deleted_permanently();

=cut

sub flag_as_deleted_permanently
{
	my ( $self ) = @_;

	delete( $self->{'id'} );
	$self->{'deleted_permanently'} = 1;

	return 1;
}


=head2 is_deleted_permanently()

Returns a boolean indicating if the current object has been removed from
ExactTarget's database.

	my $is_removed = $subscriber->is_deleted_permanently();

=cut

sub is_deleted_permanently
{
	my ( $self ) = @_;

	return $self->{'deleted_permanently'} ? 1 : 0;
}


=head1 DEPRECATED METHODS

=head2 get()

Please use C<get_attribute()> instead.

=cut

sub get
{
	croak 'get() has been deprecated, please use get_attribute() instead.';
}


=head2 set()

Please use C<set_attribute()> instead.

=cut

sub set ## no critic (NamingConventions::ProhibitAmbiguousNames)
{
	croak 'set() has been deprecated, please use set_attribute() instead.';
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Email-ExactTarget/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Email::ExactTarget::Subscriber


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/Email-ExactTarget/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-ExactTarget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-ExactTarget>

=item * MetaCPAN

L<https://metacpan.org/release/Email-ExactTarget>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2009-2014 Guillaume Aubert.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/

=cut

1;
