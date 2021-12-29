package Devel::Agent::EveryThing;

=head1 NAME

Devel::Agent::EveryThing - Trace Eveything

=head1 SYNOPSIS

  perl -d:Agent -MDevel::Agent::EveryThing myscript.pl

=head1 DESCRIPTION

This is a module that makes use of the agent debugger and writes the begining and ending of every frame to STDERR.

This module is similar to L<Devel::Trace>, but makes use of the L<Devel::Agent> deugger.  This allows for tracing how long each method runs for and providing a noted stack depth along with of the execution order.

=head1 Notes and limitations

This class does not trace entry into control structures, just execution of Non-XS methods.

=cut

use Modern::Perl;
use Devel::Agent;
our $VERSION=$Devel::Agent::VERSION;
use Data::Dumper;
use Devel::Agent::Util qw(flush_row);

STDERR->autoflush(1);
my $last=0;
my $self;

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

