use Kelp::Base -strict;
use Kelp;
use Test::More;

my $app = Kelp->new;
can_ok $app, $_ for qw/redis/;
isa_ok $app->redis, 'Redis';

done_testing;
