package Langertha::Reasoning::BudgetPolicy;
# ABSTRACT: Invented level<->token-budget interpolation, clamped to a Profile's enforced bounds
our $VERSION = '0.503';
use Moose;
use Moose::Util::TypeConstraints;
use Carp qw( croak );
use Langertha::Reasoning::Profile;


# The normalized ascending reasoning vocabulary ordinal ladder. The enum type
# itself lives once in Langertha::Reasoning::Profile (redefining it croaks); this
# is the numeric spacing convention (c) interpolates against.
my %LEVEL_ORDER = (
  none => 0, minimal => 1, low => 2, medium => 3, high => 4, xhigh => 5, max => 6,
);

enum 'Langertha::Reasoning::BudgetForm'  => [qw( range explicit )];
enum 'Langertha::Reasoning::BudgetCurve' => [qw( linear log )];

has profile => (
  is       => 'ro',
  isa      => 'Langertha::Reasoning::Profile',
  required => 1,
);


has form => (
  is      => 'ro',
  isa     => 'Langertha::Reasoning::BudgetForm',
  lazy    => 1,
  builder => '_build_form',
);

sub _build_form { return $_[0]->has_points ? 'explicit' : 'range' }


has curve => (
  is      => 'ro',
  isa     => 'Langertha::Reasoning::BudgetCurve',
  default => 'linear',
);


has points => (
  is        => 'ro',
  isa       => 'HashRef[Int]',
  predicate => 'has_points',
);


has levels => (
  is      => 'ro',
  isa     => 'ArrayRef[Langertha::Reasoning::Level]',
  lazy    => 1,
  builder => '_build_levels',
);

sub _build_levels {
  my ( $self ) = @_;
  if ( $self->has_points ) {
    return [ sort { $LEVEL_ORDER{$a} <=> $LEVEL_ORDER{$b} } keys %{ $self->points } ];
  }
  my @profile_levels = @{ $self->profile->levels };
  return @profile_levels ? [@profile_levels] : [qw( low medium high )];
}


has default_bool_level => (
  is      => 'ro',
  isa     => 'Langertha::Reasoning::Level',
  default => 'medium',
);


has source => (
  is      => 'ro',
  isa     => 'Str',
  default => 'library convention (invented level<->budget interpolation, not provider wire-truth)',
);


sub BUILD {
  my ( $self ) = @_;

  if ( $self->has_points ) {
    for my $level ( keys %{ $self->points } ) {
      croak "Langertha::Reasoning::BudgetPolicy: unknown level '$level' in points "
        . "(expected one of " . join( '|', sort keys %LEVEL_ORDER ) . ")"
        unless exists $LEVEL_ORDER{$level};
    }
  }

  if ( $self->form eq 'explicit' && !$self->has_points ) {
    croak "Langertha::Reasoning::BudgetPolicy: form 'explicit' requires 'points'";
  }

  if ( $self->form eq 'range' ) {
    my $profile = $self->profile;
    croak "Langertha::Reasoning::BudgetPolicy: form 'range' requires the profile to "
      . "carry both budget_min and budget_max (category-b bounds to interpolate across)"
      unless $profile->has_budget_min && $profile->has_budget_max;
  }

  return;
}

# The firewall: no numeric output may cross the profile's category-(b) bounds.
sub _clamp {
  my ( $self, $number ) = @_;
  my $profile = $self->profile;
  $number = $profile->budget_min
    if $profile->has_budget_min && $number < $profile->budget_min;
  $number = $profile->budget_max
    if $profile->has_budget_max && $number > $profile->budget_max;
  return $number;
}

# The ascending ordinal span of the anchor ladder.
sub _ladder_span {
  my ( $self ) = @_;
  my @ord = sort { $a <=> $b } map { $LEVEL_ORDER{$_} } @{ $self->levels };
  return ( $ord[0], $ord[-1] );
}

# The fraction (0..1) a level sits at along the anchor ladder, clamped so a level
# below the ladder floor pins to 0 and one above the ceiling pins to 1.
sub _level_fraction {
  my ( $self, $level ) = @_;
  my $ord = $LEVEL_ORDER{$level};
  croak "Langertha::Reasoning::BudgetPolicy: unknown level '" . ( $level // '' ) . "'"
    unless defined $ord;
  my ( $lo, $hi ) = $self->_ladder_span;
  return 1 if $hi == $lo;
  my $frac = ( $ord - $lo ) / ( $hi - $lo );
  $frac = 0 if $frac < 0;
  $frac = 1 if $frac > 1;
  return $frac;
}


sub budget_for {
  my ( $self, $level ) = @_;
  croak "Langertha::Reasoning::BudgetPolicy: unknown level '" . ( $level // '' ) . "'"
    unless defined $level && exists $LEVEL_ORDER{$level};

  my $raw;
  if ( $self->form eq 'explicit' ) {
    my $points = $self->points;
    if ( exists $points->{$level} ) {
      $raw = $points->{$level};
    }
    else {
      # Nearest curated anchor by ordinal distance (ties break to the lower).
      my $want = $LEVEL_ORDER{$level};
      my ($nearest) = sort {
             abs( $LEVEL_ORDER{$a} - $want ) <=> abs( $LEVEL_ORDER{$b} - $want )
          || $LEVEL_ORDER{$a} <=> $LEVEL_ORDER{$b}
      } keys %$points;
      $raw = $points->{$nearest};
    }
  }
  else {
    my $profile = $self->profile;
    my $min     = $profile->budget_min;
    my $max     = $profile->budget_max;
    my $frac    = $self->_level_fraction($level);
    if ( $self->curve eq 'log' ) {
      my $base = $min > 0 ? $min : 1;
      $raw = $base * ( $max / $base )**$frac;
    }
    else {
      $raw = $min + ( $max - $min ) * $frac;
    }
  }

  return $self->_clamp( int( $raw + 0.5 ) );
}


sub level_for {
  my ( $self, $budget ) = @_;
  croak "Langertha::Reasoning::BudgetPolicy: level_for needs an integer budget"
    unless defined $budget;

  my $profile = $self->profile;
  return 'none'
    if $profile->has_off_value && $budget == $profile->off_value;

  $budget = $self->_clamp($budget);

  if ( $self->form eq 'explicit' ) {
    my $points = $self->points;
    my ($nearest) = sort {
           abs( $self->_clamp( $points->{$a} ) - $budget )
             <=> abs( $self->_clamp( $points->{$b} ) - $budget )
        || $LEVEL_ORDER{$a} <=> $LEVEL_ORDER{$b}
    } keys %$points;
    return $nearest;
  }

  my $min = $profile->budget_min;
  my $max = $profile->budget_max;
  my ( $lo, $hi ) = $self->_ladder_span;
  my $frac = $max == $min ? 0 : ( $budget - $min ) / ( $max - $min );
  my $target = $lo + $frac * ( $hi - $lo );
  my ($nearest) = sort {
         abs( $LEVEL_ORDER{$a} - $target ) <=> abs( $LEVEL_ORDER{$b} - $target )
      || $LEVEL_ORDER{$a} <=> $LEVEL_ORDER{$b}
  } @{ $self->levels };
  return $nearest;
}


sub for_model {
  my ( $class, $id, %opts ) = @_;
  return $class->new(
    profile => Langertha::Reasoning::Profile->for_model($id),
    %opts,
  );
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Reasoning::BudgetPolicy - Invented level<->token-budget interpolation, clamped to a Profile's enforced bounds

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $policy = Langertha::Reasoning::BudgetPolicy->new(
        profile => Langertha::Reasoning::Profile->for_model('gemini-2.5-pro'),
        form    => 'range',   # interpolate across the profile's [min,max]
        levels  => [qw( low medium high )],
    );
    my $budget = $policy->budget_for('medium');   # ~16448, always within 128..32768
    my $level  = $policy->level_for(4096);        # nearest anchor level

    # explicit anchors instead of a curve
    my $curated = Langertha::Reasoning::BudgetPolicy->new(
        profile => Langertha::Reasoning::Profile->for_model('gemini-2.5-flash'),
        points  => { none => 0, low => 2048, medium => 8192, high => 24576 },
    );

=head1 DESCRIPTION

Category (c) of karr k173's three-category reasoning taxonomy (ADR 0023): the
B<invented> level-to-token-budget interpolation and its inbound inverse. B<No
provider publishes an official reasoning-level to token-budget mapping> — OpenAI
and Anthropic effort is adaptive and undocumented, and the only numeric
level-to-token formulas in the wild are OpenRouter's, labeled OpenRouter's own
convention. So every number this class emits is B<library convention, not
wire-truth>, and L</source> should say so honestly.

Because the numbers are invented, they must never be able to emit a value the
API rejects. Every numeric output of this class is B<clamped to the owning
L<Langertha::Reasoning::Profile>'s category-(b) enforced bounds>
(L<Langertha::Reasoning::Profile/budget_min> / L</budget_max>). This is the
firewall rule: convention (c) may B<read> the profile's enforced bounds (b) but
can never B<cross> them. Putting those bounds inside this convention layer — as
the original karr k173 ticket proposed — would let an override silently violate a
hard API bound; keeping them in the Profile and clamping against them here is the
single most important correction of the design.

This is B<not> a capability and is B<not> default-shipped for effort providers.
It exists only where a downstream consumer needs budget<->level conversion and
constructs it explicitly. Nothing in Langertha wires it in by default.

=head2 profile

The owning L<Langertha::Reasoning::Profile>. Its category-(b) bounds
(L<Langertha::Reasoning::Profile/budget_min> / L</budget_max>) are the firewall
every numeric output is clamped to. A C<range>-form policy needs both bounds
present (there is nothing to interpolate across otherwise).

=head2 form

C<range> (interpolate a curve across the profile's C<[budget_min, budget_max]>)
or C<explicit> (look the budget up in curated L</points>). Defaults to
C<explicit> when L</points> is given, otherwise C<range>.

=head2 curve

For C<form =E<gt> 'range'>: C<linear> (even spacing) or C<log> (geometric
spacing, finer at the low end). Ignored for C<explicit>. Default C<linear>; per
karr k173 q3 the curve is convention, so C<log> is offered but not asserted as
truth.

=head2 points

For C<form =E<gt> 'explicit'>: a curated map of reasoning level to token budget
(the invented anchors). Keys must be members of the normalized vocabulary
(C<none|minimal|low|medium|high|xhigh|max>). Each looked-up budget is still
clamped to the profile's (b) bounds, so a curated anchor outside them can never
reach the wire.

=head2 levels

The quantization anchor ladder (ascending) this convention spans — the
consumer-side anchors that deliberately do B<not> live in the Profile (whose
C<levels> is empty for a budget control, keeping it pure wire-truth). Defaults to
the profile's C<levels> when it has any, to the sorted keys of L</points> for an
explicit policy, else to C<low|medium|high>.

=head2 default_bool_level

The normalized level a boolean-control provider's "thinking on" (C<think:true>)
corresponds to for this convention, the boolean-to-level half of the inbound
bijection (its "off" counterpart is C<none>). Default C<medium>.

=head2 source

The honest curation receipt. Because no provider publishes a level-to-budget
table, this defaults to a string that says the numbers are convention rather than
wire-truth; a consumer curating empirical anchors should replace it with what it
measured and when.

=head2 budget_for

    my $tokens = $policy->budget_for('medium');

Convert a normalized reasoning level to an integer token budget. In C<explicit>
form the curated L</points> anchor is used (the nearest anchor by ordinal when
the exact level is absent); in C<range> form the L</curve> is interpolated across
the profile's C<[budget_min, budget_max]>. The result is B<always clamped to the
profile's category-(b) bounds> — the firewall — so an invented number can never
reach the wire above the ceiling or below the floor.

=head2 level_for

    my $level = $policy->level_for(4096);

The inbound inverse: convert an integer token budget to the nearest normalized
level on the anchor ladder. The budget is clamped to the profile's (b) bounds
first, so an out-of-range budget maps to the boundary level rather than off the
ladder; a budget equal to the profile's C<off_value> maps to C<none>.

=head2 for_model

    my $policy = Langertha::Reasoning::BudgetPolicy->for_model(
        'gemini-2.5-pro', form => 'range' );

Convenience constructor mirroring L<Langertha::Reasoning::Profile/for_model>:
resolves the id to its profile and passes the remaining convention options
(L</form>, L</curve>, L</points>, L</levels>, L</source>) through to L</new>.

=head1 SEE ALSO

=over

=item * L<Langertha::Reasoning::Profile> - The wire-truth categories (a)+(b) whose bounds this convention (c) is clamped to

=item * L<Langertha::Reasoning> - The value object that resolves and consumes profiles for outbound serialization

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
