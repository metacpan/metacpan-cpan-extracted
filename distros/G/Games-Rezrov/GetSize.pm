#
#  Try as hard as we can to guess the number of rows and columns
#  in the display.
#
#  Use a "nice" approach if available, wallow if we must.
#  Michael Edmonson 10/1/98
#

package Games::Rezrov::GetSize;

use strict;
use Exporter;

@Games::Rezrov::GetSize::ISA = qw(Exporter);
@Games::Rezrov::GetSize::EXPORT = qw(get_size);

$Games::Rezrov::GetSize::DEBUG = 0;

eval 'use Term::ReadKey';
if (!$@) {
  #
  # use Term::ReadKey
  # 
  print STDERR "term::readkey\n" if $Games::Rezrov::GetSize::DEBUG;

  eval << 'DONE'
  sub get_size {
    my @terminal = GetTerminalSize();
    return @terminal ? ($terminal[0], $terminal[1]) : undef;
  }
DONE
} elsif ($ENV{"COLUMNS"} and $ENV{"ROWS"}) {
  #
  # use environment variables
  #
  print STDERR "environment vars\n" if $Games::Rezrov::GetSize::DEBUG;
  eval << 'DONE'
    sub get_size {
      return ($ENV{"COLUMNS"}, $ENV{"ROWS"});
    }
DONE
} else {
    foreach ("/bin/", "/usr/bin/") {
      my $fn = $_ . "/stty";
      $Games::Rezrov::GetSize::stty_prog = $fn, last if -x $fn;
    }
    if ($Games::Rezrov::GetSize::stty_prog) {
      #
      # use stty
      #
      print STDERR "stty\n" if $Games::Rezrov::GetSize::DEBUG;
      eval << 'DONE'
	sub get_size {
	  my ($columns, $rows);
	  my $data = `$Games::Rezrov::GetSize::stty_prog -a`;
	  foreach (["rows", \$rows],
		   ["columns", \$columns]) {
	    my ($what, $ref) = @{$_};
	    if ($data =~ /$what\s+=*\s*(\d+)/) {
	      $$ref = $1;
	    } elsif ($data =~ /(\d+)\s+$what/) {
	      $$ref = $1;
	    }
	  }
	  return ($columns, $rows);
	}
DONE
      } else {
      #
      # give up
      #
      print STDERR "giving up\n" if $Games::Rezrov::GetSize::DEBUG;
      eval << 'DONE'
	sub get_size {
	  return undef;
	}
DONE
      }
    }


1;
