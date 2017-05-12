#!/usr/bin/perl -w

package File::Cache;

use strict;
use Carp;
use Digest::MD5 qw(md5_hex);
use File::Path;
use File::Find;
use File::Spec;
use File::Spec::Functions qw(tmpdir splitdir splitpath catdir);
use Exporter;

use vars qw(@ISA @EXPORT_OK $VERSION $sSUCCESS $sFAILURE $sTRUE $sFALSE
	    $sEXPIRES_NOW $sEXPIRES_NEVER $sNO_MAX_SIZE $sGET_STALE_ONLY
	    $sGET_FRESH_ONLY $CACHE_OBJECT_VERSION);

$VERSION = '0.16';

# Describes the caches created by this version of File::Cache.  (Should
# be incremented any time the cache file format changes in a way that
# breaks backward compatibility.)

$CACHE_OBJECT_VERSION = '0.01';

@ISA = qw(Exporter);

@EXPORT_OK = qw($sSUCCESS $sFAILURE $sTRUE $sFALSE $sEXPIRES_NOW
		$sEXPIRES_NEVER $sNO_MAX_SIZE );

# -----------------------------------------------------------------------------

# Code notes:
# Internal subroutines (helper routines not supposed to be called by
# external clients) are preceded with an underscore ("_"). Subroutines
# (both internal and external) that are called as functions, as
# opposed to methods, are in ALL CAPS. The PURGE and CLEAR routines
# are object-independent, which means that any subroutines they call
# must also be object-independent.

# -----------------------------------------------------------------------------

# Constants

$sSUCCESS = 1;
$sFAILURE = 0;

$sTRUE = 1;
$sFALSE = 0;

$sEXPIRES_NOW = 0;
$sEXPIRES_NEVER = -1;

$sNO_MAX_SIZE = -1;

$sGET_STALE_ONLY = 1;
$sGET_FRESH_ONLY = 0;

# The default cache key is used inside the tmp filesystem (as defined
# by File::Spec)

my $sDEFAULT_CACHE_KEY;

$sDEFAULT_CACHE_KEY = ($^O eq 'dos' || $^O eq 'MSWin32') ?
  'FileCache' : 'File::Cache';


# if a namespace is not specified, use this as a default

my $sDEFAULT_NAMESPACE = "_default";


# by default, remove objects that have expired when then are requested

my $sDEFAULT_AUTO_REMOVE_STALE = $sTRUE;


# by default, the filemode is world read/writable

my $sDEFAULT_FILEMODE = 0777;


# by default, there is no max size to the cache

my $sDEFAULT_MAX_SIZE = $sNO_MAX_SIZE;


# if the OS does not support getpwuid, use this as a default username

my $sDEFAULT_USERNAME = 'nobody';


# by default, the objects in the cache never expire

my $sDEFAULT_GLOBAL_EXPIRES_IN = $sEXPIRES_NEVER;


# default cache depth

my $sDEFAULT_CACHE_DEPTH = 0;


# File::Cache supports either Storable or Data::Dumper as the
# persistence mechanism. The default persistence mechanism uses Storable

my $sDEFAULT_PERSISTENCE_MECHANISM = 'Storable';



# cache description filename

my $sCACHE_DESCRIPTION_FILENAME = '.description';


# Always use a global friendly umask for the .description files

my $sCACHE_DESCRIPTION_UMASK = 022;


# valid filepath characters for tainting. Be sure to accept DOS/Windows style
# path specifiers (C:\path) also

my $sUNTAINTED_FILE_PATH_REGEX = qr{^([-\@\w\\\\~./:]+|[\w]:[-\@\w\\\\~./]+)$};



# -----------------------------------------------------------------------------

# create a new Cache object that can be used to persist
# data across processes

sub new
{
    my ($proto, $options) = @_;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);


    # remove objects from the cache that have expired on retrieval
    # when this is set

    my $auto_remove_stale = defined $options->{auto_remove_stale} ?
	$options->{auto_remove_stale} : $sDEFAULT_AUTO_REMOVE_STALE;

    $self->set_auto_remove_stale($auto_remove_stale);


    # username is either specified or searched for in an OS
    # independent way

    my $username = defined $options->{username} ?
	$options->{username} : _FIND_USERNAME();

    $self->set_username($username);


    # the user can specify the filemode

    my $filemode = defined $options->{filemode} ?
	$options->{filemode} : $sDEFAULT_FILEMODE;

    $self->set_filemode($filemode);


    # remember the expiration delta to be used for all objects if
    # specified

    my $global_expires_in = defined $options->{expires_in} ?
	$options->{expires_in} : $sDEFAULT_GLOBAL_EXPIRES_IN;

    $self->set_global_expires_in($global_expires_in);


    # set the cache key to either the user's value or the default

    my $cache_key = defined $options->{cache_key} ?
	$options->{cache_key} : _BUILD_DEFAULT_CACHE_KEY();

    $self->set_cache_key($cache_key);


    # this instance will use the namespace specified or the default

    my $namespace = defined $options->{namespace} ?
	$options->{namespace} : $sDEFAULT_NAMESPACE;

    $self->set_namespace($namespace);


    # the cache will automatically create subdirectories to this depth

    my $cache_depth = defined $options->{cache_depth} ?
	$options->{cache_depth} : $sDEFAULT_CACHE_DEPTH;

    $self->set_cache_depth($cache_depth);


    # the max cache size is either specified by the user or by the
    # default cache size. Be sure to do this after the cache key,
    # user, and namespace are set up, because it invokes reduce_size.

    my $max_size = defined $options->{max_size} ?
	$options->{max_size} : $sDEFAULT_MAX_SIZE;

    $self->set_max_size($max_size);


    # verify that we can create the cache when necessary later

    _VERIFY_DIRECTORY( $self->_get_namespace_path() ) == $sSUCCESS or
	croak("Can not build cache at " . $self->_get_namespace_path() .
	      ". Check directory permissions.");

    # set the persistence mechanism to the user specified one (or the
    # default), then load the necessary modules that correspond to
    # that persistence mechanism choice

    my $persistence_mechanism = defined $options->{persistence_mechanism} ?
      $options->{persistence_mechanism} : $sDEFAULT_PERSISTENCE_MECHANISM;

    $self->set_persistence_mechanism($persistence_mechanism);
    $self->_load_persistence_mechanism();


    # could update a legacy cache here


    # check that any existing cache is compatible

    $self->_check_cache_compatibility();


    # write the cache description, in case there isn't already one

    my $cache_description = $self->_get_cache_description();

    _WRITE_CACHE_DESCRIPTION( $cache_key, $cache_description, $filemode );


    return $self;
}

# -----------------------------------------------------------------------------

# Reads the cache description from the file system. Returns a reference to a
# hash, or undef if no cache appears to be in location specified by the cache
# key, or the cache has problems.  A cache description is automatically
# generated for older style caches that do not have cache description files.
# (The presence of any directories in the cache key directory are taken to
# mean that such a legacy cache exists.)

sub _READ_CACHE_DESCRIPTION
{
    my ($cache_key) = @_;

    defined($cache_key) or
      croak("cache key required");

    my $cache_description_path =
      _BUILD_PATH($cache_key, $sCACHE_DESCRIPTION_FILENAME);

    # This is the name of the variable stored using Data::Dumper in
    # the cache description file.

    my $cache_description = {};

    if (-f $cache_description_path) {

      my $serialized_cache_description_ref =
	_READ_FILE($cache_description_path);

      unless (defined $serialized_cache_description_ref and
	      defined $$serialized_cache_description_ref)
      {

        warn "Could not read cache description file $cache_description_path";
        return undef;

      }

      _UNSERIALIZE_HASH($$serialized_cache_description_ref,
			$cache_description);

    } elsif (_SUBDIRECTORIES_PRESENT($cache_key) eq $sTRUE) {

      # Older caches used Storable as the persistence mechanism
      $cache_description =
	{
	  'File::Cache Version' => undef,
	  'Cache Object Version' => 0.01,
          'Persistence Mechanism' => 'Storable',
        };

    } else {

      return undef;

    }

    return $cache_description;
}

# -----------------------------------------------------------------------------

# Determines if there are subdirectories in a given directory

sub _SUBDIRECTORIES_PRESENT
{
    my ($directory) = @_;

    defined($directory) or
	croak("directory required");

    $directory = _UNTAINT_FILE_PATH($directory);

    return $sFALSE unless -d $directory;

    opendir(DIR, $directory) or
	croak("Couldn't open directory $directory: $!");

    my @dirents = readdir(DIR);

    closedir DIR;

    foreach my $dirent (@dirents)
    {
      return $sTRUE if -d $dirent;
    }

    return $sFALSE;
}

# -----------------------------------------------------------------------------

# Writes a cache description to the file system. Takes a cache key, a
# reference to a hash, and a file mode

sub _WRITE_CACHE_DESCRIPTION
{
    my ($cache_key, $cache_description, $filemode) = @_;

    defined($cache_key) or
	croak("cache_key required");

    defined($cache_description) or
	croak("cache description required");

    defined($filemode) or
	croak("filemode required");

    my $cache_description_path =
      _BUILD_PATH($cache_key, $sCACHE_DESCRIPTION_FILENAME);

    my $serialized_cache_description = _SERIALIZE_HASH($cache_description);

    _CREATE_DIRECTORY($cache_key,0);

    # mike@blakeley.com: specifying the filemode is bad for .description,
    # since it's global for the whole cache.

    _WRITE_FILE($cache_description_path,
		\$serialized_cache_description,
		$filemode,
	        $sCACHE_DESCRIPTION_UMASK);


}


sub _SERIALIZE_HASH
{
  my ($hash_ref) = @_;

  my $serialized_hash;

  foreach my $key (keys %{$hash_ref}) {

    $serialized_hash .= "$key => $hash_ref->{$key}\n";

  }

  return $serialized_hash;
}


sub _UNSERIALIZE_HASH
{
  my ($string, $hash_ref) = @_;

  my @key_value_pair_list = split(/\n/, $string);

  foreach my $key_value_pair (@key_value_pair_list) {

    my ($key, $value) = $key_value_pair =~ m|(.*?) => (.*)|;

    next unless $key and $value;

    $hash_ref->{$key} = $value;

  }
}

# -----------------------------------------------------------------------------

# Check that any existing cache is compatible. For example, a cache
# created using a later version of File::Cache with a new cached
# object format is incompatible.

sub _check_cache_compatibility
{
    my ($self) = @_;

    my $existing_cache_description =
      _READ_CACHE_DESCRIPTION( $self->get_cache_key() );

    # Not defined means that there is no existing cache, or there is a problem
    # with the cache.
    return unless defined $existing_cache_description;

    # Compare cache object versions.
    if ( ($existing_cache_description->{'Cache Object Version'} >
          $CACHE_OBJECT_VERSION) )
    {
      warn "Incompatible cache object versions detected. " .
        "The cache will be cleared";
      CLEAR( $self->get_cache_key() );
      return;
    }

    # Check that the persistence mechanisms match.
    if ( $existing_cache_description->{'Persistence Mechanism'} ne
         $self->get_persistence_mechanism() )
    {
      warn "Incompatible cache object persistence mechanisms detected. " .
        "The cache will be cleared";
      CLEAR( $self->get_cache_key() );
      return;
    }
}

# -----------------------------------------------------------------------------

# Gets the cache description for the cache, returning a reference to a
# hash. The keys are:
# - File::Cache Version: The version of File::Cache used to create the
#   cache. (May be undef for cache descriptions that are auto-generated
#   by _READ_CACHE_DESCRIPTION based on a legacy cache.)
# - Cache Object Version: The version number of the format used to store
#   objects in the cache.
# - Persistence Mechanism: The persistence mechanism used to store
#   objects in the cache.

sub _get_cache_description
{
    my ($self) = @_;

    my $cache_description =
    {
        'File::Cache Version' => $VERSION,
        'Cache Object Version' => $CACHE_OBJECT_VERSION,
        'Persistence Mechanism' => $self->get_persistence_mechanism(),
    };

    return $cache_description;
}

# -----------------------------------------------------------------------------

# store an object in the cache associated with the identifier

sub set
{
    my ($self, $identifier, $object, $expires_in) = @_;

    defined($identifier) or
      croak("identifier required");

    my $unique_key = _BUILD_UNIQUE_KEY($identifier);

    # expiration time is based on a delta from the current time if
    # expires_in is defined, the object will expire in that number of
    # seconds from now else if expires_in is undefined, it will expire
    # based on the global_expires_in

    my $global_expires_in = $self->get_global_expires_in();

    my $expires_at;

    my $created_at = time();

    if (defined $expires_in) {
	$expires_at = ($expires_in eq $sEXPIRES_NEVER) ?
          $expires_in : ($created_at + $expires_in);
    } elsif ($global_expires_in ne $sEXPIRES_NEVER) {
	$expires_at = $created_at + $global_expires_in;
    } else {
	$expires_at = $sEXPIRES_NEVER;
    }


    # add the new object to the cache in this instance's namespace

    my %object_data = ( object => $object, expires_at => $expires_at,
			created_at => $created_at );

    my $frozen_object_data =
      _SERIALIZE( \%object_data, $self->get_persistence_mechanism() );

    # Figure out what the new size of the cache should be in order to
    # accomodate the new data and still be below the max_size. Then
    # reduce the size.

    my $max_size = $self->get_max_size();

    if ($max_size != $sNO_MAX_SIZE) {
      my $new_size = $max_size - length $frozen_object_data;
      $new_size = 0 if $new_size < 0;
      $self->reduce_size($new_size);
    }

    my $filemode = $self->get_filemode();

    my $cached_file_path = $self->_build_cached_file_path($unique_key);

    _WRITE_FILE($cached_file_path, \$frozen_object_data, $filemode);

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# loads the module for serializing data

sub _load_persistence_mechanism
{
    my ($self) = @_;

    if ($self->get_persistence_mechanism() eq 'Storable')
    {
      require Storable;
      Storable->import( qw(nfreeze thaw dclone));
    }
    # Should be already loaded. No harm done in doing it again
    elsif ($self->get_persistence_mechanism() eq 'Data::Dumper')
    {
      require Data::Dumper;
      Data::Dumper->import();
    }
    # An invalid persistence mechanism choice by the user has already been
    # checked. If we see an invalid choice here it must be a bug in
    # the module. (die in this case instead of croaking)
    else
    {
      croak("Argument must be either \"Storable\" or \"Data::Dumper\"");
    }
}

# ------------------------------------------------------------------------------

# turns a hash reference into a serialized string using a method which
# depends on the persistence mechanism choice

sub _SERIALIZE
{
    my ($data_reference, $persistence_mechanism) = @_;

    defined($data_reference) or
      croak("object reference required");

    defined($persistence_mechanism) or
      croak("persistence mechanism required");

    if ($persistence_mechanism eq 'Storable')
    {
      return nfreeze($data_reference);
    }
    else
    {
      return Data::Dumper->Dump([$data_reference], ['cache_object']);
    }
}

# ------------------------------------------------------------------------------

# turns a reference to a serialized string into a reference to data using
# a method which depends on the persistence mechanism choice. Deletes the
# cache key if the unserialization fails.

sub _UNSERIALIZE
{
    my ($data_reference, $persistence_mechanism, $cache_key) = @_;

    defined($data_reference) or
      croak("object reference required");

    defined($persistence_mechanism) or
      croak("persistence mechanism required");

    if ($persistence_mechanism eq 'Storable')
    {
      return thaw($$data_reference);
    }
    else
    {
      # This is what the serialize routine calls the cached object
      my $cache_object;

      my $errors;
      {
        local $SIG{__WARN__} = sub { $errors .= $_[0] };

        eval $$data_reference;
      }

      if ($errors || $@)
      {
        warn "Cache object is corrupted and will be deleted";
        unlink $cache_key;
        return undef;
      }

      return $cache_object;
    }
}

# ------------------------------------------------------------------------------

# return a copy of a serialized string (reference or non-reference)
# using a method which depends on the persistence mechanism choice

sub _CLONE
{
    my ($data_reference, $persistence_mechanism) = @_;

    defined($data_reference) or
 	    croak("object reference required");

    defined($persistence_mechanism) or
 	    croak("persistence mechanism required");

    my $cloned_data;

    if ($persistence_mechanism eq 'Storable')
    {
	$cloned_data =
	  (ref $data_reference) ? dclone($data_reference) : $data_reference;
    }
    else
    {
      if (ref $data_reference)
      {
        my $data = $$data_reference;
	  $cloned_data = \$data;
      }
      else
      {
	  $cloned_data = $data_reference;
      }
    }

    return $cloned_data;
}

# ------------------------------------------------------------------------------

# retrieve an object from the cache associated with the identifier,
# and remove it from the cache if its expiration has elapsed and
# auto_remove_stale is 1.

sub get
{
    my ($self, $identifier) = @_;

    defined($identifier) or
      croak("identifier required");

    my $object = $self->_get($identifier, $sGET_FRESH_ONLY);

    return $object;
}

# ------------------------------------------------------------------------------

# retrieve an object from the cache associated with the identifier,
# but only if it's stale

sub get_stale
{
    my ($self, $identifier) = @_;

    defined($identifier) or
      croak("identifier required");

    my $object = $self->_get($identifier, $sGET_STALE_ONLY);

    return $object;
}

# ------------------------------------------------------------------------------

# Gets the stale or non-stale data from the cache, depending on the
# second parameter ($sGET_STALE_ONLY or $sGET_FRESH_ONLY)

sub _get
{
    my ($self, $identifier, $freshness) = @_;

    defined($identifier) or
      croak("identifier required");

    defined($freshness) or
      croak("freshness required");

    my $unique_key = _BUILD_UNIQUE_KEY($identifier);

    my $cached_file_path = $self->_get_cached_file_path($unique_key);

    # check the cache for the specified object

    my $cloned_object = undef;

    my $object_data;

    $object_data =
      _READ_OBJECT_DATA($cached_file_path);

    if ($object_data) {

	my $object = $object_data->{object};

	my $expires_at = $object_data->{expires_at};
	
	# If we want non-stale data...

	if ($freshness eq $sGET_FRESH_ONLY) {

	    # Check if the cache item has expired

	    if (_S_SHOULD_EXPIRE($expires_at)) {

		# Remove the item from the cache if auto_remove_stale
		# is $sTRUE

		my $auto_remove_stale = $self->get_auto_remove_stale();
		
		if ($auto_remove_stale eq $sTRUE) {
		    _REMOVE_CACHED_FILE($cached_file_path) or
			croak("Couldn't remove cached file $cached_file_path");
		}

	    # otherwise fetch the object and return a copy

	    } else {
		$cloned_object =
              _CLONE( $object, $self->get_persistence_mechanism() );
	    }

	# If we want stale data...

	} else {
	
	    # and the cache item is indeed stale...

	    if (_S_SHOULD_EXPIRE($expires_at)) {
		
		# fetch the object and return a copy
		$cloned_object =
              _CLONE( $object, $self->get_persistence_mechanism() );

	    }
	}
    }

    return $cloned_object;
}

# ------------------------------------------------------------------------------

# removes a key and value from the cache, it always succeeds, even if
# the key or value doesn't exist

sub remove
{
    my ($self, $identifier) = @_;

    defined($identifier) or
      croak("identifier required");

    my $unique_key = _BUILD_UNIQUE_KEY($identifier);

    my $cached_file_path = $self->_get_cached_file_path($unique_key);

    _REMOVE_CACHED_FILE($cached_file_path) or
	croak("couldn't remove cached file $cached_file_path");

    return $sSUCCESS;
}

# ------------------------------------------------------------------------------

# take an human readable identifier, and create a unique key from it

sub _BUILD_UNIQUE_KEY
{
    my ($identifier) = @_;

    defined($identifier) or
	croak("identifier required");

    my $unique_key = md5_hex($identifier) or
	croak("couldn't build unique key for identifier $identifier");

    return $unique_key;
}

# ------------------------------------------------------------------------------

# Check to see if a directory exists and is writable, or if a prefix
# directory exists and we can write to it in order to create
# subdirectories.  _VERIFY_DIRECTORY( $self->_get_namespace_path() )
# == $sSUCCESS should be checked every time the cache key, username,
# or namespace is changed.

sub _VERIFY_DIRECTORY
{
    my ($directory) = @_;

    defined($directory) or
      croak("directory required");

    # If the directory doesn't exist, crawl upwards until we find a file or
    # directory that exists
    while (defined $directory && !-e $directory)
    {
      $directory = _GET_PARENT_DIRECTORY($directory);
    }

    return $sFAILURE unless defined $directory;

    return $sSUCCESS if -d $directory && -w $directory;

    return $sFAILURE;
}

# ------------------------------------------------------------------------------

# find the parent directory of a directory. Returns undef if there is no
# parent

sub _GET_PARENT_DIRECTORY
{
  my ($directory) = @_;

  defined($directory) or
    croak("directory required");

  my @directories = splitdir($directory);
  pop @directories;

  return undef unless @directories;

  return catdir(@directories);
}

# -----------------------------------------------------------------------------

# create a directory with optional mask, building subdirectories as needed. be
# sure to call _VERIFY_DIRECTORY before calling this function

sub _CREATE_DIRECTORY
{
    my ($directory, $mask) = @_;

    defined($directory) or
      croak("directory required");

    my $old_mask;

    if (defined $mask)
    {
      $old_mask = umask;
      umask($mask);
    }

    $directory = _UNTAINT_FILE_PATH($directory);

    mkpath ($directory, 0, 0777);

    croak("Couldn't create directory: $directory: $!")
      unless -d $directory;

    umask($old_mask) if defined $mask;

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# read in the object frozen in the specified file (absolute path).
# returns a reference to the object, or undef if the object can not be
# found or can not be unserialized

sub _READ_OBJECT_DATA
{
    my ($cached_file_path) = @_;

    defined($cached_file_path) or
      croak("cached file path required");

    my $frozen_object_data = undef;

    if (-f $cached_file_path) {
        $frozen_object_data = _READ_FILE($cached_file_path);
    } else {
        return;
    }

    if (!$frozen_object_data) {
        return;
    }


    # Get the cache persistence mechanism. Searching upwards for the cache
    # description file is a bit of a hack, but it's much better than
    # passing the persistence mechanism value through the call chain.

    my $cache_key = _SEARCH_FOR_CACHE_KEY($cached_file_path);

    die "Couldn't find cache key directory"
      unless defined $cache_key;

    my $cache_description = _READ_CACHE_DESCRIPTION( $cache_key );

    return undef unless defined $cache_description;

    # if the $frozed_object_data is corrupted, thaw will return undef
    my $thawed_data = _UNSERIALIZE( $frozen_object_data,
      $cache_description->{'Persistence Mechanism'}, $cache_key );


    return $thawed_data;
}

# -----------------------------------------------------------------------------

# Look up the directory hierarchy for the cache description file,
# which is in the cache key directory.

sub _SEARCH_FOR_CACHE_KEY
{
    my ($directory) = @_;

    defined($directory) or
      croak("directory required");

    my $file = _BUILD_PATH($directory,$sCACHE_DESCRIPTION_FILENAME);

    # If the cache description file isn't in the current directory,
    # crawl upwards
    while (defined $directory && !-e $file)
    {
      $directory = _GET_PARENT_DIRECTORY($directory);
      $file = _BUILD_PATH($directory,$sCACHE_DESCRIPTION_FILENAME)
        if defined $directory;
    }

    return $directory;
}

# -----------------------------------------------------------------------------

# remove an object from the cache

sub _REMOVE_CACHED_FILE
{
    my ($cached_file_path) = @_;

    defined($cached_file_path) or
      croak("cached file path required");


    # cached_file_path may be tainted

    $cached_file_path = _UNTAINT_FILE_PATH($cached_file_path);


    # Is there any way to do this atomically?

    if (-f $cached_file_path) {

	# We don't catch the error, because this may fail if two
	# processes are in a race and try to remove the object

	unlink($cached_file_path);

    }

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# clear all objects in this instance's namespace

sub clear
{
    my ($self) = @_;

    my $namespace_path = $self->_get_namespace_path();

    $namespace_path = _UNTAINT_FILE_PATH($namespace_path);

    return $sSUCCESS unless -e $namespace_path;

    _RECURSIVELY_REMOVE_DIRECTORY($namespace_path) or
	croak("Couldn't clear namespace: $!");

    return $sSUCCESS;
}


# -----------------------------------------------------------------------------

# iterate over all the objects in this instance's namespace and delete
# those that have expired

sub purge
{
    my ($self) = @_;

    my $namespace_path = $self->_get_namespace_path();

    finddepth(\&_PURGE_FILE_WRAPPER, $namespace_path);

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# used with the Find::Find::find routine, this calls _PURGE_FILE on
# each file found

sub _PURGE_FILE_WRAPPER
{
    my $file_path = $File::Find::name;

    $file_path = _UNTAINT_FILE_PATH($file_path);

    my $file = (splitpath($file_path))[2];

    # Don't purge the cache description file
    if (-f $file && $file ne $sCACHE_DESCRIPTION_FILENAME) {
	_PURGE_FILE($file_path);
    } else {
	return;
    }
}

# -----------------------------------------------------------------------------

# if the file specified has expired, remove it from the cache. (path
# is absolute)

sub _PURGE_FILE
{
    my ($cached_file_path) = @_;

    defined($cached_file_path) or
      croak("cached file path required");

    my $object_data = _READ_OBJECT_DATA($cached_file_path);

    if ($object_data) {
	
	my $expires_at = $object_data->{expires_at};

	if (_S_SHOULD_EXPIRE($expires_at)) {
	    _REMOVE_CACHED_FILE($cached_file_path) or
		croak("Couldn't remove cached file $cached_file_path");
	}
	
    }

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# determine whether an object should expire

sub _S_SHOULD_EXPIRE
{
    my ($expires_at, $time) = @_;

    defined($expires_at) or
      croak("expires_at required");

    # time is optional

    $time = $time || time();

    if ($expires_at == $sEXPIRES_NOW) {
	return $sTRUE;
    } elsif ($expires_at == $sEXPIRES_NEVER) {
	return $sFALSE;
    } elsif ($time >= $expires_at) {
	return $sTRUE;
    } else {
	return $sFALSE;
    }
}

# -----------------------------------------------------------------------------

# reduce this namespace to a given size. (the size does not count the
# space occupied by the cache description file.)


sub reduce_size
{
    my ($self, $new_size) = @_;

    $new_size >= 0 or
	croak("size >= 0 required");

    my $namespace_path = $self->_get_namespace_path();

    while ($self->size() > $new_size) {

	my $victim_file = _CHOOSE_VICTIM_FILE($namespace_path);

	if (!$victim_file) {
	    warn("Couldn't reduce size to $new_size\n");
	    return $sFAILURE;
	}

	_REMOVE_CACHED_FILE($victim_file) or
	    croak("Couldn't remove cached file $victim_file");
    }

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# reduce the entire cache size to a given size. (the size does not
# count the space occupied by the cache description files.)

sub REDUCE_SIZE
{
    my ($new_size, $cache_key) = @_;

    $new_size >= 0 or
	croak("size >= 0 required");

    $cache_key = $cache_key || _BUILD_DEFAULT_CACHE_KEY();

    while (SIZE() > $new_size) {
	
	my $victim_file = _CHOOSE_VICTIM_FILE($cache_key);
	
      if (!defined($victim_file)) {
          warn("Couldn't reduce size to $new_size\n");
          return $sFAILURE;
      }

	_REMOVE_CACHED_FILE($victim_file) or
	    croak("Couldn't remove cached file $victim_file");
    }

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# Choose a "victim" cache object to remove starting from the argument
# directory. (This directory should be either the cache key path or
# some subdirectory of it.) The returned file is determined in this
# order: (1) the one with the closest expiration, (2) the least recently
# accessed one, (3) undef if there are no cache files.

sub _CHOOSE_VICTIM_FILE
{
    my ($root_directory) = @_;

    defined($root_directory) or
      croak("root directory required");

    # Look for the file to delete with the nearest expiration

    my ($nearest_expiration_path, $nearest_expiration_time) =
	_RECURSIVE_FIND_NEAREST_EXPIRATION($root_directory);

    return $nearest_expiration_path if defined $nearest_expiration_path;

    # If there are no files with expirations, get the least recently
    # accessed one

    my ($latest_accessed_path, $latest_accessed_time) =
	_RECURSIVE_FIND_LATEST_ACCESSED($root_directory);

    return $latest_accessed_path if defined $latest_accessed_path;

    return undef;
}

# -----------------------------------------------------------------------------

# Recursively searches a cache namespace for the cache object with the
# nearest expiration. Returns undef if no cache object with an
# expiration time could be found.

sub _RECURSIVE_FIND_NEAREST_EXPIRATION
{
    my ($directory) = @_;

    defined($directory) or
      croak("directory required");

    my $best_nearest_expiration_path = undef;

    my $best_nearest_expiration_time = undef;

    $directory = _UNTAINT_FILE_PATH($directory);

    opendir(DIR, $directory) or
	croak("Couldn't open directory $directory: $!");

    my @dirents = readdir(DIR);

    foreach my $dirent (@dirents) {

	next if $dirent eq '.' or $dirent eq '..';

	my $nearest_expiration_path_candidate = undef;

	my $nearest_expiration_time_candidate = undef;

	my $path = _BUILD_PATH($directory, $dirent);

	if (-d $path) {

	    ($nearest_expiration_path_candidate,
	     $nearest_expiration_time_candidate) =
		 _RECURSIVE_FIND_NEAREST_EXPIRATION($path);

	} else {

	    my $object_data;

	    $object_data = _READ_OBJECT_DATA_WITHOUT_MODIFICATION($path);
		
	    my $expires_at = $object_data->{expires_at};

	    $nearest_expiration_path_candidate = $path;

	    $nearest_expiration_time_candidate = $expires_at;

	}

	
	next unless defined $nearest_expiration_path_candidate;

	next unless defined $nearest_expiration_time_candidate;

	# Skip this file if it doesn't have an expiration time.

	next if $nearest_expiration_time_candidate == $sEXPIRES_NEVER;

	# if this is the first candidate, they're automatically the
	# best, otherwise they have to beat the best

	if ((!defined $best_nearest_expiration_time) or
	    ($best_nearest_expiration_time >
	     $nearest_expiration_time_candidate)) {

	    $best_nearest_expiration_path =
		$nearest_expiration_path_candidate;

	    $best_nearest_expiration_time =
		$nearest_expiration_time_candidate;
	}

    }

    closedir(DIR);

    return ($best_nearest_expiration_path, $best_nearest_expiration_time);
}

# -----------------------------------------------------------------------------

# read in object data without modifying the access time. returns a
# reference to the object, or undef if the object could not be read

sub _READ_OBJECT_DATA_WITHOUT_MODIFICATION
{
    my ($path) = @_;

    defined($path) or
      croak("path required");

    $path = _UNTAINT_FILE_PATH($path);

    my ($file_access_time, $file_modified_time) = (stat($path))[8,9];

    my $object_data_ref = _READ_OBJECT_DATA($path);
	
    utime($file_access_time, $file_modified_time, $path);

    return $object_data_ref;
}

# -----------------------------------------------------------------------------

# Recursively searches a cache namespace for the cache object with the
# latest access time. Recursively searches for the file with the
# latest access time, starting at the directory supplied as an
# argument. Returns the path to the last accessed file and the last
# accessed time. Returns (undef,undef) if there is not at least one
# file in the directory hierarchy below and including the argument
# directory.

sub _RECURSIVE_FIND_LATEST_ACCESSED
{
    my ($directory) = @_;

    defined($directory) or
      croak("directory required");

    my $best_latest_accessed_path = undef;

    my $best_latest_accessed_time = undef;

    $directory = _UNTAINT_FILE_PATH($directory);

    opendir(DIR, $directory) or
	croak("Couldn't open directory $directory: $!");

    my @dirents = readdir(DIR);

    foreach my $dirent (@dirents) {

	next if $dirent eq '.' or $dirent eq '..';
	next if $dirent eq $sCACHE_DESCRIPTION_FILENAME;

	my $latest_accessed_path_candidate = undef;

	my $latest_accessed_time_candidate = undef;

	my $path = _BUILD_PATH($directory, $dirent);

	if (-d $path) {

	    ($latest_accessed_path_candidate,
	     $latest_accessed_time_candidate) =
		 _RECURSIVE_FIND_LATEST_ACCESSED($path);

	} else {

	    my $last_accessed_time = (stat($path))[8];

	    $latest_accessed_path_candidate = $path;

	    $latest_accessed_time_candidate = $last_accessed_time;

	}

	next unless defined $latest_accessed_path_candidate;

	next unless defined $latest_accessed_time_candidate;

	# if this is the first candidate, they're automatically the
	# best, otherwise they have to beat the best

	if ((!defined $best_latest_accessed_time) or
	    ($best_latest_accessed_time >
	     $latest_accessed_time_candidate)) {

	    $best_latest_accessed_path =
		$latest_accessed_path_candidate;

	    $best_latest_accessed_time =
		$latest_accessed_time_candidate;

	}
    }

    closedir(DIR);

    return ($best_latest_accessed_path, $best_latest_accessed_time);
}

# -----------------------------------------------------------------------------

# recursively descend to get an estimate of the memory consumption for
# this namespace, ignoring space occupied by the cache description
# file.  returns 0 if the cache doesn't appear to exist

sub size
{
    my ($self) = @_;

    my $namespace_path = $self->_get_namespace_path();

    return 0 unless -e $namespace_path;

    return _RECURSIVE_DIRECTORY_SIZE($namespace_path);
}

# -----------------------------------------------------------------------------

# find the path to the cached file, taking into account the identifier and
# namespace.

sub _get_cached_file_path
{
    my ($self,$unique_key) = @_;

    defined($unique_key) or
      croak("unique key required");

    my $namespace_path = $self->_get_namespace_path();

    my $cache_depth = $self->get_cache_depth();

    my (@path_prefix) = _EXTRACT_PATH_PREFIX($unique_key, $cache_depth);

    my $cached_file_path = _BUILD_PATH($namespace_path);

    foreach my $path_element (@path_prefix) {

	$cached_file_path = _BUILD_PATH($cached_file_path, $path_element);

    }

    $cached_file_path = _BUILD_PATH($cached_file_path, $unique_key);

    return $cached_file_path;
}

# -----------------------------------------------------------------------------

# build the path to the cached file in the file system, taking into account
# the identifier, namespace, and cache depth.

sub _build_cached_file_path
{
    my ($self,$unique_key) = @_;

    defined($unique_key) or
      croak("unique key required");

    my $cached_file_path = $self->_get_cached_file_path($unique_key);

    # $cached_file_path has the directory & file. remove the file.
    my $cached_file_directory = _GET_PARENT_DIRECTORY($cached_file_path);

    _CREATE_DIRECTORY($cached_file_directory,0);

    return $cached_file_path;
}

# -----------------------------------------------------------------------------

# return a list of the first $cache_depth letters in the $identifier

sub _EXTRACT_PATH_PREFIX
{
    my ($unique_key, $cache_depth) = @_;

    defined($unique_key) or
      croak("unique key required");

    defined($cache_depth) or
      croak("cache depth required");

    my @path_prefix;

    for (my $i = 0; $i < $cache_depth; $i++) {
	push (@path_prefix, substr($unique_key, $i, 1));
    }

    return @path_prefix;
}

# -----------------------------------------------------------------------------

# represent a path in canonical form, and check for illegal characters

sub _BUILD_PATH
{
    my (@elements) = @_;

    if (grep (/\.\./, @elements)) {
	croak("Illegal path characters ..");
    }

    my $path = File::Spec->catfile(@elements);

    return $path;
}

# -----------------------------------------------------------------------------

# read in a file. returns a reference to the data read

sub _READ_FILE
{
    my ($filename) = @_;

    my $data_ref;

    defined($filename) or
	croak("filename required");

    $filename = _UNTAINT_FILE_PATH($filename);

    open(FILE, $filename) or
	croak("Couldn't open $filename for reading: $!");

    # In case the user stores binary data
    binmode FILE;

    local $/ = undef;

    $$data_ref = <FILE>;

    close(FILE);

    return $data_ref;
}

# -----------------------------------------------------------------------------

# write a file atomically

sub _WRITE_FILE
{
    my ($filename, $data_ref, $mode, $new_umask) = @_;

    defined($filename) or
	croak("filename required");

    defined($data_ref) or
      croak("data reference required");

    defined($mode) or
      croak("mode required");

    # Prepare the name for taint checking

    $filename = _UNTAINT_FILE_PATH($filename);

    # Change the umask if necessary

    my $old_umask = umask if $new_umask;

    umask($new_umask) if $new_umask;

    # Create a temp filename

    my $temp_filename = "$filename.tmp$$";

    open(FILE, ">$temp_filename") or
	croak("Couldn't open $temp_filename for writing: $!\n");

    # Use binmode in case the user stores binary data

    binmode(FILE);

    chmod($mode, $filename);

    print FILE $$data_ref;

    close(FILE);

    rename ($temp_filename, $filename) or
      croak("Couldn't rename $temp_filename to $filename");

    umask($old_umask) if $old_umask;

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# clear all objects in all namespaces

sub CLEAR
{
    my ($cache_key) = @_;

    $cache_key = $cache_key || _BUILD_DEFAULT_CACHE_KEY();

    if (!-d $cache_key) {
	return $sSUCCESS;
    }

    # [Should this use the _UNTAINT_FILE_PATH routine?]
    $cache_key = _UNTAINT_FILE_PATH($cache_key);

    _RECURSIVELY_REMOVE_DIRECTORY($cache_key) or
	croak("Couldn't clear cache");

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# purge all objects in all namespaces that have expired

sub PURGE
{
    my ($cache_key) = @_;

    # [Should this use the _UNTAINT_FILE_PATH routine?]
    $cache_key = _UNTAINT_FILE_PATH($cache_key);

    $cache_key = $cache_key || _BUILD_DEFAULT_CACHE_KEY();

    if (!-d $cache_key) {
	return $sSUCCESS;
    }

    finddepth(\&_PURGE_FILE_WRAPPER, $cache_key);

    return $sSUCCESS;
}

# -----------------------------------------------------------------------------

# get an estimate of the total memory consumption of the cache,
# ignoring space occupied by cache description files. returns 0 if the
# cache doesn't appear to exist

sub SIZE
{
    my ($cache_key) = @_;

    return 0 unless -e $cache_key;

    return _RECURSIVE_DIRECTORY_SIZE($cache_key);
}

# -----------------------------------------------------------------------------

# walk down a directory structure and total the size of the files
# contained therein. Doesn't count the size of the cache description
# file

sub _RECURSIVE_DIRECTORY_SIZE
{
    my ($directory) = @_;

    defined($directory) or
	croak("directory required");

    my $size = 0;

    $directory = _UNTAINT_FILE_PATH($directory);

    opendir(DIR, $directory) or
	croak("Couldn't open directory $directory: $!");

    my @dirents = readdir(DIR);

    foreach my $dirent (@dirents) {

	next if $dirent eq '.' or $dirent eq '..';

	my $path = _BUILD_PATH($directory, $dirent);

	if (-d $path) {
	    $size += _RECURSIVE_DIRECTORY_SIZE($path);
	} else {
      # Don't count the cache description file
	    $size += -s $path if $dirent ne $sCACHE_DESCRIPTION_FILENAME;
	}

    }

    closedir(DIR);

    return $size;
}

# -----------------------------------------------------------------------------

# Find the username of the person running the process in an OS
# independent way

sub _FIND_USERNAME
{
    my ($self) = @_;

    my $username;

    my $success = eval {
	my $effective_uid = $>;
	$username = getpwuid($effective_uid);	
    };

    if ($success and $username) {
	return $username;
    } else {
	return $sDEFAULT_USERNAME;
    }
}

# -----------------------------------------------------------------------------


# Untaint a path to a file

sub _UNTAINT_FILE_PATH
{
    my ($file_path) = @_;

    return _UNTAINT_STRING($file_path, $sUNTAINTED_FILE_PATH_REGEX);
}



# Untaint a string

sub _UNTAINT_STRING
{
    my ($string, $untainted_regex) = @_;

    defined($untainted_regex) or
	croak("untainted regex required");

    defined($string) or
	croak("string required");

    my ($untainted_string) = $string =~ /$untainted_regex/;

    if (!defined $untainted_string || $untainted_string ne $string) {
	warn("String $string contains possible taint");
    }

    return $untainted_string;
}


# -----------------------------------------------------------------------------

# Returns the default root of the cache under the OS dependent temp dir

sub _BUILD_DEFAULT_CACHE_KEY
{
    my $tmpdir = tmpdir() or
	croak("No tmpdir on this system.  Bugs to the authors of File::Spec");

    my $default_cache_key = _BUILD_PATH($tmpdir, $sDEFAULT_CACHE_KEY);

    return $default_cache_key;
}


# -----------------------------------------------------------------------------

# Remove a directory starting at the root


sub _RECURSIVELY_REMOVE_DIRECTORY
{
  my ($root) = @_;

  -d $root or
    croak("$root is not a directory");

  opendir(DIR, $root) or
    croak("Couldn't open directory $root: $!");

  my @dirents = readdir(DIR);

  closedir(DIR) or
    croak("Couldn't close directory $root: $!");

  foreach my $dirent (@dirents) {

    next if $dirent eq '.' or $dirent eq '..';

    my $path_to_dirent = "$root/$dirent";

    $path_to_dirent = _UNTAINT_FILE_PATH($path_to_dirent);

    if (-d $path_to_dirent) {
      _RECURSIVELY_REMOVE_DIRECTORY($path_to_dirent);
    } else {
      unlink($path_to_dirent) or
	croak("Couldn't unlink($path_to_dirent): $!\n");
    }

  }

  rmdir($root) or
    croak("Couldn't rmdir $root: $!");
}


# -----------------------------------------------------------------------------

# Get whether or not we automatically remove stale data from the cache
# on retrieval

sub get_auto_remove_stale
{
    my ($self) = @_;

    return $self->{_auto_remove_stale};
}

# -----------------------------------------------------------------------------

# Set whether or not we automatically remove stale data from the cache
# on retrieval

sub set_auto_remove_stale
{
    my ($self, $auto_remove_stale) = @_;

    defined($auto_remove_stale) or
	croak("\$File::Cache::sTRUE (i.e. 1) or " .
	      "\$File::Cache::sFALSE (i.e. 0) required");

    $self->{_auto_remove_stale} = $auto_remove_stale;
}

# -----------------------------------------------------------------------------

# Get the root of this cache on the filesystem

sub get_cache_key
{
    my ($self) = @_;

    my $cache_key = $self->{_cache_key};

    return $cache_key;
}

# -----------------------------------------------------------------------------

# Set the root of this cache on the filesystem

sub set_cache_key
{
    my ($self, $cache_key) = @_;

    defined($cache_key) or
      croak("cache key required");

    $self->{_cache_key} = $cache_key;

    # We don't verify the new directory if this function is called
    # during cache creation
    if ( (caller(1))[3] ne 'File::Cache::new')
    {
      _VERIFY_DIRECTORY( $self->_get_namespace_path() ) == $sSUCCESS or
	  croak("Can not build cache at " . $self->_get_namespace_path() .
	        ". Check directory permissions.");
    }
}

# -----------------------------------------------------------------------------

# Get the root of this user's path

sub _get_user_path
{
    my ($self) = @_;

    my $cache_key = $self->get_cache_key();
    my $username = $self->get_username();

    my $user_path = _BUILD_PATH($cache_key, $username);

    return $user_path;
}

# -----------------------------------------------------------------------------

# Get the root of this namespace's path

sub _get_namespace_path
{
    my ($self) = @_;

    my $user_path = $self->_get_user_path();
    my $namespace = $self->get_namespace();

    my $namespace_path = _BUILD_PATH($user_path, $namespace);

    return $namespace_path;
}

# -----------------------------------------------------------------------------

# Get the namespace for this cache instance (within the entire cache)

sub get_namespace
{
    my ($self) = @_;

    return $self->{_namespace};
}

# -----------------------------------------------------------------------------

# Set the namespace for this cache instance (within the entire cache)

sub set_namespace
{
    my ($self, $namespace) = @_;

    defined($namespace) or
	croak("namespace required");

    $self->{_namespace} = $namespace;

    # We don't verify the new directory if this function is called
    # during cache creation
    if ( (caller(1))[3] ne 'File::Cache::new')
    {
      _VERIFY_DIRECTORY( $self->_get_namespace_path() ) == $sSUCCESS or
	  croak("Can not build cache at " . $self->_get_namespace_path() .
	        ". Check directory permissions.");
    }
}

# -----------------------------------------------------------------------------

# Get the global expiration value for the cache

sub get_global_expires_in
{
    my ($self) = @_;

    return $self->{_global_expires_in};
}

# -----------------------------------------------------------------------------

# Set the global expiration value for the cache

sub set_global_expires_in
{
    my ($self, $global_expires_in) = @_;

    ($global_expires_in > 0) ||
	($global_expires_in == $sEXPIRES_NEVER) ||
	    ($global_expires_in == $sEXPIRES_NOW) or
		croak("\$global_expires_in must be > 0," .
		      "\$sEXPIRES_NOW, or \$sEXPIRES_NEVER");

    $self->{_global_expires_in} = $global_expires_in;
}

# -----------------------------------------------------------------------------

# Get the creation time for a cache object. Returns undef if the value
# is not in the cache

sub get_creation_time
{
    my ($self, $identifier) = @_;

    my $unique_key = _BUILD_UNIQUE_KEY($identifier);

    my $cached_file_path = $self->_get_cached_file_path($unique_key);

    my $object_data;

    $object_data =
      _READ_OBJECT_DATA($cached_file_path);

    if ($object_data) {

	return $object_data->{created_at};
	
    } else {
	
        return undef;
	
    }
}

# -----------------------------------------------------------------------------

# Get the expiration time for a cache object. Returns undef if the
# value is not in the cache

sub get_expiration_time
{
    my ($self, $identifier) = @_;

    my $unique_key = _BUILD_UNIQUE_KEY($identifier);

    my $cached_file_path = $self->_get_cached_file_path($unique_key);

    my $object_data;

    $object_data =
      _READ_OBJECT_DATA($cached_file_path);

    if ($object_data) {
	
	return $object_data->{expires_at};
	
    } else {
	
        return undef;
	
    }
}

# -----------------------------------------------------------------------------

# Get the username associated with this cache

sub get_username
{
    my ($self) = @_;

    return $self->{_username};
}

# -----------------------------------------------------------------------------

# Set the username associated with this cache

sub set_username
{
    my ($self, $username) = @_;

    defined($username) or
	croak("username required");

    $self->{_username} = $username;

    # We don't verify the new directory if this function is called
    # during cache creation
    if ( (caller(1))[3] ne 'File::Cache::new')
    {
      _VERIFY_DIRECTORY( $self->_get_namespace_path() ) == $sSUCCESS or
	  croak("Can not build cache at " . $self->_get_namespace_path() .
	        ". Check directory permissions.");
    }
}

# -----------------------------------------------------------------------------

# Gets the filemode for files created within the cache

sub get_filemode
{
    my ($self) = @_;

    return $self->{_filemode};
}

# -----------------------------------------------------------------------------

# Sets the filemode for files created within the cache

sub set_filemode
{
    my ($self, $filemode) = @_;

    defined ($filemode) or
	croak("filemode required");

    $self->{_filemode} = $filemode;
}

# -----------------------------------------------------------------------------

# Gets the max cache size.

sub get_max_size
{
    my ($self) = @_;

    return $self->{_max_size};
}

# -----------------------------------------------------------------------------

# Sets the max cache size.

sub set_max_size
{
    my ($self, $max_size) = @_;

    ($max_size > 0) || ($max_size == $sNO_MAX_SIZE) or
	croak("Invalid cache size.  " .
	      "Must be either \$sNO_MAX_SIZE or greater than zero");

    $self->{_max_size} = $max_size;

    # Reduce the size if necessary.
    if ($max_size != $sNO_MAX_SIZE) {
      $self->reduce_size($max_size);
    }
}

# -----------------------------------------------------------------------------

# Gets the cache depth

sub get_cache_depth
{
    my ($self) = @_;

    return $self->{_cache_depth};
}

# -----------------------------------------------------------------------------

# Sets the cache depth

sub set_cache_depth
{
    my ($self, $cache_depth) = @_;

    ($cache_depth >= 0) or
      croak("Invalid cache depth. Must be greater than zero");

    $self->{_cache_depth} = $cache_depth;
}

# -----------------------------------------------------------------------------

# Gets the persistence mechanism

sub get_persistence_mechanism
{
    my ($self) = @_;

    return $self->{_persistence_mechanism};
}

# -----------------------------------------------------------------------------

# Sets the persistence mechanism.

sub set_persistence_mechanism
{
    my ($self, $persistence_mechanism) = @_;

    defined ($persistence_mechanism) or
	croak("persistence mechanism required");

    # We don't clear the cache if this function is called during cache
    # creation
    if ( (caller(1))[3] ne 'File::Cache::new')
    {
      $self->clear();
    }

    ($persistence_mechanism eq 'Storable') ||
      ($persistence_mechanism eq 'Data::Dumper') or
	  croak("Peristence mechanism must be either " .
          \"Storable\" or \"Data::Dumper\"");

    $self->{_persistence_mechanism} = $persistence_mechanism;
}


1;


__END__


=head1 NAME

File::Cache - Share data between processes via filesystem

=head1 NOTE

Use of File::Cache is now discouraged in favor of the new Cache::Cache
project, also available on CPAN.  Cache::Cache offers all of the
functionality of File::Cache, as well as integrating the functionality
of IPC::Cache and a number of new features.  You can view the
Cache::Cache project page at:

  http://sourceforge.net/projects/perl-cache/

=head1 DESCRIPTION

B<File::Cache> is a perl module that implements an object storage
space where data is persisted across process boundaries via the
filesystem.

File::Cache builds a cache in the file system using a multi-level
directory structure that looks like this:

  <CACHE_KEY>/<USERNAME>/<NAMESPACE>/[D1]/[D2]/.../<OBJECTS>

CACHE_KEY is the location of the root level of the cache. The cache
key defaults to <TMPDIR>/File::Cache, where <TMPDIR> is the temporary
directory on your system. USERNAME is the user identifier. This value
defaults to the userid, if it can be determined from the system, or
"nobody" if it can not. <NAMESPACE> defaults to "_default". D1, D2,
etc. are subdirectories that are created to hold the cache objects.
The number subdirectories depends on the I<cache_depth> value, which
defaults to 0. Objects are stored in the cache using a method which
depends on the I<persistence_mechanism> value.


=head1 SYNOPSIS

 use File::Cache;

 # create a cache in the default namespace, where objects
 # do not expire

 my $cache = new File::Cache();

 # create a user-private cache in the specified
 # namespace, where objects will expire in one day, and
 # will automatically be removed from the cache.

 my $cache = new File::Cache( { namespace  => 'MyCache',
                                expires_in => 86400,
                                filemode => 0600 } );

 # create a public cache in the specified namespace,
 # where objects will expire in one day, but will not be
 # removed from the cache automatically.

 my $cache = new File::Cache( { namespace  => 'MyCache',
                                expires_in => 86400,
                                username => 'shared_user',
                                auto_remove_stale => 0,
                                filemode => 0666 } );

 # create a cache readable by the user and the user's
 # group in the specified namespace, where objects will
 # expire in one day, but may be removed from the cache
 # earlier if the size becomes more than a megabyte. Also,
 # request that the cache use subdirectories to increase
 # performance of large number of objects

 my $cache = new File::Cache( { namespace  => 'MyCache',
                                expires_in => 86400,
                                max_size => 1048576,
                                username => 'shared_user',
                                filemode => 0660,
			        cache_depth => 3 } );

 # store a value in the cache (will expire in one day)

 $cache->set("key1", "value1");

 # retrieve a value from the cache

 $cache->get("key1");

 # retrieve a stale value from the cache.
 # (Undefined behavior if auto_remove_stale is 1)

 $cache->get_stale("key1");

 # store a value that expires in one hour

 $cache->set("key2", "value2", 3600);

 # reduce the cache size to 3600 bytes

 $cache->reduce_size(3600);

 # clear this cache's contents

 $cache->clear();

 # delete all namespaces from the filesystem

 File::Cache::CLEAR();

=head2 TYPICAL USAGE

A typical scenario for this would be a mod_perl or perl CGI
application.  In a multi-tier architecture, it is likely that a trip
from the front-end to the database is the most expensive operation,
and that data may not change frequently.  Using this module will help
keep that data on the front-end.

Consider the following usage in a mod_perl application, where a
mod_perl application serves out images that are retrieved from a
database.  Those images change infrequently, but we want to check them
once an hour, just in case.

my $imageCache = new Cache( { namespace => 'Images',
                              expires_in => 3600 } );

my $image = $imageCache->get("the_requested_image");

if (!$image) {

    # $image = [expensive database call to get the image]

    $imageCache->set("the_requested_image", $image);

}

That bit of code, executed in any instance of the mod_perl/httpd
process will first try the filesystem cache, and only perform the
expensive database call if the image has not been fetched before, has
timed out, or the cache has been cleared.

The current implementation of this module automatically removes
expired items from the cache when the get() method is called and the
auto_remove_stale setting is true.  Automatic removal does not occur
when the set() method is called, which means that the cache can become
polluted with expired items if many items are stored in the cache for
short periods of time, and are rarely accessed. This is a design
decision that favors efficiency in the common case, where items are
accessed frequently. If you want to limit cache growth, see the
max_size option, which will automatically shrink the cache when the
set() method is called. (max_size is unaffected by the value of
auto_remove_stale.)

Be careful that you call the purge method periodically if
auto_remove_stale is 0 and max_size has its default value of unlimited
size. In this configuration, the cache size will be a function of the
number of items inserted into the cache since the last purge. (i.e. It
can grow extremely large if you put lots of different items in the
cache.)

=head2 METHODS

=over 4

=item B<new(\%options)>

Creates a new instance of the cache object.  The constructor takes a
reference to an options hash which can contain any or all of the
following:

=over 4

=item $options{namespace}

Namespaces provide isolation between objects.  Each cache refers to
one and only one namespace.  Multiple caches can refer to the same
namespace, however.  While specifying a namespace is not required, it
is recommended so as not to have data collide.

=item $options{expires_in}

If the "expires_in" option is set, all objects in this cache will be
cleared in that number of seconds.  It can be overridden on a
per-object basis.  If expires_in is not set, the objects will never
expire unless explicitly set.

=item $options{cache_key}

The "cache_key" is used to determine the underlying filesystem
namespace to use.  In typical usage, leaving this unset and relying on
namespaces alone will be more than adequate.

=item $options{username}

The "username" is used to explicitely set the username. This is useful
for cases where one wishes to share a cache among multiple users. If
left unset, the value will be the current user's username. (Also see
$options{filemode}.)  Note that the username is not used to set
ownership of the cache files -- the i.e. the username does not have to
be a user of the system.

=item $options{filemode}

"filemode" specifies the permissions for cache files. This is useful
for cases where one wishes to share a cache among multiple users. If
left unset, the value will be "u", indicating that only the current
user can read an write the cache files. See the filemode() method
documentation for the specification syntax.

=item $options{max_size}

"max_size" specifies the maximum size of the cache, in bytes.  Cache
objects are removed during the set() operation in order to reduce the
cache size before the new cache value is added. See the reduce_size()
documentation for the cache object removal policy. The max_size will be
maintained regardless of the value of auto_remove_stale. The default is
$File::Cache::sNO_MAX_SIZE, which indicates that the cache has no
maximum size.

=item $options(auto_remove_stale}

"auto_remove_stale" specifies that the cache should remove expired
objects from the cache when they are requested.

=item $options(cache_depth}

"cache_depth" specifies the depth of the subdirectories that should be
created.  This is helpful when especially large numbers of objects are
being cached (>1000) at once.  The optimal number of files per
directory is dependent on the type of filesystem, so some hand-tuning
may be required.

=back

=item B<set($identifier, $object, $expires_in)>

Adds an object to the cache.  set takes the following parameters:

=over 4

=item $identifier

The key the refers to this object.

=item $object

The object to be stored.  This any Storable or Data::Dumper-able
scalar or (optionally blessed) ref.  Filehandles and database handles
can not be stored, but most other references to objects can be.

=item $expires_in I<(optional)>

The object will be cleared from the cache in this number of seconds.
Overrides the default expires_in value for the cache.

=back

=item B<get($identifier)>

get retrieves an object from the cache.  If the object referred to by
the identifier exists in the cache and has not expired then then
object will be returned.  If the object does not exist then get will
return undef.  If the object does exist but has expired then get will
return undef and, depending on the setting of auto_remove_stale,
remove the expired object from the cache.

=over 4

=item $identifier

The key referring to the object to be retrieved.

=back

=item B<get_stale($identifier)>

get_stale retrieves objects that have expired from the cache.
Normally, expired objects are removed automatically and can not be
retrieved via get_stale, but if the auto_remove_stale option is set to
false, then expired objects will be left in the cache.  get_stale
returns undef if the object does not exist at all or has not expired
yet.

=over 4

=item $identifier

The key referring to the object to be retrieved.

=back

=item B<remove($identifier)>

Removes an object from the cache.

=over 4

=item $identifier

The key referring to the object to be removed.

=back

=item B<clear()>

Removes all objects from this cache.

=item B<purge()>

Removes all objects that have expired

=item B<size()>

Return an estimate of the disk usage of the current namespace.


=item B<reduce_size($size)>

Reduces the size of the cache so that it is below $size. Note that the
cache size is approximate, and may slightly exceed the value of $size.

Cache objects are removed in order of nearest expiration time, or
latest access time if there are no cache objects with expiration
times. (If there are a mix of cache objects with expiration times and
without, the ones with expiration times are removed first.)
reduce_size takes the following parameter:

=over 4

=item $size

The new target cache size.

=back

=item B<get_creation_time($identifier)>

Gets the time at which the data associated with $identifier was stored
in the cache. Returns undef if $identifier is not cached.

=over 4

=item $identifier

The key referring to the object to be retrieved.

=back


=item B<get_expiration_time($identifier)>

Gets the time at which the data associated with $identifier will
expire from the cache. Returns undef if $identifier is not cached.

=over 4

=item $identifier

The key referring to the object to be retrieved.

=back


=item B<get_global_expires_in()>

Returns the default number of seconds before an object in the cache expires.

=item B<set_global_expires_in($global_expires_in)>

Sets the default number of seconds before an object in the cache
expires.  set_global_expires_in takes the following parameter:

=over 4

=item $global_expires_in

The default number of seconds before an object in the cache expires.
It should be a number greater than zero, $File::Cache::sEXPIRES_NEVER,
or $File::Cache::sEXPIRES_NOW.

=back

=item B<get_auto_remove_stale()>

Returns whether or not the cache will automatically remove objects
after they expire.

=item B<set_auto_remove_stale($auto_remove_stale)>

Sets whether or not the cache will automatically remove objects after
they expire.  set_auto_remove_stale takes the following parameter:

=over 4

=item $auto_remove_stale

The new auto_remove_stale value.  If $auto_remove_stale is 1 or
$File::Cache::sTRUE, then the cache will automatically remove items
when they are being retrieved if they have expired.  If
$auto_remove_stale is 0 or $File::Cache::sFALSE, the cache will only
remove expired items when the purge() method is called, or if max_size
is set.  Note that the behavior of get_stale is undefined if
$auto_remove_stale is true.

=back


=item B<get_username()>

Returns the username that is currently being used to define the
location of this cache.

=item B<set_username($username)>

Sets the username that is currently being used to define the location
of this cache.  set_username takes the following parameter:

=over 4

=item $username

The username that is to be used to define the location of
this cache. It is not directly used to determine the ownership of the
cache files, but can be used to isolate sections of a cache for
different permissions.

=back


=item B<get_namespace()>

Returns the current cache namespace.

=item B<set_namespace($namespace)>

Sets the cache namespace. set_namespace takes the following parameter:

=over 4

=item $namespace

The namespace that is to be used by the cache. The namespace can be
used to isolate sections of a cache.

=back


=item B<get_max_size()>

Returns the current cache maximum size. $File::Cache::sNO_MAX_SIZE (the
default) indicates no maximum size.


=item B<set_max_size($max_size)>

Sets the maximum cache size. The cache size is reduced as necessary.
set_max_size takes the following parameter:

=over 4

=item $max_size

The maximum size of the cache. $File::Cache::sNO_MAX_SIZE indicates no
maximum size.

=back


=item B<get_cache_depth()>

Returns the current cache depth.

=item B<set_cache_depth($cache_depth)>

Sets the cache depth. Consider calling clear() before resetting the
cache depth in order to prevent inaccessible cache objects from
occupying disk space. set_cache_depth takes the following parameter:

=over 4

=item $cache_depth

The depth of subdirectories that are to be used by the cache when
storing cache objects.

=back


=item B<get_persistence_mechanism()>

Returns the current cache persistence mechanism.

=item B<set_persistence_mechanism($persistence_mechanism)>

Sets the cache persistence mechanism. This method clears the cache in
order to ensure consistent cache objects. set_persistence_mechanism takes the
following parameter:

=over 4

=item $persistence_mechanism

The persistence mechanism that is to be used by the cache. This
value can be either "Storable" or "Data::Dumper".

=back


=item B<get_filemode()>

Returns the filemode specification for newly created cache objects.

=item B<set_filemode($mode)>

Sets the filemode specification for newly created cache objects.
set_filemode takes the following parameter:

=over 4

=item $mode

The file mode -- a numerical mode identical to that used by
chmod(). See the chmod() documentation for more information.

=back


=item B<File::Cache::CLEAR($cache_key)>

Removes this cache and all the associated namespaces from the
filesystem.  CLEAR takes the following parameter:

=over 4

=item $cache_key I<(optional)>

Specifies the filesystem data to be cleared.  Needed only if a cache
was created with a non-standard cache key.

=back

=item B<File::Cache::PURGE($cache_key)>

Removes all objects in all namespaces that have expired.  PURGE takes
the following parameter:

=over 4

=item $cache_key I<(optional)>

Specifies the filesystem data to be purged.  Needed only if a cache
was created with a non-standard cache key.

=back

=item B<File::Cache::SIZE($cache_key)>

Roughly estimates the amount of memory in use.  SIZE takes the
following parameter:

=over 4

=item $cache_key I<(optional)>

Specifies the filesystem data to be examined.  Needed only if a cache
was created with a non-standard cache key.

=back

=item B<File::Cache::REDUCE_SIZE($size, $cache_key)>

Reduces the size of the cache so that it is below $size. Note that the
cache size is approximate, and may slightly exceed the value of $size.

Cache objects are removed in order of nearest expiration time, or
latest access time if there are no cache objects with expiration
times. (If there are a mix of cache objects with expiration times and
without, the ones with expiration times are removed first.)
REDUCE_SIZE takes the following parameters:

=over 4

=item $size

The new target cache size.

=item $cache_key I<(optional)>

Specifies the filesystem data to be examined.  Needed only if a cache
was created with a non-standard cache key.

=back

=back

=head1 BUGS

=over 4

=item *

The root of the cache namespace is created with global read/write
permissions.

=back

=head1 SEE ALSO

IPC::Cache, Storable, Data::Dumper

=head1 AUTHOR

DeWitt Clinton <dewitt@unto.net>, and please see the CREDITS file

=cut

