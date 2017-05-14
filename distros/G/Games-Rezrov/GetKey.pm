package Games::Rezrov::GetKey;
#  Try as hard as we can to read a single key from the keyboard.
#  Use a "nice" approach if available, wallow if we must.
#  Michael Edmonson 9/29/98
#
#  POSIX code taken from Tom Christiansen's "HotKey.pm", see
#  perlfaq8, or <6k403m$r1l$9@csnews.cs.colorado.edu>
#
#  TO DO: add DOS and other OS-specific code if Term::ReadKey not available

use strict;
use Exporter;

@Games::Rezrov::GetKey::ISA = qw(Exporter);
@Games::Rezrov::GetKey::EXPORT = qw(get_key);

use constant DEBUG => 0;

$Games::Rezrov::GetKey::STTY = "";

my $CAN_READ_SINGLE = 1;

sub can_read_single {
  return $CAN_READ_SINGLE;
}

eval 'use Term::ReadKey';
if (!$@) {
  #
  # use Term::ReadKey
  # 
  print STDERR "term::readkey\n" if DEBUG;
  eval << 'DONE'
  sub get_key {
    ReadMode(3);
    my $z;
    read(STDIN, $z, 1);
    ReadMode(0);
    return $z;
  }

  sub END {
    ReadMode(0);
  }
DONE

} else {
    my $posix_ok = 0;
   eval 'use POSIX qw(:termios_h)';
   if (!$@) { 
       eval 'my $term = POSIX::Termios->new();';
       if ($@) {
         # we have the POSIX module but Termios doesn't work!
#	 die "aha";
       } else {
         $posix_ok = 1;
       } 
   } 

   if ($posix_ok) {
    #
    # use POSIX termios
    # 
    print STDERR "posix\n" if DEBUG;

    eval << 'DONE'

    my $fd_stdin = fileno(STDIN);
    my $term = POSIX::Termios->new();
    $term->getattr($fd_stdin);
    my $oterm     = $term->getlflag();
    my $echo     = ECHO | ECHOK | ICANON;
    my $noecho   = $oterm & ~$echo;

    sub cbreak {
      $term->setlflag($noecho);
      $term->setcc(VTIME, 1);
      $term->setattr($fd_stdin, TCSANOW);
    }
    
    sub cooked {
      $term->setlflag($oterm);
      $term->setcc(VTIME, 0);
      $term->setattr($fd_stdin, TCSANOW);
    }

    sub get_key {
      my $key = '';
      cbreak();
      sysread(STDIN, $key, 1);
      cooked();
      return $key;
    }

    sub END {
      cooked();
    }
DONE
  } else {
    #
    #  Ugh, hopefully it won't come to this :)
    # 
      my $prog;
    foreach ("/bin/", "/usr/bin/") {
      my $fn = $_ . "stty";
      $Games::Rezrov::GetKey::STTY = $fn, last if -x $fn;
    }
    
    if ($Games::Rezrov::GetKey::STTY) {
      # use stty program
      print STDERR "stty\n" if DEBUG;
      
      eval << 'DONE'
	sub get_key {
	  my $z;
	  system "$Games::Rezrov::GetKey::STTY -icanon -echo";
	  read(STDIN, $z, 1);
	  system "$Games::Rezrov::GetKey::STTY icanon echo";
	  return $z;
	}
	
	sub END {
	  system "$Games::Rezrov::GetKey::STTY icanon echo";
	}
DONE
      } else {
	$CAN_READ_SINGLE = 0;
	print STDERR "giving up" if DEBUG;
	eval << 'DONE'
	  sub get_key {
	    my $z;
	    read(STDIN, $z, 1);
	    return $z;
	  }
DONE
	}
      }
  }


1;


