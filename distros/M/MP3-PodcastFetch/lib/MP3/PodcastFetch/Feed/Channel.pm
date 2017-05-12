package MP3::PodcastFetch::Feed::Channel;

use strict;
use warnings;
use Class::Struct;

=head1 NAME

MP3::PodcastFetch::Feed::Channel -- Structure for recording Podcast channel information

=head1 SYNOPSIS

 use MP3::PodcastFetch::Feed::Channel;
 my $channel = MP3::PodcastFetch::Feed::Channel->new(title=>'my feed',
                                                     description =>'my very own feed'
                                                    );
 my $title = $channel->title;
 $channel->add_item($new_items);
 my @items = $channel->items;

=head1 DESCRIPTION

This is a utility class for MP3::PodcastFetch that defines accessors
for various attributes of a Podcast Channel, including channel title,
description, author, and the list of podcast episodes currently
available.

=head2 Accessors

The following accessors are defined. They can be used to get and/or
fetch the current value:

 title         Channel title
 description   Channel description
 guid          Channel unique ID
 pubDate       Channel publication date (in original format)
 author        Channel author
 link          Link to Channel URL
 items         List of MP3::PodcastFetch::Feed::Item objects corresponding to
                  podcast episodes currently available (read only accessor;
                  use add_item() to add new items).

In addition, this class defines an add_item() method, which will add a
list of MP3::PodcastFetch::Feed::Item objects to the set of podcast
episodes.

=cut

struct (
	'MP3::PodcastFetch::Feed::Channel' => {
					       title       => '$',
					       description => '$',
					       guid        => '$',
					       pubDate     => '$',
					       author      => '$',
					       link        => '$',
					       duration    => '$',
					      }
       );

sub add_item {
  my $self = shift;
  push @{$self->{'MP3::PodcastFetch::Feed::Channel::items'}},@_;
}

sub items {
  my $self = shift;
  my $items = $self->{'MP3::PodcastFetch::Feed::Channel::items'} or return;
  @$items;
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
