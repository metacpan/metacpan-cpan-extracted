package MP3::PodcastFetch;

use strict;
use warnings;
use Carp 'croak';
use MP3::PodcastFetch::Feed;
use MP3::PodcastFetch::TagManager;

use LWP::UserAgent;
use HTTP::Status;
use URI::Escape;

use File::Spec;
use File::Basename 'basename';
use File::Path 'mkpath';
use IO::Dir;
use Digest::MD5 qw(md5_hex);
use Date::Parse;
use Cwd;

our $VERSION = '1.05';

=head1 NAME

MP3::PodcastFetch -- Fetch and manage a podcast subscription

=head1 SYNOPSIS

 use MP3::PodcastFetch;
 my $feed  = MP3::PodcastFetch->new(-base => '/tmp/podcasts',
                                    -rss  => 'http://www.npr.org/rss/podcast.php?id=500001'
                                    -rewrite_filename => 1,
                                    -upgrade_tag => 'auto');
 $feed->fetch_pods;
 print "fetched ",$feed->fetched," new podcasts\n";
 for my $file ($feed->fetched_files) {
    print $file,"\n";
 }

=head1 DESCRIPTION

This package provides a convenient and simple way of mirroring the
podcasts described by an RSS feed into a local directory. It was
written as the backend for the fetch_pods.pl script.

To use it, create an MP3::PodcastFetch object with the required
B<-base> and B<-rss> arguments. The podcasts listed in the RSS
subscription file located at the B<-rss> URL will be mirrored into one
or more subdirectories located beneath the path at B<-base>. One
subdirectory will be created for each channel specified by the
RSS. Additional new() arguments control optional features of this
module.

Once the object is created, call its fetch_pods() method to download
the RSS file, parse it, and mirror the subscribed podcasts locally.

=head1 METHODS

This module implements the following methods:

=cut

BEGIN {
  my @accessors = qw(base subdir override_channel_dir rss
		     max timeout mirror_mode verbose rewrite_filename upgrade_tags use_pub_date
		     keep_old playlist_handle playlist_base force_genre force_artist
		     force_album fetch_callback delete_callback env_proxy);

  for my $accessor (@accessors) {
eval <<END;
sub $accessor {
    my \$self = shift;
    my \$d    = \$self->{$accessor};
    \$self->{$accessor} = shift if \@_;
    return \$d;
}
END
  die $@ if $@;
  }
}

=head2 Constructor

 $feed = MP3::PodcastFetch->new(-base=>$base,-rss=>$url, [other args])

The new() method creates a new MP3::PodcastFetch object. Options are
as follows:

=over 4

=item -base

The base directory for all mirrored podcast files,
e.g. "/var/podcasts". Fetched podcasts files will be stored into
appropriately-named subdirectories of this location, one subdirectory
per channel. Additional subdirectory levels can be added using the
B<-subdirs> argument. This argument is required.

=item -override_channel_dir

Default is to use directory named after a channel title.  Specify
another directory instead.

=item -rss

The URL of the RSS feed to subscribe to. This is usually indicated in
web pages as a red "podcast" or "xml" icon. This argument is required.

=item -verbose

If true, print status messages to STDERR for each podcast file
attempted.

=item -env_proxy

If true, load proxy settings from *_proxy environment variables.

=item -max

Set the maximum number of podcast episodes to keep.

=item -keep_old

If true, keep old episodes and skip new ones if B<-max> is
exceeded. The default is to delete old episodes to make room for new
ones.

=item -timeout

How long (in seconds) to wait before timing out slow servers. Applies
to both the initial RSS feed fetching and mirroring individual podcast
episodes.

=item -mirror_mode

One of "exists" or "modified-since". The default, "exists", will cause
podcast episodes to be skipped if a like-named file already
exists. "modified-since" performs a more careful comparison with the
corresponding podcast episode on the remote server. The local file
will be refreshed if the remote server's version is more recent.

=item -rewrite_filename

If true, cryptic MP3 names will be replaced with long names based on
podcast episode title.

=item -upgrade_tag

Some podcast files have informative ID3 tags, but many
don't. Particularly annoying is the genre, which may be given as
"Speech", "Podcast", or anything else. The upgrade_tag option, if set
to a non-false value, will attempt to normalize the ID3 tags from the
information provided by the RSS feed information. Specifically, the
title will be set to the title of the podcast, the album will be set
to the title of the channel (e.g. "New York Times Front Page"), the
artist will be set to the channel author (e.g. "The New York Times"),
the year will be set to the publication date, the genre will be set to
"Podcast" and the comment will be set to the channel description. You
can change some of these values using the options "force_genre,"
"force_album," and "force_artist."

The value of upgrade_tag is one of:

 false     Don't mess with the ID3 tags
 id3v1     Upgrade the ID3 version 1 tag
 id3v2.3   Upgrade the ID3 version 2.3 tag
 id3v2.4   Upgrade the ID3 version 2.4 tag
 auto      Choose the best tag available

Depending on what optional Perl ID3 manipulation modules you have
installed, you may be limited in what level of ID3 tag you can update:

 Audio::TagLib            all versions through 2.4
 MP3::Tag                 all versions through 2.3
 MP3::Info                only version 1.0

Choosing "auto" is your best bet. It will dynamically find what Perl
modules you have installed, and choose the one that provides the most
recent tag version. Omit this argument, or set it to false, to prevent
any ID3 tag rewriting from occurring.

=item -force_genre, -force_artist, -force_album

If you have "upgrade_tag" set to a true value (and at least one
tag-writing module installed) then each podcast's ID3 tag will be
modified to create a consistent set of fields using information
provided by the RSS feed. The title will be set to the title of the
podcast, the album will be set to the title of the channel (e.g. "New
York Times Front Page"), the artist will be set to the channel author
(e.g. "The New York Times"), the year will be set to the publication
date, the genre will be set to "Podcast" and the comment will be set
to the channel description.

You can change some of these values using these three options:

 -force_genre     Change the genre to whatever you specify.
 -force_artist    Change the artist.
 -force_album     Change the album.

Note that if you use ID3v1 tagging (e.g. MP3::Info) then you must
choose one of the predefined genres; in particular, there is no genre
named "Podcast." You must force something else, like "Speech" instead.

=item -playlist_handle

A writeable filehandle on a previously-opened .m3u playlist file. The
playlist file must already have the "#EXTM3U" top line written into
it. The podcast fetch operation will write an appropriate item
description for each podcast episode it mirrors.

=item -playlist_base

If you are writing a playlist and mirroring the podcasts to a
removable medium such as an sdcard for later use with a portable music
player device, you will need to set this argument to the directory
path to each podcast file as it will appear to the music player. For
example, if you mount the medium at /mnt/sdcard and keep podcasts in
/mnt/sdcard/podcasts, then the B<-base> and B<-playlist_base> options
might look like this:

  -base          => '/mnt/sdcard/podcasts',
  -playlist_base => '/podcasts'

For Windows-based devices, you might have to specify a playlist_base
using Windows filesystem conventions.

=item -subdir

Ordinarily each podcast will be placed in a directory named after its
channel, directly underneath the directory specified by "base." If
this boolean is set to a partial path, then additional levels of
directory will be placed between the base and the channel
directory. For instance:

 -base    => '/tmp/podcasts',
 -subdir  => 'News/Daily',

Will place the channel's podcasts in '/tmp/podcasts/News/Daily/channel_name/'

=item -force_genre, -force_artist, -force_album

If B<-upgrade_tag> is set to true, then you can use these options to
force the genre, artist and/or album to desired hard-coded values. By
default, genre will be set to "Podcast", and artist and album will be
dynamically determined from information provided by the RSS feed, such
that the channel name becomes the album and the podcast author becomes
the artist.

=item -use_pub_date

If B<-use_pub_date> is set to true, then podcast files will have their
modification times set to match the publication time specified in the
RSS feed. Otherwise they will take retain the modification time they
carry on the site they are downloaded from.

=item -fetch_callback

If you provide a coderef to B<-fetch_callback> this routine will be
invoked on every file fetched immediately after the file is
created. It will be called with two arguments corresponding to the
MP3::PodcastFetch object, and the complete path to the fetched file:

   my $callback = sub {
       my ($feed,$filepath) = @_;
       print STDERR "$filepath successfully fetched\n";
   }

   $feed = MP3::PodcastFetch->new(-base           => $base,
                                  -rss            => $url,
                                  -fetch_callback => $callback);


=item -delete_callback

Similar to B<-fetch_callback> except that the passed coderef is called
on every deleted file immediately after the file is deleted.

=back

=cut

# arguments:
# -base             => base directory for podcasts, e.g. /var/podcasts
# -subdir           => subdirectory for this podcast, e.g. music
# -override_channel_dir            => directory to use instead of channel title
# -rss              => url of the RSS feed to read
# -max              => maximum number of episodes to keep
# -timeout          => timeout for URL requests
# -mirror_mode      => 'modified-since' (careful) or 'exists' (careless)
# -rewrite_filename => rewrite file name with podcast title
# -upgrade_tag      => upgrade tags to v2.4
# -force_{genre,artist,album}      => force set the genre, artist and/or album
# -keep_old         => keep old podcasts that are no longer in the RSS
# -playlist_handle  => file handle for playlist
# -playlist_base    => file system base to use for the playlists
# -verbose          => print status reports
# -env_proxy	    => load proxy settings from environment variables
# -use_pub_date     => set the modtime of the downloaded podcast file to the RSS item's pubdate
# -fetch_callback	=> subroutine to run for every fetched files
# -delete_callback	=> subroutine to run for every deleted files
#


sub new {
  my $class = shift;
  my %args  = @_;
  my $self = bless {},ref $class || $class;
  $self->base($args{-base}       || '/tmp/podcasts');
  $self->subdir($args{-subdir});
  $self->override_channel_dir($args{-override_channel_dir});
  $self->rss($args{-rss}         || croak 'please provide -rss argument');
  $self->max($args{-max}                             );
  $self->timeout($args{-timeout} || 30               );
  $self->mirror_mode($args{-mirror_mode} || 'exists' );
  $self->verbose($args{-verbose}                     );
  $self->env_proxy($args{-env_proxy}                 );
  $self->rewrite_filename($args{-rewrite_filename}   );
  $self->upgrade_tags($args{-upgrade_tag}            );
  $self->keep_old($args{-keep_old}                   );
  $self->playlist_handle($args{-playlist_handle}     );
  $self->playlist_base($args{-playlist_base}         );
  $self->force_genre($args{-force_genre}             );
  $self->force_artist($args{-force_artist}           );
  $self->force_album($args{-force_artist}            );
  $self->fetch_callback( $args{-fetch_callback} || 'none' );
  $self->delete_callback( $args{-delete_callback} || 'none' );
  $self->force_album($args{-force_artist}            );
  $self->use_pub_date($args{-use_pub_date}           );
  $self->{tabs} = 1;
  $self->{files_fetched} = [];
  $self->{files_deleted} = [];
  $self;
}

=head2 Read/write accessors

The following are read/write accessors (get and/or set the
corresponding option). Each takes the form:

 $old_value = $feed->accessor([$new_value])

Where $new_value is optional.

=over 4

=item $feed->base

=item $feed->subdir

=item $feed->override_channel_dir

=item $feed->rss

=item $feed->timeout

=item $feed->mirror_mode

=item $feed->verbose

=item $feed->env_proxy

=item $feed->rewrite_filename

=item $feed->upgrade_tags

=item $feed->keep_old

=item $feed->playlist_handle

=item $feed->playlist_base

=item $feed->force_genre

=item $feed->force_artist

=item $feed->force_album

=back

=head2 Common methods

The following methods are commonly used in end-user scripts:

=over 4

=item $feed->fetch_pods

Mirror the subscribed podcast episodes into the base directory
specified in new(). After calling it, use the fetched() and errors()
methods to find out how many podcasts were successfully mirrored and
whether there were any errors. Use the fetched_files() method to get
the names of the newly fetched podcasts.

=cut

sub fetch_pods {
  my $self = shift;
  my $url  = $self->rss or croak 'No URL!';
  my $parser = MP3::PodcastFetch::Feed->new($url) or croak "Couldn't create parser";
  $parser->timeout($self->timeout);
  $parser->env_proxy($self->env_proxy);
  my @channels = $parser->read_feed;
  $self->log("Couldn't read RSS for $url: ",$parser->errstr) unless @channels;
  $self->update($_) foreach @channels;
  1;
}

=item @files = $feed->fetched_files

This method will return the complete paths to each of the podcast
episodes successfully fetched by the proceeding call to fetch_pods().

=cut

sub fetched_files {
  return @{shift->{files_fetched}}
}

=item @files = $feed->deleted_files

This method will return the complete paths to each of the podcast
episodes successfully deleted by the proceeding call to fetch_pods().

=cut

sub deleted_files {
  return @{shift->{files_deleted}}
}

=item $feed->fetched

The number of episodes fetched/refreshed.

=item $feed->skipped

The number of episodes skipped.

=item $feed->deleted

The number of episodes deleted because they are either no longer
mentioned in the subscription file or exceed the per-feed limit.

=item $feed->errors

The number of episodes not fetched because of an error.

=back

=cut

sub fetched { shift->{stats}{fetched} ||= 0 }
sub errors  { shift->{stats}{error}   ||= 0 }
sub deleted { shift->{stats}{deleted} ||= 0 }
sub skipped { shift->{stats}{skipped} ||= 0 }

=head2 Internal Methods

These methods are intended for internal use cut can be overridden in
subclasses in order to change their behavior.

=over 4

=item $feed->update($channel)

Update all episodes contained in the indicated
MP3::PodcastFetch::Feed::Channel object (this object is generated by
podcast_fetch() in the course of downloading and parsing the RSS file.

=cut

sub update {
  my $self    = shift;
  my $channel = shift;
  my $title        = $channel->title;
  my $description  = $channel->description;
  my $dir          = $self->generate_directory($channel);
  my @items        = sort {$b->timestamp <=> $a->timestamp} grep {$_->url} $channel->items;
  my $total        = @items;

  # if there are more items than we want, then remove the oldest ones
  if (my $max = $self->max) {
    splice(@items,$max) if @items > $max;
  }

  $self->log("$title: $total podcasts available. Mirroring ",scalar @items,"...");
  {
    $self->{tabs}++; # for formatting
    $self->mirror($dir,\@items,$channel);
    $self->{tabs}--; # for formatting
  }
  1;
}

=item $feed->bump_fetched($value)

=item $feed->bump_error($value)

=item $feed->bump_deleted($value)

=item $feed->bump_skipped($value)

Increase the fetched, error, deleted and skipped counters by $value,
or by 1 if not specified.

=cut

sub bump_fetched {shift->{stats}{fetched} += (@_ ? shift : 1)}
sub bump_error  {shift->{stats}{error} += (@_ ? shift : 1)}
sub bump_deleted {shift->{stats}{deleted} += (@_ ? shift : 1)}
sub bump_skipped {shift->{stats}{skipped} += (@_ ? shift : 1)}

=item $feed->mirror($dir,$items,$channel)

Mirror a list of podcast episodes into the indicated directory. $dir
is the absolute path to the directory to mirror the episodes into,
$items is an array ref of MP3::PodcastFetch::Feed::Item objects, and
$channel is a MP3::PodcastFetch::Feed::Channel object.

=cut

sub mirror {
  my $self = shift;
  my ($dir,$items,$channel) = @_;

  # generate a directory listing of the directory
  my %current_files;
  my $curdir = getcwd();
  chdir($dir) or croak "Couldn't changedir to $dir: $!";
  my $d = IO::Dir->new('.') or croak "Couldn't open directory $dir for reading: $!";
  while (my $file = $d->read) {
    next if $file eq '..';
    next if $file eq '.';
    $current_files{$file}++;
  }
  $d->close;

  # generate a list of the basenames of the items
  my %to_fetch;
  for my $i (@$items) {
    my $url   = $i->url;
    my $basename = $self->make_filename($url,$i->title);
    $to_fetch{$basename}{url}     = $url;
    $to_fetch{$basename}{item}    = $i;
  }

  # find files that are no longer on the subscription list
  my @goners = grep {!$to_fetch{$_}} keys %current_files;

  if ($self->keep_old) {
    my $max   = $self->max;
    if (@goners + keys %to_fetch > $max) {
      $self->log_error("The episode limit of $max has been reached. Will not fetch additional podcasts.");
      return;
    }
  }
  else {
  	foreach my $fn ( @goners ) {
    	my $gone = unlink $fn;
    	$self->bump_deleted($gone);
	  	if ( ref $self->delete_callback eq 'CODE' ) {
			&{$self->delete_callback}( $self, $fn );
		}
    	$self->log("$fn: deleted");
		push @{$self->{files_deleted}}, $fn;
  	}
  }

  # use LWP to mirror the remainder
  my $ua = LWP::UserAgent->new;
  $ua->env_proxy if $self->env_proxy;
  $ua->timeout($self->timeout);
  for my $basename (sort keys %to_fetch) {
    $self->mirror_url($ua,$to_fetch{$basename}{url},$basename,$to_fetch{$basename}{item},$channel);
  }

  chdir ($curdir);
}

=item $feed->mirror_url($ua,$url,$filename,$item,$channel)

Fetch a single podcast episode. Arguments are:

 $ua        An LWP::UserAgent object
 $url       The URL of the podcast episode to mirror
 $filename  The local filename for the episode (may already exist)
 $item      The corresponding MP3::PodcastFetch::Feed::Item object
 $channel   The corresponding MP3::PodcastFetch::Feed::Channel object

=cut

sub mirror_url {
  my $self = shift;
  my ($ua,$url,$filename,$item,$channel) = @_;

  my $mode = $self->mirror_mode;
  croak "invalid mirror mode $mode" unless $mode eq 'exists' or $mode eq 'modified-since';

  my $title = $item->title;

  # work around buggy servers that don't respect if-modified-since
  if ($mode eq 'exists' && -e $filename) {
      $self->log("$title: skipped");
      $self->bump_skipped;
      return;
  }

  my $response = $ua->mirror($url,$filename);
  if ($response->is_error) {
    $self->log_error("$url: ",$response->status_line);
    $self->bump_error;
    return;
  }

  if ($response->code eq RC_NOT_MODIFIED) {
      $self->bump_skipped;
      $self->log("$title: skipped");
      return;
  }

  if ($response->code eq RC_OK) {
      my $length = $response->header('Content-Length');
      my $size   = -s $filename;

      if (defined $length && $size < $length) {
	  $self->log("$title: ","INCOMPLETE. $size/$length bytes fetched (will retry later)");
	  unlink $filename;
	  $self->bump_error;
      } else {
	  $self->fix_tags($filename,$item,$channel);
	  $self->write_playlist($filename,$item,$channel);
	  $self->bump_fetched;
	  $self->add_file($filename,$item,$channel);

		if ( $mode eq 'exists' ) {
	 		#
			# change time stamp to pub date ( for dinamic url )
			#
			my $pubdate = $item->pubDate;
		    my $secs    = $pubdate ? str2time($pubdate) : 0;
			if ( $secs ) {
				utime $secs, $secs, $filename;
			}
		}
	  $self->log("$title: $size bytes fetched");
      }
      return;
  }

  $self->log("$title: unrecognized response code ",$response->code);
  $self->bump_error;
}

=item $feed->log(@msg)

Log the strings provided in @msg to STDERR. Logging is controlled by
the -verbose setting.

=cut

sub log {
  my $self = shift;
  my @msg  = @_;
  return unless $self->verbose;
  my $tabs = $self->{tabs} || 0;
  foreach (@msg) { $_ ||= '' } # get rid of uninit variables
  chomp @msg;
  warn "\t"x$tabs,@msg,"\n";
}

=item $feed->log_error(@msg)

Log the errors provided in @msg to STDERR. Logging occurs even if
-verbose is false.

=cut

sub log_error {
  my $self = shift;
  my @msg  = @_;
  my $tabs = $self->{tabs} || 0;
  foreach (@msg) { $_ ||= '' } # get rid of uninit variables
  chomp @msg;
  warn "\t"x$tabs,"*ERROR* ",@msg,"\n";
}

=item $feed->add_file($path)

Record that we successfully mirrored the podcast episode indicated by $path.

=cut

sub add_file {
  my $self = shift;
  my ($filename,$item,$channel) = @_;
  my $dir          = $self->generate_directory($channel);
  my $fn = File::Spec->catfile($dir,$filename);
  push @{$self->{files_fetched}},$fn;

	if ( ref $self->fetch_callback eq 'CODE' ) {
			&{$self->fetch_callback}( $self, $fn );
	}
}

=item $feed->write_playlist($filename,$item,$channel)

Write an entry into the current playlist indicating that $filename is
ready to be listened to. $item and $channel are the
MP3::PodcastFetch::Feed::Item and Channel objects respectively.

=cut

sub write_playlist {
  my $self = shift;
  my ($filename,$item,$channel) = @_;
  my $playlist = $self->playlist_handle or return;
  my $title    = $item->title;
  my $album    = $channel->title;
  my $duration = $self->get_duration($filename,$item);
  my $base     = $self->playlist_base || $self->base;
  my $subdir   = $self->subdir;
  my $dir      = $self->channel_dir($channel);

  # This is dodgy. We may be writing the podcast files onto a Unix mounted SD card
  # and reading it on a Windows-based MP3 player. We try to guess whether the base
  # is a Unix or a Windows base. We assume that OSX will work OK.
  my $path;
  if ($base =~ m!^[A-Z]:\\! or $base =~ m!\\!) {  # Windows style path
    eval { require File::Spec::Win32 } unless File::Spec::Win32->can('catfile');
    $path       = File::Spec::Win32->catfile($base,$subdir,$dir,$filename);
  } else {                                        # Unix style path
    eval { require File::Spec::Unix } unless File::Spec::Unix->can('catfile');
    $path       = File::Spec::Unix->catfile($base,$subdir,$dir,$filename);
  }
  print $playlist "#EXTINF:$duration,$album: $title\r\n";
  print $playlist $path,"\r\n";
}

=item $feed->fix_tags($filename,$item,$channel)

Fix the ID3 tags in the newly-downloaded podcast episode indicated by
$filename. $item and $channel are the MP3::PodcastFetch::Feed::Item
and Channel objects respectively.

=cut

sub fix_tags {
  my $self = shift;
  my ($filename,$item,$channel) = @_;

  my $mtime   = (stat($filename))[9];
  my $pubdate = $item->pubDate;
  my $secs    = $pubdate ? str2time($pubdate) : $mtime;

  if ($self->upgrade_tags ne 'no') {
      my $year    = (localtime($secs))[5]+1900;
      my $album   = $self->force_album  || $channel->title;
      my $artist  = $self->force_artist || $channel->author;
      my $comment = $channel->description;
      $comment   .= " " if $comment;
      $comment   .= "[Fetched with podcast_fetch.pl (c) 2006 Lincoln D. Stein]";
      my $genre   = $self->force_genre  || 'Podcast';

      eval {
	  MP3::PodcastFetch::TagManager->new()->fix_tags($filename,
							 {title  => $item->title,
							  genre  => $genre,
							  year   => $year,
							  artist => $artist,
							  album  => $album,
							  comment=> $comment,
							 },
							 $self->upgrade_tags,
	      );
      };
      $self->log_error($@) if $@;
  }

  if ($self->use_pub_date) {
      utime $secs,$secs,$filename;     # make the modification time match the pubtime
  } else {
      utime $mtime,$mtime,$filename;   # keep the modification times mirroring the web site
  }
}

=item $duration = $feed->get_duration($filename,$item)

This method is used to provide extended information for .m3u
playlists.

Get the duration, in seconds, of the podcast episode given by
$filename. If an ID3 tagging library is available, the duration will
be calculated from the MP3 file directory. Otherwise, it will fall
back to using the duration specified by the RSS feed's
MP3::PodcastFetch::Feed::Item object. Many RSS feeds do not specify
the duration, in which case get_duration() will return 0.

=cut

sub get_duration {
  my $self     = shift;
  my ($filename,$item) = @_;

  my $duration =  MP3::PodcastFetch::TagManager->new()->get_duration($filename);
  $duration    = $item->duration || 0 unless defined $duration;
  return $duration;
}

=item $filename = $feed->make_filename($url,$title)

Create a filename for the episode located at $url based on its $title
or the last component of the URL, depending on -rewrite_filename
argument provided to new().

=cut

sub make_filename {
  my $self = shift;
  my ($url,$title) = @_;

  if ($self->rewrite_filename eq 'md5' ) {
  	my $md5 = md5_hex( $url );
	$url =~ s#([^\?]+).*#$1#;
    my ($extension) = $url =~ /\.(\w+)$/;
	if ( defined $extension ) {
		return $self->safestr($md5) . ".$extension";
	} else {
		return $self->safestr($md5);
	}
  } elsif ($self->rewrite_filename) {
    my ($extension) = $url =~ /\.(\w+)$/;
    my $name = $self->safestr($title);
    $name   .= ".$extension" if defined $extension;
    return $name;
  } else {
  	return uri_unescape( basename($url) );
  }
}

=item $path = $feed->generate_directory($channel)

Create a directory for the channel specified by the provided
MP3::PodcastFetch::Feed::Channel object, respecting the values of
-base and -subdir. The path is created in an OS-independent way, using
File::Spec->catfile(). The directory will be created if it doesn't
already exist. If it already exists and is not writeable, the method
errors out.

=cut

sub generate_directory {
  my $self    = shift;
  my $channel = shift;
  my $dir     = File::Spec->catfile($self->base,$self->subdir||'',$self->channel_dir($channel));

  # create the thing
  unless (-d $dir) {
    mkpath($dir) or croak "Couldn't create directory $dir: $!";
  }

  -w $dir or croak "Can't write to directory $dir";
  return $dir;
}

=item $dirname = $feed->channel_dir($channel)

Generate a directory named based on the provided channel object's title,
unless it is overriden by B<-override_channel_dir> value.

=cut

sub channel_dir {
  my $self    = shift;
  my $channel = shift;

  my $dir = $self->override_channel_dir || $channel->title;

  return
    $self->safestr( $dir ); # potential bug here -- what if two podcasts have same title?
}

=item $safe_str = $feed->safe_str($unsafe_str)

This method generates OS-safe path components from channel and podcast
titles. It replaces whitespace and other odd characters with
underscores.

=back

=cut

sub safestr {
  my $self = shift;
  my $str  = shift;

  # turn runs of spaces into _ characters
  $str =~ tr/ /_/s;

  # get rid of odd characters
  $str =~ tr/a-zA-Z0-9_+^.%$@=,\\-//cd;

  return $str;
}

1;

__END__

=head1 SEE ALSO

L<podcast_fetch.pl>,
L<MP3::PodcastFetch::Feed>,
L<MP3::PodcastFetch::Feed::Channel>,
L<MP3::PodcastFetch::Feed::Item>,
L<MP3::PodcastFetch::TagManger>,
L<MP3::PodcastFetch::XML::SimpleParser>

=head1 AUTHOR

Lincoln Stein E<lt>lstein@cshl.orgE<gt>.

Copyright (c) 2006 Lincoln Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
