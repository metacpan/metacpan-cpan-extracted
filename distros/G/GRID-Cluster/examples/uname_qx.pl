#!/usr/bin/perl
use strict;
use warnings;

use GRID::Cluster;
use Data::Dumper;

my @host_names = split(/:/, $ENV{GRID_REMOTE_MACHINES});

my ($debug, $max_num_np);
for (@host_names) {
  $debug->{$_} = 0;
  $max_num_np->{$_} = 1;
}

my $cluster = GRID::Cluster->new(host_names => \@host_names,
                                 debug      => $debug,
                                 max_num_np => $max_num_np,
                             );

my $np = $cluster->get_max_np();

my @commands = map { "uname -a" } 0..$np-1;
my $result = $cluster->qx(@commands);

print Dumper($result);

__END__

=head1 NAME

uname_qx.pl -- A simple example of a remote command execution
using the method qx of a GRID::Cluster object

=head1 SYNOPSIS

  ./uname_qx.pl

=head1 DESCRIPTION

This example uses the method qx of a GRID::Cluster object
to create unidirectional pipes for communications among different
processes. The example needs the definition of the the environment
variable GRID_REMOTE_MACHINES. For example, from a bash shell a
user can write:

  export GRID_REMOTE_MACHINES=host1:host2:host3

to set that environment variable.
