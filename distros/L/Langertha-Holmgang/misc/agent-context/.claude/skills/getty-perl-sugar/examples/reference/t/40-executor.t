use strict;
use warnings;
use Test::More;
use Example::Sugar::Registry ();
use Example::Sugar::Plan ();
use Example::Sugar::Executor ();
{
  package Test::ExecutionSubject;
  sub new { bless {deep=>0}, shift }
  sub deep { $_[0]{deep} }
  sub result { $_[0]{executor}->result($_[1]) }
}
my $add = \&Example::Sugar::Registry::register_step;
sub make_executor {
  my ($owner)=@_;
  my $subject=Test::ExecutionSubject->new;
  my $bound=Example::Sugar::Plan::bind(Example::Sugar::Plan::compile([$owner]),$subject);
  my $executor=Example::Sugar::Executor->new(plan=>$bound);
  $subject->{executor}=$executor;
  return ($executor,$subject);
}
my ($first_calls,$second_calls)=(0,0);
$add->('Test::Retry',undef,'One','one',sub {++$first_calls; {value=>0}});
$add->('Test::Retry',undef,'Two','two',sub {
  ++$second_calls;
  die "temporary\n" if $second_calls == 1;
  return {value=>$_[0]->result('one')->{value}+2};
}, requires=>['one']);
$add->('Test::Retry','deep','Skip','skip',sub { die 'must not run' });
my ($executor,$subject)=make_executor('Test::Retry');
eval { $executor->run($subject) };
like($@,qr/Step 'two' failed: temporary/,'body failure has step context');
is($executor->states->{two},'failed','failed state recorded');
is($executor->states->{skip},'skipped','predicate skip is separate state');
ok(!$executor->has_result('two'),'failed step has no completed result');
ok($executor->has_result('one'),'earlier successful result retained');
is($executor->result('one')->{value},0,'false-valued payload is a valid result');
my $result=$executor->run($subject);
is($first_calls,1,'same-instance rerun does not repeat successful step');
is($second_calls,2,'explicit rerun reattempts failed step');
is($result->{two}{value},2,'consumer can read producer');
is($executor->progress->{active_total},2,'progress counts active leaf steps');
is($executor->progress->{succeeded},2,'progress counts committed results');
is($executor->progress->{failed},0,'success clears failed state');
$result->{one}{value}=999;
is($executor->result('one')->{value},0,'public result snapshot is detached');
$executor->run($subject);
is($second_calls,2,'completed same-instance rerun is a no-op');
eval { $executor->result('missing') };
like($@,qr/unavailable/,'missing result is not silently undef');
eval { $executor->run(Test::ExecutionSubject->new) };
like($@,qr/another subject/,'executor rejects cross-subject reuse');
for my $case (
  ['Undefined', sub {undef}, qr/hashref/],
  ['Scalar', sub {42}, qr/hashref/],
  ['Array', sub {[]}, qr/hashref/],
  ['Code', sub {{bad=>sub {1}}}, qr/(?:CODE|encod)/i],
  ['Blessed', sub {bless {}, 'NotAResult'}, qr/hashref/],
) {
  my $owner="Test::Bad$case->[0]";
  $add->($owner,undef,'Bad','bad',$case->[1]);
  my ($e,$s)=make_executor($owner);
  eval {$e->run($s)};
  like($@,$case->[2],"reject $case->[0] result");
  ok(!$e->has_result('bad'),'invalid result never becomes completed');
}
$add->('Test::Reentrant',undef,'Reenter','again',sub {$_[0]{executor}->run($_[0]); {}});
my ($re,$rs)=make_executor('Test::Reentrant');
eval {$re->run($rs)};
like($@,qr/already running/,'reentrant executor invocation rejected');
$add->('Test::Empty',undef,'Empty','empty',sub { {} });
my ($ee,$es)=make_executor('Test::Empty');
$ee->run($es);
ok($ee->has_result('empty'),'empty hash result still means completed');
done_testing;
