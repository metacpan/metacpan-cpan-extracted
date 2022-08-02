package LyricFinder;

require 5.001;

use strict;
use warnings;
use Carp;
use parent 'LyricFinder::_Class';

# LyricFinder - A Derived work, by (c) 2020 Jim Turner <turnerjw784 at yahoo.com> of:
#
# Lyrics Fetcher
#
# Copyright (C) 2007-2020 David Precious <davidp@preshweb.co.uk> (CPAN: BIGPRESH)
#
# Originally authored by and copyright (C) 2003 Sir Reflog <reflog@gmail.com>
# who kindly passed maintainership on to David Precious in Feb 2007
#
# Original idea:
# Copyright (C) 2003 Zachary P. Landau <kapheine@hypa.net>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

our $VERSION = '1.22';
our $DEBUG = 0;  # If you want debug messages, set debug to a true value

my @supported_mods = (qw(Cache ApiLyricsOvh AZLyrics Genius Letras Musixmatch));

my %haveit;

foreach my $module (@supported_mods)
{
	$haveit{$module} = 0;
	eval "use LyricFinder::$module; \$haveit{$module} = 1; 1";
}

sub new
{
	my $class = shift;

	#EXTRACT ANY MAIN-SPECIFIC ARGUMENTS (NOT TO BE PASSED TO SUBMODULES):
	my @args = ();
	while (@_) {
		my $arg = shift(@_);
		if ($arg =~ /^\-omit$/o) {   #ALLOW USER TO OMIT SPECIFIC INSTALLED SUBMODULE(S):
			my $omit = shift(@_);
			my @omitModules = ref($omit) ? @{$omit} : split(/\,\s*/, $omit);
			foreach my $omit (@omitModules)
			{
				$haveit{$omit} = 0  if (defined($haveit{$omit}) && $haveit{$omit});
			}
		} else {
			push @args, $arg;
		}
	}

	my $self = $class->SUPER::new('', @args);
#	@{$self->{'_fetchers'}} = @FETCHERS;
	@{$self->{'_fetchers'}} = ();
	@{$self->{'_FETCHERS'}} = ();
	#NOTE:  UPPER CASE _FETCHERS USED FOR "random" AND "all", & *NEVER* INCLUDES CACHE (1ST SUBMODULE TRIES CACHE)!:
	#LOWER CASE _fetchers INCLUDES CACHE FIRST IF CACHE DIRECTORY AND IT'S NOT WRITEONLY, AS THIS IS FOR ORDER/TRIED LIST!
	foreach my $module (@supported_mods)
	{
		next  unless ($haveit{$module} && $module ne 'Cache');
		push @{$self->{'_FETCHERS'}}, $module;
		push @{$self->{'_fetchers'}}, $module;
	}
	
	unshift(@{$self->{'_fetchers'}}, 'Cache')  if ($haveit{'Cache'}
			&& $self->{'-cache'} && $self->{'-cache'} !~ /^\>/);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub order {
	my $self = shift;
	return wantarray ? split(/\,/, $self->{'Order'}) : $self->{'Order'};
}

sub tried {
	my $self = shift;
	return wantarray ? split(/\,/, $self->{'Tried'}) : $self->{'Tried'};
}

sub _fetch {
	my ($self, $artist, $title, $fetchers) = @_;

	$self->_debug("LyricFinder::_fetch($artist, $title, $fetchers)!");
	if (!$artist || !$title || ref $artist || ref $title) {
		carp("e:_fetch() called without artist and title.");
		return;
	}

	if (!$fetchers || ref $fetchers ne 'ARRAY') {
		carp("e:_fetch not given arrayref of fetchers to try");
		return;
	}

	for my $fetcher (@$fetchers) {
		$self->{'Url'} = '';
		$self->_debug("..Trying fetcher $fetcher for artist:$artist title:$title");

		my $fetcherpkg = __PACKAGE__ . "::$fetcher";
		my $finderModule = 0;
		eval "\$finderModule = new ${fetcherpkg}(\%{\$self});";
		if ($@ || !$finderModule) {
			carp("w:Failed to load sub-module $fetcherpkg ($@)");
			next;
		}
		
		# OK, we require()d this fetcher, try using it:
		$self->{'Error'} = 'Ok';
		$self->_debug("..Source module $fetcher loaded OK");
		$self->{'Tried'} .= "$fetcher,";
		if (!$finderModule->can('fetch')) {
			$self->_debug("e:Source LyricFinder::$fetcher can't ->fetch($finderModule->{'Error'})");
			next;
		}
	
		$self->_debug("..Trying to fetch with $fetcher");
		my $lyrics = $finderModule->fetch($artist, $title);
		$self->{'Error'} = $finderModule->message();
		$self->{'Url'} = $finderModule->url();
		if ($self->{'Error'} eq 'Ok') {
			$self->_debug("..Source: $fetcher returned lyrics");
			if (defined($lyrics) && $lyrics =~ /\S/o) {
				$self->{'Source'} = $finderModule->source();;
				$self->{'Site'} = $finderModule->site();
				$self->{'image_url'} = $finderModule->image_url();
				@{$self->{'Credits'}} = $finderModule->credits();
				$self->{'Tried'} =~ s/\,$//;
				$self->_debug("i:Lyrics fetched from: ".$self->{'Source'});

				return $lyrics;
			}
		}
	}

	# if we get here, we tried all sites we were asked to try, and none
	# of them worked.
	$self->{'Error'} = 'e:All sites failed to fetch lyrics!'  if ($#{$fetchers} > 0);
	$self->{'Tried'} =~ s/\,$//;
	
	return undef;
}

sub fetch {
	my ($self, $artist, $title, $fetcherspec, $limit) = @_;

	my @tryfetchers = ();

	$self->_debug("LyricFinder::fetch($artist, $title, $fetcherspec)!");
	$self->{'Tried'} = '';

	$fetcherspec = 'random'  unless (defined($fetcherspec) && $fetcherspec);
	$self->{'Source'} = 'none';
	if ( $fetcherspec && !ref $fetcherspec && $fetcherspec !~ m'^auto$'i) {
		# we've been given a specific fetcher to use:
		if (grep /$fetcherspec/, @{$self->{'_FETCHERS'}}) {
			push @tryfetchers, $fetcherspec;
		} elsif ($fetcherspec =~ m'^random$'i) {
			my $random_fetcher;
			my %usedSources = ();
			my $usedcnt = 0;
			while ($usedcnt <= $#{$self->{'_FETCHERS'}}) {
				$random_fetcher = int(rand(scalar @{$self->{'_FETCHERS'}}));
				unless ($usedSources{${$self->{'_FETCHERS'}}[$random_fetcher]}) {
					push @tryfetchers, ${$self->{'_FETCHERS'}}[$random_fetcher];
					$usedSources{${$self->{'_FETCHERS'}}[$random_fetcher]} = 1;
					$usedcnt++;
				}
			}
		} elsif ($fetcherspec =~ m'^Cache$'i && $haveit{'Cache'}) {
			@tryfetchers = ('Cache');
		} elsif ($fetcherspec =~ m'^All$'i) {
			push @tryfetchers, @{$self->{'_FETCHERS'}};
		} else { 
			carp($self->{'Error'} = "s:Source (module) $fetcherspec isn't installed or is invalid!");
			return;
		}
	} elsif (ref $fetcherspec eq 'ARRAY') {
		# we've got an arrayref of fetchers to use:
		for my $fetcher (@$fetcherspec) {
			if (grep /$fetcher/, @{$self->{'_FETCHERS'}}) {
				push @tryfetchers, $fetcher;
			} else {
				carp("e:$fetcher isn't a valid fetcher, ignoring");
			}
		}
	} else {  #really shouldn't end up here (since default=random now), but leaving in for now.
		# OK, try all available fetchers.
		push @tryfetchers, @{$self->{'_FETCHERS'}};
	}
	$self->{'Order'} = join(',', @tryfetchers);
	$#tryfetchers = $limit - 1  if (defined($limit) && $limit > 0 && $limit < scalar(@tryfetchers));

	return $self->_fetch($artist, $title, \@tryfetchers);
}   # end of sub fetch.

1

__END__

=head1 NAME

LyricFinder - Fetch song lyrics from several internet lyric sites.

=head1 AUTHOR

This module is Copyright (c) 2020 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
All rights reserved.

This library is free software; you can redistribute it and/or modify it 
under the terms of either the GNU General Public License or the Artistic 
License, as specified in the Perl README file.

NOTE:  This is a "derived work" of L<Lyrics::Fetcher> family of modules, by 
(c) David Precious (davidp at preshweb.co.uk) (CPAN Id: BIGPRESH), as fair 
use legal under the terms of, subject to, and licensed in terms compatable 
and compliant with those modules.  Many thanks to David for laying the 
groundwork for this module!

=head1 SYNOPSIS

    #!/usr/bin/perl

    use LyricFinder;

    # create a new finder object:
    my $finder = new LyricFinder();

    # fetch lyrics for a song from a specific site (https://www.azlyrics.com):
    print $finder->fetch('Pink Floyd','Echoes','AZLyrics');

    # if you omit the site, automatically tries all available
    # sites in random order:
    print $finder->fetch('Oasis', 'Cast No Shadow');

    # or you can pass an arrayref of sites you want used in order:
    print $finder->fetch('Oasis', 'Whatever', [qw(Genius AZLyrics)]);

    # To find out which site modules are available:
    my @fetchers = $finder->sources();

    # To fetch the source (site) name and base url:
    print "(Lyrics courtesy: ".$finder->source().")\n";
    print "site url:  ".$finder->site().")\n";

    # To show what sites we had to search for these lyrics:
    print "..Tried sites:  ".$finder->tried().".\n";

    # To do caching:
    $finder->cache('/tmp/lyrics');
    #-or-
    my $localfinder = new LyricFinder(-cache => '/tmp/lyrics');

    #-or- to only fetch lyrics from our cache:
    my $local_lyrics = $localfinder->fetch('Oasis', 'Cast No Shadow', 'Cache');
    if ($local_lyrics) {
        print "..Lyrics from disk:\n\n$local_lyrics\n";
    } else {
        print "..No local lyrics found for 'Cast No Shadow', by Oasis.\n";
    }


=head1 DESCRIPTION

LyricFinder accepts an artist name and song title, searches supported 
lyrics sites for song lyrics, and, if found, returns them as a string.

The supported and currently-installed modules are:  
L<LyricFinder::ApiLyricsOvh> (for searching api.lyrics.ovh), 
L<LyricFinder::AZLyrics> (www.azlyrics.com), L<LyricFinder::Genius> 
(genius.com), L<LyricFinder::Letras> (www.letras.mus.br), and 
L<LyricFinder::Musixmatch> (www.musixmatch.com).  There is a 
special module for storing and / or fetching lyrics (.lrc) files already 
stored locally, called L<LyricFinder::Cache>.

This module is derived from the (older) Lyrics::Fetcher collection of modules 
by (c) 2007-2020 David Precious, but currently (as of December, 2020) supports 
more lyric sites (5) and bundles all the supported site modules together here 
(simply install this one module).  We have reworked the "Cache" module to 
cache lyrics files by artist and song title on disk in the user's desired 
location.  LyricFinder is also truly object-oriented making interaction with 
the user-facing methods and data easier and more streamlined.

NOTE:  This module is used completely independent of any of those modules, 
but the code is derived from them, as allowed by and the license and credits 
are included here, as required by their open-source license.  It is capable 
of being used as a drop-in replacement, but some function names and 
other code changes will be needed.

We've also added methods to easily change the "user-agent" passed to the 
lyrics sites, as needed/desired by the user programatically.

We've also changed the default to search the supported sites randomly, instead 
of in the same fixed alphabetical order by module name ("load-balancing" the 
searches to all the sites).  This is helpful when using LyricFinder as a 
plugin for streaming media players, such as the author's very own "Fauxdacious 
Media Player" that frequently stream internet radio stations, which can 
impose a "hit" on the lyrics sites each time the song title changes.  This 
reduces the odds of a user's IP-address possibly being banned by a lyrics site 
for "too-frequent scraping / usage"!  NOTE:  If you want to prevent the usage 
of one or more of the specific sites, simply delete or rename that site's 
submodule file.  If you want to use one or more specific sites, or enforce 
a specific search order, you can call the fetch() method with a third 
argument consisting of the site module name, ie. "Musixmatch", or reference to 
an array of site module names, ie. [Genius, AZLyrics].  If you specify "Cache" 
as the single module name (and provide a "-cache" directory containing lyrics 
files on your hard drive), LyricFinder will only search that directory for 
lyrics, and not the internet.  Otherwise, specifying a "-cache" directory 
will cause LyricFinder to first look in your cache directory for matching 
lyrics first, and only search any of the lyrics sites if not found, then will 
cache the lyrics found on the internet to a new lyric file in your lyrics 
directory eleminating re-searching the web when you play the same song 
again later and reducing internet bandwidth usage!

In case of problems with fetching lyrics, the error string will be returned by 
$finder->message().  If all goes well, it will have 'Ok' in it.

The site selection is made by the "method" parameter passed to the fetch() 
of this module.  You can also omit this parameter, in which case all available
fetchers will be tried in random order, or you can supply an arrayref of sites 
you'd like to try in the order you specify.

The value of the "method" parameter (if specified) must be either the "*" part 
of one of the installed LyricFinder::* fetcher package name, "all", or 
"random".

If you have another lyrics site that is not supported, please file a feature 
request via email or the CPAN bug system, or (for faster service), provide a 
Perl patch module / program source that can extract lyrics from that site and 
I'll consider it!  The easiest way to do this is to take one of the existing 
submodules, copy it to "LyricFinder::I<YOURSITE>.pm and modify it (and the POD 
docs) to your specific site's needs, test it with several Artist / Title 
combinations (see the "SYNOPSIS" code above), and send it to me 
(That's what I do for new sites)!

=head1 INSTALLATION

	To install this module, run the following commands:

	perl Makefile.PL

	make

	make test

	make install

=head1 SUBROUTINES/METHODS

=over 4

=item B<new> I<LyricFinder>([ I<options> ])

Creates a new finder object for fetching lyrics.  The same finder 
object can be used for multiple fetches from multiple sites, so this 
normally only needs to be called once.

I<options> is a hash of option/value pairs (ie. "-option" => "value").  
If an "-option" is specified with no "value" given, the default value will 
be I<1> ("I<true>").  The currently-supported options are:  

=over 4

=item B<-agent> => I<"user-agent string">

Specifies an alternate "user-agent" string sent to the lyric sites when 
attempting to fetch lyrics.  Get / set the desired user-agent 
(ie. browser name) to pass to the lyrics sites.  Some sites are pickey about 
receiving a user-agent string that corresponds to a valid / supported 
web-browser to prevent their sites from being "scraped" by programs, such 
as this.

Default:  I<"Mozilla/5.0 (X11; Linux x86_64; rv:84.0) Gecko/20100101 Firefox/84.0">.

NOTE:  This value will be overridden if $founder->agent("agent") is 
called!  NOTE:  See below how to specify a different agent for a specific 
site module.

=item B<-cache> => I<"directory">

Specifies a directory (ie. "/home/user/Music/Lyricsfiles") to be used for 
disk caching.  If specified, this directory will be searched for a matching 
lyrics (.lrc) file 
(in this example, "/home/user/Music/LyricsFiles/I<artist>/I<title>.lrc").
If no matching lyrics file is found (and the search module list is not 
specifically set to "Cache" (and lyrics are found on the internet), then 
the lyrics will be saved to the directory under "I<artist>/I<title>.lrc".

Default:  I<none> (no caching)

An optional dirctional indicator ("<" or ">") can be prepended to the 
directory to limit caching activity.  "<" allows fetching lyrics from the 
cache directory, but will not cache (write) new lyrics found on the web 
to the directory.  ">" (the opposite) will cache new lyrics but will never 
attempt to fetch (read) lyrics from the cache directory.  These options may 
be useful if one either simply wants to build a lyrics database but always 
fetch the latest, or perhaps limit lyrics to a fixed cache but not add to 
it, or perhaps is using a readonly directory.  The default is no indicator 
which allows both reading and writing.

Directory must be a valid directory, but may be specified as either a path 
(ie. "/home/user/lyrics") or a URI (ie. "file:///home/user/lyrics") or 
with a limiting directional indicator, ie. "</home/user/lyrics".  It may 
or may not have a trailing "/" (ie. "/home/user/lyrics/").

NOTE:  This value will be overridden if $founder->cache("directory") is 
called!  NOTE:  See below how to specify a different agent for a specific 
site module.

=item B<-debug> => I<number>

Specifies whether debug information will be displayed (0: no, >0: yes).

Default I<0> (no).  I<1> will display debug info.  There is currently only 
one level of debug verbosity.

=item B<-noextra> => I<0 | 1> (I<false> or I<true>)

Some sites (currently, only Musixmatch) may append some additional 
information below the lyrics text.  If specified or given a I<true> value, 
this will be suppressed and only the actual song lyrics returned.    
Default I<0> (false) - show any additional site-specific information.

=item B<-omit> => I<"site-module[,site-module2...]]>

Permits omitting specific sites which are currently installed from being 
searched (namely when using I<random> or I<all>).  For example, to 
exclude the Musixmatch site, specify:  I<-omit> => I<"Musixmatch">, which 
will cause LyricFinder::Musixmatch to not be considered for lyrics search.  
Default is for all installed sites (submodules) to be considered.  
NOTE:  The site list can be specified as a comma-separated string OR as 
an array reference, ie. I<-omit => [ qw(Musixmatch Genius) ]>.

=item B<-site-module-name> => { I<"-option"> => I<value> [, I<"-option"> => I<value> ... ] }

Specifies options for a specific site fetcher module.  These values 
will override any of the general option values specified for that specific 
module or calls to the general B<agent>() method, if it is used to fetch 
lyrics.  Examples would be if one needed to specify a different user-agent 
for one of the sites, or wished to cache lyrics fetched by sites to specific 
directories for some reason.  By default, top-level options are passed to 
the various sites, so this should only be needed in special cases.

Example:  "-Musixmatch => { -noextra => 1 }"

Default:  none (no site-specific options)

NOTE:  The "-cache" (cache-directory) option is needed by the main LyricFinder 
module and the site submodules in order to use the caching feature, so passing 
"-Cache => {-cache => I<directory>}" will NOT work (the way one might assume)!

=back 

=item [ I<$current-agent string> = ] $finder->B<agent>( [ I<user-agent string> ] )

Set the desired user-agent (ie. browser name) to pass to the lyrics sites.  
Some sites are pickey about receiving a user-agent 
string that corresponds to a valid / supported web-browser to prevent their 
sites from being "scraped" by programs, such as this.  

Default:  I<"Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0">

If no argument is passed, it returns the current GENERAL user-agent string in 
effect (but a different agent option is specified for a specific module may 
have been specified and used by THAT module - see B<new>() options above).

NOTE:  This will override any B<-agent> option value specified in B<new>()!
NOTE:  See above how to specify a different user-agent for a specific 
site module.

=item [ I<$current-directory> = ] $finder->B<cache>( [ I<$directory> ] )

Specifies a directory (ie. "/home/user/Music/Lyricsfiles") to be used for 
disk caching.  If specified, this directory will be searched for a matching 
lyrics (.lrc) file 
(in this example, "/home/user/Music/LyricsFiles/I<artist>/I<title>.lrc").
If no matching lyrics file is found (and the search module list is not 
specifically set to "Cache" (and lyrics are found on the internet), then 
the lyrics will be saved to the directory under "I<artist>/I<title>.lrc".

An optional dirctional indicator ("<" or ">") can be prepended to the 
directory to limit caching activity.  "<" allows fetching lyrics from the 
cache directory, but will not cache (write) new lyrics found on the web 
to the directory.  ">" (the opposite) will cache new lyrics but will never 
attempt to fetch (read) lyrics from the cache directory.  These options may 
be useful if one either simply wants to build a lyrics database but always 
fetch the latest, or perhaps limit lyrics to a fixed cache but not add to 
it, or perhaps is using a readonly directory.  The default is no indicator 
which allows both reading and writing.

Directory must be a valid directory, but may be specified as either a path 
(ie. "/home/user/lyrics") or a URI (ie. "file:///home/user/lyrics") or 
with a limiting directional indicator, ie. "</home/user/lyrics".  It may 
or may not have a trailing "/" (ie. "/home/user/lyrics/").

If no argument is passed, it returns the current GENERAL cache directory 
string in effect (but a different directory option is specified for a specific 
module may have been specified and used by THAT module - see B<new>() 
options above).

NOTE:  This will override any B<-cache> option value specified in B<new>()!

NOTE:  See above how to specify a different directory for a specific 
site module.

=item [ I<$scalar> | I<@array> ] = $finder->B<credits>()

Returns either a comma-separated list or an array of names credited by 
the site with posting the lyrics on the site (if any) or an empty 
string, if none found.  NOTE:  The only site that supports this currently 
is B<AZLyrics>.

=item I<$string> = $finder->B<fetch>(I<$artist>, I<$title> [, I<$source> | I<\@sources> [, I<$limit>]])

Attempt to fetch the lyrics for the given artist and title.
A single source site module can be specified as a string ($source) or multiple 
source modules, ie. [module1, module2...], or "random" or "Cache".
Default:  "random" (search all available sites in random order until lyrics 
found or all available sites have been searched).  This is the primary 
method call, and the only one required (besides B<new>()) to be called to 
obtain lyrics.  $limit (if specified) is an integer number to limit the max. 
number of fetchers to try (normally used with $source = "random") to limit 
the time needed to search for lyrics (before giving up).  If not specified, 
zero, or higher than the number of installed fetchers, then all available 
(installed) fetcher submodules (sites) will be tried (until one succefully 
finds lyrics).

"Cache" is a special value that limits searching to a specified lyrics 
directory on one's local hard drive.  NOTE:  It should NOT be included in 
a list, but used by itself.  If a lyrics directory is specified, Cache will 
automatically be searched first!

If an array reference (a list) of modules are provided, they will be searched 
in the order they appear in the list.

The currently-installed and supported modules are:  ApiLyricsOvh, AZLyrics, 
Genius, Letras, and Musixmatch (NOTE the "x" in the spelling of "Musixmatch")!

Returns lyrics as a string (includes line-breaks appropriate for the user's 
operating system), or an empty string, if no lyrics found.

=item I<$scalar> = $finder->B<image_url>()

Returns a URL for a cover-art image, if one found on the lyrics page.  
Currently, only the LyricFinder::Genius and LyricFinder::Musixmatch 
sites contain cover-art images.  For the other sites, or if no image 
is found, an empty string will be returned if this method is called.

=item I<$scalar> = $finder->B<message>()

Returns the last error string generated, or "Ok" if all's well.

=item [ I<$scalar> | I<@array> ] = $finder->B<order>()

Returns either a comma-separated list or an array of the site modules 
tried by the last fetch.  This is useful to see what sites are 
being tried and in what order if I<random> order is being used.  Similar 
to B<tried>(), except all sites being considered are shown.

=item I<$scalar> = $finder->B<site>()

Returns the actual base URL of the site that successfully fetched the lyrics 
in the last successful fetch (or an empty string if the fetch failed).

=item I<$scalar> = $finder->B<source>()

Returns the name of the module that successfully fetched the lyrics in 
the last successful fetch (or "none" if the fetch failed).

=item [ I<$arrayref> | I<@array> ] = $finder->B<sources>()

Returns a list of available site modules.  Similar to Lyric::Fetcher's 
I<available_fetchers>() function.

=item [ I<$scalar> | I<@array> ] = $finder->B<tried>()

Returns either a comma-separated list or an array of the site modules 
actually tried when fetching lyrics.  This is useful to see what sites were 
actually hit and in what order if I<random> order is being used.  Similar 
to B<order>(), except only sites actually hit are shown (the last one is 
the one that successfully fetched the lyrics.

=item I<$scalar> = $finder->B<url>()

Returns the actual URL used to fetch the lyrics from the site (includes 
the actual formatted search arguments passed to the site).  This can be 
helpful in debugging, etc.

NOTE:  If caching is being used and lyrics are found and fetched from 
the cache directory, B<site>() will return the full filename of the cache 
file fetched.

=item $LyricFinder::VERSION

The current version# of LyricFinder

=back

=head1 DEPENDENCIES

L<HTML::Strip>, L<HTTP::Request>, L<LWP::UserAgent>, L<URI::Escape>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lyricFinder at rt.cpan.org>, 
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LyricFinder>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as 
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LyricFinder

=head1 SEE ALSO

Fauxdacious media player - (L<https://wildstar84.wordpress.com/fauxdacious>)

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LyricFinder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LyricFinder>

=item * Search CPAN

L<http://search.cpan.org/dist/LyricFinder/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2020 Jim Turner.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Original Lyrics::Fetcher::* work:

Copyright (C) 2007-2020 David Precious.

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself, either Perl version 5.8.7 or, at your option, 
any later version of Perl 5 you may have available.

Legal disclaimer: I have no connection with the owners of www.genius.com. Lyrics 
fetched by this script may be copyrighted by the authors, it's up to you to 
determine whether this is the case, and if so, whether you are entitled to 
request/use those lyrics. You will almost certainly not be allowed to use the 
lyrics obtained for any commercial purposes.  

All comments / suggestions / 
bug reports gratefully received (ideally use the RT installation at 
L<https://rt.cpan.org/> or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=LyricFinder>, 
or mail me direct if you prefer).

Developed on Github at L<https://github.com/bigpresh/LyricFinder>

Previously:
Copyright 2003 Sir Reflog <reflog@mail15.com>. 
Copyright 2003 Zachary P. Landau <kapheine@hypa.net>

=cut