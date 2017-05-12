use strict;
use warnings;
use lib 'lib';
use Forward::Routes;
use Benchmark qw(:all) ;


#############################################################################
### basic test

my $r = Forward::Routes->new->add_route('hallo');
$r->add_route('foo/:bar')->name('test');



warn $r->build_path('test', bar => 'there')->{path};

my $count = 100000;
my $t = timeit($count, sub {
    $r->build_path('test', bar => 'there')->{path};
});
print "$count loops of other code took:",timestr($t),"\n";