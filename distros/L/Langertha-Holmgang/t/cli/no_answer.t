#!/usr/bin/env perl
# holmgang run when the target answers no case (k42): exit 1 and a note on stderr
# when every result is error, context_exceeded or no_vision -- over the whole run,
# a note per suite next to measured ones; the report as always. A suite whose
# results are all error measured nothing: its verdict is not ok (NOT MEASURED),
# so run and report exit 1 by the verdicts; all context_exceeded or no_vision is
# a measurement and gets only the note (k73). Constructor warnings of the engine
# reach stderr without a Perl location. Scripted Langertha::Engine::Virtual and
# test engines only; invented suites (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();
use Path::Tiny qw( path );

use Holmgang::CLI qw( cli good_suite threshold_suite );
use Holmgang::SuiteDir qw( suite_dir );
use Langertha::Holmgang::Report;

my $root    = Path::Tiny->tempdir;
my $good    = good_suite( id => 'na-fan', root => $root );
my $other   = good_suite( id => 'na-other', root => $root );
my $gated   = threshold_suite( id => 'na-gated', root => $root );
my $out_dir = Path::Tiny->tempdir;
my $JSON    = JSON::MaybeXS->new( canonical => 1 );

my $FAIL    = { error => { status => 401, message => 'invalid credentials' } };
my $CONTEXT = { error => { status => 400, message => 'This model\'s maximum context length is 8192 tokens' } };
my $VISION  = { error => { status => 400, message => 'image input is not supported - hint: provide the mmproj' } };
my @SOLVE   = ( { tool_calls => [ [ fan_set => { level => 'high' } ] ] }, { answer => 'done' } );

sub script { '--option', 'script='.$JSON->encode( [@_] ) }

sub statuses {
  my ( $file ) = @_;
  my $r = Langertha::Holmgang::Report->read("$file");
  return [ map { [ map { map { $_->{status} } @{ $_->{repetitions} } } @{ $_->{cases} } ] } @{ $r->runs } ];
}

my $NOTE = qr/^holmgang: no case got an answer from the target\b/m;

{
  my $file = $out_dir->child('error.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $good, '--target', 'Virtual', script( ($FAIL) x 2 ),
    '--repeat', 2, '--report', "$file" );
  is( $code, 1, 'every result error: exit 1' );
  like( $err, $NOTE, '... said on stderr' );
  like( $err, qr/\b2 error\b/, '... with the count per status' );
  unlike( $err, qr/ line \d+|\.p[ml]\b/, '... without a Perl location' );
  like( $out, qr/^na-fan c1 #1 error$/m, '... the per-case lines as always' );
  like( $out, qr/^Comparison by topic/m, '... and the evaluation' );
  ok( -f $file, 'the report is written still' );
  is_deeply( statuses($file), [ [qw( error error )] ], '... with both results' );
  is( Langertha::Holmgang::Report->read("$file")->runs->[0]{status}, 'complete', '... the run complete, as before' );
  like( $out, qr/^virtual\s+default\s+na-fan\s.*NOT MEASURED$/m, '... the verdict says nothing was measured (k73)' );

  # report reads the same file: the verdict, not the k42 rule of run, gives exit 1 (k73)
  my $rout;
  ( $code, $rout, $err ) = cli( report => "$file" );
  is( $code, 1, 'report of a run that measured nothing, no threshold: exit 1 (k73; was exit 0)' ) or diag $rout;
  like( $rout, qr/^virtual\s+default\s+na-fan\s+0\/2\s.*\sNOT MEASURED$/m, '... the verdict NOT MEASURED' );
  like( $rout, qr/^  no result but error in 2 of 2 repetition\(s\): nothing measured$/m, '... with the note' );
  is( $err, '', '... and nothing on stderr: report has no no-answer note' );
  ( $code, $rout ) = cli( report => "$file", '--format', 'markdown' );
  is( $code, 1, '... markdown: exit 1' );
  like( $rout, qr/^\| virtual \| default \| na-fan \| 0\/2 \|.* \| NOT MEASURED \|$/m, '... NOT MEASURED' );
  ( $code, $rout ) = cli( report => "$file", '--format', 'json' );
  is( $code, 1, '... json: exit 1' );
  my $v = JSON::MaybeXS->new->decode($rout)->{verdicts}[0];
  is_deeply( [ @{$v}{qw( k repetitions_error )}, $v->{ok} ? 1 : 0 ], [ 2, 2, 0 ],
    '... ok false with repetitions_error == k says it, no new field' );
}

{
  my $file = $out_dir->child('context.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $good, '--target', 'Virtual', script( $CONTEXT, $VISION ), '--repeat', 2,
    '--report', "$file" );
  is( $code, 1, 'only context_exceeded and no_vision: exit 1' );
  like( $err, $NOTE, '... said' );
  like( $err, qr/\b1 context_exceeded\b/, '... context_exceeded counted' );
  like( $err, qr/\b1 no_vision\b/, '... no_vision counted' );
  like( $out, qr/^virtual\s+default\s+na-fan\s.*\sok$/m, '... by the k42 rule of run, not the verdict: that is ok, a measurement (k73)' );
  ( $code ) = cli( report => "$file" );
  is( $code, 0, 'report of it, no threshold: exit 0, the verdicts decide and the k42 rule is run\'s only' );
}

{
  # one measured result among errors: the verdicts decide as before
  my $file = $out_dir->child('mixed.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $good, '--target', 'Virtual', script( $FAIL, @SOLVE ),
    '--repeat', 2, '--report', "$file" );
  is( $code, 0, 'one passed result next to an error, no threshold: exit 0' ) or diag $err;
  unlike( $err, qr/no case got an answer/, '... no note' );
  is_deeply( statuses($file), [ [qw( error passed )] ], '... error, then passed' );
  like( $out, qr/^virtual\s+default\s+na-fan\s.*\sok$/m, '... one repetition measured: the verdict ok (k42 partial, k73)' );
  is( ( cli( report => "$file" ) )[0], 0, '... report of it: exit 0 as well' );

  ( $code, $out, $err ) = cli( run => '--suite', $gated, '--target', 'Virtual', script( $FAIL, @SOLVE ), '--repeat', 2 );
  is( $code, 1, 'the same against a threshold it misses: exit 1 by the verdict' );
  like( $out, qr/na-gated .*NOT PASSED/, '... the verdict says so' );
  unlike( $err, qr/no case got an answer/, '... not the no-answer note' );

  # a measured failure counts as an answer: the target answered, the case failed
  ( $code, undef, $err ) = cli( run => '--suite', $good, '--target', 'mock-text' );
  is( $code, 0, 'mock-text, every result failed, no threshold: exit 0 as before' );
  unlike( $err, qr/no case got an answer/, '... failed is measured, no note' );
}

{
  # several suites: judged over the run, a note per suite that got no answer
  my $file = $out_dir->child('two.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $good, '--suite', $other, '--target', 'Virtual',
    script( $FAIL, @SOLVE ), '--report', "$file" );
  # flipped on purpose (k73): the exit still comes from the verdicts, but the
  # suite all error now fails its verdict -- k42 claimed exit 0 here
  is( $code, 1, 'one suite all error next to a measured one: exit 1 by its verdict (k73)' ) or diag $err;
  like( $out, qr/^virtual\s+default\s+na-fan\s.*NOT MEASURED$/m, '... the verdict NOT MEASURED' );
  like( $out, qr/^virtual\s+default\s+na-other\s.*\sok$/m, '... the measured suite ok' );
  like( $err, qr/^holmgang: suite na-fan: no case got an answer from the target \(1 error\)$/m,
    '... a note for the suite without an answer' );
  unlike( $err, qr/na-other/, '... none for the measured one' );
  unlike( $err, $NOTE, '... and no note for the run' );
  is_deeply( statuses($file), [ ['error'], ['passed'] ], '... both in the report' );
  is( ( cli( report => "$file" ) )[0], 1, '... report of it: exit 1 as well (k73)' );

  # all context_exceeded is a measurement: next to a measured suite only the note
  ( $code, $out, $err ) = cli( run => '--suite', $good, '--suite', $other, '--target', 'Virtual', script( $CONTEXT, @SOLVE ) );
  is( $code, 0, 'one suite all context_exceeded next to a measured one: exit 0 by the verdicts (k73)' ) or diag $err;
  like( $out, qr/^virtual\s+default\s+na-fan\s.*\sok$/m, '... its verdict ok' );
  like( $err, qr/^holmgang: suite na-fan: no case got an answer from the target \(1 context_exceeded\)$/m,
    '... the note for it, as before' );

  ( $code, undef, $err ) = cli( run => '--suite', $good, '--suite', $other, '--target', 'Virtual', script( ($FAIL) x 2 ) );
  is( $code, 1, 'two suites, no answer in either: exit 1' );
  like( $err, $NOTE, '... the note for the run' );
  like( $err, qr/\b2 error\b/, '... counted over both' );
  unlike( $err, qr/^holmgang: suite /m, '... no note per suite on top' );
}

{
  # an empty suite never reaches the run: the loader refuses it (no cases), exit 2
  my $empty = suite_dir( id => 'na-empty', root => $root, cases => {} );
  my ( $code, undef, $err ) = cli( run => '--suite', $empty, '--target', 'mock-solution' );
  is( $code, 2, 'a suite without cases: exit 2, it does not load' );
  like( $err, qr/^holmgang: suite \Q$empty\E does not load: cases: no cases$/m, '... said' );
}

{
  # an aborted run stays exit 2, whatever it measured
  my ( $code ) = cli( run => '--suite', $good, '--target', 'Holmgang::BrokenEngine', script(@SOLVE) );
  is( $code, 2, 'an aborted run: exit 2, not 1' );
}

{
  # the engine's constructor warning: on stderr, without a Perl location
  my ( $code, undef, $err ) = cli( run => '--suite', $good, '--target', 'Holmgang::WarnEngine', script(@SOLVE) );
  is( $code, 0, 'an engine that warns while it is built: the run goes on' ) or diag $err;
  like( $err, qr/^holmgang: temperature 0\.7 is not supported by this model, using 1$/m, '... the warning on stderr' );
  unlike( $err, qr/ line \d+|\.p[ml]\b|<\$fh>/, '... without the location or the handle line' );
}

{
  # the run note quotes the first error text (k44): scrubbed as Target scrubs it,
  # on one line, cut to 200 characters with an ellipsis; the counts stay
  require Holmgang::LongFailEngine;
  no warnings 'once';
  local $Holmgang::LongFailEngine::N = 0;
  my $key = $Holmgang::LongFailEngine::KEY;
  my ( $code, undef, $err ) = cli( run => '--suite', $good, '--suite', $other, '--target', 'Holmgang::LongFailEngine',
    '--repeat', 2 );
  is( $code, 1, 'a long multi-line error everywhere: exit 1' );
  my @notes = grep { /no case got an answer/ } split /\n/, $err;
  is( scalar @notes, 1, '... one note line for the run' ) or diag $err;
  my ( $tally, $first ) = ( $notes[0] // '' ) =~ /\Aholmgang: no case got an answer from the target \(([^)]*)\); first: (.*)\z/;
  is( $tally, '4 error', '... the count per status still in it' );
  like( $first, qr/\AHTTP 401 Unauthorized \(request 1\): the key \*\*\* was refused POST /,
    '... the first error of the run, in suite, case and repetition order, its lines joined' );
  ok( length( $first // '' ) <= 202, '... cut to 200 characters, then a space and an ellipsis (got '.length( $first // '' ).')' );
  like( $first, qr/\S \x{2026}\z/, '... the cut shown by an ellipsis' );
  unlike( $err, qr/\Q$key\E/, 'the key is nowhere on stderr' );
  unlike( $err, qr{/home/someone|\.config/invented}, '... nor the host path' );
  unlike( $err, qr/ line \d+|\.p[ml]\b/, '... nor a Perl location' );
}

{
  # a short error is quoted whole, without an ellipsis; the first one, not the second
  my $SECOND = { error => { status => 401, message => 'second refusal' } };
  my ( $code, undef, $err ) = cli( run => '--suite', $good, '--target', 'Virtual', script( $FAIL, $SECOND ), '--repeat', 2 );
  is( $code, 1, 'two different errors: exit 1' );
  like( $err, qr/^holmgang: no case got an answer from the target \(2 error\); first: [^\n]*invalid credentials$/m,
    '... the first one quoted whole, no ellipsis' );
  unlike( $err, qr/second refusal/, '... not the second' );
}

done_testing;
