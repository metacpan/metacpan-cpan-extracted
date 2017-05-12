package Linux::CPUAffinity;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

require XSLoader;
XSLoader::load('Linux::CPUAffinity', $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Linux::CPUAffinity - set and get a process's CPU affinity mask

=head1 SYNOPSIS

  use Linux::CPUAffinity;

  # get affinity of this process
  my $cpus = Linux::CPUAffinity->get(0); # eg: [0, 1, 2, 3]
  # other process
  my $cpus = Linux::CPUAffinity->get($pid);

  # set affinity of this process
  Linux::CPUAffinity->set(0 => [0,1]);
  # other process
  Linux::CPUAffinity->set($pid => [0]);

  # utility method to get processors
  my $num = Linux::CPUAffinity->num_processors();

=head1 DESCRIPTION

Linux::CPUAffinity is a wrapper module for Linux system call sched_getaffinity(2) and sched_setaffinity(2).

This module is only available on GNU/Linux.

=head1 METHODS

=over 4

=item $cpus = $class->get($pid)

Get the CPU affinity mask of the process.

=item $class->set($pid, $cpus :ArrayRef[Int])

Set the CPU affinity mask of the process.

=item $num = $class->num_processors()

Get the number of processors currently online (available).

=back

=head1 LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=head1 SEE ALSO

L<Sys::CpuAffinity>

=cut
