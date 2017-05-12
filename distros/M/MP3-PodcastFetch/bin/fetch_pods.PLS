#!perl
use Config;
use File::Basename qw(&basename &dirname);
use File::Spec;
use FindBin '$Bin';
use Cwd;

my $dir = dirname($0);
$file   = shift || File::Spec->catfile($dir,basename($0, '.PL','.PLS'));

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

my $startperl = $Config{startperl} ne '#!perl' 
  ? $Config{startperl}
  : "#!$Config{perlpath}";

print OUT <<"!GROK!THIS!";
$startperl -w
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
# $Id: fetch_pods.PLS,v 1.8 2007/01/02 01:34:22 lstein Exp $
# Warning: do not directly edit this file. Edit fetch_pods.PLS and rerun Build
use strict;
use warnings;
use FindBin '$Bin';
use Config::IniFiles;
use IO::File;
use File::Path 'mkpath';
use File::Spec;
use File::Basename 'dirname';
use POSIX 'strftime';

use lib "$Bin/../lib";
use MP3::PodcastFetch;

use constant CONFIG => "$Bin/../conf/podcasts.conf";

################## clean up nicely ##############
my $pid_file;
$SIG{TERM} = $SIG{INT} = sub { unlink $pid_file if defined $pid_file; exit -1; };
END {
  unlink $pid_file if defined $pid_file;
}
#################################################

my $config_file = shift || find_config_file();
if ($config_file =~ /^-?-h/i) { # a plea for help
  die <<END;
Usage: fetch_pods.pl [/path/to/config/file]

Fetch the podcasts indicated in the configuration file. Default locations
for the config file are:

  ~/.fetchpods
  /usr/local/etc/fetchpods.conf
  /usr/etc/fetchpods.conf
  /etc/fetchpods.conf
  /path/to/this/binary/../etc/fetchpods.conf
  /path/to/this/binary/../conf/fetchpods.conf  # for local installations

Run the command "perldoc fetch_pods.pl" for full usage information.

END
}

my $cfg = Config::IniFiles->new(-file=>$config_file,-default=>'Globals')
  or die "Couldn't open config file $config_file: $!";

$pid_file = $cfg->val(Globals=>'pidfile') || File::Spec->catdir(File::Spec->tmpdir,'fetchPods.pid');
write_pidfile($pid_file) or exit 0;

my $base  = interpolate($cfg->val(Globals=>'base'));
$base or die "Please provide a valid 'base' option in the [Globals] section of the configuration file.\n";
$base = interpolate($base);

my $date = localtime;
print "$date START fetch_pods\n";
STDOUT->flush;

my $verbose           = $cfg->val(Globals=>'verbose');
my $subdirs           = $cfg->val(Globals=>'subdirs')       || 0;
my $generate_playlist = $cfg->val(Globals=>'keep_old')      || 0;
my $playlist_base     = interpolate($cfg->val(Globals=>'playlist_base')) || $base;
my $playlist_name     = $cfg->val(Globals=>'playlist_name') || '%Y-%m-%d_podcasts.m3u';
my @sections          = grep {!/globals/i} $cfg->Sections;

true_or_false(\$verbose,\$subdirs);

my ($m3ufile,$playlist_path);
if ($generate_playlist) {
  $playlist_name = File::Spec->rel2abs($playlist_name,$base);
  $playlist_path = strftime($playlist_name,localtime);
  my $dir        = dirname($playlist_path);
  -d $dir or mkpath($dir) or die "Couldn't create directory $dir: $!";
  $m3ufile       = IO::File->new($playlist_path,">") or die "Couldn't open $playlist_path for writing: $!";
  print $m3ufile "#EXTM3U\r\n";
}

my ($fetched,$skipped,$deleted,$errors) = (0,0,0,0);
for my $podcast (@sections) {
  my $url               = $cfg->val($podcast=>'url');
  my $limit             = $cfg->val($podcast=>'limit')    || 'none';
  my $subdir            = $cfg->val($podcast=>'subdir')   || 0;
  my $override_channel  = $cfg->val($podcast=>'override_channel_dir');
  my $keep_old          = $cfg->val($podcast=>'keep_old') || 0;
  my $rewrite           = $cfg->val($podcast=>'rewrite_filename') || 0;
  my $upgrade           = $cfg->val($podcast=>'upgrade_tag') || 0;
  my $mode              = $cfg->val($podcast=>'mirror_mode') || 'modified-since';
  my $timeout           = $cfg->val($podcast=>'timeout')     || 600;
  my $genre             = $cfg->val($podcast=>'force_genre');
  my $artist            = $cfg->val($podcast=>'force_artist');
  my $album             = $cfg->val($podcast=>'force_album');
  my $use_pub_date      = $cfg->val($podcast=>'use_pub_date');

  unless (defined $url) {
    warn "No podcast RSS URL defined for $podcast\n";
    next;
  }

  true_or_false(\$keep_old,\$rewrite,\$generate_playlist);

  $limit = 1000 if $limit eq 'none';
  my $feed   = MP3::PodcastFetch->new(
                                 -base              => $base,
                                 -subdir            => $subdirs ? $subdir : '',
                                 -override_channel_dir => $override_channel,
				 -rss               => $url,
				 -max               => $limit,
				 -mirror_mode       => $mode,
				 -rewrite_filename  => $rewrite,
				 -upgrade_tag       => $upgrade,
				 -verbose           => $verbose,
                                 -force_genre       => $genre,
                                 -force_artist      => $artist,
                                 -force_album       => $album,
                                 -keep_old          => $keep_old,
                                 -playlist_handle   => $m3ufile,
                                 -playlist_base     => $playlist_base,
                                 -use_pub_date      => $use_pub_date,
                                );
  $feed->fetch_pods;
  $fetched += $feed->fetched;
  $skipped += $feed->skipped;
  $deleted += $feed->deleted;
  $errors  += $feed->errors;
}

$date = localtime;
unlink $playlist_path if $playlist_path && !$fetched;
print "$date END fetch_pods: $fetched fetched, $skipped skipped, $deleted deleted, $errors errors.\n\n";

exit 0;

# either create pidfile or exit gracefully
sub write_pidfile {
  my $file = shift;
  if (-e $file) {  # uh oh, maybe we're running :-(
    open (F,$file) or return;
    my $oldpid = <F>;
    chomp $oldpid;
    kill 0=>$oldpid and return;
    close F;
  }
  open F,">",$file or die "Can't write PID file $file: $!";
  print F $$;
  close F;
  1;
}

sub find_config_file {
  my $self  = shift;
  my $home  = (getpwuid($<))[7] || $ENV{HOME};
  my @paths = ("$home/.fetchpods",
	       "/usr/local/etc/fetchpods.conf",
	       "/usr/etc/fetchpods.conf",
	       "/etc/fetchpods.conf",
	       "$Bin/../etc/fetchpods.conf",
	       "$Bin/../conf/fetchpods.conf");
  foreach (@paths) {
    return $_ if -f $_ && -r _;
  }
}

sub true_or_false {
  for my $ref (@_) {
     next unless $$ref;
     if ($$ref =~ /^no$/i) {
        undef $$ref;
     } elsif ($$ref =~ /^yes$/i) {
        $$ref = 1;
     }
  }
}

sub interpolate {
  my $ref   = shift;
  return unless defined $ref;
  $ref     =~ s/^~([^\/]*)/($1 ? getpwnam($1):getpwuid($<))[7] || "~$1"/eg;
  $ref     =~ s/\$(\w+)/$ENV{$1}/g;
  $ref;
}

__END__

=head1 NAME

fetch_pods.pl -- Fetch and manage podcasts from the command line

=head1 SYNOPSIS

 % fetch_pods.pl /etc/fetchpods.conf
 Wed Dec 27 16:01:54 2006 START fetch_pods
	Updating podcasts for PRI's The World - Geo Quiz. 5 items available...
		PRI's The World - Geo Quiz Podcast 135: skipped
		PRI's The World - Geo Quiz Podcast 136: skipped
		PRI's The World - Geo Quiz Podcast 138: skipped
		PRI's The World - Geo Quiz Podcast 139: skipped
	Updating podcasts for APM: Future Tense. 5 items available...
		A backpack to lighten your load: deleted
		How best to begin using your new tech products: skipped
		Is malware leading Windows users to the Mac side?: skipped
		Last-minute gifts at NetworkforGood.com: skipped
		Where will next Bill Gates come from? Survey says: not the United States: 1993249 bytes fetched
Wed Dec 27 16:01:56 2006 END fetch_pods: 1 fetched, 8 skipped, 1 deleted, 1 errors.


=head1 DESCRIPTION

Use this Perl script to fetch and maintain a directory of podcast
subscriptions. Information about which podcasts to fetch are stored in
a configuration file. You can control how many podcast files to keep,
where to keep them, whether to rationalize their ID3 tags, and whether
to delete older podcast files. This script will also create playlists
listing recently-fetched podcasts.

To use this script, create a configuration file (see "Configuration
File Format") listing global options and the podcasts you wish to
subscribe to; a sample configuration file is located in the
distribution directory undef ./conf/fetchpods.conf. Then run
fetch_pods from the command line. You can explicitly give the path to
the configuration file on the command line as shown here:

  fetch_pods.pl ~/pods/news_pods.conf

If called with no arguments, fetch_pods.pl will look for a default
configuration file in the following locations:

  ~/.fetchpods
  /usr/local/etc/fetchpods.conf
  /usr/etc/fetchpods.conf
  /etc/fetchpods.conf
  /path/to/this/binary/../etc/fetchpods.conf
  /path/to/this/binary/../conf/fetchpods.conf

The script will stop and process the first configuration file it
finds. Note that when you installed this script, it created a default
fetchpods.conf in /etc/fetchpods.conf. You may want to delete this
file.

To run from a cron job once daily at 1 am, enter something like this:

 0 1 * * * /usr/bin/fetch_pods.pl >> ~/fetchpods.log

=head1 Configuration File

The configuration file is a Windows-style Ini file. It consists of a
[Globals] section and one section for each podcast subscription. A
simple config file will look like this:

 [Globals]
 base             = ~/podcasts
 verbose          = yes
 rewrite_filename = yes
 upgrade_tag      = auto

 [NYTimes]
 description = The New York Times Front Page
 limit = 2
 url   = http://www.nytimes.com/services/xml/rss/nyt/podcasts/frontpage.xml

 [NPR]
 description = NPR 7 am news summary
 url         = http://www.npr.org/rss/podcast.php?id=500001

This config file designates the directory ~/podcasts (subdirectory
"podcasts" in your home directory) to receive the podcast files. We
turn on verbose progress reporting and activate the rewrite_filename
and upgrade_tag features. As described in more detail later, the first
option replaces the cryptic default names of the podcast files with
longer more informative names, while the second normalizes the ID3 tag
information in the podcast files (e.g. setting the genre to
"Podcast").

We define two feeds, each in its own section. The [NYTimes] feed
subscribes to the New York Times front page podcast, located at the
url indicated by the "url" option. We specify a limit of 2 on the
number of podcasts to have on hand.  The [NPR] feed does the same
thing for the National Public Radio morning news summary, except that
there is no limit.

After running the script the /tmp/podcasts directory will contain one
directory each for the NYTimes and NPR feeds, and will look something
like this:

 % ls -lRh podcasts/
 podcasts/:
 total 0
 drwxrwxr-x  2 lstein lstein 128 Dec 28 14:18 7AM_ET_News_Summary/
 drwxrwxr-x  2 lstein lstein 144 Dec 28 14:18 New_York_Times_Front_Page/

 podcasts/7AM_ET_News_Summary:
 total 2.6M
 -rw-rw-r--  1 lstein lstein 2.6M Dec 28 07:16 NPR_News_Summary_for_Thursday,_Dec_28_2006_at_700_AM_EST.mp3

 podcasts/New_York_Times_Front_Page:
 total 8.6M
 -rw-rw-r--  1 lstein lstein 5.1M Dec 26 21:00 NYT_Front_Page_for_12272006.mp3
 -rw-rw-r--  1 lstein lstein 3.5M Dec 27 21:48 NYT_Front_Page_for_12282006.mp3

The name of the [Globals] section is significant (including the
capital "G") and cannot be changed. In particular, if no base is
specified, then the script will not run. The names of each of the feed
sections are not meaningful except that they must be unique. In other
words, we could just as easily have named them [Feed 1] and [Feed 2].

Most of the [Globals] options can be overridden in individual feed
sections. This allows you to create global settings, such as "limit",
which are then overidden on a case-by-case basis in each feed section.

For boolean (true/false) options, you may use perl-style truth values
(0 for false, 1 for true) or the strings "no" or "yes".

A line that begins with the # symbol is a comment and has no effect on
processing the config file.

=head2 Global section-specific options

The following options are specific to the [Globals] section and cannot
be overidden in the feed sections.

=over 4

=item base

Set the base directory for the downloaded podcasts. This option must
be present. The shortcuts ~, ~user and $ENVIRONMENT_VARIABLE are all
recognized.

=item override_channel_dir

Use a directory other than a channel title which is the default.  This
allows to put multiple channel feeds in a single directory.

=item verbose

A boolean controlling the verbosity of the output from the script. Set
to 1 or "yes" to generate status information for each file
downloaded. Defaults to "no."

=item generate_playlist

A boolean controlling whether to generate a playlist for the podcasts
downloaded in the current session. Defaults to "no."

=item playlist_name

If generate_playlist is set to a true value, this option allows you to
control the name of the generated playlist file. This can contain
strftime() style time interpolation codes so that the playlist name
contains a timestamp. The default is "%Y-%m-%d_podcasts.m3u", which
will produce playlists like "2006-12-28_podcasts.m3u". You will want
to add the hour (%H) and minute (%M) if you plan on freshening
podcasts more than once a day.

The playlist name may also contain path elements - the subdirectories
will be created as necessary. Relative paths will be resolved relative
to the base.

=item playlist_base

If generate_playlist is set to a true value, and if you are mirroring
the podcasts to a removable medium such as an sdcard for later use
with a portable music player device, you will need to change this
option. It contains the directory path to each podcast file as it will
appear to the music player. For example, if you mount the medium at
/mnt/sdcard and keep podcasts in /mnt/sdcard/podcasts, then the base
and playlist_base options might look like this:

  base          = /mnt/sdcard/podcasts
  playlist_base = /podcasts

For Windows-based devices, you might have to specify a playlist_base
using Windows filesystem conventions, e.g.:

  playlist_base = \podcasts

or even

  playlist_base = C:\podcasts

The default is to use the same base path as specified by the "base"
option.

=item subdirs

Ordinarily each podcast will be placed in a directory named after its
channel, directly underneath the directory specified by "base." If
this boolean is set to true ("yes"), then each feed section can
specify additional levels of directories in which to place the podcast
files using the "subdir" option.

For example, the example config file shown earlier will store the NY
Times podcasts under ~/podcasts/New_York_Times_Front_Page, and the NPR
news summaries under ~/podcasts/7AM_ET_News_Summary. You can organize
your podcasts a little better in this way:

 [Globals]
 base             = ~/podcasts
 verbose          = yes
 rewrite_filename = yes
 upgrade_tag      = auto
 subdirs          = yes

 [NYTimes]
 description = The New York Times Front Page
 limit  = 2
 subdir = News/Newspapers
 url    = http://www.nytimes.com/services/xml/rss/nyt/podcasts/frontpage.xml

 [NPR]
 description = NPR 7 am news summary
 subdir      = News/Radio
 url         = http://www.npr.org/rss/podcast.php?id=500001

Now the Times podcast files will be stored in the directory
~/podcasts/News/Newspapers/New_York_Times_Front_Page and the NPR news
in ~/podcasts/News/Radio/7AM_ET_News_Summary.

=item pidfile

This script writes out a file containing its process ID (PID) in order
to prevent the script from being run twice at the same time. This
option lets you change the path to the file (default
/tmp/fetch_pods.pid).

=back

=head2 Feed section options

The following options appear in individual feed sections. They can
also be placed in the [Globals] section to provide defaults for all
feeds. For example, you can place "limit = 5" in [Globals] in order to
limit all feeds by default to a maximum number of five podcast files
per feed, and then override the limit on a feed-by-feed basis with
additional "limit" options in individual feed sections.

=over 4

=item description

This is a text description of the feed. It is there for documentation
purposes only and can safely be omitted.

=item url

This is the URL for the RSS (podcast subscription) for the podcast. It
is mandatory.

=item timeout

Control how long (in seconds), the script will wait before it times
out a slow remote server during the RSS-reading or downloading
process. Incomplete downloads will be removed.

=item rewrite_filename

If this option is true (default false) the physical name of the
podcast file, which is usually something cryptic like PUB_071206.mp3,
will be replaced with a long name based on the podcast's title.

=item mirror_mode

This option controls how mirroring of podcast files is performed and
can be one of "modified-since" or "exists". The default,
"modified-since," will fetch the podcast file if either:

 1. a local copy of the podcast is absent.
 2. a local copy exists, but the version on the remote server is
    more recent.

In contrast "exists" will cause the file to be fetched only if (1)
applies. This reduces network traffic, but opens the slight
possibility that the remote podcast might be updated (e.g. for a
correction) and that you won't mirror the change. This option is
primarily intended to work around broken podcasts which have their
modification dates set in the future and thus are unecessarily
refreshed each time the script runs.

=item upgrade_tag

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

 no        Don't mess with the ID3 tags
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
recent tag version.

=item limit

By default, fetch_pods.pl will fetch all the podcasts that are
currently mentioned in the RSS feed XML document. MP3 files that are
no longer listed in the document will be removed. You can override
this behavior using the "limit" option. This sets an upper bound on
the number of MP3 files that can be stored, either on a global basis,
or a per-feed basis. For example, if you specify limit=4 for the NY
Times Front Page, then only the most recent four NYT podcasts will be
stored, even if the RSS feed lists more.

Also see the "keep_old" option.

=item keep_old

This is a boolean option which, if true, will cause expired podcasts
to be kept even if after they are no longer listed in the RSS feed
file. This also changes the behavior of the limit option. When
keep_old is false, limit will delete older podcasts in order to make
room for newer ones. When keep_old is true, then newer podcasts will
not be fetched if the total number of stored podcasts for the current
feed exceeds the limit. You will have to manually delete some podcast
files in order to make room for more.

=item force_genre, force_artist, force_album

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

 force_genre     Change the genre to whatever you specify.
 force_artist    Change the artist.
 force_album     Change the album.

For example, the NY Times front page RSS feed specifies "The New York
Times" as the artist. You can force this to a shorter abbreviation
with the following modified feed section:

 [NYTimes]
 description  = The New York Times Front Page
 url          = http://www.nytimes.com/services/xml/rss/nyt/podcasts/frontpage.xml
 force_artist = NYT

Note that if you are forced to use ID3v1 tagging (e.g. MP3::Info) then
you must choose one of the predefined genres; in particular, there is
no genre named "Podcast." You must force something else, like "Speech"
instead.

=back

=head1 SEE ALSO

L<MP3::PodcastFetch>,
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

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
