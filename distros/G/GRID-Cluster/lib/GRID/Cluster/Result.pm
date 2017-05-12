package GRID::Cluster::Result;

use GRID::Machine::MakeAccessors;
use GRID::Machine::Message;
use GRID::Machine::Result;
use overload q("") => 'str',
             bool  => 'allfirstok';

# Constructor
sub new {

  my $class = shift;

  my $self = {};

  bless $self, $class;
  return $self;
}

# Adds a new GRID::Machine::Result object to a GRID::Cluster::Result object
sub add {

  my $self = shift;
  my %args = @_;

  my $host_name = $args{host_name} if defined($args{host_name});
  my $machine_result = $args{machine_result} if defined($args{machine_result});

  $self->{$host_name} = $machine_result;

}

# Methods

# This method returns a reference to a list of trues or falses,
# depending on there were / weren't errors during executions
sub result {
  my $self = shift;

  return [ map { $self->{$_}->result } keys %{$self} ];
}

# This method returns true if all the values of the list returned by
# the method "results" are true.
# This method is used for overloading the bool operator
sub allfirstok {
  my $self = shift;

  my @results = @{$self->result};

  my @falses = grep { !$_ } @results;

  return !@falses;
}

# This method is used for overloading the q("") operator
sub str {
  my $self = shift;
  
  my $string = "";
  my @host_names = keys %{$self};

  foreach (@host_names) {
    $string .= "$_: ".$self->{$_}->str."\n";
  }

  return $string;
}


1;

__END__

=head1 NAME

GRID::Cluster::Result - The object managing the result of a L<GRID::Cluster> remote command execution

=head1 DESCRIPTION

The result of a call to a remote command, for example using methods C<copyandmake> or C<chdir>
of L<GRID::Cluster>, is a reference to a L<GRID::Cluster::Result> object. This kind of object is
responsible for obtaining the results for each machine that is part of a C<GRID::Cluster> object.

These results allow to identify which machines has finished the execution of a remote command
satisfactorily, and in which ones a failure has occurred.

A C<GRID::Cluster::Result> object contains, mainly, a hash with keys the names of the different
machines and values the corresponding L<GRID::Machine::Result> objects.

=head1 METHODS

=head2 The Constructor C<new>

Syntax:

  my $r = GRID::Cluster::Result->new();

It builds a new result object. No parameters are required.

=head2 The method C<add>

Syntax:

  $r->add(
    host_name      => $_,
    machine_result => $machine_result
  );

This method adds a C<GRID::Machine::Result> object to an existing C<GRID::Cluster::Result>
object. The parameters are:

=over

=item * 

C<host_name>: A string containing the name of a machine.

=item *

C<machine_result>: A reference to a C<GRID::Machine::Result> object.

=back

=head2 The method C<result>

This method returns a reference to a list of trues or falses, depending on
there were / weren't errors during the execution of a remote command in
every machine.

=head2 The method C<allfirstok>

This method returns true if all the values of the list returned by the method
C<result> are true. Moreover, this method is used to overload the operator
bool.

=head2 The method C<str>

This method returns the string made of concatenating stdout, stderr and errmsg of
every machine. The resulting string of calling this method looks like:

  host1:
  host2: file not found
  host3:

Furthermore, this method is used to overload the Perl operator q(""). Thus,
wherever a C<GRID::Cluster::Result> object is used on a scalar string
context the method C<str> will be called.

=head1 SEE ALSO

=over 2

=item * L<GRID::Cluster>

=item * L<GRID::Cluster::Tutorial>

=item * L<GRID::Machine>

=item * L<GRID::Machine::Result>

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
