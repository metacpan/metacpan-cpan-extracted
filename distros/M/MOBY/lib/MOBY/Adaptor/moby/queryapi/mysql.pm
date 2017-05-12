package MOBY::Adaptor::moby::queryapi::mysql;

use strict;
use vars qw($AUTOLOAD @ISA);
use Carp;
use MOBY::Adaptor::moby::queryapi;
use DBI;
use DBD::mysql;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

@ISA = qw{MOBY::Adaptor::moby::queryapi}; # implements the interface

{
	#Encapsulated class data
	
	#___________________________________________________________
	#ATTRIBUTES
    my %_attr_data = #     				DEFAULT    	ACCESSIBILITY
                  (
                   driver       =>  ["DBI:mysql",  'read/write'],
                   dbh		     =>  [undef,         'read/write'],
                   
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
    sub _standard_keys {
	keys %_attr_data;
    }

	sub driver {
		my ($self, $arg) = @_;
		$self->{driver} = $arg if defined $arg;
		return $self->{driver};
	}
	sub dbh {
		my ($self, $arg) = @_;
		$self->{dbh} = $arg if defined $arg;
		return $self->{dbh};
	}

}

sub _getDBHandle {
    my ($ontology) = @_;
    my $CONF = MOBY::Config->new;
    my $adap = $CONF->getDataAdaptor(source => $ontology);
    return $adap->dbh;
}

sub new {
	my ($caller, %args) = @_;
	my $self = $caller->SUPER::new(%args);

	my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;

    foreach my $attrname ( $self->_standard_keys ) {
    	if (exists $args{$attrname} && defined $args{$attrname}) {
		$self->{$attrname} = $args{$attrname} }
    elsif ($caller_is_obj) {
		$self->{$attrname} = $caller->{$attrname} }
    else {
		$self->{$attrname} = $self->_default_for($attrname) }
    }

    return unless $self->driver;
    my $driver = $self->driver;  # inherited from the adaptorI (queryapi)
    my $username = $self->username;
    my $password = $self->password;
    my $port = $self->port;
    my $url = $self->url;
    my $dbname = $self->dbname;
    
    my ($dsn) = "$driver:$dbname:$url:$port";
    my $dbh = DBI->connect($dsn, $username, $password, {RaiseError => 1}) or die "can't connect to database";


    ##############################################################
    unless ($dbh) {
	    print STDERR "Couldn't connect to the datasource \n",($self->_dump()),"\n\n";
	    return undef;
    }
    
    $self->dbh($dbh);
    #############################################################

    return undef unless $self->dbh;
    return $self;
    
}

sub _add_condition{
	my ($statement, @params) = @_;
	my @bindvalues = ();
 	my $condition = "where ";
 
 	foreach my $param (@params ) 
 	{
		if (($param eq 'and') || ($param eq 'or'))
 		{
		 $condition .= $param . " ";
		}
 		else
 		{
		my %pair = %$param;

		for my $key (keys %pair)
			{			
	 			if (defined $pair{$key}){
				    #added a check for servicename to support case sensitivity
				    if ($key eq "servicename") {
					$condition .= $key . " LIKE binary ? ";
					push(@bindvalues, $pair{$key});
				    } elsif ($pair{$key} eq "IS NOT NULL"){
					$condition .= $key . " IS NOT NULL ";
				    } else {
				        $condition .= $key . " = ? ";
					push(@bindvalues, $pair{$key});
				    }
 				} else{
				    $condition .= $key . " IS NULL "
 				}
			}
		}
 	}
 	$statement .= $condition;
 	return ($statement, @bindvalues);
 }

# preforms query but returns a reference to an array containing hash references	
sub do_query{
	my ($dbh, $statement, @bindvalues) = @_;
	my $sth = $dbh -> prepare($statement);	
 	if (@bindvalues < 1)
 	{
 		$sth->execute;
 	}
 	else
 	{
 		$sth->execute(@bindvalues);
 	}
 	# returns an array of hash references
    my $arrayHashRef = $sth->fetchall_arrayref({});        
	return $arrayHashRef;
}

sub get_value{
	my ($key, @params) = @_;
	
	foreach my $param (@params )
	{
	    my %pair = %$param;
	    for my $tmp (keys %pair)
	    {
			if ($tmp eq $key){
				return $pair{$key};
			}
	    }
	}
}

sub _getSIIDFromLSID {
    my ($self, $lsid) = @_;
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare("select service_instance_id from service_instance where lsid = ?");
    $sth->execute($lsid);
    my ($siid)  = $sth->fetchrow_array();
    return $siid;
}

# this should NOT retun a collection ID... needs more work...
# args passed in:  service_lsid
sub query_collection_input{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	my $serv_lsid = $args{'service_instance_lsid'};
	
	my $statement = "select
          collection_input_id,
          article_name 
          from collection_input as c, service_instance as si where si.service_instance_id = c.service_instance_id and si.lsid = ?";   
 	my $result = do_query($dbh, $statement, ($serv_lsid));
 	return $result;
}

# args passed in:  service_instance_lsid, article_name
sub insert_collection_input {
    my ($self, %args) = @_;
    my $article = $args{article_name};
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    
    $self->dbh->do("insert into collection_input (service_instance_id, article_name) values (?,?)", 
    undef, $siid, $article);
    my $id=$self->dbh->{mysql_insertid};
    return $id;
}

# pass in service_instance_lsid
sub delete_collection_input{
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    
    my $statement = "delete from collection_input where service_instance_id = ?";
    $self->dbh->do( $statement, undef, $siid);
    
    if ($self->dbh->err){
	    return (1, $self->dbh->errstr);
    }
    else{
	    return 0;
    }	
}

# pass service_instance_lsid
sub query_collection_output{
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $dbh = $self->dbh;
    
    my $statement = "select
       collection_output_id,
       article_name,
       service_instance_id
       from collection_output where service_instance_id = ? ";       
    my $result = do_query($dbh, $statement, ($siid));
    return $result;
}

# pass service_instance_lsid, article_name
sub insert_collection_output {
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $dbh = $self->dbh;
    $self->dbh->do("insert into collection_output (service_instance_id, article_name) values (?,?)", 
    undef, $siid,$args{'article_name'});
    my $id=$self->dbh->{mysql_insertid};
    return $id;
}

# pass argument service_instance_lsid
sub delete_collection_output{
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $dbh = $self->dbh;
    my $statement = "delete from collection_output where service_instance_id = ?";
    my @bindvalues = ();
    $dbh->do( $statement, undef, ($siid));

    if ($dbh->err){
	    return (1, $dbh->errstr);
    }
    else{
	    return 0;
    }	
}

# pass service_instance_lsid 
sub query_simple_input{
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $collid = $args{collection_input_id};
    my $id_to_use = $siid?$siid:$collid;
    
    my $dbh = $self->dbh;
    
    my $statement = "select
      simple_input_id,
      object_type_uri,
      namespace_type_uris,
      article_name,
      service_instance_id,
      collection_input_id
      from simple_input where ";
      
	my $condition;
      $siid && ($condition = " service_instance_id = ? and collection_input_id IS NULL");
      $collid && ($condition = " collection_input_id = ?");
      $statement .= $condition;
      
    my $result = do_query($dbh, $statement, ($id_to_use));
    return $result;
}
	
# pass service_instance_lsid, object_type_uri, namespace_type_uris, article_name, collection_input_id
sub insert_simple_input {
    my ($self, %args) = @_;
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $dbh = $self->dbh;	    
    $dbh->do("insert into simple_input
			     (object_type_uri,
			      namespace_type_uris,
			      article_name,
			      service_instance_id,
			      collection_input_id)
			     values (?,?,?,?,?)",
	    undef,
	    $args{'object_type_uri'},
	    $args{'namespace_type_uris'},
	    $args{'article_name'},
	    $siid,
	    $args{'collection_input_id'});
    my $id=$dbh->{mysql_insertid};
    return $id;
}

# pass service_instance_lsid
sub delete_simple_input{
    my ($self, %args) = @_;
    my $dbh = $self->dbh;
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my ($collid) = $args{collection_input_id};
    my $statement1; my $statement2;
    $siid && ($statement1 = "delete from simple_input where service_instance_id = ?");
    $collid && ($statement2 = "delete from simple_input where collection_input_id = ?");
    
    $siid && ($dbh->do( $statement1, undef,($siid)));
    $collid && ($dbh->do($statement2, undef,($collid)));
    if ($dbh->err){
	    return (1, $dbh->errstr);
    }
    else{
	    return 0;
    }			  
}

sub delete_inputs {  # this should replace all other delete_*_input
    my ($self, %args) = @_;
    my $dbh = $self->dbh;
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $result_ids = $self->query_collection_input(service_instance_lsid => $self->lsid);

    my $statement = "delete from simple_input where service_instance_id = ?";

    $dbh->do( $statement, undef,($siid));
    if ($dbh->err){
	    return (1, $dbh->errstr);
    }
    else{
	    return 0;
    }			  
    
}

sub delete_output {  # this should replace all other delete_*_output
    
}

# UGH this has to know too much bout the underlying database structure e.g. that one is null and other is full
# this problem is in MOBY::Central line 3321 3346 and 3374
#****** FIX
# send service_instance_lsid, collection_input_id
sub query_simple_output{
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $collid = $args{collection_output_id};
    my $dbh = $self->dbh;
    my $id_to_use = $siid?$siid:$collid;
    
    my $statement = "select
      simple_output_id,
      object_type_uri,
      namespace_type_uris,
      article_name,
      service_instance_id,
      collection_output_id
      from simple_output where ";
      my $condition;
      $siid && ($condition = " service_instance_id = ? and collection_output_id IS NULL");
      $collid && ($condition = " collection_output_id = ?");
    $statement .= $condition;


    my $result = do_query($dbh, $statement, ($id_to_use));
    return $result;
}

# pass args service_instance_id and collection_output_id
sub insert_simple_output {
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $dbh = $self->dbh;

    $dbh->do("insert into simple_output
			     (object_type_uri,
			      namespace_type_uris,
			      article_name,
			      service_instance_id,
			      collection_output_id)
			     values (?,?,?,?,?)",
	    undef,(
	    $args{'object_type_uri'},
	    $args{'namespace_type_uris'},
	    $args{'article_name'},
	    $siid,
	    $args{'collection_output_id'}));
    my $id=$dbh->{mysql_insertid};
    return $id;

}

# pass service_instance_id or collection_output_id
sub delete_simple_output{
    my ($self, %args) = @_;
    my $dbh = $self->dbh;
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my ($collid) = $args{collection_output_id};
    my $statement1; my $statement2;
    $siid && ($statement1 = "delete from simple_output where service_instance_id = ?");
    $collid && ($statement2 = "delete from simple_output where collection_output_id = ?");
    
    $siid && ($dbh->do( $statement1, undef,($siid)));
    $collid && ($dbh->do($statement2, undef,($collid)));
    if ($dbh->err){
	    return (1, $dbh->errstr);
    }
    else{
	    return 0;
    }			  
}	

# pass service_instance_lsid
sub query_secondary_input{
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $dbh = $self->dbh;
    
    my $statement = "select
      secondary_input_id,
      default_value,
      maximum_value,
      minimum_value,
      enum_value,
      datatype,
      article_name,
      description,
      service_instance_id
      from secondary_input where service_instance_id = ?";    
    my $result = do_query($dbh, $statement, ($siid));
    return $result;	
}

# pass default_value, maximum_value minimum_value enum_value datatype article_name service_instance_lsid
sub insert_secondary_input{
    my ($self, %args) = @_;	
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $dbh = $self->dbh;		
    $dbh->do(q{insert into secondary_input (default_value,maximum_value,minimum_value,enum_value,datatype,article_name,description,service_instance_id) values (?,?,?,?,?,?,?,?)},
	    undef,
	    (
	       $args{'default_value'}, $args{'maximum_value'},
	       $args{'minimum_value'}, $args{'enum_value'},
	       $args{'datatype'}, $args{'article_name'}, $args{'description'},$siid)
    );
    return $dbh->{mysql_insertid};
}

# pass service_instance_lsid
sub delete_secondary_input{
    my ($self, %args) = @_;
    my ($siid) = $self->_getSIIDFromLSID($args{service_instance_lsid});
    my $dbh = $self->dbh;
    my $statement = "delete from secondary_input where service_instance_id=?";

    $dbh->do( $statement, undef, ($siid));    
    if ($dbh->err){
	    return (1, $dbh->errstr);
    }
    else{
	    return 0;
    }	
}


# receives argument "type", that may be either an LSID or a type term
sub query_object {
	my ($self, %args) = @_;
	my $type = $args{type};
	my $condition = "";
	if ($type =~ /^urn\:lsid/){
	    $condition = "where object_lsid = ?";
	} elsif ($type) {
	    $condition = "where object_type = ?";
	}
	my $statement = "select
          object_id,
          object_lsid,
          object_type,
          description,
          authority,
          contact_email
          from object $condition";

	my $dbh = _getDBHandle("mobyobject");
	my $result;
	if ($type){
	    $result = do_query($dbh, $statement, ($type));
	} else {
	    $result = do_query($dbh, $statement);
	}	    
 	return $result;		
}

# inserts a new tuple into object table
# pass object_type object_lsid description authority contact_email
sub insert_object{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;		
	$dbh->do("insert into object 
				 (object_type, 
				 object_lsid, 
				 description, 
				 authority,
				 contact_email)
				 values (?,?,?,?,?)",
		undef,
		$args{'object_type'},
		$args{'object_lsid'},
		$args{'description'},
		$args{'authority'},
		$args{'contact_email'});
	my $id=$dbh->{mysql_insertid};
	return $id;	
}

# pass 'type' which is either an LSID or a term
sub delete_object{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	my $term = $args{type};
	return 0 unless $term;
	my $result = $self->query_object(type => $term);
	my $row = shift(@$result);
	my $id = $row->{object_id};
	my $lsid = $row->{object_lsid};
	my $statement = "delete from object where object_lsid = ?";
	$dbh->do( $statement,undef, ($lsid) );
	
	$self->_delete_object_term2term(id => $id);
	if ($dbh->err){
		return (1, $dbh->errstr);
	}
	else{
		return 0;
	}
}

# pass "type" here, should be an LSID, preferably...
sub query_object_term2term{
	my ($self, %args) = @_;
	my $type = $args{type};
	my $result = $self->query_object(type => $type);
	my $row = shift(@$result);
	my $id = $row->{object_id};
	return [{}] unless $id;
	my $dbh = $self->dbh;
	
	my $statement = "select
          assertion_id,
          relationship_type,
          object1_id,
          object2_id,
          object2_articlename
          from object_term2term where object2_id = ?";
 	my $result2 = do_query($dbh, $statement, ($id));
 	return $result2;			
}

# pass object1_type, object2_type, object2_articlename, relationship_type
sub insert_object_term2term{
	my ($self, %args) = @_;	
	my $type1 = $args{object1_type};
	my $result = $self->query_object(type => $type1);
	my $row = shift(@$result);
	my $id1 = $row->{object_id};
	my $type2 = $args{object2_type};
	$result = $self->query_object(type => $type2);
	$row = shift(@$result);
	my $id2 = $row->{object_id};
	my $relationship_type = $args{relationship_type};
	my $object2_articlename = $args{object2_articlename};

	my $dbh = $self->dbh;
	$dbh->do(
	    q{insert into object_term2term (relationship_type, object1_id, object2_id, object2_articlename) values (?,?,?,?)},
		undef,
		$relationship_type,
		$id1,
		$id2,
		$object2_articlename
	);
	
	return $dbh->{mysql_insertid};
}

# pass object 'type' as term or lsid
# this should be a private routine, not a public one.
# SHOULD NOT BE DOCUMENTED IN THE API
sub _delete_object_term2term{
	my ($self, %args) = @_;
	my $o1id = $args{id};
	return 0 unless defined($o1id);
	my $dbh = $self->dbh;	
	my $statement = "delete from object_term2term where object1_id=?";
	$dbh->do( $statement,undef, ($o1id));
	
	if ($dbh->err){
		return (1, $dbh->errstr);
	}
	else{
		return 0;
	}
}

# pass servicename and authority_uri
# TODO added LIKE binary here
sub query_service_existence {
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;

	my $servicename = $args{'servicename'};
	my $authURI = $args{'authority_uri'};
	my $result = $self->_query_authority(authority_uri => $authURI);
	return 0 unless @$result[0];
	my $id = @$result[0]->{authority_id};
	return 0 unless $id;
	my $statement = "select
          service_instance_id,
          category,
          servicename,
          service_type_uri,
          authority_id,
          url,
          contact_email,
          authoritative,
          description,
		  signatureURL,
		  lsid 
          from service_instance where servicename LIKE binary ? and authority_id = ?";
 	my $final = do_query($dbh, $statement, ($servicename, $id));
 	if (@$final[0]){return 1} else {return 0}
	
}
# selects all the columns from service_instance table
# PAY ATTENTION to what this returns.  Not auth_id but auth_uri!!
# IMPORTANT: must use quotes for the keys of the hash (eg. 'authority.authority_uri' => $value )
sub query_service_instance {
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
    	
	my @args;
	while (my ($k, $v) = each %args){
	    push @args, ({$k => $v}, "and"); # format for the_add_condition subroutine
	    								 # but too bad won't be scalable for "or"
	}
    	
	if (keys(%args)){ pop @args;}  # remove final "and"
	
	my $statement = "select 
			service_instance_id, 
			category, 
			servicename, 
			service_type_uri, 
			authority.authority_uri, 
			url, 
			service_instance.contact_email, 
			authoritative, 
			description, 
			signatureURL,
			lsid 
			from service_instance, authority ";
        my @bindvalues;
 	($statement, @bindvalues) =_add_condition($statement, @args);
	if (keys(%args)){
	    $statement .= " and authority.authority_id = service_instance.authority_id";
	} else {
	    $statement .= " where authority.authority_id = service_instance.authority_id";
	}
 	my $final = do_query($dbh, $statement, @bindvalues);
 	return $final;
}

# custom query for Moby::Central.pm->findService()
# hmmmmmmm....  I'm not sure that this routine should exist...
# it is redundant to the routine above, if the routine above were executed
# multiple times.  I think that is the more correct (though less efficient)
# way to go, since it is "scalable" to every possible underlying data source
# ********FIX  change this later...
sub match_service_type_uri{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	my $uri_list = $args{'service_type_uri'};
	my $statement = "select service_instance_id,category, servicename, service_type_uri, authority_id, url, contact_email, authoritative, description, signatureURL, lsid from service_instance where service_type_uri in ($uri_list)";
	my @bindvalues = ();	
	my $result = do_query($dbh, $statement, @bindvalues);
	return $result;
}

# passs........  blah blah..... 
sub insert_service_instance {
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	my $authority_id;
	if ($args{'authority_uri'}){ # need to transform URI to a row ID
	    my $result = $self->_query_authority(authority_uri => $args{'authority_uri'});
	    return undef unless @$result[0];
	    $authority_id = @$result[0]->{authority_id};
	    return undef unless $authority_id;
	}	

	$dbh->do(q{insert into service_instance (category, servicename, service_type_uri, authority_id, url, contact_email, authoritative, description, signatureURL, lsid) values (?,?,?,?,?,?,?,?,?,?)},
				 undef,(
				 $args{'category'},
				 $args{'servicename'},
				 $args{'service_type_uri'},
				 $authority_id,
				 $args{'url'},
				 $args{'contact_email'},
				 $args{'authoritative'},
				 $args{'description'},
				 $args{'signatureURL'},
				 $args{'lsid'}));
	
	my $id = $dbh->{mysql_insertid};
	return $id;
}

# pass service_instance_lsid
sub delete_service_instance{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	my $statement = "delete from service_instance where lsid = ?";
	$dbh->do( $statement,undef, ($args{service_instance_lsid}) );
	if ($dbh->err){
		return (1, $dbh->errstr);
	}
	else{
		return 0;
	}
}
	
# Selects all columns EXCEPT authority_id
# pass authority_uri
sub query_authority {
	my ($self, %args) = @_;
	my $authURI = $args{authority_uri};
	my $dbh = $self->dbh;
	
	my $statement = "select
          authority_common_name,
          authority_uri,
          contact_email
          from authority where authority_uri = ?";
 	my $result = do_query($dbh, $statement, ($authURI));
 	return $result;
}

# Selects all columns including authority_id
# pass authority_uri.  NOTE THAT THIS IS A PRIVATE ROUTINE
# SHOULD NOT BE DOCUMENTED IN THE API
sub _query_authority {
	my ($self, %args) = @_;
	my $authURI = $args{authority_uri};
	my $dbh = $self->dbh;
	
	my $statement = "select
          authority_common_name,
          authority_uri,
          authority_id,
          contact_email
          from authority where authority_uri = ?";
 	my $result = do_query($dbh, $statement, ($authURI));
 	return $result;
}

# custom query routine used in Moby::Central.pm -> retrieveServiceProviders()
# no args passed
sub get_all_authorities{
	my ($self, @args) = @_;
	my $dbh = $self->dbh;
	my $statement = "select distinct authority.authority_uri from service_instance right join authority on authority.authority_id = service_instance.authority_id  where servicename IS NOT NULL order by authority.authority_uri;";
	my @bindvalues = ();
	my $result = do_query($dbh, $statement, @bindvalues);
	return $result;
}

# pass authority_common_name, authority_uri, contact_email, return ID of some sort
sub insert_authority{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;		
	$dbh->do("insert into authority 
				 (authority_common_name,
				  authority_uri,
				  contact_email)
				 values (?,?,?)",
		undef,
		($args{'authority_common_name'},
		$args{'authority_uri'},
		$args{'contact_email'}));
	my $id = $dbh->{mysql_insertid};
	return $id;
}

# pass service_type, as term or LSID
sub query_service{
	my ($self, %args) = @_;
	my $type = $args{type}||"";
	my $condition = "";
	if ($type =~ /^urn\:lsid/){
	    $condition = "where service_lsid = ?";
	} elsif ($type) {
	    $condition = "where service_type = ?";
	} else {
	    $condition = "";
	}
	
	my $dbh = _getDBHandle("mobyservice");

	my $statement = "select
	  service_id, 
          service_lsid,
          service_type,
          description,
          authority,
          contact_email
	  from
	  service 
          $condition";
	my $result;
	if ($type){
	    $result = do_query($dbh, $statement, ($type));
	} else {
	    $result = do_query($dbh, $statement);
	}
 	return $result;		
}

sub new_query_service{
	my ($self, %args) = @_;
	my $type = $args{type}||"";
	my $condition = "";
	if ($type =~ /^urn\:lsid/){
	    $condition = "where s1.service_lsid = ?";
	} elsif ($type) {
	    $condition = "where s1.service_type = ?";
	} else {
	    $condition = "";
	}
	
	my $dbh = _getDBHandle("mobyservice");

	my $statement = "select
	  s1.service_id as service_id, 
          s1.service_lsid as service_lsid,
          s1.service_type as service_type,
          s1.description as description,
          s1.authority as authority,
          s1.contact_email as contact_email,
	  s2.service_type as parent_type,
	  s2.service_lsid as parent_lsid  
          from
	  service as s1
	  left join service_term2term as t
	    on s1.service_id= t.service1_id
	left join service as s2
	on s2.service_id=t.service2_id
        $condition";
	my $result;
	if ($type){
	    $result = do_query($dbh, $statement, ($type));
	} else {
	    $result = do_query($dbh, $statement);
	}
 	return $result;		
}



# pass in ....
sub insert_service{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	$dbh->do(q{insert into service (service_type, service_lsid, description, authority, contact_email) values (?,?,?,?,?)},
		undef,
		(
		   $args{'service_type'}, $args{'service_lsid'}, $args{'description'},
		   $args{'authority'}, $args{'contact_email'}
		)
	);
	return $dbh->{mysql_insertid};
}

# pass in 'type' as a term or lsid
sub delete_service{
	my ($self, %args) = @_;	
	my $type = $args{type};
	my $result = $self->query_service(type => $type);
	my $row = shift(@$result);
	my $id = $row->{service_id};
	my $lsid = $row->{service_lsid};
	return 0 unless $lsid;
	my $dbh = $self->dbh;
	my $statement = "delete from service where service_lsid = ?";
	$dbh->do( $statement, undef, ($lsid));
	$self->_delete_service_term2term(id => $id);
	if ($dbh->err){
		return (1, $dbh->errstr);
	}
	else{
		return 0;
	}
}

sub query_service_term2term{
    	my ($self, %args) = @_;
	my $type = $args{type};
	my $result = $self->query_service(type => $type);
	my $row = shift(@$result);
	my $id = $row->{service_id};
	return [{}] unless $id;
	my $dbh = $self->dbh;
	
	my $statement = "select
          assertion_id,
          relationship_type,
          service1_id,
          service2_id 
          from service_term2term where service2_id = ?";
 	my $result2 = do_query($dbh, $statement, ($id));
 	return $result2;			
}

#pass relationshiptype, servce1_type, service2_type
sub insert_service_term2term{
	my ($self, %args) = @_;	
	my $type1 = $args{service1_type};
	my $result = $self->query_service(type => $type1);
	my $row = shift(@$result);
	my $id1 = $row->{service_id};
	my $type2 = $args{service2_type};
	$result = $self->query_service(type => $type2);
	$row = shift(@$result);
	my $id2 = $row->{service_id};
	my $relationship_type = $args{relationship_type};

	my $dbh = $self->dbh;
	$dbh->do(q{insert into service_term2term (relationship_type, service1_id, service2_id) values (?,?,?)},
		undef,
		($relationship_type,
		$id1,
		$id2)
	);
	
	return $dbh->{mysql_insertid};
}


# NOTE THAT THIS IS A PRIVATE FUNCTION AND SHOULD
# NOT BE DOCUMENTED IN THE API.  
sub _delete_service_term2term{
	my ($self, %args) = @_;
	my $id = $args{id};
	return 0 unless (defined($id));
	my $dbh = $self->dbh;	
	my $statement = "delete from service_term2term where service1_id=?";
	$dbh->do( $statement,undef, ($id));	
	if ($dbh->err){
		return (1, $dbh->errstr);
	}
	else{
		return 0;
	}
}


sub query_relationship{
	my ($self, %args) = @_;
	my $type = $args{type} || "";
#	return [{}] unless $type;
	my $condition = "";
	if ($type =~ /^urn\:lsid/){
	    $condition = "  relationship_lsid = ? and ";
	} elsif ($type) {
	    $condition = "  relationship_type = ? and ";
	}
	my $ont = $args{ontology};
	
	my $dbh = $self->dbh;
	
	my $statement = "select
          relationship_id,
          relationship_lsid,
          relationship_type,
          container,
          description,
          authority,
          contact_email,
          ontology
          from relationship where $condition ontology = ?";
 	
	if ($type){
	    return do_query($dbh, $statement, ($type, $ont));
	} else {
	    return do_query($dbh, $statement, ($ont));
	}
}

sub query_namespace{
	my ($self, %args) = @_;	
	my $type = $args{type};
	my $condition = "";
	if ($type =~ /^urn\:lsid/){
	    $condition = " where namespace_lsid = ?";
	} elsif ($type) {
	    $condition = " where namespace_type = ?";
	} else {
	    $condition = "";
	}
	
	my $dbh = _getDBHandle("mobynamespace");
	
	my $statement = "select
          namespace_id,
          namespace_lsid,
          namespace_type,
          description,
          authority,
          contact_email
          from namespace $condition";
	my $result;
	if ($type){
	    $result = do_query($dbh, $statement, ($type));
	} else {
	    $result = do_query($dbh, $statement);
	}
 	return $result;	
}


sub insert_namespace{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	$dbh->do(q{insert into namespace (namespace_type, namespace_lsid, description, authority,contact_email) values (?,?,?,?,?)},
		undef,
		(
		   $args{'namespace_type'}, $args{'namespace_lsid'},$args{'description'},$args{'authority'},$args{'contact_email'}
		)
	);
	return $dbh->{mysql_insertid};
}

# pass namesapce_lsid
sub delete_namespace{
	my ($self, %args) = @_;	
	my $type = $args{type};
	my $result = $self->query_namespace(type => $type);
	my $row = shift(@$result);
	my $id = $row->{namespace_id};
	my $lsid = $row->{namespace_lsid};
	return 0 unless $lsid;
	my $dbh = $self->dbh;
	my $statement = "delete from namespace where namespace_lsid = ?";
	$dbh->do( $statement, undef, ($lsid));
	$self->_delete_namespace_term2term(id => $id);
	if ($dbh->err){
		return (1, $dbh->errstr);
	}
	else{
		return 0;
	}
}

sub query_namespace_term2term{
    	my ($self, %args) = @_;
	my $type = $args{type};
	my $result = $self->query_namespace(type => $type);
	my $row = shift(@$result);
	my $id = $row->{namespace_id};
	return [{}] unless $id;
	my $dbh = $self->dbh;
	
	my $statement = "select
          assertion_id,
          relationship_type,
          namespace1_id,
          namespace2_id
          from namespace_term2term where namespace2_id = ?";
 	my $result2 = do_query($dbh, $statement, ($id));
 	return $result2;
}

# PRIVATE, NOT PART OF API!
sub _delete_namespace_term2term{
	my ($self, %args) = @_;
	my $id = $args{id};
	return 0 unless defined($id);
	my $dbh = $self->dbh;	
	my $statement = "delete from namespace_term2term where namespace1_id=?";
	$dbh->do( $statement,undef, ($id));	
	if ($dbh->err){
		return (1, $dbh->errstr);
	}
	else{
		return 0;
	}
}
# pass type as LSID or term
sub check_object_usage{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;	
	my $errorMsg = 1;
	my $type = $args{type};
	return 0 unless $type;
	my $result = $self->query_object(type => $type);
	my $row = shift @$result;
	my $lsid = $row->{object_lsid};
	
	my ($id) = $dbh->selectrow_array(q{select service_instance.service_instance_id from service_instance natural join simple_input where object_type_uri = ?},
		undef, $lsid
	);
	return $errorMsg
	  if ($id);
	  
	($id) = $dbh->selectrow_array(q{select service_instance.service_instance_id from service_instance natural join simple_output where object_type_uri = ?},
		undef, $lsid
	);
	return $errorMsg
	  if ($id);
	  
	($id) = $dbh->selectrow_array(q{select service_instance.service_instance_id from service_instance natural join collection_input natural join simple_input where object_type_uri = ?},
		undef, $lsid
	);
	return $errorMsg
	  if ($id);
	  
	($id) = $dbh->selectrow_array(q{select service_instance.service_instance_id from service_instance natural join collection_output natural join simple_output where object_type_uri = ?},
		undef, $lsid
	);
	return $errorMsg
	  if ($id);	  
	  
	return 0;
}

# custom query routine for Moby::Central.pm -> deregisterNamespace()
sub check_namespace_usage{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;	
	my $errorMsg = 1;
	my $type = $args{type};
	return 0 unless $type;
	my $result = $self->query_namespace(type => $type);
	my $row = shift @$result;
	my $lsid = $row->{namespace_lsid};
		
        my $sth = $dbh->prepare("select service_instance.service_instance_id, namespace_type_uris from service_instance natural join simple_input where INSTR(namespace_type_uris,'$lsid')"
	  );
	$sth->execute;

	while ( my ( $id, $ns ) = $sth->fetchrow_array() ) {
		my @nss = split ",", $ns;
		foreach (@nss) {
			$_ =~ s/\s//g;
			my $errstr = "Namespace Type $type ($_) is used by a service (service ID number $id) and may not be deregistered";
			return (1, $errstr)
			  if ( $_ eq $lsid );
		}
	}
	$sth = $dbh->prepare("select service_instance.service_instance_id, namespace_type_uris from service_instance natural join simple_output where INSTR(namespace_type_uris,'$lsid')"
	  );
	$sth->execute;
	while ( my ( $id, $ns ) = $sth->fetchrow_array() ) {
		my @nss = split ",", $ns;
		foreach (@nss) {
			$_ =~ s/\s//g;
			my $errstr = "Namespace Type $type ($_) is used by a service (service ID number $id) and may not be deregistered";
			return (1, $errstr)
			  if ( $_ eq $lsid );
		}
	}
	$sth =
	  $dbh->prepare("select service_instance.service_instance_id, namespace_type_uris from service_instance natural join collection_input natural join simple_input where INSTR(namespace_type_uris, '$lsid')"
	  );
	$sth->execute;
	while ( my ( $id, $ns ) = $sth->fetchrow_array() ) {
		my @nss = split ",", $ns;
		foreach (@nss) {
			$_ =~ s/\s//g;
			my $errstr = "Namespace Type $type ($_) is used by a service (service ID number $id) and may not be deregistered";
			return (1, $errstr)
			  if ( $_ eq $lsid );
		}
	}
	$sth =
	  $dbh->prepare("select service_instance.service_instance_id, namespace_type_uris from service_instance natural join collection_output natural join simple_output where INSTR(namespace_type_uris, '$lsid')"
	  );
	$sth->execute;
	while ( my ( $id, $ns ) = $sth->fetchrow_array() ) {
		my @nss = split ",", $ns;
		foreach (@nss) {
			$_ =~ s/\s//g;
			my $errstr = "Namespace Type $type ($_) is used by a service (service ID number $id) and may not be deregistered";
			return (1, $errstr)
			  if ( $_ eq $lsid );
		}
	}		
	return (0, "");
}

# custom query routine for Moby::Central.pm -> findService()	
sub check_keywords{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;		
	my $param = $args{keywords};
	return ([{}]) unless (ref($param) =~ /ARRAY/);
	my @keywords = @$param;
	#my %findme = %$param;
	my $searchstring;
	foreach my $kw ( @keywords ) {
			$kw =~ s/\*//g;
			$kw = $dbh->quote("%$kw%");
			$searchstring .= " OR description like $kw ";
		}
		$searchstring =~ s/OR//;    # remove just the first OR in the longer statement

	my $statement = "select service_instance_id,category, servicename, service_type_uri, authority_id, url, contact_email, authoritative, description, signatureURL, lsid from service_instance where $searchstring";
	my @bindvalues = ();
	
	my $ids = do_query($dbh, $statement, @bindvalues);		  
	return ($ids);
}	
	
# custom query subroutine for Moby::Central.pm->_searchForSimple()
sub find_by_simple{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;	
	my $inout = $args{'inout'};
	my $ancestor_string = $args{'ancestor_string'};
	my $namespaceURIs = $args{'namespaceURIs'};
	
	my $query ="select service_instance_id, namespace_type_uris from simple_$inout where object_type_uri in ($ancestor_string) and collection_${inout}_id IS NULL "
	  ;    # if service_instance_id is null then it must be a collection input.
	my $nsquery;
	foreach my $ns ( @{$namespaceURIs} ) {    # namespaces are already URI's
		$nsquery .= " OR INSTR(namespace_type_uris, '$ns') ";
	}
	if ($nsquery) {
		$nsquery =~ s/OR//;                   # just the first
		$nsquery .= " OR namespace_type_uris IS NULL";
		$query   .= " AND ($nsquery) ";
	}
	
	my $result = do_query($dbh, $query, ());
 	return $result;
}

# custom query subroutine for Moby::Central.pm->_searchForCollection()
sub find_by_collection{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;	
	my $inout = $args{'inout'};
	my $objectURI = $args{'objectURI'};
	my $namespaceURIs = $args{'namespaceURIs'};
	
	my $query = "select
			c.service_instance_id,
			s.namespace_type_uris
		from
			simple_$inout as s,
			collection_$inout as c
		where
			s.collection_${inout}_id IS NOT NULL
		AND s.collection_${inout}_id = c.collection_${inout}_id
		AND object_type_uri = '$objectURI' ";
	my $nsquery;
		foreach my $ns ( @{$namespaceURIs} ) {    # namespaces are already URI's
			$nsquery .= " OR INSTR(namespace_type_uris, '$ns') ";
		}
		if ($nsquery) {
			$nsquery =~ s/^\sOR//;                # just the first
			$nsquery .= " OR namespace_type_uris IS NULL";
			$query   .= " AND ($nsquery) ";                 # add the AND clause
		}
		
	my $result = do_query($dbh, $query, ());
 	return $result;
}

# custom query subroutine for Moby::Central.pm->RetrieveServiceNames
sub get_service_names{		
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;	
	my $statement = "select authority_uri, servicename, lsid from authority as a, service_instance as s where s.authority_id = a.authority_id";	
	my @bindvalues = ();
	
    my $result = do_query($dbh, $statement, @bindvalues);
	return $result; 
}

# custom query for Moby::Central.pm->_flatten
sub get_parent_terms{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	
	my $type_id = $args{'relationship_type_id'};
	my $statement = "
	select
		OE1.term
	from
		OntologyEntry as OE1,
		OntologyEntry as OE2,
		Term2Term as TT
	where
		ontologyentry2_id = OE2.id
		and ontologyentry1_id = OE1.id
		and relationship_type_id = $type_id
		and OE2.term = ?";
		
	my @bindvalues = ();
	push(@bindvalues, $args{'term'});
	
	my $result = do_query($dbh, $statement, @bindvalues);
	return $result;
}

# custom query subroutine for selecting from object_term2term and object tables
# used in Moby::OntologyServer.pm->retrieveObject()
sub get_object_relationships{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	my $type = $args{type};
	return 0 unless $type;
	my $result = $self->query_object(type => $type);
	my $row = shift @$result;
	my $id = $row->{object_id};

	my $statement = "select 
	relationship_type,
	object_type,
	object_lsid,
	description,
	authority,
	contact_email,
	object2_articlename 
	from object_term2term, object 
	where object1_id = ? and object2_id = object_id";
	
	my $result2 = do_query($dbh, $statement, ($id));
	return $result2;
}

# relationship query for any table used in Moby::OntologyServer->_doRelationshipQuery()
# note: returns a reference to an array containing ARRAY references
sub get_relationship{
	my ($self, %args) = @_;	
	my $dbh = $self->dbh;
	my $direction = $args{'direction'};
	my $ontology = $args{'ontology'};
	my $relationship = $args{'relationship'}; # this is assumed to be an LSID

	my $type = $args{'term'};
	return 0 unless $type;
	my $lsid;
	if ($ontology eq "service"){
	    my $result = $self->query_service(type => $type);
	    my $row = shift @$result;
	    $lsid = $row->{service_lsid};
	} else {
	    my $result = $self->query_object(type => $type);
	    my $row = shift @$result;
	    $lsid = $row->{object_lsid};
	}
	my $defs;
	my $extra_columns;
	$extra_columns = ", relationship_type ";
	if ($ontology eq "object"){$extra_columns .=", object2_articlename ";}
	if ( $direction eq 'root' ) {
		unless ( defined $relationship ) {
			$defs = $self->dbh->selectall_arrayref( "
            select distinct s2.${ontology}_lsid $extra_columns from
                ${ontology}_term2term as t2t,
                $ontology as s1,
                $ontology as s2  
            where
                s1.${ontology}_id = t2t.${ontology}1_id and
                s2.${ontology}_id = t2t.${ontology}2_id and
                s1.${ontology}_lsid = ?", undef, $lsid );    # ")
		} else {
			$defs = $self->dbh->selectall_arrayref( "
            select distinct s2.${ontology}_lsid $extra_columns from
                ${ontology}_term2term as t2t,
                $ontology as s1,
                $ontology as s2  
            where
                relationship_type = ? and 
                s1.${ontology}_id = t2t.${ontology}1_id and
                s2.${ontology}_id = t2t.${ontology}2_id and
                s1.${ontology}_lsid = ?", undef, $relationship, $lsid );    # ")
		}
	} else {
		unless ( defined $relationship ) {
			$defs = $self->dbh->selectall_arrayref( "
            select distinct s1.${ontology}_lsid $extra_columns from
                ${ontology}_term2term as t2t,
                $ontology as s1,
                $ontology as s2  
            where
                s1.${ontology}_id = t2t.${ontology}1_id and
                s2.${ontology}_id = t2t.${ontology}2_id and
                s2.${ontology}_lsid = ?", undef, $lsid);                   # ")
		} else {
			$defs = $self->dbh->selectall_arrayref( "
            select distinct s1.${ontology}_lsid $extra_columns from
                ${ontology}_term2term as t2t,
                $ontology as s1,
                $ontology as s2  
            where
                relationship_type = ? and 
                s1.${ontology}_id = t2t.${ontology}1_id and
                s2.${ontology}_id = t2t.${ontology}2_id and
                s2.${ontology}_lsid = ?", undef, $relationship, $lsid );    # ")
		}
	}
	return $defs;
}

# Get all relationships in the queried database in one go.  The
# complete table ${ontology}_term2term is transferred into a hash
# whose reference is finally returned.  Important: note that the hash
# is built 'direction aware', that is for objects 'object1_id' is used
# as key when direction is 'root' and 'object2_id' as value. Vice
# versa for the 'leaves' direction.  Likewise for services.
# Returns a hash reference.
sub get_all_relationships {

  my ($self, %args) = @_;
  my $direction = $args{'direction'};
  my $ontology = $args{'ontology'};
  # my $relationship = $args{'relationship'}; # has to be lsid!

  my $relHash;
  my $dbh = _getDBHandle("moby$ontology");

  my $statement = "select ${ontology}1_id, ${ontology}2_id, relationship_type";
  $statement .= ", object2_articlename, assertion_id " if $ontology eq 'object';
  $statement .= " from ${ontology}_term2term";
  # my $relationship_lsid = "urn:lsid:biomoby.org:${ontology}relation:isa";
  my $defs = $dbh->selectall_arrayref($statement);

  return {} unless @$defs;
  foreach my $def (@$defs) {
    my $relationship = $def->[2];
    if ( $relationship =~ /has/i ) {
      # HAS or HASA
      # >1 has/hasa child possible; also store articlename and assertion_id
      # hash structure: $relHash->{has/a-lsid}->{object1_id}->[object2_id,articlename,assertion_id]
      push @{$relHash->{$relationship}->{$def->[0]}}, [$def->[1],$def->[3],$def->[4]] if $direction eq 'root';
      push @{$relHash->{$relationship}->{$def->[1]}}, [$def->[0],$def->[3],$def->[4]] if $direction eq 'leaves';
    }
    elsif ( $relationship =~ /isa/i ) {
      # ISA
      push @{$relHash->{$relationship}->{$def->[1]}}, $def->[0] if $direction eq 'leaves'; # >1 child possible!
      $relHash->{$relationship}->{$def->[0]} = $def->[1] if $direction eq 'root'; # no multi parents!
    }
    else { return {}; }
  }
  return $relHash;
}

# retrieve details for a number of entities from table $ontology
# represented by a list of ${ontology}_id's;
# used in MOBY::OntologyServer::Relationships
sub get_details_for_id_list {
  my ($self, $ontology, $fields, $idList) = @_;

  return {} unless @$idList;
  return {} unless @$fields;

  my $dbh = _getDBHandle("moby$ontology");
  my $result = {};

  # avoid errors due to wrong field names:
  my %existingFields;
  my @queryFields = ();
  my $resArray = $dbh->selectall_arrayref("SHOW COLUMNS FROM $ontology");
  foreach my $row ( @$resArray ) {
    $existingFields{$row->[0]}++;
  }
  foreach my $field ( @$fields ) {
    next if $field eq "${ontology}_id";
    if ( exists $existingFields{$field} ) {
      push @queryFields, $field;
    }
    else {
      warn "Requested field $field does not exist in table $ontology!";
    }
  }

  #
  my $statement = "select ${ontology}_id, ". join(",", @queryFields). 
    " from $ontology where ${ontology}_id in (" .
      join(",", @$idList) . ")";
  $resArray = $dbh->selectall_arrayref($statement);
  foreach my $row ( @$resArray ) {
    my $entityId = shift @$row;
    foreach my $field (@queryFields) {
      my $value = shift @$row;
      $result->{$entityId}->{$field} = $value ? $value : '';
    }
  }
  return $result;
}

sub _checkURI {
	
#	my $uri = "http://www.ics.uci.edu/pub/ietf/uri/#Related";
#print "$1, $2, $3, $4, $5, $6, $7, $8, $9" if
#  $uri =~ m{^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?};
#
#The license for this recipe is available here.
#
#Discussion:
#
#If the match is successful, a URL such as
#
#http://www.ics.uci.edu/pub/ietf/uri/#Related
#
#will be broken down into the following group match variables:
#
#$1 = http:
#$2 = http
#$3 = //www.ics.uci.edu
#$4 = www.ics.uci.edu
#$5 = /pub/ietf/uri/
#$6 =
#$7 =
#$8 = #Related
#$9 = Related
#
#In general, this regular expression breaks a URI down into the following parts,
#as defined in the RFC:
#
#scheme = $2
#authority = $4
#path = $5
#query = $7
#fragment = $9

}

sub DESTROY {}

1;
