package MP3::PodcastFetch::Feed;

use strict;
use base 'MP3::PodcastFetch::XML::SimpleParser';
use MP3::PodcastFetch::Feed::Channel;
use MP3::PodcastFetch::Feed::Item;

use LWP::UserAgent;

=head1 NAME

MP3::PodcastFetch:Feed -- Fetch and parse an RSS file

=head1 SYNOPSIS

 use MP3::PodcastFetch::Feed;
 my $feed = MP3::PodcastFetch::Feed->new('http://www.npr.org/rss/podcast.php?id=500001');

 $feed->timeout(100);
 my @channels = $feed->read_feed;
 for my $c (@channels) {
   print "Title = ",$c->title,"\n";
 }

=head1 DESCRIPTION

This package provides convenient downloading and parsing of the
subscription information in an RSS feed URL. It was written to support
the podcast_fetch.pl script.

To use it, create an MP3::PodcastFetch:Feed object with the desired
RSS URL. Set additional parameters such as timeout values. Then call
the read_feed() method to get a list of
MP3::PodcastFetch::Feed::Channel objects that contain various bits of
information about the podcast subscription.

Internally, it is a subclass of MP3::PodcastFetch::XML::SimpleParser,
a very straightforward sax-based XML parser.

=head2 METHODS

This module implements the following methods:

=over 4

=cut

=item $feed = MP3::PodcastFetch::Feed->new($url)

Create a new MP3::PodcastFetch::Feed object pointing to the indicated
URL. The default fetch timeout is set to 10s.

=cut

sub new {
  my $class = shift;
  my $url   = shift;
  my $self  = $class->SUPER::new();
  $self->url($url);
  $self->timeout(10);
  $self;
}

=item $url = $feed->url([$new_url])

Get or set the  RSS URL.

=cut

sub url {
  my $self = shift;
  my $d    = $self->{url};
  $self->{url} = shift if @_;
  $d;
}

=item $error = $feed->errstr([$new_error])

Get or set an error message. Call errstr() after an unsuccessful fetch
to find out what went wrong.

=cut

sub errstr {
  my $self = shift;
  my $d    = $self->{error};
  $self->{error} = shift if @_;
  $d;
}

=item $timeout = $feed->timeout([$new_timeout])

Get or set the timeout for the RSS XML file fetch operation. The
default timeout is 10s, meaning that the module will wait a maximum of
10 seconds to get a response from the remote server.

=cut

sub timeout {
  my $self = shift;
  my $d    = $self->{timeout};
  $self->{timeout} = shift if @_;
  $d;
}

=item $env_proxy = $feed->env_proxy([$env_proxy])

Get or set the proxy usage for the RSS XML file fetch operation. The
default is without proxy,

=cut

sub env_proxy {
  my $self	= shift;
  my $d		= $self->{env_proxy};
  $self->{env_proxy} = shift if @_;
  $d;
}

=item @channels = $feed->read_feed()

This is the main workhorse method of the module. It tries to read and
parse the RSS file at the previously-indicated URL. If successful, it
returns a list of MP3::PodcastFetch::Feed::Channel objects containing
information about each channel and the podcast episodes contained
within them. If unsuccessful, it returns an empty list. You can use
the errstr() method to find out what went wrong.

=cut

sub read_feed {
  my $self = shift;
  my $url  = $self->url or return;
  my $ua = LWP::UserAgent->new;
  $ua->env_proxy if $self->env_proxy;
  $ua->timeout($self->timeout);
  my $response = $ua->get($url,':content_cb' => sub { $self->parse($_[0]) } );
  $self->eof;
  unless ($response->is_success) {
    $self->errstr($response->status_line);
    return;
  }
  return $self->results;
}

=back

=head2 Internal methods

The following methods are used during the parse of the downloaded RSS
file. See MP3::PodcastFetch::XML::SimpleParser for a description of
how they work.

=over 4

=item t_channel

=cut

sub t_channel {
  my $self = shift;
  my $attrs = shift;
  if ($attrs) { # tag is starting
    push @{$self->{current}},MP3::PodcastFetch::Feed::Channel->new;
    return;
  } else {
    $self->add_object(pop @{$self->{current}});
  }
}

=item t_item

=cut

sub t_item {
  my $self  = shift;
  my $attrs = shift;
  if ($attrs) { # tag is starting
    push @{$self->{current}},MP3::PodcastFetch::Feed::Item->new;
    return;
  } else {
    my $item =pop @{$self->{current}};
    my $channel = $self->{current}[-1] or return;
    $channel->add_item($item);
  }
}

=item t_title

=cut

sub t_title {
  my $self  = shift;
  my $attrs = shift;
  unless ($attrs) { # tag is ending
    my $item = $self->{current}[-1] or return;
    $item->title($self->char_data);
  }
}

=item t_description

=cut

sub t_description {
  my $self  = shift;
  my $attrs = shift;
  unless ($attrs) { # tag is ending
    my $item = $self->{current}[-1] or return;
    $item->description($self->char_data);
  }
}

=item t_guid

=cut

sub t_guid {
  my $self  = shift;
  my $attrs = shift;
  unless ($attrs) { # tag is ending
    my $item = $self->{current}[-1] or return;
    $item->guid($self->char_data);
  }
}

=item t_pubDate

=cut

sub t_pubDate {
  my $self = shift;
  my $attrs = shift;
  unless ($attrs) {
    my $item = $self->{current}[-1] or return;
    $item->pubDate($self->char_data);
  }
}

=item t_link

=cut

sub t_link {
  my $self = shift;
  my $attrs = shift;
  unless ($attrs) {
    my $item = $self->{current}[-1] or return;
    $item->link($self->char_data);
  }
}

=item t_author

=cut

sub t_author {
  my $self = shift;
  my $attrs = shift;
  unless ($attrs) {
    my $item = $self->{current}[-1] or return;
    $item->author($self->char_data);
  }
}

=item t_itunes_author

=cut

*t_itunes_author = \&t_author;

sub t_itunes_duration {
  my $self = shift;
  my $attrs = shift;
  unless ($attrs) {
    my $item = $self->{current}[-1] or return;
    my @time = split ':',$self->char_data;
    my $secs = pop @time || 0;
    my $mins = pop @time || 0;
    my $hrs  = pop @time || 0;
    $item->duration($hrs*60*60+$mins*60+$secs);
  }
}

=item t_enclosure

=cut

sub t_enclosure {
  my $self = shift;
  my $attrs = shift;
  if ($attrs) {
    my $item = $self->{current}[-1] or return;
    $item->url($attrs->{url});
  }
}

=back

=cut

1;

__END__

=head1 SEE ALSO

L<podcast_fetch.pl>,
L<MP3::PodcastFetch>,
L<MP3::PodcastFetch::Feed::Channel>,
L<MP3::PodcastFetch::Feed::Item>,
L<MP3::PodcastFetch::TagManager>,
L<MP3::PodcastFetch::XML::SimpleParser>

=head1 AUTHOR

Lincoln Stein E<lt>lstein@cshl.orgE<gt>.

Copyright (c) 2006 Lincoln Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
