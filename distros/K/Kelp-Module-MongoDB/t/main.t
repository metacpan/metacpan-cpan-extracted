use Kelp::Base -strict;
use Kelp;
use Test::More;
 
my $app = Kelp->new;
can_ok $app, $_ for qw/mongodb/;
isa_ok $app->mongodb, 'MongoDB::MongoClient';
 
done_testing;
