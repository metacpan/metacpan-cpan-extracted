package Devel::ebug::Backend::Plugin::StackTrace;
$Devel::ebug::Backend::Plugin::StackTrace::VERSION = '0.59';
use strict;
use warnings;
use Devel::StackTrace;

sub register_commands {
    return ( stack_trace => { sub => \&stack_trace } );

}

sub stack_trace {
  my($req, $context) = @_;
  my $trace = Devel::StackTrace->new;
  my @frames = $trace->frames;
  # remove our internal frames
  shift @frames;
  shift @frames;
  shift @frames;
  return { stack_trace => \@frames };
}


1;
