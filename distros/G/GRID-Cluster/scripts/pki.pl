#!/usr/bin/perl
use warnings;
use strict;

use Getopt::Long;
use File::Temp qw/ tempfile /;
use Term::Prompt;

# Default options
my $help = '';
my $verbose = '';
my $sshkeygen_opts = '';
my $sshkeygen_cmd = 'ssh-keygen';
my $passphrase = "''";
my $type = 'rsa';
my $bits = '2048';
my $filename = "$ENV{HOME}/.ssh/grid_cluster_rsa";
my $configFile = "$ENV{HOME}/.ssh/config";
my @clusters;

# String with correct usage
my $str_help = <<"HELP";
Usage: ./pki.pl [options] -c host_1,...,host_N [-c host_1,...,host_N]
options:
  -h                              Show the script help.
  -v                              Verbose mode.
  -s ssh-keygen command           Provide the ssh-keygen command. By default, 'ssh-keygen'.
  -k ssh-keygen string            Provide an arguments string which is passed to the ssh-keygen command.
  -p passphrase                   Provide a passphrase. By default, no passphrase is used.
  -t type                         Specify type of key to create. By default, 'RSA' type is specified.
  -b bits                         Number of bits in the key to create. By default, 2048 bits are used.
  -f key pair filename            Filename of the key file. By default, \$HOME/.ssh/grid_cluster_rsa.
  -g configuration filename       Filename of the configuration file. By default, \$HOME/.ssh/config.
  -c host_1, host_2, ..., host_N  Specify a set of machines where the public key has to be installed.
                                  This option can be used several times to specify sets of machines which
                                  need the same password to login.

Each host specified with the option -c must be configured in a configuration file
(man ssh_config). By default, the configuration file is \$HOME/.ssh/config.
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

HELP

# Captures command line options
die $str_help
  unless (GetOptions(
    'h|help'              => \$help,
    'v|verbose'           => \$verbose,
    's=s'                 => \$sshkeygen_cmd,
    'k=s'                 => \$sshkeygen_opts,
    'p|passphrase=s'      => \$passphrase,
    't|type=s'            => \$type,
    'b|bits=s'            => \$bits,
    'f|key_filename=s'    => \$filename,
    'g|config_filename=s' => \$configFile,
    'c|cluster=s'         => \@clusters,
   ) && (!$help));

die "Error: A set of hosts must be specified\n" if (!@clusters);

# Opens the configuration file
open CONFIG, $configFile or die "Error: Configuration file does not exist\n";

# Reads all the configuration file
my $configFileContent;
{
  undef $/;
  $configFileContent = <CONFIG>;
}

close CONFIG;

# Generates the public/private key pair
warn "Generating the public/private key pair\n" if ($verbose);

# Default command to create the public/private key pair
my $keygen_cmd = "$sshkeygen_cmd $sshkeygen_opts -P $passphrase -t $type -b $bits -f $filename";

warn "ssh-keygen command: $keygen_cmd\n" if ($verbose);

# Creates a temporary file to redirect errors during the the ssh-keygen command invocation
(undef, my $tmpfilename) = tempfile(OPEN => 0, DIR => "/tmp/");

my $code = system qq{$keygen_cmd 2>$tmpfilename};
$code = $code >> 8;

if (($code != 0) && ($code != 1)) {
  my $result .= `cat $tmpfilename` if -s $tmpfilename;
  die "Error: ssh-keygen command has exited with value $code\n$result";
}

warn "The public/private key pair has been generated\n" if (($verbose) && ($code == 0));
warn "The public/private key pair has not been generated\n" if (($verbose) && ($code != 0));

# Obtains the generated public key
my $public_key = qx{cat $filename.pub};
chomp $public_key;
my $meta_public_key = quotemeta($public_key);

# Copies the public key to remote machines
warn "Copying the public key to remote machines\n" if ($verbose);

# Creates a temporary file to redirect STDOUT during the copy of the public key
# to remote machines
(undef, $tmpfilename) = tempfile(OPEN => 0, DIR => "/tmp/");

foreach my $cluster (@clusters) {
  my $password = prompt('p', "Enter password for hosts $cluster:", '', '');
  print "\n";

  foreach my $host (split /,\s*/, $cluster) {
   
    warn "Trying to copy the public key to host $host\n" if ($verbose);

    # Checks if $host exist in the configuration file
    if ($configFileContent !~ m/Host $host/) {
      warn "Host $host is not present in the configuration file. Skipping\n" if ($verbose);
    }
    else {
      # Creates the command
      my $command = qq{
        ssh $host 
        'umask u=rwx,g=,o=;
        test -d .ssh || mkdir .ssh;
        touch .ssh/authorized_keys;
        resultado=`grep -c $meta_public_key .ssh/authorized_keys`;
        if [ \$resultado -eq 0 ]; then
          echo $meta_public_key >> .ssh/authorized_keys;
          echo -e Public key has been copied in the host $host;
        else echo -e Public key is already installed in the host $host; fi'
      };

      $command =~ s/\n/ /g;

      # Executes the command
      open FILE, "|sshpass -d 0 $command 2>/dev/null 1>$tmpfilename";
      print FILE $password;
      close FILE;

      # Checks the result of the command
      my $result = qx{cat $tmpfilename} if (-s $tmpfilename);

      if (($result) && (($result =~ m/Public key has been copied in the host $host/g) ||
         ($result =~ m/Public key is already installed in the host $host/g)) && ($verbose)) {
        warn $result;
      }
      elsif ($verbose) {
        warn "Error: The copy process of the public key has failed for the host $host\n";
      }
    }
  }
}

__END__

=head1 NAME

pki.pl - Public Key Infrastructure Configuration

=head1 SYNOPSIS

  ./pki.pl -h
  ./pki.pl [-v] -c host_1,host_2,...,host_n
  ./pki.pl [-v] [-s 'ssh-keygen command'] [-k 'ssh-keygen arguments] [-p passphrase] [-t type] [-b bits] [-f key pair filename]
           [-g configuration filename] -c host_1,host_2,...,host_n [-c host1,host2,...,host_n]

=head1 DESCRIPTION

This script allows the generation of public/private key pairs, using the ssh-keygen
command. Generated public key is copied to a list of remote machines. Specifically,
the public key is added, if not exist, in the file $HOME/.ssh/authorized_keys of
each remote machine.

The basic execution of the command is as follows:

  ./pki.pl [-v] -c host_1,host_2,...host_n

In this case, a public/private key pair is generated in the local directory $HOME/.ssh/,
using the ssh-keygen command, which must be located in some directory included in $PATH.
The filenames of the generated public and private keys are I<grid_cluster_rsa.pub> and
I<grid_cluster_rsa>, respectively.

By default, generated keys have the following characteristics:

=over

=item * Type: RSA

=item * Number of bits: 2048

=item * No passphrase

=back

Once the public/private key pair has been generated, the public key is copied to remote machines
specified by the option -c. This option can be used several times to specify sets of machines
with the same password to login. By this way, the copy process of the public key to remote
machines is easier.

Each host specified with the option -c, must be configured in a configuration file
(I<man ssh_config>). By default, the configuration file is $HOME/.ssh/config.
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

The behaviour of the script can be modified by the different supported options. These options are
exposed in the following section.

=head1 OPTIONS

The options allowed by this script can take the same values of the ssh-keygen command (execute
I<man ssh-keygen> from shell for more information). The allowed options are the next ones:

=over

=item * -h                              Show the script help.

=item * -v                              Verbose mode.

=item * -s ssh-keygen command           Provide the ssh-keygen command. By default, 'ssh-keygen'.

=item * -k ssh-keygen string            Provide an arguments string which is passed to the ssh-keygen command.

=item * -p passphrase                   Provide a passphrase. By default, no passphrase is used.

=item * -t type                         Specify type of key to create. By default, 'RSA' type is specified.

=item * -b bits                         Number of bits in the key to create. By default, 2048 bits are used.

=item * -f key pair filename            Filename of the key file. By default, $HOME/.ssh/grid_cluster_rsa.

=item * -g configuration filename       Filename of the configuration file. By default, $HOME/.ssh/config.

=item * -c host_1, host_2, ..., host_n  Specify a set of machines where the public key has to be installed.
                                        This option can be used several times to specify sets of machines which
                                        need the same password to login.

=back

=head1 DEPENDENCIES

This script requires the following modules and libraries:

=over

=item * L<GetOpt::Long> module by Johan Vromans

=item * L<File::Temp> module by Tim Jenness

=item * L<Term::Prompt> module by Matthew O. Persico

=item * C<sshpasswd> command must be installed. See L<http://sourceforge.net/projects/sshpass/>

=item * The program assumes an Open SSH installation

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

Copyright (C) 2010 by Eduardo Segredo Gonzalez and Casiano Rodriguez Leon.
All rights reserved.

This software is free; you can redistribute it and/or modify it under the
same terms as Perl itself, either Perl version 5.12.2 or, at your option,
any later version of Perl 5 you may have available.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
