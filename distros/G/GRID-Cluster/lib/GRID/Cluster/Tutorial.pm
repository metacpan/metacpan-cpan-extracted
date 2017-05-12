__END__

=head1 NAME

GRID::Cluster::Tutorial - An introduction to parallel computing using components

=head1 SYNOPSIS

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 1
  Calculating Pi with 1000000000 iterations and 1 processes
  Elapsed Time: 56.591251 seconds
  Pi Value: 3.141593

  real    0m58.374s
  user    0m0.520s
  sys     0m0.048s

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 2
  Calculating Pi with 1000000000 iterations and 2 processes
  Elapsed Time: 28.459958 seconds
  Pi Value: 3.141592

  real    0m30.610s
  user    0m0.524s
  sys     0m0.056s

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 3
  Calculating Pi with 1000000000 iterations and 3 processes
  Elapsed Time: 20.956588 seconds
  Pi Value: 3.141594

  real    0m22.549s
  user    0m0.296s
  sys     0m0.068s

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 6
  Calculating Pi with 1000000000 iterations and 6 processes
  Elapsed Time: 15.694753 seconds
  Pi Value: 3.141594

  real    0m17.285s
  user    0m0.304s
  sys     0m0.104s

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 12
  Calculating Pi with 1000000000 iterations and 12 processes
  Elapsed Time: 13.246352 seconds
  Pi Value: 3.141588

  real    0m14.798s
  user    0m0.328s
  sys     0m0.116s

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 15
  Calculating Pi with 1000000000 iterations and 15 processes
  Elapsed Time: 12.924256 seconds
  Pi Value: 3.1416

  real    0m14.500s
  user    0m0.372s
  sys     0m0.108s

=head1 SUMMARY

Programming is difficult. Parallel programming is harder.
As a rule of thumb, 20% of the code is responsible for 80%
of the computing time.
As anyone working in High Performance Computing knows,
optimizing the computing time and optimizing programmer's time are
contradictory goals. Therefore, the Pareto Principle applies when
considering the total benefits of optimizing:
We must find a compromise between the efforts and costs
of the High Performance Computing component (HPC)
versus the High Performance Programming component (HPP).
Another spoke in the Parallel Computing wheel is the need
of staff for the set-up, administration and maintenance of the
available computer networks. These requirements make difficult the
exploitation of distributed systems, specially when several
organizations are engaged.

This work explores the convenience of using dynamic languages
(like Ruby, Perl or Python) as coordination languages for components
written using different HPC tools. The very high programming level
provided by these languages make feasible a 'zero administration'
setup of a cluster while the use of HPC languages contributes to
preserve highest levels of performance. Results show that the
overwhelming gain in programmer's time does not implies any loss
of performance.

=head1 REQUIREMENTS

To experiment with the examples in this tutorial
you will need at least two Unix machines with SSH, Perl and an
installation of the module C<GRID::Machine> from Casiano Rodriguez.
If you are not familiar with Perl or Linux this module probably
isn't for you.
If you are not familiar with SSH, see

=over 2

=item * I<SSH, The Secure Shell: The Definitive Guide> by Daniel J. Barrett
and Richard E. Silverman. O'Reilly

=item * L<http://www.openssh.com>

=item * Man pages of C<ssh>, C<ssh-key-gen>, C<ssh_config>, C<scp>,
C<ssh-agent>, C<ssh-add>, C<sshd>

=item * L<http://www.ssh.com>

=item * Linux Focus article L<http://tldp.org/linuxfocus/English/Archives/lf-2003_01-0278.pdf>
by Erdal Mutlu I<Automating system administration with ssh and scp>

=back

=head1 BUILDING A PARALLEL VIRTUAL MACHINE

SSH includes the ability to authenticate users using public keys. Instead of
authenticating the user with a password, the SSH server on the remote machine will
verify a challenge signed by the user's I<private key> against its copy
of the user's I<public key>. To achieve this automatic ssh-authentication
you have to:

=over 2

=item *

Configure each remote machine in a configuration file (I<man ssh_config>).
By default, the configuration file is $HOME/.ssh/config.
The basic syntax which this script needs is the following:

  Host host_1
  HostName myHost1.mydomain.com
  User myUser

  Host host_2
  HostName myHost2.mydomain.com
  User anotherUser
  .
  .
  .
  Host host_n
  HostName myHostn.mydomain.com
  User myUser

=item *

Run the script I<pki.pl> which is included in this distribution. This script allows
the generation of public/private key pairs, using the I<ssh-keygen> command.
Generated public key is copied to a list of remote machines. Specifically,
the public key is added, if not exist, in the file $HOME/.ssh/authorized_keys of
each remote machine.

The basic execution of the command is as follows:

  local.machine$ ./pki.pl [-v] -c host_1,host_2,...host_n

In this case, a public/private key pair is generated in the local directory $HOME/.ssh/,
using the ssh-keygen command, which must be located in some directory included in $PATH.
The filenames of the generated public and private keys are I<grid_cluster_rsa.pub> and
I<grid_cluster_rsa>, respectively.

By default, generated keys have the following characteristics:

=over 2

=item * Type: RSA

=item * Number of bits: 2048

=item * No passphrase

=back

Once the public/private key pair has been generated, the public key is copied to
remote machines specified by the option -c. This option can be used several times to
specify sets of machines with the same password to login. In this way, the copy
process of the public key to remote machines is easier.

The behaviour of the script can be modified by the different supported options. For
more information, you can execute the script with the option -h.

=item *

Add a line for each remote machine in the configuration file that specifies
the public/private key which is going to be used to authenticate the user.

  Host host_1
  HostName myHost1.mydomain.com
  User myUser
  IdentityFile ~/.ssh/grid_cluster_rsa 

  Host host_2
  HostName myHost2.mydomain.com
  User anotherUser
  IdentityFile ~/.ssh/grid_cluster_rsa 
  .
  .
  .
  Host host_n
  HostName myHostn.mydomain.com
  User myUser
  IdentityFile ~/.ssh/grid_cluster_rsa 

=item *

Once the public key is installed on remote machines and the configuration file
is properly written, you should be able to authenticate using your private key:

  $ ssh host_1
  Linux host_1 2.6.15-1-686-smp #2 SMP Mon Mar 6 15:34:50 UTC 2006 i686
  Last login: Sat Jul  7 13:34:00 2007 from local.machine
  user@host_1:~$

You can also automatically execute commands in the remote server:

  local.machine$ ssh host_1 uname -a
  Linux host_1 2.6.15-1-686-smp #2 SMP Mon Mar 6 15:34:50 UTC 2006 i686 GNU/Linux

=back

=head1 A PARALLEL ALGORITHM

The selected case of study for this tutorial is the computation of the number Pi
using numerical integration. This is not, in fact, a good way to compute Pi, but makes
a good example of how to exploit several machines to fulfill a coordination task.

To obtain the value of the number Pi, the area under the curve 4/(1+x*x) in the interval
[0,1] must be computed.
To obtain an approximated value of the number Pi, this interval can be divided
into N sub-intervals of size 1/N. Adding up the areas of the small
rectangles with base 1/N and height the value of the curve
4/(1+x*x) in the middle of the interval, an approximation is obtained.
Since the goal is to optimize the execution time, the sum of the areas will be
distributed among the processors. Every different process located on remote machines
will have assigned a logical identifier numbered from 0 to np-1 (being
np the total number of processes) and each machine will sum up the areas of
roughly N/np intervals.

To achieve a higher performance the code executed by every process has been
written in C<C> language:

  1  #include <stdio.h>
  2  #include <stdlib.h>
  3
  4  main(int argc, char **argv) {
  5    int id, N, np, i;
  6    double sum, left;
  7
  8    if (argc != 4) {
  9      printf("Usage:\n%s id N np\n",argv[0]);
 10      exit(1);
 11    }
 12
 13    id = atoi(argv[1]);
 14    N  = atoi(argv[2]);
 15    np = atoi(argv[3]);
 16
 17    for(i = id, sum = 0; i < N; i += np) {
 18      double x = (i + 0.5) / N;
 19      sum += 4 / (1 + x * x);
 20    }
 21
 22    sum /= N;
 23    printf("%lf\n", sum);
 24    exit(0);
 25  }

The program receives three arguments: The first one, C<id>
identifies the process with a logical number, the second one, C<N>,
is the total number of intervals, the third C<np> is the number of
processes being used. Notice the I<for> loop at line 17: Process id
sums up the areas corresponding to intervals id, id+np, id+2*np, etc.
The program concludes writing to the standard output the partial sum.

Observe that, since infinite precision numbers are not being used, errors
introduced by rounding and truncation imply that increasing N would not
lead to a more precise evaluation of the number Pi.

=head1 COORDINATING A PARALLEL VIRTUAL MACHINE

To coordinate the component program aforementioned, a driver has been written.
This driver uses GRID::Cluster and runs a number of copies of the former C<C>
program in a set of available machines, adding up partial results as soon as
they are available:

  1 #!/usr/bin/perl
  2 use warnings;
  3 use strict;
  4 use GRID::Cluster;
  5 use Time::HiRes qw(time gettimeofday tv_interval);
  6 use Getopt::Long;
  7 use List::Util qw(sum);
  8 use Pod::Usage;

First lines load the modules:

=over 2

=item * GRID::Cluster will be used to open SSH connections with remote machines
        and to coordinate the components among different remote processes.

=item * Time::HiRes will be used to time the processes.

=item * Getopt::Long will be used to obtain command line options of the user.

=item * List::Util allows the use of a set of methods to manage lists of elements.

=item * Pod::Usage will be used to present the correct usage of the program.

=back

Next lines present the initialization process, where the command line parameters
introduced by the user are obtained:

 10 my $config = 'MachineConfig.pm';
 11 my $np = 1;
 12 my $N = 100;
 13 my $clean = 0;
 14
 15 GetOptions(
 16   'config=s' => \$config, # Module containing the definition of %machine and %map_id_machine
 17   'np=i'     => \$np,
 18   'N=i'      => \$N,
 19   'clean'    => \$clean,
 20   'help'     => sub { pod2usage( -exitval => 0, -verbose => 2,) },
 21 ) or pod2usage(-msg => "Bad usage\n", -exitval => 1, -verbose => 1,);
 22
 23 my ($debug,  $max_num_np) = do $config;
 24
 25 my @machine = sort { $max_num_np->{$b} <=> $max_num_np->{$a} } keys  %$max_num_np;

At lines 15-21, the function I<GetOptions> obtains the command line
parameters introduced by the user and checks if the program usage is correct.
One of the command line parameters is the name of a file which contains the
configuration of the virtual parallel machine. The syntax of a configuration
file is as follows:

  my %debug = (
    host1 => 0,
    host2 => 0,
    host3 => 0,
    host4 => 0,
    ...
    IP address/name => 0 | 1,
  );

  my %max_num_proc = (
    host1 => 1,
    host2 => 2,
    host3 => 1,
    host4 => 3,
    ...
    IP address/name => N,
  );

  return (\%debug, \%max_num_proc);

The variable I<%debug> allows to activate the GRID::Cluster debug mode in
every machine of the virtual parallel machine. On the other hand, the variable
I<%max_num_proc> stores the maximum number of processes that can be
instantiated in every machine of the virtual parallel machine. These two variables
are initialized at line 23.

The variable I<@machine> stores the IP addresses/names of the machines where
a user has SSH access. These machines will constitute the virtual parallel
machine. At line 25 the machines are sorted taking into account the maximum
number of processes supported by each one.

 27 my $c = GRID::Cluster->new(host_names => \@machine, debug => $debug, max_num_np => $max_num_np)
 28    || die "No machines has been initialized in the cluster";
 29
 30 $np ||= $c->get_num_machines();
 31
 32 $c->copyandmake(
 33       dir => 'pi',
 34       makeargs => 'pi',
 35       files => [ qw{pi.c Makefile} ],
 36       cleanfiles => $clean,
 37       cleandirs => $clean, # remove the whole directory at the end
 38       keepdir => 1,
 39     );
 40
 41 $c->chdir("pi/") || die "Can't change to pi/\n";

At line 27 a new GRID::Cluster object is instantiated, using the method I<new>.
The number of processes is obtained from an argument specified in the command
line by the user, or by the use of the method I<get_num_machines> at line 30.
The call to I<copyandmake> at lines 32-39 copies (using I<scp>) the files
I<pi.c> and I<Makefile> to a directory named I<pi> on the remote machine.
The directory I<pi> will be created if it does not exists. After the file transfer,
the command specified by the option I<make> will be executed with the arguments
specified in the option I<makeargs>. If the I<make> option isn't specified but
there is a file named I<Makefile> between the transferred files, the I<make>
program will be executed. Set the I<make> option to number 0 or the string
I<''> to avoid the execution of any command after the transfer. The transferred files
will be removed when the connection finishes if the option I<cleanfiles> is set.
More radical, the option I<cleandirs> will remove the created directory and all the
files below it. Observe that the directory and the files will be kept if they were not
created by this connection. The call to I<copyandmake> by default sets I<dir>
as the current directory in the remote machine. Set the option I<keepdir> to one
to avoid this.
The method I<chdir> (line 41) of a GRID::Cluster object changes the working
directory of every remote machine associated to the virtual parallel machine.

 43 my @commands = map {  "./pi $_ $N $np |" } 0..$np-1;
 44
 45 my $t0 = [gettimeofday];
 46
 47 my $pi = sum @{$c->qx(@commands)};
 48
 49 my $elapsed = tv_interval($t0);
 50
 51 print "Calculating Pi with $N iterations and $np processes\n";
 52 print "Elapsed Time: $elapsed seconds\n";
 53 print "Pi Value: $pi\n";

Last step consists in creating the commands that are going to be executed
in different machines (line 43) by the use of the method I<qx> of a GRID::Cluster
object. This method allows the execution of different tasks or processes
following an approximation based on farms, this is, initially, a maximum number
of processes are run, and when one of them finishes its execution, a new process
is run, if there are more pending processes to be executed. This feature allows
a good load balancing among different machines.

At line 47, the method I<qx> returns a list with the partial sums calculated
by every process executed in the virtual parallel machine, and by the use of
the function I<sum>, a sum of all these results is performed, obtaining the
value of the number Pi.

=head1 COMPUTATIONAL RESULTS

The execution of the C<C> program on each of the three involved machines is presented
in following lines. The number of intervals N has been fixed to 1,000,000,000.

  $ time ./pi 0 1000000000 1
  3.141593
  real    0m56.959s
  user    0m56.492s
  sys     0m0.004s

  $ time ./pi 0 1000000000 1
  3.141593
  real    0m30.862s
  user    0m30.850s
  sys     0m0.012s

  $ time ./pi 0 1000000000 1
  3.141593
  real    0m29.026s
  user    0m28.654s
  sys     0m0.049s

These results indicate that the first machine is slower than the other two.

Now let us run the driver using only the fastest machine and one process. The time
spent is comparable to the pure C<C> time, and that is great because the overhead
introduced by the coordination tasks is not as large:

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 1
  Calculating Pi with 1000000000 iterations and 1 processes
  Elapsed Time: 30.919523 seconds
  Pi Value: 3.141593

  real    0m32.690s
  user    0m0.516s
  sys     0m0.060s

Now we are going to execute the driver using two different machines, each one with only
one process:

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 2
  Calculating Pi with 1000000000 iterations and 2 processes
  Elapsed Time: 28.459958 seconds
  Pi Value: 3.141592

  real    0m30.610s
  user    0m0.524s
  sys     0m0.056s

We can see that the sequential pure C version took 56 seconds in the slowest machine.
By using two machines, each one with one process,  the time has been reduced to 23 seconds.
This a factor of 56/31 = 1.80 times faster. This factor is even better if I don't consider
the set-up time: 56/29 = 1.93. The total time decreases if three machines are used, every
one with only one process:

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 3
  Calculating Pi with 1000000000 iterations and 3 processes
  Elapsed Time: 20.956588 seconds
  Pi Value: 3.141594

  real    0m22.549s
  user    0m0.296s
  sys     0m0.068s

which gives a speed factor of 56/23 = 2.43 or not considering the set-up time 56/21 = 2.66.

If you increase the number of processes, the use of the method I<qx> allows to obtain
better results, due to the load balancing produced by the use of a mechanism based
on a farm. The results increasing the number of processes (but only using three machines,
every one with a process in every moment) are in the following lines:

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 6
  Calculating Pi with 1000000000 iterations and 6 processes
  Elapsed Time: 15.694753 seconds
  Pi Value: 3.141594

  real    0m17.285s
  user    0m0.304s
  sys     0m0.104s

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 12
  Calculating Pi with 1000000000 iterations and 12 processes
  Elapsed Time: 13.246352 seconds
  Pi Value: 3.141588

  real    0m14.798s
  user    0m0.328s
  sys     0m0.116s

  $ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 15
  Calculating Pi with 1000000000 iterations and 15 processes
  Elapsed Time: 12.924256 seconds
  Pi Value: 3.1416

  real    0m14.500s
  user    0m0.372s
  sys     0m0.108s

Using 3 processes with 3 machines (every one with only one process), the
fastest machines have to wait for the slowest one to finish the execution.
Using 6, 12 and 15 processes, the time is decreased. Because of the
heterogeneity of the different machines, while the slowest machine is
executing a process, the fastest one has executed several processes.
More processes are executed in less time by the fastest machine
(load balancing) and the consequence is a decrease in the total execution
time.

=head1 SEE ALSO

=over 2

=item * GRID::Cluster

=item * GRID::Cluster::Result

=item * GRID::Cluster::Tutorial

=item * GRID::Machine

=item * IPC::PerlSSH

=item * Man pages of ssh, ssh-key-gen, ssh_config, scp, ssh-agent, ssh-add, sshd

=item * http://www.openssh.com

=item * The Wikipedia entry in Cluster Computing http://en.wikipedia.org/wiki/Computer_cluster

=item * The Wikipedia entry in GRID Computing: http://en.wikipedia.org/wiki/Grid_computing

=item * The Wikipedia entry for Load Balancing http://en.wikipedia.org/wiki/Load_balancing_%28computing%29

=item * The State of Parallel Computing in Perl 2007. Perlmonks node at http://www.perlmonks.org/?node_id=595771

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
