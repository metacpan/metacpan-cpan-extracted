package HTTP::Recorder::Httperf::Logger;
use base 'HTTP::Recorder::Logger';
use strict;
use warnings;


$HTTP::Recorder::Httperf::Logger::VERSION = '0.01';
#just override the 'Log' method.
sub Log 
{
  my ($self, $line) = @_;
  my $scriptfile = $self->{'file'};
  open (SCRIPT, ">>$scriptfile") or die "Couldn't open $scriptfile: $!";
  print SCRIPT $line;
  close SCRIPT or die "Couldn't close $scriptfile";
}


1;

