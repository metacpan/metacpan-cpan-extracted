package Hey::Cache;

our $VERSION = '0.01';

use Data::DumpXML qw(dump_xml);

=cut

=head1 NAME

Hey::Cache - Cache data multiple data structures

=head1 SYNOPSIS

  use Hey::Cache;
  
  my $cache = Hey::Cache->new(
      Namespace => 'WeatherApp2000',		# string (optional, default='default')
      CacheFile => 'fun_cache_file.xml',	# file path and name (optional, default='cache.xml')
      AutoSync => 1,				# boolean (optional, default=1)
      Expires => 300, 				# seconds (optional, default=86400)
  );
  
  $cache->set(
      Name => '98501',				# sets the name/key of the piece of data
      Value => { Temperature => 17,		# sets the data that you wish to cache
		 Condition => 'Rain',
		 High => 19,
		 Low => 7 },
      Expires => 600, 				# optional, defaults to what was set in the constructor above
  );

  $value = $cache->get( Name => '98501' ); 	# returns what you had set
  
  ... enough time passes (at least 10 minutes, according to the "Expires" value) ...
  
  $value = $cache->get( Name => '98501' ); 	# returns undef because it has expired
  
  $value = $cache->get( Name => '98501', Expires => 86400 );	# returns what you had set
								# because it is newer than a day

=head1 DESCRIPTION

Helps with regular data caching.  It's targetted for items that are in hash references, primarly.

=head2 new

  my $cache = Hey::Cache->new(
      Namespace => 'WeatherApp2000',		# string (optional, default='default')
      CacheFile => 'fun_cache_file.xml',	# file path and name (optional, default='cache.xml')
      AutoSync => 1,				# boolean (optional, default=1)
      Expires => 300, 				# seconds (optional, default=86400)
  );

=head3 Namespace [optional]

Default value is "default".

=head3 CacheFile [optional]

Default value is "cache.xml".

=head3 AutoSync [optional]

Default value is 1.

=head3 Expires [optional]

Default value is 86400 (24 hours).

=cut

sub new {
  my $class = shift;
  my %options = @_;
  my $self = {};
  bless($self, $class); # class-ify it.

  $self->{cacheFile} = $options{CacheFile} || 'cache.xml'; # define location of cache file
  $self->{autoSync} = (!defined($options{AutoSync}) ? 1 : ($options{AutoSync} ? 1 : 0)); # default to true
  $self->{expires} = int($options{Expires}) || 86400; # default to 24 hours
  $self->{namespace} = $options{Namespace} || $options{NameSpace} || 'default'; # which namespace to read/write

  use Data::DumpXML::Parser;
  my $parser = Data::DumpXML::Parser->new( Blesser => sub {} );

  $self->{cache} = {}; # preset to emptiness
  eval { $self->{cache} = $parser->parsefile($self->{cacheFile})->[0] }; # try to load cache file

  return $self;
}

=cut

=head2 sync

  $cache->sync;

Sends the data out to file.  If AutoSync is disabled (per call or in the constructor), this will manually save out 
your data to the cache file.  If AutoSync is enabled, this will happen automatically.

=cut

sub sync {
  my $self = shift || return undef;

  my $cacheOut = dump_xml($self->{cache}); # convert hashref data into XML structure
  if ($cacheOut) { # only if cacheOut is valid/existing (wouldn't want to wipe out our only cache with null)
    if (open(CACHEFH, '>'.$self->{cacheFile})) { # overwrite old cache file with new cache file
      print CACHEFH $cacheOut;
      close(CACHEFH);
      return 1;
    }
  }

  return undef;
}

=cut

=head2 get

  $weather = $cache->get( Name => '98501' );
  $weather = $cache->get( Name => '98501', Expires => 600 ); # override the expiration of the item

Gets the named data from the cache.

=head3 Name [required]

The name of the item to return.  This name was specified in the $cache->set function.

=head3 Expires [optional]

Age in number of seconds that would be acceptable.  If the cached item is newer than this value, it will return the item.  If the cached item is 
older than the value, it will return undef.

=cut

sub get {
  my $self = shift || return undef;
  my %options = @_;

  my $var = $options{Name} || return undef;

  (defined($self->{cache}->{$self->{namespace}})) || ($self->{cache}->{$self->{namespace}} = {}); # make sure this object exists

  my $obj = $self->{cache}->{$self->{namespace}}->{$var}; # get object

  return undef unless $obj; # no obj?  no problem.  your job is your credit!

  my $expires = int($options{Expires}) || $obj->{expires};

  if ($obj->{timestamp} + $expires <= time()) { # if expired
    return undef;
  }

  return $obj->{value}; # return object's value
}

=cut

=head2 set

  $value = { Temperature => 14, High => 15, Low => 12 };
  $cache->get( Name => '98501', Value => $value );

Set a value (scalar, hash, etc) by name into the cache.

=head3 Name [required]

The name.  Name of the item.  Use this as a key to get it later with the $cache->get function.

=head3 Value [required]

The value.  It works best if it's a reference to something, especially a hash.

=head3 Sync [optional]

Boolean.  Defaults to the value specified in the constructor, which defaults to true.

=head3 Timestamp [optional]

Defaults to the current time.  If it is useful to set a different timestamp, you can do it here.  This value is in epoch seconds.

=head3 Expires [optional]

Defaults to the value specified in the constructor.  Sets the expiration time for this item.  Expiration is stored with each item separately, so you 
can assign different expirations for different items.

=cut

sub set {
  my $self = shift || return undef;
  my %options = @_;

  my $var = $options{Name} || return undef;
  my $value = $options{Value};
  my $doSync = (defined($options{Sync}) ? $options{Sync} : $self->{autoSync});
  my $timestamp = $options{Timestamp} || $options{TimeStamp} || time();
  my $expires = int($options{Expires}) || $self->{expires};

  $self->{cache}->{$self->{namespace}}->{$var} = { # set the object in the cache
      timestamp => $timestamp,
      expires => $expires,
      value => $value,
  };

  $self->sync if $doSync; # write it out to file

  return 1;
}

=cut

=head1 AUTHOR

Dusty Wilson, E<lt>hey-cache-module@dusty.hey.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dusty Wilson E<lt>http://dusty.hey.nu/E<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
