# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

package    # hide from PAUSE
  TestLib;

use strict;
use warnings;
use FindBin qw( $Bin );

sub new { return bless {}, shift }

sub run_gearmand {
  my ($self) = @_;
  unlink '/tmp/gearmand-xs.log';
  my $gearmand = find_gearmand();
  die "Cannot locate gearmand executable"
    if !$gearmand;
  if ($self->{gearmand_pid}= fork)  {
    warn("test_server PID is " . $self->{gearmand_pid});
  }
  else {
    die "cannot fork: $!"
      if (!defined $self->{gearmand_pid});
    $|++;
    my @cmd= ($gearmand, '-p', 4731, '--log-file=/tmp/gearmand-xs.log', '--verbose=DEBUG', '--pid-file=/tmp/gearmand-xs.pid');
    exec(@cmd)
      or die("Could not exec $gearmand");
    exit;
  }
}

sub run_test_worker {
  my ($self) = @_;
  if ($self->{test_worker_pid} = fork)
  {
    warn("test_worker PID is " . $self->{test_worker_pid});
  }
  else
  {
    die "cannot fork: $!"
      if (!defined $self->{test_worker_pid});
    $|++;
    my @cmd = ($^X, "$Bin/test_worker.pl");
    exec(@cmd)
      or die("Could not exec $Bin/test_worker.pl");
    exit;
  }
}

sub DESTROY {
  my ($self) = @_;

  for my $proc (qw/gearmand_pid test_worker_pid/)
  {
    system 'kill', $self->{$proc}
      if $self->{$proc};
  }
}

sub find_gearmand {
  my $gearmand= find_gearmand_in_path();
  $gearmand ||= find_gearmand_with_pkg_config();
  return $gearmand
}

sub find_gearmand_in_path {
  my $gearmand= `which gearmand`;
  chomp $gearmand;
  return $gearmand;
}

sub find_gearmand_with_pkg_config {
  my $pkg_config = `which pkg-config`;
  chomp $pkg_config;
  return
    if !$pkg_config;
  my $exec_prefix= `$pkg_config --variable=exec_prefix gearmand`;
  chomp $exec_prefix;
  return "$exec_prefix/sbin/gearmand"
    if $exec_prefix
}

1;
