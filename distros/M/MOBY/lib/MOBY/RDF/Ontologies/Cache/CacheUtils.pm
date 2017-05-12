#-----------------------------------------------------------------
# MOBY::RDF::Ontologies::Cache::Cache
# Author: Edward Kawas <edward.kawas@gmail.com>,
#
# For copyright and disclaimer see below.
#
# $Id: CacheUtils.pm,v 1.3 2008/09/02 13:12:33 kawas Exp $
#-----------------------------------------------------------------
package MOBY::RDF::Ontologies::Cache::CacheUtils;

#imports
use XML::LibXML;
use File::Spec;
use strict;
use DirHandle;

# names of cache directories/files/locks
use constant LIST_FILE          => '__L__I__S__T__';
use constant RDF_FILE           => '__R__D__F__';
use constant UPDATE_FILE        => '__U__P__D__A__T__E__F__I__L__E__';
use constant DATATYPES_CACHE    => 'dataTypes';
use constant SERVICES_CACHE     => 'services';
use constant NAMESPACES_CACHE   => 'namespaces';
use constant SERVICETYPES_CACHE => 'serviceTypes';

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::RDF::Ontologies::Cache::CacheUtils - Utility module that aids in caching 

=head1 SYNOPSIS

	use MOBY::RDF::Ontologies::Cache::CacheUtils;
	my $cachedir = "C:/tmp/";
	my $url      = "http://moby.ucalgary.ca/moby/MOBY-Central.pl";
	my $uri      = "http://moby.ucalgary.ca/MOBY/Central";

	my $x = MOBY::RDF::Ontologies::Cache::CacheUtils->new(

		endpoint  => $url,
		namespace => $uri,
		cache     => $cachedir,

	);

	# create the cache directory
	$x->create_cache_dirs;

	# check if the cache exists
	print "Cache exists!\n" if $x->cache_exists();
	print "Cache doesnt exist!\n" unless $x->cache_exists();

	# get the cache dir
	print "The cache dir is: " . $x->cachedir . "\n";

	# get the exact location of all cache dirs
	my $dirs = $x->get_cache_dirs();
	while ( ( $key, $value ) = each( %{$dirs} ) ) {    
		print "$key is stored in $value\n";
	}


=head1 DESCRIPTION

	This module aids in the creation and maintainence of cache directories

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

=head2 new

Instantiate a CacheUtils object.

Parameters: 
	* A Hash with keys:
		-> endpoint		=> the BioMOBY registry endpoint to use <required>
		-> namespace	=> the BioMOBY registry namespace to use <required>
		-> cache		=> the directory to store the cache <required>

If endpoint or cache are not specified, then new fails (dies).

=cut

sub new {
	my ( $class, %args ) = @_;

	# create an object
	my $self = bless {}, ref($class) || $class;

	# set various variables
	$self->{endpoint}  = $args{endpoint}  if $args{endpoint};
	$self->{namespace} = $args{namespace} if $args{namespace};
	$self->{cachedir}  = $args{cache}     if $args{cache};

	# this variable isnt that important ...
	$self->{namespace} = "http://moby.ucalgary.ca/MOBY/Central"
	  unless $self->{endpoint};

	# die if endpoint or cachedir is missing
	die
"You neglected to specify a cache destination. Please specify a 'cache' location ...\n"
	  unless $self->{cachedir};
	die
"You neglected to provide a BioMOBY registry endpoint. Please specify an 'endpoint'\n"
	  unless $self->{endpoint};

	# done
	return $self;
}

#-----------------------------------------------------------------
# _endpoint
#    Return and/or set an endpoint of a given registry.

#-----------------------------------------------------------------
sub _endpoint {
	my ( $self, $registry ) = @_;

	# set the endpoint if necessary
	$self->{endpoint} = $registry if $registry and $registry =~ m"^http://";

	# return the endpoint
	return $self->{endpoint};
}

#-----------------------------------------------------------------
# _namespace
#    Return and/or set an namespace of a given registry.

#-----------------------------------------------------------------
sub _namespace {
	my ( $self, $registry ) = @_;

	# set the namespace if necessary
	$self->{namespace} = $registry if $registry and $registry =~ m"^http://";

	# return the namespace
	return $self->{namespace};
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
			} else {
				$lastOneWasDigitalized = 0;
				$string                = $string . "$char";
			}
		}
		return $string;
	}
	return '';
}

#-----------------------------------------------------------------
# cache_exists
#-----------------------------------------------------------------

=head2 cache_exists

Return true if a local cache for the given registry exists (or
probably exists). An argument is a an endpoint of a
registry.

=cut

sub cache_exists {
	my ( $self, $registry ) = @_;
	my $pathToList =
	  File::Spec->catfile( $self->cachedir,
						   $self->_clean( $self->_endpoint($registry) ),
						   SERVICES_CACHE );
	return -e $pathToList;
}

#-----------------------------------------------------------------
# cache_exists
#-----------------------------------------------------------------

=head2 cachedir

Return the cache dir

=cut

sub cachedir {
	my ( $self, $dir ) = @_;
	$self->{cachedir} = $dir if $dir and -d $dir;
	return $self->{cachedir};
}

#-----------------------------------------------------------------
# create_cache_dirs
#-----------------------------------------------------------------

=head2 create_cache_dirs

Creates the cache directories needed for generating datatypes and services.

Throws an exception if there are problems creating the directories.

=cut

sub create_cache_dirs {
	my ($self) = @_;
	my @dirs = (
				 File::Spec->catfile(
									  $self->cachedir,
									  $self->_clean( $self->_endpoint ),
									  DATATYPES_CACHE
				 ),
				 File::Spec->catdir(
									 $self->cachedir,
									 $self->_clean( $self->_endpoint ),
									 SERVICES_CACHE
				 ),
				 File::Spec->catdir(
									 $self->cachedir,
									 $self->_clean( $self->_endpoint ),
									 NAMESPACES_CACHE
				 ),
				 File::Spec->catdir(
									 $self->cachedir,
									 $self->_clean( $self->_endpoint ),
									 SERVICETYPES_CACHE
				 ),
	);

	foreach my $file (@dirs) {
		my ( $v, $d, $f ) = File::Spec->splitpath($file);
		my $dir = File::Spec->catdir($v);
		foreach my $part ( File::Spec->splitdir( ( $d . $f ) ) ) {
			$dir = File::Spec->catdir( $dir, $part );
			next if -d $dir or -e $dir;
			mkdir($dir)
			  || die( "Error creating caching directory '" . $dir . "':\n$!" );
		}
	}
}

#-----------------------------------------------------------------
# get_cache_dirs
#-----------------------------------------------------------------

=head2 get_cache_dirs

Gets the cache directories used for a specific cache as a hash.

=cut

sub get_cache_dirs {
	my ($self) = @_;
	return {
			 DATATYPES_CACHE => File::Spec->catfile(
											  $self->cachedir,
											  $self->_clean( $self->_endpoint ),
											  DATATYPES_CACHE
			 ),
			 SERVICES_CACHE => File::Spec->catdir(
											  $self->cachedir,
											  $self->_clean( $self->_endpoint ),
											  SERVICES_CACHE
			 ),
			 NAMESPACES_CACHE => File::Spec->catdir(
											  $self->cachedir,
											  $self->_clean( $self->_endpoint ),
											  NAMESPACES_CACHE
			 ),
			 SERVICETYPES_CACHE => File::Spec->catdir(
											  $self->cachedir,
											  $self->_clean( $self->_endpoint ),
											  SERVICETYPES_CACHE
			 ),
	};

}


sub plainfiles {
   my ($self, $dir )= @_;
   my $dh = DirHandle->new($dir)   or die "can't opendir $dir: $!";
   return sort                     # sort pathnames
          grep {    -f     }       # choose only "plain" files
          map  { "$dir/$_" }       # create full paths
          grep {  !/^\./   }       # filter out dot files
          $dh->read();             # read all entries
}


1;
__END__
