#-----------------------------------------------------------------
# MOBY::RDF::Ontologies::Cache::ServiceCache
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: ServiceCache.pm,v 1.6 2008/09/02 13:12:33 kawas Exp $
#-----------------------------------------------------------------

package MOBY::RDF::Ontologies::Cache::ServiceCache;

use XML::LibXML;

use RDF::Core::Model::Parser;
use RDF::Core::Storage::Memory;
use RDF::Core::Model;
use RDF::Core::Resource;
use RDF::Core::Literal;
use RDF::Core::Statement;
use RDF::Core::Model::Serializer;

use Fcntl ':flock';

use MOBY::RDF::Utils;
use MOBY::RDF::Ontologies::Services;
use MOBY::RDF::Ontologies::Cache::CacheUtils;
use MOBY::Client::Central;

use SOAP::Lite;

use Data::Dumper;
use strict;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::RDF::Ontologies::Cache::ServiceCache - Module for creating a cache of service instances for use when generating RDF

=head1 SYNOPSIS

	use MOBY::RDF::Ontologies::Cache::ServiceCache;

	# required
	my $cachedir = "/tmp/";

	# optional - gets default values from MOBY::Client::Central
	my $url = "http://moby.ucalgary.ca/moby/MOBY-Central.pl";
	my $uri = "http://moby.ucalgary.ca/MOBY/Central";

	my $x = MOBY::RDF::Ontologies::Cache::ServiceCache->new(
		endpoint	=> $url, 
		namespace 	=> $uri,
		cache		=> $cachedir,
	);

	# create the service cache
	$x->create_service_cache();

	# update the cache
	$x->update_service_cache();

	# obtain the RDF in a thread safe manner
	my $rdf = $x->get_rdf

=head1 DESCRIPTION

	This module aids in the creation and maintainence of a service instance cache for use in generating service RDF

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------

=head2 new

Instantiate a ServiceCache object.

Parameters: 
	* A Hash with keys:
		-> endpoint		=> the BioMOBY registry endpoint to use <optional>
		-> namespace	=> the BioMOBY registry namespace to use <optional>
		-> cache		=> the directory to store the cache <REQUIRED>

This subroutine attempts to create the cache directories right away 
and if any problems occur then an Exception is thrown.

=cut

sub new {
	my ( $class, %args ) = @_;

	# create an object
	my $self = bless {}, ref($class) || $class;

	# set various variables
	$self->{endpoint}  = $args{endpoint}  if $args{endpoint};
	$self->{namespace} = $args{namespace} if $args{namespace};
	$self->{cachedir}  = $args{cache}     if $args{cache};
	
	
	eval {
		$self->{endpoint} = MOBY::Client::Central->new()->{default_MOBY_server};
	} unless $args{endpoint};
	
	# if the values arent set, set to default values
	$self->{endpoint} = "http://moby.ucalgary.ca/moby/MOBY-Central.pl"
	  unless $self->{endpoint};
	$self->{namespace} = "http://moby.ucalgary.ca/MOBY/Central"
	  unless $self->{namespace};
	$self->{cachedir} = "/tmp/" unless $self->{cachedir};

	$self->{utils} = MOBY::RDF::Ontologies::Cache::CacheUtils->new(
												 cache     => $self->{cachedir},
												 endpoint  => $self->{endpoint},
												 namespace => $self->{namespace}
	);

	# create the cache directory if necessary
	$self->{utils}->create_cache_dirs unless $self->{utils}->cache_exists;

	# done
	return $self;
}

#-----------------------------------------------------------------
# create_service_cache
#-----------------------------------------------------------------

=head2 create_service_cache

Create the service cache. This will over write any pre-existing 
cache that it finds.

This method is not thread safe.

Throw an exception if any of the following occurs:
    * A SOAP error as a result of calling the registry
    * Problems writing to the cache directory

=cut

sub create_service_cache {
	my ($self) = @_;

	# 2 steps:
	# -> create a LIST file
	my $xml = $self->_create_list_file;

	# 2-> foreach service store RDF for the authority
	my $parser                = XML::LibXML->new();
	my $doc                   = $parser->parse_string($xml);
	my %authorities_completed = ();
	my $nodes = $doc->documentElement()->getChildrenByTagName('serviceName');
	for ( 1 .. $nodes->size() ) {
		my $name = $nodes->get_node($_)->getAttribute('authURI');
		next if $authorities_completed{$name};
		$authorities_completed{$name} = 1;

		$xml = MOBY::RDF::Ontologies::Services->new(
										   endpoint => $self->{utils}->_endpoint );
		$xml = $xml->findService( { authURI => $name, isAlive => 'no' } );
		my $file = File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE,
							$name
		);
		open( FILE, ">$file" )
		  or die("Can't open file '$file' for writing: $!");
		print FILE $xml;
		close FILE;
	}
}

#-----------------------------------------------------------------
# update_service_cache
#-----------------------------------------------------------------

=head2 update_service_cache

Update the services cache. This will update any items that are 'old',
by relying on the LSID for the datatype. This method is not thread safe.

This method returns the number of changed resources.

To update the cache with a thread safe method, call C<get_rdf>.

Throw an exception if any of the following occur:
	* There is a SOAP error calling the registry
	* There were read/write errors on the cache directory or its contents

=cut

sub update_service_cache {
	my ($self)           = @_;
	my $wasOld           = 0;
	my %old_services     = ();
	my %new_services     = ();
	my %changed_services = ();

	if (
		 !(
			-e File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE
			)
		 )
	  )
	{
		$self->create_service_cache;
		return;
	}

	if (
		 !(
			-e File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE,
							$self->{utils}->LIST_FILE
			)
		 )
	  )
	{
		warn(     "Services LIST_FILE doesn't exist, so I created the cache from scratch!"
		);
		$self->create_service_cache;
		return;
	}

	# steps:
	# read in the LIST file and extract lsids for all services
	my $file = File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE,
							$self->{utils}->LIST_FILE
	);
	my $parser = XML::LibXML->new();
	my $doc;
	eval {
		$doc    = $parser->parse_file($file);
	};
	warn "There was something wrong with '$file' and we couldn't parse it.\nWill attempt to create from scratch.\n" if $@;
	$doc = $parser->parse_string($self->_create_list_file) if $@;
	
	my $nodes  = $doc->documentElement()->getChildrenByTagName('serviceName');
	for ( 1 .. $nodes->size() ) {
		my $name = $nodes->get_node($_)->getAttribute('authURI');
		my $lsid = $nodes->get_node($_)->getAttribute('lsid');
		$old_services{$name}{$lsid} = 1;
	}

	# get the new LIST file and extract lsids for all services
	my $soap =
	  SOAP::Lite->uri( $self->{utils}->_namespace )
	  ->proxy( $self->{utils}->_endpoint )->on_fault(
		sub {
			my $soap = shift;
			my $res  = shift;
			die(   "There was a problem calling the registry: "
				 . $self->{utils}->_endpoint . "\@ "
				 . $self->{utils}->_namespace . ".\n"
				 . $res );
		}
	  );

	my $xml = $soap->retrieveServiceNames()->result;
	$parser = XML::LibXML->new();
	$doc    = $parser->parse_string($xml);
	$nodes  = $doc->documentElement()->getChildrenByTagName('serviceName');
	for ( 1 .. $nodes->size() ) {
		my $name = $nodes->get_node($_)->getAttribute('authURI');
		my $lsid = $nodes->get_node($_)->getAttribute('lsid');
		$new_services{$name}{$lsid} = 1;
	}

    # go through the keys of the new one and if the keys doesnt exist or has been modified, add to 'download' queue
	foreach my $auth ( keys %new_services ) {
		next if $changed_services{$auth};
		foreach my $lsid ( keys %{ $new_services{$auth} } ) {
			$changed_services{$auth} = 1 unless $old_services{$auth}{$lsid};
			delete $old_services{$auth}{$lsid} if $old_services{$auth}{$lsid};
			
		}
	}

	# iterate over old_services and add their authority to changed_services
	# old services should only have authorities with services that have been removed 
	foreach my $auth ( keys %old_services ) {
		next if $changed_services{$auth};
		foreach my $lsid ( keys %{ $old_services{$auth} } ) {
			next if $changed_services{$auth};
			$changed_services{$auth} = 1;
		}
	}
	
    # if their where changes, save new LIST file over the old one and get changes
	if ( keys %changed_services ) {

		# save new LIST file
		open( FILE, ">$file" )
		  or die("Can't open file '$file' for writing: $!");
		print FILE $xml;
		close FILE;

		# clear used values
		$xml    = undef;
		$file   = undef;
		$parser = undef;
		$doc    = undef;
		$nodes  = undef;
		foreach my $authURI ( keys %changed_services ) {
			$wasOld++;
			$xml = MOBY::RDF::Ontologies::Services->new(
										  endpoint => $self->{utils}->_endpoint, );

			$xml = $xml->findService( { authURI => $authURI, isAlive => 'no' } );
			$file = File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE,
							$authURI
			);
			open( FILE, ">$file" )
			  or die("Can't open file '$file' for writing: $!");
			print FILE $xml;
			close FILE;
		}
	}
	
	# iterate through file system list and if the authority is missing from new_services delete it from the cache
	my $cachedir = File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE
	);
	
	eval {
		my @files = $self->{utils}->plainfiles($cachedir);
		foreach my $path (@files) {
			my $filename = substr $path, length($cachedir)+1;
			
			# dont remove the RDF, LIST or update file
			next if -d $filename;
			next
			  if $filename eq $self->{utils}->RDF_FILE
				  or $filename eq $self->{utils}->LIST_FILE
			  	or $filename eq $self->{utils}->UPDATE_FILE;
			  	
			unlink($path) unless $new_services{$filename};
			$wasOld++ unless $new_services{$filename};
		}
	};
	return $wasOld;
}

#-----------------------------------------------------------------
# get_rdf
#    Return a cached copy of the RDF

#-----------------------------------------------------------------

=head2 get_rdf

Gets the cached copy of the RDF for all services. This subroutine 
is thread safe as it performs a flock on a Lock file in the 
directory while performing operations.

Throw an exception if any of the following occur:
	* There was a SOAP problem communicating with a registr
	* There was a file read/write while performing cache related
	  activities
	* There was a problem parsing XML

=cut

sub get_rdf {
	my ($self) = @_;
	my $xml = "";
	my $lock = File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE,
							$self->{utils}->UPDATE_FILE
	);

	my $file = File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE,
							$self->{utils}->RDF_FILE
	);
	my $dir = File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE
	);

	open( LOCK, ">$lock" );
	flock( LOCK, LOCK_EX );
	eval {

		# check if we need to re-merge the RDF
		my $isStale = $self->update_service_cache;
		if ( $isStale or !( -e $file ) ) {
			
			my $providers = $self->_get_service_providers;
			
			# re-merge rdf
			my $parser = XML::LibXML->new();
			my $doc    = undef;
			opendir DIR, $dir
			  or die "Could not open directory for reading: $!\n";

			# foreach authority, parse the rdf - add to a single document
			foreach my $RDF ( readdir DIR ) {
				next if -d $RDF;
				next
				  if $RDF eq $self->{utils}->RDF_FILE
				  or $RDF eq $self->{utils}->LIST_FILE
				  or $RDF eq $self->{utils}->UPDATE_FILE;
				#remove those authorities that dont have any services
				unlink(File::Spec->catfile( $dir, $RDF )) unless $providers->{$RDF};  
				do {
					eval {
						$doc =
						  $parser->parse_file(
											File::Spec->catfile( $dir, $RDF ) );
					};
					warn $@ if $@;
					# if it didnt parse correctly, reset to null
					$doc = undef if $@;
					next;
				} unless $doc;
				my $temp_doc = eval {
					$parser->parse_file( File::Spec->catfile( $dir, $RDF ) );
				};
				warn $@ if $@;
				next    if $@;
				foreach

				  # here
				  my $service (
							  $temp_doc->findnodes('/rdf:RDF/rdf:Description') )
				{
					$doc->documentElement->appendChild($service);
				}

			}
			$xml = $doc->toString() if $doc;
			$xml = new MOBY::RDF::Utils->empty_rdf unless $doc;

			# save new RDF file
			open( FILE, ">$file" )
			  or die("Can't open file '$file' for writing: $!");
			print FILE $xml;
			close FILE;
		} else {

			# send existing rdf
			open( RDF_FILE, $file );
			$xml = join "", <RDF_FILE>;
		}
	};
	#flock( LOCK, LOCK_UN );
	close(LOCK);
	die $@ if $@;
	return $xml;
}

sub _get_service_providers {
	my ($self) = @_;
	my $soap =    
	  SOAP::Lite->uri( $self->{utils}->_namespace )
	  ->proxy( $self->{utils}->_endpoint )->on_fault(
		sub {
			my $soap = shift;
			my $res  = shift;
			die(   "There was a problem calling the registry: "
				 . $self->{utils}->_endpoint . "\@ "
				 #. $self->{utils}->_namespace . ".\n"
				 . $res );
		}
	  );

	my $xml = $soap->retrieveServiceProviders()->result;
	my %providers = ();
	
	my $parser                = XML::LibXML->new();
	my $doc                   = $parser->parse_string($xml);
	my $nodes = $doc->documentElement()->getChildrenByTagName('serviceProvider');
	for ( 1 .. $nodes->size() ) {
		my $name = $nodes->get_node($_)->getAttribute('name');
		next if $providers{$name};
		$providers{$name} = 1;
	}
	
	return \%providers;
	
}

# creates the list file and returns it as a string
sub _create_list_file {
	my ($self) = @_;
	my $soap =    
	  SOAP::Lite->uri( $self->{utils}->_namespace )
	  ->proxy( $self->{utils}->_endpoint )->on_fault(
		sub {
			my $soap = shift;
			my $res  = shift;
			die(   "There was a problem calling the registry: "
				 . $self->{utils}->_endpoint . "\@ "
				 . $self->{utils}->_namespace . ".\n"
				 . $res );
		}
	  );

	my $xml = $soap->retrieveServiceNames()->result;

	# create cache dirs as needed
	$self->{utils}->create_cache_dirs;
	my $file = File::Spec->catfile(
							$self->{utils}->cachedir,
							$self->{utils}->_clean( $self->{utils}->_endpoint ),
							$self->{utils}->SERVICES_CACHE,
							$self->{utils}->LIST_FILE
	);
	open( FILE, ">$file" )
	  or die("Can't open file '$file' for writing: $!");
	print FILE $xml;
	close FILE;
	
	return $xml;

}

1;
__END__
