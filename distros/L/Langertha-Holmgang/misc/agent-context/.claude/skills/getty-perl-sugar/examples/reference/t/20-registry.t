use strict;
use warnings;
use Test::More;
use Example::Sugar::Registry ();
my $count = 0;
my $code = sub { ++$count; return {ok=>1} };
my $add = \&Example::Sugar::Registry::register_step;
my $entries = \&Example::Sugar::Registry::entries;
$add->('Test::Owner', undef, 'First', 'first', $code);
is($count, 0, 'declaration does not execute body');
is(scalar @{$entries->('Test::Owner')}, 1, 'one declaration stored');
is($entries->('Test::Owner')->[0]{phase}, 'gather', 'default phase');
is_deeply($entries->('Test::Missing'), [], 'unknown owner is an empty bucket');
my @bad = (
  ['duplicate', qr/Duplicate/, ['Test::Owner', undef, 'Again', 'first', $code]],
  ['owner', qr/owner/, ['bad owner', undef, 'Bad', 'a', $code]],
  ['key', qr/key/, ['Test::Owner', undef, 'Bad', 'bad key', $code]],
  ['label', qr/label/, ['Test::Owner', undef, '', 'a', $code]],
  ['body', qr/coderef/, ['Test::Owner', undef, 'Bad', 'a', undef]],
  ['odd', qr/Odd/, ['Test::Owner', undef, 'Bad', 'a', $code, 'phase']],
  ['unknown option', qr/Unknown/, ['Test::Owner', undef, 'Bad', 'a', $code, typo=>1]],
  ['duplicate option', qr/Repeated option/, ['Test::Owner', undef, 'Bad', 'a', $code, phase=>'gather', phase=>'render']],
  ['phase', qr/Unknown phase/, ['Test::Owner', undef, 'Bad', 'a', $code, phase=>'launch']],
  ['requires type', qr/arrayref/, ['Test::Owner', undef, 'Bad', 'a', $code, requires=>'first']],
  ['repeated dep', qr/Repeated dependency/, ['Test::Owner', undef, 'Bad', 'a', $code, requires=>[qw(first first)]]],
  ['self dep', qr/itself/, ['Test::Owner', undef, 'Bad', 'a', $code, requires=>['a']]],
  ['dep key', qr/Invalid dependency/, ['Test::Owner', undef, 'Bad', 'a', $code, requires=>[undef]]],
  ['revision', qr/revision/, ['Test::Owner', undef, 'Bad', 'a', $code, revision=>'']],
  ['predicate expression', qr/not an expression/, ['Test::Owner', 'tier eq pro', 'Bad', 'a', $code]],
  ['predicate array', qr/Unsupported/, ['Test::Owner', [], 'Bad', 'a', $code]],
  ['empty predicate map', qr/empty predicate/, ['Test::Owner', {}, 'Bad', 'a', $code]],
  ['nested predicate value', qr/scalars/, ['Test::Owner', {a=>[]}, 'Bad', 'a', $code]],
);
for my $case (@bad) {
  eval { $add->(@{$case->[2]}); 1 };
  like($@, $case->[1], "reject $case->[0]");
  is(scalar @{$entries->('Test::Owner')}, 1, 'rejection does not commit a declaration');
}
my $deps = ['first'];
my $pred = {tier=>'pro'};
$add->('Test::Owner', $pred, 'Second', 'second', $code, requires=>$deps);
$deps->[0] = 'mutated'; $pred->{tier} = 'other';
my $copy = $entries->('Test::Owner');
is($copy->[1]{requires}[0], 'first', 'registration copies dependency array');
is($copy->[1]{predicate}{tier}, 'pro', 'registration copies predicate map');
$copy->[1]{requires}[0] = 'edited';
$copy->[1]{predicate}{tier} = 'edited';
is($entries->('Test::Owner')->[1]{requires}[0], 'first', 'lookup cannot mutate dependency registry');
is($entries->('Test::Owner')->[1]{predicate}{tier}, 'pro', 'lookup cannot mutate predicate registry');
Example::Sugar::Registry::seal_owner('Test::Owner');
eval { $add->('Test::Owner', undef, 'Third', 'third', $code) };
like($@, qr/sealed/, 'explicit seal rejects later declarations');
done_testing;
