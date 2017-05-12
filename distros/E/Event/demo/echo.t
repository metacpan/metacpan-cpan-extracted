#!./perl -w

$| = 1;
use Event qw(time);
require Event::io;

print "This demo echoes whatever you type.  If you don't type anything
for as long as 2.5 seconds then it will complain.  Enter an empty line
to exit.

";

my $recent = time;
Event->io(fd      => \*STDIN,
          timeout => 2.5,
          poll    => "r",
          repeat  => 1,
          cb      => sub {
	      my $e = shift;
	      my $got = $e->got;
              #print scalar(localtime), " ";
	      if ($got eq "r") {
		  sysread(STDIN, $buf, 80);
		  chop $buf;
		  my $len = length($buf);
		  Event::unloop if !$len;
		  print "read[$len]:$buf:\n";
		  $recent = time;
	      } else {
		  print "nothing for ".(time - $recent)." seconds\n";
	      }
          });

Event::loop();
