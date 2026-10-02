package Langertha::ModelProbe;
# ABSTRACT: Reads model-scoped capability facts from a provider's own model metadata
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use URI;


# The capabilities a probe may learn. Metadata that states more (Ollama's
# "tools" / "thinking", OpenRouter's supported_parameters, LM Studio's
# trained_for_tool_use) is deliberately not read yet: those flags drive the
# chat_f rewrite matrix (ADR 0005), image_input is advisory (ADR 0032).
my @PROBED_CAPABILITIES = qw( image_input );

sub probed_capabilities { return @PROBED_CAPABILITIES }


my %FORMAT = (
  openrouter => { method => 'GET',  extract => \&_extract_openrouter, catalogue => 1 },
  mistral    => { method => 'GET',  extract => \&_extract_mistral,    catalogue => 1 },
  lmstudio   => { method => 'GET',  extract => \&_extract_lmstudio,   catalogue => 1 },
  tsystems   => { method => 'GET',  extract => \&_extract_tsystems,   catalogue => 1 },
  ollama     => { method => 'POST', extract => \&_extract_ollama, per_model => 1 },
  llamacpp   => { method => 'GET',  extract => \&_extract_llamacpp },
);

sub _format {
  my ( $class, $format ) = @_;
  croak "Langertha::ModelProbe: format must be a string, not a reference"
    if ref $format;
  croak "Langertha::ModelProbe: unknown model_metadata_format '"
    . ( $format // '(undef)' ) . q{'}
    unless defined $format && $FORMAT{$format};
  return $FORMAT{$format};
}

sub is_known_format {
  my ( $class, $format ) = @_;
  return defined $format && !ref $format && exists $FORMAT{$format} ? 1 : 0;
}

sub http_method { return $_[0]->_format( $_[1] )->{method} }

sub per_model { return $_[0]->_format( $_[1] )->{per_model} ? 1 : 0 }

sub is_catalogue { return $_[0]->_format( $_[1] )->{catalogue} ? 1 : 0 }


sub extract {
  my ( $class, $format, $data, $models ) = @_;
  my $spec = $class->_format($format);
  return {} unless ref $data eq 'HASH';
  my $facts = $spec->{extract}->( $data, [ grep { _id_ok($_) } @{ ref $models eq q{ARRAY} ? $models : [] } ] );
  return $facts;
}


sub server_root_url {
  my ( $class, $url ) = @_;
  my $uri  = URI->new($url);
  my $path = $uri->path;
  $path =~ s{/v1/?\z}{};
  $path =~ s{/\z}{};
  $uri->path($path);
  return $uri->as_string;
}


sub lookup_ids {
  my ( $class, $format, $model ) = @_;
  $class->_format($format);
  return () unless _id_ok($model);
  my @ids = ($model);
  if ( $format eq 'ollama' ) {
    # Ollama names without a tag mean :latest (llava == llava:latest).
    if    ( $model =~ /\A(.+):latest\z/ ) { push @ids, $1 }
    elsif ( $model !~ /:/ )              { push @ids, "$model:latest" }
  }
  elsif ( $format eq 'openrouter' ) {
    # A routing variant (:online, :free, :nitro, :floor, :thinking, ...) is
    # the base model's capabilities; used only when the variant itself is
    # not listed.
    push @ids, $1 if $model =~ m{\A([^:]+/[^:]+):[A-Za-z0-9._-]+\z};
  }
  return @ids;
}


# Only a non-empty plain string is a model id; a reference or an empty
# string is never a store key.
sub _id_ok { return defined $_[0] && !ref $_[0] && length $_[0] ? 1 : 0 }

sub _bool { return $_[0] ? 1 : 0 }

sub _extract_openrouter {
  my ( $data ) = @_;
  my %facts;
  for my $model ( @{ ref $data->{data} eq 'ARRAY' ? $data->{data} : [] } ) {
    next unless ref $model eq 'HASH' && ref $model->{architecture} eq 'HASH';
    my $in = $model->{architecture}{input_modalities};
    next unless ref $in eq 'ARRAY';
    my $vision = _bool( grep { defined && $_ eq 'image' } @$in );
    for my $id ( grep { _id_ok($_) } $model->{id}, $model->{canonical_slug} ) {
      $facts{$id} //= { image_input => $vision };
    }
  }
  return \%facts;
}

sub _extract_mistral {
  my ( $data ) = @_;
  my ( %by_id, %by_alias );
  for my $model ( @{ ref $data->{data} eq 'ARRAY' ? $data->{data} : [] } ) {
    next unless ref $model eq 'HASH' && ref $model->{capabilities} eq 'HASH';
    next unless exists $model->{capabilities}{vision};
    my $fact = { image_input => _bool( $model->{capabilities}{vision} ) };
    $by_id{ $model->{id} } = $fact if _id_ok( $model->{id} );
    for my $alias ( @{ ref $model->{aliases} eq 'ARRAY' ? $model->{aliases} : [] } ) {
      $by_alias{$alias} //= { %$fact } if _id_ok($alias);
    }
  }
  return { %by_alias, %by_id };
}

sub _extract_lmstudio {
  my ( $data ) = @_;
  my %facts;
  for my $model ( @{ ref $data->{models} eq 'ARRAY' ? $data->{models} : [] } ) {
    next unless ref $model eq 'HASH' && ref $model->{capabilities} eq 'HASH';
    next unless exists $model->{capabilities}{vision};
    my $vision = _bool( $model->{capabilities}{vision} );
    my @ids = ( $model->{key},
      map { ref $_ eq 'HASH' ? $_->{id} : () }
        @{ ref $model->{loaded_instances} eq 'ARRAY' ? $model->{loaded_instances} : [] } );
    $facts{$_} //= { image_input => $vision } for grep { _id_ok($_) } @ids;
  }
  return \%facts;
}

sub _extract_tsystems {
  my ( $data ) = @_;
  my %facts;
  for my $model ( @{ ref $data->{data} eq 'ARRAY' ? $data->{data} : [] } ) {
    next unless ref $model eq 'HASH' && ref $model->{meta_data} eq 'HASH';
    my $in = $model->{meta_data}{input_modalities};
    next unless ref $in eq 'ARRAY' && _id_ok( $model->{id} );
    my $vision = _bool( grep { defined && !ref && lc eq 'image' } @$in );
    $facts{ $model->{id} } //= { image_input => $vision };
  }
  return \%facts;
}

sub _extract_ollama {
  my ( $data, $models ) = @_;
  my $caps = $data->{capabilities};
  return {} unless ref $caps eq 'ARRAY' && @$models;
  my $vision = _bool( grep { defined && $_ eq 'vision' } @$caps );
  return { map { $_ => { image_input => $vision } } @$models };
}

sub _extract_llamacpp {
  my ( $data, $models ) = @_;
  my $modalities = $data->{modalities};
  return {} unless ref $modalities eq 'HASH' && exists $modalities->{vision} && @$models;
  my $vision = _bool( $modalities->{vision} );
  return { map { $_ => { image_input => $vision } } @$models };
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ModelProbe - Reads model-scoped capability facts from a provider's own model metadata

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Normally reached through the engine (ADR 0032):
    my $learned = await $engine->probe_model_capabilities_f;
    # { 'google/gemma-4-26b-a4b' => { image_input => 1 }, ... }

    # The inbound door itself, for a metadata document already in hand:
    my $facts = Langertha::ModelProbe->extract( lmstudio => $data, \@models );

=head1 DESCRIPTION

The inbound door for B<model metadata>: it reads what a provider's own
metadata endpoint says about a model and turns it into capability facts in the
L<Langertha::Role::Capabilities> vocabulary. It is keyed by a per-concern
format tag, the engine's C<model_metadata_format> (ADR 0032), the same way the
tool value objects are keyed by C<tool_wire_format> (ADR 0001):

=over

=item * C<openrouter> - C<GET /models>, C<data[].architecture.input_modalities>
(C<image> in the list means the model sees images). Facts are keyed by C<id>
and C<canonical_slug>.

=item * C<mistral> - C<GET /v1/models>, C<data[].capabilities.vision>. Facts
are keyed by C<id> and by each entry of C<aliases>; an entry's own C<id> wins
over another entry's alias.

=item * C<lmstudio> - LM Studio's native C<GET /api/v1/models>,
C<models[].capabilities.vision>. Facts are keyed by C<key> and by the C<id> of
each C<loaded_instances> entry. Entries without C<capabilities> (embedding
models) give no fact.

=item * C<tsystems> - T-Systems AI Foundation Services C<GET /v2/models>,
C<data[].meta_data.input_modalities>, a nullable array of strings; C<image> in
it, matched case-insensitively because the spelling is not documented, means
the model sees images. Facts are keyed by C<id>. An entry without
C<meta_data> or with a missing or null C<input_modalities> gives no fact.
Shaped from the provider's public OpenAPI document only: no key exists to
verify it live.

=item * C<ollama> - C<POST /api/show> with C<{ model }>, one request per model;
the C<capabilities> array (C<vision> in it means the model sees images). A
server too old to report C<capabilities> gives no fact.

=item * C<llamacpp> - C<GET /props>, C<modalities.vision>. llama.cpp serves one
model whatever id the request names, so the fact is keyed by every model id the
probe was asked about. A server without C<modalities> gives no fact.

=back

Only capabilities the metadata states outright are read, and in this version
that is C<image_input> alone (L</probed_capabilities>). A document that does
not carry the field yields no fact for that model, never a false one.

This class has no instances; all methods are class methods. It does no network
I/O: the engine sends the request (L<Langertha::Role::Capabilities/probe_model_capabilities_f>).

=head2 probed_capabilities

    my @caps = Langertha::ModelProbe->probed_capabilities;   # ('image_input')

The capability names a probe can learn. Everything else stays with the static
layers of L<Langertha::Role::Capabilities/engine_capabilities>.

=head2 is_known_format

    Langertha::ModelProbe->is_known_format('ollama');   # 1

=head2 http_method

    my $method = Langertha::ModelProbe->http_method('ollama');   # 'POST'

=head2 per_model

True when the format answers for one model per request (C<ollama>: the request
body names the model); false when one request answers for the whole server.

=head2 is_catalogue

    Langertha::ModelProbe->is_catalogue('openrouter');   # 1
    Langertha::ModelProbe->is_catalogue('llamacpp');     # 0

True when one document names every model it describes (C<openrouter>,
C<mistral>, C<lmstudio>, C<tsystems>), so a single probe can learn the whole catalogue
(C<< models => 'all' >>). False for C<ollama> (one model per request) and
C<llamacpp> (the document does not name its model).

=head2 extract

    my $facts = Langertha::ModelProbe->extract( $format, $data, \@models );

Reads a decoded metadata document and returns
C<< { $model_id => { image_input => 0|1 } } >>. C<\@models> are the ids the
probe asked about: the C<ollama> and C<llamacpp> documents do not name the
model, so their fact is keyed by these. Croaks on an unknown format; a
document of an unexpected shape gives an empty HashRef.

=head2 server_root_url

    Langertha::ModelProbe->server_root_url('http://localhost:11434/v1');
    # http://localhost:11434

Strips a trailing C</v1> (and slash) from an OpenAI-compatible base URL, for
the self-hosted servers whose metadata lives beside C</v1> (Ollama C</api/show>,
LM Studio C</api/v1/models>, llama.cpp C</props>).

=head2 lookup_ids

    my @ids = Langertha::ModelProbe->lookup_ids( ollama => 'llava' );
    # ('llava', 'llava:latest')

The store keys, in order, under which a fact for C<$model> may have been
learned: the exact id first, then the format's equivalent spelling. For
C<ollama> a missing tag is C<:latest> (C<llava> and C<llava:latest> find each
other). For C<openrouter> a routing variant suffix (C<openai/gpt-4o:online>,
C<:free>, C<:nitro>, ...) falls back to the base id when the variant itself was
not listed. Other formats match exactly. A non-string or empty id gives an
empty list.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Capabilities> - C<probe_model_capabilities_f> and the learned layer

=item * L<Langertha::Role::ImageInput> - The C<image_input> flag

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
