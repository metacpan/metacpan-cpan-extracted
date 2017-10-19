package Facebook::InstantArticle;
use Moose;
use namespace::autoclean;

use Mojo::Log;
use XML::Generator;

use Facebook::InstantArticle::Analytics;
use Facebook::InstantArticle::Author;
use Facebook::InstantArticle::Blockquote;
use Facebook::InstantArticle::Copyright;
use Facebook::InstantArticle::Embed;
use Facebook::InstantArticle::Figure::Image;
use Facebook::InstantArticle::Figure::Video;
use Facebook::InstantArticle::Heading;
use Facebook::InstantArticle::List;
use Facebook::InstantArticle::Map;
use Facebook::InstantArticle::Paragraph;

our $VERSION = '0.13';

=encoding utf-8

=head1 NAME

Facebook::InstantArticle - Helper class for generating Facebook Instant Articles
markup.

=head1 DESCRIPTION

Facebook::InstantArticle is a simple helper class for generating L<Facebook
Instant Articles markup|https://developers.facebook.com/docs/instant-articles/reference>.

At the moment it doesn't support all of the features, and both the internal and
external API are subject to change in upcoming releases, so use with care.

=head1 SYNOPSIS

  use Facebook::InstantArticle;
  use DateTime;

  my $now = DateTime->now,

  my $ia = Facebook::InstantArticle->new(
      language          => 'en',
      url               => 'http://www.example.com/2016/08/17/some-article',
      title             => 'Some title',
      subtitle          => 'Got one?',
      kicker            => 'Nobody needs a kicker, but...',
      published         => "$now",
      modified          => "$now",
      auto_ad_placement => 0, # defaults to true
      style             => 'MyStyleName',
  );

  $ia->add_author(
      name        => 'Me Myself',
      description => 'A little bit about myself',
  );

  $ia->add_author(
      name        => 'Someone Else',
      description => 'A little bit about someone else',
  );

  $ia->add_lead_asset_image(
      source  => 'http://www.example.com/some_image.png',
      caption => 'Nice image, eh?',
  );

  # or

  $ia->add_lead_asset_video(
      source  => 'http://www.example.com/some_video.mp4',
      caption => 'Nice video, eh?',
  );

  $ia->add_paragraph(
      'Will be wrapped in a P element, conversion of inner HTML might be
       done, explained later in this documentation.'
  );

  $ia->add_image(
      source          => 'http://www.example.com/some_image.png',
      caption         => 'Nice picture, eh?',
      enable_comments => 1, # default false
      enable_likes    => 1, # default false
  );

  $ia->add_video(
      source  => 'http://www.example.com/some_video.mp4',
      caption => 'Nice video, eh?',
  );

  say $ia->to_string;

=cut

has 'language'          => ( isa => 'Str',  is => 'rw', required => 1 );
has 'url'               => ( isa => 'Str',  is => 'rw', required => 1 );
has 'title'             => ( isa => 'Str',  is => 'rw', required => 1 );
has 'subtitle'          => ( isa => 'Str',  is => 'rw', required => 0 );
has 'kicker'            => ( isa => 'Str',  is => 'rw', required => 0 );
has 'published'         => ( isa => 'Str',  is => 'rw', required => 1 );
has 'modified'          => ( isa => 'Str',  is => 'rw', required => 1 );
has 'style'             => ( isa => 'Str',  is => 'rw', required => 0 );
has 'auto_ad_placement' => ( isa => 'Bool', is => 'rw', required => 0, default => 1 );

has '_header_elements' => ( isa => 'ArrayRef[Object]', is => 'ro', default => sub { [] } );
has '_body_elements'   => ( isa => 'ArrayRef[Object]', is => 'ro', default => sub { [] } );
has '_footer_elements' => ( isa => 'ArrayRef[Object]', is => 'ro', default => sub { [] } );
has '_credit_elements' => ( isa => 'ArrayRef[Object]', is => 'ro', default => sub { [] } );

has '_log' => ( isa => 'Mojo::Log', is => 'ro', default => sub { Mojo::Log->new } );

=head1 METHODS

=head2 add_lead_asset_image

Adds a lead asset image to the article.

    $ia->add_lead_asset_image(
        source  => 'http://www.example.com/lead_image.png',
        caption => 'Something wicked this way comes...',
    );

=cut

sub add_lead_asset_image {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Figure::Image->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_header_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add lead asset image to article header!' );
}

=head2 add_lead_asset_video

Adds a lead asset video to the article.

    $ia->add_lead_asset_video(
        source  => 'http://www.example.com/lead_video.mp4',
        caption => 'Something wicked this way comes...',
    );

=cut

sub add_lead_asset_video {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Figure::Video->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_header_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add lead asset video to article header!' );
}

=head2 add_author

Adds an author to the article.

    $ia->add_author(
        name => 'Oscar Wilde',
    );

=cut

sub add_author {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Author->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_header_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add author to article header!' );
}

=head2 add_paragraph

Adds a paragraph to the article.

    $ia->add_paragraph( 'This is a paragraph' );

=cut

sub add_paragraph {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Paragraph->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add paragraph to article body!' );
}

=head2 add_image

Adds an image to the article.

    $ia->add_image(
        source  => 'http://www.example.com/image.png',
        caption => 'Some caption...',
    );

=cut

sub add_image {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Figure::Image->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add image to article body!' );
}

=head2 add_video

Adds a video to the article.

    $ia->add_video(
        source  => 'http://www.example.com/video.mp4',
        caption => 'Some caption...',
    );

=cut

sub add_video {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Figure::Video->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add video to article body!' );
}

=head2 add_slideshow

Adds a Facebook::InstantArticle::Slideshow object to the article.

    my $ss = Facebook::InstantArticle::Slideshow->new;

    $ss->add_image(
        source  => 'http://www.example.com/image_01.png',
        caption => 'Image #1',
    );

    $ss->add_image(
        source  => 'http://www.example.com/image_02.png',
        caption => 'Image #2',
    );

    $ia->add_slideshow( $ss );

=cut

sub add_slideshow {
    my $self      = shift;
    my $slideshow = shift;

    if ( defined $slideshow && $slideshow->is_valid ) {
        return push( @{$self->_body_elements}, $slideshow );
    }

    $self->_log->warn( 'Failed to add slideshow to article body!' );
}

=head2 add_credit

Adds a credit to the article.

    $ia->add_credit( 'Thanks for helping me write this article, someone!' );

=cut

sub add_credit {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Paragraph->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_credit_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add credit to article credits!' );
}

=head2 add_copyright

Adds a copyright to the article.

    $ia->add_copyright( 'Copyright 2016, Fubar Inc.' );

=cut

sub add_copyright {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Copyright->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_footer_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add copyright to article footer!' );
}

=head2 add_list

Adds a Facebook::InstantArticle::List object to the article.

    $ia->add_list(
        ordered  => 1, # default 0
        elements => [ 'Element #1', 'Element #2', 'Element 3' ],
    );

=cut

sub add_list {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::List->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add list to article body!' );
}

=head2 add_blockquote

Adds a blockquote to the article.

   $ia->add_blockquote( 'This is blockquoted.' );

=cut

sub add_blockquote {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Blockquote->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add blockquote to article body!' );
}

=head2 add_embed

Adds an embed to the article.

    $ia->add_embed( 'code' );

=cut

sub add_embed {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Embed->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add embed to article body!' );
}

=head2 add_heading

Adds a heading to the article BODY.

    $ia->add_heading(
        level => 1,
        text  => 'Heading',
    );

=cut

sub add_heading {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Heading->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add heading to article body!' );
}

=head2 add_map

Adds a map to the article BODY.

    $ia->add_map(
        latitude  => 56.1341342,
        longitude => 23.253474,
    );

=cut

sub add_map {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Map->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add map to article body!' );
}

=head2 add_analytics

Adds an analytics iframe to the article body.

=cut

sub add_analytics {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Analytics->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_body_elements}, $e );
        }
    }

    $self->_log->warn( 'Failed to add analytics/tracking to article body!' );
}

=head2 to_string

Generates the instant article and returns it as a string.

=cut

sub to_string {
    my $self = shift;

    # TODO: Validate

    my $gen = XML::Generator->new( ':pretty' );

    my $xml = $gen->html(
        { lang => $self->language, prefix => 'op:http://media.facebook.com/op#' },

        $gen->head(
            $gen->meta( { charset => 'utf-8' } ),
            $gen->meta( { property => 'op:markup_version', version => 'v1.0' } ),
            $gen->meta( { property => 'fb:likes_and_comments', content => 'enable' } ),
            $gen->meta( { property => 'fb:use_automatic_ad_placement', content => ( $self->auto_ad_placement ? 'enable=true ad_density=default' : 'enable=false' ) } ),
            ( length $self->style ? $gen->meta( { property => 'fb:article_style', content => $self->style } ) : undef ),
            $gen->link( { rel => 'canonical', href => $self->url } ),
        ),

        $gen->body(
            $gen->article(
                $gen->header(
                    $gen->h1( $self->title ),
                    ( length $self->subtitle ? $gen->h2($self->subtitle) : undef ),
                    ( length $self->kicker ? $gen->h3({ class => 'op-kicker' }, $self->kicker) : undef ),
                    $gen->time( { class => 'op-published', datetime => $self->published } ),
                    $gen->time( { class => 'op-modified', datetime => $self->modified } ),
                    ( @{$self->_header_elements} ? map { $_->as_xml_gen } @{$self->_header_elements} : undef ),
                ),
                ( @{$self->_body_elements} ? map { $_->as_xml_gen } @{$self->_body_elements} : undef ),
                $gen->footer(
                    ( @{$self->_credit_elements} ? $gen->aside(map { $_->as_xml_gen } @{$self->_credit_elements}) : undef ),
                    ( @{$self->_footer_elements} ? map { $_->as_xml_gen } @{$self->_footer_elements} : undef ),
                ),
            ),
        ),
    );

    return "<!doctype html>\n" . $xml;
}

1;

__END__

=head1 AUTHOR

Tore Aursand E<lt>toreau@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016 - Tore Aursand

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
