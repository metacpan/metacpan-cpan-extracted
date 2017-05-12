use GRID::Machine;
use Data::Dumper;
my $host = $ENV{GRID_REMOTE_MACHINE};
my $debug = shift() ? 12344 : 0; 
my $machine = GRID::Machine->new(
  host => $host, 
  debug => $debug,
  uses => [ 'Sys::Hostname', 'POSIX qw(WNOHANG setsid)' ]);

# Install function 'rmap' on remote.machine
my $r = $machine->sub( 
  forky => q{
    SERVER->remotelog( "Starting Child");
    SERVER->remotelog("files before fork = ".qx{ls -ltr});
    #$| = 1;
    my $pid = fork();

    if ($pid) {
      SERVER->remotelog("Child started with pid $pid");
      SERVER->remotelog("files = ".qx{ls -ltr});

      open my $out, ">& STDOUT";
      open STDOUT, "> chuchi.txt";
      print "After fork. Father!\n";
      close(STDOUT);
      #kill 9, $pid;
      #wait;
      return 8;
    };

    setsid(); 
    open(STDIN, "</dev/null");
    open(STDOUT,">/dev/null");
    open(STDERR,">&STDOUT");

    open my $f, "> pi.txt" or die q{Can't open 'pi.txt'};;
    print $f scalar(localtime)."=> 3.1415\n";
    close($f);
    
    exit(0);
  },
);
die $r->errmsg unless $r->ok;

$r = $machine->forky();
print "lives\n";
print Dumper $r; # Dumps remote stdout and stderr

