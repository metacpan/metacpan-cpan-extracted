package t::Elive::MockConnection;
use warnings; use strict;

=head1 NAME

t::Elive::MockConnection

=head1 DESCRIPTION

A partial emulation of the SOAP connection and database backend.

=cut

use parent 'Elive::Connection::SDK';

use Elive;
use Elive::Entity;
use Elive::Entity::User;
use Elive::Entity::ServerDetails;

use YAML::Syck;

use t::Elive::MockSOM;

__PACKAGE__->mk_accessors( qw{mockdb server_details_id} );

sub connect {
    goto \&_connect;
}

sub _connect {
    my ($class, $url,  $user, $pass, %opt) = @_;

    my $self = {};
    bless $self, $class;

    $url ||= 'http://elive_mock_connection';
    $url =~ s{/$}{};                    # lose trailing '/'
    $url =~ s{/webservice\.event$}{};   # lose endpoint
    $url =~ s{/v[1-9]$}{};                  # lose adapter path

    if ($url =~ s{^(\w+)://(.*)\@}{$1://}) {  # lose/capture credentials

	my ($_user, $_pass) = split(':', $2, 2);

	$user ||= $_user;
	$pass ||= $_pass if $_pass;
    }

    $self->url($url);

    $self->user($user);
    $self->user('test_user') unless $self->user;

    $self->pass($pass);
    $self->pass('test_pass') unless $self->pass;

    $self->debug($opt{debug})
	if defined $opt{debug};

    $self->mockdb({});

    Elive::Entity::User->insert(
	{loginName => $self->user,
	 loginPassword => $self->pass,
	 role => {roleId => 0},
	},
	connection => $self,
	);

    #
    # Pretend that we can insert a server details record. Just for the
    # purposes of our mockup
    #
    local($self->known_commands->{createServerDetails}) = 'c';

    my $server_details = Elive::Entity::ServerDetails->insert(
	{
	 version => '9.6.0',
	 alive => 1,
	},
	connection => $self,
	);

    $self->server_details_id( $server_details->serverDetailsId );

    return $self;
}

sub call {
    my $self = shift;
    my $cmd = shift;

    my %params = @_;

    my $known_commands = $self->known_commands;
    $self->check_command($cmd);

    my $entities = Elive::Entity->entities;
    my %collections =
	(map {@$_}
	 grep {$_[0]}
	 map {[($_->collection_name||'') => $_]}
	 (values %$entities)
	);
    #
    # Determine an operation for the command
    #
    my $crud = $known_commands->{$cmd};
    die "Uknown command $cmd in mock connection"
	unless $crud;

    my $som = bless {}, 't::Elive::MockSOM';

    my ($op, $entity_name) = ($cmd =~ m{^(add|get|create|check|delete|update|list)(.*)$});

    $entity_name = 'User' if $cmd eq 'changePassword';

    if ($entity_name) {

	$entity_name = lcfirst($entity_name);

	if (my $entity_class = ($entities->{$entity_name} || $collections{$entity_name})) {

	    #
	    # dereference aliases
	    #
	    my %aliases = $entity_class->_to_aliases;
	    for (grep {exists $params{$_}} (keys %aliases)) {
		my $att = $aliases{$_};
		$params{$att} = delete $params{$_};
	    }

	    my @primary_key = @{ $entity_class->_primary_key };

	    $params{$primary_key[0]} ||= $self->server_details_id
		if $entity_name eq 'serverDetails';

	    warn YAML::Syck::Dump {cmd => $cmd, params => \%params}
	    if ($self->debug||0) >= 3;

	    if ($crud eq 'c') {
		foreach my $fld (@primary_key) {

		    if (defined $params{$fld}) {
			if (my $isa = $entity_class->_isa) {
			    #
			    # Isa relation. E.g. MeetingParameters isa Meeting
			    # (check on existance of primary entity to go here)
			    #
			    next;
			}
			die "not allowing insert with preallocated key $fld for $entity_name";
		    }

		    $params{$fld} = do {
			my $id;
			my $ctr;
			do {
			    $id = sprintf("%d", rand(32767) + 1);
			    die "mockup primary keys exhausted for $entity_name?"
				if (++$ctr > 10000);
			} while exists $self->mockdb->{__IDS__}{$entity_name}{$id};

			$self->mockdb->{__IDS__}{$entity_name}{$id} = $id;
		    }
		}

		foreach (keys %params) {
		    die "undefed param: $_"
			unless defined $params{$_};
		}

		my $pkey = $params{$primary_key[0]};
		my $som = t::Elive::MockSOM->make_result($entity_class, \%params);		
		$self->mockdb->{$entity_name}{ $pkey } = \%params;

		if ($entity_name eq 'meeting') {
		    local ($self->known_commands->{createServerParameters}) = 'c';
		    local ($self->known_commands->{createMeetingParameters}) = 'c';
		    $self->call('createServerParameters',
				meetingId => $pkey,
				seats => $params{seats}||0);
		    $self->call('createMeetingParameters',
				meetingId => $pkey,
				recordingStatus => 'remote',
			);
		}

		return $som;
	    }
	    elsif ($crud eq 'u') {

		foreach my $fld (@primary_key) {
		    
		    die "missing key field $fld for $entity_name"
			if !defined $params{$fld};
		}

		my $pkey = $params{$primary_key[0]};

		die "entity $entity_name $primary_key[0]=$pkey - not found"
		    unless $self->mockdb->{$entity_name}{ $pkey };

		foreach (keys %params) {
		    my $val = $params{$_};
		    if (defined $val) {
			$self->mockdb->{$entity_name}{ $pkey }{$_} = $val;
		    }
		    else {
			delete $self->mockdb->{$entity_name}{ $pkey }{$_};
		    }
		}

		my $data = $self->mockdb->{$entity_name}{ $pkey };
		my $som = t::Elive::MockSOM->make_result($entity_class, $data);
		return $som;
	    }
	    elsif ($op eq 'list') {
		my $data = $self->mockdb->{$entity_name} || [];

		if (%params) {
		    my $properties = $entity_class->property_types;

		    foreach my $property (%params) {
			my $value = $params{$property};
			next unless defined $value;

			die "$entity_class: don't know how to list propertiy: $property"
			    unless exists $properties->{$property};
			$data = [grep {defined $_->{$property} && $_->{$property} eq $value} @$data];
		    }
		}
		#
		# other possible parameter is filter => <expr>. This would take
		# some work to implement!
		#

		return t::Elive::MockSOM->make_result($entity_class, @$data);
	    }
	    elsif ($crud eq 'r') {
		my $data;

		my $pkey = $params{$primary_key[0]};

		if ($entity_name eq 'user') {

		    my $user = $params{loginName} || $params{userName} || $params{userId};
		    #
		    # users can be retrieved by userId or loginName
		    #
		    if ($user) {
			my ($_data) = grep {$_->{loginName} eq $user || $_->{userId} eq $user} values %{  $self->mockdb->{$entity_name} || {} };
			if ($_data) {
			    $pkey = $_data->{userId}
			}
			else {
			    $pkey = '';
			}
		    }
		    else {
			die "attempt to fetch user without loginName or userId"
		    }
		}
		else {
		    die "get without primary key: $primary_key[0]"
			unless $pkey;
		}

		$data = $self->mockdb->{$entity_name}{ $pkey };

		#
		# user passwords are not returned
		#

		return $data
		    ? t::Elive::MockSOM->make_result($entity_class, $data)
		    : t::Elive::MockSOM->not_found();
	    }
	    elsif ($crud eq 'd') {

		foreach (@primary_key) {
		    die "attempted delete of $entity_name without primary key value for $_"
			unless defined $params{$_};
		}

		my $pkey = $params{$primary_key[0]};
		my $data = $self->mockdb->{$entity_name}{ $pkey };
		die "entity not found: $entity_name/$pkey"
		    unless $data;

		delete $self->mockdb->{$entity_name}{ $pkey };

		my $result = t::Elive::MockSOM->make_result($entity_class, $data);
		return $result;
	    }
	    else {
		die "unable to handle $crud mockup for $cmd";
	    }
	}
	else {
	    die "unknown entity: $entity_name";
	}
    }

    die "tba cmd: $cmd, crud $crud";
}

1;
