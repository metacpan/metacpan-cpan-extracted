package Langertha::Manifest;
# ABSTRACT: Provider manifest (/.well-known/langertha.json) value object, parser and validator
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use JSON::MaybeXS ();
use Langertha::Manifest::Endpoint;
use Langertha::Manifest::Auth;
use Langertha::Manifest::Model;
with 'Langertha::Manifest::Validation';


has provider_id => ( is => 'ro', isa => 'Str', required => 1 );
has issuer      => ( is => 'ro', isa => 'Str', required => 1 );

has endpoints => (
  is       => 'ro',
  isa      => 'ArrayRef[Langertha::Manifest::Endpoint]',
  required => 1,
);

has auth => (
  is      => 'ro',
  isa     => 'ArrayRef[Langertha::Manifest::Auth]',
  default => sub { [] },
);

has models => (
  is      => 'ro',
  isa     => 'ArrayRef[Langertha::Manifest::Model]',
  default => sub { [] },
);

# Stored as a private deep copy (plain JSON data only) and handed out as a
# fresh copy, so neither the caller's input nor a returned structure can
# mutate the immutable manifest.
has _extensions => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => 'extensions',
  default  => sub { {} },
);

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  if ( exists $args->{extensions} ) {
    $class->_error('extensions: must be a JSON object') unless ref $args->{extensions} eq 'HASH';
    $args->{extensions} = $class->_json_clone( 'extensions', $args->{extensions} );
  }
  return $args;
};

sub extensions {
  my ($self) = @_;
  return $self->_json_clone( 'extensions', $self->_extensions );
}


use constant SCHEMA_VERSION => 1;
use constant KIND           => 'langertha-provider';

sub schema_version { return SCHEMA_VERSION }
sub kind           { return KIND }


sub BUILD {
  my ($self) = @_;
  $self->_error( q{provider_id must match [a-z0-9][a-z0-9._-]* (max 128), got '}
    . $self->_display( $self->provider_id ) . q{'} )
    unless $self->provider_id =~ /\A[a-z0-9][a-z0-9._-]{0,127}\z/;
  $self->_check_url( 'issuer', $self->issuer );
  $self->_error('at least one endpoint is required') unless @{ $self->endpoints };

  my ( %auth, %endpoint, %model );
  for my $entry ( @{ $self->auth } ) {
    $self->_error( "duplicate auth id '" . $entry->id . q{'} ) if $auth{ $entry->id }++;
  }
  for my $entry ( @{ $self->endpoints } ) {
    $self->_error( "duplicate endpoint id '" . $entry->id . q{'} ) if $endpoint{ $entry->id }++;
    $self->_error( "endpoint '" . $entry->id . "': auth_ref '" . $entry->auth_ref
      . q{' names no auth entry} )
      if defined $entry->auth_ref && !$auth{ $entry->auth_ref };
  }
  for my $entry ( @{ $self->models } ) {
    my $shown = $self->_display( $entry->id );
    $self->_error( "model '$shown': endpoint_ref '" . $entry->endpoint_ref
      . q{' names no endpoint} )
      unless $endpoint{ $entry->endpoint_ref };
    $self->_error( "duplicate model '$shown' on endpoint '" . $entry->endpoint_ref . q{'} )
      if $model{ $entry->endpoint_ref }{ $entry->id }++;
  }
  return;
}

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub from_json {
  my ( $class, $text ) = @_;
  my $data = eval { $JSON->decode($text) };
  unless ( defined $data || !$@ ) {
    ( my $err = $@ ) =~ s/\s+at \S+ line \d+\.?\s*\z//s;
    croak "Langertha::Manifest: invalid JSON: $err";
  }
  return $class->from_hash($data);
}


sub from_hash {
  my ( $class, $data ) = @_;
  my $manifest = eval { $class->_from_hash($data) };
  return $manifest if $manifest;
  my $error = $@;
  my $message = blessed($error) && $error->can('message') ? $error->message : "$error";
  $message =~ s/\s+\z//;
  $message = "Langertha::Manifest: $message" unless $message =~ /\ALangertha::Manifest: /;
  croak $message;
}

sub _from_hash {
  my ( $class, $data ) = @_;
  # The version is checked before anything else: a document of another major
  # version may legitimately carry fields v1 does not know, and the useful
  # error then is "unsupported version", not "unknown field".
  $class->_error('must be a JSON object') unless ref $data eq 'HASH';
  my $version = $data->{schema_version};
  $class->_error(q{field 'schema_version' is required}) unless defined $version;
  # A JSON number with a whole value (1, 1.0, 1e0 -- the same verdict on every
  # JSON backend), never a string ("1"), checked before anything numifies it.
  $class->_error('schema_version: must be an integer (a JSON number, not a string)')
    unless $class->_is_whole_number($version);
  $class->_error( "unsupported schema_version $version (this Langertha reads "
    . SCHEMA_VERSION . ')' )
    unless $version == SCHEMA_VERSION;
  $class->_check_fields( $data,
    required => [qw( schema_version kind provider_id issuer endpoints )],
    optional => [qw( auth models extensions )],
  );
  $class->_error( q{kind: must be '} . KIND . q{'} )
    unless !ref $data->{kind} && $data->{kind} eq KIND;
  $class->_error('extensions: must be a JSON object')
    if exists $data->{extensions} && ref $data->{extensions} ne 'HASH';

  my %parsed;
  for my $section (
    [ endpoints => 'Langertha::Manifest::Endpoint' ],
    [ auth      => 'Langertha::Manifest::Auth' ],
    [ models    => 'Langertha::Manifest::Model' ],
  ) {
    my ( $name, $entry_class ) = @$section;
    next unless exists $data->{$name};
    $class->_error("$name: must be an array") unless ref $data->{$name} eq 'ARRAY';
    my @entries = @{ $data->{$name} };
    for my $i ( 0 .. $#entries ) {
      my $entry = eval { $entry_class->from_hash( $entries[$i] ) };
      $class->_rethrow( "${name}[$i]", $@ ) unless $entry;
      push @{ $parsed{$name} }, $entry;
    }
    $parsed{$name} //= [];
  }

  return $class->new(
    provider_id => $class->_string( 'provider_id', $data->{provider_id} ),
    issuer      => $class->_string( 'issuer', $data->{issuer} ),
    %parsed,
    ( exists $data->{extensions} ? ( extensions => $data->{extensions} ) : () ),
  );
}


sub endpoint {
  my ( $self, $id ) = @_;
  my ($found) = grep { $_->id eq $id } @{ $self->endpoints };
  return $found;
}


sub auth_entry {
  my ( $self, $id ) = @_;
  my ($found) = grep { $_->id eq $id } @{ $self->auth };
  return $found;
}


sub models_for_endpoint {
  my ( $self, $id ) = @_;
  return grep { $_->endpoint_ref eq $id } @{ $self->models };
}


sub to_hash {
  my ($self) = @_;
  return {
    # + 0: a fresh number, never the shared constant (constant folding may
    # have cached a string on it, and a JSON encoder would then emit "1").
    schema_version => SCHEMA_VERSION + 0,
    kind           => KIND,
    provider_id    => $self->provider_id,
    issuer         => $self->issuer,
    endpoints      => [ map { $_->to_hash } @{ $self->endpoints } ],
    auth           => [ map { $_->to_hash } @{ $self->auth } ],
    models         => [ map { $_->to_hash } @{ $self->models } ],
    extensions     => $self->extensions,
  };
}


sub to_json {
  my ($self) = @_;
  return $JSON->encode( $self->to_hash );
}


sub TO_JSON { shift->to_hash }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Manifest - Provider manifest (/.well-known/langertha.json) value object, parser and validator

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Manifest;

    # Parse (a JSON string or an already-decoded hashref) -- validated or croaks
    my $manifest = Langertha::Manifest->from_json($json_text);
    my $manifest = Langertha::Manifest->from_hash(\%data);

    for my $model ( @{ $manifest->models } ) {
      my $endpoint = $manifest->endpoint( $model->endpoint_ref );
      next unless $endpoint->is_known_dialect;
      printf "%s via %s at %s (tools: %s)\n", $model->id, $endpoint->dialect,
        $endpoint->base_url, $model->supports('tools_native') ? 'yes' : 'no';
    }

    # Serialize
    my $hashref = $manifest->to_hash;
    my $json    = $manifest->to_json;      # canonical, byte-stable

    # Build one from a configured engine
    use Langertha::Manifest::Builder;
    my $manifest = Langertha::Manifest::Builder->from_engine($engine);

=head1 DESCRIPTION

The data model of the provider manifest served at
C</.well-known/langertha.json>: a declarative description of what a provider
exposes — endpoints with their wire dialect, auth mechanisms, model ids and
declared capabilities. Langertha core owns the schema, these value objects,
the parser/validator and the L<Langertha::Manifest::Builder>; fetching,
trust, aliases and secret binding belong to the client (langertha-raider),
publishing to the servers (langertha-knarr, langertha-skeid). Core does no
network I/O here.

Schema version 1 carries exactly: C<schema_version> (C<1>), C<kind>
(C<langertha-provider>), C<provider_id>, C<issuer>, C<endpoints>, C<auth>,
C<models> and C<extensions>. Validation is strict:

=over

=item * a field outside the schema is rejected — at the top level and in
every endpoint, auth and model entry;

=item * a command-, code-, secret- or prompt-shaped field (C<command>,
C<exec>, C<engine_class>, C<api_key>, C<secret_path>, C<env>,
C<system_prompt>, C<mcp_servers>, C<tools>, …) is rejected explicitly with a
message saying why — a manifest never carries those;

=item * URLs are printable-ASCII C<http>/C<https> without userinfo, query
or fragment (best effort: a secret embedded in the path itself cannot be
detected);

=item * ids and model ids carry no control or format characters (a client
prints them);

=item * ids are unique and every C<auth_ref> / C<endpoint_ref> resolves;

=item * C<schema_version> must be a JSON number whose value is C<1> (C<1>,
C<1.0> and C<1e0> alike, on every JSON backend; the string C<"1"> is not); any other version
is rejected before anything else is checked.

=back

C<extensions> is inert: it must be an object of plain JSON data, and it is
kept and serialized exactly as given, never validated further or
interpreted by core.

Values, unlike structure, are open: an unknown C<dialect>, auth C<type> or
capability name is accepted. C<is_known_dialect> / C<is_known_type> tell a
client whether it has an adapter; a client treats a capability it does not
know as absent.

A manifest states what the provider B<claims>. It is not a probe result and
grants no local permission: a model claiming C<tools_native> does not
authorise running local tools.

=head2 provider_id

Stable provider slug, C<[a-z0-9][a-z0-9._-]*> (max 128).

=head2 issuer

Origin of the publisher, an C<http>/C<https> URL.

=head2 endpoints

ArrayRef of L<Langertha::Manifest::Endpoint>; at least one.

=head2 auth

ArrayRef of L<Langertha::Manifest::Auth>; may be empty.

=head2 models

ArrayRef of L<Langertha::Manifest::Model>; may be empty (a filtered
manifest can legitimately list none).

=head2 extensions

HashRef, inert: never validated beyond "plain JSON data" and never
interpreted by core; serialized exactly as given. It is deep-copied on
construction and every read returns a fresh copy, so mutating the input or
the returned structure does not change the manifest. A blessed object
(other than a JSON boolean) or a code reference in it is rejected.

=head2 schema_version

Always C<1>: the only schema version this Langertha reads and writes.

=head2 kind

Always C<langertha-provider>.

=head2 from_json

    my $manifest = Langertha::Manifest->from_json($json_bytes);

Decodes UTF-8 JSON text and hands it to L</from_hash>. Croaks on invalid
JSON and on every validation failure.

=head2 from_hash

    my $manifest = Langertha::Manifest->from_hash(\%data);

Validates a decoded manifest document and returns the object. Croaks with
C<Langertha::Manifest: E<lt>pathE<gt>: E<lt>reasonE<gt>> on the first
violation.

=head2 endpoint

    my $endpoint = $manifest->endpoint('chat');

The endpoint with that id, or C<undef>.

=head2 auth_entry

    my $auth = $manifest->auth_entry( $endpoint->auth_ref );

The auth entry with that id, or C<undef>.

=head2 models_for_endpoint

    my @models = $manifest->models_for_endpoint('chat');

The model entries served on that endpoint.

=head2 to_hash

The manifest as a plain Perl data structure, ready for any JSON encoder.
Capability values are JSON booleans; C<extensions> is returned as given.

=head2 to_json

UTF-8 JSON with sorted keys (canonical), so the output is byte-stable:
C<to_json> is a fixed point after one roundtrip
(C<< from_json($m->to_json)->to_json eq $m->to_json >>). Input that omitted
optional sections comes back with their defaults (C<auth>, C<models>,
C<extensions>, C<capabilities>) filled in, so the first serialization of
such input is not byte-identical to it.

=head1 SEE ALSO

=over

=item * L<Langertha::Manifest::Builder> - Builds a manifest from configured engines

=item * L<Langertha::Manifest::Endpoint>, L<Langertha::Manifest::Auth>, L<Langertha::Manifest::Model> - The entries

=item * L<Langertha::Role::Capabilities> - The capability vocabulary

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
