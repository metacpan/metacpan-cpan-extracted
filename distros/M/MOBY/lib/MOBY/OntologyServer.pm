#$Id: OntologyServer.pm,v 1.3 2008/09/02 13:14:18 kawas Exp $
# this module needs to talk to the 'real' ontology
# server as well as the MOBY Central database
# in order to ensure that they are both in sync

=head1 NAME

MOBY::OntologyServer - A way for MOBY Central to query the
object, service, namespace, and relationship ontologies

=cut

=head1 SYNOPSIS

 use MOBY::OntologyServer;
 my $OS = MOBY::OntologyServer->new(ontology => "object");

 my ($success, $message, $existingURI) = $OS->objectExists(term => "Object");

 if ($success){
     print "object exists and it has the LSID $existingURI\n";
 } else {
    print "object does not exist; additional message from server: $message\n";
 }


=cut

=head1 DESCRIPTION

Swappable interface to ontologies.  It should deal with LSID's 100%
of the time, and also deal with MOBY-specific common names for objects,
services, namespaces, and relationship types.



=head1 AUTHORS

Mark Wilkinson (markw@illuminae.com)

BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS


=head2 new

 Title     :	new
 Usage     :	my $OS = MOBY::OntologyServer->new(%args)
 Function  :	
 Returns   :	MOBY::OntologyServer object
 Args      :    ontology => [object || service || namespace || relationship]
                database => mysql databasename that holds the ontologies
                host =>  mysql hostname
                username => mysql username
                password => mysql password
                port => mysql port
                dbh => pre-existing database handle to a mysql database

=cut

package MOBY::OntologyServer;

use strict;
use Carp;
use vars qw($AUTOLOAD);
use DBI;
use DBD::mysql;
use MOBY::Config;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

my $debug = 0;
{

	#Encapsulated class data
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		ontology => [ undef, 'read/write' ],
		database => [ undef, 'read/write' ],
		host     => [ undef, 'read/write' ],
		username => [ undef, 'read/write' ],
		password => [ undef, 'read/write' ],
		port     => [ undef, 'read/write' ],
		dbh      => [ undef, 'read/write' ],
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
}

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref($caller);
	my $class         = $caller_is_obj || $caller;
	my $self          = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} && defined $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ($caller_is_obj) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for($attrname);
		}
	}
	$self->ontology eq 'object'       && $self->database('mobyobject');
	$self->ontology eq 'namespace'    && $self->database('mobynamespace');
	$self->ontology eq 'service'      && $self->database('mobyservice');
	$self->ontology eq 'relationship' && $self->database('mobyrelationship');

	#print STDERR "\n\nCONFIG object is $CONFIG\n\n";
	$CONFIG ||= MOBY::Config->new;

#print STDERR "got username ",($CONFIG->{mobycentral}->{username})," for mobycentral\n";
	$self->username( $CONFIG->{ $self->database }->{username} )
	  unless $self->username;
	$self->password( $CONFIG->{ $self->database }->{password} )
	  unless $self->password;
	$self->port( $CONFIG->{ $self->database }->{port} ) unless $self->port;
	$self->host( $CONFIG->{ $self->database }->{url} )  unless $self->host;
	my $host = $self->host ? $self->host : $ENV{MOBY_CENTRAL_URL};
	chomp $host;
	my $username =
	  $self->username ? $self->username : $ENV{MOBY_CENTRAL_DBUSER};
	chomp $username;
	my $password =
	  $self->password ? $self->password : $ENV{MOBY_CENTRAL_DBPASS};
	chomp $password if $password;
	$password =~ s/\s//g if $password;
	my $port = $self->port ? $self->port : $ENV{MOBY_CENTRAL_DBPORT};
	chomp $port;
	my ($dsn) =
	    "DBI:mysql:"
	  . ( $CONFIG->{ $self->database }->{dbname} ) . ":"
	  . ($host) . ":"
	  . ($port);

	#print STDERR "\n\nDSN was $dsn\n\n";
	my $dbh;

#	$debug && &_LOG("connecting to db with params ",$self->database, $self->username, $self->password,"\n");
	if ( defined $password ) {
		$dbh = DBI->connect( $dsn, $username, $password, { RaiseError => 1 } )
		  or die "can't connect to database";
	} else {
		$dbh = DBI->connect( $dsn, $username, undef, { RaiseError => 1 } )
		  or die "can't connect to database";
	}

	#	$debug && &_LOG("CONNECTED!\n");
	if ($dbh) {
		$self->dbh($dbh);
		return $self;
	} else {
		return undef;
	}
}

=head2 objectExists

 moby:newterm will return (0, $message, $MOBYLSID)
 newterm will return (0, $message, $MOBYLSID
 oldterm will return (1, $message, undef)
 newLSID will return (0, $desc, $lsid)


=cut

sub objectExists {
	my ( $self, %args ) = @_;

	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );

	my $term = $args{term};
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	my $sth;
	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'object' );
	return (0, undef, undef) unless $term;

	my $result;
	
	$result = $adaptor->query_object(type => $term);
	
	my $row = shift(@$result);
	my $lsid = $row->{object_lsid};
	my $type = $row->{object_type};
	my $desc = $row->{description};
	my $auth = $row->{authority};
	my $email = $row->{contact_email};
	
	if ($lsid)
	{ # if it is in there, then it has been discovered regardless of being foreign or not
		return ( 1, $desc, $lsid );
	} elsif ( _isForeignLSID($term) )
	{ # if not in our ontology, but is a foreign LSID, then pass it back verbatim
		return (
			0,
"LSID $term does not exist in the biomoby.org Object Class system\n",
			$term
		);
	} else { # under all other circumstances (i.e. not a term, or a non-existent biomoby LSID) then fail
		return (
			0,
"Object type $term does not exist in the biomoby.org Object Class system\n",
			''
		);
	}
}

=head2 objectInfo

=cut

sub objectInfo{
	my ( $self, %args ) = @_;

	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );

	my $term = $args{term};
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	my $sth;
	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'object' );
	return (0, undef, undef) unless $term;

	my $result;
	
	$result = $adaptor->query_object(type => $term);
	my $row = shift(@$result);
	#my $lsid = $row->{object_lsid};
	#my $type = $row->{object_type};
	#my $desc = $row->{description};
	#my $auth = $row->{authority};
	#my $email = $row->{contact_email};
	#
	if ($row->{object_lsid})
	{ # if it is in there, then it has been discovered regardless of being foreign or not
		return $row;
	} elsif ( _isForeignLSID($term) ) { # if not in our ontology, but is a foreign LSID, then pass it back verbatim
		return {object_lsid => $term,
			object_type => $term,
			description => "LSID $term does not exist in the biomoby.org Object Class system\n",
			authority => "",
			contact_email => "",
		       };
	} else { # under all other circumstances (i.e. not a term, or a non-existent biomoby LSID) then fail
		return {object_lsid => "",
			object_type => "",
			description => "LSID $term does not exist in the biomoby.org Object Class system\n",
			authority => "",
			contact_email => "",
		       };
	}
}


=head2 serviceInfo

=cut

sub serviceInfo{
	my ( $self, %args ) = @_;

	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyservice' );

	my $term = $args{term};
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	my $sth;
	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'service' );
	return (0, undef, undef) unless $term;

	my $result;
	
	$result = $adaptor->query_service(type => $term);
	my $row = shift(@$result);

	if ($row->{service_lsid})
	{ # if it is in there, then it has been discovered regardless of being foreign or not
		return $row;
	} elsif ( _isForeignLSID($term) ) { # if not in our ontology, but is a foreign LSID, then pass it back verbatim
		return {service_lsid => $term,
			service_type => $term,
			description => "LSID $term does not exist in the biomoby.org Object Class system\n",
			authority => "",
			contact_email => "",
		       };
	} else { # under all other circumstances (i.e. not a term, or a non-existent biomoby LSID) then fail
		return {service_lsid => "",
			service_type => "",
			description => "LSID $term does not exist in the biomoby.org Object Class system\n",
			authority => "",
			contact_email => "",
		       };
	}
}

sub _isMOBYLSID {
	my ($lsid) = @_;
	return 1 if $lsid =~ /^urn\:lsid\:biomoby.org/;
	return 0;
}

sub _isForeignLSID {
	my ($lsid) = @_;
	return 0 if $lsid =~ /^urn\:lsid\:biomoby.org/;
	return 1;
}

=head2 createObject

=cut

sub createObject {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );
	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'object' );
	return ( 0, "requires a object type node", '' ) unless ( $args{node} );
	return ( 0, "requires an authURI ",        '' ) unless ( $args{authority} );
	return ( 0, "requires a contact email address", '' )
	  unless ( $args{contact_email} );
	return ( 0, "requires a object description", '' )
	  unless ( $args{description} );
	my $term = $args{node};

	my $result;
	$result = $adaptor->query_object(type => $term);		
	my $row = shift(@$result);
	my $lsid = $row->{object_lsid};
	my $type = $row->{object_type};
	my $desc = $row->{description};
	my $auth = $row->{authority};
	my $email = $row->{contact_email};

	if ($lsid) {    # if it is in there, then the object exists
		return ( 0, "This term already exists: $lsid", $lsid );
	}
	my $LSID = $self->setURI( $term );
	unless ($LSID) { return ( 0, "Failed during creation of an LSID", '' ) }
	$args{description}   =~ s/^\s+(.*?)\s+$/$1/s;
	$args{node}          =~ s/^\s+(.*?)\s+$/$1/s;
	$args{contact_email} =~ s/^\s+(.*?)\s+$/$1/s;
	$args{authority}     =~ s/^\s+(.*?)\s+$/$1/s;
	
	my $insertid = $adaptor->insert_object(object_type => $args{'node'}, 
						object_lsid => $LSID, 
						description => $args{'description'},
						authority => $args{'authority'},
						contact_email => $args{'contact_email'});
	unless ( $insertid ) {
		return ( 0, "Object creation failed for unknown reasons", '' );
	}
	return ( 1, "Object creation succeeded", $LSID );
}

=head2 retrieveObject

=cut

sub retrieveObject {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );
	my $term = $args{'type'};
	$term ||=$args{'node'};
	
	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'object' );
	return ( 0, "requires a object type node as an argument", '' )
	  unless ( $term );
	my $LSID =
	  ( $term =~ /urn\:lsid/ )
	  ? $term
	  : $self->getObjectURI($term);
	unless ($LSID) { return ( 0, "Failed during creation of an LSID", '' ) }
	my $result = $adaptor->query_object(type => $LSID);
	my $row = shift(@$result);
	my $type = $row->{object_type};
	my $lsid = $row->{object_lsid};
	my $desc = $row->{description};
	my $auth = $row->{authority};
	my $contact = $row->{contact_email};

	unless ($lsid) { return ( 0, "Object doesn't exist in ontology", "" ) }

	$result = $adaptor->get_object_relationships(type => $lsid);
	my %rel;
	foreach my $row (@$result)
	{
	my $relationship_type = $row->{relationship_type};
	my $objectlsid = $row->{object_lsid};
	my $article = $row->{object2_articlename};
	my $contact = $row->{contact_email};
	my $def = $row->{definition};
	my $auth = $row->{authority};
	my $type = $row->{object_type};

	push @{ $rel{$relationship_type} }, [ $objectlsid, $article, $type, $def, $auth, $contact ];
	}
	return {
			 objectType	=> $type,
			 objectLSID    => $lsid,
			 description   => $desc,
			 contactEmail  => $contact,
			 authURI       => $auth,
			 Relationships => \%rel
	};
}

=head2 deprecateObject

=cut

sub deprecateObject {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );

	return ( 0, "WRONG ONTOLOGY", '' ) unless ( $self->ontology eq 'object' );
	my $term = $args{term};

#    if ($term =~ /^urn:lsid/ && !($term =~ /^urn:lsid:biomoby.org:objectclass/)){
#        return (0, "can't delete from external ontology", $term);
#    }
	my $LSID;
	unless ( $term =~ /urn\:lsid/ ) { $LSID = $self->getObjectURI($term) } else { $LSID = $term }
	return ( 0, "Object type $term cannot be resolved to an LSID", "" )
	  unless $LSID;
	
	my $result = $adaptor->query_object(type => $LSID);
	my $row = shift(@$result);
	my $id = $row->{object_id};
	my $lsid = $row->{object_lsid};

	# object1_id ISA object2_id?
	my $isa = $adaptor->query_object_term2term(type => $lsid);
	my $isas = shift @$isa;
	if ( $isas->{object1_id}) {
		return ( 0,
				 qq{Object type $term has object dependencies in the ontology},
				 $lsid );
	}

	my ($err, $errstr) = $adaptor->delete_object(type => $lsid);
	if ( $err ) {
		return ( 0, "Delete from Object Class table failed: $errstr",
				 $lsid );
	}
	return ( 1, "Object $term Deleted", $lsid );
}

=head2 deleteObject

=cut

sub deleteObject {
	my $self = shift;
	$self->deprecateObject(@_);
}

=head2 relationshipExists

=cut 

sub relationshipExists {

	# term => $term
	# ontology => $ontology
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyrelationship' );
	return ( 0, "WRONG ONTOLOGY!", '' )
	  unless ( $self->ontology eq 'relationship' );
	my $term = lc( $args{term} );
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	my $ont = $args{ontology};
	return ( 0, "requires both term and ontology arguments\n", '' )
	  unless ( defined($term) && defined($ont) );
	my $result;
	if ( $term =~ /^urn\:lsid/ ) {

	$result = $adaptor->query_relationship(
					type => $term,
					ontology => $ont);	
	
	} else {
	
	$result = $adaptor->query_relationship(type => $term, ontology => $ont);
	
	}
	my $row = shift(@$result);
	my $lsid = $row->{relationship_lsid};
	my $type = $row->{relationship_type};
	my $desc = $row->{description};
	my $auth = $row->{authority};
	my $email = $row->{contact_email};
	if ($lsid) {
		return ( 1, $desc, $lsid, $type, $auth, $email );
	} else {
		return (
			0,"Relationship Type $term does not exist in the biomoby.org Relationship Type system\n",
			'', '', '', ''
		);
	}
}

=head2 addObjectRelationship

=cut

sub addObjectRelationship {

	# adds a  relationship
	#subject_node => $term,
	#relationship => $reltype,
	#object_node => $objectType,
	#articleName => $articleName,
	#authority => $auth,
	#contact_email => $email
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );

	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'object' );
	
	my $result = $adaptor->query_object(type => $args{subject_node});
	my $row = shift(@$result);
	my $subj_lsid = $row->{object_lsid};
	return ( 0, qq{Object type $args{subject_node} does not exist in the ontology}, '' )
	  unless defined $subj_lsid;
	  
	$result = $adaptor->query_object(type => $args{object_node});
	$row = shift(@$result);
	my $obj_lsid = $row->{object_lsid};
	return ( 0,qq{Object type $args{object_node} does not exist in the ontology},'' )
	  unless defined $obj_lsid;
	my $isa = $adaptor->query_object_term2term(type => $subj_lsid);
	my $isarow = shift @$isa;
	if ( $isarow->{object_lsid} ) {
		return (
			0,
			qq{Object type $args{subject_node} has existing object dependencies in the ontology.  It cannot be changed.},
			$subj_lsid
		);
	}
	my $OE = MOBY::OntologyServer->new( ontology => 'relationship' );
	my ( $success, $desc, $rel_lsid ) = $OE->relationshipExists(
		term => $args{relationship},
		ontology => 'object' );
	($success) || return ( 0,
			qq{Relationship $args{relationship} does not exist in the ontology},
			'' );
	
	# need to ensure that identical article names dont' end up at the same level
	my $articleNameInvalid = &_testIdenticalArticleName(term => $subj_lsid, articleName => $args{articleName});
	return (0, "Object will have conflicting articleName ".($args{articleName}), '') if $articleNameInvalid;

	my $insertid = $adaptor->insert_object_term2term(relationship_type => $rel_lsid, 
							 object1_type => $subj_lsid,
							 object2_type => $obj_lsid,
							 object2_articlename => $args{articleName});
	
	
	if ($insertid ) {
		return ( 1, "Object relationsihp created successfully", '' );
	} else {
		return ( 0, "Object relationship creation failed for unknown reasons",
				 '' );
	}
}

sub _testIdenticalArticleName {
	my (%args)= @_;
	my $term = $args{term};
	my $articleName = $args{articleName};
	my $foundCommonArticleNameFlag = 0;
	# need to first traverse down the ISA pathway to root
	# then for each ISA test the hAS and HASA's for their articlenames and see if they are the same
	# case insensitive?
	my $OS = MOBY::OntologyServer->new(ontology => 'object');
	my $OSrel = MOBY::OntologyServer->new(ontology => 'relationship');
	my ($exists1, $desc, $isalsid) = $OSrel->relationshipExists(term => 'isa', ontology => 'object');
	my ($exists2, $desc2, $hasalsid) = $OSrel->relationshipExists(term => 'hasa', ontology => 'object');
	my ($exists3, $desc3, $haslsid) = $OSrel->relationshipExists(term => 'has', ontology => 'object');
	
	return 1 unless ($exists1 && $exists2 && $exists3);  # this is bad, since it returns boolean suggesting that it found a common articlename rather than finding that a given relationship doesn't exist, but... hey....
		# check the hasa relationships for common articleName
	$foundCommonArticleNameFlag += _compareArticleNames(OS => $OS, type => $args{term}, relationship => $hasalsid, targetArticleName => $articleName);
		# check the has relationships for common articleName		
	$foundCommonArticleNameFlag += _compareArticleNames(OS => $OS, type => $args{term}, relationship => $haslsid, targetArticleName => $articleName);

	# now get all of its inherited parents
	my $relationships = $OS->Relationships(
		ontology => 'object',
		term => $args{term},
		relationship => $isalsid,
		direction => 'root',
		expand =>  1);
	 #relationships{relationship} = [[lsid1,articleNmae], [lsid2, articleName], [lsid3, articleName]]	
	my ($isa) = keys(%$relationships);  # can only be one key returned, and must be isa in this case
	my @ISAlist;
	(@ISAlist = @{$relationships->{$isa}}) if ($relationships->{$isa}) ;
	# for each of the inherited parents, check their articleNames
	foreach my $ISA(@ISAlist){  # $ISA = [lsid, articleName] (but articleName shuld be null anyway in this case)
		my $what_it_is = $ISA->{lsid};
		# check the hasa relationships for common articleName
		$foundCommonArticleNameFlag += _compareArticleNames(OS => $OS, type => $what_it_is, relationship => $hasalsid, targetArticleName => $articleName);
		# check the has relationships for common articleName		
		$foundCommonArticleNameFlag += _compareArticleNames(OS => $OS, type => $what_it_is, relationship => $haslsid, targetArticleName => $articleName);
	}
	return $foundCommonArticleNameFlag;
}

sub _compareArticleNames {
	my (%args) = @_;
	my $OS =  $args{OS};
	my $what_it_is = $args{type};
	my $lsid = $args{relationship};
	my $targetArticleName = $args{targetArticleName};
	my $foundCommonArticleNameFlag = 0;
	my $contents = $OS->Relationships(
		ontology => 'object',
		term => $what_it_is,
		relationship => $lsid,
		direction => 'root',
		);
	if ($contents){
		#$hasarelationships{relationship} = [[lsid1,articleNmae], [lsid2, articleName], [lsid3, articleName]]	
	       my ($content) = keys(%$contents);
	       if ($contents->{$content}){
			my @CONTENTlist = @{$contents->{$content}};
			foreach my $CONTAINED(@CONTENTlist){
				$foundCommonArticleNameFlag = 1 if ($CONTAINED->{articleName} eq $targetArticleName); #->[1] is the articleName field
			}
	       }
	}
	return $foundCommonArticleNameFlag;
}

=head2 addServiceRelationship

=cut

sub addServiceRelationship {

	# adds an ISA relationship
	# fail if another object is in relation to this objevt
	#subject_node => $term,
	#relationship => $relationship,
	#predicate_node => $pred
	#authority => $auth,
	#contact_email => $email);
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyservice' );

	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'service' );

	my $result = $adaptor->query_service(type => $args{subject_node});
	my $row = shift(@$result);
	my $sbj_lsid = $row->{service_lsid};
					    
	return (0,
		qq{Service type $args{subject_node} has object dependencies in the ontology.  It can not be changed},
		$sbj_lsid
	  ) unless defined $sbj_lsid;

	my $isa = $adaptor->query_service_term2term(service2_id => $sbj_lsid);
	my $isarow = shift @$isa;
	if ( $isarow->{service_lsid} ) {
		return (
			0,
			qq{Service type $args{subject_node} has object dependencies in the ontology.  It can not be changed},
			$sbj_lsid
		);
	}
	$result = $adaptor->query_service(type => $args{object_node});
	$row = shift(@$result);
	my $obj_lsid = $row->{service_lsid};
	# get ID of the related service
	
	defined $obj_lsid
	  || return ( 0,
		  qq{Service $args{object_node} does not exist in the service ontology},
		  '' );
	my $OE = MOBY::OntologyServer->new( ontology => 'relationship' );
	my ( $success, $desc, $rel_lsid ) = $OE->relationshipExists(
		term => $args{relationship},
		ontology => 'service' );
	($success)
	  || return ( 0,
			qq{Relationship $args{relationship} does not exist in the ontology},
			'' );

	my $insertid = $adaptor->insert_service_term2term(relationship_type => $rel_lsid, 
							  service1_type => $sbj_lsid,
							  service2_type => $obj_lsid);
	if ( defined($insertid)) {
		return ( 1, "Service relationship created successfully", '' );
	} else {
		return ( 0, "Service relationship creation failed for unknown reasons",
				 '' );
	}
}

=head2 serviceExists

=cut

sub serviceExists {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyservice' );

	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'service' );
	my $term = $args{term};
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	if ( $term =~ /^urn:lsid/
		 && !( $term =~ /^urn:lsid:biomoby.org:servicetype/ ) )
	{
		return ( 1, "external ontology", $term );
	}
	return (0, undef, undef) unless $term;

	my $result;
	$result = $adaptor->query_service(type => $term);
	my $row = shift(@$result);
	my $id = $row->{service_id};
	my $type = $row->{service_type};
	my $lsid = $row->{service_lsid};
	my $desc = $row->{description};
	my $auth = $row->{authority};
	my $email = $row->{contact_email};

	if ($id) {
		return ( 1, $desc, $lsid );
	} else {
		return (
			0,
"Service Type $term does not exist in the biomoby.org Service Type ontology\n",
			''
		);
	}
}

=head2 createServiceType

=cut

sub createServiceType {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyservice' );

	#node => $term,
	#descrioption => $desc,
	#authority => $auth,
	#contact_email => $email);
	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'service' );
	return ( 0, "requires a object type node", '' ) unless ( $args{node} );
	return ( 0, "requires an authURI ",        '' ) unless ( $args{authority} );
	return ( 0, "requires a contact email address", '' )
	  unless ( $args{contact_email} );
	return ( 0, "requires a object description", '' )
	  unless ( $args{description} );
	my $term = $args{node};
	if ( $term =~ /^urn:lsid/
		 && !( $term =~ /^urn:lsid:biomoby.org:servicetype/ ) )
	{    # if it is an LSID, but not a MOBY LSID, than barf
		return ( 0, "can't create a term in a non-MOBY ontology!", $term );
	}

	my $LSID =$self->setURI( $args{'node'} );
	unless ($LSID) { return ( 0, "Failed during creation of an LSID", '' ) }

	my $insertid = $adaptor->insert_service(service_type => $args{'node'},
						service_lsid => $LSID,
						description => $args{'description'},
						authority => $args{'authority'},
						contact_email => $args{'contact_email'});

	unless ( $insertid ) {
		return ( 0, "Service creation failed for unknown reasons", '' );
	}
	return ( 1, "Service creation succeeded", $LSID );
}

=head2 deleteServiceType

=cut

sub deleteServiceType {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyservice' );

	return ( 0, "WRONG ONTOLOGY!", '' ) unless ( $self->ontology eq 'service' );
	my $term = $args{term};
	if ( $term =~ /^urn:lsid/
		 && !( $term =~ /^urn:lsid:biomoby.org:servicetype/ ) )
	{
		return ( 0, "can't delete from external ontology", $term );
	}
	my $LSID;
	unless ( $term =~ /^urn:lsid:biomoby.org:servicetype/ ) {
		$LSID = $self->getServiceURI($term);
	} else {
		$LSID = $term;
	}
	return (
		0, q{Service type $term cannot be resolved to an LSID in the MOBY ontologies},""
	  ) unless $LSID;

	my $result = $adaptor->query_service(type => $LSID);
	my $row = shift(@$result);
	my $lsid = $row->{service_lsid};

	if ( !defined $lsid ) {
		return ( 0, q{Service type $term does not exist in the ontology},
				 $lsid );
	}

	# service1_id ISA service2_id?
	my $isa = $adaptor->query_service_term2term(type => $lsid);
	my $isas = shift(@$isa);
	
	if ( $isas->{service1_id} ) {
		return ( 0, qq{Service type $term has dependencies in the ontology},
				 $lsid );
	}
	my ($err, $errstr) = $adaptor->delete_service(type => $lsid);

	if ( $err ) {
		return ( 0, "Delete from Service Type table failed: $errstr",
				 $lsid );
	}

	return ( 1, "Service Type $term Deleted", $lsid );
}

=head2 namespaceExists

=cut

sub namespaceExists {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobynamespace' );

	return ( 0, "WRONG ONTOLOGY!", '' )
	  unless ( $self->ontology eq 'namespace' );
	my $term = $args{term};
	return (0, undef, undef) unless $term;
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	if ( $term =~ /^urn:lsid/
		 && !( $term =~ /^urn:lsid:biomoby.org:namespacetype/ ) )
	{
		return ( 1, "external ontology", $term );
	}
	my $result;
	$result = $adaptor->query_namespace(type => $term);
	my $row = shift(@$result);
	my $id = $row->{namespace_id};
	my $type = $row->{namespace_type};
	my $lsid = $row->{namespace_lsid};
	my $desc = $row->{description};
	my $auth = $row->{authority};
	my $email = $row->{contact_email};

	if ($id) {
		return ( 1, $desc, $lsid );
	} else {
		return (
			0,
"Namespace Type $term does not exist in the biomoby.org Namespace Type ontology\n",
			''
		);
	}
}

=head2 createNamespace

=cut

sub createNamespace {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobynamespace' );
	#node => $term,
	#descrioption => $desc,
	#authority => $auth,
	#contact_email => $email);
	return ( 0, "WRONG ONTOLOGY!", '' )
	  unless ( $self->ontology eq 'namespace' );
	return ( 0, "requires a namespace type node", '' ) unless ( $args{node} );
	return ( 0, "requires an authURI ", '' ) unless ( $args{authority} );
	return ( 0, "requires a contact email address", '' )
	  unless ( $args{contact_email} );
	return ( 0, "requires a object description", '' )
	  unless ( $args{description} );
	my $term = $args{node};
	if ( $term =~ /^urn:lsid/){    # if it is an LSID, barf
		return ( 0, "can't create a term from an lsid!", $term );
	}
	my $LSID = $self->setURI( $term );
	unless ($LSID) { return ( 0, "Failed during creation of an LSID", '' ) }

	my $insertid = $adaptor->insert_namespace(namespace_type => $args{'node'}, 
						namespace_lsid => $LSID,
						description => $args{'description'},
						authority => $args{'authority'},
						contact_email => $args{'contact_email'});

	unless ( $insertid ) {
		return ( 0, "Namespace creation failed for unknown reasons", '' );
	}
	return ( 1, "Namespace creation succeeded", $LSID );
}

=head2 deleteNamespace

=cut

sub deleteNamespace {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobynamespace' );
	return ( 0, "WRONG ONTOLOGY!", '' )
	  unless ( $self->ontology eq 'namespace' );
	my $term = $args{term};
	my $LSID;
	unless ( $term =~ /urn\:lsid/ ) { $LSID = $self->getNamespaceURI($term) } else { $LSID = $term }
	return ( 0, q{Namespace type $term cannot be resolved to an LSID}, "" )
	  unless $LSID;
	if ( $term =~ /^urn:lsid/
		 && !( $term =~ /^urn:lsid:biomoby.org:namespacetype/ ) )
	{
		return ( 0, "cannot delete a term from an external ontology", $term );
	}

	my $result = $adaptor->query_namespace(type => $LSID);
	my $row = shift(@$result);
	my $lsid = $row->{namespace_lsid};

	unless ($lsid) {
		return ( 0, q{Namespace type $term does not exist in the ontology},
				 $lsid );
	}

	# service1_id ISA service2_id?
	my $isa = $adaptor->query_namespace_term2term(type => $lsid);
	my $isas = shift @$isa;
	
	if ($isas->{namespace1_id} ) {
		return ( 0, qq{Namespace type $term has dependencies in the ontology},
				 $lsid );
	}

	my ($err, $errstr) = $adaptor->delete_namespace(type => $lsid);

	if ( $err ) {
		return ( 0, "Delete from namespace table failed: $errstr",
				 $lsid );
	}

	#($err, $errstr) = $adaptor->delete_namespace_term2term(namespace1_id => $lsid);
	#
	#if ( $err ) {
	#	return (
	#		 0,
	#		 "Delete from namespace term2term table failed: $errstr",
	#		 $lsid
	#	);
	#}
	return ( 1, "Namespace Type $term Deleted", $lsid );
}

=head2 retrieveAllServiceTypes

=cut

sub retrieveAllServiceTypes {
	my ($self) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyservice' );
	my $types = $adaptor->new_query_service();

	my %response;
	foreach (@$types) {
		$response{ $_->{'service_type'} } = [$_->{'description'}, $_->{'service_lsid'}, $_->{'contact_email'}, $_->{'authority'}, $_->{'parent_type'}, $_->{'parent_lsid'}]; #UNCOMMENT
	}
	return \%response;
}

=head2 retrieveAllNamespaceTypes

=cut

sub retrieveAllNamespaceTypes {
	my ($self) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobynamespace' );
	my $types = $adaptor->query_namespace();

	my %response;
	foreach (@$types) {
		$response{ $_->{namespace_type} } = [$_->{description}, $_->{namespace_lsid}, $_->{authority}, $_->{contact_email}];
	}
	return \%response;
}

=head2 retrieveAllObjectClasses

=cut

sub retrieveAllObjectClasses {
	my ($self) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );
	my $types = $adaptor->query_object();

	my %response;
	foreach (@$types) {
		$response{ $_->{object_type} } = [$_->{description}, $_->{object_lsid}];
	}
	return \%response;
}
*retrieveAllObjectTypes = \&retrieveAllObjectClasses;
*retrieveAllObjectTypes = \&retrieveAllObjectClasses;

=head2 getObjectCommonName

=cut

sub getObjectCommonName {
	my ( $self, $URI ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );
	return undef unless $URI =~ /urn\:lsid/;
	my $result = $adaptor->query_object(type => $URI);
	my $row = shift(@$result);
	my $name = $row->{object_type};

	return $name ? $name : $URI;
}

=head2 getNamespaceCommonName

=cut

sub getNamespaceCommonName {
	my ( $self, $URI ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobynamespace' );
	return undef unless $URI =~ /urn\:lsid/;
	my $result = $adaptor->query_namespace(type => $URI);
	my $row = shift(@$result);
	my $name = $row->{namespace_type};
	
	return $name ? $name : $URI;
}

=head2 getServiceCommonName

=cut

sub getServiceCommonName {
	my ( $self, $URI ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyservice' );
	return undef unless $URI =~ /urn\:lsid/;
	my $result = $adaptor->query_service(type => $URI);
	my $row = shift(@$result);
	my $name = $row->{service_type};

	return $name ? $name : $URI;
}

=head2 getServiceURI

=cut

sub getServiceURI {
	my ( $self, $term ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyservice' );
	return $term if $term =~ /urn\:lsid/;
	
	my $result = $adaptor->query_service(type => $term);
	my $row = shift(@$result);
	my $id = $row->{service_lsid};

	return $id;
}

=head2 getObjectURI

=cut

sub getObjectURI {
	my ( $self, $term ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyobject' );
	return $term if $term =~ /urn\:lsid/;

	my $result = $adaptor->query_object(type => $term);
	my $row = shift(@$result);
	my $id = $row->{object_lsid};

	return $id;
}

=head2 getNamespaceURI

=cut

sub getNamespaceURI {
	my ( $self, $term ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobynamespace' );
	
	return $term if $term =~ /urn\:lsid/;

	my $result = $adaptor->query_namespace(type => $term);
	my $row = shift(@$result);
	my $id = $row->{namespace_lsid};

	return $id;
}

=head2 getRelationshipURI

consumes ontology (object/service)
consumes relationship term as term or LSID

=cut

sub getRelationshipURI {
	my ( $self, $ontology, $term ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyrelationship' );
	
	return $term if $term =~ /urn\:lsid/;

	my $result = $adaptor->query_relationship(type => $term, ontology => $ontology);
	my $row = shift(@$result);
	my $id = $row->{relationship_lsid};

	return $id;
}

=head2 getRelationshipTypes

=cut

sub getRelationshipTypes {
	my ( $self, %args ) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobyrelationship' );
	
	my $ontology = $args{'ontology'};
	my $OS = MOBY::OntologyServer->new( ontology => "relationship" );

	my $defs = $adaptor->query_relationship(ontology => $ontology);

	my %result;
	foreach ( @$defs ) {
		$result{ $_->{relationship_lsid} } = [ $_->{relationship_type}, $_->{authority}, $_->{description} ];
	}
	return \%result;
}

=head2 RelationshipsDEPRECATED

=cut

sub RelationshipsDEPRECATED {

	# this entire subroutine assumes that there is NOT multiple parenting!!
	my ( $self, %args ) = @_;
	my $ontology     = $args{ontology} ? $args{ontology} : $self->ontology;
	my $term         = $args{term};
	my $relationship = $args{relationship};
	my $direction    = $args{direction} ? $args{direction} : 'root';
	my $expand       = $args{expand} ? 1 : 0;
	return
	  unless (    $ontology
			   && $term
			   && ( ( $ontology eq 'service' ) || ( $ontology eq 'object' ) ) );

	# convert $term into an LSID if it isn't already
	if ( $ontology eq 'service' ) {
		$term = $self->getServiceURI($term);
		$relationship ||="isa";
		my $OS = MOBY::OntologyServer->new(ontology => 'relationship');
		$relationship = $OS->getRelationshipURI("service", $relationship);
	} elsif ( $ontology eq 'object' ) {
		$term = $self->getObjectURI($term);
		$relationship ||="isa";
		my $OS = MOBY::OntologyServer->new(ontology => 'relationship');
		$relationship = $OS->getRelationshipURI("object", $relationship);
	}
	my %results;
	while (    ( $term ne 'urn:lsid:biomoby.org:objectclass:Object' )
			&& ( $term ne 'urn:lsid:biomoby.org:servicetype:Service' ) )
	{
		my $defs = $self->_doRelationshipsQuery(
							$ontology,
							$term,
							$relationship,
							$direction );
		return {[]} unless $defs; # somethig has gone terribly wrong!
		my $lsid;
		my $rel;
		my $articleName;
		foreach ( @{$defs} ) {
			$lsid = $_->[0];
			$rel  = $_->[1];
			$articleName = $_->[2];
			$articleName ||="";
			$debug
			  && _LOG("\t\tADDING RELATIONSHIP $_    :    $lsid to $rel\n");
			push @{ $results{$rel} }, [$lsid, $articleName];
		}
		last unless ($expand);
		last unless ( $direction eq "root" ); # if we aren't going to root, then be careful or we'll loop infnitely
		$term = $lsid; # this entire subroutine assumes that there is NOT multiple parenting...
	}
	return \%results;    #results(relationship} = [[lsid1,articleNmae], [lsid2, articleName], [lsid3, articleName]]
}


=head2 Relationships

=cut

sub Relationships {
  my ($self, %args) = @_;
  my %results;
  
  my $term         = $args{term};
  my $ontology     = $args{ontology} ? $args{ontology} : $self->ontology;
  my $direction    = $args{direction} ? $args{direction} : 'root';
  $direction = $direction eq 'root'? 'root' : 'leaves'; # map anything else to 'leaves'
  my $relationship  = $args{relationship};
  my $expand       = $args{expand} ? 1 : 0;
  
  # in order to make this function also usable for 'traverseDAG'
  # we need a more precise definition what to expand. Note that
  # the default settings assure the behaviour of the old 'expand' param.
  #  1. expand along the isa relationship?
  my $isaExpand    = $args{isaExpand} ? $args{isaExpand} : $expand;
  #  2. expand along the inclusion relationship types (has/hasa),
  #     i.e. get inclusions of inclusions?
  #     (Note: this is set when called by 'traverseDAG')
  my $incExpand   = $args{incExpand} ? $args{incExpand} : 0;
  #  3. explore inclusion relationships for complete isa hierarchy?
  #     (Note: this was fix behaviour of the old 'expand',
  #      but is not used by traverseDAG)
  my $mapIncToIsa = $args{mapIncToIsa} ? $args{mapIncToIsa} : $expand;

  # first of all, get ID of query entity,
  # internally, we will operate on pure IDs
  # as long as possible...
  $CONFIG ||= MOBY::Config->new;     # exported by Config.pm
  my $datasource = "moby$ontology";  # like mobyobject, or mobyservice
  my $adaptor = $CONFIG->getDataAdaptor( datasource => $datasource );
  my $queryId;
  my $query_method = "query_$ontology";
  my $result = $adaptor->$query_method(type => $term);
  my $row = shift @$result;
  $queryId = $row->{"${ontology}_id"};

  return {} unless $queryId;

  # get all relationships in the database in one query
  my $relHash = $adaptor->get_all_relationships(direction=>$direction,ontology=>$ontology);

  # find out which relationships to return
  # use keys of %$relHash, because these are lsids:

  # initialize to return all relationships (becomes effective if eg. 'all' was used)
  my @relList = keys %$relHash;
  if ( (not $relationship) or # ISA (and nothing else) is the default if nothing specified
       ($relationship =~ /isa$/i) ) {
    @relList = grep { /isa$/i } @relList;
  }
  elsif ( $relationship =~ /has(a)?$/i ) {
    # if either has or hasa was specified, use only that
    @relList = grep { /$relationship$/i } @relList;
  }

  # build the isa hierarchy, it's needed in any case...
  my ($isaLsid) = grep { /isa$/i } keys %$relHash; # we need the lsid...
  my $isa_hierarchy = $self->_getIsaHierarchy($relHash->{$isaLsid}, $queryId, $direction, $isaExpand);

  # prepare the hash for storing HAS/HASA relationship details
  my $hasRelDetails;

  # table fields needed to get entity details:
  my @fields = ("${ontology}_lsid","${ontology}_type");

  # nodes to check for has/hasa relationship
  my @checkNodes = ($queryId);
  # mapIncToIsa means that has/hasa has to be checked
  # not only for the query object alone but also for all
  # isa ancestors/descendants
  push @checkNodes, @$isa_hierarchy if $mapIncToIsa;
  
  # the result hash will consist of one list for each included relationship type...
  foreach my $rel ( @relList ) {
    my @entityQueryList = ();  # this collects the unique object ids
    my @entityResultList = (); # this collects ids of objects to add to the result, maybe not unique
    # the latter one is not essential to have, the only benefit is
    # a somehow predictable order in the output...

    # find out which entities we have to include in the result
    # and how these are related to each other;
    # Note: all needed information is present in the relationship hash %$relHash!

    if ( $rel ne $isaLsid ) {
      # either HAS or HASA
      foreach my $node ( @checkNodes ) {
	my $incls = $self->_getInclusions($relHash,$node,[$rel], $incExpand);
	foreach my $triplet ( @$incls ) {
	  my ($inclId, $inclArtName, $inclAssert) = @$triplet;
	  $hasRelDetails->{$inclId}->{$inclAssert} = $inclArtName;  # can be more than one articleName for each included Object
	  push @entityResultList, $inclId;
	}
      }
	# we have the following structure now for the HAS and HASA...
	#       DB<35> x $hasRelDetails
	#	0  HASH(0x95cd1bc)
	#	5371 => HASH(0x95f7fd8)   # object type
	#	10795 => 'Tiny'		  # related to parent by $ rel relationship 
	#	10796 => 'Small'
	#	10797 => 'Aliphatic'
	#	10798 => 'Aromatic'
	#	10799 => 'Non-polar'
	#	10800 => 'Polar'
	#	10801 => 'Charged'
	#	10802 => 'Positive'
	#	10803 => 'Negative'
	#	10804 => 'Hydropathy_KD'
	#	10805 => 'Hydropathy_OHM'
	#	10806 => 'Consensus'

      # set up list of unique object ids for the database lookup
      @entityQueryList = keys %$hasRelDetails;
    }
    else {
      # ISA
      @entityQueryList = @$isa_hierarchy;  # isa hierarchy is guaranteed to be unique...
      @entityResultList = @$isa_hierarchy; # ... but still both variables have to be set
    }
    
    # now it's time to move away from pure ids, retrieve details from database:
    my $details = $adaptor->get_details_for_id_list($ontology, \@fields, \@entityQueryList);
    my $newstructure;
    # enhance details with information about relationships and build result hash
    foreach my $entityId (@entityResultList) {
      # add articleName slot if necessary
      next if $details->{$entityId}->{'articleName'};  # we've already processed this one
      if ( exists $hasRelDetails->{$entityId} ) {  # the only things that have RelDetails are HASA/HAS EntityIDs
	foreach my $assert ( keys %{$hasRelDetails->{$entityId}} ) {
	  # THIS DATA STRUCTURE IS WRONG - IT ASSUMES ONE ARTICLE NAME FOR EACH CONTAINED OBJECT TYPE
	  # NEEDS TO BE REVERSED!
	  my $articleName = $hasRelDetails->{$entityId}->{$assert};
	  my $objectTypeLSID = $details->{entityId}->{object_lsid};
	  $details->{$entityId}->{'articleName'}->{$articleName} = "Related_by";  # I know, this is a very goofy data structure.  What we really
				# want are keys $details->{entitId}->{articleName}
				# so taht we can see how often that object is included
				# by a has or hasa relationship
	}
      }
      elsif ( $ontology eq 'object') {  # if it doesn't have a RelDetail, and it is the object ontology we are querying, then its an ISA
	# for isa, articleName is the empty string
	$details->{$entityId}->{'articleName'} = '';
      }

      # map ontology specific field names to commons slots:
      # 1. 'object_lsid'/'service_lsid' -> 'lsid'
      $details->{$entityId}->{'lsid'} = $details->{$entityId}->{"${ontology}_lsid"} 
	unless exists $details->{$entityId}->{'lsid'}; # do just once foreach object!
      delete $details->{$entityId}->{"${ontology}_lsid"}; # remove redundant slot
      # 2. 'object_type'/'service_type' -> 'term'
      $details->{$entityId}->{'term'} = $details->{$entityId}->{"${ontology}_type"}
	unless exists $details->{$entityId}->{'term'}; # do just once foreach object!
      delete $details->{$entityId}->{"${ontology}_type"}; # remove redundant slot

      # finally, add record to the result hash
      push @{ $results{$rel} }, $details->{$entityId};
    }
  }
  return \%results;
}

sub _getIsaHierarchy {
  # Finds out the isa hierarchy for the query entity, that is
  # the parent (the one which it inherits from) if direction is 'root' or
  # the children (one or more which inherit from it) if direction is 'leaves'.
  # If 'expand' is set all deeper levels (ancestors or descendants if you like)
  # are also included.
  # Note 1: this implementation relies on pure single inheritance!
  # Note 2: we can use the same method for both directions only because the
  #         provided isaHash is built with the direction in mind, make sure
  #         to have direction consistent!

  # returned is a reference to a flat list
  
  my ($self, $isaHash, $query, $direction, $expand) = @_;

  my @hierarchy = ();
  if ( exists $isaHash->{$query} ) {
    if ( $direction eq 'root' ) {
      # push the parent entity
      push @hierarchy, $isaHash->{$query}; # relies on single inheritance!
    }
    elsif ( $direction eq 'leaves' ) {
      # push the direct children
      push @hierarchy, @{$isaHash->{$query}};
    }
    else {
      # it has to be either 'root' or 'leaves'
      warn "_getIsaHierarchy was called with wrong direction indicator,
            use either 'root' or 'leaves'!\n";
      return [];
    }
    if ( $expand ) {
      my @firstLevel = @hierarchy;
      foreach my $entity ( @firstLevel ) {
	my $deeperLevels = $self->_getIsaHierarchy($isaHash, $entity, $direction, 1);
	push @hierarchy, @$deeperLevels;
      }
    }
    return \@hierarchy;
  }
  else {
    # important: anchor the recursion!
    return [];
  }
}

sub _getInclusions {

  # Finds out the objects related to the query by one of the inclusion
  # relationships (HAS or HASA). This is the HAS/HASA-analogue to
  # _getIsaHierarchy, but is more complicated, because the values in
  # the provided relationship hash ($relHash) are not simple ids but
  # triplets ("relationship records") in the format of:
  # [id of relationship partner, articleName, assertion id]
  # On the other hand, direction does not matter here, because
  # we have to deal with multi relationships in any case.
  # Like for ISA, be aware that the relationship hash '$relHash'
  # is built direction dependant. Make sure to use it consistently!

  # Note: third argument is a listref of relationship types, that is
  # it could be called with HAS and HASA (expected are lsids) at
  # the same time and in this way merge both inclusion relationship
  # types. However, this usage is not used currently and not tested!
  
  # Returned is a reference to a list with each element being
  # a triplet (listref to a relationship record) as explained above.
  
  my ($self, $relHash, $query, $relList, $expand) = @_;

  my %nodeCheckDone; # for avoiding multiple check of one node (if expand is set)
  my @allInclusions = ();
  foreach my $relType ( @$relList ) {
    # 'root' means: include all relationships where query is the
    # containing (outer) object;
    # eg. if A HAS B, and A is query, include this record
    if ( exists $relHash->{$relType}->{$query} ) {
      my $relRecords = $relHash->{$relType}->{$query};
      foreach my $record ( @$relRecords ) {
	push @allInclusions, $record;
	if ( $expand ) {
	  my ($incId, $artName, $assert) = @$record;
	  if ( not exists $nodeCheckDone{$incId} ) {
	    my $deeperInclusions = $self->_getInclusions($relHash, $incId, $relList, 1);
	    push @allInclusions, @$deeperInclusions;
	    $nodeCheckDone{$incId}++;
	  }
	}
      }
    }
  }
  return \@allInclusions; # empty if nothing found, this anchors the recursion
}

=head2 setURI

=cut

sub setURI {
	my ( $self, $id ) = @_;
	my $URI;

my ($sec,$min,$hour,$mday,$month,$year, $wday,$yday,$dst) =gmtime(time);
my $date = sprintf ("%04d-%02d-%02dT%02d-%02d-%02dZ",$year+1900,$month+1,$mday,$hour,$min,$sec);

	# $id = lc($id);
	if ( $self->ontology eq 'object' ) {
		$URI = "urn:lsid:biomoby.org:objectclass:$id:$date";
	} elsif ( $self->ontology eq 'namespace' ) {
		$URI = "urn:lsid:biomoby.org:namespacetype:$id:$date";
	} elsif ( $self->ontology eq 'service' ) {
		$URI = "urn:lsid:biomoby.org:servicetype:$id:$date";
	} elsif ( $self->ontology eq 'relationship' ) {
		$URI = "urn:lsid:biomoby.org:relationshiptype:$id";  # dont' add version info here
	} else {
		$URI = 0;
	}
	return $URI;
}

=head2 traverseDAG

=cut

sub traverseDAG {
  my ( $self, $term, $direction ) = @_;
  my $ontology = $self->ontology;
  return {} unless $ontology;
  return {} unless $term;
  $direction = "root" unless ($direction);
  return {} unless ( ( $direction eq 'root' ) || ( $direction eq 'leaves' ) );
  if ( $ontology eq 'service' ) {
    $term = $self->getServiceURI($term);
  } elsif ( $ontology eq 'object' ) {
    $term = $self->getObjectURI($term);
  }
  return {} unless $term; # search term not in db!
  return {} unless $term =~ /^urn\:lsid/;    # now its a URI

  my $result = {};
  # get the types of relationships for the object/service ontology
  my $relTypeHash = $self->getRelationshipTypes( ontology => $ontology );
  my $relHash = $self->Relationships( term => $term,
				  direction => $direction,
				  ontology => $ontology,
				  isaExpand => 1,
				  incExpand => 1,
				  mapIncToIsa => 0,
				  relationship => 'all');
  foreach my $relType ( keys %$relTypeHash ) {
    $result->{$relType} = [];
    my %tmpHash; # avoid doubles!
    my $relList = $relHash->{$relType};
    foreach my $rel ( @$relList ) {
      $tmpHash{$rel->{'lsid'}}++;
    }
    @{$result->{$relType}} = keys %tmpHash;
  }
  return $result;
}

sub _LOG {
	return unless $debug;

	#print join "\n", @_;
	#print  "\n---\n";
	#return;
	open LOG, ">>/tmp/OntologyServer.txt" or die "can't open logfile $!\n";
	print LOG join "\n", @_;
	print LOG "\n---\n";
	close LOG;
}
sub DESTROY { }

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
1;
