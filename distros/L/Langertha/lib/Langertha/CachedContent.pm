package Langertha::CachedContent;
# ABSTRACT: Immutable value object for a Gemini explicit cachedContent resource
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );


has name => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  predicate => 'has_name',
);


has model => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_model',
);


has contents => (
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);


has system_instruction => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  predicate => 'has_system_instruction',
  default   => sub { undef },
);


has tools => (
  is      => 'ro',
  isa     => 'Maybe[ArrayRef]',
  default => sub { undef },
);


has ttl => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);


has expire_time => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);


has display_name => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);


has create_time => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);


has update_time => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);


has total_token_count => (
  is      => 'ro',
  isa     => 'Maybe[Int]',
  default => sub { undef },
);


# Build-time wire-truth gate: ttl and expire_time are mutually exclusive
# (the CachedContent resource's `expiration` field is a oneof — exactly one
# of expireTime|ttl). Croak early rather than emit an ambiguous wire form.
sub BUILD {
  my ( $self ) = @_;

  if ( defined $self->ttl && defined $self->expire_time ) {
    croak "Langertha::CachedContent: 'ttl' and 'expire_time' are mutually "
      . "exclusive — pick one (expiration is a oneof on the wire)";
  }

  # Name format: cachedContents/{id} when present.
  if ( $self->has_name ) {
    my $n = $self->name;
    croak "Langertha::CachedContent: name must be 'cachedContents/{id}'; got '$n'"
      unless $n =~ m{\AcachedContents/[^/\s]+\z};
  }
}

# --- Wire serializers ---

sub to_create_body {
  my ( $self ) = @_;
  croak "Langertha::CachedContent: model is required to create a cache"
    unless $self->has_model;

  my %body = ( model => $self->model );

  if ( $self->has_system_instruction ) {
    $body{systemInstruction} = {
      parts => [ { text => $self->system_instruction } ],
    };
  }

  if ( $self->tools && @{ $self->tools } ) {
    require Langertha::Tool;
    # tools is Tool[] here as on generateContent: each Tool wraps its
    # functionDeclarations, so the gemini tools payload goes out as is (k327).
    $body{tools} = Langertha::Tool->format_list( 'gemini', $self->tools );
  }

  if ( @{ $self->contents } ) {
    $body{contents} = $self->contents;
  }

  if ( defined $self->ttl ) {
    $body{ttl} = $self->ttl;
  }
  elsif ( defined $self->expire_time ) {
    $body{expireTime} = $self->expire_time;
  }

  if ( defined $self->display_name ) {
    $body{displayName} = $self->display_name;
  }

  return \%body;
}


# Convenience: the field that L<Langertha::Engine::Gemini> drops into a
# generateContent body to reference an existing cache.
sub to_reference {
  my ( $self ) = @_;
  croak "Langertha::CachedContent: cannot reference an unnamed cache (set 'name' first)"
    unless $self->has_name;
  return { cachedContent => $self->name };
}


# --- Constructors from wire-format hashes ---

sub from_hash {
  my ( $class, $hash ) = @_;
  return $hash if ref($hash) && eval { $hash->isa(__PACKAGE__) };
  return undef unless ref($hash) eq 'HASH';
  return undef unless length( $hash->{name} // '' );

  # expiration is a proto oneof, flat in JSON: the server answers with a
  # top-level expireTime (ttl is input only). An `expiration` wrapper is read
  # as an alternate spelling (ADR 0018). A server time wins over a ttl, which
  # would otherwise trip the BUILD oneof gate (k327).
  my $exp = ref( $hash->{expiration} ) eq 'HASH' ? $hash->{expiration} : {};
  my $expire_time = $hash->{expireTime} // $exp->{expireTime};
  my $ttl = defined $expire_time ? undef : $hash->{ttl} // $exp->{ttl};

  my $um = $hash->{usageMetadata};
  my $tokens = ref($um) eq 'HASH' ? $um->{totalTokenCount} : undef;

  my $si_text;
  if ( ref( $hash->{systemInstruction} ) eq 'HASH' ) {
    my $parts = $hash->{systemInstruction}{parts};
    $si_text = ref($parts) eq 'ARRAY' && ref( $parts->[0] ) eq 'HASH'
      ? $parts->[0]{text}
      : undef;
  }

  return $class->new(
    name              => $hash->{name},
    model             => $hash->{model},
    $hash->{displayName} ? ( display_name => $hash->{displayName} ) : (),
    $hash->{createTime}  ? ( create_time  => $hash->{createTime}  ) : (),
    $hash->{updateTime}  ? ( update_time  => $hash->{updateTime}  ) : (),
    defined $ttl         ? ( ttl          => $ttl )                 : (),
    defined $expire_time ? ( expire_time  => $expire_time )         : (),
    defined $tokens      ? ( total_token_count => $tokens )          : (),
    defined $si_text     ? ( system_instruction => $si_text )        : (),
    ref( $hash->{contents} ) eq 'ARRAY' ? ( contents => $hash->{contents} ) : (),
  );
}


# --- Convenience accessors ---

# Clock-vs-expiry comparison. Uses updateTime (or createTime as fallback)
# plus the configured ttl so a CachedContent built from a create-body
# (which carries ttl but no expireTime) can still answer is_expired.
sub age_seconds {
  my ( $self ) = @_;
  my $t = $self->update_time || $self->create_time or return undef;
  my $epoch = _parse_rfc3339_unix($t);
  return undef unless defined $epoch;
  my $delta = time - $epoch;
  return $delta < 0 ? 0 : $delta;   # future timestamps clamp to 0
}


sub is_expired {
  my ( $self ) = @_;

  # Prefer server-reported expireTime when present.
  if ( $self->expire_time ) {
    my $deadline = _parse_rfc3339_unix( $self->expire_time );
    return defined $deadline && time >= $deadline ? 1 : 0;
  }

  # Otherwise derive from updateTime + ttl (the resource's clock is the
  # server's clock, but we keep the predicate conservative: returns 0 when
  # there is not enough information to decide).
  return 0 unless defined $self->ttl;
  my $age = $self->age_seconds;
  return 0 unless defined $age;
  my $ttl = _parse_duration_seconds( $self->ttl );
  return 0 unless defined $ttl;
  return $age >= $ttl ? 1 : 0;
}


# Parse "300s" / "3.5s" / "3600s" / "60m" / "1h" etc. into integer seconds.
# Supports the subset Google documents explicitly: a number followed by
# `s`. Falls back to treating the whole string as a number of seconds.
sub _parse_duration_seconds {
  my ( $d ) = @_;
  return undef unless defined $d && length $d;
  if ( $d =~ /\A(\d+(?:\.\d+)?)s\z/ ) {
    return int( $1 + 0.5 );
  }
  if ( $d =~ /\A(\d+(?:\.\d+)?)m\z/ ) {
    return int( $1 * 60 + 0.5 );
  }
  if ( $d =~ /\A(\d+(?:\.\d+)?)h\z/ ) {
    return int( $1 * 3600 + 0.5 );
  }
  if ( $d =~ /\A(\d+)\z/ ) {
    return int $1;
  }
  return undef;
}

# Parse RFC 3339 ("2026-08-11T10:05:00Z" / "+00:00" / fractional seconds)
# into a unix epoch. Best-effort; returns undef for unparseable input.
sub _parse_rfc3339_unix {
  my ( $s ) = @_;
  return undef unless defined $s && length $s;

  # Match the subset Google returns: 2026-08-11T10:05:00Z, with optional
  # fractional seconds and optional +HH:MM offset. Hand-rolled so we don't
  # lean on Time::Piece's TZ semantics — those vary by build and would
  # produce different "now" deltas across machines.
  unless ( $s =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(Z|[+-]\d{2}:\d{2})\z/ ) {
    return undef;
  }
  my ( $y, $mo, $d, $h, $mi, $sec, $tz ) = ( $1, $2, $3, $4, $5, $6, $7 );
  require Time::Local;
  my $utc = Time::Local::timegm( $sec, $mi, $h, $d, $mo - 1, $y );
  if ( $tz eq 'Z' ) {
    return $utc;
  }
  $tz =~ /\A([+-])(\d{2}):(\d{2})\z/ or return $utc;
  my $off = $2 * 3600 + $3 * 60;
  $off = -$off if $1 eq '-';
  return $utc - $off;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::CachedContent - Immutable value object for a Gemini explicit cachedContent resource

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Create-input shape (no name yet)
    my $cc = Langertha::CachedContent->new(
        model              => 'models/gemini-2.5-pro',
        system_instruction => 'You are a careful reviewer.',
        ttl                => '300s',
        contents           => [ { role => 'user', parts => [ { text => 'long prompt...' } ] } ],
    );
    my $body = $cc->to_create_body;
    # { model => 'models/gemini-2.5-pro',
    #   systemInstruction => { parts => [ { text => '...' } ] },
    #   ttl => '300s',
    #   contents => [ ... ] }

    # Server-returned shape
    my $cc2 = Langertha::CachedContent->from_hash({
        name          => 'cachedContents/abc123',
        model         => 'models/gemini-2.5-pro',
        displayName   => 'reviewer-context',
        createTime    => '2026-08-11T10:00:00Z',
        updateTime    => '2026-08-11T10:00:00Z',
        expireTime    => '2026-08-11T10:05:00Z',
        usageMetadata => { totalTokenCount => 4096 },
    });
    $cc2->is_expired;   # bool (vs. cached expireTime + clock)
    $cc2->age_seconds;  # since updateTime

=head1 DESCRIPTION

Canonical value object for the Gemini explicit context-cache resource
(L<https://ai.google.dev/api/caching>) — a server-side managed cache of
input context with its own lifecycle (create / get / list / patch / delete).

Distinct from L<Langertha::PromptCache>:

=over

=item * L<Langertha::PromptCache> models the B<request-side> caching knob
(Anthropic C<cache_control> breakpoint, OpenAI C<prompt_cache_key>) that
flips behaviour on the next request. ADR 0009.

=item * This class models the B<resource> itself — a long-lived cached
context blob identified by C<name> (C<cachedContents/{id}>) that the
client manages across requests.

=back

The two seams are deliberately separate: a CachedContent resource lives
across many requests and the engine request body references it by name
(via the C<cachedContent> field on a C<generateContent> body). See
L<Langertha::Role::CachedContent> for the create / get / list / update /
delete wrappers around this object.

The value object carries one wire shape today: Gemini C<cachedContent>.
Like L<Langertha::Tool>/L<Langertha::PromptCache>, future providers that
expose the same resource can add a C<to_$fmt> serializer without touching
the engines.

=head2 name

Resource name, C<cachedContents/{id}>. C<undef> for create-input
objects that have not yet been persisted; populated from the server
response or set manually when wrapping an externally-obtained cache.

=head2 model

Required on create. Full model name (C<models/gemini-2.5-pro>) per the
Gemini REST contract. Optional on read-only shapes (C<Langertha::Engine::Gemini>
always populates it on responses, but a future response-less path may not).

=head2 contents

ArrayRef of content parts (the same shape L<Langertha::Engine::Gemini> puts in
the C<contents> request body field: C<[{ role =E<gt> 'user', parts =E<gt> [{text =E<gt> '...'}] }]>).
Immutable on the server once created — input only, never echoed back as
updatable.

=head2 system_instruction

Optional C<systemInstruction> text. The Gemini REST contract accepts text
only (no structured parts).

=head2 tools

Optional ArrayRef of tool definitions in the canonical L<Langertha::Tool>
form (or any shape L<Langertha::Tool::from_list> accepts). Serialized on
create as the Gemini C<tools> list, C<< [ { functionDeclarations => [...] } ] >>,
the shape a C<generateContent> request uses.

=head2 ttl

Optional Duration string (C<"300s">, C<"3600s">). Mutually exclusive with
L</expire_time> — exactly one of the two is permitted per
L</BUILD>. L<Langertha::Role::CachedContent/create_f> sends whichever was
set.

=head2 expire_time

Optional absolute expiration as an RFC 3339 timestamp string
(C<"2026-08-11T10:05:00Z">). Mutually exclusive with L</ttl>.

=head2 display_name

Optional human-readable label (max 128 Unicode chars on the server). Only
the create body carries it; updates can PATCH it via C<updateMask>.

=head2 create_time

Server-set RFC 3339 timestamp. Populated from the create / get / list
response.

=head2 update_time

Server-set RFC 3339 timestamp of last update. Populated from the response.

=head2 total_token_count

From C<usageMetadata.totalTokenCount> in the create / get / list response.
Useful for cache-hit accounting; the per-request hit count surfaces via
the L<Langertha::Response/usage> C<cached_content_token_count> field.

=head2 to_create_body

    my $href = $cc->to_create_body;

Returns the POST C<cachedContents> request body HashRef. Croaks if
L</model> is unset. L</ttl> / L</expire_time> serialize into the
C<expiration> oneof as C<ttl> or C<expireTime>.

=head2 to_reference

    my $href = $cc->to_reference;
    # { cachedContent => 'cachedContents/abc123' }

Returns the HashRef L<Langertha::Engine::Gemini> merges into a
C<generateContent> body to reference this cachedContent by name.

=head2 from_hash

    my $cc = Langertha::CachedContent->from_hash($response_href);

Builds a value object from a C<cachedContent> response hash (GET / POST /
LIST). Returns C<undef> if C<$hash> is not a hashref or carries no
C<name>. The expiry is read from the top-level C<expireTime> (or C<ttl>) the
server sends; an C<expiration> wrapper holding either is read as well. When
both an C<expireTime> and a C<ttl> are present, C<expireTime> is kept. Accepts an existing L<Langertha::CachedContent> as a pass-through.

=head2 age_seconds

Returns whole seconds since the cache's L</update_time> (or
L</create_time> as fallback), or C<undef> if neither is set. Useful for
diagnosing TTL drift between the client's clock and the server.

=head2 is_expired

Returns true when the cache is past its L</expire_time> (server-reported),
or when C<update_time + ttl> has elapsed for caches that did not report
an absolute expiry. Returns false when no expiry information is available.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::CachedContent> - Lifecycle role (create / get / list / update / delete)

=item * L<Langertha::PromptCache> - Sibling value object for the request-side caching knob (ADR 0009)

=item * L<Langertha::Engine::Gemini> - The only engine currently consuming this object

=item * L<https://ai.google.dev/api/caching> - Gemini CachedContent REST reference

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
