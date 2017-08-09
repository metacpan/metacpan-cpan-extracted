use Mojo::Base -strict;

use Test::More;

# worker
require Kevin::Command::kevin::worker;
my $worker = Kevin::Command::kevin::worker->new;
ok $worker->description, 'has a description';
like $worker->usage, qr/worker/, 'has usage information';

done_testing();
