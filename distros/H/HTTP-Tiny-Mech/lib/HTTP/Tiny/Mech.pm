use 5.006;    # pragmas, our
use strict;
use warnings;

package HTTP::Tiny::Mech;

our $VERSION = '1.001002';

# ABSTRACT: Wrap a WWW::Mechanize instance in an HTTP::Tiny compatible interface.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use parent 'HTTP::Tiny';

sub new {
  my ( $self, %args ) = @_;
  my ( $mechua, $has_mechua );
  if ( exists $args{mechua} ) {
    $has_mechua = 1;
    $mechua     = delete $args{mechua};
  }
  my $instance = $self->SUPER::new(%args);
  if ($has_mechua) {
    $instance->{mechua} = $mechua;
  }
  return bless $instance, $self;
}

## no critic (Subroutines::RequireArgUnpacking)
sub mechua {
  my ( $self, $new_mechua, $has_new_mechua ) = ( $_[0], $_[1], @_ > 1 );
  if ($has_new_mechua) {
    $self->{mechua} = $new_mechua;
  }
  return $self->{mechua} if exists $self->{mechua};
  require WWW::Mechanize;
  return ( $self->{mechua} = WWW::Mechanize->new() );
}
## use critic










sub _unwrap_response {
  my ( undef, $response ) = @_;
  return {
    status  => $response->code,
    reason  => $response->message,
    headers => $response->headers,
    success => $response->is_success,
    content => $response->content,
  };
}

sub _wrap_request {
  my ( undef, $method, $uri, $opts ) = @_;
  require HTTP::Request;
  my $req = HTTP::Request->new( $method, $uri );
  $req->headers( $opts->{headers} ) if $opts->{headers};
  $req->content( $opts->{content} ) if $opts->{content};
  return $req;
}









sub get {
  my ( $self, $uri, $opts ) = @_;
  return $self->_unwrap_response( $self->mechua->get( $uri, ( $opts ? %{$opts} : () ) ) );
}







sub request {
  my ( $self, @request ) = @_;
  my $req      = $self->_wrap_request(@request);
  my $response = $self->mechua->request($req);
  return $self->_unwrap_response($response);
}




































1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Mech - Wrap a WWW::Mechanize instance in an HTTP::Tiny compatible interface.

=head1 VERSION

version 1.001002

=head1 SYNOPSIS

  # Get something that expects an HTTP::Tiny instance
  # to work with HTTP::Mechanize under the hood.
  #
  my $thing => ThingThatExpectsHTTPTiny->new(
    ua => HTTP::Tiny::Mech->new()
  );

  # Get something that expects HTTP::Tiny
  # to work via WWW::Mechanize::Cached
  #
  my $thing => ThingThatExpectsHTTPTiny->new(
    ua => HTTP::Tiny::Mech->new(
      mechua => WWW::Mechanize::Cached->new( )
    );
  );

=head1 DESCRIPTION

This code is somewhat poorly documented, and highly experimental.

Its the result of a quick bit of hacking to get L<< C<MetaCPAN::API>|MetaCPAN::API >> working faster
via the L<< C<WWW::Mechanize::Cached>|WWW::Mechanize::Cached >> module ( and gaining cache persistence via
L<< C<CHI>|CHI >> )

It works so far for this purpose.

At present, only L</get> and L</request> are implemented, and all other calls
fall through to a native L<< C<HTTP::Tiny>|HTTP::Tiny >>.

=head1 ATTRIBUTES

=head2 C<mechua>

This class provides one non-standard parameter not in HTTP::Tiny, C<mechua>, which
is normally an autovivified C<WWW::Mechanize> instance.

You may override this parameter if you want to provide a custom instance of a C<WWW::Mechanize> class.

=head1 WRAPPED METHODS

=head2 get

Interface should be the same as it is with L<HTTP::Tiny/get>.

=head2 request

Interface should be the same as it is with L<HTTP::Tiny/request>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
