package Elive::Entity;
use warnings; use strict;

use Mouse;
use Carp;

extends 'Elive::DAO';

our $VERSION = '1.37';

=head1 NAME

Elive::Entity - Base class for Elive Entities

=head1 DESCRIPTION

This is the base class for Elluminate C<Live!> Command Toolkit entity
specific classes.

=cut

=head2 data_classes

returns a list of all entity instance classes

=cut

sub data_classes {
    my $class = shift;
    return qw(
      Elive::Entity::Group
      Elive::Entity::MeetingParameters
      Elive::Entity::Meeting
      Elive::Entity::ParticipantList
      Elive::Entity::Preload
      Elive::Entity::Recording
      Elive::Entity::Report
      Elive::Entity::ServerDetails
      Elive::Entity::ServerParameters
      Elive::View::Session
      Elive::Entity::User
   );
}

=head2 connect

     Elive::Entity->connect('https://myServer.com/test', some_user => 'some_pass');
     my $connection = Elive::Entity->connection;

Connects to an Elluminate server instance. Dies if the connection could not
be established. If, for example, the SOAP connection or user login failed.

The login user must either be an Elluminate I<Live!> system administrator
account, or a user that has been configured to access the Command Toolkit
via web services.

=cut

sub connect {
    my ($class, $url, $login_name, $pass, %opts) = @_;

    Carp::croak("usage: ${class}->connect(url, [login_name] [, pass])")
	unless ($class && $url);

    require Elive::Connection::SDK;

    my $connection = Elive::Connection::SDK->connect(
	$url,
	$login_name => $pass,
	debug => $class->debug,
	%opts,
	);

    $class->_connection($connection);

    return $connection;
}

#
# Normalise our data and reconstruct arrays.
#
# See t/dao-unpack.t for examples and further explanation.
#

sub _get_results {
    my $class = shift;
    my $som = shift;
    my $connection = shift;

    $connection->_check_for_errors($som);

    my $results_list = $class->_unpack_as_list($som->result);

    return $results_list;
}

sub _unpack_as_list {
    my $class = shift;
    my $result = shift;

    $result = $class->_unpack_results($result);

    my $reftype = Elive::Util::_reftype($result);

    my $results_list;

    if ($reftype eq 'HASH') {

	$results_list = [ $result ];

    }
    elsif ($reftype eq 'ARRAY') {

	$results_list = $result;

    }
    elsif ($reftype) {
	Carp::croak "unknown type in result set: $reftype";
    }
    else {

	$results_list = defined($result) && $result ne ''
	    ? [ $result ]
	    : [];

    }

    warn "$class result: ".YAML::Syck::Dump($result)
	if ($class->debug >= 2);

    return $results_list;
}

sub _unpack_results {
    my $class = shift;
    my $results = shift;

    my $results_type = Elive::Util::_reftype($results);

    if (!$results_type) {
	return $results;
    }
    elsif ($results_type eq 'ARRAY') {
	return [map {$class->_unpack_results($_)} @$results];
    }
    elsif ($results_type eq 'HASH') {
	#
	# Convert some SOAP/XML constructs to their perl equivalents
	#
	foreach my $key (keys %$results) {
	    my $value = $results->{$key};

	    if ($key eq 'Collection') {

		if (Elive::Util::_reftype($value) eq 'HASH'
		    && exists ($value->{Entry})) {
		    $value = $value->{Entry};

		    my %parent = %$results;
		    delete $parent{Collection};
		    if (keys %parent) {
			#
			# merge in with the parent
			#
			$parent{Entry} = $value;
			$value = \%parent;
		    }
		}
		else {
		    $value = [];
		}
		#
		# Throw away our parse of this struct. It only exists to
		# house this collection
		#
		return $class->_unpack_results($value);
	    }
	    elsif ($key eq 'Map') {

		if (Elive::Util::_reftype($value) eq 'HASH') {

		    if (exists ($value->{Entry})) {

			$value = $value->{Entry};
			#
			# Looks like we've got Key, Value pairs.
			# Throw array the key and reference the value,
			# that's all we're interested in.
			#
			if (Elive::Util::_reftype ($value) eq 'ARRAY') {
		    
			    $value = [map {$_->{Value}} @$value];
			}
			else {
			    $value = $value->{Value};
			}
		    }
		}
		else {
		    $value = [];
		}
		#
		# Throw away our parse of this struct it only exists to
		# house this collection
		#
		return $class->_unpack_results($value);
	    }

	    $results->{$key} = $class->_unpack_results($value);
	}
	    
    }
    else {
	die "Unhandled type in response body: $results_type";
    }

    return $results;
}

=head2 quote

This is a utility method for quoting literal arguments to C<list> filter
expressions:

    my $users = Elive::Entity::User->list(
		    filter => "surname=".Elive::Entity::User->quote("O'Reilly"),
                );

=cut

sub quote {
    my $class = shift;
    my $str = shift;

    return $str
	if !defined $str
	or $str eq ''
	or $str =~ m{^ \w+ $}x;

    $str =~ s{'}{''}g;

    return "'$str'";
}

=head1 SEE ALSO

=head2 Ancestor Classes

=over 4

=item L<Elive::DAO> - base class

=item L<Mouse> - Middle-weight L<Moose> like class system

=back

=head2 Derived Classes

=over 4

=item Elive::Entity::Group

=item Elive::Entity::MeetingParameters

=item Elive::Entity::Meeting

=item Elive::Entity::ParticipantList

=item Elive::Entity::Preload

=item Elive::Entity::Recording

=item Elive::Entity::Report

=item Elive::Entity::ServerDetails

=item Elive::Entity::ServerParameters

=item Elive::Entity::Session

=item Elive::View::Session

=item Elive::Entity::User

=back

=cut

1;
