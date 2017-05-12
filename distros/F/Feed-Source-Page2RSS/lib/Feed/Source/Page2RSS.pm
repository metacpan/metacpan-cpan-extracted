package Feed::Source::Page2RSS;

use warnings;
use strict;

use Carp;
use URI;
use constant {
  RSS => "http://page2rss.com/page/rss",
  ATOM => "http://page2rss.com/page/atom",
};

=head1 NAME

Feed::Source::Page2RSS - Creation of a Atom/RSS feed with the Page2RSS service

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Page2RSS create a Atom/RSS feed to monitor a webpage. This module help you to
create these feeds.

  use Feed::Source::Page2RSS;
  
  my $feed = Feed::Source::Page2RSS->new( url => "http://www.google.com", feed_type => "rss" );
  my $feed_url = $feed->url_feed();
  
  or
  
  my $feed = Feed::Source::Page2RSS->new( url => "http://www.google.com" );
  my $atom = $feed->atom_feed();
  
  is equivalent to 
  
  my $feed = Feed::Source::Page2RSS->new( url => "http://www.google.com" );
  $feed->feed_type('atom');
  my $atom = $feed->url_feed();
  
  or
  
  my $feed = Feed::Source::Page2RSS->new( url => "http://www.google.com" );
  my $rss = $feed->rss_feed();

  is equivalent to 
  
  my $feed = Feed::Source::Page2RSS->new( url => "http://www.google.com" );
  $feed->feed_type('rss');
  my $rss = $feed->url_feed();
  
=head1 FUNCTIONS

=head2 new

Constructor of the Feed::Source::Page2RSS object. You can spcecify the
following options :

=over 4

=item url

URL to monitor

=item feed_type

Feed type of the returned URL. Possible values are RSS and Atom. 

=back

=cut

sub new {
  my ($class, %args) = @_;
  my $self;
  $self->{params}{url} = $args{url} if exists $args{url};
  $self->{feed_type} = uc $args{feed_type} || "RSS";
  bless $self, $class;
  $self;
}

=head2 feed_type

Adjust the feed type. Possible value are RSS and Atom. 

=cut

sub feed_type {
  my $self = shift;
  $self->{feed_type} = uc shift if @_;
}

=head2 url_feed

Return the URL feed.

=cut

sub url_feed {
  my $self = shift;
  if (exists $self->{params}{url}) {
    my $uri;
    if ($self->{feed_type} eq "RSS") {
      $uri = URI->new(RSS);
    } else {
      $uri = URI->new(ATOM)
    }
    $uri->query_form( $self->{params} );
    return $uri->as_string();
  } else {
    croak "You must specify an URL to monitor";
  }
  
}

=head2 atom_feed

Return the Atom URL feed. 

=cut

sub atom_feed {
  my $self = shift;
  if (exists $self->{params}{url}) {
    my $uri = URI->new(ATOM);
    $uri->query_form( $self->{params} );
    return $uri->as_string();
  } else {
    croak "You must specify an URL to monitor";
  }
  
}

=head2 rss_feed

Return the RSS URL feed.

=cut

sub rss_feed {
  my $self = shift;
  if (exists $self->{params}{url}) {
    my $uri = URI->new(RSS);
    $uri->query_form( $self->{params} );
    return $uri->as_string();
  } else {
    croak "You must specify an URL to monitor";
  }
  
}


=head1 AUTHOR

Emmanuel Di Pretoro, C<< <<manu at bjornoya.net>> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-feed-source-page2rss at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-Source-Page2RSS>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Feed::Source::Page2RSS

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Feed-Source-Page2RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Feed-Source-Page2RSS>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-Source-Page2RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/Feed-Source-Page2RSS>

=back

=head1 SEE ALSO

Page2RSS L<http://page2rss.com>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Emmanuel Di Pretoro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Feed::Source::Page2RSS
