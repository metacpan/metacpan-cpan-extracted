package Langertha::Knarr::Authorizer;
# ABSTRACT: Role for who may use a Knarr, and with which model
our $VERSION = '1.103';
use Moose::Role;
use Future;


requires qw( identify authorize visible_models forwards_client_key );

sub start { }

sub identify_f {
  my ( $self, $http_req, $action ) = @_;
  return Future->done( $self->identify( $http_req, $action ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Authorizer - Role for who may use a Knarr, and with which model

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    package My::Authorizer;
    use Moose;
    with 'Langertha::Knarr::Authorizer';

    sub identify {
      my ( $self, $http_req, $action ) = @_;
      return { identity => {} } if $http_req->header('X-Trusted');
      return { status => 401, message => 'unauthorized' };
    }
    sub authorize      { return }                    # every model
    sub visible_models { $_[2] }                     # every listed model
    sub forwards_client_key { 1 }

    __PACKAGE__->meta->make_immutable;

    my $knarr = Langertha::Knarr->new(
      handler    => $handler,
      authorizer => My::Authorizer->new,
    );

=head1 DESCRIPTION

Decides who may use a L<Langertha::Knarr>, in two phases:

=over

=item 1. B<Identify> -- who is asking. Runs once the route is known, before
the body is read: a client that cannot identify itself learns no C<400>,
no C<404> and no model name. A request that presents Knarr's admin key to a
route that is not an admin route never gets here: L<Langertha::Knarr>
answers it with C<401> first, whatever the authorizer.

=item 2. B<Authorize> -- may this identity do this action with this model.
Runs once the action and the model are known: after the chat request was
parsed, with the model of a C<POST /api/show> body. A request that names no
model gets the identity's own C<model> first, when it has one
(L<Langertha::Knarr::Request/apply_grant>).

=back

Every refusal is answered by Knarr in the client protocol's error shape
(L<Langertha::Knarr/ERRORS>), on the native server and under
L<Langertha::Knarr::PSGI> alike.

The identity is a plain HashRef. It goes to the handler chain as
L<Langertha::Knarr::Request/grant>. It must never carry a secret: no key,
no token, no hash of one.

Two authorizers ship with Knarr: L<Langertha::Knarr::Authorizer::StaticKey>
(L<Langertha::Knarr/auth_token>, the default) and
L<Langertha::Knarr::Authorizer::Token> (one short-lived token per model,
checked against a L<Langertha::Knarr::TokenStore>).

=head2 identify_f

    my $result = await $authorizer->identify_f( $http_req, $action );

Returns a L<Future> that is done with the result of the identify phase and
never fails:

    { identity => \%identity }                       # go on
    { status => 401, message => 'unauthorized' }     # refused

The native server uses it, so a check that has to ask something (a
database) does not hold the event loop. The default calls L</identify>.

=head2 identify

    my $result = $authorizer->identify( $http_req, $action );

Required. The same result, synchronously (L<Langertha::Knarr::PSGI>, where
the request may block). C<$http_req> answers C<< ->header($name) >>;
C<$action> is the route's action (C<chat>, C<models>, C<a2a_card>, ...).

=head2 authorize

    my ( $status, $message ) = $authorizer->authorize( $identity, $action, $model );

Required. Empty list when the identity may do C<$action> with C<$model>
(C<undef> when the action has none), else the status and the client's
message of the refusal.

=head2 visible_models

    my $models = $authorizer->visible_models( $identity, \@models );

Required. The models a model list (C</v1/models>, C</api/tags>, ACP
C</agents>, C</api/show>) shows this identity, from the list the handler or
router gives, as hashes with an C<id> (the shape
L<Langertha::Knarr::Protocol/format_models_response> takes).

=head2 forwards_client_key

Required. True when the client's own key may reach an upstream: then the
raw passthrough runs and a passthrough handler forwards the client's
C<Authorization> and C<x-api-key> (Knarr's proxy key taken out). False: the
raw passthrough never runs, and both headers are dropped from every header
set Knarr forwards.

=head2 start

    $authorizer->start($loop);

Called by L<Langertha::Knarr> once a process starts serving, with the
L<IO::Async::Loop> it serves on: by L<Langertha::Knarr/start> with one
worker, in every forked worker otherwise -- never in the prefork
supervisor, whose connections every worker would share. An authorizer that
needs a connection opens it here, without blocking, so the first request
does not wait for it. It may be called again in the same process (an admin
push hands the same authorizer over again) and must then do nothing. The
default does nothing. L<Langertha::Knarr::PSGI> does not call it.

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
