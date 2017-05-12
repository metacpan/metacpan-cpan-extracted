use Test::More tests=>4; 
use Logger::Simple;

my $logfile="t/logfile2";

my $log=Logger::Simple->new(LOG=>$logfile);

$log->write("Test");
ok(-s $logfile,'Writing to logfile');

my $MSG=$log->retrieve_history;
ok($MSG eq "Test");

$log->write("Test2");
$log->write("Test3");

my @Msg=$log->retrieve_history;
ok(scalar @Msg == 3);

$log->clear_history;
my @Msg2=$log->retrieve_history;
ok(scalar @Msg2 == 0);

undef $log;

if($^O eq 'MSWin32'){
  system "C:\\Windows\\System32\\cmd.exe \/c del t\\logfile2";
}else{ 
  unlink $logfile;
}

