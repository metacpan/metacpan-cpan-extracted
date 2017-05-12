package MP3::PodcastFetch::Feed::Item;

use strict;
use warnings;
use Class::Struct;
use Date::Parse 'str2time';

=head1 NAME

MP3::PodcastFetch::Feed::Item -- Structure for recording Podcast episode information

=head1 SYNOPSIS

 use MP3::PodcastFetch::Feed::Item
 my $item = MP3::PodcastFetch::Feed::Item->new(title=>'my podcast',
                                               description =>'my very own podcast'
                                               );
 my $title = $item->title;
 my $description = $item->description;
 my $url         = $item->url;

=head1 DESCRIPTION

This is a utility class for MP3::PodcastFetch that defines accessors
for various attributes of a Podcast episode, including its title,
description, author and URL.

=head2 Accessors

The following accessors are defined. They can be used to get and/or
fetch the current value:

 title         Episode title
 description   Episode description
 url           Podcast file's downloaded URL (sound file URL)
 link          Podcast episode's web page (HTML file URL)
 guid          Episode unique ID
 pubDate       Episode publication date (in original format)
 author        Episode author
 duration      Episode's duration
 timestamp     Episode's modification date, in seconds

=cut

struct (
	title       => '$',
	description => '$',
	guid        => '$',
	pubDate     => '$',
	author      => '$',
	link        => '$',
	url         => '$',
        duration    => '$',
	);

sub timestamp {
  my $date = shift->pubDate or return 0;
  str2time($date);
}


1;


__END__

=head1 SEE ALSO

L<podcast_fetch.pl>,
L<MP3::PodcastFetch>,
L<MP3::PodcastFetch::Feed>,
L<MP3::PodcastFetch::Feed::Channel>,
L<MP3::PodcastFetch::Feed::Item>,
L<MP3::PodcastFetch::TagManager>,

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2006 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
