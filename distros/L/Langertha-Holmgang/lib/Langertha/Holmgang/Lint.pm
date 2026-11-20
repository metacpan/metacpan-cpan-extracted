package Langertha::Holmgang::Lint;
# ABSTRACT: The self-check every case passes on every load

use Moose;
use namespace::autoclean;
use utf8;

use Langertha::Holmgang::Error;
use Langertha::Holmgang::Expectation qw( filter_value );
use Langertha::Holmgang::Grader;
use Langertha::Holmgang::Template ();
use Langertha::Holmgang::World ();

our $VERSION = '0.002';


has grader => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_grader',
);
sub _build_grader { Langertha::Holmgang::Grader->new }


has mock_runs => (
  is        => 'ro',
  predicate => 'has_mock_runs',
);


sub _refuse {
  my ( $self, $field, $reason ) = @_;
  Langertha::Holmgang::Error->throw( $field, $reason );
}

sub lint {
  my ( $self, $case, $f ) = @_;
  $f //= $case->id;
  my $g = $self->grader;

  # 0. argument filters, where the world applies them (a where pattern takes {name} only)
  for my $t ( @{ $case->tools } ) {
    my $hs = $t->{handlers} || [];
    for my $j ( 0 .. $#$hs ) {
      my $hf = $f.': tools.'.$t->{name}.'.handlers['.$j.']';
      $self->_when_filters( $hs->[$j]{when}, $hf );
      my $ap = $hs->[$j]{apply} || [];
      for my $k ( 0 .. $#$ap ) {
        my $op = $ap->[$k];
        $self->_filters( $op->{$_}, $hf.'.apply['.$k.'].'.$_ ) for grep { exists $op->{$_} } @Langertha::Holmgang::World::OPS, qw( value at from to );
      }
    }
  }
  my $obs = $case->observe || [];
  $self->_when_filters( $obs->[$_]{when}, $f.': observe['.$_.']' ) for 0 .. $#$obs;

  # 1. templates
  for my $t ( @{ $case->tools } ) {
    my $hs = $t->{handlers} || [];
    for my $j ( 0 .. $#$hs ) {
      $self->_renders( $case, $hs->[$j]{output}, $f.': tools.'.$t->{name}.'.handlers['.$j.'].output' );
    }
  }
  $self->_renders( $case, $obs->[$_]{output}, $f.': observe['.$_.'].output' ) for 0 .. $#$obs;

  my $failed = sub {
    my ( $r ) = @_;
    return join '; ', map { '"'.$_->{title}.'": '.$_->{reason} } grep { $_->{required} && !$_->{passed} } @{ $r->{rules} };
  };
  # 5. a check command runs without a gap after every path
  my $check_gap = sub {
    my ( $r, $field ) = @_;
    my ( $rule ) = grep { defined $_->{sim_gap} } @{ $r->{rules} } or return;
    $self->_refuse( $f.': '.$field, 'check command "'.$rule->{title}.'" hits a gap of the simulation: '.$rule->{sim_gap} );
  };

  # 2. doing nothing
  my $noop = $g->grade( $case, { state => $case->initial_state, calls => [] } );
  $check_gap->( $noop, 'rules' );
  $self->_refuse( $f.': rules', 'doing nothing passes already — the rules check no change' )
    if $noop->{status} eq 'passed' && !$case->no_tool;

  # 3. the right paths
  my @alt = @{ $case->alternatives || [] };
  my @right = (
    [ solution => 'the reference solution', $case->solution ],
    map { [ 'alternatives['.$_.']', 'alternative "'.$alt[$_]{title}.'"', $alt[$_]{calls} ] } 0 .. $#alt,
  );
  for my $r ( @right ) {
    my ( $field, $name, $calls ) = @$r;
    my $sol = $g->replay( $case, $calls );
    if ( @{ $sol->{failed_calls} } ) {
      my $n = $sol->{failed_calls}[0];
      $self->_refuse( $f.': '.$field.'['.$n.']', 'call fails: '.( $sol->{outputs}[$n] // '' ) );
    }
    if ( @{ $sol->{sim_gaps} } ) {
      $self->_refuse( $f.': '.$field.'['.$sol->{sim_gaps}[0]{call}.']', 'gap of the simulation: '.$sol->{sim_gaps}[0]{gap} );
    }
    $check_gap->( $sol, $field );
    $self->_refuse( $f.': '.$field, $name.' does not pass: '.$failed->($sol) ) unless $sol->{status} eq 'passed';
  }

  # 4. the wrong solutions
  my $wrong = $case->wrong_solutions || [];
  for my $j ( 0 .. $#$wrong ) {
    my $w = $wrong->[$j];
    my $r = $g->replay( $case, $w->{calls} );
    $self->_refuse( $f.': wrong_solutions['.$j.']', 'wrong solution "'.$w->{title}.'" passes' ) if $r->{status} eq 'passed';
    $check_gap->( $r, 'wrong_solutions['.$j.']' );
  }

  $self->mock_runs->( $self, $case, $f ) if $self->has_mock_runs;
  return 1;
}


sub _when_filters {
  my ( $self, $when, $field ) = @_;
  $when ||= [];
  $self->_filters( $when->[$_]{path}, $field.'.when['.$_.'].path' ) for 0 .. $#$when;
  return;
}

# the {name|filter} the world's value and interp_text replace; a filter is known when
# filter_value takes it
sub _filters {
  my ( $self, $v, $field ) = @_;
  if ( ref $v eq 'HASH' ) { $self->_filters( $v->{$_}, $field.'.'.$_ ) for sort keys %$v; return }
  if ( ref $v eq 'ARRAY' ) { $self->_filters( $v->[$_], $field.'['.$_.']' ) for 0 .. $#$v; return }
  return if !defined $v || ref $v;
  while ( $v =~ /\{[A-Za-z_][A-Za-z0-9_]*\|([a-z]+)\}/g ) {
    my $name = $1;
    eval { filter_value( 'x', $name ); 1 }
      or $self->_refuse( $field, "unknown filter '".$name."' (known: split, int, lc)" );
  }
  return;
}

sub _renders {
  my ( $self, $case, $tmpl, $field ) = @_;
  return unless defined $tmpl;
  eval { Langertha::Holmgang::Template::render( $tmpl, $case->initial_state, {}, $self->grader->simulators ); 1 }
    or $self->_refuse( $field, 'output template (Kolon) broken: '.( $@ =~ s/\s+\z//r ) );
  return;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Lint - The self-check every case passes on every load

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $lint = Langertha::Holmgang::Lint->new( grader => $grader );
  $lint->lint( $case, 'cases/c1.yaml' );   # 1, or a Langertha::Holmgang::Error

  # with the two mock runs, as the loader's default lint has them
  my $lint = Langertha::Holmgang::Lint->new(
    mock_runs => Langertha::Holmgang::Runner->lint_mock_runs,
  );

=head1 DESCRIPTION

A case checks itself (cai-platform C<docs/entwurf-evals.md> §3.5) after the
shape check, on every load from either front end:

=over 4

=item 0. Every argument filter (C<{name|filter}>) the world applies — in the
path, C<value>, C<at>, C<from> and C<to> of a handler's change and in the
C<when> paths of handlers and observations — is one format 2 knows
(C<split>, C<int>, C<lc>), whether or not a solution reaches it.

=item 1. Every output template of the suite's handlers and the case's
observations renders against the initial state.

=item 2. B<Doing nothing fails> — except in the "no tool" family
(C<solution: []> with the required rule C<only_tools: []>), where doing
nothing is the right answer.

=item 3. The B<reference solution> and every B<alternative> pass, none of
their calls fails, and none hits a gap of the simulation.

=item 4. Every B<wrong solution> fails.

=item 5. No C<check> command hits a gap of the simulation after any of these
paths (doing nothing, right ones, wrong ones).

=back

That at least one required rule checks the end state is part of the shape
check (L<Langertha::Holmgang::Structure>). The two mock runs over a model
engine — replaying the reference solution passes, twice identically; text
only fails — need the runner; they come in as L</mock_runs>
(L<Langertha::Holmgang::Runner/lint_mock_runs>, the loader's default).

A case that does not hold is a L<Langertha::Holmgang::Error> with field and
reason, and does not load. Fix the case or the simulator, never lint.

=head2 grader

The L<Langertha::Holmgang::Grader> that replays the paths.

=head2 mock_runs

Optional code reference, called as C<< $code->( $lint, $case, $field ) >>
after the checks above pass. It runs the two mock runs and throws a
L<Langertha::Holmgang::Error> when one does not hold. Without it they do not
run.

=head2 lint

  $lint->lint( $case, $field );

Runs the checks above on a L<Langertha::Holmgang::Case>. C<$field> starts
every refused field (default the case id). Returns 1.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
