#-----------------------------------------------------------------
# MOSES::MOBY::Cache::Central
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Central.pm,v 1.9 2009/10/09 17:29:28 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Cache::Central;

use MOSES::MOBY::Base;
use base qw( MOSES::MOBY::Base );
use MOSES::MOBY::Cache::Registries;
use MOSES::MOBY::Def::DataType;
use MOSES::MOBY::Def::Service;
use MOSES::MOBY::Def::Data;
use MOSES::MOBY::Def::Namespace;
use MOSES::MOBY::Def::Relationship;
use SOAP::Lite;
use XML::LibXML;
use File::Spec;
use strict;
use vars qw ($DEFAULT_REGISTRY_URL $VERSION);

# names of cache directories/files
use constant LIST_FILE          => '__L__I__S__T__';
use constant DATATYPES_CACHE    => 'dataTypes';
use constant SERVICES_CACHE     => 'services';
use constant NAMESPACES_CACHE   => 'namespaces';
use constant SERVICETYPES_CACHE => 'serviceTypes';

# the version of this file:
$VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Cache::Central - access to locally cached Moby entities

=cut

=head1 SYNOPSIS

 use MOSES::MOBY::Cache::Central;

 # create an aceess to a Moby registry cache
 # (use 'registry' only for non-default registries)
 my $cache = new MOSES::MOBY::Cache::Central
    ( cachedir =>'/usr/local/cache/',
     );

 my $cache = new MOSES::MOBY::Cache::Central
    ( cachedir =>'/usr/local/cache/',
      registry => 'IRRI'
    );

 # get the location of the cache and the URL of a registry (whose
 # cache we are accessing)
 print $cache->cachedir;
 print $cache->registry();

 # create a cache for datatypes and fill it up
 $cache->create_datatype_cache;
 
 #update the datatype cache
 $cache->update_datatype_cache;
 
 # create a cache for services and fill it up
 $cache->create_service_cache;
 
 #update the services cache
 $cache->update_service_cache;
 
 # get a data type called DNASequence
 my $dna = $cache->get_datatype ('DNASequence');
	
 # get all datatypes from cache
 my @dts = $cache->get_datatypes;

 # get all services provided by the given authority
 my @services = $cache->get_service ('bioinfo.inibap.org');

 # get some services provided by the given authority
 my @services = $cache->get_service
    ('bioinfo.inibap.org',
     qw( Get_TropGENE_Distance_Matrix Get_TropGENE_Nj_Tree ));

 # get all authorities and service names
 require Data::Dumper;
 my %all = $cache->get_service_names;
 print Data::Dumper->Dump ( [ \%all ], ['By_authorities']);

=cut

=head1 DESCRIPTION

Access to a cached Moby entities, such as data types and service
definitions. It does not create a cache, just reads it.

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<cachedir>

A mandatory parameter containing a name of a local directory where is
a Moby cache. The Moby cache directory can contain more caches (from
more Moby registries). The location points to the top-level directory
name. For example, if we have the following directory structure
(containing caches from four different Moby registries):

   /work/moby-live/Java/myCache/
      http58.47.47bioinfo46icapture46ubc46ca47cgi45bin47mobycentral47MOBY45Central46pl/
         dataTypes/
         namespaces/
         services/
         serviceTypes/
      http58.47.47cropwiki46irri46org47cgi45bin47MOBY45Central46pl/
         ...
      http58.47.47mips46gsf46de47cgi45bin47proj47planet47moby47MOBY45Central46pl/
         ...
      http58.47.47mobycentral46icapture46ubc46ca47cgi45bin47MOBY0547mobycentral46pl/
         ...

Then, the location should be C</work/moby-live/Java/myCache>.

=item B<registry>

A URL of a moby registry whose cache you are going to access. Or an
abbreviation (a synonym) of a BioMoby registry. See more about
synonyms in L<MOSES::MOBY::Cache::Registries>.

For a default registry, use string 'default' (but there is no need to
do so: default is default by default).

=item B<registries>

An object of type MOSES::MOBY::Cache::Registries that you can manipulate to add 
more registries. See more about this object in L<MOSES::MOBY::Cache::Registries>.

=back

=cut

{
    my %_allowed =
	(
	 cachedir  => undef,
	 registries=> new MOSES::MOBY::Cache::Registries,
	 registry  => { type => MOSES::MOBY::Base->STRING,
			post => \&_check_registry },
	 # undocumented, for internal use only (so far)
	 datatypes => {type => 'MOSES::MOBY::Def::DataType', is_array => 1},
#	 services  => {type => 'MOSES::MOBY::Def::Service',  is_array => 1},
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

sub _check_registry {
    my $self = shift;
    $self->{registry} = $self->{registry} || $MOBYCFG::REGISTRY || 'default';
}


#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# _endpoint
#    Return an endpoint of the $self->registry, or of a given
#    registry.
#-----------------------------------------------------------------
sub _endpoint {
    my ($self, $registry) = @_;
    $registry ||= $self->registry;
    return $registry if $registry =~ m"^http://";
    my $reg = $self->registries->get ($registry);
    return $reg->{endpoint} if $reg;
    return $self->registries->get ('default')->{endpoint};
}

#-----------------------------------------------------------------
# _namespace
#    Return a namespace of the $self->registry, or of a given
#    registry.
#-----------------------------------------------------------------
sub _namespace {
    my ($self, $registry) = @_;
    $registry ||= $self->registry;
    return "http://localhost/MOBY/Central" if $registry =~ m"^http://";
    my $reg = $self->registries->get ($registry);
    return $reg->{namespace} if $reg;
    return $self->registries->get ('default')->{namespace};
}


#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->registry ($MOBYCFG::REGISTRY || 'default');
    $self->cachedir ($MOBYCFG::CACHEDIR);
	$self->registries( new MOSES::MOBY::Cache::Registries);
    $self->datatypes ([]);
#    $self->services ([]);
}

#-----------------------------------------------------------------
# get_datatypes
#-----------------------------------------------------------------

=head2 get_datatypes

Return a reference to an array of C<MOSES::MOBY::Def::DataType> objects. They
were generated from the local Moby cache. All data types found in the
cache are returned.

No arguments (at least, so far).

=cut

sub get_datatypes {
    my $self = shift;

    # get all available names
    my @names =	$self->get_datatype_names;
    foreach my $name (@names) {
#	$self->add_datatypes ($self->get_datatype ($name);
	push @{ $self->{datatypes} }, $self->get_datatype ($name);
    }
    return $self->datatypes ? $self->datatypes : [];
}

#-----------------------------------------------------------------
# get_datatype
#-----------------------------------------------------------------

=head2 get_datatype

Return a Moby data type definition (type MOSES::MOBY::Def::DataType), as
obtained from a local cache. The argument is a name of a data type
that will be returned.

Throw an exception if such named data type does not exist in the local
cache.

=cut

sub get_datatype {
    my ($self, $datatype_name) = @_;
    $self->throw ("No data type given.")
	unless $datatype_name;
    my $file = File::Spec->catfile ($self->cachedir,
				    $self->_clean ($self->_endpoint),
				    DATATYPES_CACHE,
				    $datatype_name);
    my $xml = '';
    local $/ = undef;
    open (FILE, "<$file")
	or $self->throw ("Can't open file $file for reading: $!");
    $xml = <FILE>;
    close FILE;
    
    return $self->_createDataTypeFromXML ($xml);
}

#-----------------------------------------------------------------
# create_datatype_cache
#-----------------------------------------------------------------

=head2 create_datatype_cache

Create the datatype cache. This will over write any pre-existing 
cache that it finds.

Throw an exception if any of the following occur:
    * There is a SOAP error calling the registry
    * There were write errors on the cache directory or its contents

=cut

sub create_datatype_cache {
    my ($self) = @_;	
    
    # 2 steps:
    # -> create a LIST file
    my $soap = 
    	SOAP::Lite->uri($self->_namespace)
		  ->proxy( $self->_endpoint )->on_fault(
				sub {
					my $soap = shift;
					my $res  = shift;
					$self->throw ("There was a problem calling the registry: " . $self->_endpoint . "\@ " . $self->_namespace . ".\n" . $res);	
				}
			  );

	my $xml   =
			  $soap->retrieveObjectNames( )->result;
    # create cache dirs as needed
    $self->create_cache_dirs;    
    my $file = File::Spec->catfile ($self->cachedir,
				    $self->_clean ($self->_endpoint),
				    DATATYPES_CACHE,
				    LIST_FILE);
    open (FILE, ">$file")
	or $self->throw ("Can't open file '$file' for writing: $!");
    print FILE $xml;
    close FILE;
    
    $LOG->debug("Saving the '". LIST_FILE . "' file.");
    
    # 2-> foreach datatype store 'retrieveObjectDefinition'
    my $parser       = XML::LibXML->new();
    my $doc          = $parser->parse_string($xml);
    
    my $nodes = $doc->documentElement()->getChildrenByTagName('Object');
    for (1 .. $nodes->size()) {
    	my $name =  $nodes->get_node($_ )->getAttribute('name');
    	my $input =<<END;
<retrieveObjectDefinition>
           <objectType>$name</objectType>
</retrieveObjectDefinition>
END
		$LOG->debug("Processing the datatype, '$name'.");
		$xml   =
			  $soap->retrieveObjectDefinition ( SOAP::Data->type('string' => "$input") )->result;
		$file = File::Spec->catfile ($self->cachedir,
				    $self->_clean ($self->_endpoint),
				    DATATYPES_CACHE,
				    $name);
    	open (FILE, ">$file") or $self->throw ("Can't open file '$file' for writing: $!");
    	print FILE $xml;
    	close FILE;
    }
    
}

#-----------------------------------------------------------------
# update_datatype_cache
#-----------------------------------------------------------------

=head2 update_datatype_cache

Update the datatype cache. This will update any items that are 'old',
by relying on the LSID for the datatype.

Throw an exception if any of the following occur:
    * A cache to update doesn't exist
    * There is a SOAP error calling the registry
    * There were read/write errors on the cache directory or its contents

=cut

sub update_datatype_cache {
    my ($self) = @_;	
    
    my %old_datatypes = ();
    my %new_datatypes = ();
    my @changed_datatypes = ();
   
   if (!(-e File::Spec->catfile (
   					$self->cachedir,
				    $self->_clean ($self->_endpoint),
				    DATATYPES_CACHE))) {
		$self->throw("Datatype cache doesn't exist, so I can't update it. Please create a datatype cache first!");
	}
   if (!(-e File::Spec->catfile (
   					$self->cachedir,
				    $self->_clean ($self->_endpoint),
				    DATATYPES_CACHE,
				    LIST_FILE))) {
		$self->throw("Datatypes LIST_FILE doesn't exist, so I can't update the cache. Please create a datatype cache first!");
	}
    # steps:
    # read in the LIST file and extract lsids for all datatypes
    $LOG->debug("Reading the cached '" . LIST_FILE ."'.");
    my $file = File::Spec->catfile ($self->cachedir,
				    $self->_clean ($self->_endpoint),
				    DATATYPES_CACHE,
				    LIST_FILE);
	my $parser       = XML::LibXML->new();
    my $doc          = $parser->parse_file($file);
    my $nodes = $doc->documentElement()->getChildrenByTagName('Object');
    for (1 .. $nodes->size()) {
    	my $name =  $nodes->get_node($_ )->getAttribute('name');
    	my $lsid = $nodes->get_node($_ )->getAttribute('lsid');
    	$old_datatypes{$name} = $lsid;
    }
    $LOG->debug("Retrieving an up to date '". LIST_FILE ."'.");
    # get the new LIST file and extract lsids for all datatypes
    my $soap = 
    	SOAP::Lite->uri($self->_namespace)
		  ->proxy( $self->_endpoint )->on_fault(
				sub {
					my $soap = shift;
					my $res  = shift;
					$self->throw ("There was a problem calling the registry: " . $self->_endpoint . "\@ " . $self->_namespace . ".\n" . $res);	
				}
			  );

	my $xml   = $soap->retrieveObjectNames( )->result;
	$parser       = XML::LibXML->new();
    $doc          = $parser->parse_string($xml);
    $nodes = $doc->documentElement()->getChildrenByTagName('Object');
    for (1 .. $nodes->size()) {
    	my $name =  $nodes->get_node($_ )->getAttribute('name');
    	my $lsid = $nodes->get_node($_ )->getAttribute('lsid');
    	$new_datatypes{$name} = $lsid;
    }    
    # go through the keys of the new one and if the keys doesnt exist or has been modified, add to 'download' queue
    foreach my $dt (keys %new_datatypes) {
    	next unless !$old_datatypes{$dt} or $old_datatypes{$dt} ne $new_datatypes{$dt}; 
   		push @changed_datatypes, $dt;
   		$LOG->debug("The datatype, '$dt', seems to have been modified.");
    }
    
    # if their where changes, save new LIST file over the old one and get changes
    if (scalar @changed_datatypes) {
    	# save new LIST file
    	open (FILE, ">$file")
			or $self->throw ("Can't open file '$file' for writing: $!");
    	print FILE $xml;
    	close FILE;
    	# clear used values
    	$xml = undef;
    	$file = undef;
    	$parser = undef;
    	$doc = undef;
    	$nodes = undef;
    	foreach my $name (@changed_datatypes) {
    		print "Found modified datatype, '$name', updating ...\n";
    		my $input =<<END;
<retrieveObjectDefinition>
           <objectType>$name</objectType>
</retrieveObjectDefinition>
END

			$LOG->debug("Updating the datatype, '$name'.");
			$xml   =
				  $soap->retrieveObjectDefinition ( SOAP::Data->type('string' => "$input") )->result;
			$file = File::Spec->catfile ($self->cachedir,
				    	$self->_clean ($self->_endpoint),
				    	DATATYPES_CACHE,
				    	$name);
    		open (FILE, ">$file") or $self->throw ("Can't open file '$file' for writing: $!");
    		print FILE $xml;
    		close FILE;
    	}
    }
}

#-----------------------------------------------------------------
# create_service_cache
#-----------------------------------------------------------------

=head2 create_service_cache

Create the service cache. This will over write any pre-existing 
cache that it finds.

Throw an exception if any of the following occurs:
    * A SOAP error as a result of calling the registry
    * Problems writing to the cache directory

=cut

sub create_service_cache {
    my ($self) = @_;	
    
    # 2 steps:
    # -> create a LIST file
    my $soap = 
    	SOAP::Lite->uri($self->_namespace)
		  ->proxy( $self->_endpoint )->on_fault(
				sub {
					my $soap = shift;
					my $res  = shift;
					$self->throw ("There was a problem calling the registry: " . $self->_endpoint . "\@ " . $self->_namespace . ".\n" . $res);	
				}
			  );

	my $xml   =
			  $soap->retrieveServiceNames( )->result;
    # create cache dirs as needed
    $self->create_cache_dirs;
    my $file = File::Spec->catfile ($self->cachedir,
				    $self->_clean ($self->_endpoint),
				    SERVICES_CACHE,
				    LIST_FILE);
    open (FILE, ">$file")
	or $self->throw ("Can't open file '$file' for writing: $!");
    print FILE $xml;
    close FILE;
 
    # 2-> foreach datatype store 'findService' on the authority
    my $parser       = XML::LibXML->new();
    my $doc          = $parser->parse_string($xml);
    my %authorities_completed = ();
    my $nodes = $doc->documentElement()->getChildrenByTagName('serviceName');
    for (1 .. $nodes->size()) {
    	my $name =  $nodes->get_node($_ )->getAttribute('authURI');
    	next if $authorities_completed{$name};
    	$authorities_completed{$name} = 1;
    	my $input =<<END;
<findService>
           <authURI>$name</authURI>
</findService>
END
		$xml   =
			  $soap->findService ( SOAP::Data->type('string' => "$input") )->result;
		$file = File::Spec->catfile ($self->cachedir,
				    $self->_clean ($self->_endpoint),
				    SERVICES_CACHE,
				    $name);
    	open (FILE, ">$file") or $self->throw ("Can't open file '$file' for writing: $!");
    	print FILE $xml;
    	close FILE;
    }
    
}

#-----------------------------------------------------------------
# update_service_cache
#-----------------------------------------------------------------

=head2 update_service_cache

Update the services cache. This will update any items that are 'old',
by relying on the LSID for the datatype.

Throw an exception if any of the following occur:
	* A cache to update doesn't exist
	* There is a SOAP error calling the registry
	* There were read/write errors on the cache directory or its contents

=cut

sub update_service_cache {
    my ($self) = @_;	
    
    my %old_services = ();
    my %new_services = ();
    my %changed_services = ();
   
   if (!(-e File::Spec->catfile (
   					$self->cachedir,
				    $self->_clean ($self->_endpoint),
				    SERVICES_CACHE))) {
		$self->throw("Services cache doesn't exist, so I can't update it. Please create a services cache first!");
	}
	
	if (!(-e File::Spec->catfile (
   					$self->cachedir,
				    $self->_clean ($self->_endpoint),
				    SERVICES_CACHE,
				    LIST_FILE))) {
		$self->throw("Services LIST_FILE doesn't exist, so I can't update the cache. Please create a services cache first!");
	}
   
    # steps:
    # read in the LIST file and extract lsids for all datatypes
    my $file = File::Spec->catfile ($self->cachedir,
				    $self->_clean ($self->_endpoint),
				    SERVICES_CACHE,
				    LIST_FILE);
	my $parser       = XML::LibXML->new();
    my $doc          = $parser->parse_file($file);
    my $nodes = $doc->documentElement()->getChildrenByTagName('serviceName');
    for (1 .. $nodes->size()) {
    	my $name =  $nodes->get_node($_ )->getAttribute('authURI');
    	my $lsid = $nodes->get_node($_ )->getAttribute('lsid');
    	$old_services{$name}{$lsid} = 1;
    }
    # get the new LIST file and extract lsids for all datatypes
    my $soap = 
    	SOAP::Lite->uri($self->_namespace)
		  ->proxy( $self->_endpoint )->on_fault(
				sub {
					my $soap = shift;
					my $res  = shift;
					$self->throw ("There was a problem calling the registry: " . $self->_endpoint . "\@ " . $self->_namespace . ".\n" . $res);	
				}
			  );

	my $xml   = $soap->retrieveServiceNames( )->result;
	$parser       = XML::LibXML->new();
    $doc          = $parser->parse_string($xml);
    $nodes = $doc->documentElement()->getChildrenByTagName('serviceName');
    for (1 .. $nodes->size()) {
    	my $name =  $nodes->get_node($_ )->getAttribute('authURI');
    	my $lsid = $nodes->get_node($_ )->getAttribute('lsid');
    	$new_services{$name}{$lsid} = 1;
    }
    # go through the keys of the new one and if the keys doesnt exist or has been modified, add to 'download' queue
    foreach my $auth (keys %new_services) {
    	next if $changed_services{$auth};
    	foreach my $lsid (keys %{$new_services{$auth}})  {
    		next unless !$old_services{$auth}{$lsid};
    		$changed_services{$auth} = 1;
    	}
   		
    }

    # if their where changes, save new LIST file over the old one and get changes
    if (keys %changed_services) {
    	# save new LIST file
    	open (FILE, ">$file")
			or $self->throw ("Can't open file '$file' for writing: $!");
    	print FILE $xml;
    	close FILE;
    	# clear used values
    	$xml = undef;
    	$file = undef;
    	$parser = undef;
    	$doc = undef;
    	$nodes = undef;
    	foreach my $authURI (keys %changed_services) {
    		my $input =<<END;
<findService>
           <authURI>$authURI</authURI>
</findService>
END
			$xml   =
				  $soap->findService ( SOAP::Data->type('string' => "$input") )->result;
			$file = File::Spec->catfile ($self->cachedir,
				    	$self->_clean ($self->_endpoint),
				    	SERVICES_CACHE,
				    	$authURI);
    		open (FILE, ">$file") or $self->throw ("Can't open file '$file' for writing: $!");
    		print FILE $xml;
    		close FILE;
    	}
    }
}

#-----------------------------------------------------------------
# _createDataTypeFromXML
#    given xmlString, build a MOSES::MOBY::Def::DataType
#-----------------------------------------------------------------
sub _createDataTypeFromXML {
    my ($self, $xml) = @_;
    my $parser       = XML::LibXML->new();
    my $doc          = $parser->parse_string($xml);
    
    #print $doc->toString(1) ."\n";
    my $datatype = MOSES::MOBY::Def::DataType->new();
    
    my $nodes = $doc->documentElement()->getChildrenByTagName('objectType');
    
    # nodes should contain 1 element
    my $lsid = $nodes->get_node(1)->getAttribute('lsid')
	if (     $nodes
		 and $nodes->get_node(1)
		 and $nodes->get_node(1)->getAttribute('lsid') );
    $datatype->lsid($lsid);
    my $datatypeName = $nodes->get_node(1)->textContent
	if (     $nodes
		 and $nodes->get_node(1)
		 and $nodes->get_node(1) );
    $datatype->name($datatypeName);
    
    $nodes = $doc->documentElement()->getChildrenByTagName('Description');
    my $desc = $nodes->get_node(1)->textContent
	if ( $nodes and $nodes->get_node(1) );
    $datatype->description($desc);
    
    $nodes = $doc->documentElement()->getChildrenByTagName('authURI');
    my $auth = $nodes->get_node(1)->textContent
	if ( $nodes and $nodes->get_node(1) );
    $datatype->authority($auth);
    
    $nodes = $doc->documentElement()->getChildrenByTagName('contactEmail');
    my $email = $nodes->get_node(1)->textContent
	if ( $nodes and $nodes->get_node(1) );
    $datatype->email($email);
    
    # extract relationships :-> an array of up to 3 nodes
    $nodes = $doc->documentElement()->getChildrenByTagName('Relationship');
    my $count = $nodes->size();
    while ( $count > 0 ) {
	my $node         = $nodes->get_node( $count-- );
	my $relationship = $node->getAttribute('relationshipType');
	if ( $relationship =~ /^.*isa$/i ) {
	    my $parent = $node->getChildrenByTagName('objectType');
	    my $isa    = $parent->get_node(1)->textContent
		if ( $parent and $parent->get_node(1) and $parent->get_node(1) );
	    $datatype->parent($isa);
	}
	elsif ( $relationship =~ /^.*hasa$/i ) {
	    my $pNode = $node->getChildrenByTagName('objectType');
	    for ( my $i = 1 ; $i <= $pNode->size() ; $i++ ) {
		my $article = $pNode->get_node($i)->getAttribute('articleName')
		    if (     $pNode
			     and $pNode->get_node(1)
			     and $pNode->get_node($i)->getAttribute('articleName') );
		my $dt = $pNode->get_node($i)->textContent
		    if (     $pNode
			     and $pNode->get_node($i)
			     and $pNode->get_node($i) );
		push(
		     @{ $datatype->children },
		     new MOSES::MOBY::Def::Relationship(
						 memberName   => $article || 'MISSING_MEMBER_NAME',
						 datatype     => $dt,
						 relationship => HASA
						 )
		     );
	    }
	}
	elsif ( $relationship =~ /^.*has$/i ) {
	    my $pNode = $node->getChildrenByTagName('objectType');
	    for ( my $i = 1 ; $i <= $pNode->size() ; $i++ ) {
		my $article = $pNode->get_node($i)->getAttribute('articleName')
		    if (     $pNode
			     and $pNode->get_node($i)
			     and $pNode->get_node($i)->getAttribute('articleName') );
		my $dt = $pNode->get_node($i)->textContent
		    if ( $pNode and $pNode->get_node(1) and $pNode->get_node(1) );
		push(
		     @{ $datatype->children },
		     new MOSES::MOBY::Def::Relationship(
						 memberName   => $article || 'MISSING_MEMBER_NAME',
						 datatype     => $dt,
						 relationship => HAS
						 )
		     );
	    }
	}
    }
    
    return $datatype;

    #print $datatype->toString();
}

#-----------------------------------------------------------------
# get_datatype_names
#-----------------------------------------------------------------

=head2 get_datatype_names

Return an array of data type names obtained from the cache. The cache
is defined by the C<cachedir> (and optionally by the C<registry>)
parameters given in the constructor of this instance.

=cut

sub get_datatype_names {
    my $self = shift;

    my $pathToList = File::Spec->catfile ($self->cachedir,
					  $self->_clean ($self->_endpoint),
					  DATATYPES_CACHE);
    my @names = ();
    my $parser = XML::LibXML->new();

    my $doc = $parser->parse_file ( File::Spec->catfile ($pathToList, LIST_FILE) );
    
    my $nodes = $doc->documentElement()->getChildrenByTagName ('Object');
    for ( my $i = 1 ; $i <= $nodes->size() ; $i++ ) {
	my $node = $nodes->get_node($i);
	next unless $node->getAttribute ('name');
	push (@names, $node->getAttribute ('name'));
    }
    return @names;
}

#-----------------------------------------------------------------
# _clean
#   Returns a string that has all of the non-digits and letters
#   converted to a numerical ASCII representation. Used for creating a
#   directory name from the registry URL.
#-----------------------------------------------------------------
sub _clean {
    my $self                  = shift;
    my $lastOneWasDigitalized = 0;
    
    if (@_) {
	my $toBeCleaned = shift;
	my $string      = '';
	my @array       = split( //, $toBeCleaned );
	foreach my $char (@array) {
	    if ( not $char =~ /[a-zA-z0-9]/ ) {
		$string = $string
		    . ( ( $lastOneWasDigitalized == 1 ? "." : "" ) . ord($char) );
		$lastOneWasDigitalized = 1;
	    }
	    else {
		$lastOneWasDigitalized = 0;
		$string                = $string . "$char";
	    }
	}
	return $string;
    }
    return '';
}

#-----------------------------------------------------------------
# get_related_types
#-----------------------------------------------------------------

=head2 get_related_types

Return a reference to an array of C<MOSES::MOBY::Def::DataType> objects (they
were generated from the local Moby cache). Include only those data
types that are referred to (used by) the given data type.

An argument is one or more data types (C<MOSES::MOBY::Def::DataType>) whose
related data types are looked for.

=cut

sub get_related_types {
    my ($self, @datatypes) = @_;
    my $sofar_seen = {};
    foreach my $datatype (@datatypes) {
	$self->_get_related_types ($datatype, $sofar_seen);
    }
    return [ sort { $a->name cmp $b->name } values (%{ $sofar_seen }) ];
}

sub _get_related_types {
    my ($self, $datatype, $sofar_seen) = @_;
    return $sofar_seen unless $datatype;
    $$sofar_seen{$datatype->name} = $datatype;

    # go up (ISA line)
    $self->_add_types ($datatype->parent, $sofar_seen);

    # go down (HAS[A] line)
    if ($datatype->children) {
	foreach my $child_name (@{ $datatype->children }) {
	    $self->_add_types ($child_name->datatype, $sofar_seen);
	}
    }
}

sub _add_types {
    my ($self, $datatype_name, $sofar_seen) = @_;
    if ($datatype_name) {
	unless (exists ($$sofar_seen{$datatype_name})) {
	    my $related_obj = $self->get_datatype ($datatype_name);
	    $self->_get_related_types ($related_obj, $sofar_seen);
	}
    }
}

#-----------------------------------------------------------------
# get_all_children
#    return an array of MOSES::MOBY::Def::Relationship
#-----------------------------------------------------------------
sub get_all_children {
    my ($self, $datatype_name) = @_;
    my @children = ();
    while ($datatype_name ne 'Object') {
	my $datatype = $self->get_datatype ($datatype_name);
	push (@children, @{ $datatype->children });
	$datatype_name = $datatype->parent;
    }
    return @children;
}

#-----------------------------------------------------------------
# get_services
#-----------------------------------------------------------------

=head2 get_services

Return an array of BioMoby service definitions (type
C<MOSES::MOBY::Def::Service>), as obtained from a local cache.

Without any arguments it returns all services from all authorities:

    use MOSES::MOBY::Cache::Central;

    # create an aceess to a Moby registry cache
    # (use 'registry' only for non-default registries)
    my $cache = new MOSES::MOBY::Cache::Central
       ( cachedir =>'/usr/local/cache/',
         registry => 'http://my.moby.registry/endpoint/mobycentral.pl'
       );

    my @services = $cache->get_services;

If there is one argument, it should be a scalar, containing an
authority name. All services from this authority are returned. It
throws an exception if such named authority does not exist in the
local cache:

    @services = $cache->get_services ($authority);

If there are more arguments, the first is always an authority name, as
above, and the remaining are the service names (from the same
authority) wanted to be returned. If any of these names represents an
unknown service, it is ignored (no exception thrown):

    @services = $cache->get_services ('samples.jmoby.net',
				      qw ( HelloBiomobyWorld Mabuhay ));
or
    
    @services = $cache->get_services ('samples.jmoby.net', 'Mabuhay');

=cut

sub get_services {
    my ($self, @services) = @_;

#    print "GS: " . join (", ", @services) . "\n";

    # no authority given: get all services
    unless (@services) {
	my %by_authorities = $self->get_service_names;
	foreach my $authority (sort keys (%by_authorities)) {
	    push (@services, $self->get_services ($authority));
	}
	return @services;
    }

    # okay, we have an authority; read her XML definitions
    my $authority = shift @services;
    my $file = File::Spec->catfile ($self->cachedir,
				    $self->_clean ($self->_endpoint),
				    SERVICES_CACHE,
				    $authority);
    my $xml = '';
    local $/ = undef;
    open (FILE, "<$file")
	or $self->throw ("Can't open file $file for reading: $!");
    $xml = <FILE>;
    close FILE;

    # finally, get services from the authority XML
    if (@services) {
    	# get services by name
	my @result = ();
    	foreach my $name (@services) {
	    push (@result, $self->_createServiceFromXML ($xml, $name, $authority));
    	}
	return @result;
    }

    # get them all (from given authority)
    return $self->_createAllServicesFromXML ($xml);
}

#-----------------------------------------------------------------
# _createServiceFromXML
#    given xmlString and a service name, build a MOSES::MOBY::Def::Service
#-----------------------------------------------------------------
sub _createServiceFromXML {
    my ($self, $xml, $service_name, $service_authority) = @_;
    my $parser       = XML::LibXML->new();
    my $doc          = $parser->parse_string($xml);
    
    my $service = MOSES::MOBY::Def::Service->new();
    my @nodes = $doc->documentElement()->findnodes('*[@serviceName="'.$service_name.'"][@authURI="'.$service_authority.'"]');
    my $service_node = undef;
    $service_node = $nodes[0];
    $self->throw ("Service, '$service_name', under the authority, '$service_authority', was not found in the cache.") unless $service_node;
    
    $service->name($service_node->getAttribute('serviceName') || $service_name);
    $service->authority($service_node->getAttribute('authURI') || '');
    $service->lsid($service_node->getAttribute('lsid') || '');
    $service->type($service_node->getChildrenByTagName('serviceType')->get_node(1)->textContent) if $service_node->getChildrenByTagName('serviceType')->size() > 0;
    $service->authoritative($service_node->getChildrenByTagName('authoritative')->get_node(1)->textContent) if $service_node->getChildrenByTagName('authoritative')->size() > 0;
    $service->category($service_node->getChildrenByTagName('Category')->get_node(1)->textContent) if $service_node->getChildrenByTagName('Category')->size() > 0;
    $service->description($service_node->getChildrenByTagName('Description')->get_node(1)->textContent) if $service_node->getChildrenByTagName('Description')->size() > 0;
    $service->email($service_node->getChildrenByTagName('contactEmail')->get_node(1)->textContent) if $service_node->getChildrenByTagName('contactEmail')->size() > 0;
    $service->signatureURL($service_node->getChildrenByTagName('signatureURL')->get_node(1)->textContent) if $service_node->getChildrenByTagName('signatureURL')->size() > 0;
    $service->url($service_node->getChildrenByTagName('URL')->get_node(1)->textContent) if $service_node->getChildrenByTagName('URL')->size() > 0;
    
    my $input = $service_node->getChildrenByTagName('Input')->get_node(1) if $service_node->getChildrenByTagName('Input')->size > 0;
    if ($input) {
    	my $simples = $input->getChildrenByTagName('Simple');
    	for ( my $i = 1 ; $i <= $simples->size() ; $i++ ) {
    		my $simple = $simples->get_node($i);
    		my $article_name = $simple->getAttribute('articleName') || 'MISSING_ARTICLE_NAME_IN_INPUT';
    		my $object_type = $simple->getChildrenByTagName('objectType')->get_node(1) if $simple->getChildrenByTagName('objectType')->size > 0;
    		$self->throw('Simple input missing an object type') unless $object_type;
    		$object_type = $object_type->textContent;
    		
    		my $primary = MOSES::MOBY::Def::PrimaryDataSimple->new;
    		$primary->name($article_name);
    		$primary->datatype(new MOSES::MOBY::Def::DataType(name=>$object_type));
    		
    		my $namespaces = $simple->getChildrenByTagName('Namespace');
    		for ( my $j = 1 ; $j <= $namespaces->size() ; $j++ ) {
    			my $namespace = $namespaces->get_node($j)->textContent;
    			$primary->add_namespaces(MOSES::MOBY::Def::Namespace->new(name=>$namespace));
    		}
    		$service->add_inputs($primary);
    	}
    	my $collections = $input->getChildrenByTagName('Collection');
    	for ( my $i = 1 ; $i <= $collections->size() ; $i++ ) {
    		my $collection = $collections->get_node($i);
    		my $article_name = $collection->getAttribute('articleName') || 'MISSING_ARTICLE_NAME_IN_INPUT';
    		my $primaryCollection = MOSES::MOBY::Def::PrimaryDataSet->new(name=>$article_name);
    		$simples = $collection->getChildrenByTagName('Simple') || ();
    		for ( my $j = 1 ; $j <= $simples->size() ; $j++ ) {
	    		my $simple = $simples->get_node($j);
    			my $article_name = $simple->getAttribute('articleName') || '';
    			my $object_type = $simple->getChildrenByTagName('objectType')->get_node(1) if $simple->getChildrenByTagName('objectType')->size > 0;
    			$self->throw('Simple input missing an object type') unless $object_type;
	    		$object_type = $object_type->textContent;
    		
	    		my $primary = MOSES::MOBY::Def::PrimaryDataSimple->new;
    			$primary->name($article_name);
    			$primary->datatype(new MOSES::MOBY::Def::DataType(name=>$object_type));
    		
    			my $namespaces = $simple->getChildrenByTagName('Namespace');
	    		for ( my $j = 1 ; $j <= $namespaces->size() ; $j++ ) {
    				my $namespace = $namespaces->get_node($j)->textContent;
    				$primary->add_namespaces(MOSES::MOBY::Def::Namespace->new(name=>$namespace));
    			}
    			$primaryCollection->add_elements($primary);
    		}
    		$service->add_inputs($primaryCollection);
    	}
    }
    
    my $secondary = $service_node->getChildrenByTagName('secondaryArticles')->get_node(1) if $service_node->getChildrenByTagName('secondaryArticles')->size > 0;
    if ($secondary) {
    	my $parameters = $secondary->getChildrenByTagName('Parameter');
    	for (my $i = 1; $i <= $parameters->size(); $i++) {
    		my $parameter = $parameters->get_node($i);
    		my $article_name = $parameter->getAttribute('articleName') || 'MISSING_PARAMETER_NAME';
    		my $description = $parameter->getChildrenByTagName('description')->get_node(1)->textContent if $parameter->getChildrenByTagName('description') and $parameter->getChildrenByTagName('description')->size() > 0;
    		my $default = $parameter->getChildrenByTagName('default')->get_node(1)->textContent if $parameter->getChildrenByTagName('default') and $parameter->getChildrenByTagName('default')->size() > 0;
    		my $max = $parameter->getChildrenByTagName('max')->get_node(1)->textContent if $parameter->getChildrenByTagName('max') and $parameter->getChildrenByTagName('max')->size() > 0;
    		my $min = $parameter->getChildrenByTagName('min')->get_node(1)->textContent if $parameter->getChildrenByTagName('min') and $parameter->getChildrenByTagName('min')->size() > 0;
    		my $enum = $parameter->getChildrenByTagName('enum');
    		
    		my $secondaryParameter = MOSES::MOBY::Def::SecondaryData->new(
    				name=>$article_name
    			);
    		
    		$secondaryParameter->min($min) if $min and $min ne '';
    		$secondaryParameter->max($max) if $max and $max ne '';
    		$secondaryParameter->default($default) if $default;
    		$secondaryParameter->description($description) if $description;
    		for (my $j = 1; $j <= $enum->size(); $j++) {
    			$secondaryParameter->add_allowables($enum->get_node($j)->textContent);
    		}
    		$service->add_secondarys($secondaryParameter);

    	}
    }
    
    my $output = $service_node->getChildrenByTagName('Output')->get_node(1) if $service_node->getChildrenByTagName('Output')->size > 0;
    if ($output) {
    	my $simples = $output->getChildrenByTagName('Simple');
    	for ( my $i = 1 ; $i <= $simples->size() ; $i++ ) {
    		my $simple = $simples->get_node($i);
    		my $article_name = $simple->getAttribute('articleName') || 'MISSING_ARTICLE_NAME_IN_OUTPUT';
    		my $object_type = $simple->getChildrenByTagName('objectType')->get_node(1) if $simple->getChildrenByTagName('objectType')->size > 0;
    		$self->throw('Simple output missing an object type') unless $object_type;
    		$object_type = $object_type->textContent;
    		
    		my $primary = MOSES::MOBY::Def::PrimaryDataSimple->new;
    		$primary->name($article_name);
    		$primary->datatype(new MOSES::MOBY::Def::DataType(name=>$object_type));
    		
    		my $namespaces = $simple->getChildrenByTagName('Namespace');
    		for ( my $j = 1 ; $j <= $namespaces->size() ; $j++ ) {
    			my $namespace = $namespaces->get_node($j)->textContent;
    			$primary->add_namespaces(MOSES::MOBY::Def::Namespace->new(name=>$namespace));
    		}
    		$service->add_outputs($primary);
    	}
    	my $collections = $output->getChildrenByTagName('Collection');
    	for ( my $i = 1 ; $i <= $collections->size() ; $i++ ) {
    		my $collection = $collections->get_node($i);
    		my $article_name = $collection->getAttribute('articleName') || 'MISSING_ARTICLE_NAME_IN_OUTPUT';
    		my $primaryCollection = MOSES::MOBY::Def::PrimaryDataSet->new(name=>$article_name);
    		$simples = $collection->getChildrenByTagName('Simple') || ();
    		for ( my $j = 1 ; $j <= $simples->size() ; $j++ ) {
	    		my $simple = $simples->get_node($j);
    			my $article_name = $simple->getAttribute('articleName') || '';
    			my $object_type = $simple->getChildrenByTagName('objectType')->get_node(1) if $simple->getChildrenByTagName('objectType')->size > 0;
    			$self->throw('Simple input missing an object type') unless $object_type;
	    		$object_type = $object_type->textContent;
    		
	    		my $primary = MOSES::MOBY::Def::PrimaryDataSimple->new;
    			$primary->name($article_name);
    			$primary->datatype(new MOSES::MOBY::Def::DataType(name=>$object_type));
    		
    			my $namespaces = $simple->getChildrenByTagName('Namespace');
	    		for ( my $j = 1 ; $j <= $namespaces->size() ; $j++ ) {
    				my $namespace = $namespaces->get_node($j)->textContent;
    				$primary->add_namespaces(MOSES::MOBY::Def::Namespace->new(name=>$namespace));
    			}
    			$primaryCollection->add_elements($primary);
    		}
    		$service->add_outputs($primaryCollection);
    	}
    }
    return $service;
}

#-----------------------------------------------------------------
# _createAllServicesFromXML
#    given xmlString, build an array of MOSES::MOBY::Def::Service 
#    contained in the xml
#-----------------------------------------------------------------
sub _createAllServicesFromXML {
    my ($self, $xml) = @_;
    my $parser       = XML::LibXML->new();
    my $doc          = $parser->parse_string($xml);
    
    my $service_name =  "";
    my $authority =  "";
    my @services = ();
    
    my $nodes = $doc->documentElement->getChildrenByTagName('Service');
    for (my $i = 1; $i <= $nodes->size; $i++) {
    	$service_name = $nodes->get_node($i)->getAttribute('serviceName');
	$authority = $nodes->get_node($i)->getAttribute('authURI');
    	my $service = $self->_createServiceFromXML($xml, $service_name, $authority);
    	push @services, $service;
    }
    return @services;
}

#-----------------------------------------------------------------
# get_service_names
#-----------------------------------------------------------------

=head2 get_service_names

Return a hash where keys are authority names and values are array
references with service names belonging to corresponding authorities.

=cut

sub get_service_names {
    my $self = shift;
    my $pathToList = File::Spec->catfile ($self->cachedir,
					  $self->_clean ($self->_endpoint),
					  SERVICES_CACHE);
    my %hash;
    my $parser = XML::LibXML->new();

    my $doc = $parser->parse_file ( File::Spec->catfile ($pathToList, LIST_FILE) );
    
    my $nodes = $doc->documentElement()->getChildrenByTagName ('serviceName');
    
    for ( my $i = 1 ; $i <= $nodes->size() ; $i++ ) {
		my $node = $nodes->get_node($i);
		next unless $node->getAttribute ('name');
		my  $name = $node->getAttribute('name');
		my $authority = $node->getAttribute('authURI');
		if (exists $hash{$authority}) {
			my $array_ref = $hash{$authority};
			my @array = @{$array_ref};
			push @{array}, $name;
			$hash{$authority} = \@array;
		}else {
			my @array = ();
			push @array, $name;
			$hash{$authority} = \@array;
		}
    }
    return %hash;
}

#-----------------------------------------------------------------
# cache_exists
#-----------------------------------------------------------------

=head2 cache_exists

Return true if a local cache for the given registry exists (or
probably exists). An argument is a synonym, or an endpoint, of a
registry. See more about registry synonyms in
L<MOSES::MOBY::Cache::Registries>.

Here is how to ask for all existing registries:



=cut

sub cache_exists {
    my ($self, $registry) = @_;
    my $pathToList = File::Spec->catfile ($self->cachedir,
					  $self->_clean ($self->_endpoint ($registry)),
					  SERVICES_CACHE);
    return -e $pathToList;
}


#-----------------------------------------------------------------
# create_cache_dirs
#-----------------------------------------------------------------

=head2 create_cache_dirs

Creates the cache directories needed for generating datatypes and services.

Throws an exception if there are problems creating the directories.

=cut

sub create_cache_dirs {
    my ($self)= @_;
    my @dirs = (
    	File::Spec->catfile ($self->cachedir,$self->_clean ($self->_endpoint),DATATYPES_CACHE),
    	File::Spec->catdir ($self->cachedir,$self->_clean ($self->_endpoint),SERVICES_CACHE),
    	File::Spec->catdir ($self->cachedir,$self->_clean ($self->_endpoint),NAMESPACES_CACHE),
    	File::Spec->catdir ($self->cachedir,$self->_clean ($self->_endpoint),SERVICETYPES_CACHE),
     );
    
    foreach my $file (@dirs) {
    	my ($v, $d, $f) = File::Spec->splitpath( $file );
    	my $dir = File::Spec->catdir($v);
    	foreach my $part ( File::Spec->splitdir( ($d.$f ) ) ) {
        	$dir = File::Spec->catdir($dir, $part);
        	next if -d $dir or -e $dir;
        	mkdir( $dir ) || $self->throw("Error creating caching directory '".$dir."':\n$!");
        	$LOG->debug("creating the directory, '$dir'.");
    	}
    }
}

1;
__END__
