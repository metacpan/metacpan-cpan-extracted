package IPC::SharedCache;

$IPC::SharedCache::VERSION = '1.3';

=pod 

=head1 NAME

IPC::SharedCache - a Perl module to manage a cache in SysV IPC shared memory.

=head1 SYNOPSIS

  use IPC::SharedCache;

  # the cache is accessed using a tied hash.
  tie %cache, 'IPC::SharedCache', ipc_key => 'AKEY',
                                  load_callback => \&load,
                                  validate_callback => \&validate;

  # get an item from the cache
  $config_file = $cache{'/some/path/to/some.config'};

=head1 DESCRIPTION

This module provides a shared memory cache accessed as a tied hash.

Shared memory is an area of memory that is available to all processes.
It is accessed by choosing a key, the ipc_key arguement to tie.  Every
process that accesses shared memory with the same key gets access to
the same region of memory.  In some ways it resembles a file system,
but it is not hierarchical and it is resident in memory.  This makes
it harder to use than a filesystem but much faster.  The data in
shared memory persists until the machine is rebooted or it is
explicitely deleted.

This module attempts to make shared memory easy to use for one
specific application - a shared memory cache.  For other uses of
shared memory see the documentation to the excelent module I use,
IPC::ShareLite (L<IPC::ShareLite>).

A cache is a place where processes can store the results of their
computations for use at a later time, possibly by other instances of
the application.  A good example of the use of a cache is a web
server.  When a web server receieves a request for an html page it
goes to the file system to read it.  This is pretty slow, so the web
server will probably save the file in memory and use the in memory
copy the next time a request for that file comes in, as long as the
file hasn't changed on disk.  This certainly speeds things up but web
servers have to serve multiple clients at once, and that means
multiple copies of the in-memory data.  If the web server uses a
shared memory cache, like the one this module provides, then all the
servers can use the same cache and much less memory is consumed.

This module handles all shared memory interaction using the
IPC::ShareLite module (version 0.06 and higher) and all data
serialization using Storable.  See L<IPC::ShareLite> and L<Storable>
for details.

=head1 MOTIVATION

This module began its life as an internal piece of HTML::Template (see
L<HTML::Template>).  HTML::Template has the ability to maintain a
cache of parsed template structures when running in a persistent
environment like Apache/mod_perl.  Since parsing a template from disk
takes a fair ammount of time this can provide a big performance gain.
Unfortunately it can also consume large ammounts of memory since each
web server maintains its own cache in its own memory space.

By using IPC::ShareLite and Storable (L<IPC::ShareLite> and
L<Storable>), HTML::Template was able to maintain a single shared
cache of templates.  The downside was that HTML::Template's cache
routines became complicated by a lot of IPC code.  My solution is to
break out the IPC cache mechanisms into their own module,
IPC::SharedCache.  Hopefully over time it can become general enough to
be usable by more than just HTML::Template.

=head1 USAGE

This module allows you to store data in shared memory and have it load
automatically when needed.  You can also define a test to screen
cached data for vailidty - if the test fails the data will be
reloaded.  This is useful for defining a max-age for cached data or
keeping cached data in sync with other resources.  In the web server
example above the validation test would look to see wether the file
had changed on disk.

To initialize this module you provide two callback subroutines.  The
first is the "load_callback".  This gets called when a user of the
cache requests an item from that is not yet present or is stale.  It
must return a reference to the data structure that will be stored in
the cache.  The second is the "validate_callback".  This gets called
on every cache access - its job is to check the cached object for
freshness (and/or some other validity, of course).  It must return
true or false.  When it returns true, the cached object is valid and
is retained in the cache.  When it returns false, the object is
re-loaded using the "load_callback" and the result is stored in the
cache.

To use the module you just request entries for the objects you need.
If the object is present in the cache and the "validate_callback"
returns true, then you get the object from the cache.  If not, the
object is loaded into the cache with the "load_callback" and returned
to you.

The cache can be used to store any perl data structures that can be
serialized by the Storable module.  See L<Storable> for details.

=head1 EXAMPLE

In this example a shared cache of files is maintained.  The
"load_callback" reads the file from disk into the cache and the
"validate_callback" checks its modification time using stat().  Note
that the "load_callback" stores information into the cached object
that "validate_callback" uses to check the freshness of the cache.

  # the "load_callback", loads the file from disk, storing its stat()
  # information along with the file into the cache.  The key in this
  # case is the filename to load.
  sub load_file {
    my $key = shift;

    open(FILE, $key) or die "Unable to open file named $key : $!");

    # note the modification time of this file - the 9th element of a
    # stat() is the modification time of the file.
    my $mtime = (stat($key))[9];

    # read the file into the variable $contents in 1k chunks
    my ($buffer, $contents);
    while(read(FILE, $buffer, 1024)) { $contents .= $buffer }
    close(FILE);

    # prepare the record to store in the cache
    my %record = ( mtime => $mtime, contents => $contents );
   
    # this record goes into the cache associated with $key, which is
    # the filename.  Notice that we're returning a reference to the
    # data structure here.
    return \%record;
  }

  # the "validate" callback, checks the mtime of the file on disk and
  # compares it to the cache value.  The $record is a reference to the
  # cached values array returned from load_file above.
  sub validate_file {
    my ($key, $record) = @_;

    # get the modification time out of the record
    my $stored_mtime = $record->{mtime};

    # get the current modification time from the filesystem - the 9th
    # element of a stat() is the modification time of the file.
    my $current_mtime = (stat($key))[9];

    # compare and return the appropriate result.
    if ($stored_mtime == $current_mtime) {
      # the cached object is valid, return true
      return 1;
    } else {
      # the cached object is stale, return false - load_callback will
      # be called to load it afresh from disk.
      return 0;
    }
  }

  # now we can construct the IPC::SharedCache object, using as a root
  # key 'SAMS'.

  tie %cache 'IPC::SharedCache' ipc_key => 'SAMS', 
                                load_callback => \&load_file,
                                validate_callback => \&validate_file;

  # fetch an object from the cache - if it's already in the cache and
  # validate_file() returns 1, then we'll get the cached file.  If it's
  # not in the cache, or validate_file returns 0, then load_file is
  # called to load the file into the cache.

  $config_file = $cache{'/some/path/to/some.config'};

=head1 DETAILS

The module implements a full tied hash interface, meaning that you can
use exists(), delete(), keys() and each().  However, in normal usage
all you'll need to do is to fetch values from the cache and possible
delete keys.  Just in case you were wondering, exists() doesn't
trigger a cache load - it returns 1 if the given key is already in the
cache and 0 if it isn't.  Similarily, keys() and each() operate on
key/value pairs already loaded into the cache.

The most important thing to realize is that there is no need to
explicitely store into the cache since the load_callback is called
automatically when it is necessary to load new data.  If you find
yourself using more than just "C<$data = $cache{'key'};>" you need to
make sure you really know what you're doing!

=head2 OPTIONS

There are a number parameters to tie that can be used to control the
behavior of IPC::SharedCache.  Some of them are required, and some art
optional. Here's a preview:

   tie %cache, 'IPC::SharedCache',

      # required parameters
      ipc_key => 'MYKI',
      load_callback => \&load,
      validate_callback => \&validate,

      # optional parameters
      ipc_mode => 0666,
      ipc_segment_size => 1_000_000,
      max_size => 50_000_000,
      debug => 1;

=head2 ipc_key (required)

This is the unique identifier for the particular cache.  It can be
specified as either a four-character string or an integer value.  Any
script that wishes to access the cache must use the same ipc_key
value.  You can use the ftok() function from IPC::SysV to generate
this value, see L<IPC::SysV> for details.  Using an ipc_key value
that's already in use by a non-IPC::SharedCache application will cause
an error.  Many systems provide a utility called 'ipcs' to examine
shared memory; you can use it to check for existing shared memory
usage before choosing your ipc_key.

=head2 load_callback and validate_callback (required)

These parameters both specify callbacks for IPC::SharedCache to use
when the cache gets a request for a key.  When you access the cache
(C<$data = $cache{$key}>), the cache first looks to see if it already
has an object for the given key.  If it doesn't, it calls the
load_callback and returns the result which is also stored in the
cache.  Alternately, if it does have the object in the cache it calls
the validate_callback to check if the object is still good.  If the
validate_callback returns true then object is good and is returned.
If the validate_callback returns false then the object is discarded
and the load_callback is called.

The load_callback recieves a single parameter - the requested key.  It
must return a reference to the data object be stored in the cache.
Returning something that is not a reference results in an error.

The validate_callback recieves two parameters - the key and the
reference to the stored object.  It must return true or false.

There are two ways to specify the callbacks.  The first is simply to
specify a subroutine reference.  This can be an anonymous subroutine
or a named one.  Example:

  tie %cache, 'IPC::SharedCache',
      ipc_key => 'TEST',
      load_callback => sub { ... },
      validate_callback => \&validate;

The second method allows parameters to be passed to the subroutine
when it is called.  This is done by specifying a reference to an array
of values, the first being the subroutine reference and the rest are
parameters for the subroutine.  The extra parameters are passed in
before the IPC::SharedCache provided parameters.  Example:

  tie %cache, 'IPC::SharedCache',
      ipc_key => 'TEST',
      load_callback => [\&load, $arg1, $arg2, $arg3]
      validate_callback => [\&validate, $self];

=head2 ipc_mode (optional)

This option specifies the access mode of the IPC cache.  It defaults
to 0666.  See L<IPC::ShareLite> for more information on IPC access
modes.  The default should be fine for most applications.

=head2 ipc_segment_size (optional)

This option allows you to specify the "chunk size" of the IPC shared
memory segments.  The default is 65,536, which is 64K.  This is a good
default and is very portable.  If you know that your system supports
larger IPC segment sizes and you know that your cache will be storing
large data items you might get better performance by increasing this
value.  

This value places no limit on the size of an object stored in the
cache - IPC::SharedCache automatically spreads large objects across
multiple IPC segments.

WARNING: setting this value too low (below 1024 in my experience) can
cause errors.

=head2 max_size (optional)

By setting this parameter you are setting a logical maximum to the
ammount of data stored in the cache.  When an item is stored in the
cache and this limit is exceded the oldest item (or items, as
necessary) in the cache will be deleted to make room.  This value is
specified in bytes.  It defaults to 0, which specifies no limit on the
size of the cache.  

Turning this feature on costs a fair ammount of performance - how much
depends largely on home much data is being stored into the cache
versus the size of max_cache.  In the worst case (where the max_size
is set much too low) this option can cause severe "thrashing" and
negate the benefit of maintaining a cache entirely.

NOTE: The size of the cache may in fact exceed this value - the
book-keeping data stored in the root segment is not counted towards
the total.  Also, extra padding imposed by the ipc_segment_size is not
counted.  This may change in the future if I learn that it would be
appropriate to count this padding as used memory.  It is not clear to
me that all IPC implementations will really waste this memory.

=head2 debug (optional)

Set this option to 1 to see a whole bunch of text on STDERR about what
IPC::SharedCache is doing.

=head1 UTILITIES

Two static functions are included in this package that are meant to be
used from the command-line.

=head2 walk

Walk prints out a detailed listing of the contents of a shared cache
at a given ipc_key.  It provides information the current keys stored
and a dump of the objects stored in each key.  Be warned, this can be
quite a lot of data!  Also, you'll need the Data::Dumper module
installed to use 'walk'.  You can get it on CPAN.

You can call walk like:

   perl -MIPC::SharedCache -e 'IPC::SharedCache::walk AKEY'"

Example:

   $ perl -MIPC::SharedCache -e 'IPC::SharedCache::walk MYKI'"
   *===================*
   IPC::SharedCache Root
   *===================*
   IPC_KEY: MYKI
   ELEMENTS: 3
   TOTAL SIZE: 99 bytes
   KEYS: a, b, c

   *=======*
   Data List
   *=======*

   KEY: a
   $CONTENTS = [
                 950760892,
                 950760892,
                 950760892
               ];


   KEY: b
   $CONTENTS = [
                 950760892,
                 950760892,
                 950760892
               ];


   KEY: c
   $CONTENTS = [
                 950760892,
                 950760892,
                 950760892
               ];

=head2 remove

This function totally removes an entire cache given an ipc_key value.
This should not be done to a running system!  Still, it's an
invaluable tool during development when flawed data may become 'stuck'
in the cache.

   $ perl -MIPC::SharedCache -e 'IPC::SharedCache::remove MYKI'

This function is silent and thus may be usefully called from within a
script if desired.

=head1 BUGS

I am aware of no bugs - if you find one please email me at
sam@tregar.com.  When submitting bug reports, be sure to include full
details, including the VERSION of the module and a test script
demonstrating the problem.

=head1 CREDITS

I would like to thank Maurice Aubrey for making this module possible
by producing the excelent IPC::ShareLite.

The following people have contributed patches, ideas or new features:

   Tim Bunce
   Roland Mas
   Drew Taylor
   Ed Loehr
   Maverick

Thanks everyone!

=head1 AUTHOR

Sam Tregar, sam@tregar.com (you can also find me on the mailing list
for HTML::Template at htmltmpl@lists.vm.com - join it by sending a
blank message to htmltmpl-subscribe@lists.vm.com).

=head1 LICENSE

IPC::SharedCache - a Perl module to manage a SysV IPC shared cache.
Copyright (C) 2000 Sam Tregar (sam@tregar.com)

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA


=cut


use strict;
use integer;

use Carp;
use Storable qw(freeze thaw);
use IPC::ShareLite qw(LOCK_EX LOCK_SH);

# a local cache to store the root share
use vars qw(%ROOT_SHARE_CACHE);

###############
# Constructor #
###############

sub TIEHASH {
  my $pkg = shift;
  my $self = bless({}, $pkg);  # create the object with bless
  my $options = {};
  $self->{options} = $options;

  _debug("TIEHASH : " . join(', ', @_)) if $options->{debug};

  # set default parameters in options hash
  %$options = (
               ipc_key => undef,
               ipc_mode => 0666,
               ipc_segment_size => 65536,
               load_callback => undef,
               validate_callback => undef,
               max_size => 0,
               debug => 0
              );
  
  # load in options supplied to new()
  croak("$pkg object created with odd number of option parameters - should be of the form option => value")
    if (@_ % 2);  
  for (my $x = 0; $x <= $#_; $x += 2) {
    croak("Unknown parameter $_[$x] in $pkg object creation.") 
      unless exists($options->{lc($_[$x])});
    $options->{lc($_[$x])} = $_[($x + 1)]; 
  }

  # make sure the required ones are here.
  foreach my $name (qw(ipc_key load_callback validate_callback)) {
    croak("$pkg object creation missing $name paramter.")
      unless defined($options->{$name});
  }
  
  require "Data/Dumper.pm" if $options->{debug};

  # initialize the cache root
  $self->_init_root;

  return $self;
}

##################
# Public Methods #
##################

# get a value from the cache
sub FETCH {
  my ($self, $key) = @_;
  my $options = $self->{options};
  my $ipc_key = $options->{ipc_key};

  _debug("FETCH: $key") if $options->{debug};

  # predeclare my variables to avoid spending any more time than
  # necessary inside shared locks.
  my ($root_record, $obj_ipc_key, $object);
   
  my $root = $ROOT_SHARE_CACHE{$ipc_key};
  confess("IPC::SharedCache : Undefined root share.")
    unless defined $root;
  
  _lock($root, LOCK_SH);

  # look in the cache map for a record matching this key
  $root_record = $self->_get_root_record($root);
  
  # if one exists, fetch the object from the cache
  $object = $self->_get_share_object($root_record->{'map'}{$key})
    if (exists $root_record->{'map'}{$key});

  # that's it - release the lock
  _unlock($root);
    
  # test its validity with _validate, if not get it with _load and
  # STORE it.   Do the same if it wasn't there.  If it passes, return it.
  if (defined($object)) {
    my $result;

    eval { $result = $self->_validate($key, $object); }; 
    croak("Error occured during validate_callback: $@") if $@;

    _debug("VALIDATE RETURN TRUE FOR: $key") if $options->{debug} and $result;
    _debug("VALIDATE RETURN FALSE FOR: $key") if $options->{debug} and not $result;
    return $object if $result;
  }

  # if it didn't pass, load it and STORE it.  Then return it.
  eval { $object = $self->_load($key); };
  croak("Error occured during load_callback: $@") if $@;

  $self->STORE($key, $object) if defined $object;
  return $object;
}

# store a value from the cache.  Generally not called from userland,
# but available none-the-less.
sub STORE {
  my ($self, $key, $object) = @_;
  my $options = $self->{options};
  my $ipc_key = $options->{ipc_key};

  _debug("STORE: $key $object") if $options->{debug};

  # freeze the block to store in the cache
  my $cache_block = freeze($object);

  # if max_size is set check to see if we can store this object at all,
  # return if not.
  if ($options->{max_size} and 
      length($cache_block) > $options->{max_size}) {
    _debug("STORE: $key is too large for cache max_size ($options->{max_size})") if $options->{debug};
    return;
  }

  # predeclare my variables to avoid spending any more time than
  # necessary inside shared locks.
  my ($root_record, $obj_ipc_key);
     
  my $root = $ROOT_SHARE_CACHE{$ipc_key};
  confess("IPC::SharedCache : Undefined root share.")
    unless defined $root;
  
  # get an exclusive lock on the root cache - may need to write 
  _lock($root, LOCK_EX);

  # look in the cache map for a record matching this key
  $root_record = $self->_get_root_record($root);
  
  # if a record already exists for this key, we can just go ahead and
  # store the new object into the old slot.
  my $share;
  if (exists $root_record->{'map'}{$key}) {
    # we've got a key, get the share and cache it
    $share = IPC::ShareLite->new('-key' => $root_record->{'map'}{$key},
                                 '-mode' => $options->{ipc_mode},
                                 '-size' => $options->{ipc_segment_size},
                                 '-create' => 0,
                                 '-destroy' => 0);
    confess("IPC::SharedCache: Unable to get shared cache block $root_record->{'map'}{$key} : $!") unless defined $share;  

    $root_record->{'size'} -= $root_record->{'length_map'}{$key};
    $root_record->{'size'} += length($cache_block);
    $root_record->{'length_map'}{$key} = length($cache_block);
  } else {
    # otherwise we need to find a new segment
    my $obj_ipc_key = $root_record->{'last_key'} || 1;
    for ( my $end = $obj_ipc_key + 10000 ; 
          $obj_ipc_key != $end ; 
          $obj_ipc_key++ ) {
      $share = IPC::ShareLite->new('-key' => $obj_ipc_key,
                                   '-mode' => $options->{ipc_mode},
                                   '-size' => $options->{ipc_segment_size},
                                   '-create' => 1,
                                   '-exclusive' => 1,
                                   '-destroy' => 0,
                                  );
      last if defined $share;
    }        
    croak("IPC::SharedCache : searched through 10,000 consecutive locations for a free shared memory segment, giving up : $!")
      unless defined $share;

    # update the root record and store
    $root_record->{'last_key'} = $obj_ipc_key;
    $root_record->{'map'}{$key} = $obj_ipc_key;
    $root_record->{'size'} += length($cache_block);
    $root_record->{'length_map'}{$key} = length($cache_block);
    push (@{$root_record->{'queue'}},$key);
  }

  # if we're over max_size, delete off the queue until we're below the
  # limit.  We need to inline the delete to keep track of stats and
  # delay the update.
  if ($options->{max_size}) {
    while($root_record->{'size'} > $options->{'max_size'} and
          scalar(@{$root_record->{'queue'}})) {
      my $delete_key = shift @{$root_record->{'queue'}};
      # delete the segment for this object
      { 
        my $share = IPC::ShareLite->new('-key' => $root_record->{map}{$delete_key},
                                        '-mode' => $options->{ipc_mode},
                                        '-size' => $options->{ipc_segment_size},
                                        '-create' => 0,
                                    '-destroy' => 1);
        confess("IPC::SharedCache: Unable to get shared cache block $root_record->{'map'}{$key} : $!") unless defined $share;
        # share is now deleted since destroy == 1 and $share goes out of scope
      }
      # remove the record members for this share
      $root_record->{'last_key'} = $root_record->{map}{$delete_key};
      delete($root_record->{'map'}{$delete_key});
      $root_record->{'size'} -= $root_record->{'length_map'}{$delete_key};
      delete($root_record->{'length_map'}{$delete_key});
    }
  }
      
  # store the block and the updated root record into the cache
  eval { $root->store(freeze($root_record)); };
  confess("IPC::SharedCache: Problem storing into root cache segment.  IPC::ShareLite error: $@") if $@;    

  eval { $share->store($cache_block); };
  confess("IPC::SharedCache: Problem storing into cache segment $root_record->{'map'}{$key}.  IPC::ShareLite error: $@") if $@;    

  # that's it - release the lock
  _unlock($root);

  # I suppose that chained assigments should work.
  return $object;
}

sub DELETE { 
  my ($self, $key) = @_;
  my $options = $self->{options};
  my $ipc_key = $options->{ipc_key};

  _debug("DELETE: $key") if $options->{debug};

  # predeclare my variables to avoid spending any more time than
  # necessary inside shared locks.
  my ($root_record, $obj_ipc_key);
   
  my $root = $ROOT_SHARE_CACHE{$ipc_key};
  confess("IPC::SharedCache : Undefined root share.")
    unless defined $root;
  
  # get an exclusive lock on the root cache
  _lock($root, LOCK_EX);

  # look in the cache map for a record matching this key
  $root_record = $self->_get_root_record($root);
    
  unless (exists $root_record->{'map'}{$key}) {
    _unlock($root);
    return 1;
  }
  $obj_ipc_key = $root_record->{'map'}{$key};

  # delete the segment for this object
  { 
    my $share = IPC::ShareLite->new('-key' => $obj_ipc_key,
                                    '-mode' => $options->{ipc_mode},
                                    '-size' => $options->{ipc_segment_size},
                                    '-create' => 0,
                                    '-destroy' => 1);
    confess("IPC::SharedCache: Unable to get shared cache block $root_record->{'map'}{$key} : $!") unless defined $share;
    # share is now deleted since destroy == 1 and $share goes out of scope
  }
  
  # remove the record members for this share
  $root_record->{'last_key'} = $obj_ipc_key;
  delete($root_record->{'map'}{$key});
  $root_record->{'size'} -= $root_record->{'length_map'}{$key};
  delete($root_record->{'length_map'}{$key});
  @{$root_record->{'queue'}} = grep {$_ ne $key } @{$root_record->{'queue'}};

  # store the block and the updated root record into the cache
  eval { $root->store(freeze($root_record)); };
  confess("IPC::SharedCache: Problem storing into root cache segment.  IPC::ShareLite error: $@") if $@;

  # that's it - release the lock
  _unlock($root);
  return 1;
}

sub EXISTS { 
  my ($self, $key) = @_;
  my $options = $self->{options};
  my $ipc_key = $options->{ipc_key};

  _debug("EXISTS: $key") if $options->{debug};

  # predeclare my variables to avoid spending any more time than
  # necessary inside shared locks.
  my ($root_record, $obj_ipc_key);
   
  my $root = $ROOT_SHARE_CACHE{$ipc_key};
  confess("IPC::SharedCache : Undefined root share.")
    unless defined $root;
  
  # get an exclusive lock on the root cache
  _lock($root, LOCK_SH);

  # look in the cache map for a record matching this key
  $root_record = $self->_get_root_record($root);
    
  _unlock($root);

  return 1 if (exists $root_record->{'map'}{$key});
  return 0;
} 

sub FIRSTKEY { 
  my ($self) = @_;
  my $options = $self->{options};
  my $ipc_key = $options->{ipc_key};

  _debug("FIRSTKEY") if $options->{debug};

  # predeclare my variables to avoid spending any more time than
  # necessary inside shared locks.
  my ($root_record, $obj_ipc_key, $first_key);
   
  my $root = $ROOT_SHARE_CACHE{$ipc_key};
  confess("IPC::SharedCache : Undefined root share.")
    unless defined $root;
  
  # get an exclusive lock on the root cache
  _lock($root, LOCK_SH);

  # look in the cache map for a record matching this key
  $root_record = $self->_get_root_record($root);

  # get the first key
  $first_key = $root_record->{'queue'}[0];
    
  _unlock($root);

  return $first_key;
}

sub NEXTKEY { 
  my ($self, $lastkey) = @_;
  my $options = $self->{options};
  my $ipc_key = $options->{ipc_key};

  _debug("NEXTKEY $lastkey") if $options->{debug};

  # predeclare my variables to avoid spending any more time than
  # necessary inside shared locks.
  my ($root_record, $obj_ipc_key, $next_key);
   
  my $root = $ROOT_SHARE_CACHE{$ipc_key};
  confess("IPC::SharedCache : Undefined root share.")
    unless defined $root;
  
  # get an exclusive lock on the root cache
  _lock($root, LOCK_SH);

  # look in the cache map for a record matching this key
  $root_record = $self->_get_root_record($root);

  # get the next key
  for(my $x = 0; $x < $#{$root_record->{'queue'}}; $x++) {
    $next_key = $root_record->{'queue'}[($x + 1)], last
      if ($root_record->{'queue'}[$x] eq $lastkey);
  }
    
  _unlock($root);

  return $next_key;
} 


sub CLEAR { 
  # implementation from Tie::Hash
  my $self = shift;
  my $options = $self->{options};
  my $key = $self->FIRSTKEY(@_);
  my @keys;

  _debug("CLEAR") if $options->{debug};

  while (defined $key) {
    push @keys, $key;
    $key = $self->NEXTKEY(@_, $key);
  }
  foreach $key (@keys) {
    $self->DELETE(@_, $key);
  }
}

####################
# Static Functions #
####################

# call like "perl -MIPC::SharedCache -e 'IPC::SharedCache::walk AKEY'"
sub walk {
  my ($key, $segment_size) = @_;
  $segment_size = 65536 unless defined($segment_size);
  print("Usage: IPC::SharedCache::list AKEY [segment_size]\n"), exit
    if (not defined($key) or scalar(@_) > 2);

  require "Data/Dumper.pm";
  
  # make sure the cache actually exists here
  my $test = IPC::ShareLite->new('-key' => $key,
                                 '-mode' => 0666,
                                 '-size' => $segment_size,
                                 '-create' => 0, 
                                 '-destroy' => 0);
  die "Unable to find a cache at key $key : $!" unless defined $test;

  my %self;
  tie %self, 'IPC::SharedCache',
    ipc_key => $key,
      ipc_segment_size => $segment_size,
        load_callback => sub {},
          validate_callback => sub {};

  my $root = $ROOT_SHARE_CACHE{$key};
  confess("IPC::SharedCache : Undefined root share.")
    unless defined $root;
  
  # get a shared lock on the root cache
  _lock($root, LOCK_SH);

  # look in the cache map for a record matching this key
  my $root_record = _get_root_record(\%self, $root);

  my $elements = scalar(keys(%{$root_record->{'map'}}));
  my $keys = join(', ', sort { $a <=> $b } keys(%{$root_record->{'map'}}));

  print STDERR <<END;
*===================*
IPC::SharedCache Root
*===================*
IPC_KEY: $key
ELEMENTS: $elements
TOTAL SIZE: $root_record->{size} bytes
KEYS: $keys

*=======*
Data List
*=======*

END

  foreach my $key (sort { $a <=> $b } keys(%{$root_record->{'map'}})) {
    my ($contents_block, $contents) = _get_share_object(\%self, $root_record->{'map'}{$key});
    $contents = Data::Dumper->Dump([$contents], 
                                   [qw($CONTENTS)]);
    print STDERR <<END;
KEY: $key
IPC_KEY: $root_record->{'map'}{$key}
$contents

END
  }

  # that's it - release the lock
  _unlock($root);
}

# call like "perl -MIPC::SharedCache -e 'IPC::SharedCache::remove AKEY'"
sub remove {
  my ($key, $segment_size) = @_;
  $segment_size = 65536 unless defined($segment_size);
  print("Usage: IPC::SharedCache::remove AKEY [segment_size]\n"), exit
    if (not defined($key) or scalar(@_) > 2);

  my %self;
  tie %self, 'IPC::SharedCache',
    ipc_key => $key,
      ipc_segment_size => $segment_size,
        load_callback => sub {},
          validate_callback => sub {};

  # remove all segments
  %self = ();

  # this has to come first - dangeling references to the root will
  # keep it from actually being deleted.
  delete($ROOT_SHARE_CACHE{$key});
  
  # delete the root segment
  { 
    my $share = IPC::ShareLite->new('-key' => $key,
                                    '-size' => $segment_size,
                                    '-create' => 0,
                                    '-destroy' => 1);
    confess("IPC::SharedCache: Unable to get shared cache block $key : $!") unless defined $share;
    # share is now deleted since destroy == 1 and $share goes out of scope
  }

  return;
}


#########################
# IPC Utility Functions #
#########################

# initialize the cache root
sub _init_root {
  my $self = shift;
  my $options = $self->{options};
  my $ipc_key = $options->{ipc_key};

  # do root initialization, check the cache first
  my $root = $ROOT_SHARE_CACHE{$ipc_key};
  return if defined $root;

  # try to get a handle on an existing root for this key
  $root = IPC::ShareLite->new('-key' => $ipc_key,
                              '-mode' => $options->{ipc_mode},
                              '-size' => $options->{ipc_segment_size},
                              '-create' => 0, 
                              '-destroy' => 0);
  if (defined $root) {
    $ROOT_SHARE_CACHE{$ipc_key} = $root;
    return;
  }

  # prepare empty root record for new root creation
  my $record = { 'map' => {},
                 'size' => 0,
                 'last_key' => 0,
                 'queue' => [],
               };
  my $record_block = freeze($record);  

  #print Data::Dumper->Dump([$record, $record_block], 
  #                         [qw($record $record_block)]), "\n"
  #                           if $options->{debug};

  # try to create it if that didn't work (and do initialization)
  $root = IPC::ShareLite->new('-key' => $options->{ipc_key},
                              '-mode' => $options->{ipc_mode},
                              '-size' => $options->{ipc_segment_size},
                              '-create' => 1, 
                              '-exclusive' => 1,
                              '-destroy' => 0);
  confess("IPC::SharedCache object initialization : Unable to initialize root ipc shared memory segment : $!") 
    unless defined($root);

  eval { $root->store($record_block); };
  confess("IPC::SharedCache object initialization : Problem storeing inital root cache record.  IPC::ShareLite error: $@") if $@;

  

  print STDERR "### IPC::SharedCache Debug ### ROOT INIT\n"
    if $options->{debug};

  # put the share into the local memory cache 
  $ROOT_SHARE_CACHE{$ipc_key} = $root;
}

# lock the root segment, specifying type of lock
sub _lock {
  my ($root, $type) = @_;

  # get a lock
  my $result = $root->lock($type);
  confess("IPC::SharedCache: Can't lock on root cache segment.") 
    unless defined $result;

  return 1;
}

# unlock the root segment
sub _unlock {
  my ($root) = @_;

  # get a lock
  my $result = $root->unlock();
  confess("IPC::SharedCache: Can't unlock root cache segment.") 
    unless defined $result;

  return 1;
}

# gets the root record given the root share - does no locking of its
# own.
sub _get_root_record {
  my ($self, $root) = @_;
  my ($root_block, $root_record);

  # fetch the root block
  eval { $root_block = $root->fetch(); };
  confess("IPC::SharedCache: Problem fetching root cache segment.  IPC::ShareLite error: $@") if $@;
  confess("IPC::SharedCache: Problem fetching root cache segment.  IPC::ShareLite error: $!") unless defined($root_block);
  
  # thaw the root block, recovering the cache map
  eval { $root_record = thaw($root_block) };
  confess("IPC::SharedCache: Invalid cache_map recieved from shared memory.  Perhaps this key is in use by another application?  Storable error: $@") if $@;
  confess("IPC::SharedCache: Invalid cache_map recieved from shared memory.  Perhaps this key is in use by another application?") unless ref($root_record) eq 'HASH';
      
  # look in the cache map for a record matching this key
  return $root_record;
}

# gets a cached object from a share - no locking, just a single atomic fetch.
sub _get_share_object {
  my ($self, $obj_ipc_key) = @_;
  my $options = $self->{options};

  # we've got a key, get the share and cache it
  my $share = IPC::ShareLite->new('-key' => $obj_ipc_key,
                                  '-mode' => $options->{ipc_mode},
                                  '-size' => $options->{ipc_segment_size},
                                  '-create' => 0,
                                  '-destroy' => 0);
  confess("IPC::SharedCache: Unable to get shared cache block $obj_ipc_key : $!") unless defined $share;
  
  # get the cache block
  my $cache_block;
  eval { $cache_block = $share->fetch(); };
  confess("IPC::SharedCache: Problem fetching cache segment $obj_ipc_key.  IPC::ShareLite error: $@") if $@;
    
  # pull out object data
  my $object;
  eval { $object = thaw($cache_block); };
  confess("IPC::SharedCache: Invalid cache object recieved from shared memory on key $obj_ipc_key.  Perhaps this key is in use by another application?  Storable error: $@") if $@;

  return($cache_block, $object)
    if (wantarray);
  return $object;
}


#############################
# General Utility Functions #
#############################

# wrapper to call validate_callback and return result
sub _validate {
  my ($self, $key, $object) = @_;
  my $validate_callback = $self->{options}{validate_callback};
  my $validate_type = ref($validate_callback);

  if ($validate_type eq 'CODE') {
    return $validate_callback->($key, $object);
  } elsif ($validate_type eq 'ARRAY') {
    my ($real_callback,@params) = @$validate_callback;
    if (ref($real_callback) eq 'CODE') {
      return $real_callback->(@params, $key, $object);
    } else {
      croak("IPC::SharedCache : validate_callback set to bad value - when set to an array the first element must be a CODE ref.");
    }
  } else {
    croak("IPC::SharedCache : validate_callback must be set to either a CODE ref or an ref to an array where the first element is a CODE ref and the rest are parameters.");
  }
}

# wrapper to call load_callback and return result
sub _load {
  my ($self, $key) = @_;
  my $load_callback = $self->{options}{load_callback};
  my $load_type = ref($load_callback);
  my $result;
  
  if ($load_type eq 'CODE') {
    return $load_callback->($key);
  } elsif ($load_type eq 'ARRAY') {
    my ($real_callback, @params) = @{$load_callback};
    if (ref($real_callback) eq 'CODE') {
      return $real_callback->(@params, $key);
    } else {
      croak("IPC::SharedCache : load_callback set to bad value - when set to an array the first element must be a CODE ref.");
    }
  } else {
    croak("IPC::SharedCache : load_callback must be set to either a CODE ref or an array where the first element is a CODE ref and the rest are extra parameters to the subroutine.");
  }
}

sub _debug {
  my ($msg) = @_;
  print STDERR "### IPC::SharedCache Debug ### $msg\n";
}

1;
__END__

=pod

=head1 AUTHOR

Sam Tregar, sam@tregar.com

=head1 SEE ALSO

perl(1).

=cut
