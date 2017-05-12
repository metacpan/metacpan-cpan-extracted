package GRID::Cluster::Handle;

use strict;
use warnings;

use GRID::Machine;
use GRID::Cluster::Handle;
use IO::Select;

# Constructor
sub new {
  my $class = shift;

  my %opts = @_;

  my $self = \%opts;

  bless $self, $class;
  return $self;
}

# Getters

sub get_readset {
  my $self = shift;
  return $self->{readset} if defined($self->{readset});
}

sub get_proc {
  my $self = shift;
  return $self->{proc} if defined($self->{proc});
}

sub get_rproc {
  my $self = shift;
  return $self->{rproc} if defined($self->{rproc});
}

sub get_wproc {
  my $self = shift;
  return $self->{wproc} if defined($self->{wproc});
}

sub get_pid {
  my $self = shift;
  return $self->{pid} if defined($self->{pid});
}

sub get_id {
  my $self = shift;
  return $self->{id} if defined($self->{id});
}

sub get_map_id_machine {
  my $self = shift;
  return $self->{map_id_machine} if defined($self->{map_id_machine});
}

1;

__END__

=head1 NAME

GRID::Cluster::Handle - The object that manages C<GRID::Cluster> unidirectional and bidirectional pipes

=head1 DESCRIPTION

The result of a call to the methods C<open> or C<open2> of L<GRID::Cluster> is a reference to a 
C<GRID::Cluster::Handle> object. This kind of object manages C<GRID::Cluster> unidirectional
and bidirectional pipes used during the execution of remote commands.

A C<GRID::Cluster::Handle> object has the following attributes:

=over

=item *

I<readset>

A reference to a L<IO::Select> object. It contains the handles to make reading operations over the
pipes.

=item *

I<proc>

A reference to a list that contains the reading handles of a pipe. This attribute is only used by
the methods C<open> and C<close>.

=item *

I<rproc>

A reference to a list that contains the reading handles of a pipe. This attribute is only used by
the methods C<open2> and C<close2>.

=item *

I<wproc>

A reference to a list that contains the writing handles of a pipe. This attribute is only used by
the methods C<open2> and C<close2>.

=item *

I<pid>

A reference to a list that contains the PIDs of the processes that have been opened.

=item *

I<id>

A reference to a hash. The keys are unique identificators of every pipe reading handle. The values
are numbers that identify every reading handle.

=item *

I<map_id_machine>

A reference to a hash. The keys are the C<id> numbers of the reading handles. The values are the names
of every machine.

=back

=head1 METHODS

=head2 The Constructor C<new>

Syntax:
  
  my $cluster_handles = GRID::Cluster::Handle->new (
    readset        => $readset,
    rproc          => \@rproc,
    wproc          => \@wproc,
    pid            => \@pid,
    id             => \%id,
    map_id_machine => \%map_id_machine
  );

In the case of using the methods C<open2> and C<close2>.

  my $cluster_handles = GRID::Cluster::Handle->new (
    readset        => $readset,
    proc           => \@proc,
    pid            => \@pid,
    id             => \%id,
    map_id_machine => \%map_id_machine
  );

In the case of using the methods C<open> and C<close>.

=head1 SEE ALSO

=over 2

=item * L<GRID::Cluster>

=item * L<GRID::Cluster::Tutorial>

=item * L<GRID::Machine>

=item * L<IPC::PerlSSH>

=item * L<http://www.openssh.com>

=item * L<http://www.csm.ornl.gov/torc/C3/>

=item * Man pages of C<ssh>, C<ssh-key-gen>, C<ssh_config>, C<scp>,
C<ssh-agent>, C<ssh-add>, C<sshd>

=back

=head1 AUTHORS

Eduardo Segredo Gonzalez E<lt>esegredo@ull.esE<gt> and
Casiano Rodriguez Leon E<lt>casiano@ull.esE<gt>

=head1 AKNOWLEDGEMENTS

This work has been supported by the EC (FEDER) and
the Spanish Ministry of Science and Innovation inside the 'Plan
Nacional de I+D+i' with the contract number TIN2008-06491-C04-02.

Also, it has been supported by the Canary Government project number
PI2007/015.

The work of Eduardo Segredo was funded by grant FPU-AP2009-0457.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Casiano Rodriguez Leon and Eduardo Segredo Gonzalez.
All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
