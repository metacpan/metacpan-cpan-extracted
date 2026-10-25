package Langertha::Knarr::Authorizer::StaticKey;
# ABSTRACT: One shared proxy key for every route and model (auth_token)
our $VERSION = '1.103';
use Moose;
use Digest::SHA qw( sha256 );
use Encode ();
use namespace::autoclean;

with 'Langertha::Knarr::Authorizer';


has key => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);

sub identify {
  my ( $self, $http_req, $action ) = @_;
  return $self->_allowed if $self->_open;
  # Discovery endpoints stay anonymous so clients can introspect.
  return $self->_allowed if $action eq 'a2a_card';
  # One element of the value is enough: a header sent twice arrives as one
  # value joined with ', ' (k53).
  for my $name ( 'Authorization', 'x-api-key' ) {
    my $value = scalar $http_req->header($name);
    next unless defined $value;
    my $bearer = lc $name eq 'authorization';
    for my $element ( split /,/, $value ) {
      $element =~ s/\A\s+|\s+\z//g;
      next if $bearer && $element !~ s/\ABearer\s+//i;
      return $self->_allowed if $self->_same_key( $element, $self->key );
    }
  }
  return { status => 401, message => 'unauthorized' };
}


sub authorize { return }


sub visible_models {
  my ( $self, $identity, $models ) = @_;
  return $models;
}


sub forwards_client_key { 1 }


sub _open {
  my ($self) = @_;
  my $key = $self->key;
  return !( defined $key && length $key );
}

sub _allowed { return { identity => {} } }

# Equal keys, compared without an early exit: both go through SHA-256 and the
# digests are compared whole, so the time does not depend on how much of the
# key was right (k76). Callable on the class.
sub _same_key {
  my ( $self, $given, $want ) = @_;
  return 0 unless defined $given && defined $want;
  my $g = sha256( utf8::is_utf8($given) ? Encode::encode( 'UTF-8', $given ) : $given );
  my $w = sha256( utf8::is_utf8($want)  ? Encode::encode( 'UTF-8', $want )  : $want );
  my $diff = 0;
  $diff |= ord( substr $g, $_, 1 ) ^ ord( substr $w, $_, 1 ) for 0 .. 31;
  return $diff ? 0 : 1;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Authorizer::StaticKey - One shared proxy key for every route and model (auth_token)

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Langertha::Knarr::Authorizer::StaticKey;

    my $knarr = Langertha::Knarr->new(
      handler    => $handler,
      authorizer => Langertha::Knarr::Authorizer::StaticKey->new( key => 'sk-proxy' ),
    );

    # the same, and what Knarr builds by itself:
    my $knarr = Langertha::Knarr->new( handler => $handler, auth_token => 'sk-proxy' );

=head1 DESCRIPTION

The L<Langertha::Knarr::Authorizer> behind L<Langertha::Knarr/auth_token>:
one shared key opens every route and every model. L<Langertha::Knarr>
builds one over its C<auth_token> unless it is given another authorizer,
and builds it anew when the C<auth_token> changes (an admin push).

Without a L</key> every request is let in. With one, a request must
present it as C<Authorization: Bearer> I<key> or C<x-api-key>; a header
sent twice counts as one value of comma-separated elements, and any one of
them may be the key. The key is compared in constant time (both sides
through SHA-256, the digests compared whole). The A2A agent card stays
anonymous. Anything else gets C<401> C<unauthorized>.

The identity is C<{}>: the key says nothing about who asks. Every model
may be used and listed, and the client's own provider key may reach a
passthrough upstream (L</forwards_client_key> is true; Knarr takes this key
out of what it forwards).

=head2 key

Optional. The shared key; C<undef> or empty lets every request in.

=head2 identify

    my $result = $authorizer->identify( $http_req, $action );

C<< { identity => {} } >> for a request with the key (or for every request
without a L</key>), C<< { status => 401, message => 'unauthorized' } >>
otherwise.

=head2 authorize

Always allows: the key opens every model.

=head2 visible_models

Returns the list it is given.

=head2 forwards_client_key

True.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
