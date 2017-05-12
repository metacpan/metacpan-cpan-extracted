#!/usr/bin/perl -w

package IPC::Cache;

use strict;
use Carp;
use IPC::ShareLite;
use Storable qw(freeze thaw dclone);
use vars qw($VERSION);
use Fcntl ':flock';

$VERSION = '0.02';

my $sEXPIRES_NOW = 0;
my $sEXPIRES_NEVER = -1;
my $sSUCCESS = 1;
my $sTRUE = 1;
my $sFALSE = 0;


# IPC::ShareLite converts a four character text string to the shared memory key

my $sDEFAULT_CACHE_KEY = "IPCC";


# if a namespace is not specified, use this as a default

my $sDEFAULT_NAMESPACE = "_default";



# create a new Cache object that can be used to persist
# data across processes

sub new 
{
    my ($proto, $options) = @_;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);


    # this instance will use the namespace specified or the default

    my $namespace = $options->{namespace} || $sDEFAULT_NAMESPACE;

    $self->{_namespace} = $namespace;


    # remember the expiration delta to be used for all objects if specified

    $self->{_expires_in} = $options->{expires_in} || $sEXPIRES_NEVER;

    # create a new share associated with the cache key

    my $cache_key = $options->{cache_key} || $sDEFAULT_CACHE_KEY;

    my $share = new IPC::ShareLite( -key => $cache_key, -create => 1  ) or
	croak("Couldn't create new IPC::ShareLite");

    # store the share for this instance

    $self->{_share} = $share;

    
    # atomically initialize the segment as frozen data

    $self->_lock();

    my $frozen_data = $self->_get_frozen_data();

    if (not $frozen_data) {
	my %data;
	$frozen_data = freeze(\%data);
	$self->_set_frozen_data($frozen_data);
    }

    $self->_unlock();


    return $self;
}


# store an object in the cache associated with the identifier

sub set 
{
    my ($self, $identifier, $object, $expires_in) = @_;

    $identifier or
	croak("identifier required");

    my $namespace = $self->{_namespace} or
	croak("namespace required");


    # expiration time is based on a delta from the current time
    # if expires_in is defined, the object will expire in that number of seconds from now
    #  else if expires_in is undefined, it will expire based on the global _expires_in
    
    my $expires_at;

    if (defined $expires_in) {
	$expires_at = time() + $expires_in;
    } elsif ($self->{_expires_in} ne $sEXPIRES_NEVER) {
	$expires_at = time() + $self->{_expires_in};
    } else {
	$expires_at = $sEXPIRES_NEVER;
    }

    # atomically add the new object to the cache in this instance's namespace

    $self->_lock();

    my $frozen_data = $self->_get_frozen_data();

    my %data = %{ thaw($frozen_data) };

    $data{$namespace}->{$identifier} = { object => $object, expires_at => $expires_at };

    $frozen_data = freeze(\%data);

    $self->_set_frozen_data($frozen_data);

    $self->_unlock();

    return $sSUCCESS;
}



# retrieve an object from the cache associated with the identifier

sub get 
{
    my ($self, $identifier) = @_;

    $identifier or
	croak("identifier required");
    
    my $namespace = $self->{_namespace} or
	croak("namespace required");

    # atomically (necessary for read-only?) check the cache for the specified object

    my $cloned_object = undef;

    $self->_lock();

    my $frozen_data = $self->_get_frozen_data();
    
    my %data = %{ thaw($frozen_data) };

    if (exists $data{$namespace}->{$identifier}) {

	my $object = $data{$namespace}->{$identifier}->{object};
	
	my $expires_at = $data{$namespace}->{$identifier}->{expires_at};
	
	# if the object has expired, remove it from the cache
	
	if (_s_should_expire($expires_at)) {
	    delete $data{$namespace}->{$identifier};
	} else {
	    # if the object is a reference, clone it before returning it (may be unnecessary?)
	    $cloned_object = (ref $object) ? dclone($object) : $object;
	}
    }
    
    $self->_unlock();

    return $cloned_object;
}


# clear all objects in this instance's namespace

sub clear 
{
    my ($self) = @_;

    my $namespace = $self->{_namespace};

    # atomically iterate over all of the key in this instance's namespace and delete them

    $self->_lock();

    my $frozen_data = $self->_get_frozen_data();
    
    my %data = %{ thaw($frozen_data) };

    foreach my $identifier (keys %{$data{$namespace}}) {
	delete $data{$namespace}->{$identifier};
    }

    $frozen_data = freeze(\%data);

    $self->_set_frozen_data($frozen_data);

    $self->_unlock();

    return $sSUCCESS;
}



# iterate over all the objects in this instance's namespace and delete those that have expired

sub purge
{
    my ($self) = @_;

    my $namespace = $self->{_namespace};

    my $time = time();

    # atomically iterate over all of the keys in this instance's namespace and delete those that have expired

    $self->_lock();

    my $frozen_data = $self->_get_frozen_data();
    
    my %data = %{ thaw($frozen_data) };

    my $namespace_ref = $data{$namespace};

    _s_purge_namespace($namespace_ref, $time);

    $frozen_data = freeze(\%data);
    
    $self->_set_frozen_data($frozen_data);

    $self->_unlock();

    return $sSUCCESS;
}



# purge expired objects from all namespaces associated with this cache key

sub _purge_all 
{
    my ($self) = @_;

    my $time = time();

    # atomically iterate over all of the keys in all of this instance's namespaces and delete those that have expired

    $self->_lock();

    my $frozen_data = $self->_get_frozen_data();

    my %data = %{ thaw($frozen_data) };
    
    foreach my $namespace (keys %data) {

	my $namespace_ref = $data{$namespace};

	_s_purge_namespace($namespace_ref, $time);

    }

    $frozen_data = freeze(\%data);

    $self->_set_frozen_data($frozen_data);

    $self->_unlock();

    return $sSUCCESS;    
}


# iterate over all the objects in the specified namespace and delete those that have expired

sub _s_purge_namespace
{
    my ($namespace_ref, $time) = @_;

    foreach my $identifier (keys %{$namespace_ref}) {
	
	my $expires_at = $namespace_ref->{$identifier}->{expires_at};

	# if the object has expired, remove it from the cache

	if (_s_should_expire($expires_at, $time)) {
	    delete $namespace_ref->{$identifier};
	}
    }
    
    return $sSUCCESS;    
}


# determine whether an object should expire

sub _s_should_expire
{
    my ($expires_at, $time) = @_;

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


# use this cache instance's frozen data to get an estimate of the memory consumption

sub _size 
{
    my ($self) = @_;

    $self->_lock();

    my $frozen_data = $self->_get_frozen_data();

    my $size = length $frozen_data;

    $self->_unlock();

    return $size;
}

# set the frozen data in the share

sub _set_frozen_data
{
    my ($self, $frozen_data) = @_;

    my $share = $self->{_share} or
	croak("Couldn't get share");

    $share->store($frozen_data);

    return $sSUCCESS;
}


# get the frozen data from the share 

sub _get_frozen_data 
{
    my ($self) = @_;

    my $share = $self->{_share} or
	croak("Couldn't get share");

    return $share->fetch();
}


# lock on the shared memory

sub _lock  
{
    my ($self) = @_;

    my $share = $self->{_share} or
	croak("Couldn't get share");

    $share->lock(LOCK_EX) or
	croak("Couldn't lock");

    return $sSUCCESS;
}


# unlock on the shared memory

sub _unlock 
{
    my ($self) = @_;

    my $share = $self->{_share} or
	croak("Couldn't get share");

    $share->unlock() or
	croak("Couldn't unlock");

    return $sSUCCESS;
}



# clear all objects in all namespaces and release the shared memory

sub CLEAR 
{
    my ($cache_key) = @_;

    $cache_key = $cache_key || $sDEFAULT_CACHE_KEY;

    my $tmp_share = new IPC::ShareLite( -key => $cache_key, -create => 1, -destroy => 1 ) or
	croak("Couldn't create new IPC::ShareLite");

    return $sSUCCESS;
}



# purge all objects in all namespaces that have expired

sub PURGE 
{
    my ($cache_key) = @_;

    $cache_key = $cache_key || $sDEFAULT_CACHE_KEY;

    # note that this will not destroy the shared memory segment when it finishes

    my $tmp_cache = new IPC::Cache( { cache_key => $cache_key } ) or
	croak("Couldn't instantiate new cache");

    $tmp_cache->_purge_all();

    return $sSUCCESS;
}


# get an estimate of the total memory consumption of the cache

sub SIZE 
{
    my ($cache_key) = @_;

    $cache_key = $cache_key || $sDEFAULT_CACHE_KEY;

    my $tmp_cache = new IPC::Cache( { cache_key => $cache_key } ) or
	croak("Couldn't instantiate new cache");

    return $tmp_cache->_size();
}


1;


__END__


=head1 NAME

B<IPC::Cache> - a perl module that implements an object storage space where data is persisted across process boundaries

=head1 SYNOPSIS

use IPC::Cache;

# create a cache in the specified namespace, where objects 
# will expire in one day
    
my $cache = new Cache( { namespace  => 'MyCache', 
                         expires_in => 86400 } );

# store a value in the cache (will expire in one day)

$cache->set("key1", "value1");

# retrieve a value from the cache

$cache->get("key1");

# store a value that expires in one hour

$cache->set("key2", "value2", 3600);

# clear this cache's contents

$cache->clear();

# delete all namespaces from shared memory

IPC::Cache::CLEAR();

=head1 DESCRIPTION

IPC::Cache is used to persist data across processes via shared memory.

=head2 TYPICAL USAGE

A typical scenario for this would be a mod_perl or perl CGI application.  In a
multi-tier architecture, it is likely that a trip from the front-end to the
database is the most expensive operation, and that data may not change frequently.  
Using this module will help keep that data on the front-end.
 
Consider the following usage in a mod_perl application, where a mod_perl application
serves out images that are retrieved from a database.  Those images change infrequently,
but we want to check them once an hour, just in case.
 
my $cache = new Cache( { namespace => 'Images', 
                         expires_in => 3600 } );
    
my $image = $imageCache->get("the_requested_image");

if (!$image) {

    # $image = [expensive database call to get the image]

    $cache->set("the_requested_image", $image);

}

That bit of code, executed in any instance of the mod_perl/httpd process will
first try the shared memory cache, and only perform the expensive database call
if the image has not been fetched before, has timed out, or the cache has been cleared.

=head2 METHODS

=over 4

=item B<new(\%options)>

Creates a new instance of the cache object.  The constructor takes a reference to an options 
hash which can contain any or all of the following:

=over 4

=item $options{namespace}

Namespaces provide isolation between objects.  Each cache refers to one and only one
namespace.  Multiple caches can refer to the same namespace, however.  While specifying
a namespace is not required, it is recommended so as not to have data collide.

=item $options{expires_in}

If the "expires_in" option is set, all objects in this cache will be cleared in that number
of seconds.  It can be overridden on a per-object basis.  If expires_in is not set, the objects
will never expire unless explicitly set.

=item $options{cache_key}

The "cache_key" is used to determine the underlying shared memory segment to use.  In typical
usage, leaving this unset and relying on namespaces alone will be more than adequate.

=back

=item B<set($identifier, $object, $expires_in)>

Adds an object to the cache.  set takes the following parameters:

=over 4

=item $identifier

The key the refers to this object.

=item $object

The object to be stored.

=item $expires_in I<(optional)>

The object will be cleared from the cache in this number of seconds.  Overrides 
the default expire_in for the cache.

=back

=item B<get($identifier)>

Retrieves an object from the cache.  get takes the following parameter:

=over 4

=item $identifier

The key referring to the object to be retrieved.

=back

=item B<clear()>

Removes all objects from this cache.

=item B<purge()>

Removes all objects that have expired

=item B<IPC::Cache::CLEAR($cache_key)>

Removes this cache and all the associated namespaces from shared memory.  CLEAR
takes the following parameter:

=over 4

=item $cache_key I<(optional)>

Specifies the shared memory segment to be cleared.  Needed only if a cache was created in
a non-standard shared memory segment.

=back

=item B<IPC::Cache::PURGE($cache_key)>

Removes all objects in all namespaces that have expired.  PURGE takes the following  
parameter:

=over 4

=item $cache_key I<(optional)>

Specifies the shared memory segment to be purged.  Needed only if a cache was created in
a non-standard shared memory segment.

=back

=item B<IPC::Cache::SIZE($cache_key)>

Roughly estimates the amount of memory in use.  SIZE takes the following  
parameter:

=over 4

=item $cache_key I<(optional)>

Specifies the shared memory segment to be examined.  Needed only if a cache was created in
a non-standard shared memory segment.

=back

=back

=head1 BUGS

=over 4

=item *

The SIZE method estimates only the size of the frozen data, not the actual shared memory usage

=item *

There is no mechanism for limiting the amount of memory in use

=back

=head1 AUTHOR

DeWitt Clinton <dclinton@eziba.com>

=cut
