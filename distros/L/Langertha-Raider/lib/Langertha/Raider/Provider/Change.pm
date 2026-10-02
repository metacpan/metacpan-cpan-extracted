package Langertha::Raider::Provider::Change;
# ABSTRACT: Internal classification of what changed between an accepted and a newly fetched provider manifest
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use URI;
use Langertha::Manifest;
use Langertha::Raider::Approval;
use Langertha::Raider::Provider::Fetch;


# The name of the view's shape. It is part of what the fingerprint covers,
# so a later change of the view changes every fingerprint -- a stored one
# then no longer matches and consent is asked again, never skipped.
use constant VIEW => 'raider-provider-consent-1';

sub manifest_class { 'Langertha::Manifest' }
sub fetch_class    { 'Langertha::Raider::Provider::Fetch' }
sub digest_class   { 'Langertha::Raider::Approval' }


sub consent_view {
  my ( $self, $manifest, $origin ) = @_;
  $self->_check_manifest($manifest);
  my %endpoints = map {
    $_->id => {
      origin  => $self->_origin_of($_->base_url, "endpoint '".$_->id."' base_url"),
      dialect => $_->dialect,
      auth    => $self->_auth_type($manifest, $_),
    }
  } @{ $manifest->endpoints };
  return {
    view        => VIEW,
    origin      => $self->_origin_of($origin, 'origin'),
    issuer      => $manifest->issuer,
    provider_id => $manifest->provider_id,
    endpoints   => \%endpoints,
  };
}


sub fingerprint {
  my ( $self, $manifest, $origin ) = @_;
  return $self->digest_class->digest_arguments( $self->consent_view($manifest, $origin) );
}


sub classify {
  my ( $self, %arg ) = @_;
  for my $name (qw( old old_origin new new_origin )) {
    croak __PACKAGE__.'->classify needs '.$name unless defined $arg{$name};
  }
  my ( $old, $new ) = @arg{qw( old new )};
  my $was = $self->consent_view($old, $arg{old_origin});
  my $is  = $self->consent_view($new, $arg{new_origin});

  my @changes;
  my $change = sub {
    my ( $kind, $consent, $description, %about ) = @_;
    push @changes, { kind => $kind, consent => $consent, description => $description, %about };
  };

  for my $field (qw( origin issuer provider_id )) {
    $change->($field, 1, $field.' changed: '.$was->{$field}.' -> '.$is->{$field})
      unless $was->{$field} eq $is->{$field};
  }

  $self->_endpoint_changes($change, $old, $new, $was->{endpoints}, $is->{endpoints});
  $self->_auth_changes($change, $old, $new);
  $self->_model_changes($change, $old, $new);

  my $digest = $self->digest_class;
  $change->('extensions', 0, 'extensions changed (inert in manifest v1)')
    unless $digest->digest_arguments($old->extensions) eq $digest->digest_arguments($new->extensions);

  return {
    changes         => \@changes,
    needs_consent   => ( ( grep { $_->{consent} } @changes ) ? 1 : 0 ),
    old_fingerprint => $digest->digest_arguments($was),
    new_fingerprint => $digest->digest_arguments($is),
  };
}

sub _endpoint_changes {
  my ( $self, $change, $old, $new, $was, $is ) = @_;
  my %ids = map { $_ => 1 } keys %$was, keys %$is;
  for my $id ( sort keys %ids ) {
    my $what = "endpoint '".$id."'";
    my ( $before, $after ) = ( $was->{$id}, $is->{$id} );
    unless ($before) {
      $change->('endpoint_added', 1, $what.' added: '.$self->_describe_endpoint($after), endpoint => $id);
      next;
    }
    unless ($after) {
      $change->('endpoint_removed', 1, $what.' removed (was '.$self->_describe_endpoint($before).')', endpoint => $id);
      next;
    }
    my ( $old_endpoint, $new_endpoint ) = ( $old->endpoint($id), $new->endpoint($id) );
    if ( $before->{origin} ne $after->{origin} ) {
      $change->('endpoint_origin', 1, $what.': origin '.$before->{origin}.' -> '.$after->{origin}, endpoint => $id);
    }
    elsif ( $old_endpoint->base_url ne $new_endpoint->base_url ) {
      $change->('endpoint_path', 0, $what.': base_url '.$old_endpoint->base_url.' -> '.$new_endpoint->base_url
        .' (same origin)', endpoint => $id);
    }
    $change->('endpoint_dialect', 1, $what.': dialect '.$before->{dialect}.' -> '.$after->{dialect}, endpoint => $id)
      unless $before->{dialect} eq $after->{dialect};
    if ( $self->_auth_label($before->{auth}) ne $self->_auth_label($after->{auth}) ) {
      $change->('endpoint_auth', 1, $what.': auth '.$self->_auth_label($before->{auth})
        .' -> '.$self->_auth_label($after->{auth}), endpoint => $id);
    }
    elsif ( ( $old_endpoint->auth_ref // '' ) ne ( $new_endpoint->auth_ref // '' ) ) {
      $change->('endpoint_auth_ref', 0, $what.": auth_ref '".$old_endpoint->auth_ref."' -> '"
        .$new_endpoint->auth_ref."' (same type ".$after->{auth}.')', endpoint => $id);
    }
  }
  return;
}

# Auth entries no endpoint of the new manifest names. One that an endpoint
# names reaches the endpoint's view, and its change is that endpoint's.
sub _auth_changes {
  my ( $self, $change, $old, $new ) = @_;
  my %named = map { defined $_->auth_ref ? ( $_->auth_ref => 1 ) : () } @{ $new->endpoints };
  my %was = map { $_->id => $_->type } @{ $old->auth };
  my %is  = map { $_->id => $_->type } @{ $new->auth };
  my %ids = map { $_ => 1 } keys %was, keys %is;
  for my $id ( sort grep { !$named{$_} } keys %ids ) {
    my $what = "auth '".$id."'";
    if ( !defined $was{$id} ) {
      $change->('auth_added', 0, $what.' added: type '.$is{$id}.' (no endpoint uses it)', auth => $id);
    }
    elsif ( !defined $is{$id} ) {
      $change->('auth_removed', 0, $what.' removed (was type '.$was{$id}.')', auth => $id);
    }
    elsif ( $was{$id} ne $is{$id} ) {
      $change->('auth_type', 0, $what.': type '.$was{$id}.' -> '.$is{$id}.' (no endpoint uses it)', auth => $id);
    }
  }
  return;
}

sub _model_changes {
  my ( $self, $change, $old, $new ) = @_;
  my %was = map { $_->endpoint_ref."\0".$_->id => $_ } @{ $old->models };
  my %is  = map { $_->endpoint_ref."\0".$_->id => $_ } @{ $new->models };
  my %keys = map { $_ => 1 } keys %was, keys %is;
  my $digest = $self->digest_class;
  for my $key ( sort keys %keys ) {
    my ( $before, $after ) = ( $was{$key}, $is{$key} );
    my $model = $before // $after;
    my $what = "model '".$model->id."' on endpoint '".$model->endpoint_ref."'";
    my %about = ( model => $model->id, endpoint => $model->endpoint_ref );
    if ( !$before ) {
      $change->('model_added', 0, $what.' added', %about);
    }
    elsif ( !$after ) {
      $change->('model_removed', 0, $what.' removed', %about);
    }
    elsif ( $digest->digest_arguments($before->to_hash->{capabilities})
         ne $digest->digest_arguments($after->to_hash->{capabilities}) ) {
      $change->('model_capabilities', 0, $what.': capabilities '
        .$self->_describe_capabilities($before).' -> '.$self->_describe_capabilities($after), %about);
    }
  }
  return;
}

sub _check_manifest {
  my ( $self, $manifest ) = @_;
  croak __PACKAGE__.' needs a '.$self->manifest_class.', got '.( defined $manifest ? ( ref $manifest || $manifest ) : 'undef' )
    unless blessed $manifest && $manifest->isa($self->manifest_class);
  return;
}

sub _origin_of {
  my ( $self, $url, $what ) = @_;
  my $uri = URI->new( $url // '' );
  croak __PACKAGE__.': '.$what.' names no origin: '.( $url // 'undef' )
    unless $uri->can('host') && length( $uri->host // '' );
  return $self->fetch_class->origin($uri);
}

# Returns undef as a value, not an empty list: it lands in a hash slot.
sub _auth_type {
  my ( $self, $manifest, $endpoint ) = @_;
  return undef unless defined $endpoint->auth_ref;
  return $manifest->auth_entry($endpoint->auth_ref)->type;
}

sub _auth_label {
  my ( $self, $type ) = @_;
  return defined $type ? 'type '.$type : 'none';
}

sub _describe_endpoint {
  my ( $self, $view ) = @_;
  return 'dialect '.$view->{dialect}.' at '.$view->{origin}.', auth '.$self->_auth_label($view->{auth});
}

sub _describe_capabilities {
  my ( $self, $model ) = @_;
  my $caps = $model->capabilities;
  return '(none)' unless %$caps;
  return '{'.join(', ', map { $_.'='.( $caps->{$_} ? 'true' : 'false' ) } sort keys %$caps).'}';
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Provider::Change - Internal classification of what changed between an accepted and a newly fetched provider manifest

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $class = 'Langertha::Raider::Provider::Change';
    my $got = $class->classify(
      old => $accepted_manifest, old_origin => 'https://provider.example',
      new => $fetched_manifest,  new_origin => $report->{final_url},
    );
    # { needs_consent   => 1,
    #   changes         => [ { kind => 'endpoint_origin', consent => 1, endpoint => 'chat',
    #                          description => "endpoint 'chat': origin ... -> ..." }, ... ],
    #   old_fingerprint => '3f2a...', new_fingerprint => '9b1c...' }

    my $hex = $class->fingerprint($manifest, $origin);

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

A provider manifest (ADR 0007) may change after the user accepted it. Not
every change is a new trust decision: a model list may change without
renegotiating anything, while a change of origin or auth mechanism must be
accepted again (C<docs/RAIDER-REDESIGN-HANDOFF.md> 11.2). This class tells
the two apart. It is pure logic: it stores nothing and asks nobody; keeping
an accepted manifest and asking again is the provider binding's job.

B<The consent view> (L</consent_view>) is the part of a manifest a consent
covers. Every change to it needs renewed consent, every other change does
not -- so C<needs_consent> of L</classify> is true exactly when the two
L</fingerprint>s differ. The view holds:

=over

=item * B<origin> -- the origin the manifest was fetched from. Another
origin is another party, whatever the document says.

=item * B<issuer> -- compared as the exact string, as OpenID Connect
compares issuers: it is the identity the provider claims.

=item * B<provider_id> -- the name the provider was accepted under and is
shown by. A manifest cannot rename itself under an existing consent.

=item * B<every endpoint> by its id, with the B<origin> of its C<base_url>
(where requests and the credential go), its B<dialect> (how raider talks to
it) and the B<type> of the auth entry its C<auth_ref> names (which
credential it asks for; C<undef> for none). Every endpoint counts, not only
the ones a model uses today: a model list change needs no consent and can put
any endpoint into use. An endpoint added or removed is a change to the view.
Removing one narrows trust, but the accepted binding no longer describes the
provider, so it is asked again as well -- this keeps "needs consent" and
"fingerprint changed" the same statement.

=back

Changes that need no consent, reported so nothing changes silently:

=over

=item * the path of an endpoint's C<base_url> within the same origin
(C<endpoint_path>) -- the origin is the trust boundary, not the path;

=item * the id of the auth entry an endpoint names when its type stays
(C<endpoint_auth_ref>) -- the id is a label, the mechanism is what counts;

=item * auth entries no endpoint of the new manifest names (C<auth_added>,
C<auth_removed>, C<auth_type>) -- they reach no endpoint; one that does is
reported as the endpoint's C<endpoint_auth>;

=item * models added or removed, also from one endpoint to another
(C<model_added>, C<model_removed>) -- a model entry is its id on its
endpoint;

=item * a model's declared capabilities (C<model_capabilities>) -- a
capability is what the provider B<claims>, never what raider B<authorises>
(ADR 0007: the four states stay separate; ADR 0005: permissions never come
from a manifest). It changes what raider sends to an origin already
accepted, not where anything goes;

=item * C<extensions> -- inert in manifest v1. Once extensions carry
references to MCP servers or packs, installing, loading and running them
needs local policy of its own (ADR 0007).

=back

=head2 consent_view

    my $view = $class->consent_view($manifest, $origin);

The part of C<$manifest> (a L<Langertha::Manifest>) a consent covers, as
plain data (see L</DESCRIPTION>). C<$origin> is the origin -- or any URL of
it, such as the final URL of the fetch -- the manifest was fetched from.
Croaks when C<$manifest> is not a manifest or C<$origin> names no host.

=head2 fingerprint

    my $hex = $class->fingerprint($manifest, $origin);

The SHA-256 (hex) of the canonical JSON of L</consent_view> -- the
canonical form of L<Langertha::Raider::Approval/digest_arguments>: keys
sorted at every depth, UTF-8. The same for the same view whatever the key
order of the manifest document, the order of its endpoints, or any change
that needs no consent.

=head2 classify

    my $got = $class->classify(
      old => $accepted, old_origin => $accepted_origin,
      new => $fetched,  new_origin => $fetched_origin,
    );

Compares an accepted manifest with a newly fetched one, each with the origin
it was fetched from. Resolves to a hash:

=over

=item C<changes> -- one hash per change, in a stable order (origin, issuer,
provider_id, endpoints by id, auth entries by id, models by endpoint and
id, extensions): C<kind>, C<consent> (C<1> or C<0>), C<description> (one
line for a person) and, where it applies, C<endpoint>, C<auth> or C<model>
naming what changed. Empty when nothing changed.

=item C<needs_consent> -- C<1> when any change needs renewed consent, else
C<0>.

=item C<old_fingerprint>, C<new_fingerprint> -- the L</fingerprint>s; they
differ exactly when C<needs_consent> is C<1>.

=back

Kinds that need consent: C<origin>, C<issuer>, C<provider_id>,
C<endpoint_added>, C<endpoint_removed>, C<endpoint_origin>,
C<endpoint_dialect>, C<endpoint_auth>. Kinds that do not: C<endpoint_path>,
C<endpoint_auth_ref>, C<auth_added>, C<auth_removed>, C<auth_type>,
C<model_added>, C<model_removed>, C<model_capabilities>, C<extensions>.
Croaks on a missing or invalid argument.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Provider::Activation> -- C<raider --provider>, which accepts nothing beyond one run

=item * L<Langertha::Raider::Provider::Fetch> -- where a manifest and its origin come from

=item * L<Langertha::Manifest> -- the manifest's schema and validator (core)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

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
