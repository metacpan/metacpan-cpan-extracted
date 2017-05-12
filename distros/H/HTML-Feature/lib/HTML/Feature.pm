package HTML::Feature;
use strict;
use warnings;
use HTML::Feature::FrontParser;
use HTML::Feature::Engine;
use base qw(HTML::Feature::Base);

__PACKAGE__->mk_accessors($_) for qw(_front_parser _engine);

our $VERSION = '3.00011';

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = $class->SUPER::new( config => \%args );
    $self->_setup;
    return $self;
}

sub parse {
    my $self     = shift;
    my $whatever = shift;
    my $url      = shift;
    my $html     = $self->front_parser->parse($whatever);
    if ( !$url and $self->{base_url} ) {
        $url = $self->{base_url};
    }
    my $result = $self->engine->run( \$html, $url );
    return $result;
}

sub parse_url {
    my $self = shift;
    $self->parse(@_);
}

sub parse_response {
    my $self = shift;
    $self->parse(@_);
}

sub parse_html {
    my $self = shift;
    $self->parse(@_);
}

sub _setup {
    my $self = shift;
    $self->front_parser( HTML::Feature::FrontParser->new( context => $self ) );
    $self->engine( HTML::Feature::Engine->new( context => $self ) );
    if ( !$self->{not_encode} ) {
        $self->{enc_type} ||= "utf8";
    }
}

#---
# accessor methods
#---

sub front_parser {
    my $self = shift;
    my $args = shift;
    if ( !$args ) {
        $self->_front_parser;
    }
    else {
        $self->_front_parser($args);
    }
}

sub engine {
    my $self = shift;
    my $args = shift;
    if ( !$args ) {
        $self->_engine;
    }
    else {
        $self->_engine($args);
    }
}

1;
__END__

=head1 NAME

HTML::Feature - Extract Feature Sentences From HTML Documents

=head1 SYNOPSIS

  use HTML::Feature;

  # simple usage

  my $feature = HTML::Feature->new;
  my $result  = $feature->parse("http://www.perl.com");

  print "Title:"        , $result->title, "\n";
  print "Description:"  , $result->desc , "\n";
  print "Featured Text:", $result->text , "\n";


  # you can set some engine modules serially. ( if one module can't extract text, it calls to next module )

  my $feature = HTML::Feature->new( 
    engines => [
      'HTML::Feature::Engine::LDRFullFeed',
      'HTML::Feature::Engine::GoogleADSection',
      'HTML::Feature::Engine::TagStructure',
    ],
  );

  my $result = $feature->parse($url);


  # And you can set your custom engine module in arbitrary place.

  my $feature = HTML::Feature->new( 
    engines => [
      'Your::Custom::Engine::Module'
    ],
  );


=head1 DESCRIPTION

This module extracst blocks of feature sentences out of an HTML document.

Version 3.0, we provide three engines. 

  1. LDRFullFeed

    Use wedata's databaase that is compatible for LDR Full Feed.
      see -> http://wedata.net/help/about ( Japanse only )

  2. GoogleADSection

    Extract by 'Google AD Section' HTML COMMENT TAG

  3. TagStructure

    Default engine. It guesses and extracts a feature sentence by HTML tag structure.
    Unlike other modules that performs similar tasks, this module by default extracts blocks without using morphological analysis, and instead it uses simple statistics processing.
    Because of this, HTML::Feature::Engine::TagStructure has an advantage over other similar modules in that it can be applied to documents in any language.

=head1 METHODS

=head2 new

Instantiates a new HTML::Feature object. Takes the following parameters

    my $f = HTML::Feature->new(%param);

    my $f = HTML::Feature->new(
        engines      => [ class_name1, 
                          class_name2,       # backend engine module (default: 'TagStructure') 
                          class_name3 ], 

        user_agent   => 'my-agent-name',     # LWP::UserAgent->agent (default: 'libwww-perl/#.##') 
        http_proxy   => 'http://proxy:3128', # http proxy server (default: '')
        timeout      => 10,                  # set the timeout value in seconds. (default: 180)

        not_decode   => 1,                   # if this value is 1, HTML::Feature does not decode the HTML document (default: '')
        not_encode   => 1,                   # if this value is 1, HTML::Feature does not encode the result value  (default: '') 

        element_flag => 1,                   # flag of HTML::Element object as returned value (default: '') 
   );

=over 4

=item engine

Specifies the class name of the engine that you want to use.

HTML::Feature is designed to accept some different engines.
If you want to customize the behavior of HTML::Feature, specify your own engine in this parameter.

=back 

=head2 parse

    my $result = $f->parse($url);
    # or
    my $result = $f->parse($html_ref,[$url]);
    # or
    my $result = $f->parse($http_response);

Parses the given argument. The argument can be either a URL, a string of HTML
(must be passed as a scalar reference), or an HTTP::Response object.
HTML::Feature will detect and delegate to the appropriate method (see below)


=head2 parse_url($url)

Parses an URL. This method will use LWP::UserAgent to fetch the given url.

=head2 parse_html($html, [$url])

Parses a string containing HTML. If you use 'HTML::Feature::Engine::LDRFullFeed', $url will be necessary.

=head2 parse_response($http_response)

Parses an HTTP::Response object.

=head2 front_parser

accessor method that points to HTML::Feature::FrontParser object. 

=head2 engine

accessor method that points to HTML::Feature::Engine object.

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
