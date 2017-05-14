package Games::Rezrov::ZIO_Tools;

use strict;
use Exporter;

@Games::Rezrov::ZIO_Tools::ISA = qw(Exporter);
@Games::Rezrov::ZIO_Tools::EXPORT = qw(set_xterm_title
			       find_module);

sub set_xterm_title {
  # if title is not defined, return whether or not the title *can* be
  # changed.
  my $title = shift;
  # see the comp.windows.x FAQ.
  if ($ENV{"DISPLAY"}) {
    # these are X-specific, so...
    my $term = $ENV{"TERM"};
    my $esc = pack 'c', 27;
    # escape

    if ($term =~ /xterm/i) {
      # XTerm
      if (defined $title) {
	printf "%s]2;%s%s", $esc, $title, pack('c', 7);  # bell
      } else {
	return 1;
      }
    } elsif ($term eq "vt300") {
      # DECTerm?
      if (defined $title) {
	printf '%s]21;%s%s\\', $esc, $title, $esc;
      } else {
	return 1;
      }
    }
  }

  return 0;
}

sub find_module {
  #
  #  Determine whether or not a given Perl module or library is installed
  #
  my $cmd = 'use ' . $_[0];
  eval $cmd;
  return $@ ? 0 : 1;
}

1;
