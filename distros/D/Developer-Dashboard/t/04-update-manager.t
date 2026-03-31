use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::UpdateManager;

my $repo = getcwd();
local $ENV{HOME} = tempdir(CLEANUP => 1);

my $paths = Developer::Dashboard::PathRegistry->new;
my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);
my $collector = Developer::Dashboard::Collector->new(paths => $paths);
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector,
    files      => $files,
    paths      => $paths,
);
my $updater = Developer::Dashboard::UpdateManager->new(
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);

chdir $repo or die $!;
my $result = $updater->run;
ok(ref($result) eq 'ARRAY', 'update returns array of step results');
ok(@$result >= 3, 'all update steps executed');

ok(-f $files->global_config, 'global config written');
ok(-f $paths->dashboards_root . '/welcome', 'welcome page written');
ok(-f $paths->config_root . '/shell/bashrc.sh', 'shell bootstrap written');

done_testing;

__END__

=head1 NAME

04-update-manager.t - update manager tests

=head1 DESCRIPTION

This test verifies update script execution and runtime bootstrap behavior.

=cut
