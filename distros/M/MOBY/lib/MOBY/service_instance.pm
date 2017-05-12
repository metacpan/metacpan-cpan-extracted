package MOBY::service_instance;
use SOAP::Lite;
use strict;
use Carp;
use vars qw($AUTOLOAD @ISA);
use MOBY::central_db_connection;
use MOBY::OntologyServer;
use MOBY::authority;
use MOBY::Config;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

#@ISA = qw(MOBY::central_db_connection);  # can't do this yet...

=head1 NAME

MOBY::service_instance - a lightweight connection to the
service_instance table in the database

=head1 SYNOPSIS

 use MOBY::service_instance;
 my $Instance = MOBY::service_instance->new(
     authority => $AUTHORITY,
     servicename => 'marksFabulousService',
     service_type => $SERVICE_TYPE,
	 category => 'moby',
     url => "http://www.illuminae.com/mobyservice.pl",
     contact_email => "markw@illuminae.com",
     authoritative => 1,
     inputs => \@inputs,
     output => \@outputs,
     description => 'retrieves random sequences from a database');

 print $Instance->service_instance_id;
 print $Instance->authority->authority_common_name;


=cut

=head1 DESCRIPTION

representation of the service_instance table.  Can write to the database

=head1 AUTHORS

Mark Wilkinson (mwilkinson@mrl.ubc.ca)


=cut

{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		service_instance_id => [ undef, 'read/write' ],
		category            => [ undef, 'read/write' ],
		servicename         => [ undef, 'read/write' ],
		_authority          => [ undef, 'read/write' ],   # the authority object
		service_type        => [ undef, 'read/write' ],
		service_type_uri    => [ undef, 'read/write' ],
		authority           => [ undef, 'read/write' ],
		authority_uri       => [ undef, 'read/write' ],
		signatureURL        => [ undef, 'read/write' ],
		url                 => [ undef, 'read/write' ],
		inputs              => [ undef, 'read/write' ],
		outputs             => [ undef, 'read/write' ],
		secondaries         => [ undef, 'read/write' ],
		contact_email       => [ undef, 'read/write' ],
		authoritative       => [ 0,     'read/write' ],
		description         => [ undef, 'read/write' ],
		registry 	    => [ 'MOBY_Central', 'read/write' ],		
		lsid 			=> [ undef, 'read/write' ],
		test     		=> [ 0,              'read/write' ]
		,    # toggles create or test_existence behaviour
	  );

	#_____________________________________________________________
	# METHODS, to operate on encapsulated class data
	# Is a specified object attribute accessible in a given mode
	sub _accessible {
		my ( $self, $attr, $mode ) = @_;
		$_attr_data{$attr}[1] =~ /$mode/;
	}

	# Classwide default value for a specified object attribute
	sub _default_for {
		my ( $self, $attr ) = @_;
		$_attr_data{$attr}[0];
	}

	# List of names of all specified object attributes
	sub _standard_keys {
		keys %_attr_data;
	}

	sub service_name
	{ # give them a break if they chose service_name or servicename as the parameter
		my ( $self, $val ) = @_;
		if ( defined $val ) {
			if ( defined $self->{servicename} ) {
				return
				  undef # you are not allowed to change it once it has been set!
			} else {
				$self->{servicename} = $val;
			}
		}
		return $self->{servicename};
	}

	sub category {
		my ( $self, $val ) = @_;
		if ( ( defined $val ) && $self->category ) { return undef }
		( defined $val ) && ( $self->{category} = $val );
		return $self->{category};
	}

	sub service_type {
		my ( $self, $val ) = @_;
		if ( defined $val && $self->service_type ) { return undef }
		( defined $val ) && ( $self->{service_type} = $val );
		return $self->{service_type};
	}

	sub url {
		my ( $self, $val ) = @_;
		if ( defined $val && $self->url ) { return undef }
		( defined $val ) && ( $self->{url} = $val );
		return $self->{url};
	}

	sub signatureURL {
		my ( $self, $val ) = @_;
		if ( defined $val && $self->signatureURL ) { return undef }
		( defined $val ) && ( $self->{signatureURL} = $val );
		return $self->{signatureURL};
	}

	sub contact_email {
		my ( $self, $val ) = @_;
		if ( defined $val && $self->contact_email ) { return undef }
		( defined $val ) && ( $self->{contact_email} = $val );
		return $self->{contact_email};
	}

	sub description {
		my ( $self, $val ) = @_;
		if ( defined $val && $self->description ) { return undef }
		( defined $val ) && ( $self->{description} = $val );
		return $self->{description};
	}

	sub dbh {
		$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
		my $adaptor =
		  $CONFIG->getDataAdaptor( datasource => 'mobycentral' )->dbh;
	}

	sub adaptor {
		$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
		my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );
	}
}

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref($caller);
	return $caller if $caller_is_obj;
	my $class = $caller_is_obj || $caller;
	my $proxy;
	my ($self) = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ($caller_is_obj) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for($attrname);
		}
	}
	return undef unless $self->authority_uri;
	return undef unless $self->servicename;
	if( $self->lsid){
		my $l = $self->lsid;  # but is LSID valid format?
		return undef unless $l =~ m'^[uU][rR][nN]:[lL][sS][iI][dD]:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*:\d\d\d\d-\d\d\-\d\dT\d\d\-\d\d\-\d\d(Z|[\+|-]\d\d\d\d){1,1}$';
	}
	if ( $self->test ) { return $self->service_instance_exists }  # returns boolean

	$self->authority( $self->_get_authority() ); # as MOBY::authority object

	if ( $self->service_type ) {
		my $OE = MOBY::OntologyServer->new( ontology => 'service' );
		my ( $success, $message, $servicetypeURI ) =
		  $OE->serviceExists( term => $self->service_type );
		unless (
			$success || ( ( $self->service_type =~ /urn:lsid/i ) && !( $self->service_type =~ /urn:lsid:biomoby.org/i ) )
			)
		{
			return undef;
		}
		( $self->service_type =~ /urn:lsid/ )?
		$self->service_type_uri( $self->service_type )
		: $self->service_type_uri($servicetypeURI);
	}
	my $existing_services = $self->adaptor->query_service_instance(servicename => $self->servicename,
								      authority_uri => $self->authority_uri);
	my $existing_service = shift(@$existing_services);
	if ($existing_service->{servicename}) { # if service exists, then instantiate it from the database retrieval we just did
		$self->servicename( $existing_service->{'servicename'} );
		$self->authoritative( $existing_service->{'authoritative'} );
		$self->service_instance_id( $existing_service->{'service_instance_id'} );
		$self->category( $existing_service->{'category'} );
		$self->service_type( $existing_service->{'service_type_uri'} );
		$self->url( $existing_service->{'url'} );
		$self->contact_email( $existing_service->{'contact_email'} );
		$self->description( $existing_service->{'description'} );
		$self->authority( $existing_service->{'authURI'} );
		$self->signatureURL( $existing_service->{'signatureURL'} );
		$self->lsid( $existing_service->{'lsid'} );
		$self->{__exists__} = 1;    # this service already existed
	} elsif (!($existing_service->{servicename})        # if it doesn't exist
		&& (defined $self->category)    # and you have given me things I need to create it
		&& ( defined $self->service_type )
		&& ( defined $self->url )
		&& ( defined $self->contact_email )
		&& ( defined $self->description )
	  ) {        # then create it de novo if we have enough information
		# create a timestamp for the LSID
		my ($sec,$min,$hour,$mday,$month,$year, $wday,$yday,$dst) =gmtime(time);
		my $date = sprintf ("%04d-%02d-%02dT%02d-%02d-%02dZ",$year+1900,$month+1,$mday,$hour,$min,$sec);

		#create LSID for service and register it in the DB
		my $_config ||= MOBY::Config->new;
		unless ($self->lsid){
			# create an LSID if one wasnt passed in
			my $LSID_Auth = $_config->{mobycentral}->{lsid_authority};
			my $LSID_NS = $_config->{mobycentral}->{lsid_namespace};
			$LSID_Auth ||="biomoby.org";
			$LSID_NS ||="serviceinstance";
			
# TODO - # MOBY Central should validate the format of authority uri and servicename when it starts up, sice we are using them to construct LSID's			
			my $service_lsid = "urn:lsid:$LSID_Auth:$LSID_NS:"
			  . $self->authority_uri . "," 
			  . $self->servicename.":"."$date";  # LSID with timestamp
			$self->lsid($service_lsid);		
		}
		my $id = $self->adaptor->insert_service_instance(
			category         => $self->category,
			servicename      => $self->servicename,
			service_type_uri => $self->service_type_uri,
			authority_uri    => $self->authority_uri,
			url              => $self->url,
			contact_email    => $self->contact_email,
			authoritative    => $self->authoritative,
			description      => $self->description,
			signatureURL     => $self->signatureURL,
			lsid             => $self->lsid
		);
		return undef unless $id;
		$self->service_instance_id($id);
		$self->{__exists__} = 1;    # this service now exists
	} else { # if it doesn't exist, and you havne't given me anyting I need to create it, then bail out
		return undef;
	}
	return $self;
}

sub DELETE_THYSELF {
	my ($self) = @_;
	my $dbh = $self->dbh;
	unless ( $self->{__exists__} ) {
		return undef;
	}
	$CONFIG ||= MOBY::Config->new;
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

#********FIX  this should really be delete_input and delete_output
# the routines below know too much about the database (e.g. that
# the delete_simple_input routines are broken into two parts - by LSID and
# by collecion ID...  BAD BAD BAD
	$adaptor->delete_simple_input(service_instance_lsid => $self->lsid);
	$adaptor->delete_simple_output(service_instance_lsid => $self->lsid);
	
	my $result = $adaptor->query_collection_input(service_instance_lsid => $self->lsid);
	
	foreach my $row (@$result) {
		my $id = $row->{collection_input_id};
		$adaptor->delete_simple_input(collection_input_id => $id);
	}
	$result = $adaptor->query_collection_output(service_instance_lsid => $self->lsid);
	
	foreach my $row (@$result) {
		my $id = $row->{collection_output_id};
		
		$adaptor->delete_simple_output(collection_output_id => $id);
	}
	$adaptor->delete_collection_input(service_instance_lsid => $self->lsid);
	$adaptor->delete_collection_output(service_instance_lsid => $self->lsid);
	$adaptor->delete_secondary_input(service_instance_lsid => $self->lsid);
	$adaptor->delete_service_instance(service_instance_lsid => $self->lsid);
			
	return 1;
}

sub authority_id {
	my ($self) = @_;
	return $self->authority->authority_id;
}

sub service_instance_exists {
	my ($self) = @_;
	$CONFIG ||= MOBY::Config->new;
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );
	my $dbh = $self->dbh;
	my $authority;

	my $result = $adaptor->query_service_existence(authority_uri => $self->authority_uri, servicename => $self->servicename);
	return $result
}

sub _get_authority
{ # there's somethign fishy here... the authority.pm object already knows about authority_id and authorty_uri, doens't it?
	my ($self) = @_;
	my $dbh = $self->dbh;
	my $authority;
	$CONFIG ||= MOBY::Config->new;
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );	
	my $result = $adaptor->query_authority(authority_uri => $self->authority_uri);
#*********FIX we should nver need to know the authority ID in this level of code!
	if ( @$result[0]) {
		my $row = shift(@$result);
		#my $id = $row->{authority_id};
		my $name = $row->{authority_common_name};
		my $uri = $row->{authority_uri};
		my $email = $row->{contact_email};

		$authority = MOBY::authority->new(
			dbh           => $self->dbh,
#			authority_id  => $id,
			authority_uri => $uri,
			contact_email => $email,
		);
	} else {
		$authority = MOBY::authority->new(
			dbh           => $self->dbh,
			authority_uri => $self->authority_uri,
			contact_email => $self->contact_email,
		);
	}
	return $authority;
}

sub add_simple_input {
	my ( $self, %a ) = @_;

	# validate here... one day...
	my $simple = MOBY::simple_input->new(
		object_type_uri     => $a{'object_type_uri'},
		namespace_type_uris => $a{'namespace_type_uris'},
		article_name        => $a{'article_name'},
		service_instance_id => $self->service_instance_id,
		service_instance_lsid => $self->lsid,
		collection_input_id => $a{'collection_input_id'}
	);
	push @{ $self->{inputs} }, $simple;
	return $simple->simple_input_id;
}

sub add_simple_output {
	my ( $self, %a ) = @_;

	# validate here... one day...
	my $simple = MOBY::simple_output->new(
		object_type_uri     => $a{'object_type_uri'},
		namespace_type_uris => $a{'namespace_type_uris'},
		article_name        => $a{'article_name'},
		service_instance_id => $self->service_instance_id,
		service_instance_lsid => $self->lsid,
		collection_output_id => $a{'collection_output_id'}
	);
	push @{ $self->{outputs} }, $simple;
	return $simple->simple_output_id;
}

sub add_collection_input {
	my ( $self, %a ) = @_;

	# validate here... one day...
	my $coll = MOBY::collection_input->new(
		article_name        => $a{'article_name'},
		service_instance_lsid => $self->lsid,
		service_instance_id => $self->service_instance_id, );
	push @{ $self->{inputs} }, $coll;
	return $coll->collection_input_id;
}

sub add_collection_output {
	my ( $self, %a ) = @_;

	# validate here... one day...
	my $coll = MOBY::collection_output->new(
		article_name        => $a{'article_name'},
		service_instance_lsid => $self->lsid,
		service_instance_id => $self->service_instance_id, );
	push @{ $self->{outputs} }, $coll;
	return $coll->collection_output_id;
}

sub add_secondary_input {
	my ( $self, %a ) = @_;

	# validate here... one day...
	my $sec = MOBY::secondary_input->new(
		default_value       => $a{'default_value'},
		maximum_value       => $a{'maximum_value'},
		minimum_value       => $a{'minimum_value'},
		enum_value          => $a{'enum_value'},
		datatype            => $a{'datatype'},
		article_name        => $a{'article_name'},
		description		=> $a{'description'},
		service_instance_id => $self->service_instance_id,
		service_instance_lsid => $self->lsid,
	);
	push @{ $self->{inputs} }, $sec;
	return $sec->secondary_input_id;
}

sub AUTOLOAD {
	no strict "refs";
	my ( $self, $newval ) = @_;
	$AUTOLOAD =~ /.*::(\w+)/;
	my $attr = $1;
	if ( $self->_accessible( $attr, 'write' ) ) {
		*{$AUTOLOAD} = sub {
			if ( defined $_[1] ) { $_[0]->{$attr} = $_[1] }
			return $_[0]->{$attr};
		};    ### end of created subroutine
###  this is called first time only
		if ( defined $newval ) {
			$self->{$attr} = $newval;
		}
		return $self->{$attr};
	} elsif ( $self->_accessible( $attr, 'read' ) ) {
		*{$AUTOLOAD} = sub {
			return $_[0]->{$attr};
		};    ### end of created subroutine
		return $self->{$attr};
	}

	# Must have been a mistake then...
	croak "No such method: $AUTOLOAD";
}
sub DESTROY { }
1;
