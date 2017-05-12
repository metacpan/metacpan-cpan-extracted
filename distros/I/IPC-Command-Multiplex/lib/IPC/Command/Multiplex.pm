package IPC::Command::Multiplex;

use strict;
use warnings FATAL => 'all';
use 5.008001;
use Exporter qw(import);

our @EXPORT = qw(multiplex);

use POE qw(Wheel::Run);

our $VERSION = '0.008001';

sub multiplex {
  my %args = @_;
  my %kids;
  POE::Session->create(
    inline_states => {
      _start => sub {
        foreach my $cmd (@{$args{run}}) {
          my $kid = POE::Wheel::Run->new(
            Program => $cmd,
            StdoutEvent => 'stdout_line',
          );
          $_[KERNEL]->sig_child($kid->PID, 'child_signal');
          $kids{$kid->PID} = $kid;
        }
      },
      stdout_line => sub {
        $args{callback}->($_[ARG0]);
      },
      child_signal => sub { delete $kids{$_[ARG1]} },
    }
  );
  POE::Kernel->run;
}

=head1 NAME

IPC::Command::Multiplex - run commands in parallel

=head1 SYNOPSIS

  multiplex(
    run => [
      [ 'command1', 'arg1', 'arg2', 'arg3' ],
      [ 'command2', 'arg1', 'arg2', 'arg3' ],
      ...
    ],
    callback => sub {
      chomp(my $line = shift);
      # do something with $line here
    }
  );

=head1 DESCRIPTION

A simple way to run multiple commands (forking for each one) and get each
line returned from them to a callback as they get sent.

Useful for aggregating log analysis and similar.

Currently using POE - this should be considered an implementation detail and
may change - if this detail "leaks", i.e. you have to care about it when
using this module, please file a bug.

Yes, this code is horribly new and could do with lots more examples. Try it
out, email to complain, or send me some!

=head1 AUTHOR

Matt S Trout (mst) - <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None as yet. Maybe this module is perfect ... (insert laughter here)

=head1 COPYRIGHT

(c) 2010 the IPC::Command::Multiplex L</AUTHOR> and L</CONTRIBUTORS> as
listed above

=head1 LICENSE

This library is free software under the same terms as perl itself

=cut

1;
