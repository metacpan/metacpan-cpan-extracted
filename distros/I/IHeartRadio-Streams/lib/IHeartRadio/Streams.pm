=head1 NAME

IHeartRadio::Streams - Fetch actual raw streamable URLs from radio-station websites on IHeartRadio.com

=head1 AUTHOR

This module is Copyright (C) 2017 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	use strict;

	use IHeartRadio::Streams;

	my $station = new IHeartRadio::Streams(<url>);

	die "Invalid URL or no streams found!\n"  unless ($station);

	my @streams = $station->get();

	my $first = $station->get();

	my $best = $station->getBest();

	print "Best stream URL=".$best->{'Url'}."\n";

	my $besturl = $station->getBest('Url');

	my $stationTitle = $station->getStationTitle();
	
	print "Best stream URL=$besturl, Title=$stationTitle\n";

	my @allfields = $station->validFields();

	for (my $i=0; $i<$station->count(); $i++) {

		foreach my $field (@allfields) {

			print "--$field: ".$streams[$i]->{$field}."\n";

		}

	}
	
=head1 DESCRIPTION

IHeartRadio::Streams accepts a valid radio station URL on http://iheart.com and
returns the urls and other information properties for the actual stream URLs 
available for that station.  The purpose is that one needs one of these URLs 
in order to have the option to stream the station in one's own choice of 
audio player software rather than using their web browser and accepting any / 
all flash, ads, javascript, cookies, trackers, web-bugs, and other crapware 
that can come with that method of playing.  The author uses his own custom 
all-purpose audio player called "fauxdacious" (his custom hacked version of 
the open-source "audacious" media player.  "fauxdacious" incorporates this 
module to decode and play iheart.com streams.

One or more streams can be returned for each station.  The available 
properties for each stream returned are normally:  Bandwidth, 
HasPlaylist (1|0), MediaType (ie. MP3, AAC, etc.), Reliability (1-100), 
StreamId (numeric), Type (ie. Live) and Url.

=head1 EXAMPLES

	#!/usr/bin/perl

	use strict;

	use IHeartRadio::Streams;

	my $wbap = new IHeartRadio::Streams('https://www.iheart.com/live/news-talk-820-5350/',
			'secure_shoutcast', 'secure', 'any', '!rtmp');

	die "Invalid URL or no streams found!\n"  unless ($wbap);

	my $streamurl = $wbap->getStream();  #OR:  $wbap->get('stream');

	my $stationname = $wbap->getStationTitle();  #OR: $wbap->get('title');

	my $stationid = $wbap->getStationID();  #OR:  $wbap->get('id');

	my $stationcallletters = $wbap->getFccID();  #OR: $wbap->get('fccid');

	my @allfields = $wbap->validFields();

	my $stationdata = $wbap->get();
	
	print "--$stationid ($stationcallletters): name=$stationname stream=$streamurl\n==========\n";

	foreach my $field (@allfields) {

		print "--$field: ".$stationdata->{$field}."\n";

	}

	print "=========\n";

	my @streamlist = $wbap->get('streams');

	foreach my $stream (@streamlist) {

		print "--stream=$stream\n";

	}

This would print:

--5350 (WBAP-AM): name=Dallas' WBAP - News Talk 820 stream=https://17263.live.streamtheworld.com:443/WBAPAMAAC_SC

==========

--cnt: 6

--fccid: WBAP-AM

--iconurl: https://iscale.iheart.com/catalog/live/5350?ops=fit(100%2C100)

--id: 5350

--imageurl: https://iscale.iheart.com/catalog/live/5350

--plsid: WBAPAMAAC

--streams: ARRAY(0x80c466a8)

--streamtype: secure_pls_stream

--streamurl: https://playerservices.streamtheworld.com/pls/WBAPAMAAC.pls

--title: Dallas' WBAP - News Talk 820

=========

--stream=https://17523.live.streamtheworld.com:443/WBAPAMAAC_SC

--stream=https://16143.live.streamtheworld.com:443/WBAPAMAAC_SC

--stream=https://18653.live.streamtheworld.com:443/WBAPAMAAC_SC

--stream=https://17483.live.streamtheworld.com:443/WBAPAMAAC_SC

--stream=https://17263.live.streamtheworld.com:443/WBAPAMAAC_SC

--stream=https://19293.live.streamtheworld.com:443/WBAPAMAAC_SC

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<streamtype>... ] )

Accepts an iheart.com URL and creates and returns a new station object, or 
I<undef> if the URL is not a valid iHeartRadio station or no streams are found.

The optional I<streamtype> can be one of:  any, secure, secure_pls, pls, 
secure_hls, hls, secure_shortcast, shortcast, secure_rtmp, rtmp, etc.  More 
than one value can be specified to control order of search.  A I<streamtype> 
can be preceeded by an exclamantion point ("!") to reject that type of stream.  

For example, the list:  'secure_shoutcast', 'secure', 'any', '!rtmp' 
would try to find a "secure_shoutcast" (https) shortcast stream, if none found, 
would then look for any secure (https) stream, failing that, would look for 
any valid stream (http or https).  All the while skipping any that are "rtmp" 
streams.  Searching stops when a stream matching the criteria is found.

=item $station->B<get>(I<[property]>)

Returns the value for the property or a hash reference to all the properties.
If the property is 'stream' then either a randomly-selected stream from the 
list of valid streams is returned or an array of all the valid streams 
(depending on context).   If the property is 'streams' then either an array 
or an array reference to all the valid streams (depending on context).

=item $station->B<getStream>([ I<[stream-index]> ])

Similar to B<get>('stream') except it returns a single stream from the list 
corresponding to the numeric I<[stream-index]> position in the list.  If 
negative, then indexed from the last position in the list.  If out of 
bounds, then either the first element (if negative) or last (if positive).

If I<[stream-index]> is not specified, a random index value is used and 
thus a random (but valid) stream url is returned.

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<validFields>()

Returns an array containing all the valid property names found.  This 
list is normally:  (B<cnt>, B<fccid>, B<plsid>, B<iconurl>, B<imageurl>, 
B<stream>, B<streams>, and B<streamurl>).  These can be used in the I<get> functions and 
as the keys in the hash references returned to fetch the corresponding 
property values.

=item $station->B<getStationID>()

Returns the station's IHeartRadio ID, for eample, the station: 
'https://www.iheart.com/live/news-talk-820-5350/' would return "5350".

=item $station->B<getStationTitle>()

Returns the station's title (description).  for eample, the station:
'https://www.iheart.com/live/news-talk-820-5350/' would return:
"Dallas' WBAP - News Talk 820".

=item $station->B<getIconURL>()

Returns the url for the station's "cover art" icon image.

=item $station->B<getImageURL>()

Returns the url for the station's IHeartRadio site's banner image.

=back

=head1 KEYWORDS

iheartradio iheart

=head1 DEPENDENCIES

LWP::Simple

=head1 BUGS

Please report any bugs or feature requests to C<bug-iheartradio-streams at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IHeartRadio-Streams>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IHeartRadio::Streams

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IHeartRadio-Streams>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IHeartRadio-Streams>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IHeartRadio-Streams>

=item * Search CPAN

L<http://search.cpan.org/dist/IHeartRadio-Streams/>

=back

=head1 ACKNOWLEDGEMENTS

The idea for this module came from a Python script that does this same task named 
"getstream", but I wanted a Perl module that could be called from within another 
program!  I do not know the author of getstream.py.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jim Turner.

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

package IHeartRadio::Streams;

use strict;
use warnings;
#use Carp qw(croak);
use LWP::Simple qw();
use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = '1.00';

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(get getBest count validFields);
$Carp::Internal{ (__PACKAGE__) }++;

sub new
{
	my $class = shift;
	my $url = shift;
	my (@okStreams, @skipStreams);
	while (@_) {
		if ($_[0] =~ /^\!/o) {
			(my $i = shift) =~ s/\!//o;
			push @skipStreams, $i;
		} else {
			push @okStreams, shift;
		}
	}	
	@okStreams = ('any')  unless (defined $okStreams[0]);  # one of:  {secure_pls | pls | stw}

	my $self = {};

	return undef  unless ($url);

	my $html = '';
	my $wait = 1;
	for (my $i=0; $i<=2; $i++) {  #WE TRY THIS FETCH 3 TIMES SINCE FOR SOME REASON, DOESN'T ALWAYS RETURN RESULTS 1ST TIME?!:
		$html = LWP::Simple::get($url);
		last  if ($html);
		sleep $wait;
		++$wait;
	}
	return undef  unless ($html);  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	my $html2 = '';
	my $streamhtml0 = ($html =~ /\"streams\"\s*\:\s*\{([^\}]+)\}/) ? $1 : '';
	my $streamhtml;
	return undef  unless ($streamhtml0);

	my $streampattern;

	# OUTTERMOST LOOP TO TRY EACH STREAM-TYPE: (CONSTRAINED IF USER SPECIFIES STREAMTYPES AS EXTRA ARGS TO new())
	foreach my $streamtype (@okStreams) {
		$streamhtml = $streamhtml0;
		$streampattern = $streamtype;
		if ($streamtype eq 'secure') {
			$streampattern = '\"secure_\w+';
		} elsif ($streamtype eq 'any') {
			$streampattern = '\"\w+';
		} else {
			$streampattern = '\"' . $streamtype;
		}
		$self->{'cnt'} = 0;
		$self->{'id'} = ($html =~ m#\"id\"\s*\:\s*([^\,\s]+)#) ? $1 : '';
		$self->{'id'} = $1  if (!$self->{'id'} && ($url =~ m#\/([^\/]+)\/?$#));
		$self->{'fccid'} = ($html =~ m#\"callLetters\"\s*\:\s*\"([^\"]+)\"#i) ? $1 : '';
		$self->{'title'} = ($html =~ m#\"description\"\s*\:\s*\"([^\"]+)\"#) ? $1 : $url;
		$self->{'title'} =~ s#http[s]?\:\/\/www\.iheart\.com\/live\/##;
		$self->{'imageurl'} = ($html =~ m#\"image_src\"\s+href=\"([^\"]+)\"#) ? $1 : '';
		$self->{'iconurl'} = $self->{'imageurl'} . '?ops=fit(100%2C100)';
		# INNER LOOP: MATCH STREAM URLS BY TYPE PATTEREN REGEX UNTIL WE FIND ONE THAT'S ACCEPTABLE (NOT EXCLUDED TYPE):
INNER:  while ($streamhtml =~ s#(${streampattern}_stream)\"\s*\:\s*\"([^\"]+)\"##)
		{
			$self->{'streamtype'} = substr($1, 1);
			$self->{'streamurl'} = $2;
			foreach my $xp (@skipStreams) {
				next INNER  if ($self->{'streamtype'} =~ /$xp/);  #REJECTED STREAM-TYPE.
			}

			# WE NOW HAVE A STREAM THAT MATCHES OUR CONSTRAINTS:
			$self->{'cnt'} = 1  if ($self->{'streamurl'});

			# IF IT'S A ".pls" (PLAYLIST) STREAM, WE NEED TO FETCH THE LIST OF ACTUAL STREAMS:
			# streamurl WILL STILL CONTAIN THE PLAYLIST STREAM ITSELF!
			if ($self->{'cnt'} && $self->{'streamtype'} =~ /pls/) {
				my @streams;
				$self->{'plsid'} = $1  if ($self->{'streamurl'} =~ m#\/([^\/]+)\.pls$#i);
				for (my $i=0; $i<=2; $i++) {  #WE TRY THIS FETCH 3 TIMES SINCE FOR SOME REASON, DOESN'T ALWAYS RETURN RESULTS 1ST TIME?!:
					$html2 = LWP::Simple::get($self->{'streamurl'});
					last  if ($html);
					sleep $wait;
					++$wait;
				}
				$self->{'cnt'} = 0;
				while ($html2 =~ s#File\d+\=(\S+)##) {
					push @streams, $1;
					++$self->{'cnt'};
				}
				$self->{'streams'} = \@streams;  #WE'LL HAVE A LIST OF 'EM TO RANDOMLY CHOOSE ONE FROM:
			}
			else  #NON-pls STREAM, WE'LL HAVE A LIST CONTAINING A SINGLE STREAM:
			{
				$self->{'streams'} = [$self->{'streamurl'}];
			}
			return undef  unless ($self->{'cnt'});   #STEP 2 FAILED - NO PLAYABLE STREAMS FOUND, PUNT!

			#SAVE WHAT PROPERTY NAMES WE HAVE (FOR $station->validFields()):
	
			@{$self->{fields}} = ();
			foreach my $field (sort keys %{$self}) {
				next  if ($field =~ /fields/o);
				push @{$self->{fields}}, $field;
			}

			bless $self, $class;   #BLESS IT!

			return $self;
		}
	}
	return undef;
}

sub get
{
	my $self = shift;
	my $field = shift || 0;

	my @streams = ();
	my $subcnt;
	if ($field) {  #USER SUPPLIED A PROPERTY NAME, FETCH ONLY THAT PROPERTY, (ie. "Url"):
		if ($field eq 'stream') {
			return wantarray ? @{$self->{'streams'}} : ${$self->{'streams'}}[int rand scalar @{$self->{'streams'}}];
		} elsif ($field eq 'streams') {
			return wantarray ? @{$self->{$field}} : $self->{$field};
		} else {
			return wantarray ? ($self->{$field}) : $self->{$field};
		}
	} else {       #NO PROPERTY NAME, RETURN A HASH-REF TO ALL THE PROPERTIES:
		return $self;
	}
}

sub count
{
	my $self = shift;
	return $self->{'cnt'};  #TOTAL NUMBER OF PLAYABLE STREAM URLS FOUND.
}

sub validFields
{
	my $self = shift;
	return @{$self->{'fields'}};  #LIST OF ALL VALID PROPERTY NAME FIELDS.
}

sub getStationID
{
	my $self = shift;
	return $self->{'id'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getPlsID
{
	my $self = shift;
	return $self->{'plsid'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getFccID
{
	my $self = shift;
	return $self->{'fccid'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getStationTitle
{
	my $self = shift;
	return $self->{'title'};  #URL TO THE STATION'S TITLE(DESCRIPTION), IF ANY.
}

sub getStream
{
	my $self = $_[0];
	my $streamNumber = defined($_[1]) ? $_[1] : int rand scalar @{$self->{'streams'}};
	$streamNumber = $#{$self->{'streams'}}  if ($streamNumber > $#{$self->{'streams'}});
	$streamNumber = scalar(@{$self->{'streams'}}) + $streamNumber  if ($streamNumber < 0);
	$streamNumber = 0  if ($streamNumber < 0);
	return ${$self->{'streams'}}[$streamNumber];  #URL TO RANDOM PLAYABLE STREAM.
}

sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getImageURL
{
	my $self = shift;
	return $self->{'imageurl'};  #URL TO THE STATION'S BANNER IMAGE, IF ANY.
}

1
