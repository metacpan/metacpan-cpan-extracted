package t::TestUtils;

use strict;
use warnings;
use Config;
use Test::More;
use Env qw( HARNESS_ACTIVE );

BEGIN {
  use ExtUtils::MakeMaker qw( prompt );
  use base qw( Exporter );
  our @EXPORT  = qw{
      skip_interactive
      skip_old_perl
      skip_no_file_which
      skip_no_tty
      skip_not_in_path
      is_no
      is_yes
      perl_exe
      perl_path
      prompt
   };
}

sub skip_interactive {
  skip "!! Run 'perl -Mblib test.pl interactive' to perform interactive tests/demonstrations of the module's abilities.", 1 if $HARNESS_ACTIVE;
}

sub skip_old_perl {
  skip "Layers requires Perl 5.8.0 or better.", 1 if $] < 5.008;
}

sub skip_no_file_which {
  skip "This test requires File::Which.", 1 if not eval { require File::Which };
}

sub skip_no_tty {
  skip "/dev/tty cannot be opened.", 1 if not open(my $fh, '<', '/dev/tty');
  close $fh;
}

sub skip_not_in_path {
  # Test that the specified executable can be found in the PATH environment
  # variable using File::Which.
  my $exe = shift; 
  my $loc = File::Which::which($exe);
  skip "Executable '$exe' is not in PATH.", 1 if not defined $loc;
}

sub is_yes {
  my ($val) = @_;
  return ($val =~ /^y(?:es)?/i || $val eq '');
}

sub is_no {
  my ($val) = @_;
  return ($val =~ /^n(?:o)?/i || $val eq '');
}

sub perl_exe {
  # Find the Perl executable name
  my $this_perl = $^X;
  $this_perl = (File::Spec->splitpath( $this_perl ))[-1];
  return $this_perl;
}

sub perl_path {
  # Find the Perl full-path (taken from the perlvar documentation)
  my $this_perl = $^X;
  if ($^O ne 'VMS') {
    $this_perl .= $Config{_exe}
    unless $this_perl =~ m/$Config{_exe}$/i;
  }
  return $this_perl;
}

1;
