package LyricFinder::Cache;

use 5.008000;
use strict;
use warnings;
use Carp;

my $Source = 'Cache';

# the Default HTTP User-Agent we'll send:
our $AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0";

sub new
{
	my $class = shift;

	my $self = {};
	$self->{'agent'} = $AGENT;
	$self->{'cache'} = '';
	$self->{'Error'} = 'Ok';
	$self->{'Site'} = '';
	$self->{'Url'} = '';
	$self->{'Credits'} = [];

	my %args = @_;
	foreach my $i (keys %args) {
		if ($i =~ s/^\-//) {
			$self->{$i} = $args{"-$i"};
		} else {
			$self->{$i} = $args{$i};
		}
	}

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub source {
	return $Source;
}

sub url {
	my $self = shift;
	return $self->{'Url'};
}

sub order {
	return wantarray ? ($Source) : $Source;
}

sub tried {
	return order ();
}

sub credits {
	my $self = shift;
	return wantarray ? @{$self->{'Credits'}} : join(', ', @{$self->{'Credits'}});
}

sub message {
	my $self = shift;
	return $self->{'Error'};
}

sub site {
	my $self = shift;
	return 'none'  unless (defined($self) && $self->{'cache'});
	return 'file://'.$self->{'cache'};
}

# Allow user to specify a different user-agent:
sub agent {
	my $self = shift;

	if (defined $_[0]) {
		$self->{'agent'} = $_[0];
	} else {
		return $self->{'agent'};
	}
}

sub cache {
	my $self = shift;

	if (defined $_[0]) {
		$self->{'cache'} = $_[0];
	} else {
		return $self->{'cache'};
	}
}

sub fetch {
	my $self = shift;
	my ($artist, $song) = @_;

	# reset the error var, change it if an error occurs.
	$self->{'Error'} = 'Ok';
	$self->{'Url'} = '';

	unless ($artist && $song) {
		carp($self->{'Error'} = 'e:Cache.fetch() called without artist and song!');
		return;
	}

	unless ($self->{'cache'}) {
		carp($self->{'Error'} = 'e:Cache.fetch() called without a cache directory specified!');
		return;
	}

	if ($self->{'cache'} =~ /^\>/) {
		carp($self->{'Error'} = 'e:Cache.fetch() called but cache directory writeonly (">" specified)!');
		return;
	}

	$artist =~ s#\s*\/.*$##;  #ONLY USE 1ST ARTIST, IF MORE THAN ONE!

	# Their URLs look like e.g.:
	#https://www.musixmatch.com/lyrics/Artist-name/Title

	my $LOCALDIR = $self->{'cache'};
	$LOCALDIR =~ s#^\<##;          #STRIP OFF ANY LEADING DIRECTIONAL INDICATOR.
	$LOCALDIR =~ s#\\#\/#g;        #DE-DOSIFY WINDOWS FNS.
	$LOCALDIR .= '/'  unless ($LOCALDIR =~ m#\/#);
	$LOCALDIR =~ s#^file\:\/\/##;  #CONVERT TO FILE IF URI

	unless (-d "$LOCALDIR") {
		carp($self->{'Error'} = 'e:Cache.fetch() called but cache directory not a valid directory');
		return;
	}

	$self->{'Url'} = $LOCALDIR . '/' . $artist . '/' . $song . '.lrc';
	if (-f $self->{'Url'} && open (IN, $self->{'Url'})) {
		my $lyrics = '';
		while (<IN>) {
			$lyrics .= $_;
		}
		close IN;
		$lyrics = $self->_parse($lyrics);
		return $lyrics;
	} else {
		$self->{'Error'} = 'e:Cache - Lyrics not found';
		return;
	}
}

sub save {
	my ($self, $artist, $song, $lyrics) = @_;

	return 0  if ($self->{'cache'} =~ /^\</);  #NO SAVE IF CACHE IS INPUT ONLY.

	my $LOCALDIR = $self->{'cache'};
	$LOCALDIR =~ s#\\#\/#g;       #DE-DOSIFY WINDOWS FNS.
	$LOCALDIR .= '/'  unless ($LOCALDIR =~ m#\/$#);
	$LOCALDIR =~ s#^file\:\/\/##; #CONVERT TO FILE IF URI
	if (-d "$LOCALDIR") {
		(my $artistDir = $LOCALDIR . $artist) =~ s/([\&])/\\$1/g;
		mkdir "$artistDir"  unless (-d $artistDir);
		if (-d "$artistDir") {
			(my $songFid = $LOCALDIR . $artist . '/' . $song . '.lrc') =~ s/([\&])/\\$1/g;
			if (open OUT, ">$songFid")
			{
				print OUT $lyrics;
				close OUT;
				return 1;
			}
			else
			{
				$self->{'Error'} = "e:$Source - Could not cache lyrics for ($artist, $song) to ($songFid) (could not open file: $!)!\n";
			}
		}
		else
		{
			$self->{'Error'} = "e:$Source - Could not cache lyrics for ($artist, $song) dir ($artistDir) still does not exist?!\n";
		}
	}
	return 0;
}

# Internal use only functions:

sub _parse {
	my $self = shift;
	my $text = shift;

	if ($text =~ /\w/) {
		# normalize Windowsey \r\n sequences:
		$text =~ s/\r+//gs;
		# strip off pre & post padding with spaces:
		$text =~ s/^ +//mg;
		$text =~ s/ +$//mg;
		# clear up repeated blank lines:
		$text =~ s/(\R){2,}/\n\n/gs;
		# and remove any blank top lines:
		$text =~ s/^\R+//s;
		$text =~ s/\R\R+$/\n/s;
		$text .= "\n"  unless ($text =~ /\n$/s);
		# now fix up for either Windows or Linux/Unix:
		$text =~ s/\R/\r\n/gs  if ($^O =~ /Win/);

		return $text;
	} else {
		carp "e:$Source - Failed to identify lyrics in cache.";
		return;
	}
}   # end of sub parse

1;

__END__

=head1 NAME

LyricFinder::Cache - Fetch song lyrics from and save lyrics to a local directory.

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

    use LyricFinder::Cache;

    # create a new finder object:
    my $finder = new LyricFinder::Cache(-cache => '/tmp/lyrics');

    # fetch lyrics for a song from our local directory:
    # (The local file must be:  "/tmp/lyrics/Pink Floyd/Echos.lrc")
    print $finder->fetch('Pink Floyd','Echoes');

    # To fetch the source (site) name and base url:
    # (Here, this will return "cache" and "/tmp/lyrics")!
    print "(Lyrics courtesy: ".$finder->source().")\n";
    print "site url:  ".$finder->site().")\n";


=head1 DESCRIPTION

LyricFinder::Cache accepts an artist name and song title, searches 
a specified local directory tree for song lyrics, and, if found, returns 
them as a string.  It's designed to be called by LyricFinder, but can be used 
directly as well.  In LyricFinder, it is invoked by specifying 
I<"Cache"> as the third argument of the B<fetch>() method.  When used with 
LyricFinder, with the other site modules, it can also fetch lyrics that 
already exist in this specified "cache" directory, but if not, lyrics will 
then be fetched from the other site module(s) and then LyricFinder::Cache 
will save them to the "cache" directory automatically.

In case of problems with fetching lyrics, the error string will be returned by 
$finder->message().  If all goes well, it will have 'Ok' in it.

=head1 INSTALLATION

This module is installed automatically with LyricFinder installation.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new> I<LyricFinder::Cache>([ I<options> ])

Creates a new finder object for fetching lyrics.  The same finder 
object can be used for multiple fetches, so this normally only needs to be 
called once.

I<options> is a hash of option/value pairs (ie. "-option" => "value").  
The currently-supported options are:  

=over 4

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

NOTE:  If using this module directly for fetching, specifying ">" as 
the directional indicator will be useless (no lyrics will be returned)!

Directory must be a valid directory, but may be specified as either a path 
(ie. "/home/user/lyrics") or a URI (ie. "file:///home/user/lyrics") or 
with a limiting directional indicator, ie. "</home/user/lyrics".  It may 
or may not have a trailing "/" (ie. "/home/user/lyrics/").

NOTE:  A valid directory MUST be specified for this module to even work!

NOTE:  This value will be overridden if $founder->cache("directory") is 
called!

=item B<-debug> => I<number>

Specifies whether debug information will be displayed (0: no, >0: yes).
Default I<0> (no).  I<1> will display debug info.  There is currently only 
one level of debug verbosity.

=back 

=item [ I<$current-agent string> = ] $finder->B<agent>( [ I<user-agent string> ] )

This method, included here for compatibility only, is only useful for the 
other site modules that access the internet, but is ignored here.

Set the desired user-agent (ie. browser name) to pass to www.azlyrics.com.  
Some sites are pickey about receiving a user-agent 
string that corresponds to a valid / supported web-browser to prevent their 
sites from being "scraped" by programs, such as this.  

Default:  I<"Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0">

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

NOTE:  If using this module directly for fetching, specifying ">" as 
the directional indicator will be useless (no lyrics will be returned)!

Directory must be a valid directory, but may be specified as either a path 
(ie. "/home/user/lyrics") or a URI (ie. "file:///home/user/lyrics") or 
with a limiting directional indicator, ie. "</home/user/lyrics".  It may 
or may not have a trailing "/" (ie. "/home/user/lyrics/").

If no argument is passed, it returns the current GENERAL cache directory 
string in effect (but a different directory option is specified for a specific 
module may have been specified and used by THAT module - see B<new>() 
options above).

NOTE:  A valid directory MUST be specified for this module to even work!

NOTE:  This will override any B<-cache> option value specified in B<new>()!

=item [ I<$scalar> | I<@array> ] = $finder->B<credits>()

Returns either a comma-separated list or an array of names credited by 
the site with posting the lyrics on the site (if any) or an empty 
string, if none found.  NOTE:  This function is in all the site modules for 
compatability, but is inapplicable here, so an empty string or array will 
always be returned.

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
(this module's) name, either as "Cache" or ("Cache").

=item I<$scalar> = $finder->B<save>(I<$artist>, I<$song>, I<$lyrics>)

This function is called internally by the other site modules to save (cache) 
the lyrics fetched by the other site modules to the user-specified cache 
directory.  It is unique to this module and should never be called 
by the user.

=item I<$scalar> = $finder->B<site>()

Returns the actual base URL of the site that successfully fetched the lyrics 
in the last successful fetch (or an empty string if the fetch failed).  
This site's base URL on success is always the specified "cache" directory in 
URI format:  ie. "file:///home/user/Music/LyricsFiles".

=item I<$scalar> = $finder->B<source>()

Returns the name of the module that successfully fetched the lyrics in 
the last successful fetch (or "none" if the fetch failed).
This site's module name on success is always:  "I<Cache>".

=item [ I<$scalar> | I<@array> ] = $finder->B<tried>()

LyricFinder method, included here for compatibility only that isn't 
particularly useful here.  

Returns either a comma-separated list or an array of the site modules 
actually tried when fetching lyrics.  This is useful to see what sites were 
actually hit and in what order if I<random> order is being used.  Similar 
to B<order>(), except only sites actually hit are shown (the last one is 
the one that successfully fetched the lyrics.

In the case of site submodules, such as this, it simply returns the source 
(this module's) name, either as "Cache" or ("Cache").

=item I<$scalar> = $finder->B<url>()

Returns the actual URL used to fetch the lyrics from the site (includes 
the actual formatted search arguments passed to the site).  This can be 
helpful in debugging, etc.

NOTE:  This module will return the full filename of the cache file fetched 
in URI format (ie. file://I<cache_directory>/I<artist name>/<song title>.lrc).

=back

=head1 DEPENDENCIES

-none-

=head1 BUGS

Please report any bugs or feature requests to C<bug-lyricFinder-cache 
at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LyricFinder-Cache>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LyricFinder::Cache

=head1 SEE ALSO

LyricFinder - (L<LyricFinder>)

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LyricFinder-Cache>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LyricFinder-Cache>

=item * Search CPAN

L<http://search.cpan.org/dist/LyricFinder-Cache/>

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

=cut
