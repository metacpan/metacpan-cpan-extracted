use strict;
use warnings;

use Test::More;
use Time::HiRes qw(gettimeofday tv_interval);

use Digest::Adler32::XS;

my $eval_result = eval {
    require Digest::Adler32;
};

if (! $eval_result) {
    plan skip_all => 'Benchmark test requires Digest::Adler32 to be installed';
}

sub test_adler32 {
    my ($adler) = @_;
    
    my $string = join('', ('AA' .. 'ZZ')) x 10;
    for(my $i = 0; $i < 2000; $i++) {
        $adler->add($string);
    }
    return $adler->digest();
}

my $at0 = [gettimeofday];
my $aresult = test_adler32(Digest::Adler32->new());
my $atd = tv_interval ($at0, [gettimeofday]);

ok($atd, "Benchmark run for Digest::Adler32 at $atd seconds");

my $bt0 = [gettimeofday];
my $bresult = test_adler32(Digest::Adler32::XS->new());
my $btd = tv_interval ($bt0, [gettimeofday]);

ok($btd, "Benchmark run for Digest::Adler32::XS at $btd seconds");
is($bresult, $aresult, "Same result");

diag(sprintf("Digest::Adler32::XS benchmarked %0.2f times faster", (1.0 / ($btd / $atd))));

done_testing();

1;