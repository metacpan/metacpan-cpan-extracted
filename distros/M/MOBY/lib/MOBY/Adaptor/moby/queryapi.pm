#$Id: queryapi.pm,v 1.3 2008/09/02 13:09:30 kawas Exp $
package MOBY::Adaptor::moby::queryapi;
use strict;
use Carp;
use vars qw($AUTOLOAD);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Adaptor::moby::queryapi - An interface definition for MOBY Central underlying data-stores

=cut

=head1 SYNOPSIS

 use MOBY::Adaptor::moby::queryapi::mysql  # implements this interface def
 my $m = MOBY::Adaptor::moby::queryapi::mysql->new(
    username => 'user',
    password => 'pass',
    dbname => 'mobycentral',
    port => '3306',
    sourcetype => 'DBD::mysql');
 my $objectid = $m->insert_object(
    {object_type => "MyObject"},
    {description => "this represents a foo bar"},
    {authority => "www.example.org"},
    {contact_email, 'me@example.org'})


=cut

=head1 DESCRIPTION

This is an interface definition. There is NO implementation in this module
with the exception that certain calls to required parameters have get/setter
functions in this module (that can be overridden)

=head1 AUTHORS

Mark Wilkinson markw_at_ illuminae dot com
Dennis Wang oikisai _at_ hotmail dot com
BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS


=head2 new

 Title     :	new
 Usage     :	my $MOBY = MOBY::Client::Central->new(%args)
 Function  :	connect to one or more MOBY-Central
                registries for searching
 Returns   :	MOBY::Client::Central object
 Args      :    
 Notes     :    


=cut


sub new {
	my ($caller, %args) = @_;
	my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;

    my $self = bless {}, $class;

    foreach my $attrname ( $self->_standard_keys_a ) {
    	if (exists $args{$attrname} && defined $args{$attrname}) {
		$self->{$attrname} = $args{$attrname} }
    elsif ($caller_is_obj) {
		$self->{$attrname} = $caller->{$attrname} }
    else {
		$self->{$attrname} = $self->_default_for($attrname) }
    }
    return $self;    
}


# Modified by Dennis

{
	#Encapsulated class data
	
	#___________________________________________________________
	#ATTRIBUTES
    my %_attr_data = #     				DEFAULT    	ACCESSIBILITY
                  (
				   username		=>  [undef, 		'read/write'],
				   password		=>  [undef, 		'read/write'],
				   dbname		=>  [undef,		'read/write'],
				   port			=>  [undef,		'read/write'],
				   proxy		=>  [undef,		'read/write'],
				   url			=>  [undef,		'read/write'],
				   driver		=>  [undef, 		'read/write'],
                    );

   #_____________________________________________________________

    # METHODS, to operate on encapsulated class data

    # Is a specified object attribute accessible in a given mode
    sub _accessible  {
	my ($self, $attr, $mode) = @_;
	$_attr_data{$attr}[1] =~ /$mode/
    }

    # Classwide default value for a specified object attribute
    sub _default_for {
	my ($self, $attr) = @_;
	$_attr_data{$attr}[0];
    }

    # List of names of all specified object attributes
    sub _standard_keys_a {
	keys %_attr_data;
    }

=head2 username

 Title     :	username
 Usage     :	my $un = $API->username($arg)
 Function  :	get/set username (if required)
 Returns   :	String (username)
 Args      :    String (username) - optional.

=cut


	sub username {
		my ($self, $arg) = @_;
		$self->{username} = $arg if defined $arg;
		return $self->{username};
	}

=head2 password

 Title     :	password
 Usage     :	my $un = $API->password($arg)
 Function  :	get/set password (if required)
 Returns   :	String (password)
 Args      :    String (password) - optional.

=cut

	sub password {
		my ($self, $arg) = @_;
		$self->{password} = $arg if defined $arg;
		return $self->{password};
	}

=head2 dbname

 Title     :	dbname
 Usage     :	my $un = $API->dbname($arg)
 Function  :	get/set dbname (if required)
 Returns   :	String (dbname)
 Args      :    String (dbname) - optional.

=cut

	sub dbname {
		my ($self, $arg) = @_;
		$self->{dbname} = $arg if defined $arg;
		return $self->{dbname};
	}

=head2 port

 Title     :	port
 Usage     :	my $un = $API->port($arg)
 Function  :	get/set port (if required)
 Returns   :	String (port)
 Args      :    String (port) - optional.

=cut


	sub port {
		my ($self, $arg) = @_;
		$self->{port} = $arg if defined $arg;
		return $self->{port};
	}

=head2 proxy

 Title     :	proxy
 Usage     :	my $un = $API->proxy($arg)
 Function  :	get/set proxy (if required)
 Returns   :	String (proxy)
 Args      :    String (proxy) - optional.

=cut

	sub proxy {
		my ($self, $arg) = @_;
		$self->{proxy} = $arg if defined $arg;
		return $self->{proxy};
	}


=head2 sourcetype

 Title     :	sourcetype
 Usage     :	my $un = $API->sourcetype($arg)
 Function  :	get/set string name of sourcetype (e.g. mySQL)
 Returns   :	String (sourcetype)
 Args      :    String (sourcetype) - optional.

=cut

	sub sourcetype {
		my ($self, $arg) = @_;
		$self->{sourcetype} = $arg if defined $arg;
		return $self->{sourcetype};
	}


=head2 driver

 Title     :	driver
 Usage     :	my $un = $API->driver($arg)
 Function  :	get/set string name of DSI driver module (e.g. DBI:mySQL)
 Returns   :	String (driver)
 Args      :    String (driver) - optional.

=cut

	sub driver {
		my ($self, $arg) = @_;
		$self->{driver} = $arg if defined $arg;
		return $self->{driver};
	}


=head2 url

 Title     :	url
 Usage     :	my $un = $API->url($arg)
 Function  :	get/set url (if required)
 Returns   :	String (url)
 Args      :    String (url) - optional.

=cut

	sub url {
		my ($self, $arg) = @_;
		$self->{url} = $arg if defined $arg;
		return $self->{url};
	}

	sub _implementation {
		my ($self, $arg) = @_;
		$self->{'_implementation'} = $arg if defined $arg;
		return $self->{'_implementation'};
	}

=head2 dbh

 Title     :	dbh
 Usage     :	my $un = $API->dbh($arg)
 Function  :	get/set database handle (if required)
 Returns   :	Database handle in whatever object is appropriate for sourcetype
 Args      :    Database handle in whatever object is appropriate for sourcetype

=cut

	sub dbh {
		my ($self, $arg) = @_;
		$self->{dbh} = $arg if defined $arg;
		return $self->{dbh};
	}
	
}

# this should replace all other delete_*_input
# still incomplete
sub delete_inputs{
	die "delete_inputs not implemented in adaptor\n";
}

#still incomplete 
sub delete_output {  # this should replace all other delete_*_output
    die "delete_output not implemented in adaptor\n";
}

#
# collection_input table functions
#

=head2 query_collection_input

 Title     :	query_collection_input
 Usage     :	my $un = $API->query_collection_input(%arg)
 Function  :	get the collection input information for a given service
 Args      :    service_lsid => String
 Returns   :    listref of hashrefs:
                [{collection_input_id => Integer
                  article_name        => String}, ...]
		one hashref for each collection that service consumes
 Notes     : the fact that it returns a collection_input_id is bad since this
             is only useful to an SQL-based API...

=cut

sub query_collection_input{
	die "query_collection_input not implemented in adaptor\n";
}

=head2 insert_collection_input

 Title     :	insert_collection_input
 Usage     :	my $un = $API->insert_collection_input(%args)
 Function  :	Inserts a Collection input into the database
 Args      :   	article_name           => String,
		service_instance_lsid  => String,				
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_collection_input {
	die "insert_collection_input not implemented in adaptor\n";
}

=head2 delete_collection_input

 Title     :	delete_collection_input
 Usage     :	my $un = $API->delete_collection_input(%args)
 Function  :	Deletes Collection inputs according to the service instance
 Args      :    service_instance_lsid => String,
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 if successful
 		$errstr = String error message if there was an error	


=cut

sub delete_collection_input{
	die "delete_collection_input not implemented in adaptor\n";
}

#
# collection_output table fuctions
#

=head2 query_collection_output

 Title     :	query_collection_output
 Usage     :	my $un = $API->query_collection_output(%args)
 Function  :	Executes a query for Collection outputs according to the service instance
 Args      :    service_instance_lsid => String,				
 Returns   :    listref of hashrefs:
 		[{collection_output_id => Integer,
      		article_name	       => String,
      		service_instance_id    => Integer}, ...]
 Notes     : 	Only allows querying by lsid or type term, so service_instance_id is retrieved from lsid or term

=cut

sub query_collection_output{
	die "query_collection_output not implemented in adaptor\n";
}

=head2 insert_collection_output

 Title     :	insert_collection_output
 Usage     :	my $un = $API->insert_collection_output(%args)
 Function  :	Inserts a Collection output into the database
 Args      :   	article_name           => String,
		service_instance_lsid  => String,				
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_collection_output {
	die "insert_collection_output not implemented in adaptor\n";
	#my ($self, %args) = @_;	
	#my $dbh = $self->dbh;
	#if ($self->sourcetype eq "MOBY::Adaptor::moby::queryapi::mysql"){
	#	# this should be dropped down into the mysql.pm module??  probably...
	#	$self->dbh->do("insert into collection_output (service_instance_id, article_name) values (?,?)", undef, ($args{service_instance}, $args{article_name}));
	#	my $id=$self->dbh->{mysql_insertid};
	#	return $id;
	#}
}

=head2 delete_collection_output

 Title     :	delete_collection_output
 Usage     :	my $un = $API->delete_collection_output(%args)
 Function  :	Deletes Collection outputs according to the service instance
 Args      :    service_instance_lsid => String,
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 if successful
 		$errstr = String error message if there was an error	


=cut

sub delete_collection_output{
	die "delete_collection_output not implemented in adaptor\n";
}
	
#
# simple_output table functions
#

=head2 query_simple_input

 Title     :	query_simple_input
 Usage     :	my $un = $API->query_simple_input(%args)
 Function  :	Executes a query for Simple inputs according to the service instance or collection output
 Args      :    service_instance_lsid => String,
 				collection_input_id  => Integer
 Returns   :    listref of hashrefs:
 		[{simple_input_id 	 => Integer,
      		object_type_uri		 => String,
     		namespace_type_uris	 => String,
      		article_name		 => String,
      		service_instance_id	 => Integer,
      		collection_input_id      => Integer}, ...]
 Notes     : 	Only allows querying by lsid or type term, so service_instance_id is retrieved from lsid or term

=cut

sub query_simple_input{
	die "query_simple_input not implemented in adaptor\n";
}

=head2 insert_simple_input

 Title     :	insert_simple_input
 Usage     :	my $un = $API->insert_simple_input(%args)
 Function  :	Inserts a Simple input into the database
 Args      :    object_type_uri        => String,
		namespace_type_uris    => String,
		article_name           => String,
		service_instance_lsid  => String,
		collection_input_id    => Integer
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_simple_input {
	die "insert_simple_input not implemented in adaptor\n";
}

=head2 delete_simple_input

 Title     :	delete_simple_input
 Usage     :	my $un = $API->delete_simple_input(%args)
 Function  :	Deletes Simple inputs according to the service instance, or collection input
 Args      :    service_instance_lsid => String,
 	        collection_input_id   => Integer
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 if successful
 		$errstr = String error message if there was an error

=cut

sub delete_simple_input{
	die "delete_simple_input not implemented in adaptor\n";
}

#
# simple_output table functions
#

=head2 query_simple_output

 Title     :	query_simple_output
 Usage     :	my $un = $API->query_simple_output(%args)
 Function  :	Executes a query for Simple outputs according to the service instance or collection output
 Args      :    service_instance_lsid => String,
 		collection_output_id  => Integer
 Returns   :    listref of hashrefs:
 		[{simple_output_id 	 => Integer,
      		object_type_uri		 => String,
     		namespace_type_uris	 => String,
      		article_name		 => String,
      		service_instance_id	 => Integer,
      		collection_output_id     => Integer}, ...]
 Notes     : 	Only allows querying by lsid or type term, so service_instance_id is retrieved from lsid or term

=cut

sub query_simple_output{
	die "query_simple_output not implemented in adaptor\n";	
}

=head2 insert_simple_output

 Title     :	insert_simple_output
 Usage     :	my $un = $API->insert_simple_output(%args)
 Function  :	Inserts a Simple output into the database
 Args      :    object_type_uri        => String,
		namespace_type_uris    => String,
		article_name           => String,
		service_instance_lsid  => String,
		collection_output_id   => Integer
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_simple_output {
	die "insert_simple_output not implemented in adaptor\n";
}

=head2 delete_simple_output

 Title     :	delete_simple_output
 Usage     :	my $un = $API->delete_simple_output(%args)
 Function  :	Deletes Simple outputs according to the service instance, or collection output
 Args      :    service_instance_lsid => String,
 		collection_output_id  => Integer
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 if successful
 		$errstr = String error message if there was an error	

=cut

sub delete_simple_output{
	die "delete_simple_output not implemented in adaptor\n";
}

# secondary_input table functions

=head2 query_secondary_input

 Title     :	query_secondary_input
 Usage     :	my $un = $API->query_secondary_input(%args)
 Function  :	Executes a query for Secondary input articles in the database
 Args      :    service_instance_lsid => String
 Returns   :    listref of hashrefs:
 		[{secondary_input_id => Integer,
      		default_value	     => String,
      		maximum_value	     => Float,
     		minimum_value	     => Float,
     		enum_value	     => String,
      		datatype	     => String,
      		article_name	     => String,
      		service_instance_id  => Integer}, ...]
 Notes     : 	Only allows querying by lsid or type term, so service_instance_id is retrieved from lsid or term

=cut

sub query_secondary_input{
	die "query_secondary_input not implemented in adaptor\n";
}

=head2 insert_secondary_input

 Title     :	insert_secondary_input
 Usage     :	my $un = $API->insert_secondar_input(%args)
 Function  :	Inserts a Secondary input into the database
 Args      :    default_value 		  => String,
		maximum_value 		  => Float,
		minimum_value 		  => Float,
		enum_value 	       	  => String,
		datatype 	       	  => String,
		article_name 		  => String,
		service_instance_lsid     => String
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_secondary_input{
	die "insert_secondary_input not implemented in adaptor\n";
}

=head2 delete_secondary_input

 Title     :	delete_secondary_input
 Usage     :	my $un = $API->delete_secondary_input(%args)
 Function  :	Deletes a Secondary input from the database
 Args      :    service_instance_lsid => String 
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 if successful
 		$errstr = String error message if there was an error	

=cut

sub delete_secondary_input{
	die "delete_secondary_input not implemented in adaptor\n";
}

#
# object table functions
#

=head2 query_object

 Title     :	query_object
 Usage     :	my $un = $API->query_object(%args)
 Function  :	Executes a query for objects in the database
 Args      :    type => String - lsid or a term identifying a particular object
 Returns   :    listref of hashrefs:
 		[{object_id	  => Integer,
          	object_lsid	  => String,
          	object_type	  => String,
          	description	  => String,
          	authority	  => String,
         	contact_email     => String}, ...]
 Notes     : 	Only allows querying by lsid or type term

=cut

sub query_object{
	die "query_object not implemented in adaptor\n";
}

=head2 insert_object

 Title     :	insert_object
 Usage     :	my $un = $API->insert_object(%args)
 Function  :	Inserts an object into the database
 Args      :    object_type   => String, 
		object_lsid   => String, 
		description   => String, 
		authority     => String,
		contact_email => String
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_object{
	die "insert_object not implemented in adaptor\n";
}

=head2 delete_object

 Title     :	delete_object
 Usage     :	my $un = $API->delete_object(%args)
 Function  :	Deletes an object and any relationships it has from the database
 Args      :    type => String - lsid or term identifying a particular object
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 if successful
 		$errstr = String error message if there was an error	

=cut

sub delete_object{
	die "delete_object not implemented in adaptor\n";
}

#
# object_term2term table functions
#

=head2 query_object_term2term

 Title     :	query_object_term2term
 Usage     :	my $un = $API->query_object_term2term(%args)
 Function  :	Executes a query for object relationships in the database
 Args      :    type => String - lsid or a term identifying a particular object
 Returns   :    listref of hashrefs:
 		[{assertion_id	    => Integer,
          	relationship_type   => String,
          	object1_id	    => String,
		  object2_id	    => String,
          	object2_articlename => String}, ...]
 Notes     : 	Only allows querying by lsid or type term

=cut

sub query_object_term2term{
	die "query_object_term2term not implemented in adaptor\n";
}

=head2 insert_object_term2term

 Title     :	insert_object_term2term
 Usage     :	my $un = $API->insert_object_term2term(%args)
 Function  :	Inserts an object relationship into the database
 Args      :    relationship_type 	=> String, 
		object1_id 		=> String,
		object2_id 		=> String,
		object2_articlename     => String
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_object_term2term{
	die "insert_object_term2term not implemented in adaptor\n";
}

# private routine in mysql api, should not be documented
sub delete_object_term2term{
	die "delete_object_term2term not implemented in adaptor\n";
}

#
# service_instance table functions
#

=head2 query_service_instance

 Title     :	query_service_instance
 Usage     :	my $un = $API->query_service_instance(%args)
 Function  :	Executes a query for service instances in the database
 Args      :  	0 or more:
	        service_instance_id 	 	 => Integer 
		category			 => String 
		servicename			 => String 
		service_type_uri		 => String 
		'authority.authority_uri' 	 => String - IMPORTANT notice use of quotes to avoid conflict with perl special operator '.' 
		url				 => String 
		'service_instance.contact_email' => String - Again IMPORTANT use of quotes
		authoritative			 => Integer 
		description			 => String 
		signatureURL			 => String
		lsid				 => String 
 Returns   :    listref of hashrefs:
 		[{service_instance_id 	       => Integer, 
		category		       => String, 
		servicename		       => String, 
		service_type_uri	       => String, 
		authority.authority_uri	       => String, 
		url			       => String, 
		service_instance.contact_email => String, 
		authoritative		       => Integer, 
		description		       => String, 
		signatureURL		       => String,
		lsid 			       => String}, ...]
 Notes     : 	Allows querying by multiple conditions joined by 'and'

=cut

sub query_service_instance {
	die "query_service_instance not implemented in adaptor\n";
}

=head2 query_service_existence

 Title     :	query_service_existence
 Usage     :	my $un = $API->query_service_existence(%args)
 Function  :	Executes a query to check if the service exists in the database
 Args      :    servicename   => String
 		authority_uri => String 				
 Returns   :    1 if service exists
 		0 if no such service instance
 Notes     : 	Only allows querying by URI of the authority and service name

=cut

sub query_service_existence{
	die "query_service_existence not implemented in adaptor\n";	
}

# This might be redundant of query_service_instance(), since same function can be
# replicated by several of its calls
sub match_service_type_uri{
	die "match_service_type_uri not implemented in adaptor\n";
}

=head2 insert_service_instance

 Title     :	insert_service_instance
 Usage     :	my $un = $API->insert_service_instance(%args)
 Function  :	Inserts a service instance into the database
 Args      :    category         => String,
		servicename      => String,
		service_type_uri => String,
		authority_uri    => String,
		url              => String,
		contact_email    => String, 
		authoritative    => Integer,
		description      => String,
		signatureURL     => String,
		lsid             => String
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_service_instance {
	die "insert_service_instance not implemented in adaptor\n";
}

=head2 delete_service_instance

 Title     :	delete_service_instance
 Usage     :	my $un = $API->delete_service_instance(%args)
 Function  :	Deletes a service instance from the database
 Args      :    service_instance_lsid => String 
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 if successful
 		$errstr = String error message if there was an error	


=cut


sub delete_service_intance{
	die "delete_service_intance not implemented in adaptor\n";
}
	
#
# authority table functions
#

=head2 query_authority

 Title     :	query_authority
 Usage     :	my $un = $API->query_authority(%args)
 Function  :	Executes a query for authorities in the database
 Args      :    authority_uri => String
 Returns   :    listref of hashrefs:
 		[{authority_common_name => String,
         	authority_uri			=> String,
          	contact_email			=> String}, ...]
 Notes     : 	Only allows querying by URI of the authority

=cut

sub query_authority{
	die "query_authority not implemented in adaptor\n";
}

=head2 get_all_authorities

 Title     :	get_all_authorities
 Usage     :	my $un = $API->get_all_authorities()
 Function  :	Gets all unique authority URIs from the database
 Args      :    no arguments
 Returns   :    listref of hashrefs:
 		[{authority_uri => String}]


=cut


sub get_all_authorities{
	die "get_all_authorities not implemented in adaptor\n";
}

=head2 insert_authority

 Title     :	insert_authority
 Usage     :	my $un = $API->insert_authority(%args)
 Function  :	Inserts an authority into the database
 Args      :    authority_common_name => String,
		authority_uri         => String,
		contact_email	      => String
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_authority{
	die "insert_authority not implemented in adaptor\n";
}

# Not implemented in mysql... should we allow deleting the authority?
sub delete_authority{
	die "delete_authority not implemented in adaptor\n";
}

#
# service table fuctions
#

=head2 query_service

 Title     :	query_service
 Usage     :	my $un = $API->query_service(%args)
 Function  :	Executes a query for service class
 Args      :    type => String - either service_type or service_lsid
 Returns   :    listref of hashrefs:
 		[{service_id  => Integer, 
          	service_lsid  => String,
          	service_type  => String,
          	description   => String,
          	authority     => String,
          	contact_email => String}, ...]
 Notes     : 	the fact that it returns an service_id is bad since this
             	is only useful to an SQL-based API...

=cut

sub query_service{
	die "query_service not implemented in adaptor\n";
}

=head2 insert_service

 Title     :	insert_service
 Usage     :	my $un = $API->insert_service(%args)
 Function  :	Inserts a service class into the database
 Args      :    service_type  => String,
		service_lsid  => String,
		description   => String,
		authority     => String,
		contact_email => String
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_service{
	die "insert_service not implemented in adaptor\n";
}

=head2 delete_service

 Title     :	delete_service
 Usage     :	my $un = $API->delete_service(%args)
 Function  :	Deletes a service from the database
 Args      :    service_lsid => String 
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 otherwise
 		$errstr = String error message if there was an error	


=cut

sub delete_service{
	die "delete_service not implemented in adaptor\n";
}

#
# service_term2term table functions
#

=head2 query_service_term2term

 Title     :	query_service_term2term
 Usage     :	my $un = $API->query_service_term2term(%args)
 Function  :	Executes a query for service relationships
 Args      :    type => String - either service_type or service_lsid
 Returns   :    listref of hashrefs:
 		[{assertion_id	  => Integer,
          	relationship_type => String,
          	service1_id	  => String,
          	service2_id	  => String}, ...]
 Notes     : 	the fact that it returns an service ids is bad since this
             	is only useful to an SQL-based API...should return lsids

=cut

sub query_service_term2term{
	die "query_service_term2term not implemented in adaptor\n";
}

=head2 insert_service_term2term

 Title     :	insert_service_term2term
 Usage     :	my $un = $API->insert_service_term2term(%args)
 Function  :	Inserts a service relationship
 Args      :    relationship_type => String, 
		service1_type     => String,
		service2_type     => String
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_service_term2term{
	die "insert_service_term2term not implemented in adaptor\n";
}

# private subroutine in mysql api

sub delete_service_term2term{
	die "delete_service_term2term not implemented in adaptor\n";
}

#
# relationship table functions
#

=head2 query_relationship

 Title     :	query_relationship
 Usage     :	my $un = $API->query_relationship(%args)
 Function  :	Executes a query for a relationship in an ontology
 Args      :    type     => String,
 		ontology => String
 Returns   :    listref of hashrefs:
                [{relationship_id => Integer,
          	relationship_lsid => String,
          	relationship_type => String,
          	container 	  => Integer,
          	description	  => String,
          	authority	  => String,
          	contact_email	  => String,
          	ontology	  => String}, ...]
		one hashref for each relationship
 Notes     : the fact that it returns a relationship_id is bad since this
             is only useful to an SQL-based API...

=cut

sub query_relationship{
	die "query_relationship not implemented in adaptor\n";
}

# probably no need for this in the future and not implemented in mysql api
sub insert_relationship{
	die "insert_relationship not implemented in adaptor\n";
}

# is not implemented in mysql api either... should this be removed?
sub delete_relationship{
	die "delete_relationship not implemented in adaptor\n";
}

#
# namespace table functions
#

=head2 query_namespace

 Title     :	query_namespace
 Usage     :	my $un = $API->query_namespace(%args)
 Function  :	Executes a query for namespace instances in the database
 Args      :    type => String - either lsid or term for a particular namespace
 Returns   :    listref of hashrefs:
 		[{namespace_id => Integer,
          	namespace_lsid => String,
          	namespace_type => String,
          	description    => String,
          	authority      => String,
          	contact_email  => String}, ...]

=cut

sub query_namespace{
	die "query_namespace not implemented in adaptor\n";
}

=head2 insert_namespace

 Title     :	insert_namespace
 Usage     :	my $un = $API->insert_namespace(%args)
 Function  :	Deletes a namespace instance from the database
 Args      :    namespace_type => String,
 		namespace_lsid => String,
 		description    => String, 
 		authority      => String,
 		contact_email  => String
 Returns   :    Integer insertid
 Notes     : 	the fact that it returns an insertid is bad since this
             	is only useful to an SQL-based API...

=cut

sub insert_namespace{
	die "insert_namespace not implemented in adaptor\n";
}

=head2 delete_namespace

 Title     :	delete_namespace
 Usage     :	my $un = $API->delete_namespace(%args)
 Function  :	Deletes a namespace instance from the database
 Args      :    type => String - lsid or namespace term identifying a particular namespace
 Returns   :    ($err, $errstr)
 		$err = 1 if there was an delete error, 0 otherwise
 		$errstr = String error message if there was an error	

=cut

sub delete_namespace{
	die "delete_namespace not implemented in adaptor\n";
}

=head2 query_namespace_term2term

 Title     :	query_namespace_term2term
 Usage     :	my $un = $API->query_namespace_term2term(%args)
 Function  :	Execute a query for namespaces_term2term
 Args      :    type => String - namespace_type you are checking for
 Returns   :    listref of hashrefs:
 		[{assertion_id 	  => Integer,
          	relationship_type => String,
          	namespace1_id 	  => String,
          	namespace2_id	  => String}, ...]
 Notes	   :    namespace1_id and namespace2_id will be lsids	 				

=cut

# namespace_term2term table functions
sub query_namespace_term2term{
	die "query_namespace_term2term not implemented in adaptor\n";
}

# does not exist in mysql api, should this be removed?
sub insert_namespace_term2term{
	die "insert_namespace_term2term not implemented in adaptor\n";
}

# changed to a private subroutine in mysql
# I guess this subroutine should be removed from here?
sub _delete_namespace_term2term{
	die "delete_namespace_term2term not implemented in adaptor\n";
}

=head2 check_object_usage

 Title     :	check_object_usage
 Usage     :	my $un = $API->check_object_usage(%args)
 Function  :	Execute a custom query for objects that are used by some service
 Args      :   	type => String - either namespace_lsid or namespace_term 
 Returns   :    a list:
 		($err, $errstr)
 		$err = 1 if namespace is used by a service, 0 otherwise
 		$errstr = contains the error message 

=cut

# custom query subroutine for Moby::Central.pm->deregisterObjectClass()
sub check_object_usage{
	die "check_object_usage not implemented in adaptor\n";
}

=head2 check_namespace_usage

 Title     :	check_namespace_usage
 Usage     :	my $un = $API->check_namespace_usage(%args)
 Function  :	Execute a custom query for namespaces that are used by some service
 Args      :   	type => String - either namespace_lsid or namespace_term 
 Returns   :    a list:
 		($err, $errstr)
 		$err = 1 if namespace is used by a service, 0 otherwise
 		$errstr = contains the error message 

=cut

# custom query routine for Moby::Central.pm -> deregisterNamespace()
sub check_namespace_usage{
	die "check_namespace_usage not implemented in adaptor\n";
}

=head2 check_keywords

 Title     :	check_keywords
 Usage     :	my $un = $API->check_keywords(%args)
 Function  :	Execute a custom query for services with keywords in its description
 Args      :    keywords => listref (of keywords)
 Returns   :    listref of hashrefs:
                [{service_instance_id => Integer,
                category 	      => String, 
                servicename 	      => String, 
                service_type_uri      => String, 
                authority_id 	      => Integer, 
                url 		      => String, 
                contact_email 	      => String, 
                authoritative 	      => String, 
                description 	      => String, 
                signatureURL 	      => String, 
                lsid   		      => String}, ...]
                Each hash represents a service
 Notes     : 	the fact that it returns a service_instance_id is bad since this
             	is only useful to an SQL-based API...
		Keywords are assumed to be joined by "OR" for the query 

=cut

# custom query routine for Moby::Central.pm -> findService()
sub check_keywords{
	die "check_keywords not implemented in adaptor\n";
}

=head2 find_by_simple

 Title     :	find_by_simple
 Usage     :	my $un = $API->find_by_simple(%args)
 Function  :	Execute a custom query for service ids in simple_input/output
 Args      :    inout           => String - to specify if input or output
		ancestor_string => String - values that occur in object_type_uri
		namespaceURIs   => array-ref - reference to an array of namespace URIs
 Returns   :    listref of hashrefs:
                [{service_instance_id => Integer,
                namespace_type_uris   => String}, ...]
 Notes     : 	the fact that it returns a service_instance_id is bad since this
             	is only useful to an SQL-based API...

=cut

# custom query subroutine for Moby::Central.pm->_searchForSimple()
sub find_by_simple{
	die "find_by_simple not implemented in adaptor\n";
}

=head2 find_by_collection

 Title     :	find_by_collection
 Usage     :	my $un = $API->find_by_collection(%args)
 Function  :	Execute a custom query for service ids from collections
 Args      :    inout         => String - to specify if input or output
		objectURI     => String - value that binds to object_type_uri
		namespaceURIs => array-ref - reference to an array of namespace URIs
 Returns   :    listref of hashrefs:
                [{service_instance_id => Integer,
                namespace_type_uris   => String}, ...]
 Notes     : 	the fact that it returns a service_instance_id is bad since this
             	is only useful to an SQL-based API...

=cut

# custom query subroutine for Moby::Central.pm->_searchForCollection()
sub find_by_collection{
	die "find_by_collection not implemented in adaptor\n";
}

=head2 get_service_names

 Title     :	get_service_names
 Usage     :	my $un = $API->get_service_names(%args)
 Function  :	Execute a query for all service names
 Args      :    no inputs needed
 Returns   :    listref of hashrefs:
                [{authority_uri => String,
                servicename     => String}, ...]
		one hashref for each service

=cut

# custom query subroutine for Moby::Central.pm->RetrieveServiceNames
sub get_service_names{	
	die "get_service_names not implemented in adaptor\n";
}

=head2 get_parent_terms

 Title     :	get_parent_terms
 Usage     :	my $un = $API->get_parent_terms(%args)
 Function  :	From a given term, traverse the ontology and get all parent terms
 Args      :    relationship_type_id => Integer - a bind value for relationship_type_id on an underlying SQL-based data source
 		term                 => String - bindvalue for OntologyEntry.term
 Returns   :    listref of hashrefs:
                [{term => String}, ...]
		one hashref for each parent

=cut

# custom query for Moby::Central.pm->_flatten
sub get_parent_terms{
	die "get_parent_terms not implemented in adaptor\n";
}

=head2 get_object_relationships

 Title     :	get_object_relationships
 Usage     :	my $un = $API->get_object_relationships(%args)
 Function  :	Execute a query for objects that have relationships with other objects
 Args      :    type => String - either an object name or LSID
 Returns   :    listref of hashrefs:
                [{relationship_type => String,
                object_type 	    => String,
                object_lsid         => String,
                description 	    => String,
                authority	    => String,
                contact_email	    => String,
                object2_articlename => String}, ...]
		one hashref for each relationship between two objects
 Notes     : 	relationship_type from object_term2term, object_lsid from object, and object2_articlename from object_term2term

=cut

# custom query subroutine for selecting from object_term2term and object tables
# used in Moby::OntologyServer.pm->retrieveObject()
sub get_object_relationships{
	die "get_object_relationships not implemented in adaptor\n";
}

=head2 get_relationship

 Title     :	get_relationship
 Usage     :	my $un = $API->get_relationship(%args)
 Function  :	Execute a query for a relationship between two ontologies
 Args      :    direction    => String - direction in the ontology (eg. 'root')
 		ontology     => String - name of the table ontology
 		term         => String - a bind value for lsid
 		relationship => String - a bind value for relationship_type
 Returns   :	reference to array containing array-refs representing the result set:
 		[[String lsid, String relationship_type], ...]
 		each array-ref represents one row
 Notes	   :	Only returns distinct lsids from $ontology and relationship_type from $ontology_term2term

=cut

# relationship query for any table used in Moby::OntologyServer->_doRelationshipQuery()
# note: returns a reference to an array containing ARRAY references
sub get_relationship{
	die "get_relationship not implemented in adaptor\n";
}

=head2 get_all_relationships

 Title     :	get_all_relationships
 Usage     :	my $un = $API->get_all_relationships(%args)
 Function  :	Execute a query for all relationships represented in $ontology_term2term
 Args      :    direction    => String - direction in the ontology (either 'root' or 'leaves')
 		ontology     => String - name of the table ontology
 Returns   :	reference to hash with the following structure:
                $resultHash->{String relationship_type}->{Integer key_entity_id} = <VALUE>
                The structure of <VALUE> depends on relationship_type and direction:
                HAS/HASA    :
                   <VALUE> = @([Integer value_entity_id, String articleName, Integer assertion_id])
                ISA, leaves :
                   <VALUE> = @(Integer value_entity_id)
                ISA, root   :
                   <VALUE> = Integer value_entity_id
 Notes     :	The hash is built 'direction-aware', that is for
                - root  : key_entity_id = ${ontology}1_id, value_entity_id = ${ontology}2_id
                - leaves: key_entity_id = ${ontology}2_id, value_entity_id = ${ontology}1_id
                The structure of the result hash is a bit complex because it is specifically
                designed for usage by MOBY::OntolgyServer::Relationships
                The result hash contains the entire table ${ontology}_term2term in order to
                reduce DB interaction in the ontology exploration

=cut

# Get all relationships in the queried database in one go.  The
# complete table ${ontology}_term2term is transferred into a hash
# whose reference is finally returned.  Important: note that the hash
# is built 'direction aware', that is for objects 'object1_id' is used
# as key when direction is 'root' and 'object2_id' as value. Vice
# versa for the 'leaves' direction.  Likewise for services.
# Returns a hash reference.
sub get_all_relationships{
	die "get_all_relationships not implemented in adaptor\n";
}

=head2 get_details_for_id_list

 Title     :	get_deails_for_id_list
 Usage     :	my $un = $API->get_all_relationships($ontology, $field_list, $id_list)
 Function  :	Retrieve details specified in @$field_list from $ontology for ids in @$id_list
 Args      :    $ontology   => String - name of the table ontology
                $field_list => Reference to array of Strings representing table fields in $ontology
                $id_list    => Reference to array of Integers representing ${ontology}_ids
 Returns   :	reference to hash with the following structure:
                $resultHash->{Integer ${ontology}_id}->{String field_name} = field_value
 Notes     :    This function is generic with respect to which details (fields) are retrieved, but
                is restricted to those tables whose name is identical to the ontology name (i.e.
                currently 'object', 'service', 'namespace' and 'relationship')
                Makes use of the 'select ... from ... where ... in (<LIST>)' statement syntax
                in order to reduce the number of DB interactions
                Used in MOBY::OntologyServer::Relationships, but maybe useful for other purposes...

=cut

# retrieve details for a number of entities from table $ontology
# represented by a list of ${ontology}_id's;
# used in MOBY::OntologyServer::Relationships
sub get_details_for_id_list {
        die "get_details_for_id_list not implemented in adaptor\n";
}


# Not quite sure what this does...
sub _checkURI {
	die "_checkURI not implemented in adaptor\n";
}
  
sub _dump {
	my ($self) = @_;
    foreach my $attrname ( $self->_standard_keys ) {
		print STDERR "$attrname = ",($self->{$attrname}),"\n";
	}
}

sub DESTROY {}
#
#sub AUTOLOAD {
#    no strict "refs";
#    my ($self, $newval) = @_;
#
#    $AUTOLOAD =~ /.*::(\w+)/;
#
#    my $attr=$1;
#    if ($self->_accessible($attr,'write')) {
#
#	*{$AUTOLOAD} = sub {
#	    if (defined $_[1]) { $_[0]->{$attr} = $_[1] }
#	    return $_[0]->{$attr};
#	};    ### end of created subroutine
#
####  this is called first time only
#	if (defined $newval) {
#	    $self->{$attr} = $newval
#	}
#	return $self->{$attr};
#
#    } elsif ($self->_accessible($attr,'read')) {
#
#	*{$AUTOLOAD} = sub {
#	    return $_[0]->{$attr} }; ### end of created subroutine
#	return $self->{$attr}  }
#
#
#    # Must have been a mistake then...
#    croak "No such method: $AUTOLOAD";
#}
#

1;
