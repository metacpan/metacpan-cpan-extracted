package Mail::Mbox::MessageParser::MetaInfo;

use strict;
use Carp;

use Mail::Mbox::MessageParser;

use vars qw( $VERSION $_DEBUG @ISA );
use vars qw( $_CACHE %_CACHE_OPTIONS $UPDATING_CACHE );

@ISA = qw( Exporter );

$VERSION = sprintf "%d.%02d%02d", q/0.2.0/ =~ /(\d+)/g;

*_DEBUG = \$Mail::Mbox::MessageParser::_DEBUG;
*_dprint = \&Mail::Mbox::MessageParser::_dprint;
sub _dprint;

# The class-wide cache, which will be read and written when necessary. i.e.
# read when an folder reader object is created which uses caching, and
# written when a different cache is specified, or when the program exits, 
$_CACHE = {};

%_CACHE_OPTIONS = ();

$UPDATING_CACHE = 0;

#-------------------------------------------------------------------------------

sub _LOAD_STORABLE
{
  if (eval {require Storable})
  {
    import Storable;
    return 1;
  }
  else
  {
    return 0;
  }
}

#-------------------------------------------------------------------------------

sub SETUP_CACHE
{
  my $cache_options = shift;

  carp "Need file_name option" unless defined $cache_options->{'file_name'};

  return "Can not load " . __PACKAGE__ . ": Storable is not installed.\n"
    unless _LOAD_STORABLE();
  
  # Load Storable if we need to
  # See if the client is setting up a different cache
  if (exists $_CACHE_OPTIONS{'file_name'} &&
    $cache_options->{'file_name'} ne $_CACHE_OPTIONS{'file_name'})
  {
    _dprint "New cache file specified--writing old cache if necessary.";
    WRITE_CACHE();
    $_CACHE = {};
  }

  %_CACHE_OPTIONS = %$cache_options;

  _READ_CACHE();

  return 'ok';
}

#-------------------------------------------------------------------------------

sub CLEAR_CACHE
{
  unlink $_CACHE_OPTIONS{'file_name'}
    if defined $_CACHE_OPTIONS{'file_name'} && -f $_CACHE_OPTIONS{'file_name'};

  $_CACHE = {};
  $UPDATING_CACHE = 1;
}

#-------------------------------------------------------------------------------

sub _INITIALIZE_ENTRY
{
  my $file_name = shift;

  my @stat = stat $file_name;

  return 0 unless @stat;

  my $size = $stat[7];
  my $time_stamp = $stat[9];


  if (exists $_CACHE->{$file_name} &&
      (defined $_CACHE->{$file_name}{'size'} &&
       defined $_CACHE->{$file_name}{'time_stamp'} &&
       $_CACHE->{$file_name}{'size'} == $size &&
       $_CACHE->{$file_name}{'time_stamp'} == $time_stamp))
  {
    _dprint "Cache is valid";

    # TODO: For now, if we re-initialize, we start over. Fix this so that we
    # can use partial cache information.
    if ($UPDATING_CACHE)
    {
      _dprint "Resetting cache entry for \"$file_name\"\n";

      # Reset the cache entry for this file
      $_CACHE->{$file_name}{'size'} = $size;
      $_CACHE->{$file_name}{'time_stamp'} = $time_stamp;
      $_CACHE->{$file_name}{'emails'} = [];
      $_CACHE->{$file_name}{'modified'} = 0;
    }
  }
  else
  {
    if (exists $_CACHE->{$file_name})
    {
      _dprint "Size or time stamp has changed for file \"" .
        $file_name . "\". Invalidating cache entry";
    }
    else
    {
      _dprint "Cache is invalid: \"$file_name\" has not yet been parsed";
    }

    $_CACHE->{$file_name}{'size'} = $size;
    $_CACHE->{$file_name}{'time_stamp'} = $time_stamp;
    $_CACHE->{$file_name}{'emails'} = [];
    $_CACHE->{$file_name}{'modified'} = 0;

    $UPDATING_CACHE = 1;
  }
}

#-------------------------------------------------------------------------------

sub _ENTRY_STILL_VALID
{
  my $file_name = shift;

  return 0 unless exists $_CACHE->{$file_name} &&
    defined $_CACHE->{$file_name}{'size'} &&
    defined $_CACHE->{$file_name}{'time_stamp'} &&
    # Sanity check the cache to ensure we can at least determine the prologue
    # length.
    defined $_CACHE->{$file_name}{'emails'}[0]{'offset'};

  my @stat = stat $file_name;

  return 0 unless @stat;

  my $size = $stat[7];
  my $time_stamp = $stat[9];

  return ($_CACHE->{$file_name}{'size'} == $size &&
    $_CACHE->{$file_name}{'time_stamp'} == $time_stamp);
}

#-------------------------------------------------------------------------------

sub _READ_CACHE
{
  my $self = shift;

  return unless -f $_CACHE_OPTIONS{'file_name'};

  _dprint "Reading cache";

  # Unserialize using Storable
  local $@;

  eval { $_CACHE = retrieve($_CACHE_OPTIONS{'file_name'}) };

  if ($@)
  {
    $_CACHE = {};
    _dprint "Invalid cache detected, and will be ignored.";
    _dprint "Message from Storable module: \"$@\"";
  }
}

#-------------------------------------------------------------------------------

sub WRITE_CACHE
{
  # In case this is called during cleanup following an error loading
  # Storable
  return unless defined $Storable::VERSION;

  return if $UPDATING_CACHE;

  # TODO: Make this cache separate files instead of one big file, to improve
  # performance.
  my $cache_modified = 0;

  foreach my $file_name (keys %$_CACHE)
  {
    if ($_CACHE->{$file_name}{'modified'})
    {
      $cache_modified = 1;
      $_CACHE->{$file_name}{'modified'} = 0;
    }
  }

  unless ($cache_modified)
  {
    _dprint "Cache not modified, so no writing is necessary";
    return;
  }

  _dprint "Cache was modified, so writing is necessary";

  # The mail box cache may contain sensitive information, so protect it
  # from prying eyes.
  my $oldmask = umask(077);

  # Serialize using Storable
  store($_CACHE, $_CACHE_OPTIONS{'file_name'});

  umask($oldmask);

  $_CACHE->{$_CACHE_OPTIONS{'file_name'}}{'modified'} = 0;
}

#-------------------------------------------------------------------------------

# Write the cache when the program exits
sub END
{
  _dprint "Exiting and writing cache if necessary"
    if defined(&_dprint);

  WRITE_CACHE();
}

1;

__END__

# --------------------------------------------------------------------------

=head1 NAME

Mail::Mbox::MessageParser::MetaInfo - A cache for folder metadata

=head1 DESCRIPTION

This module implements a cache for meta-information for mbox folders. The
information includes such items such as the file position, the line number,
and the byte offset of the start of each email.

=head2 METHODS AND FUNCTIONS

=over 4

=item SETUP_CACHE(...)

  SETUP_CACHE( { 'file_name' => <cache file name> } );

  <cache file name> - the file name of the cache

Call this function once to set up the cache before creating any parsers. You
must provide the location to the cache file. There is no default value.

Returns an error string or 1 if there is no error.

=item CLEAR_CACHE();

Use this function to clear the cache and delete the cache file.  Normally you
should not need to clear the cache--the module will automatically update the
cache when the mailbox changes. Call this function after I<SETUP_CACHE>.


=item WRITE_CACHE();

Use this function to force the module to write the in-memory cache information
to the cache file. Normally you do not need to do this--the module will
automatically write the information when the program exits.


=item $ref = new( { 'file_name' => <mailbox file name>,
                    'file_handle' => <mailbox file handle>, });

    <file_name> - The full filename of the mailbox
    <file_handle> - An opened file handle for the mailbox

The constructor for the class takes two parameters. I<file_name> is the
filename of the mailbox. This will be used as the cache key, so it's important
that it fully defines the path to the mailbox. The I<file_handle> argument is
the opened file handle to the mailbox. Both arguments are required.

Returns a reference to a Mail::Mbox::MessageParser object, or a string
describing the error.

=back


=head1 BUGS

No known bugs.

Contact david@coppit.org for bug reports and suggestions.


=head1 AUTHOR

David Coppit <david@coppit.org>.


=head1 LICENSE

This code is distributed under the GNU General Public License (GPL) Version 2.
See the file LICENSE in the distribution for details.


=head1 HISTORY

This code was originally part of the grepmail distribution. See
http://grepmail.sf.net/ for previous versions of grepmail which included early
versions of this code.


=head1 SEE ALSO

Mail::Mbox::MessageParser

=cut
