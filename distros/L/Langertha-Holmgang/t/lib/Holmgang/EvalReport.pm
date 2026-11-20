package Holmgang::EvalReport;
# Test helper for the evaluation tests: invented reports from a compact spec
# (ADR 0003 — no real case, no real target).
use strict;
use warnings;
use Exporter qw( import );

use Langertha::Holmgang::Report;
use Langertha::Holmgang::Evaluation;

our @EXPORT_OK = qw( report evaluation );

# report( { target, variant, suite, topic, repeat, status, error, cases => [ id | { id, weight, tier, difficulty, tags, hard } ],
#           results => [ [ case, repetition, status, forbidden_calls?, input_tokens? ], … ] }, … )
sub report {
  my ( @runs ) = @_;
  my $r = Langertha::Holmgang::Report->new( started_at => '2026-11-04T10:00:00Z' );
  for my $run ( @runs ) {
    my %case_seen;
    my @cases = map { ref $_ ? $_ : { id => $_ } } @{ $run->{cases} || [] };
    # cases named only in results join the run in order of first mention
    for my $res ( @{ $run->{results} || [] } ) {
      push @cases, { id => $res->[0] } unless grep { $_->{id} eq $res->[0] } @cases;
    }
    my $repeat = $run->{repeat};
    unless ( $repeat ) {
      $repeat = 1;
      $_->[1] > $repeat and $repeat = $_->[1] for @{ $run->{results} || [] };
    }
    $r->add_run(
      target  => { label => $run->{target} // 'mock-a', engine => 'Virtual', model => 'mock-1', url => undef },
      variant => { name => exists $run->{variant} ? $run->{variant} : 'plain', settings => {} },
      suite   => { id => $run->{suite} // 's', version => '1',
                   topic => exists $run->{topic} ? $run->{topic} : 'netz', digest => 'd' },
      repeat  => $repeat,
      status  => $run->{status} // 'complete',
      error   => $run->{error},
      cases   => [ map { {
        case_id => $_->{id}, title => 'T '.$_->{id}, tags => $_->{tags} // [],
        tier    => $_->{tier}, difficulty => $_->{difficulty}, weight => exists $_->{weight} ? $_->{weight} : 1,
        hard    => $_->{hard}, untrusted => 0,
        ( defined $_->{scenario} ? ( scenario => $_->{scenario} ) : () ),
      } } @cases ],
      results => [ map { my ( $c, $n, $st, $fc, $in ) = @$_; {
        case_id => $c, repetition => $n, status => $st, forbidden_calls => $fc // 0,
        turns   => defined $in ? [ { input_tokens => $in, output_tokens => 1, calls => 0 } ] : [],
      } } @{ $run->{results} || [] } ],
    );
  }
  return $r->finish('2026-11-04T11:00:00Z');
}

sub evaluation {
  my ( $runs, %arg ) = @_;
  return Langertha::Holmgang::Evaluation->new( report => report(@$runs), %arg );
}

1;
