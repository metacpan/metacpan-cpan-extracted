package Langertha::Knarr::Reasoning;
# ABSTRACT: Map a face's native reasoning controls onto the normalized reasoning_effort level
our $VERSION = '1.102';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS ();


# The normalized ascending reasoning vocabulary (Langertha::Reasoning::Level).
my %LEVEL = map { $_ => 1 } qw( none minimal low medium high xhigh max );

has default_level => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_default_level',
);

sub _build_default_level {
  my ( $self ) = @_;
  return 'medium' unless $self->budget_available;
  my $attr = Langertha::Reasoning::BudgetPolicy->meta->find_attribute_by_name('default_bool_level');
  my $level = $attr && $attr->default;
  return defined $level && $LEVEL{$level} ? $level : 'medium';
}


has budget_points => (
  is        => 'ro',
  isa       => 'HashRef[Int]',
  predicate => 'has_budget_points',
);


sub BUILD {
  my ( $self, $args ) = @_;
  croak __PACKAGE__."->new: unknown default_level '".$args->{default_level}."'"
    if exists $args->{default_level} && !$LEVEL{ $args->{default_level} // '' };
  if ( $self->has_budget_points ) {
    for my $level ( sort keys %{ $self->budget_points } ) {
      croak __PACKAGE__."->new: unknown level '".$level."' in budget_points" unless $LEVEL{$level};
    }
  }
  return;
}

has budget_available => (
  is       => 'ro',
  isa      => 'Bool',
  lazy     => 1,
  builder  => '_build_budget_available',
  init_arg => undef,
);

sub _build_budget_available {
  # Optional core feature (Langertha > 0.503): probed, not a hard dependency.
  return eval { require Langertha::Reasoning::BudgetPolicy; 1 } ? 1 : 0;
}


sub fallback_budget_points {
  return { low => 2048, medium => 8192, high => 24576 };
}


sub budget_policy {
  my ( $self, $model ) = @_;
  return unless $self->budget_available;
  my $policy = eval {
    my $profile = Langertha::Reasoning::Profile->for_model($model);
    my %opts = $self->has_budget_points
      ? ( points => $self->budget_points )
      : $profile->has_budget_min && $profile->has_budget_max
        ? ()
        : ( points => $self->fallback_budget_points );
    Langertha::Reasoning::BudgetPolicy->new( profile => $profile, %opts );
  };
  return $policy;
}


sub level_for_budget {
  my ( $self, $budget, $model ) = @_;
  return unless defined $budget && !ref $budget && $budget =~ /\A[0-9]+\z/;
  my $policy = $self->budget_policy($model) or return;
  my $level = eval { $policy->level_for( $budget + 0 ) };
  return defined $level && $LEVEL{$level} ? $level : ();
}


sub level_for_bool {
  my ( $self, $on ) = @_;
  return $on ? $self->default_level : 'none';
}


sub _explicit_level {
  my ( $self, $value ) = @_;
  return defined $value && !ref $value && length $value ? $value : ();
}

sub from_anthropic {
  my ( $self, $data ) = @_;
  return unless ref $data eq 'HASH';
  my $output_config = ref $data->{output_config} eq 'HASH' ? $data->{output_config} : {};
  for my $explicit ( $data->{reasoning_effort}, $output_config->{effort} ) {
    my ($level) = $self->_explicit_level($explicit);
    return $level if defined $level;
  }
  my $thinking = $data->{thinking};
  return unless ref $thinking eq 'HASH';
  my $type = $thinking->{type} // '';
  return 'none' if $type eq 'disabled';
  return $self->default_level if $type eq 'adaptive';
  return unless $type eq 'enabled';
  return $self->default_level unless defined $thinking->{budget_tokens};
  return $self->level_for_budget( $thinking->{budget_tokens}, $data->{model} );
}


sub from_ollama {
  my ( $self, $think, $explicit ) = @_;
  my ($level) = $self->_explicit_level($explicit);
  return $level if defined $level;
  return unless defined $think;
  return $self->level_for_bool($think) if JSON::MaybeXS::is_bool($think);
  return if ref $think;
  return $LEVEL{$think} ? $think : ();
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Reasoning - Map a face's native reasoning controls onto the normalized reasoning_effort level

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    my $reasoning = Langertha::Knarr::Reasoning->new;

    # Anthropic face: thinking / output_config.effort
    my $level = $reasoning->from_anthropic($body);

    # Ollama face: think (boolean or level string)
    my $level = $reasoning->from_ollama( $body->{think} );

    # exactly overridable
    my $mine = Langertha::Knarr::Reasoning->new(
      default_level => 'high',
      budget_points => { low => 1024, medium => 4096, high => 16384 },
    );

=head1 DESCRIPTION

Only the OpenAI face carries the normalized C<reasoning_effort> enum
natively. The Anthropic face carries C<thinking> (C<enabled> with a
C<budget_tokens> integer, C<adaptive>, C<disabled>) and the Ollama face
carries C<think> (a boolean, or a level string on GPT-OSS). This class turns
those into the one normalized level L<Langertha::Knarr::Request/reasoning_effort>
holds, so the routed path forwards a client's thinking request to whatever
engine the model routes to, capability-gated like every other control.

The mapping is:

=over

=item * C<thinking.type = disabled>, C<think: false> - C<none>

=item * C<thinking.type = adaptive>, C<thinking.type = enabled> without a
budget, C<think: true> - L</default_level> (C<medium>)

=item * C<think: "low">, ... - the level as sent, when it is one of
C<none minimal low medium high xhigh max>; any other string maps to nothing

=item * C<thinking.budget_tokens = N> - the nearest level of a
L<Langertha::Reasoning::BudgetPolicy> for the request's model (see
L</budget_points>)

=back

A face's own explicit effort always wins over a derived one: a top-level
C<reasoning_effort>, and on the Anthropic face C<output_config.effort>, are
taken as sent. Every value that does not fit maps to nothing, never to an
invented level, and nothing here croaks on a client body.

Budget mapping needs a core with L<Langertha::Reasoning::BudgetPolicy>
(L</budget_available>). On an older core (Langertha 0.503) C<budget_tokens>
stays unmapped - the request carries no C<reasoning_effort> from it - while
the boolean and level-string forms, which need no budget convention, still
map.

=head2 default_level

The level a client's "thinking on" without a level maps to (C<think: true>,
C<thinking.type = adaptive>, C<thinking.type = enabled> without a budget).
Defaults to L<Langertha::Reasoning::BudgetPolicy/default_bool_level> on a
core that has it, else C<medium>. Its "off" counterpart is always C<none>.

=head2 budget_points

Optional curated level-to-token anchors, e.g.
C<< { low => 1024, medium => 4096, high => 16384 } >>. When set, every
C<budget_tokens> maps through an C<explicit>
L<Langertha::Reasoning::BudgetPolicy> with these points. When unset, a model
whose L<Langertha::Reasoning::Profile> carries both budget bounds (Gemini 2.5)
maps through the C<range> policy across those bounds, and every other model
through L</fallback_budget_points>. The policy always clamps to the profile's
enforced bounds.

=head2 budget_available

True when the installed core has L<Langertha::Reasoning::BudgetPolicy>, i.e.
when C<budget_tokens> maps at all.

=head2 fallback_budget_points

The anchors used for a model whose profile carries no budget bounds (every
Claude model) when L</budget_points> is unset:
C<< { low => 2048, medium => 8192, high => 24576 } >> - the curated example
anchors of L<Langertha::Reasoning::BudgetPolicy>. No provider publishes a
level-to-budget table, so these are convention, not wire-truth. There is no
C<none> anchor: a client that enabled thinking with a budget never maps to
C<none>. Override in a subclass, or set L</budget_points>.

=head2 budget_policy

    my $policy = $reasoning->budget_policy('claude-sonnet-4-6');

The L<Langertha::Reasoning::BudgetPolicy> a budget for C<$model> maps
through (see L</budget_points>), or nothing when L</budget_available> is
false or the policy cannot be built.

=head2 level_for_budget

    my $level = $reasoning->level_for_budget( 4096, $model );

The normalized level a token budget maps to for C<$model>, or nothing for a
budget that is not a non-negative integer or when budgets do not map (see
L</budget_available>).

=head2 level_for_bool

    my $level = $reasoning->level_for_bool(1);   # default_level
    my $level = $reasoning->level_for_bool(0);   # 'none'

=head2 from_anthropic

    my $level = $reasoning->from_anthropic($decoded_body);

The level an Anthropic Messages body asks for: a top-level
C<reasoning_effort> or C<output_config.effort> as sent, else what
C<thinking> maps to (see L</DESCRIPTION>), else nothing.

=head2 from_ollama

    my $level = $reasoning->from_ollama( $body->{think}, $body->{reasoning_effort} );

The level an Ollama C<think> value asks for: a JSON boolean maps through
L</level_for_bool>, a level string of the normalized vocabulary is kept, any
other value maps to nothing. An explicit C<reasoning_effort> wins.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr::Request> - Holds the resulting C<reasoning_effort>, capability-gated in C<chat_f_args>

=item * L<Langertha::Reasoning::BudgetPolicy> - The budget-to-level convention budgets map through

=item * L<Langertha::Reasoning::Profile> - The per-model bounds that convention is clamped to

=back

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
