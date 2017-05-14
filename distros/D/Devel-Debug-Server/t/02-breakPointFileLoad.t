use Test::More tests=> 6;

use strict;
use warnings;
no warnings 'once';
use FindBin;
use lib "$FindBin::Bin/../lib";
use Proc::Background;
use Time::HiRes qw(usleep nanosleep);
use_ok("Devel::Debug::Server::Client");

#with option "-debugAgentProcess" another command window will open for the process to debug
my $cmdArg = $ARGV[0] || '';
my $cmdArgValue = $ARGV[1] ||undef;

my $processToDebugPID = undef;
my $processToDebugOption = 0;
if ( $cmdArg eq '-debugAgentProcess'){
    $processToDebugOption = 1;
}

my $debugServerCommand = "perl -I$FindBin::Bin/../lib $FindBin::Bin/../bin/debugServer.pl";
my $processCommand = "perl -I$FindBin::Bin/../lib $FindBin::Bin/../bin/debugAgent.pl $FindBin::Bin/load_calc.pl"; 


my $procServer = Proc::Background->new({'die_upon_destroy' => 1},$debugServerCommand);
my $processToDebug = Proc::Background->new({'die_upon_destroy' => 1},$processCommand);

sleep 1; #wait for processes to start

ok($procServer->alive(), "debug server is running");
ok($processToDebug->alive(), "process to debug is running");

sleep 1; #wait for processes to register to debug server

my $debugData = Devel::Debug::Server::Client::refreshData();

my @processesIDs = keys %{$debugData->{processesInfo}};

$processToDebugPID = $processesIDs[0];

my $modulePath = "$FindBin::Bin/Calc.pm";
my $processInfos = $debugData->{processesInfo}{$processToDebugPID};
$debugData = Devel::Debug::Server::Client::breakPoint($modulePath,11);

$debugData = waitMilliSecondAndRefreshData(300);
 $processInfos = $debugData->{processesInfo}{$processToDebugPID};
is_deeply($debugData->{effectiveBreakpoints},{},"Breakpoint requested on a not yet loaded file can't be set for now.");

#launch again the process and wait for breakPoint to be reach
$debugData = Devel::Debug::Server::Client::run($processToDebugPID);

$debugData = waitMilliSecondAndRefreshData(300);

 $processInfos = $debugData->{processesInfo}{$processToDebugPID};
$processInfos = $debugData->{processesInfo}{$processToDebugPID};
is($processInfos->{fileName},$modulePath,"We are in the good file");
is($processInfos->{line},11,"We are on the good line of Calc.pm");

undef $processToDebug;

sub waitMilliSecondAndRefreshData{
    my ($timeToWaitMilliSec) = @_;

    usleep($timeToWaitMilliSec * 1000); #wait for breakPoint to be reach

    return Devel::Debug::Server::Client::refreshData();
}

1; #script completed !
