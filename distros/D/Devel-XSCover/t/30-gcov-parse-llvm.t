use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover::Gcov ();

sub slurp { my $f = File::Spec->catfile(qw(t fixtures gcov llvm), shift); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

my $reader = Devel::XSCover::Gcov->new(dir => 'xt/spike', silent => 1);
my $spike  = $reader->parse(slurp('Spike.gcov.txt'));

is_deeply([sort keys %$spike], [
    '/opt/homebrew/opt/perl/lib/perl5/5.42/darwin-thread-multi-2level/CORE/inline.h',
    '/opt/homebrew/opt/perl/lib/perl5/5.42/darwin-thread-multi-2level/CORE/sv_inline.h',
    'Spike.c', 'Spike.xs', 'include/spike.h', 'xs/more.xs',
], 'the six sources of the Spike object, as gcov names them');

my $xs = $spike->{'Spike.xs'};
is(scalar keys %{ $xs->{lines} }, 26, '26 executable lines in Spike.xs');
is($xs->{lines}{27}, 353062, 'the add line');
is($xs->{lines}{10}, 2, 'the if in the static helper');
is($xs->{lines}{55}, 0, 'case 2, never run, is zero');
ok(!exists $xs->{lines}{48}, 'a case label is not executable');
ok(!exists $xs->{lines}{1}, 'nor an include line');

is_deeply([ grep { $_->{line} == 36 } @{ $xs->{blocks} } ],
    [ { line => 36, arms => [2, 1] }, { line => 36, arms => [1, 1] } ],
    'if (a && b) is two blocks of two arms on one line');
is_deeply([ grep { $_->{line} == 47 } @{ $xs->{blocks} } ],
    [ { line => 47, arms => [1, 1, 1, 0, 1] } ],
    'the switch is one block of five arms');
is_deeply([ grep { $_->{line} == 95 } @{ $xs->{blocks} } ],
    [ { line => 95, arms => [1, 0] } ],
    'the guard is one block, its second arm never taken');
is_deeply($xs->{functions}, [ { name => 'only_from_one', line => 8, count => 2 } ],
    'the one plain C function in the xs, on its declaration line');

my $c = $spike->{'Spike.c'};
my %fn = map { $_->{name} => $_ } @{ $c->{functions} };
is($fn{XS_Spike_add}{count}, 353062, 'the add wrapper count');
is($fn{XS_Spike__More_exit_only}{count}, 0, 'the _exit child wrote nothing');
is($fn{boot_Spike}{count}, 5, 'boot once per process');
is(scalar @{ $c->{functions} }, 12, 'eleven wrappers and the boot');
ok(!exists $c->{lines}{193}, 'a body line mapped to the xs is not counted in the c');

my $more = $spike->{'xs/more.xs'};
is_deeply($more->{lines}, { 7 => 1, 15 => 1, 23 => 0, 31 => 0 }, 'the included xs: triple, child_only, exit_only, never');

my $h = $spike->{'include/spike.h'};
is_deeply($h->{lines}, { 4 => 1, 6 => 1, 7 => 1, 8 => 1 }, 'the header from the Spike object: spike_square only');
is_deeply($h->{functions}, [ { name => 'spike_square', line => 4, count => 1 } ], 'one inline function instantiated');

my $helper = $reader->parse(slurp('helper.gcov.txt'));
is_deeply([sort keys %$helper], ['include/spike.h', 'src/helper.c'], 'the helper object: two sources');
is_deeply($helper->{'src/helper.c'}{blocks}, [ { line => 5, arms => [1, 1, 1, 0] } ], 'its switch, four arms');
is_deeply($helper->{'include/spike.h'}{lines}, { 4 => 1, 6 => 1, 7 => 0, 8 => 1, 11 => 1, 13 => 1 },
    'the header from the helper object: both functions, a different line set and a different count on line 7');
is_deeply([ map { $_->{name} } @{ $helper->{'include/spike.h'}{functions} } ], [qw(spike_square spike_only_helper)], 'both inline functions');

done_testing;
