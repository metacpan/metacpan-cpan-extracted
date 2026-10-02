package Langertha::PromptCache;
# ABSTRACT: Immutable prompt-caching request control with cross-provider conversion
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );


has enable => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has ttl => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);


has key => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);


sub to_anthropic {
  my ( $self ) = @_;
  return () unless $self->enable;
  return (
    cache_control => {
      type => 'ephemeral',
      ( defined $self->ttl ? ( ttl => $self->ttl ) : () ),
    },
  );
}


sub to_openai {
  my ( $self ) = @_;
  return () unless defined $self->key && length $self->key;
  return ( prompt_cache_key => $self->key );
}


# Maps a cache_wire_format tag to the per-format serializer method.
my %TO_METHOD = (
  openai    => 'to_openai',
  anthropic => 'to_anthropic',
);

sub to {
  my ( $self, $fmt ) = @_;
  my $method = $TO_METHOD{ $fmt // '' }
    or croak "Langertha::PromptCache: unknown cache wire format '" . ( $fmt // '' ) . "'";
  return $self->$method;
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::PromptCache - Immutable prompt-caching request control with cross-provider conversion

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $c = Langertha::PromptCache->new(
        enable => 1,
        ttl    => '1h',
    );
    my %kwargs = $c->to('anthropic');
    # ( cache_control => { type => 'ephemeral', ttl => '1h' } )

    my $c2 = Langertha::PromptCache->new( key => 'my-route' );
    my %kw2 = $c2->to('openai');
    # ( prompt_cache_key => 'my-route' )

=head1 DESCRIPTION

Canonical value object for the request-side prompt-caching knob, dispatched
by an engine's C<cache_wire_format>. Mirrors L<Langertha::Reasoning>: the
per-provider placement of the field lives in this one reviewable place rather
than scattered across engines (ADR 0001).

Prompt caching is asymmetric across providers. Only two providers expose a
per-request knob worth modeling:

=over

=item * B<Anthropic> — an explicit C<cache_control> breakpoint enables caching
(top-level auto-place form). Carries an optional C<ttl> (C<5m> default, C<1h>).

=item * B<OpenAI> — caching is automatic; the only request-side lever is
C<prompt_cache_key>, a routing hint that steers which cache shard is used.

=back

Every other provider (Gemini, DeepSeek, ...) caches implicitly with no
request-side parameter, so this value object models exactly these two shapes.

=head2 enable

Whether to emit an Anthropic C<cache_control> breakpoint. Ignored by the
OpenAI serializer (OpenAI caching is automatic).

=head2 ttl

Optional Anthropic cache time-to-live: C<5m> (the current default when omitted)
or C<1h>. Only emitted when set; the C<1h> window needs this set explicitly.

=head2 key

Optional OpenAI C<prompt_cache_key> routing hint. Ignored by the Anthropic
serializer.

=head2 to_anthropic

Serializes to the top-level C<cache_control =E<gt> { type =E<gt> 'ephemeral' }>
auto-place form (plus C<ttl> when set). Empty list when caching is not enabled.

=head2 to_openai

Serializes to a flat C<prompt_cache_key>. Empty list when no key is set.

=head2 to

    my %kwargs = $c->to($cache_wire_format);

Dispatch to the per-format serializer. Returns the body kwargs to merge into
the request (an empty list when nothing applies to that wire).

=head1 SEE ALSO

=over

=item * L<Langertha::Role::PromptCache> - The composed role exposing the cache attributes

=item * L<Langertha::Reasoning> - Sibling value object for the reasoning-effort knob

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
