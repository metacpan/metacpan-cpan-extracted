use Mojo::Base -strict;
use Test::More;

use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';

my $tmpdir = tempdir CLEANUP => 1, EXLOCK => 0;
my $file = catfile $tmpdir, 'minion.data';

# job command
require Minion::Command::minion::job;
my $jc = Minion::Command::minion::job->new;
$jc->app->plugin(Minion => {Storable => $file});

my $minion = $jc->app->minion;
$minion->reset;

# run job command
my $id = $jc->run('--enqueue', 'foo', '--args', '[23, "bar"]');
my $batch = $minion->backend->list_jobs(0, 10);
is $batch->[0]{task}, 'foo', 'right task';

my @w;
local $SIG{__WARN__} = sub { push @w, shift };
is $jc->run, $id, 'right job id';
ok !scalar(@w), 'no warnings' or diag "Got warning: $w[0]";

# Clean up once we are done
$minion->reset;
done_testing();
