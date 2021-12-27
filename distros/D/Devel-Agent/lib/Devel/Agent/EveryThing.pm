package Devel::Trace::EveryThing;

=head1 NAME

Devel::Trace::EveryThing

=head1 SYNOPSIS

  perl -d:Agent -MDevel::Trace::EveryThing myscript.pl

=head1 DESCRIPTION

This is a module that makes use of the agent debugger and writes the begining and ending of every frame to STDERR.

This module is similar to L<Devel::Trace>, but makes use of the L<Devel::Agent> deugger.  This allows for tracing how long each method runs for and providing a noted stack depth along with of the execution order.

=head1 Notes and limitations

This class does not trace entry int control structures, just execution of Non-XS methods.

=cut

use Modern::Perl;
use Devel::Agent;
our $VERSION=$Devel::Agent::VERSION;
use Data::Dumper;

STDERR->autoflush(1);
my $last=0;
my $self;

my $pending={};
sub flush_row {
  my ($self,$frame)=@_;
  my $depth=$frame->{depth};
  if($last==0 || $depth > $last +1) {
    # we jumpped some frames.
    my $frames=$self->grab_missing($last,$frame);
    foreach my $frame ($frames->@*) {
      print_frame($frame,$last);
    }
  }
  
  print_frame($frame,$last);
  $last=$frame->{depth};
}

sub print_frame {
  my $frame=shift;
  my $last=shift;
  my $depth=($frame->{depth} -1) *2;
  
  my $format;
  if(exists $frame->{duration}) {
    frame_start($depth,$frame) unless delete $pending->{$frame->{depth}};
    printf STDERR "\%${depth}s%s Depth: %i End Frame:   \%i Line: File: \%s %i Duration: %f\n",'',@{$frame}{qw(class_method depth order_id source line duration)};
  } else {
    $pending->{$frame->{depth}}=1;
    frame_start($depth,$frame);
  }
}

sub frame_start{
  my ($depth,$frame)=@_;
  printf STDERR "\%${depth}s\%s Depth: %i Start Frame: \%i File: \%s Line: \%i\n",'',@{$frame}{qw(class_method depth order_id source line)};
}
$self=DB->new(
  on_frame_end=>\&flush_row,
); 
$self->start_trace;
# it starts but never stops


END {
  # hun, turns out we needed this!
  $self->stop_trace;
}

1;

__END__

=head1 AUTHOR

Michael Shipper L<mailto:AKALINUX@CPAN.ORG>

=cut

