package IS::Init;
use strict;
use IO::Socket;
use IO::Select;
use POSIX qw(:signal_h :errno_h :sys_wait_h);
use Data::Dump qw(dump);

my $debug=$ENV{DEBUG} || 0;

sub debug
{
  warn @_ if $debug;
}

BEGIN {
	use vars qw ($VERSION);
	$VERSION     = 0.93;
}

=head1 NAME

IS::Init - Clusterwide "init", spawn cluster applications

=head1 SYNOPSIS

  use IS::Init;

  my $init = new IS::Init;

  # spawn all apps for resource group "foo", runlevel "run"
  $init->tell("foo","run");

  # spawn all apps for resource group "foo", runlevel "runmore"
  # (this stops everything started by runlevel "run")
  $init->tell("foo","runmore");

=head1 DESCRIPTION

This module provides basic "init" functionality, giving you a single
inittab-like file to manage initialization and daemon startup across a
cluster or collection of machines.

=head1 USAGE

This module's package includes a script 'isinit', which is intended to
be a bolt-in cluster init tool, calling IS::Init.  The script is
called like 'init', with the addition of a new "resource group"
argument.

This module is intended to be used like 'init' and 'telinit' -- the
first execution runs as a daemon, spawning and managing processes.
Later executions talk to the first, requesting it to switch to
different runlevels.

The module references a configuration file, /etc/isinittab by default,
which is identical in format to /etc/inittab, with a new "resource
group" column added.  This file must be replicated across all hosts in
the cluster by some means.

A "resource group" is a collection of applications and physical
resources which together make up a coherent function.  For example,
sendmail, /etc/sendmail.cf, and the /var/spool/mqueue directory might
make up a resource group. From /etc/isinittab you could spawn the
scripts which update sendmail.cf, mount mqueue, and then start
sendmail itself.

=head1 PUBLIC METHODS

=head2 new

=cut

sub new
{
  my $class=shift;
  $class = (ref $class || $class);
  my $self={};
  bless $self, $class;

=pod

The constructor accepts an optional hash containing the paths to the
configuration file and to the socket, like this:

  my $init = new IS::Init (
      'config' => '/etc/isinittab',
      'socket' => '/var/run/is/init.s'
      'initstat' => '/var/run/is/initstat'
			  );

=cut

  my %parms=@_;
  
  $self->{'config'} = $parms{'config'} || "/etc/isinittab";
  $self->{'socket'} = "/var/run/is/init.s";
  $self->_config();
  $self->{'socket'} = $parms{'socket'} if $parms{'socket'};

  ($self->{'group'}, $self->{'level'}) = ("NULL", "NULL");

=pod

The first time this method is executed on a machine, it opens a UNIX
domain socket, /var/run/is/init.s by default.  Subsequent executions
communicate with the first via this socket.  

=cut

  $self->_open_socket() || $self->_start_daemon() || die $!;

  return $self;
}

=head2 tell($resource_group,$runlevel)

This method talks to a running IS::Init daemon, telling it to switch
the given resource group to the given runlevel.  

All processes listed in the configuration file (normally
/etc/isinittab) which belong to the new runlevel will be started if
they aren't already running.

All processes in the resource group which do not belong to the new
runlevel will be killed.

Other resource groups will not be affected.

=cut

sub tell
{
  my ($self,$group,$runlevel)=@_;
  my $socket = $self->_open_socket() || die $!;
  print $socket "$group $runlevel\n";
  close($socket);
  1;
}

sub status
{
  my $self=shift;
  my %parm = @_;
  my $group = $parm{'group'} if $parm{'group'};
  my $level = $parm{'level'} if $parm{'level'};
  my $initstat = $parm{'initstat'} if $parm{'initstat'};
  # allow this to be called as IS::Init->status(...)
  $self=bless({},$self) unless ref($self);
  $self->{'initstat'} = $initstat if $initstat;
  return "" unless $self->{'initstat'} && -f $self->{'initstat'};
  my $startid="start";
  my $endid="end";
  my $out;
  do
  {
    $out ="";
    open(STATUS,"<$self->{'initstat'}") || die $!;
    while(<STATUS>)
    {
      if (/^!startid (.*)/)
      {
	$startid = $1;
	next;
      }
      next if $startid eq "start";
      if (/^!endid (.*)/)
      {
	$endid = $1;
	last;
      }
      my ($sgroup,$state,$slevel) = split;
      next unless $state;
      if ($group)
      {
	next if $group ne $sgroup;
	s/^\S+\s+(.*?)\s*$/$1/;
	chomp;
      }
      if ($level)
      {
	next if $level ne $slevel;
	s/^(\S+)\s+.*$/$1/;
	chomp;
      }
      $out .= $_;
    }

  } while $startid ne $endid;
  return $out;
}

sub stopall
{
  my ($self)=@_;
  my $socket = $self->_open_socket() || die $!;
  print $socket "stopall";
  close($socket);
  1;
}


sub _open_socket
{
  my $self=shift;
  my $client = new IO::Socket::UNIX (
      Peer => $self->{'socket'},
      Type => SOCK_STREAM
				    );
  return $client;
}

sub _start_daemon
{
  my $self=shift;

  my $child;
  unless ($child = fork())
  {
    while(1)
    {
      unlink $self->{'socket'};
      my $server = new IO::Socket::UNIX (
	  Local => $self->{'socket'},
	  Type => SOCK_STREAM,
	  Listen => SOMAXCONN
					) || die $!;
      while(my $client = $server->accept())
      {
	$SIG{CHLD} = 'IGNORE';
	debug "reading\n";
	my $data=<$client>;
	$data="" unless $data;
	chomp($data=$data);
	debug "$data\n" if $data;
	debug "done reading, got: $data\n";
	$self->_stopall() if $data =~ /^stopall/;
	my ($group,$level) = split(' ',$data);
	$self->_spawn($group,$level);
	$self->_sigchld();
	close($client);
      }
      debug "restarting socket\n";
    }
  }

  debug "IS::Init daemon started as PID $child\n"; 

  sleep 1;
  return $child;
}

sub _status
{
  my ($self,$group,$level,$state) = @_;
  $level = $self->{'status'}{$group}{'level'} unless $level;
  $self->{'status'}{$group}{'level'}=$level;
  $self->{'status'}{$group}{'state'}=$state;
  return "" unless $self->{'initstat'};
  # fetch all groups in inittab
  my @group;
  for my $tag (keys %{$self->{'inittab'}{'group'}})
  {
    my $group = $self->{'inittab'}{'group'}{$tag};
    push @group, $group unless grep /^$group$/, @group;
  }
  # add the groups in status, just in case
  for my $group (keys %{$self->{'status'}})
  {
    push @group, $group unless grep /^$group$/, @group;
  }
  my $id = rand();
  open(STATUS,">$self->{'initstat'}") || die $!;
  print STATUS "!startid $id\n";
  # for my $group (keys %{$self->{'status'}})
  for my $group (sort @group)
  {
    next if $group eq "NULL";
    debug "storing status for $group\n";
    my $state = $self->{'status'}{$group}{'state'} || "stopped";
    my $level = $self->{'status'}{$group}{'level'} || "";
    printf STATUS ("%-15s %-15s %-15s\n", $group, $state, $level);
  }
  print STATUS "!endid $id\n";
  # print STATUS dump($self);
  close STATUS;
}

sub _stopall
{
  my $self=shift;
  for my $group (keys %{$self->{'status'}})
  {
    $self->_status($group,'',"stopping");
  }
  for my $tag (keys %{$self->{'pid'}})
  {
    $self->_kill($tag);
  }
  for my $group (keys %{$self->{'status'}})
  {
    $self->_status($group,'',"stopped");
  }
  exit(0);
}

sub _config
{
  my $self=shift;
  $self->{'inittab'}={};
  open(INITTAB,"<$self->{'config'}") || die $!;
  while(<INITTAB>)
  {
    next if /^#/;
    next if /^\s*$/;
    chomp;
    my ($group,$tag,$level,$mode,$cmd) = split(':',$_,5);
    debug "inittab $group|$tag|$level|$mode|$cmd\n";
    if ($mode eq "socket")
    {
      $self->{'socket'} = $cmd;
      next;
    }
    if ($mode eq "initstat")
    {
      $self->{'initstat'} = $cmd;
      next;
    }
    next if /^:::/;
    $self->{'inittab'}{'group'}{$tag} = $group;
    my @level;
    if ($level =~/,/)
    {
      @level = split(',',$level);
      debug dump(@level). "\n";
    }
    else
    {
      @level = split('',$level);
    }
    debug "final levels @level\n";
    $self->{'inittab'}{'levels'}{$tag} = \@level;
    $self->{'inittab'}{'mode'}{$tag} = $mode;
    $self->{'inittab'}{'cmd'}{$tag} = $cmd;
  }
}

# starts and stops processes according to new runlevel
sub _spawn
{
  my ($self,$newgroup,$newlevel)=@_;
  ($newgroup,$newlevel)=($self->{'group'},$self->{'level'})
  unless $newgroup && ($newlevel || (defined($newlevel) && $newlevel == 0));
  ($self->{'group'},$self->{'level'}) = ($newgroup,$newlevel);
  $self->_status($newgroup,$newlevel,"start");
  $self->_config();
  my @activetags;
  my $testres="";
  for my $tag (keys %{$self->{'inittab'}{'group'}})
  {
    debug "checking $tag\n"; 
    my $group=$self->{'inittab'}{'group'}{$tag};
    my @level=@{$self->{'inittab'}{'levels'}{$tag}};
    my $mode=$self->{'inittab'}{'mode'}{$tag};
    my $cmd=$self->{'inittab'}{'cmd'}{$tag};
    next if $mode eq "off";
    push @activetags, $tag;
    next unless $group eq $newgroup;

    debug "$group $tag has levels @level\n";

    # if this line is for our newly commanded runlevel
    if(grep /^$newlevel$/, @level)
    {
      # start processes in new runlevel
      debug "starting $newgroup $newlevel\n";

      # bail if already started in another runlevel
      next if $self->{'pid'}{$tag};

      if ($mode eq "wait")
      {
	# set a placeholder to keep us from running $tag again
	$self->{'pid'}{$tag} = "wait";
	debug "wait system($cmd)\n";
	# XXX process start
	system($cmd);
	next;
      }

      if ($mode eq "test")
      {
	# set a placeholder to keep us from running $tag again
	$self->{'pid'}{$tag} = "test";
	debug "test system($cmd)\n";
	# XXX process start
	system($cmd);
	my $rc = $? >> 8;
	$testres = "fail"  if $rc;
	next;
      }

      if ($mode eq "respawn")
      {
	# start timing and counting
	$self->{'time'}{$tag}=time() unless $self->{'time'}{$tag};
	$self->{'counter'}{$tag}=0 unless $self->{'counter'}{$tag};
	if($self->{'time'}{$tag} < time() - 10)
	{
	  # it's been a while; restarting timing and counting
	  $self->{'time'}{$tag}=time(); 
	  $self->{'counter'}{$tag}=0;
	}
	# skip this inittab entry if we're in jail
	next unless time() >= $self->{'time'}{$tag};
	# let it respawn no more than 5 times in 10 seconds
	if ($self->{'counter'}{$tag} >= 5)
	{
	  warn "$0: $tag respawning too rapidly -- sleeping 60 seconds\n";
	  # go to jail 
	  $self->{'time'}{$tag}=time() + 60; 
	  $self->{'counter'}{$tag}=0;
	  next;
	}
	$self->{'counter'}{$tag}++;
      }

      # we only get here if tag is respawn or once
      if (my $pid = fork())
      {
	# parent
	debug "$pid forked\n";
	# build index so we can find pid from tag
	$self->{'pid'}{$tag} = $pid;
	# build reverse index so we can find tag from pid
	$self->{'tag'}{$self->{'pid'}{$tag}}=$tag;
	next;
      }
      # child
      # sleep 1;
      debug "exec $cmd\n";
      # XXX process start
      exec($cmd);
    }
    else
    {
      # stop processes in old runlevel 
      next unless $self->{'pid'}{$tag};
      $self->_kill($tag);
    }

  }

  # stop processes which are no longer in inittab
  for my $tag (keys %{$self->{'pid'}})
  {
    next if grep /^$tag$/, @activetags;
    $self->_kill($tag);
  }

  my $state = $testres || "run";
  $self->_status($newgroup,$newlevel,$state);
}

sub _kill
{
  my $self = shift;
  my $tag = shift;
  if 
  (
    $self->{'pid'}{$tag} eq "wait" ||
    $self->{'pid'}{$tag} eq "test"
  )
  {
    delete $self->{'pid'}{$tag};
    return;
  }
  return unless $self->{'pid'}{$tag};
  debug "killing $self->{'pid'}{$tag}\n";
  # XXX process kill start
  kill(15,$self->{'pid'}{$tag});
  for(my $i=1;$i <= 16; $i*=2)
  {
    last unless $self->{'pid'}{$tag};
    last unless kill(0,$self->{'pid'}{$tag});
    sleep $i;
  }
  return unless $self->{'pid'}{$tag};
  while(kill(0,$self->{'pid'}{$tag}))
  {
    # XXX process kill hard
    debug "hard kill $self->{'pid'}{$tag}\n";
    kill(9,$self->{'pid'}{$tag});
  }
  # XXX process kill done
  debug "killed $self->{'pid'}{$tag}\n";

  delete $self->{'pid'}{$tag};
}

sub _sigchld
{
  my $self=shift;
  my $pid = waitpid(-1, &WNOHANG);
  if ($pid == -1)
  {
    # nothing exited -- ignore
    $SIG{CHLD} = sub {$self->_sigchld()};
    return;
  }
  unless (kill(0,$pid) == 0)
  {
    # still running -- false alarm
    $SIG{CHLD} = sub {$self->_sigchld()};
    return;
  }
  # $pid exited
  debug "$pid exited\n";
  # XXX pid exited (do we get here for every kill?  what about system()?)
  my $tag = $self->{'tag'}{$pid};
  # why not just always delete $self->{'pid'}{$tag} here?
  delete $self->{'pid'}{$tag} if $self->{'inittab'}{'mode'}{$tag} eq 'respawn';
  # reread isinittab
  $self->_spawn();
  $SIG{CHLD} = sub {$self->_sigchld()};
}

=head1 BUGS

=head1 AUTHOR

	Steve Traugott
	CPAN ID: STEVEGT
	stevegt@TerraLuna.Org
	http://www.stevegt.com

=head1 COPYRIGHT

Copyright (c) 2001 Steve Traugott. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1; #this line is important and will help the module return a true value

__END__


