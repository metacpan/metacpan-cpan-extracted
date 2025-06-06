package LyricFinder::AZLyrics;

use strict;
use warnings;
use Carp;
use HTML::Strip;
use parent 'LyricFinder::_Class';

our $haveLyricsCache;
BEGIN {
	$haveLyricsCache = 0;
	eval "use LyricFinder::Cache; \$haveLyricsCache = 1; 1";
}

my $Source = 'AZLyrics';
my $Site   = 'https://www.azlyrics.com';
my $DEBUG  = 0;

sub new
{
	my $class = shift;

	my $self = $class->SUPER::new($Source, @_);
	@{$self->{'_fetchers'}} = ($Source);
	unshift(@{$self->{'_fetchers'}}, 'Cache')  if ($haveLyricsCache
			&& $self->{'-cache'} && $self->{'-cache'} !~ /^\>/);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub fetch {
	my ($self, $artist_in, $song_in) = @_;

	$self->_debug("AZLyrics::fetch($artist_in, $song_in)!");

	return ''  unless ($self->_check_inputs($artist_in, $song_in));
	return ''  if ($self->{'Error'} ne 'Ok');

	# first, see if we've got it cached:
	$self->_debug("i:haveCache=$haveLyricsCache= -cachedir=".$self->{'-cache'}."=");
	if ($haveLyricsCache && $self->{'-cache'} && $self->{'-cache'} !~ /^\>/) {
		my $cache = new LyricFinder::Cache(%{$self});
		if ($cache) {
			my $lyrics = $cache->fetch($artist_in, $song_in);
			if (defined($lyrics) && $lyrics =~ /\w/) {
				$self->_debug("..Got lyrics from cache.");
				$self->{'Source'} = 'Cache';
				$self->{'Site'} = $cache->site();
				$self->{'Url'} = $cache->url();

				return $lyrics;
			}
		}
	}

	$self->{'Site'} = $Site;

	(my $artist = $artist_in) =~ s#\s*\/.*$##;    #ONLY USE 1ST ARTIST, IF MORE THAN ONE!
	$artist =~ s/[^a-z0-9]//gi;
	(my $song = $song_in) =~ s/[^a-z0-9]//gi;

	# Their URLs look like e.g.:
	# https://www.azlyrics.com/lyrics/direstraits/heavyfuel
	$self->{'Url'} = $Site . '/lyrics/'
			. join('/', lc $artist, lc $song) . '.html';

	my $lyrics = $self->_web_fetch($artist_in, $song_in);
	if ($lyrics && $haveLyricsCache && $self->{'-cache'} && $self->{'-cache'} !~ /^\</) {
		$self->_debug("=== WILL CACHE LYRICS! ===");
		# cache the fetched lyrics, if we can:
		my $cache = new LyricFinder::Cache(%{$self});
		$cache->save($artist_in, $song_in, $lyrics)  if ($cache);
	}
	return $lyrics;
}

# Internal use only functions:

sub _parse {
	my $self = shift;
	my $html = shift;

	$self->_debug("AZLyrics::_parse()!");
	if (my ($goodbit) = $html =~
			m{our licensing agreement. Sorry about that. \-\-\>(.+?)\<\/div\>}msi)
	{
		# Scoop out any credits for these lyrics:
		while ($html =~ s{Thanks\s+to\s+(.+)}{}xi) {
			(my $creditlist = $1) =~ s/\s+for\b.+$//o;
			push @{$self->{'Credits'}}, split(/\,\s*/, $creditlist);
		}

		my $hs   = HTML::Strip->new();
		my $text = $hs->parse($goodbit);

		return $self->_normalize_lyric_text($self->_html2text($text));
	} else {
		carp($self->{'Error'} = "e:$Source - Failed to identify lyrics on result page.");
		return '';
	}
}   # end of sub parse

1

__END__

=head1 NAME

LyricFinder::AZLyrics - Fetch song lyrics from www.azlyrics.com.

=head1 AUTHOR

This module is Copyright (c) 2020-2025 by

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

    use LyricFinder::AZLyrics;

    # create a new finder object:
    my $finder = new LyricFinder::AZLyrics();

    # fetch lyrics for a song from https://www.azlyrics.com:
    print $finder->fetch('Pink Floyd','Echoes');

    # To fetch the source (site) name and base url:
    print "(Lyrics courtesy: ".$finder->source().")\n";
    print "site url:  ".$finder->site().")\n";

    # To do caching:
    $finder->cache('/tmp/lyrics');
    #-or-
    my $localfinder = new LyricFinder::AZLyrics(-cache => '/tmp/lyrics');


=head1 DESCRIPTION

LyricFinder::AZLyrics accepts an artist name and song title, searches 
https://www.azlyrics.com for song lyrics, and, if found, returns them as a 
string.  It's designed to be called by LyricFinder, but can be used 
directly as well.  In LyricFinder, it is invoked by specifying 
I<"AZLyrics"> as the third argument of the B<fetch>() method.

In case of problems with fetching lyrics, the error string will be returned by 
$finder->message().  If all goes well, it will have 'Ok' in it.

=head1 INSTALLATION

This module is installed automatically with LyricFinder installation.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new> I<LyricFinder::AZLyrics>([ I<options> ])

Creates a new finder object for fetching lyrics.  The same finder 
object can be used for multiple fetches, so this normally only needs to be 
called once.

I<options> is a hash of option/value pairs (ie. "-option" => "value").  
If an "-option" is specified with no "value" given, the default value will 
be I<1> ("I<true>").  The currently-supported options are:  

=over 4

=item B<-agent> => I<"user-agent string">

Specifies an alternate "user-agent" string sent to www.azlyrics.com when 
attempting to fetch lyrics.  Set the desired user-agent (ie. browser name) to 
pass to www.azlyrics.com.  Some sites are pickey about receiving a user-agent 
string that corresponds to a valid / supported web-browser to prevent their 
sites from being "scraped" by programs, such as this.  

Default:  I<"Mozilla/5.0 (X11; Linux x86_64; rv:112.0) Gecko/20100101 Firefox/112.0">.

NOTE:  This value will be overridden if $finder->agent("agent") is 
called!

=item B<-cache> => I<"directory">, and B<-debug> => I<integer>.

Specifies a directory (ie. "/home/user/Music/Lyricsfiles") to be used for 
disk caching.  If specified, this directory will be searched for a matching 
lyrics (.lrc) file 
(in this example, "/home/user/Music/LyricsFiles/I<artist>/I<title>.lrc").
If no matching lyrics file is found (and the search module list is not 
specifically set to "Cache" (and lyrics are found on the internet), then 
the lyrics will be saved to the directory under "I<artist>/I<title>.lrc".

Default:  none (no caching)

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

NOTE:  This value will be overridden if $finder->cache("directory") is 
called!

=item B<-debug> => I<number>

Specifies whether debug information will be displayed (0: no, >0: yes).
Default I<0> (no).  I<1> will display debug info.  There is currently only 
one level of debug verbosity.

=back 

=item [ I<$current-agent-string> = ] $finder->B<agent>( [ I<user-agent-string> ] )

Get / Set the desired user-agent (ie. browser name) to pass to www.azlyrics.com.  
Some sites are pickey about receiving a user-agent 
string that corresponds to a valid / supported web-browser to prevent their 
sites from being "scraped" by programs, such as this.  

Default:  I<"Mozilla/5.0 (X11; Linux x86_64; rv:112.0) Gecko/20100101 Firefox/112.0">

If no argument is passed, it returns the current GENERAL user-agent string in 
effect (but a different agent option is specified for a specific module may 
have been specified and used by THAT module - see B<new>() options above).

NOTE:  This will override any B<-agent> option value specified in B<new>()!

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

=item [ I<$scalar> | I<@array> ] = $finder->B<credits>()

Returns either a comma-separated list or an array of names credited by 
the site with posting the lyrics on the site (if any) or an empty 
string, if none found.

=item I<$string> = $finder->B<fetch>(I<$artist>, I<$title>)

Attempt to fetch the lyrics for the given artist and title.  
This is the primary method call, and the only one required to be called 
(besides B<new>()) to obtain lyrics.

Returns lyrics as a string (includes line-breaks appropriate for the user's 
operating system), or an empty string, if no lyrics found.

=item I<$scalar> = $finder->B<message>()

Returns the last error string generated, or "Ok" if all's well.

=item [ I<$scalar> | I<@array> ] = $finder->B<order>()

LyricFinder method, included here for compatibility only that isn't 
particularly useful here.  

Returns either a comma-separated list or an array of the site modules 
tried by the last fetch.  This is useful to see what sites are 
being tried and in what order if I<random> order is being used.  Similar 
to B<tried>(), except all sites being considered are shown.

In the case of site submodules, such as this, it simply returns the source 
(this module's) name, either as "AZLyrics" or ("AZLyrics").

=item I<$scalar> = $finder->B<site>()

Returns the actual base URL of the site that successfully fetched the lyrics 
in the last successful fetch (or an empty string if the fetch failed).  
This site's base URL on success is always:  "I<https://www.azlyrics.com>".

NOTE:  If caching is being used and lyrics are found and fetched from 
the cache directory, B<site>() will return the cache directory in URI format, 
ie. "file:///home/user/Music/LyricsFiles"!

=item I<$scalar> = $finder->B<source>()

Returns the name of the module that successfully fetched the lyrics in 
the last successful fetch (or "none" if the fetch failed).
This site's module name on success is always:  "I<AZLyrics>".

NOTE:  If caching is being used and lyrics are found and fetched from 
the cache directory, B<source>() will return "I<Cache>"!

=item [ I<$scalar> | I<@array> ] = $finder->B<tried>()

LyricFinder method, included here for compatibility only that isn't 
particularly useful here.  

Returns either a comma-separated list or an array of the site modules 
actually tried when fetching lyrics.  This is useful to see what sites were 
actually hit and in what order if I<random> order is being used.  Similar 
to B<order>(), except only sites actually hit are shown (the last one is 
the one that successfully fetched the lyrics.

In the case of site submodules, such as this, it simply returns the source 
(this module's) name, either as "AZLyrics" or ("AZLyrics").

=item I<$scalar> = $finder->B<url>()

Returns the actual URL used to fetch the lyrics from the site (includes 
the actual formatted search arguments passed to the site).  This can be 
helpful in debugging, etc.

NOTE:  If caching is being used and lyrics are found and fetched from 
the cache directory, B<site>() will return the full filename of the cache 
file fetched.

=back

=head1 DEPENDENCIES

L<HTML::Strip>, L<HTTP::Request>, L<LWP::UserAgent>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lyricFinder-azlyrics 
at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LyricFinder-AZLyrics>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LyricFinder::AZLyrics

=head1 SEE ALSO

LyricFinder - (L<LyricFinder>)

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LyricFinder-AZLyrics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LyricFinder-AZLyrics>

=item * Search CPAN

L<http://search.cpan.org/dist/LyricFinder-AZLyrics/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2020-2025 Jim Turner.

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

=cut
