use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover::Gcov ();

sub slurp { my $f = File::Spec->catfile(qw(t fixtures gcov gcc), shift); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

my $reader = Devel::XSCover::Gcov->new(dir => 'xt/spike', silent => 1, conditions => 1);
my $spike  = $reader->parse(slurp('Spike.gcov.txt'));
ok(exists $spike->{'Spike.xs'} && exists $spike->{'xs/more.xs'} && exists $spike->{'include/spike.h'} && exists $spike->{'Spike.c'}, 'the dist files of the Spike object, as gcc 14 names them');
ok((grep { m{/inline\.h$} } keys %$spike), 'and perl\'s inline.h by its absolute path');

my $xs = $spike->{'Spike.xs'};
is($xs->{lines}{27}, 800002, 'the add line counted in full under gcc 14, with the thread test plain');
is($xs->{lines}{55}, 0, 'case 2 never run reads zero from #####');
is_deeply([ grep { $_->{line} == 36 } @{ $xs->{blocks} } ], [ { line => 36, arms => [2, 1] }, { line => 36, arms => [1, 1] } ], 'if (a && b): two blocks of two arms, the (fallthrough) note dropped');
my ($switch) = grep { $_->{line} == 47 } @{ $xs->{blocks} };
is(scalar @{ $switch->{arms} }, 5, 'the switch is one block of five arms');
is(scalar(grep { $_ == 0 } @{ $switch->{arms} }), 1, 'one of which was never taken');
is_deeply([ grep { $_->{line} == 36 } @{ $xs->{conditions} } ], [ { line => 36, covered => 4, total => 4, terms => [ { true => 1, false => 1 }, { true => 1, false => 1 } ] } ], 'the && decision: two terms, every outcome decided the result');
is_deeply([ grep { $_->{line} == 95 } @{ $xs->{conditions} } ], [ { line => 95, covered => 1, total => 2, terms => [ { true => 0, false => 1 } ] } ], 'the guard: its true outcome never decided the result');
is_deeply([ grep { $_->{line} == 10 } @{ $xs->{conditions} } ], [ { line => 10, covered => 2, total => 2, terms => [ { true => 1, false => 1 } ] } ], 'if (x > 10): one term, both outcomes');
is_deeply($xs->{functions}, [ { name => 'only_from_one', line => 8, count => 2 } ], 'the C helper on its line');

my $h = $spike->{'include/spike.h'};
is_deeply($h->{conditions}, [ { line => 6, covered => 1, total => 2, terms => [ { true => 1, false => 0 } ] } ], 'the inline function\'s if, from the Spike object: x < 0 was only ever true');
my $helper = $reader->parse(slurp('helper.gcov.txt'));
is_deeply($helper->{'include/spike.h'}{conditions}, [ { line => 6, covered => 1, total => 2, terms => [ { true => 0, false => 1 } ] } ], 'and from the helper object only ever false, which the merge will join');
my ($hs) = grep { $_->{line} == 5 } @{ $helper->{'src/helper.c'}{blocks} };
is(scalar @{ $hs->{arms} }, 4, 'the helper switch, four arms');

done_testing;
