package HTTP::Headers::ActionPack::Authorization;
# ABSTRACT: The Authorization Header factory

use strict;
use warnings;

our $VERSION = '0.10';

use HTTP::Headers::ActionPack::Authorization::Basic;
use HTTP::Headers::ActionPack::Authorization::Digest;

sub new {
    my $class = shift;
    my $type  = shift;
    $type eq 'Basic'
        ? HTTP::Headers::ActionPack::Authorization::Basic->new( $type, @_ )
        : HTTP::Headers::ActionPack::Authorization::Digest->new( $type, @_ );
}

sub new_from_string {
    my ($class, $header_string) = @_;
    $header_string =~ /^Basic/
        ? HTTP::Headers::ActionPack::Authorization::Basic->new_from_string( $header_string )
        : HTTP::Headers::ActionPack::Authorization::Digest->new_from_string( $header_string );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Headers::ActionPack::Authorization - The Authorization Header factory

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::Authorization;

  # create HTTP::Headers::ActionPack::Authorization::Basic objects ...

  # create from string
  my $auth = HTTP::Headers::ActionPack::Authorization->new_from_string(
      'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
  );

  # create from parameters
  my $auth = HTTP::Headers::ActionPack::Authorization->new(
      'Basic' => {
          username => 'Aladdin',
          password => 'open sesame'
      }
  );

  my $auth = HTTP::Headers::ActionPack::Authorization->new(
      'Basic' => [ 'Aladdin', 'open sesame' ]
  );

  my $auth = HTTP::Headers::ActionPack::Authorization->new(
      'Basic' => 'QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
  );

  # or HTTP::Headers::ActionPack::Authorization::Digest objects ...

  # create from string
  my $auth = HTTP::Headers::ActionPack::Authorization->new_from_string(
      q{Digest
        username="jon.dough@mobile.biz",
        realm="RoamingUsers@mobile.biz",
        nonce="CjPk9mRqNuT25eRkajM09uTl9nM09uTl9nMz5OX25PZz==",
        uri="sip:home.mobile.biz",
        qop=auth-int,
        nc=00000001,
        cnonce="0a4f113b",
        response="6629fae49393a05397450978507c4ef1",
        opaque="5ccc069c403ebaf9f0171e9517f40e41"}
  );

  # create from parameters
  my $auth = HTTP::Headers::ActionPack::Authorization->new(
      'Digest' => (
          username => 'jon.dough@mobile.biz',
          realm    => 'RoamingUsers@mobile.biz',
          nonce    => "CjPk9mRqNuT25eRkajM09uTl9nM09uTl9nMz5OX25PZz==",
          uri      => "sip:home.mobile.biz",
          qop      => 'auth-int',
          nc       => '00000001',
          cnonce   => "0a4f113b",
          response => "6629fae49393a05397450978507c4ef1",
          opaque   => "5ccc069c403ebaf9f0171e9517f40e41"
      )
  );

=head1 DESCRIPTION

This is a factory class that can be used to create the appropriate
subclass based on the type of Authorization header.

=head1 METHODS

=over 4

=item C<new ( %params )>

=item C<new_from_string ( $header_string )>

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/sartak/http-headers-actionpack/issues>.

=head1 SOURCE

The source code repository for HTTP-Headers-ActionPack can be found at L<https://github.com/sartak/http-headers-actionpack>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Robert Rothenberg <perl@rhizomnic.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2026 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
