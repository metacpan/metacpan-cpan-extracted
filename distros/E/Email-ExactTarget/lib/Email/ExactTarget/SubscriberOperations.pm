=encoding utf8

=cut

package Email::ExactTarget::SubscriberOperations;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use Data::Validate::Type;
use URI::Escape;
use Text::Unaccent qw();

use Email::ExactTarget::Subscriber;


=head1 NAME

Email::ExactTarget::SubscriberOperations - Collection of functions to manipulate arrayrefs of Subscriber objects.


=head1 VERSION

Version 1.6.2

=cut

our $VERSION = '1.6.2';


=head1 SYNOPSIS

	# Create a new subscriber operations object
	my $subscriber_operations = $exact_target->subscriber_operations();

	my $subscribers;
	eval
	{
		$subscribers = $subscriber_operations->retrieve(
			'email' => [ qw( test@test.invalid foo@bar.invalid ) ],
		);
	};
	warn "Retrieving the subscribers failed: $@" if $@;


=head1 METHODS

=head2 new()

Creates a new SubscriberOperations object, requires an Email::ExactTarget
object to be passed as parameter.

	my $subscriber_operations = Email::ExactTarget::SubscriberOperations->new( $exact_target );

Note that this is not the recommended way of creating a SubscriberOperations
object. If you are writing a script using this distribution, you should use
instead:

	my $subscriber_operations = $exact_target->subscriber_operations();

=cut

sub new
{
	my ( $class, $exact_target, %args ) = @_;

	# Require an Email::ExactTarget object to be passed.
	confess 'Pass an Email::ExactTarget object to create an Email::ExactTarget::SubscriberOperations object'
		unless defined( $exact_target ) && $exact_target->isa( 'Email::ExactTarget' );

	# Create the object.
	my $self = bless(
		{
			'exact_target' => $exact_target,
		},
		$class,
	);

	return $self;
}


=head2 exact_target()

Returns the main Exact Target object.

	my $exact_target = $subscriber_operations->exact_target();

=cut

sub exact_target
{
	my ( $self ) = @_;

	return $self->{'exact_target'};
}


=head2 create()

Creates a new subscriber in ExactTarget's database using the staged changes on
the subscriber objects passed as parameter.

	$subscriber_operations->create(
		\@subscribers
	);

=cut

sub create
{
	my ( $self, $subscribers ) = @_;

	return $self->_update_create(
		'subscribers' => $subscribers,
		'soap_action' => 'Create',
		'soap_method' => 'CreateRequest',
		'options'     => undef,
	);
}


=head2 update_or_create()

Creates a new subscriber in ExactTarget's database using the staged changes on
the subscriber objects passed as parameter. If the subscriber already exists in
the database, updates it.

	$subscriber_operations->update_or_create(
		\@subscribers
	);

=cut

sub update_or_create
{
	my ( $self, $subscribers ) = @_;

	return $self->_update_create(
		'subscribers' => $subscribers,
		'soap_action' => 'Create',
		'soap_method' => 'CreateRequest',
		'options'     => SOAP::Data->name(
			'Options' => \SOAP::Data->value(
				SOAP::Data->name(
					'SaveOptions' => \SOAP::Data->value(
						SOAP::Data->name(
							'SaveOption' => \SOAP::Data->value(
								SOAP::Data->name(
									'PropertyName' => '*',
								),
								SOAP::Data->name(
									'SaveAction' => 'UpdateAdd',
								),
							),
						),
					),
				),
			),
		),
	);
}


=head2 update()

Applies to ExactTarget's database any staged changes on the subscriber objects
passed as parameter.

	$subscriber_operations->update(
		\@subscribers
	);

=cut

sub update
{
	my ( $self, $subscribers ) = @_;

	return $self->_update_create(
		'subscribers' => $subscribers,
		'soap_action' => 'Update',
		'soap_method' => 'UpdateRequest',
		'options'     => SOAP::Data->name(
			'Options' => \SOAP::Data->value(),
		),
	);
}


=head2 retrieve()

Retrieves from ExactTarget's database the subscribers corresponding to the
unique identifiers passed as parameter.

	my $subscribers = $subscriber_operations->retrieve(
		'email' => [ $email1, $email2 ],
	);

=cut

sub retrieve
{
	my ( $self, %args ) = @_;
	my $email = delete( $args{'email'} );

	# Check parameters.
	confess 'Emails identifying the subscribers to retrieve were not passed.'
		if !defined( $email );

	confess "The 'email' parameter must be an arrayref"
		if !Data::Validate::Type::is_arrayref( $email );

	confess 'Emails identifying the subscribers to retrieve were not passed.'
		if scalar( @$email ) == 0;

	# The 'IN' operator in ExactTarget requires at least 2 emails.
	# If only one email is passed, we're simply going to send it twice and get one
	# result back.
	$email = [ $email->[0], $email->[0] ]
		if scalar( @$email ) == 1;

	# Shortcuts.
	my $exact_target = $self->exact_target() || confess 'Email::ExactTarget object is not defined';
	my $verbose = $exact_target->verbose();

	# Prepare SOAP content.
	my $soap_args =
	[
		SOAP::Data->name(
			RetrieveRequest => \SOAP::Data->value(
				SOAP::Data->name(
					ObjectType => 'Subscriber',
				),
				SOAP::Data->name(
					Properties => ( 'ID', 'EmailTypePreference', 'EmailAddress' ),
				),
				SOAP::Data->name(
					'Filter' => \SOAP::Data->value(
						SOAP::Data->name(
							Property => 'EmailAddress',
						),
						SOAP::Data->name(
							SimpleOperator => 'IN',
						),
						SOAP::Data->name(
							Value => @$email,
						),
					),
				)->attr( { 'xsi:type' => 'SimpleFilterPart' } ),
			),
		),
	];

	# Get Exact Target's reply.
	my $soap_response = $exact_target->soap_call(
		'action'    => 'Retrieve',
		'method'    => 'RetrieveRequestMsg',
		'arguments' => $soap_args,
	);
	my ( $soap_success, $soap_request_id, @soap_object ) = $soap_response->paramsall();

	# Check for errors.
	confess Dumper( $soap_response->fault() )
		if defined( $soap_response->fault() );

	confess "The SOAP reply status is '$soap_success', not 'OK'"
		unless defined( $soap_success ) && ( $soap_success eq 'OK' );

	# Turn the SOAP objects into known objects.
	my @subscriber = ();
	foreach my $soap_object ( @soap_object )
	{
		# Check for errors in the XML returned.
		confess "No attributes found."
			unless defined( $soap_object->{'Attributes'} );

		confess 'No subscriber ID found.'
			unless defined( $soap_object->{'ID'} );

		# Create a Subscriber object and fill it.
		my $subscriber = Email::ExactTarget::Subscriber->new();
		$subscriber->id( $soap_object->{'ID'} );
		$subscriber->set_properties(
			{
				map { $_ => $soap_object->{ $_ } }
					qw( EmailTypePreference EmailAddress )
			},
			'is_live' => 1,
		);
		$subscriber->set_attributes(
			{
				map
				{
					$_->{'Name'} => $_->{'Value'}
				} @{ $soap_object->{'Attributes'} }
			},
			'is_live' => 1,
		);

		push( @subscriber, $subscriber );
	}

	return \@subscriber;
}


=head2 pull_list_subscriptions()

Pulls from ExactTarget's database the list subscriptions for the arrayref of
subscribers passed as parameter.

	# Pull list subscriptions.
	$subscriber_operations->pull_list_subscriptions(
		$subscribers
	);

	# Pull list subscriptions only for the specified lists.
	# This is helpful if you have a lot of legacy/historical lists you
	# don't actually sync with, as it cuts down on the number of results
	# and the time it takes to retrieve them.
	$subscriber_operations->pull_list_subscriptions(
		$subscribers,
		list_ids => \@list_ids,
	);

=cut

sub pull_list_subscriptions
{
	my ( $self, $subscribers, %args ) = @_;
	my $list_ids = delete( $args{'list_ids'} );
	croak 'Unrecognized arguments: ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Verify arguments.
	confess 'An arrayref of subscribers to pull list subscriptions for is required.'
		if !Data::Validate::Type::is_arrayref( $subscribers );
	confess 'A non-empty arrayref of subscribers to pull list subscriptions for is required.'
		if scalar( @$subscribers ) == 0;
	if ( defined( $list_ids ) )
	{
		confess 'When defined, the argument "list_ids" must be an arrayref'
			if !Data::Validate::Type::is_arrayref( $list_ids );
		confess 'When defined, the argument "list_ids" must contain at least one list ID to restrict the query to'
			if scalar( @$list_ids ) == 0;
	}

	# Shortcuts.
	my $exact_target = $self->exact_target() || confess 'Email::ExactTarget object is not defined';
	my $verbose = $exact_target->verbose();

	# Prepare the filter on the subscribers' email.
	my @emails = map { $_->get_attribute('Email Address') } @$subscribers;
	my $email_filter = \SOAP::Data->value(
		SOAP::Data->name(
			Property => 'SubscriberKey',
		),
		SOAP::Data->name(
			SimpleOperator => scalar( @emails ) == 1
				? 'equals'
				: 'IN',
		),
		SOAP::Data->name(
			Value => scalar( @emails ) == 1
				? $emails[0]
				: @emails,
		),
	);

	# Prepare the list ID filter, if needed.
	my $list_id_filter;
	if ( defined( $list_ids ) )
	{
		$list_id_filter = \SOAP::Data->value(
			SOAP::Data->name(
				Property => 'ListID',
			),
			SOAP::Data->name(
				SimpleOperator => scalar( @$list_ids ) == 1
					? 'equals'
					: 'IN',
			),
			SOAP::Data->name(
				Value => scalar( @$list_ids ) == 1
					? $list_ids->[0]
					: @$list_ids,
			),
		);
	}

	# Prepare the complete filter.
	my $filter;
	if ( defined( $list_id_filter ) )
	{
		# Since we're filtering on list ID and email, then we need to set up a complex
		# filter to combine them.
		$filter = SOAP::Data->name(
			'Filter' => \SOAP::Data->value(
				SOAP::Data->name(
					'LeftOperand' => $email_filter,
				)->attr( { 'xsi:type' => 'SimpleFilterPart' } ),
				SOAP::Data->name(
					LogicalOperator => 'AND',
				),
				SOAP::Data->name(
					'RightOperand' => $list_id_filter,
				)->attr( { 'xsi:type' => 'SimpleFilterPart' } ),
			),
		)->attr( { 'xsi:type' => 'ComplexFilterPart' } );
	}
	else
	{
		# Filter only on email with a simple filter.
		$filter = SOAP::Data->name(
			'Filter' => $email_filter,
		)->attr( { 'xsi:type' => 'SimpleFilterPart' } );
	}

	# Prepare SOAP content.
	my $soap_args =
	[
		SOAP::Data->name(
			RetrieveRequest => \SOAP::Data->value(
				SOAP::Data->name(
					ObjectType => 'ListSubscriber',
				),
				SOAP::Data->name(
					Properties => qw( ListID SubscriberKey Status ),
				),
				$filter,
			),
		),
	];

	# Get Exact Target's reply.
	my $soap_response = $exact_target->soap_call(
		'action'    => 'Retrieve',
		'method'    => 'RetrieveRequestMsg',
		'arguments' => $soap_args,
	);

	my ( $soap_success, $soap_request_id, @soap_params_out ) = $soap_response->paramsall();

	# Check for errors.
	confess Dumper( $soap_response->fault() )
		if defined( $soap_response->fault() );

	confess "The SOAP reply status is '$soap_success', not 'OK'"
		unless defined( $soap_success ) && ( $soap_success eq 'OK' );

	# Check the detail of the response for each object, and update accordingly.
	my $subscribers_by_email =
	{
		map
			{ $_->get_attribute('Email Address') => $_ }
			@$subscribers
	};

	foreach my $soap_param_out ( @soap_params_out )
	{
		$subscribers_by_email->{ $soap_param_out->{'SubscriberKey'} }->set_lists_status(
			{
				$soap_param_out->{'ListID'} => $soap_param_out->{'Status'},
			},
			'is_live' => 1,
		);
	}

	return 1;
}


=head2 delete_permanently()

Deletes permanently the subscribers in the set passed as parameter from
ExactTarget's database.

Note that this operation cannot be reversed. If you want to keep the subscribers
but make sure emails are never sent to them, look into adding them to the
"blacklist" list instead.

	my $all_subscribers_removed = $subscriber_operations->delete_permanently(
		\@subscribers
	);

	unless ( $all_subscribers_removed )
	{
		foreach my $subscriber ( @subscribers )
		{
			my $errors = $subscriber->errors();
			if ( defined( $errors ) )
			{
				# We failed to delete the subscriber.
				print 'Failed to update subscriber ', $subscriber->id(), ": ", Dumper( $errors );
			}
			else
			{
				# Success.
			}
		}
	}

=cut

sub delete_permanently
{
	my ( $self, $subscribers ) = @_;

	# Verify parameters.
	confess 'The "subscribers" parameter need to be set.'
		if !defined( $subscribers );
	confess 'The "subscribers" parameter must be an arrayref'
		if !Data::Validate::Type::is_arrayref( $subscribers );
	confess 'The "subscribers" parameter must have at least one subscriber in the arrayref'
		if scalar( @$subscribers ) == 0;

	# Shortcuts.
	my $exact_target = $self->exact_target() || confess 'Email::ExactTarget object is not defined';
	my $verbose = $exact_target->verbose();

	# Prepare SOAP content.
	my @soap_data = ();

	foreach my $subscriber ( @$subscribers )
	{
		# Reuse the existing identifiers.
		my @object =
		(
			SOAP::Data->name(
				'EmailAddress' => $subscriber->get_attribute( 'Email Address', 'is_live' => 1 ),
			),
			SOAP::Data->name(
				'ID' => $subscriber->id(),
			),
		);

		# Create the subscriber block in the SOAP message.
		push(
			@soap_data,
			SOAP::Data->name(
				'Objects' => \SOAP::Data->value(
					@object
				),
			)->attr( { 'xsi:type' => 'Subscriber' } ),
		)
	}

	# Get Exact Target's reply.
	my $soap_response = $exact_target->soap_call(
		'action'    => 'Delete',
		'method'    => 'DeleteRequest',
		'arguments' =>
		[
			SOAP::Data->value(
				@soap_data
			)
		],
	);

	my @soap_params_out  = $soap_response->paramsall();
	my $soap_success = pop( @soap_params_out );
	my $soap_request_id = pop( @soap_params_out );

	# Check for errors.
	confess Dumper( $soap_response->fault() )
		if defined( $soap_response->fault() );

	confess "The SOAP reply status is '$soap_success', not 'OK'"
		unless defined( $soap_success ) && ( $soap_success eq 'OK' );

	# Parse the output.
	my $deletion_results = {};
	foreach my $param_out ( @soap_params_out )
	{
		$deletion_results->{ $param_out->{'OrdinalID'} } =
		{
			'StatusCode'    => $param_out->{'StatusCode'},
			'StatusMessage' => $param_out->{'StatusMessage'},
		};
	}

	# Check the detail of the response for each object, and update it accordingly.
	my $errors_found = 0;
	for ( my $count = 0; $count < scalar( @$subscribers ); $count++ )
	{
		my $subscriber = $subscribers->[ $count ];
		my $deletion_result = $deletion_results->{ $count };

		# Check the individual status code to determine if the update for that
		# subscriber was successful.
		if ( $deletion_result->{'StatusCode'} ne 'OK' )
		{
			$errors_found = 1;
			$subscriber->add_error( $deletion_result->{'StatusMessage'} );
			next;
		}

		# The subscriber has been deleted in ExactTarget's database, flag it locally
		# as deleted to prevent any further operation on this object.
		unless ( $subscriber->flag_as_deleted_permanently() )
		{
			$errors_found = 1;
			$subscriber->add_error( "Deleted in ExactTarget's database, but failed to flag locally the object as deleted." );
			next;
		}
	}

	return !$errors_found;
}


=head1 INTERNAL FUNCTIONS

=head2 _update_create()

Internal. Updates or create a set of subscribers.

	my $batch_success = $subscriber_operations->_update_create(
		'subscribers' => \@subscriber,
		'soap_action' => 'Update',
		'soap_method' => 'UpdateRequest',
	);

	my $batch_success = $subscriber_operations->_update_create(
		'subscribers' => \@subscriber,
		'soap_action' => 'Create',
		'soap_method' => 'CreateRequest',
	);

Note $batch_success will be true only if all the elements have been updated
successfully. When it is false, you should loop through @subscriber and use the
C<errors()> method on each object to find which one(s) failed.

=cut

sub _update_create
{
	my ( $self, %args ) = @_;
	my $subscribers = delete( $args{'subscribers'} );

	# Verify parameters.
	confess 'The "subscribers" parameter need to be set.'
		if !defined( $subscribers );
	confess 'The "subscribers" parameter must be an arrayref'
		if !Data::Validate::Type::is_arrayref( $subscribers );
	confess 'The "subscribers" parameter must have at least one subscriber in the arrayref'
		if scalar( @$subscribers ) == 0;

	# Shortcuts.
	my $exact_target = $self->exact_target() || confess 'Email::ExactTarget object is not defined';
	my $verbose = $exact_target->verbose();

	# Make sure that the subscribers haven't been flagged locally as deleted.
	foreach my $subscriber ( @$subscribers )
	{
		next unless $subscriber->is_deleted_permanently();

		confess 'Cannot perform operations on an object flagged as permanently deleted'
			. ( $verbose ? ': ' . Dumper( $subscriber) : '.' );
	}

	# Prepare SOAP content.
	my @soap_data = ();
	if ( defined( $args{'options'} ) )
	{
		push( @soap_data, $args{'options'} );
	}

	foreach my $subscriber ( @$subscribers )
	{
		my @object = ();

		if ( $args{'soap_action'} eq 'Create' )
		{
			# Use the new email address as unique identifier.
			push(
				@object,
				SOAP::Data->name(
					'EmailAddress' => $subscriber->get_attribute( 'Email Address', 'is_live' => 0 ),
				),
			);
		}
		else
		{
			# Reuse the existing identifiers.
			push(
				@object,
				SOAP::Data->name(
					'EmailAddress' => $subscriber->get_attribute( 'Email Address', 'is_live' => 1 ),
				),
				SOAP::Data->name(
					'ID' => $subscriber->id(),
				),
			);
		}

		# Add the staged properties for this subscriber.
		my $properties = $subscriber->get_properties( is_live => 0 );
		foreach my $name ( keys %$properties )
		{
			push(
				@object,
				SOAP::Data->name(
					$name => $properties->{ $name }
				)
			);
		}

		# Add the new values for attributes and list subscriptions.
		push(
			@object,
			$self->_soap_format_attributes( $subscriber->get_attributes( 'is_live' => 0 ) ),
			$self->_soap_format_lists(
				'current' => $subscriber->get_lists_status( 'is_live' => 1 ),
				'staged'  => $subscriber->get_lists_status( 'is_live' => 0 ),
			),
		);

		# Create the new subscriber block in the SOAP message.
		push(
			@soap_data,
			SOAP::Data->name(
				'Objects' => \SOAP::Data->value(
					@object
				),
			)->attr( { 'xsi:type' => 'Subscriber' } ),
		);
	}

	# Get Exact Target's reply.
	my $soap_response = $exact_target->soap_call(
		'action'    => $args{'soap_action'},
		'method'    => $args{'soap_method'},
		'arguments' =>
		[
			SOAP::Data->value(
				@soap_data
			)
		],
	);

	my @soap_params_out  = $soap_response->paramsall();
	my $soap_success = pop( @soap_params_out );
	my $soap_request_id = pop( @soap_params_out );

	# Check for errors.
	confess Dumper( $soap_response->fault() )
		if defined( $soap_response->fault() );

	my $batch_success = defined( $soap_success ) && ( $soap_success eq 'OK' )
		? 1
		: 0;

	# Check the detail of the response for each object, and update accordingly.
	my %update_details = ();
	foreach my $param_out ( @soap_params_out )
	{
		$update_details{ $param_out->{'Object'}->{'EmailAddress'} } = $param_out;
	}
	foreach my $subscriber ( @$subscribers )
	{
		my $email = $args{'soap_action'} eq 'Create'
			? $subscriber->get_attribute('Email Address', is_live => 0 )
			: $subscriber->get_attribute('Email Address');

		my $update_details = $update_details{ $email };

		# Check the individual status code to determine if the update for that
		# subscriber was successful.
		if ( $update_details->{'StatusCode'} ne 'OK' )
		{
			$subscriber->add_error( $update_details->{'StatusMessage'} );
			next;
		}

		# Set the ExactTarget ID on the current object.
		if ( defined( $update_details->{'Object'}->{'ID'} ) )
		{
			if ( defined( $subscriber->id() ) )
			{
				confess 'The subscriber object ID was ' . $subscriber->id() . ' locally, '
					. 'but ExactTarget now claims it is ' . $update_details->{'Object'}->{'ID'}
					if $subscriber->id() != $update_details->{'Object'}->{'ID'};
			}
			else
			{
				$subscriber->id( $update_details->{'Object'}->{'ID'} );
			}
		}

		# Apply the staged attributes that ExactTarget reports as updated.
		if ( defined ( $update_details->{'Object'}->{'Attributes'} ) )
		{
			my $attributes = Data::Validate::Type::is_arrayref( $update_details->{'Object'}->{'Attributes'} )
				? $update_details->{'Object'}->{'Attributes'}
				: [ $update_details->{'Object'}->{'Attributes'} ];

			$subscriber->apply_staged_attributes(
				[ map { $_->{'Name'} } @$attributes ]
			);
		}

		# Apply the staged list status updates.
		if ( defined ( $update_details->{'Object'}->{'Lists'} ) )
		{
			my $lists = Data::Validate::Type::is_arrayref( $update_details->{'Object'}->{'Lists'} )
				? $update_details->{'Object'}->{'Lists'}
				: [ $update_details->{'Object'}->{'Lists'} ];

			$subscriber->apply_staged_lists_status(
				{
					map
						{ $_->{'ID'} => $_->{'Status'} }
						@$lists
				}
			);
		}

		# Make sure that all the staged updates have been performed by ExactTarget.
		my $attributes_remaining = $subscriber->get_attributes( 'is_live' => 0 );
		if ( scalar( keys %$attributes_remaining ) != 0 )
		{
			$subscriber->add_error('The following staged changes were not applied: ' . join(', ', keys %$attributes_remaining ) . '.' );
		}
		my $lists_remaining = $subscriber->get_lists_status( 'is_live' => 0 );
		if ( scalar( keys %$lists_remaining ) != 0 )
		{
			$subscriber->add_error(
				"The following staged lists status changes were not applied:\n"
				. join( "\n", map { "   $_ => $lists_remaining->{$_}" } keys %$lists_remaining )
			);
		}
	}

	return $batch_success;
}


=head2 _soap_format_lists()

Formats the lists subscription changes passed as a hashref for inclusion in the
SOAP messages.

	my $soap_lists = $self->_soap_format_lists( $lists );

See http://wiki.memberlandingpages.com/API_References/Web_Service_Guide/_Technical_Articles/Managing_Subscribers_On_Lists.

=cut

sub _soap_format_lists
{
	my ( $self, %args ) = @_;

	my $status_current = $args{'current'};
	my $status_staged = $args{'staged'};

	confess 'Current lists status not defined'
		unless defined( $status_current );

	confess 'Staged lists status not defined'
		unless defined( $status_staged );

	my @lists = ();
	foreach my $list_id ( keys %$status_staged )
	{
		push(
			@lists,
			SOAP::Data->name(
				'Lists' => \SOAP::Data->value(
					SOAP::Data->name(
						'ID' => $list_id,
					),
					SOAP::Data->name(
						'Status' => $status_staged->{$list_id},
					),
					SOAP::Data->name(
						'Action' => defined( $status_current->{$list_id} )
							? 'update'
							: 'create',
					),
				),
			),
		);
	}

	return @lists;
}


=head2 _soap_format_attributes()

Formats the attributes passed as a hashref for inclusion in the SOAP messages.

	my $soap_attributes = $self->_soap_format_attributes( $attributes );

=cut

sub _soap_format_attributes
{
	my ( $self, $attributes ) = @_;

	confess 'Attributes not defined'
		unless defined( $attributes );

	if ( $self->exact_target()->unaccent() )
	{
		foreach my $attribute ( keys %$attributes )
		{
			next if !defined( $attributes->{ $attribute } );

			$attributes->{ $attribute } = Text::Unaccent::unac_string(
				'latin1',
				$attributes->{ $attribute },
			);
		}
	}

	my @attribute = ();
	foreach my $name ( keys %{ $attributes } )
	{
		push(
			@attribute,
			SOAP::Data->name(
				'Attributes' => \SOAP::Data->value(
					SOAP::Data->name(
						'Name' => $name,
					),
					SOAP::Data->name(
						'Value' => $attributes->{$name},
					),
				),
			),
		);
	}

	return @attribute;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Email-ExactTarget/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Email::ExactTarget::SubscriberOperations


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
