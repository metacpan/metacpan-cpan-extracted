#!/usr/bin/env perl
# holmgang report: evaluates the files holmgang run wrote (mock targets only),
# per topic, as text, Markdown and JSON; thresholds from --suite. Invented suites
# only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();
use Path::Tiny qw( path );

use Holmgang::CLI qw( cli good_suite threshold_suite );

my $root  = Path::Tiny->tempdir;
my $good  = good_suite( id => 'rep-fan', root => $root );
my $gated = threshold_suite( id => 'rep-gated', root => $root );
my $dir   = Path::Tiny->tempdir;
my $replay = $dir->child('replay.json');
my $text   = $dir->child('text.json');
is( ( cli( run => '--suite', $good, '--target', 'mock-solution', '--report', "$replay" ) )[0], 0, 'setup: replay report' );
is( ( cli( run => '--suite', $gated, '--target', 'mock-text', '--report', "$text" ) )[0], 1, 'setup: text-only report' );

{
  my ( $code, $out, $err ) = cli( report => "$replay", "$text", '--by', 'topic' );
  is( $code, 0, 'without --suite no threshold: only hard cases decide, exit 0' ) or diag $err;
  like( $out, qr/^Comparison by topic/m, '... the comparison table' );
  like( $out, qr/^mock-solution\s+default\s+100\.0%/m, '... a row per target' );
  like( $out, qr/^mock-text\s+default\s+0\.0%/m, '... both files joined' );
  like( $out, qr/^Verdicts per suite/m, '... the verdicts' );
}

{
  my ( $code, $out ) = cli( report => "$replay", "$text", '--suite', $gated );
  is( $code, 1, 'with the suite\'s threshold the text-only verdict fails: exit 1' );
  like( $out, qr/rep-gated .*NOT PASSED/, '... and says so' );
}

{
  my ( $code, $out ) = cli( report => "$replay", '--format', 'markdown' );
  is( $code, 0, 'markdown: exit 0' );
  like( $out, qr/^### Comparison by topic/m, '... headings' );
  like( $out, qr/^\| mock-solution \| default \| 100\.0% \| 100\.0% \|$/m, '... pipe table' );
}

{
  my ( $code, $out ) = cli( report => "$replay", "$text", '--format', 'json' );
  is( $code, 0, 'json: exit 0' );
  my $d = JSON::MaybeXS->new->decode($out);
  is( $d->{holmgang_evaluation}, 1, '... the evaluation document' );
  is_deeply( [ sort map { $_->{target} } @{ $d->{comparison}{rows} } ], [qw( mock-solution mock-text )], '... both targets' );
}

{
  my $junk = $dir->child('junk.json');
  $junk->spew_utf8('{"not":"a report"}');
  my ( $code, undef, $err ) = cli( report => "$junk" );
  is( $code, 2, 'a file that is no report: exit 2' );
  like( $err, qr/does not read: .*not a Holmgang report/, '... said' );
  is( ( cli( report => "$dir/missing.json" ) )[0], 2, 'a missing file: exit 2' );
  is( ( cli('report') )[0], 2, 'no file: exit 2' );
  ( $code, undef, $err ) = cli( report => "$replay", '--by', 'tier' );
  is( $code, 2, '--by other than topic: exit 2' );
  like( $err, qr/per topic/, '... the evaluation is per topic' );
  is( ( cli( report => "$replay", '--format', 'html' ) )[0], 2, 'an unknown --format: exit 2' );
}

done_testing;
