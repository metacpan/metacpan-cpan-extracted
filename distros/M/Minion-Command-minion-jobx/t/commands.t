use Mojo::Base -strict;
 
use Test::More;
 
# job
require Minion::Command::minion::jobx;
my $job = Minion::Command::minion::jobx->new;
ok $job->description, 'has a description';
like $job->usage, qr/job/, 'has usage information';

done_testing();
