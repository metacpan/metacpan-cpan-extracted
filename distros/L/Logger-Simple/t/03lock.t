use Test::More;
use Logger::Simple;

if($^O eq "MSWin32"){
  plan( skip_all => 'File Locking not working on MS Windows' );
}else{
  plan (tests => 2);
  $logfile="t/logfile3";
  $logger=Logger::Simple->new(LOG=>$logfile);

  $logger->lock;
  ok(-e ".LS.lock",'Lock file created');

  $logger->unlock;
  ok(!-e ".LS.lock",'Lock file destroyed');

  undef $logger;

  if($^O eq 'MSWin32'){
    system "C:\\Windows\\System32\\cmd.exe \/c del t\\logfile3";
  }else{ 
    unlink $logfile;
  }
}

