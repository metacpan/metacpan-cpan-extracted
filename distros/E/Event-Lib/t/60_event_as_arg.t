# Objective:
# ----------
#
# Check that events can be used as additional arguments 
# for other events.

use IO::Socket;
use Event::Lib;
use Test;

BEGIN {
    plan tests => 4;
}

my $PATH = "t/sock-$$";

unless (fork) {
      sleep 1;
      my $real_client = IO::Socket::UNIX->new(Peer => $PATH) or die $@;
      $real_client->autoflush(1);
      $real_client->write("foobar");
      sleep 1;
      $real_client->write("foobar:");
}
else {
      my $sock = IO::Socket::UNIX->new(
		      Local => $PATH,
                      Listen => 1,
                  ) or die "$!";

      $sock->listen() or die $!;

      {
	    my $e = event_new($sock, EV_READ, \&handle_incoming);
	    $e->add();
	    event_mainloop();
	    wait;
      }

      sub handle_incoming {
          $client = $sock->accept() or die $!;
          event_new($client, EV_READ, \&do_readcolon)->add();
	  ok(1);
      }

      sub do_readcolon {
          my ($e, $e_type) = @_;
          my $read = sysread($e->fh, my $buf, 1024);
          $buf =~ s/\r?\n//g;
          unless ($buf =~ /:/) {
              my $t = timer_new(\&_handle_event, $e);
              $t->add(1);
	      ok(1);
          }
          else {
              $e->fh->close();
	      ok(1);
	      unlink $PATH or die $!;
	      exit;
          }
      }

      sub _handle_event {
          my ($e, $e_type, $io_event) = @_;
          $io_event->add();
	  ok(1);
      }
}
