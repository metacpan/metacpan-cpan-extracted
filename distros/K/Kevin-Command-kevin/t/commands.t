use Mojo::Base -strict;

use Test::More;

{
# worker
  require Kevin::Command::kevin::worker;
  my $cmd = Kevin::Command::kevin::worker->new;
  ok $cmd->description, 'has a description';
  like $cmd->usage, qr/worker/, 'has usage information';
}

{
# jobs
  require Kevin::Command::kevin::jobs;
  my $cmd = Kevin::Command::kevin::jobs->new;
  ok $cmd ->description, 'has a description';
  like $cmd ->usage, qr/jobs/, 'has usage information';
}

{
# workers
  require Kevin::Command::kevin::workers;
  my $cmd = Kevin::Command::kevin::workers->new;
  ok $cmd ->description, 'has a description';
  like $cmd ->usage, qr/workers/, 'has usage information';
}

done_testing();
