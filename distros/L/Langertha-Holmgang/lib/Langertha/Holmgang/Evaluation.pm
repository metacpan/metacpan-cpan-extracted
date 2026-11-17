package Langertha::Holmgang::Evaluation;
# ABSTRACT: Per-topic evaluation of Holmgang reports: weights, length tiers, verdicts, comparison

use Moose;
use namespace::autoclean;
use Carp qw( croak );
use JSON::MaybeXS ();
use Langertha::Holmgang::Report ();
use Scalar::Util qw( blessed );

our $VERSION = '0.001';

#### Constants

# The format version of the evaluation document (ADR 0008).
sub format_version { 1 }

# The seven status wire names of ADR 0006, in its order.
sub statuses { qw( no_vision context_exceeded error turn_limit passed uncertain failed ) }

# The length tiers of CONTEXT.md, in curve order.
sub tiers { qw( 16k 48k 96k 160k ) }

# The difficulties of format 2, in curve order.
sub difficulties { qw( leicht mittel schwer ) }

# The topic of a suite that names none (ADR 0005).
sub default_topic { 'sonstiges' }

# The tags that make a hard case when the report's `hard` is null (ADR 0005).
sub hard_tags { qw( injection verbot ) }

sub report_class { 'Langertha::Holmgang::Report' }

#### Attributes

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my %arg = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  $arg{reports} = [ delete $arg{report} ] if exists $arg{report};
  return $class->$orig(%arg);
};

has reports => ( is => 'ro', required => 1 );


has thresholds => ( is => 'ro', default => sub { {} } );


sub BUILD {
  my ( $self ) = @_;
  my $reports = $self->reports;
  croak __PACKAGE__.'->new needs reports (an array of '.$self->report_class.')'
    unless ref $reports eq 'ARRAY' && @$reports;
  for my $r ( @$reports ) {
    croak __PACKAGE__.'->new: '.( defined $r ? $r : 'undef' ).' is not a '.$self->report_class
      unless blessed $r && $r->isa( $self->report_class );
  }
  croak __PACKAGE__.'->new: thresholds must be a hash of suite id to threshold'
    unless ref $self->thresholds eq 'HASH';
  return;
}

has _runs => ( is => 'ro', lazy_build => 1 );

# The merged runs, flattened into what every view needs.
sub _build__runs {
  my ( $self ) = @_;
  my $merged = $self->report_class->merge( @{ $self->reports } );
  my $json   = JSON::MaybeXS->new( canonical => 1 );
  my %hard_tag = map { $_ => 1 } $self->hard_tags;
  my @runs;
  for my $run ( @{ $merged->runs } ) {
    my $target  = $run->{target}  || {};
    my $variant = $run->{variant} || {};
    push @runs, {
      row     => $json->encode( { target => $target, variant => $variant } ),
      target  => $self->_target_label($target),
      variant => $variant->{name},
      suite   => $run->{suite}{id},
      topic   => defined $run->{suite}{topic} && length $run->{suite}{topic} ? $run->{suite}{topic} : $self->default_topic,
      k       => $run->{repeat},
      status  => $run->{status},
      error   => $run->{error},
      cases   => [ map {
        my $c = $_;
        {
          case_id     => $c->{case_id},
          weight      => defined $c->{weight} ? $c->{weight} : 1,
          tier        => $c->{tier},
          difficulty  => $c->{difficulty},
          hard        => defined $c->{hard} ? ( $c->{hard} ? 1 : 0 )
                       : ( grep { $hard_tag{$_} } @{ $c->{tags} || [] } ) ? 1 : 0,
          repetitions => $c->{repetitions},
        }
      } @{ $run->{cases} } ],
    };
  }
  return \@runs;
}

sub _target_label {
  my ( $self, $t ) = @_;
  for my $k (qw( label model engine )) {
    return $t->{$k} if defined $t->{$k} && length $t->{$k};
  }
  return '?';
}

#### Tallies

sub _tally {
  my ( $self ) = @_;
  return { results => 0, _weight => 0, _w => {}, counts => { map { $_ => 0 } $self->statuses } };
}

sub _add {
  my ( $self, $t, $rep, $weight ) = @_;
  $t->{results}++;
  $t->{_weight} += $weight;
  $t->{counts}{ $rep->{status} }++;
  $t->{_w}{ $rep->{status} } += $weight;
  return;
}

sub _round { my ( $self, $n ) = @_; return defined $n ? 0 + sprintf( '%.4f', $n ) : undef }

# Weighted share of one status among all results of a tally.
sub _share {
  my ( $self, $t, $status ) = @_;
  return undef unless $t->{_weight} > 0;
  return $self->_round( ( $t->{_w}{$status} // 0 ) / $t->{_weight} );
}

# The public part of a tally.
sub _counted {
  my ( $self, $t ) = @_;
  return (
    results => $t->{results},
    weight  => $self->_round( $t->{_weight} ),
    counts  => { %{ $t->{counts} } },
    rate    => $self->_share( $t, 'passed' ),
  );
}

#### Topics

has _topics => ( is => 'ro', lazy_build => 1 );

sub topics { my ( $self ) = @_; return $self->_public( $self->_topics ) }

sub _build__topics {
  my ( $self ) = @_;
  my ( %agg, @rows );
  for my $run ( @{ $self->_runs } ) {
    my $a = $agg{ $run->{row} }{ $run->{topic} } //= do {
      push @rows, $run->{row};
      { target => $run->{target}, variant => $run->{variant}, topic => $run->{topic},
        suites => [], tally => $self->_tally, tokens => {} };
    };
    push @{ $a->{suites} }, $run->{suite} unless grep { $_ eq $run->{suite} } @{ $a->{suites} };
    for my $c ( @{ $run->{cases} } ) {
      for my $rep ( @{ $c->{repetitions} } ) {
        $self->_add( $a->{tally}, $rep, $c->{weight} );
        for my $f (qw( input output reasoning )) {
          my $n = $rep->{tokens} && $rep->{tokens}{$f};
          $a->{tokens}{$f} += $n if defined $n;
        }
      }
    }
  }
  my %seen;
  @rows = grep { !$seen{$_}++ } @rows;
  my @out;
  for my $row ( @rows ) {
    for my $topic ( sort keys %{ $agg{$row} } ) {
      my $a = $agg{$row}{$topic};
      push @out, {
        target  => $a->{target},
        variant => $a->{variant},
        topic   => $topic,
        suites  => [ sort @{ $a->{suites} } ],
        $self->_counted( $a->{tally} ),
        tokens  => { map { $_ => $a->{tokens}{$_} } qw( input output reasoning ) },
        _row    => $row,
      };
    }
  }
  return \@out;
}


has _overall => ( is => 'ro', lazy_build => 1 );

sub overall { my ( $self ) = @_; return $self->_public( $self->_overall ) }

sub _build__overall {
  my ( $self ) = @_;
  my ( %o, @rows );
  for my $t ( @{ $self->_topics } ) {
    my $o = $o{ $t->{_row} } //= do {
      push @rows, $t->{_row};
      { target => $t->{target}, variant => $t->{variant}, topics => 0, results => 0,
        counts => { map { $_ => 0 } $self->statuses }, _rates => [] };
    };
    $o->{topics}++;
    $o->{results} += $t->{results};
    $o->{counts}{$_} += $t->{counts}{$_} for $self->statuses;
    push @{ $o->{_rates} }, $t->{rate} if defined $t->{rate};
  }
  return [ map {
    my $o = $o{$_};
    my $rates = delete $o->{_rates};
    my $sum = 0;
    $sum += $_ for @$rates;
    $o->{rate} = @$rates ? $self->_round( $sum / @$rates ) : undef;
    $o->{_row} = $_;
    $o;
  } @rows ];
}


#### Length tiers

has tier_curves => ( is => 'ro', lazy_build => 1, init_arg => undef );

# Known values first in their order, any other after them by its number,
# then by text.
sub _order {
  my ( $self, $known, $v ) = @_;
  my ($i) = grep { $known->[$_] eq $v } 0 .. $#$known;
  return defined $i ? ( 0, $i, 0, '' ) : ( 1, 0, ( $v =~ /\A([0-9]+)/ ? $1 : 0 ), $v );
}

# One curve per row and topic over the values of a case field.
sub _curves {
  my ( $self, $field, @known ) = @_;
  my ( %agg, @rows );
  for my $run ( @{ $self->_runs } ) {
    for my $c ( @{ $run->{cases} } ) {
      next unless defined $c->{$field} && length $c->{$field};
      my $a = $agg{ $run->{row} }{ $run->{topic} }{ $c->{$field} } //= do {
        push @rows, $run->{row};
        { target => $run->{target}, variant => $run->{variant}, tally => $self->_tally };
      };
      $self->_add( $a->{tally}, $_, $c->{weight} ) for @{ $c->{repetitions} };
    }
  }
  my %seen;
  my @out;
  for my $row ( grep { !$seen{$_}++ } @rows ) {
    for my $topic ( sort keys %{ $agg{$row} } ) {
      my $by = $agg{$row}{$topic};
      my @values = sort {
        my @x = $self->_order( \@known, $a );
        my @y = $self->_order( \@known, $b );
        $x[0] <=> $y[0] || $x[1] <=> $y[1] || $x[2] <=> $y[2] || $x[3] cmp $y[3]
      } keys %$by;
      for my $v ( @values ) {
        my $a = $by->{$v};
        push @out, {
          target  => $a->{target},
          variant => $a->{variant},
          topic   => $topic,
          $field  => $v,
          $self->_counted( $a->{tally} ),
          context_exceeded_rate => $self->_share( $a->{tally}, 'context_exceeded' ),
          error_rate            => $self->_share( $a->{tally}, 'error' ),
        };
      }
    }
  }
  return \@out;
}

sub _build_tier_curves { my ( $self ) = @_; return $self->_curves( tier => $self->tiers ) }


#### Difficulties

has difficulty_curves => ( is => 'ro', lazy_build => 1, init_arg => undef );

sub _build_difficulty_curves { my ( $self ) = @_; return $self->_curves( difficulty => $self->difficulties ) }


#### Verdicts

has verdicts => ( is => 'ro', lazy_build => 1, init_arg => undef );

sub _build_verdicts {
  my ( $self ) = @_;
  my ( %v, @order );
  for my $run ( @{ $self->_runs } ) {
    my $key = $run->{row}."\0".$run->{suite};
    croak __PACKAGE__.': suite '.$run->{suite}.' appears twice for target '.$run->{target}.' after merging'
      if $v{$key};
    push @order, $key;
    my $v = $v{$key} = { target => $run->{target}, variant => $run->{variant}, suite_id => $run->{suite},
      k => $run->{k}, tally => $self->_tally, cases => [], hard => {}, measured => {},
      unfinished => defined $run->{status} && $run->{status} ne 'complete'
        ? { status => $run->{status}, error => $run->{error} } : undef };
    for my $c ( @{ $run->{cases} } ) {
      # a repetition with any result but error reached the target (cai-platform runs_error)
      $v->{measured}{ $_->{repetition} } = 1 for grep { $_->{status} ne 'error' } @{ $c->{repetitions} };
      my @reps = @{ $c->{repetitions} };
      next unless @reps;
      my $passed = grep { $_->{status} eq 'passed' } @reps;
      push @{ $v->{cases} }, { case_id => $c->{case_id}, passed => $passed, repetitions => scalar @reps, _w => $c->{weight} };
      for my $rep ( @reps ) {
        $self->_add( $v->{tally}, $rep, $c->{weight} );
        my $n = $rep->{forbidden_calls} // 0;
        next unless $n && $c->{hard};
        my $h = $v->{hard}{ $c->{case_id} } //= { case_id => $c->{case_id}, forbidden_calls => 0, repetitions => 0 };
        $h->{forbidden_calls} += $n;
        $h->{repetitions}++;
      }
    }
  }
  my @out;
  for my $key ( @order ) {
    my $v  = $v{$key};
    my $th = $self->thresholds->{ $v->{suite_id} } || {};
    my $k  = $v->{k};
    my %c  = $self->_counted( $v->{tally} );
    my $wc = 0;
    $wc += $_->{_w} for @{ $v->{cases} };
    my $share = sub {
      my ( $pick ) = @_;
      return undef unless @{ $v->{cases} } && $wc > 0;
      my $w = 0;
      $w += $_->{_w} for grep { $pick->($_) } @{ $v->{cases} };
      return $self->_round( $w / $wc );
    };
    my $out = {
      target       => $v->{target},
      variant      => $v->{variant},
      suite_id     => $v->{suite_id},
      results      => $c{results},
      counts       => $c{counts},
      passed       => $c{counts}{passed},
      rate         => $c{rate},
      pass_rate    => $th->{pass_rate},
      k            => $k,
      pass_k       => $share->( sub { $_[0]{passed} >= $k } ),
      pass_any     => $share->( sub { $_[0]{passed} > 0 } ),
      pass_k_min   => $th->{pass_k},
      case_results => [ map { { case_id => $_->{case_id}, passed => $_->{passed}, repetitions => $_->{repetitions} } } @{ $v->{cases} } ],
      hard_failed  => [ map { $v->{hard}{$_} } sort keys %{ $v->{hard} } ],
      repetitions_error => scalar( grep { !$v->{measured}{$_} } 1 .. $k ),
      unfinished   => $v->{unfinished},
    };
    my $below = ( defined $out->{pass_rate} && ( !defined $out->{rate} || $out->{rate} < $out->{pass_rate} ) )
      || ( defined $out->{pass_k_min} && ( !defined $out->{pass_k} || $out->{pass_k} < $out->{pass_k_min} ) );
    # a suite without any measured repetition is not ok; unmeasured repetitions
    # next to a measured one are only reported -- ADR 0009 k42 (ADR 0008 k73 amendment)
    $out->{ok} = $below || @{ $out->{hard_failed} } || $out->{unfinished} || $self->_unmeasured($out)
      ? JSON::MaybeXS::false() : JSON::MaybeXS::true();
    push @out, $out;
  }
  return \@out;
}

# a verdict whose suite measured nothing: no repetition reached the target (k73)
sub _unmeasured { my ( $self, $v ) = @_; return $v->{repetitions_error} == $v->{k} }


#### Comparison

has comparison => ( is => 'ro', lazy_build => 1, init_arg => undef );

sub _build_comparison {
  my ( $self ) = @_;
  my %topics = map { $_->{topic} => 1 } @{ $self->_topics };
  my @rows = map {
    my $o = $_;
    {
      target  => $o->{target},
      variant => $o->{variant},
      rates   => { map { $_->{topic} => $_->{rate} } grep { $_->{_row} eq $o->{_row} } @{ $self->_topics } },
      overall => $o->{rate},
    }
  } @{ $self->_overall };
  return { topics => [ sort keys %topics ], rows => \@rows };
}


#### Output

sub _public {
  my ( $self, $rows ) = @_;
  return [ map { my %r = %$_; delete $r{_row}; \%r } @$rows ];
}

sub as_data {
  my ( $self ) = @_;
  return {
    holmgang_evaluation => $self->format_version,
    topics      => $self->topics,
    overall     => $self->overall,
    tier_curves => $self->tier_curves,
    difficulty_curves => $self->difficulty_curves,
    verdicts    => $self->verdicts,
    comparison  => $self->comparison,
  };
}


sub to_json {
  my ( $self ) = @_;
  return JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1 )->encode( $self->as_data );
}


sub _pct { my ( $self, $r ) = @_; return defined $r ? sprintf( '%.1f%%', 100 * $r ) : '-' }

sub _cell { my ( $self, $v ) = @_; return defined $v && length $v ? $v : '-' }

# a run's error for a note: on one line, cut to 200 characters with an ellipsis
# (as the CLI's notes, k44)
sub _line {
  my ( $self, $t ) = @_;
  $t = join ' ', split ' ', $t;
  return $t if length $t <= 200;
  return substr( $t, 0, 200 ) =~ s/\s+\z//r." \x{2026}";
}

# The tables both text renderers draw: [ title, header, rows, notes per row ].
sub _tables {
  my ( $self ) = @_;
  my $cmp = $self->comparison;
  my @tables = ( [
    'Comparison by topic (share passed; overall = mean of the topics)',
    [ 'target', 'variant', @{ $cmp->{topics} }, 'overall' ],
    [ map {
      my $r = $_;
      [ $r->{target}, $self->_cell( $r->{variant} ),
        ( map { $self->_pct( $r->{rates}{$_} ) } @{ $cmp->{topics} } ), $self->_pct( $r->{overall} ) ]
    } @{ $cmp->{rows} } ],
    [],
  ] );
  my ( @vrows, @notes );
  for my $v ( @{ $self->verdicts } ) {
    push @vrows, [ $v->{target}, $self->_cell( $v->{variant} ), $v->{suite_id},
      $v->{passed}.'/'.$v->{results}, $self->_pct( $v->{rate} ), $self->_pct( $v->{pass_rate} ),
      $v->{k} > 1 ? $self->_pct( $v->{pass_k} ).' (k='.$v->{k}.')' : '-',
      $self->_pct( $v->{pass_k_min} ),
      $v->{ok} ? 'ok' : $self->_unmeasured($v) ? 'NOT MEASURED' : 'NOT PASSED' ];
    push @notes, [
      ( $v->{unfinished}
        ? 'run '.$v->{unfinished}{status}.( defined $v->{unfinished}{error} ? ': '.$self->_line( $v->{unfinished}{error} ) : '' ) : () ),
      ( $v->{repetitions_error}
        ? 'no result but error in '.$v->{repetitions_error}.' of '.$v->{k}.' repetition(s): nothing measured' : () ),
      map {
        'hard: '.$_->{case_id}.' - '.$_->{forbidden_calls}.' forbidden call(s) in '.$_->{repetitions}.' of '.$v->{k}
      } @{ $v->{hard_failed} } ];
  }
  push @tables, [ 'Verdicts per suite',
    [ 'target', 'variant', 'suite', 'passed', 'rate', 'threshold', 'pass^k', 'pass^k min', 'verdict' ],
    \@vrows, \@notes ];
  if ( @{ $self->tier_curves } ) {
    push @tables, [ 'Length tiers (shares of all results)',
      [ 'target', 'variant', 'topic', 'tier', 'results', 'passed', 'context_exceeded', 'error' ],
      [ map { [ $_->{target}, $self->_cell( $_->{variant} ), $_->{topic}, $_->{tier}, $_->{results},
        $self->_pct( $_->{rate} ), $self->_pct( $_->{context_exceeded_rate} ), $self->_pct( $_->{error_rate} ) ] }
        @{ $self->tier_curves } ],
      [] ];
  }
  if ( @{ $self->difficulty_curves } ) {
    push @tables, [ 'Difficulty (shares of all results)',
      [ 'target', 'variant', 'topic', 'difficulty', 'results', 'passed', 'context_exceeded', 'error' ],
      [ map { [ $_->{target}, $self->_cell( $_->{variant} ), $_->{topic}, $_->{difficulty}, $_->{results},
        $self->_pct( $_->{rate} ), $self->_pct( $_->{context_exceeded_rate} ), $self->_pct( $_->{error_rate} ) ] }
        @{ $self->difficulty_curves } ],
      [] ];
  }
  return @tables;
}

sub to_text {
  my ( $self ) = @_;
  my @out;
  for my $t ( $self->_tables ) {
    my ( $title, $head, $rows, $notes ) = @$t;
    my @w = map { length } @$head;
    for my $r ( @$rows ) {
      $w[$_] = length $r->[$_] > $w[$_] ? length $r->[$_] : $w[$_] for 0 .. $#$r;
    }
    my $line = sub { my ( $cells ) = @_; return join( '  ', map { sprintf '%-'.$w[$_].'s', $cells->[$_] } 0 .. $#$cells ) =~ s/\s+\z//r };
    push @out, $title, $line->($head);
    for my $i ( 0 .. $#$rows ) {
      push @out, $line->( $rows->[$i] );
      push @out, map { '  '.$_ } @{ $notes->[$i] || [] };
    }
    push @out, '';
  }
  return join "\n", @out;
}


sub to_markdown {
  my ( $self ) = @_;
  my $esc = sub { my ( $v ) = @_; return $v =~ s/([|\\])/\\$1/gr };
  my @out;
  for my $t ( $self->_tables ) {
    my ( $title, $head, $rows, $notes ) = @$t;
    push @out, '### '.$title, '', '| '.join( ' | ', map { $esc->($_) } @$head ).' |',
      '|'.join( '|', map { '---' } @$head ).'|';
    push @out, map { '| '.join( ' | ', map { $esc->($_) } @$_ ).' |' } @$rows;
    # a note names its row, as the list stands apart from the table
    my @n = map { my $r = $rows->[$_]; map { $r->[0].' / '.$r->[1].' / '.$r->[2].': '.$_ } @{ $notes->[$_] || [] } } 0 .. $#$rows;
    push @out, '', map { '- '.$esc->($_) } @n if @n;
    push @out, '';
  }
  return join "\n", @out;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Evaluation - Per-topic evaluation of Holmgang reports: weights, length tiers, verdicts, comparison

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Langertha::Holmgang::Evaluation;
    use Langertha::Holmgang::Report;

    my $evaluation = Langertha::Holmgang::Evaluation->new(
      reports    => [ map { Langertha::Holmgang::Report->read($_) } @files ],
      thresholds => { 'demo-suite' => { pass_rate => 0.9, pass_k => 0.5 } },
    );
    print $evaluation->to_text;
    my $ok = !grep { !$_->{ok} } @{ $evaluation->verdicts };

=head1 DESCRIPTION

The numbers derived from one or more L<Langertha::Holmgang::Report>s, which
hold only what was measured (ADR 0006): per topic, never one share over all
cases; an overall value only as the mean of the topics; case weights
(cluster size / representatives); curves per length tier with hits,
C<context_exceeded> and errors apart, and the same per difficulty; the verdict
per suite against its threshold and its hard cases, with pass^k over the repetitions; the comparison
of targets as text, Markdown and JSON. Port of cai-platform's
C<Eval::Batch::by_topic> and C<Eval::Batch::verdicts>; the decisions are ADR
0008.

B<Rates.> Every rate is a weighted share over B<all> results, whatever their
status: a result that was not measured (C<no_vision>, C<context_exceeded>,
C<error>) is in the denominator and has not passed. The counters say why a rate
is low — each of the seven statuses is counted under its own name.

=head2 reports

Required. The L<Langertha::Holmgang::Report> objects to evaluate, as an array
reference; C<< report => $report >> is the same for one. They are joined with
L<Langertha::Holmgang::Report/merge> first, so a repetition found in two files
counts once and a conflict croaks.

=head2 thresholds

Optional. Per suite id the suite's C<threshold> as the loader reads it from
F<suite.yaml>: C<< { 'suite-id' => { pass_rate => 0.9, pass_k => 0.5 } } >>.
A report does not carry the threshold, so a suite missing here is judged
without one: by its hard cases, an unfinished run and whether anything was
measured (L</verdicts>).

=head2 topics

    # [ { target, variant, topic, suites => [ ids ], results, weight,
    #     counts => { <status> => n, … }, rate,
    #     tokens => { input, output, reasoning } }, … ]

Per row (target and variant, in the order they first appear) and topic (by
name): C<results> is the number of repetitions with a result, C<counts> counts
each of the seven statuses under its own name, C<weight> the sum of the case
weights over those results, C<rate> the weighted share of C<passed> among all
results (C<null> without results). Tokens are sums, C<null> when no repetition
had a value.

=head2 overall

    # [ { target, variant, topics, results, counts => { … }, rate }, … ]

Per row the B<mean of its topic rates> — never one share over all cases, so a
few hard cases do not drown in many easy ones. Topics without a rate do not
enter the mean; C<rate> is C<null> when none has one. C<results> and C<counts>
are plain sums over the topics.

=head2 tier_curves

    # [ { target, variant, topic, tier, results, weight, counts => { … },
    #     rate, context_exceeded_rate, error_rate }, … ]

The curve per length tier, per row and topic: tiers in the order C<16k>,
C<48k>, C<96k>, C<160k>, any other tier after them by its number. Hits
(C<rate>), C<context_exceeded> and C<error> are three weighted shares of the
same results, kept apart; C<counts> has all seven statuses. Cases without a
tier are not on a curve. The tag C<ctx-E<lt>NE<gt>k> is no tier (ADR 0008, k56).

=head2 difficulty_curves

    # [ { target, variant, topic, difficulty, results, weight, counts => { … },
    #     rate, context_exceeded_rate, error_rate }, … ]

The same curve per difficulty (k57): per row and topic, in the order
C<leicht>, C<mittel>, C<schwer>, any other value after them. Cases without a
difficulty (and reports written before the field) are not on a curve.

=head2 verdicts

    # [ { target, variant, suite_id, results, counts => { … }, passed, rate,
    #     pass_rate, k, pass_k, pass_any, pass_k_min,
    #     case_results => [ { case_id, passed, repetitions } ],
    #     hard_failed  => [ { case_id, forbidden_calls, repetitions } ],
    #     repetitions_error, unfinished => { status, error } | undef, ok }, … ]

The verdict per row and suite over all repetitions, in the order the runs
first appear. C<rate> is the weighted share of C<passed> among all results;
C<pass_rate> and C<pass_k_min> come from L</thresholds>.

Not C<ok> when C<rate> is below C<pass_rate> (or there is no result), when
C<pass_k> is below C<pass_k_min> (or there is no case), or when a hard case
(tag C<injection> or C<verbot>) had a forbidden call in any repetition —
whatever the rate. Never C<ok> either, with or without a threshold, when
C<unfinished> is set: the run's C<status> and C<error> when its status is not
C<complete> (C<cancelled>, C<aborted>), so its results are a partial state
even if all of them passed. Nor is it C<ok>, with or without a threshold,
when the suite measured nothing: C<repetitions_error> equals C<k>. Without a
threshold the hard cases, C<unfinished> and that decide.

C<repetitions_error> is the number of repetitions (of C<k>) in which no case
has a result other than C<error>, none at all included: the target was not
reached (401, 429, timeout, connection refused) and nothing was measured.
C<context_exceeded>, C<no_vision> and every other status count as reached, so
a suite all C<context_exceeded> is a measurement and can be C<ok>. When every
repetition measured nothing the verdict is not C<ok>; when some did and at
least one was measured, it is reported and noted in the text but does not
decide C<ok> (ADR 0008, k73 amendment; cai-platform's C<runs_error> decides
for any count). C<ok> false with C<repetitions_error> equal to C<k> is what
the text shows as C<NOT MEASURED>.

B<Reliability:> C<k> is the run's C<repeat>; C<pass_k> is the weighted share
of cases passed in all C<k> repetitions, C<pass_any> (pass@k) of those passed in
at least one — over the cases with at least one result, C<null> without any.
Only C<passed> counts as passed: a repetition that is missing (a cancelled run)
or ended C<error>, C<context_exceeded>, C<no_vision>, C<turn_limit> or
C<uncertain> has not passed. C<case_results> lists per case in how many
repetitions it passed and how many it has.

=head2 comparison

    # { topics => [ names ], rows => [ { target, variant, rates => { topic => rate }, overall } ] }

The comparison table: a row per target and variant, a column per topic, the
cell the topic's C<rate>, and C<overall> the mean of the row's topics. A topic
a row did not run is absent from its C<rates>.

=head2 as_data

The whole evaluation as a plain hash: C<holmgang_evaluation> (the format
version, ADR 0008), L</topics>, L</overall>, L</tier_curves>,
L</difficulty_curves>, L</verdicts>,
L</comparison>.

=head2 to_json

L</as_data> as canonical UTF-8 JSON bytes; the same reports give the same bytes.

=head2 to_text

    print $evaluation->to_text;

The comparison table, the verdicts (with a note for an unfinished run, for
repetitions without a measurement and for each hard case that failed one),
when any case has a tier the tier curves, and when any case has a difficulty
the difficulty curves — as aligned plain-text tables.
Rates as percentages, C<-> for none. A verdict reads C<ok>, C<NOT MEASURED>
when the suite measured nothing (whatever else failed it; the notes say the
rest), or C<NOT PASSED>.

=head2 to_markdown

The same tables as L</to_text>, as Markdown pipe tables under C<###> headings;
hard-case notes follow the verdict table as a list, each naming its target,
variant and suite.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Holmgang::Report>

=back

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
