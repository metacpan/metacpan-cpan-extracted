#!/usr/bin/env perl
# Acceptance 3 (CONTEXT.md, k20): a real suite written by hand in the case DSL
# (ADR 0007) loads and gives what its format 2 original gives. Runs only against
# copies kept outside this checkout (ADR 0003): HOLMGANG_ACCEPTANCE_DSL is a search
# directory of DSL suites (<id>/suite.pl), HOLMGANG_ACCEPTANCE_SUITES the search
# directories of the format 2 originals (as in acceptance_load.t). Skips without
# both. Nothing of the cases is printed -- test names carry suite and case ids only.
#
# Claims, per DSL suite and its original of the same id:
#  (a) the DSL suite loads, lint and both mock runs of every case included;
#  (b) the loaded structure equals the original case by case: the suite head,
#      every case key of the structure, the initial state, what the model is
#      sent, the derived values and the effective settings;
#  (c) the mock runs of every case (reference solution, text only) give
#      identical results, sent requests included;
#  (d) `holmgang export-yaml` of the DSL suite writes format 2 that loads, has
#      the DSL suite's digest and gives identical mock results again.
# The digest of the DSL suite differs from the original's by design: it is the
# digest of its export (ADR 0007 amendment k19), not of the original's files.
use strict;
use warnings;
use Test::More;

use Path::Tiny qw( path );
use Langertha::Holmgang::CLI;
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Structure;
use Langertha::Holmgang::Target;

my $dsl   = $ENV{HOLMGANG_ACCEPTANCE_DSL};
my $roots = $ENV{HOLMGANG_ACCEPTANCE_SUITES};
plan skip_all => 'set HOLMGANG_ACCEPTANCE_DSL (DSL suites) and HOLMGANG_ACCEPTANCE_SUITES (their format 2 originals)'
  unless $dsl && $roots;

my $loader = Langertha::Holmgang::Loader->new;
my @dirs = sort grep { -f $_->child('suite.pl') } path($dsl)->children;
ok( scalar @dirs, 'DSL suites found' );

my @HEAD    = qw( id version title description license source topic threshold repeat defaults tools );
my @DERIVED = qw( tier effective_weight is_hard has_untrusted has_images no_tool );

# Deep equality as is_deeply sees it (texts by eq, undef only equals undef),
# without is_deeply's diagnostics: those would print case content.
sub same {
  my ( $x, $y ) = @_;
  return !defined $y if !defined $x;
  return 0 if !defined $y || ref $x ne ref $y;
  if ( ref $x eq 'HASH' ) {
    return 0 unless join( "\0", sort keys %$x ) eq join( "\0", sort keys %$y );
    same( $x->{$_}, $y->{$_} ) || return 0 for keys %$x;
    return 1;
  }
  if ( ref $x eq 'ARRAY' ) {
    return 0 unless @$x == @$y;
    same( $x->[$_], $y->[$_] ) || return 0 for 0 .. $#$x;
    return 1;
  }
  return same( $$x, $$y ) if ref $x eq 'SCALAR' || ref $x eq 'REF';
  return "$x" eq "$y";
}

sub refused {
  my ( $err ) = @_;
  return diag( 'refused'.( ref $err && $err->can('field') ? ' at '.$err->field : '' ) );
}

# what a mock run of a case gives, the requests it sent included
sub mock {
  my ( $case, $mode ) = @_;
  my $e   = Langertha::Holmgang::Runner->mock_engine( $case, $mode );
  my $res = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e ) )->run_case($case);
  return {
    ( map { $_ => $res->{$_} } qw( status score error rules diff sim_gaps forbidden_calls injection_held calls answer state transcript ) ),
    requests => $e->requests,
  };
}

sub same_runs {
  my ( $got, $want, $what ) = @_;
  for my $i ( 0 .. $#{ $want->cases } ) {
    my ( $cg, $cw ) = ( $got->cases->[$i], $want->cases->[$i] );
    for my $mode (qw( solution text )) {
      ok( same( mock( $cg, $mode ), mock( $cw, $mode ) ), $cw->id.": mock $mode run identical ($what)" );
    }
  }
}

for my $dir ( @dirs ) {
  my $id = $dir->basename;
  subtest $id => sub {
    # (a)
    my $p = eval { $loader->load( $dir->stringify ) };
    ok( $p, '(a) the DSL suite loads, lint green' ) or return refused($@);
    my $ydir = eval { $loader->locate( $roots, $id ) };
    ok( $ydir, 'the format 2 original found' ) or return;
    my $y = $loader->load($ydir);

    # (b)
    ok( same( { map { $_ => $p->$_ } @HEAD }, { map { $_ => $y->$_ } @HEAD }), '(b) suite head identical' );
    ok( same( [ map { $_->id } @{ $p->cases } ], [ map { $_->id } @{ $y->cases } ]), '(b) same cases in the same order' );
    isnt( $p->digest, $y->digest, 'digests differ: the DSL digest is its export\'s (k19)' );
    for my $i ( 0 .. $#{ $y->cases } ) {
      my ( $cy, $cp ) = ( $y->cases->[$i], $p->cases->[$i] );
      my $cid = $cy->id;
      ok( same( $cp->$_, $cy->$_ ), "(b) $cid: $_ identical" ) for @Langertha::Holmgang::Structure::CASE_KEYS;
      ok( same( $cp->initial_state,   $cy->initial_state ), "(b) $cid: initial state identical" );
      ok( same( $cp->prompt_messages, $cy->prompt_messages ), "(b) $cid: what the model is sent identical" );
      ok( same( [ map { $cp->$_ } @DERIVED ], [ map { $cy->$_ } @DERIVED ] ), "(b) $cid: derived values identical" );
      ok( same( [ map { $cp->effective($_) } qw( system temperature max_tokens max_turns ) ],
        [ map { $cy->effective($_) } qw( system temperature max_tokens max_turns ) ] ), "(b) $cid: effective settings identical" );
    }

    # (c)
    same_runs( $p, $y, '(c) DSL against the original' );

    # (d)
    my $out = Path::Tiny->tempdir;
    my ( $o, $e ) = ( '', '' );
    open my $oh, '>:encoding(UTF-8)', \$o or die;
    open my $eh, '>:encoding(UTF-8)', \$e or die;
    my $code = Langertha::Holmgang::CLI->new( out => $oh, err => $eh, loader => $loader )
      ->run( 'export-yaml', $dir->stringify, '--out', $out->stringify );
    is( $code, 0, '(d) holmgang export-yaml exits 0' );
    my $x = eval { $loader->load( $out->child($id)->stringify ) };
    ok( $x, '(d) the export loads, lint green' ) or return refused($@);
    ok( -f $out->child( $id, 'suite.yaml' ), '(d) ... as format 2' );
    is( $x->digest, $p->digest, '(d) the export has the DSL suite\'s digest' );
    ok( same( [ map { $_->id } @{ $x->cases } ], [ map { $_->id } @{ $y->cases } ]), '(d) same cases in the same order' );
    same_runs( $x, $y, '(d) export against the original' );
  };
}

done_testing;
