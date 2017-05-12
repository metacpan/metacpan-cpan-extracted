=encoding utf8

=cut

package Email::ExactTarget;

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use HTML::Entities qw();
use Data::Dumper;
use Carp;
use SOAP::Lite 0.71; #+trace => [qw (debug)];

use Email::ExactTarget::SubscriberOperations;


=head1 NAME

Email::ExactTarget - Interface to ExactTarget's API.


=head1 VERSION

Version 1.6.2

=cut

our $VERSION = '1.6.2';

our $ENDPOINT_LIVE = 'https://webservice.exacttarget.com/Service.asmx';

our $ENDPOINT_TEST = 'https://webservice.test.exacttarget.com/Service.asmx';

our $NAMESPACE = 'http://exacttarget.com/wsdl/partnerAPI';


=head1 SYNOPSIS

This module allows you to interact with Exact Target, an Email Service
Provider. It encapsulates all the communications with the API provided by Exact
Target to offer a Perl interface for managing lists and subscribers amongst
other features.

Please note that you will need to register with Exact Target first in order to
obtain an API key and password, as well as agree with the Terms and Conditions
for using the API.

	use Email::ExactTarget;

	# Create an object to communicate with Exact Target
	my $exact_target = Email::ExactTarget->new(
		'username'                => 'dummyusername',
		'password'                => 'dummypassword',
		'verbose'                 => 1,
		'unaccent'                => 1,
	);


=head1 METHODS

=head2 new()

Create a new Exact Target object that will be used as the interface with Exact
Target's API.

	my $exact_target = Email::ExactTarget->new(
		'username'                => 'dummyusername',
		'password'                => 'dummypassword',
		'verbose'                 => 2,
		'unaccent'                => 1,
	);

Creates a new object to communicate with Exact Target.

'username' and 'password' are mandatory.

The verbose parameter is optional and defaults to not verbose.

The 'unaccent' parameter is optional and defaults to 0. See the documentation
for unaccent() for more information.

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Check for deprecated parameters.
	carp "'all_subscribers_list_id' is not used anymore by Email::ExactTarget, please drop it from the list of arguments passed to Email::ExactTarget->new()"
		if exists( $args{'all_subscribers_list_id'} );

	# Check for mandatory parameters
	foreach my $arg ( qw( username password ) )
	{
		croak "Argument '$arg' is needed to create the Email::ExactTarget object"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}

	#Defaults.
	$args{'unaccent'} = 0
		unless defined( $args{'unaccent'} ) && ( $args{'unaccent'} eq '1' );
	$args{'use_test_environment'} = 0
		unless defined( $args{'use_test_environment'} ) && ( $args{'use_test_environment'} eq '1' );

	# Create the object
	my $self = bless(
		{
			'username'                => $args{'username'},
			'password'                => $args{'password'},
			'use_test_environment'    => $args{'use_test_environment'},
		},
		$class,
	);

	# Set properties for which we have a setter.
	$self->unaccent( $args{'unaccent'} );
	$self->verbose( $args{'verbose'} );

	return $self;
}


=head2 subscriber_operations()

Create a new Email::ExactTarget::SubscriberOperations object, which
will allow interacting with collections of
Email::ExactTarget::Subscriber objects.

	my $subscriber_operations = $exact_target->subscriber_operations();

=cut

sub subscriber_operations
{
	my ( $self, %args ) = @_;

	return Email::ExactTarget::SubscriberOperations->new( $self, %args );
}


=head1 GETTERS / SETTERS

=head2 unaccent()

Exact Target charges a fee to allow accentuated characters to be passed through
their API, and otherwise turns them into question marks (for example,
"Jérôme" would become "J?r?me"). The alternative is to preemptively transform
accentuated characters from the messages sent to Exact Target into their
unaccentuated version("Jérôme" would thus become "Jerome"), which is free and
degrades in an nicer way. To enable that automatic conversion to unaccentuated
characters, set this to 1.

	$exact_target->unaccent( 1 );

	if ( $exact_target->unaccent() )
	{
		# [...]
	}

=cut

sub unaccent
{
	my ( $self, $unaccent ) = @_;

	$self->{'unaccent'} = ( $unaccent || 0 )
		if defined( $unaccent );

	return $self->{'unaccent'};
}


=head2 verbose()

Control the verbosity of the warnings in the code.

	$exact_target->verbose( 1 ); # turn on verbose information

	$exact_target->verbose( 0 ); # quiet now!

	warn 'Verbose' if $exact_target->verbose(); # getter-style

=cut

sub verbose
{
	my ( $self, $verbose ) = @_;

	$self->{'verbose'} = ( $verbose || 0 )
		if defined( $verbose );

	return $self->{'verbose'};
}


=head2 get_all_subscribers_list_id()

Discontinued, this method will be removed soon.

=cut

sub get_all_subscribers_list_id
{
	carp 'get_all_subscribers_list_id() is deprecated!';

	return undef;
}


=head2 use_test_environment()

Return a boolean indicating whether the test environment is used in requests.

	my $use_test_environment = $exact_target->use_test_environment();

=cut

sub use_test_environment
{
	my ( $self ) = @_;

	return $self->{'use_test_environment'} ? 1 : 0;
}


=head1 GENERAL WEBSERVICE INFORMATION

=head2 version_info()

Deprecated.

=cut

sub version_info
{
	my ( $self ) = @_;

	my $soap_args =
	[
		SOAP::Data->name(
			IncludeVersionHistory => 'true'
		)->type('boolean')
	];

	my $soap_response = $self->soap_call(
		'action'    => 'VersionInfo',
		'method'    => 'VersionInfoRequestMsg',
		'arguments' => $soap_args,
	);

	croak $soap_response->fault()
		if defined( $soap_response->fault() );

	return $soap_response->result();
}


=head2 get_system_status()

See L<http://wiki.memberlandingpages.com/API_References/Web_Service_Guide/Methods/GetSystemStatus>

Returns the system status information given by the webservice.

Return example:

	{
		'StatusCode'    => 'OK',
		'SystemStatus'  => 'OK',
		'StatusMessage' => 'System Status Retrieved',
	};

=cut

sub get_system_status
{
	my ( $self ) = @_;

	my $soap_response = $self->soap_call(
		'action'    => 'GetSystemStatus',
		'method'    => 'GetSystemStatusRequestMsg',
		'arguments' => [],
	);
	my $soap_results = $soap_response->result();

	# Check for errors.
	croak $soap_response->fault()
		if defined( $soap_response->fault() );
	croak 'No results found.'
		unless defined( $soap_results->{'Result'} );

	return $soap_results->{'Result'};
}


=head1 INTERNAL METHODS

=head2 soap_call()

Internal, formats the SOAP call with the arguments provided and checks the
reply.

	my ( $error, $response_data ) = $exact_target->soap_call(
		'action'    => $method,
		'arguments' => $arguments,
	);

=cut

sub soap_call
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	my $use_test_environment = $self->use_test_environment();
	my $endpoint = $use_test_environment
		? $ENDPOINT_TEST
		: $ENDPOINT_LIVE;

	# Check the parameters.
	confess 'You must define a SOAP action'
		if !defined( $args{'action'} ) || ( $args{'action'} eq '' );
	confess 'You must define a SOAP method'
		if !defined( $args{'method'} ) || ( $args{'method'} eq '' );
	$args{'arguments'} ||= [];

	# Do not forget to specify the soapaction (on_action), you will find it in the
	# wsdl.
	#    - uri is the target namespace in the wsdl
	#    - proxy is the endpoint address
	my $soap = SOAP::Lite
		->uri( $NAMESPACE )
		->on_action( sub { return '"' . $args{'action'} . '"' } )
		->proxy( $endpoint )
		->readable( ( $verbose ? 1 : 0 ) );

	# You must define the namespace used in the wsdl, as an attribute to the
	# method without namespace prefix for compatibility with .NET
	# (document/literal).
	my $method = SOAP::Data->name( $args{'method'} )
		->attr( { xmlns => $NAMESPACE } );

	# SOAP envelope headers. SOAP API requires addressing, security extensions.
	#
	# <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
	#   <wsse:UsernameToken>
	#     <wsse:Username>username</wsse:Username>
	#     <wsse:Password>password</wsse:Password>
	#   </wsse:UsernameToken>
	# </wsse:Security>
	my @header = (
		SOAP::Header
			->name( Action => $args{'action'} )
			->uri( 'http://schemas.xmlsoap.org/ws/2004/08/addressing' )
			->prefix( 'wsa' ),
		SOAP::Header
			->name( To => $endpoint )
			->uri( 'http://schemas.xmlsoap.org/ws/2004/08/addressing' )
			->prefix( 'wsa' ),
		SOAP::Header
			->name(
				Security => \SOAP::Data->value(
					SOAP::Data->name(
						UsernameToken => \SOAP::Data->value(
							SOAP::Data->name( Username => $self->{'username'} )->prefix( 'wsse' ),
							SOAP::Data->name( Password => $self->{'password'} )->prefix( 'wsse' )
						)
					)->prefix('wsse')
				)
			)
			->uri( 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' )
			->prefix( 'wsse' )
	);

	# Make the call to the webservice.
	my $soap_response = $soap->call(
		@header,
		$method,
		@{ $args{'arguments'} }
	);

	# Print some debugging information if requested.
	if ( $verbose )
	{
		carp 'Fault: ' . Dumper( $soap_response->fault() )
			if defined( $soap_response->fault() );

		carp 'Result: ' . Dumper( [ $soap_response->result() ] )
			if defined( $soap_response->result() );

		carp 'Params out: ' . Dumper( $soap_response->paramsout() )
			if defined( $soap_response->paramsout() );
	}

	return $soap_response;
}


=head1 RUNNING TESTS

By default, only basic tests that do not require a connection to ExactTarget's
platform are run in t/.

To run the developer tests, you will need to do the following:

=over 4

=item *

Request access to the test environment from ExactTarget (recommended) unless
you want to run the tests in your production environment (definitely NOT
recommended).

=item *

Ask ExactTarget to enable the webservice access for you, if not already set up.
It appears to be a customer-level property only ExactTarget can change.

=item *

In ExactTarget's interface, you will need to log in as an admin, then go to the
"Admin" tab, "Account Settings > My Users". Then create a user with "API User"
set to "Yes".

=item *

Go to the "Subscribers" tab, then "My Subscribers". If you look at the
properties for the list named "All Subscribers", you will see a field named
"ID". This is your "All Subscribers List ID", make a note of it.

=item *

Back to "My Subscribers", create at least two new lists and make a note of their
IDs.

=back

You can now create a file named ExactTargetConfig.pm in your own directory, with
the following content:

	package ExactTargetConfig;

	# The arguments that will be passed to Email::ExactTarget->new() when
	# instantiating new objects during testing.
	sub new
	{
		return
		{
			username                => 'username', # The username of the test account you created.
			password                => 'password', # The password of the test account you created.
			verbose                 => 0,
			unaccent                => 1,
			use_test_environment    => 1,
		};
	}

	# 'All Subscribers' is a special list in ExactTarget. If a user is
	# subscribed to a list but not the 'All Subscribers' list, the user
	# won't get any email.
	sub get_all_subscribers_list_id
	{
		# The ID of the 'All Subscribers' list that exists by default
		# in ExactTarget.
		return 00000;
	}

	# Tests cover adding/removing users from lists, this is an arrayref of
	# list IDs to use during those tests. Two list IDs are required.
	sub get_test_list_ids
	{
		return
		[
			# The IDs of the test lists you created.
			000000,
			000000,
		];
	}

	1;

You will then be able to run all the tests included in this distribution, after
adding the path to ExactTargetConfig.pm to your library paths.


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Email-ExactTarget/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Email::ExactTarget


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


=head1 ACKNOWLEDGEMENTS

I originally developed this project for ThinkGeek
(L<http://www.thinkgeek.com/>). Thanks for allowing me to open-source it!


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
