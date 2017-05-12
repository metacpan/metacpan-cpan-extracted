package HTML::Feature::FrontParser;
use strict;
use warnings;
use Carp;
use URI;
use Scalar::Util qw(blessed);
use UNIVERSAL::require;
use base qw(HTML::Feature::Base);

__PACKAGE__->mk_accessors($_) for qw( _fetcher _decoder);

sub parse {
    my $self = shift;
    my $arg  = shift;
    if ( !$arg ) {
        croak('Usage: parse( $uri | $http_response | $html_ref )');
    }
    my $pkg = blessed($arg);
    if ( !$pkg ) {
        if ( my $ref = ref $arg ) {
            if ( $ref eq 'SCALAR' ) {
                my $html = $$arg;
                unless ( $self->context->config->{not_decode} ) {
                    if(utf8::is_utf8($html)){
                        utf8::encode($html);
                    }
                    $html = $self->decoder->decode($html);
                }
                return $html;
            }
            croak('Usage: parse( $uri | $http_response | $html_ref )');
        }
        $pkg = 'URI';
        $arg = URI->new($arg);
    }
    if ( $pkg->isa('URI') ) {
        return $self->_parse_url( $arg, @_ );
    }
    elsif ( $pkg->isa('HTTP::Response') ) {
        return $self->_parse_response( $arg, @_ );
    }
    else {
        croak('Usage: parse( $uri | $http_response | $html_ref )');
    }
}

sub _parse_url {
    my $self = shift;
    my $url  = shift;
    my $res  = $self->fetcher->request($url);
    $self->_parse_response( $res, @_ );
}

sub _parse_response {
    my $self          = shift;
    my $http_response = shift;
    my $args          = shift;
    my $c             = $self->context;
    if ( $args->{element_flag} ) {
        $self->{element_flag} = $args->{element_flag};
    }
    $c->{base_url} = $http_response->base;
    my $html = $http_response->content;
    unless ( $c->config->{not_decode} ) {
        $html = $self->decoder->decode( $html, { response => $http_response } );
    }
    return $html;
}

#---
# accessor methods
#---

sub fetcher {
    my $self = shift;
    my $args = shift;
    if ( !$args ) {
        $self->_fetcher or sub {
            HTML::Feature::Fetcher->require or die $@;
            my $fetcher = HTML::Feature::Fetcher->new( context => $self->context );
            $self->_fetcher($fetcher);
          }
          ->();
    }
    else {
        $self->_fetcher($args);
    }
}

sub decoder {
    my $self = shift;
    my $args = shift;
    if ( !$args ) {
        $self->_decoder or sub {
            HTML::Feature::Decoder->require or die $@;
            $self->_decoder( HTML::Feature::Decoder->new( context => $self->context ) );
          }
          ->();
    }
    else {
        $self->_decoder($args);
    }
}

1;
__END__

=head1 NAME

HTML::Feature::FrontParser - Inner dispatcher.

=head1 SYNOPSIS

  use HTML::Feature::FrontParser;

  my $front_parser = HTML::Feature::FrontParser->new( context => $html_feature );
  my $html         = $front_parser->parse($indata); # $in_data is either of a URL or a string of HTML(scalar reference) or a HTTP::Request object

=head1 DESCRIPTION

HTML::Feature::FronParser is an Inner dispatcher.
It detects the method that should be called in HTML::Feature.

=head1 METHODS

=head2 parse

    parse($url);
    # or
    parse($html_ref);
    # or
    parse($http_response);

Parses the given argument. The argument can be either a URL, a string of HTML
(must be passed as a scalar reference), or an HTTP::Response object.
HTML::Feature will detect and delegate to the appropriate method (see below)

=head2 fetcher

accessor method that points to HTML::Feature::Fetcher object.

=head2 decoder

accessor method that points to HTML::Feature::Decoder object.

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
