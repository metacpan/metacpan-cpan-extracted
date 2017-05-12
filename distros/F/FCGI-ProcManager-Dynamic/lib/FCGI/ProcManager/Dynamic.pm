package FCGI::ProcManager::Dynamic;
use base FCGI::ProcManager;

# Copyright (c) 2012, Andrey Velikoredchanin.
# This library is free software released under the GNU Lesser General
# Public License, Version 3.  Please read the important licensing and
# disclaimer information included below.

# $Id: Dynamic.pm,v 0.7 2017/03/09 12:17:00 Andrey Velikoredchanin $

use strict;

use vars qw($VERSION);
BEGIN {
	$VERSION = '0.8';
}

use POSIX;
use Time::HiRes qw(usleep);
use IPC::SysV qw(IPC_PRIVATE IPC_CREAT IPC_NOWAIT IPC_RMID);
use FCGI::ProcManager;

=head1 NAME

FCGI::ProcManager::Dynamic -  extension for FCGI::ProcManager, it can dynamically control number of work processes depending on the load.

=head1 SYNOPSIS

 # In Object-oriented style.
 use CGI::Fast;
 use FCGI::ProcManager::Dynamic;
 my $proc_manager = FCGI::ProcManager::Dynamic->new({
 	n_processes => 8,
 	min_nproc => 8,
 	max_nproc => 32,
 	delta_nproc => 4,
 	delta_time => 60,
 	max_requests => 300
 });
 $proc_manager->pm_manage();
 while ($proc_manager->pm_loop() && (my $cgi = CGI::Fast->new())) {
 	$proc_manager->pm_pre_dispatch();
 	# ... handle the request here ...
 	$proc_manager->pm_post_dispatch();
 }

=head1 DESCRIPTION

FCGI::ProcManager::Dynamic the same as FCGI::ProcManager, but it has additional settings and functions for dynamic control of work processes's number.

=head1 Addition options

=head2 min_nproc

The minimum amount of worker processes.

=head2 max_nproc

The maximum amount of worker processes.

=head2 delta_nproc

amount of worker processes which will be changed for once in case of their increase or decrease.

=head2 delta_time

Delta of time from last change of processes's amount, when they will be reduced while lowering of loading.

=head2 max_requests

Amount of requests for one worker process. If it will be exceeded worker process will be recreated.

=head1 Addition functions

=head2 pm_loop

Function is needed for correct completion of worker process's cycle if max_requests will be exceeded.

=head1 BUGS

No known bugs, but this does not mean no bugs exist.

=head1 SEE ALSO

L<FCGI::ProcManager>
L<FCGI>

=head1 MAINTAINER

Andrey Velikoredchanin <andy@andyhost.ru>

=head1 AUTHOR

Andrey Velikoredchanin

=head1 COPYRIGHT

FCGI-ProcManager-Dynamic - A Perl FCGI Dynamic Process Manager
Copyright (c) 2012, Andrey Velikoredchanin.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

BECAUSE THIS LIBRARY IS LICENSED FREE OF CHARGE, THIS LIBRARY IS
BEING PROVIDED "AS IS WITH ALL FAULTS," WITHOUT ANY WARRANTIES
OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, WITHOUT
LIMITATION, ANY IMPLIED WARRANTIES OF TITLE, NONINFRINGEMENT,
MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, AND THE
ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY,
AND EFFORT IS WITH THE YOU.  See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

=cut

sub pm_manage
{
	my $self = shift;

	$self->{USED_PROCS} = 0;

	if (!defined($self->{min_nproc})) { $self->{min_nproc} = $self->n_processes(); };
	if (!defined($self->{max_nproc})) { $self->{max_nproc} = 8; };
	if (!defined($self->{delta_nproc})) { $self->{delta_nproc} = 5; };
	if (!defined($self->{delta_time})) { $self->{delta_time} = 5; };

	$self->{_last_delta_time} = time();

	# Создает очередь сообщений
	if (!defined($self->{ipcqueue} = msgget(IPC_PRIVATE, IPC_CREAT | 0666))) {
		die "Cannot create shared message pipe!";
	};

	$self->{USEDPIDS} = {};

	$self->SUPER::pm_manage();
}

sub pm_wait
{
	my $self = shift;

	# wait for the next server to die.
	my $pid = 0;
	while ($pid >= 0)
	{
		$pid = waitpid(-1, WNOHANG);

		if ($pid > 0)
		{
			# notify when one of our servers have died.
			delete($self->{PIDS}->{$pid});
			$self->pm_notify("worker (pid $pid) exited with status ".$?);
		};

		# Читаем сообщения
		my $rcvd;
		my $delta_killed = $self->{delta_nproc};
		while (msgrcv($self->{ipcqueue}, $rcvd, 60, 0, IPC_NOWAIT))
		{
			my ($code, $cpid) = unpack("l! l!", $rcvd);
			if ($code eq '1')
			{
				$self->{USEDPIDS}->{$cpid} = 1;
			}
			elsif ($code eq '2')
			{
				delete($self->{USEDPIDS}->{$cpid});
			};
		};

		# Сверяем нет-ли в списке загруженных PID уже удаленных и считаем количество используемых
		$self->{USED_PROCS} = 0;
		foreach my $cpid (keys %{$self->{USEDPIDS}})
		{
			if (!defined($self->{PIDS}->{$cpid}))
			{
				delete($self->{USEDPIDS}->{$cpid});
			}
			else
			{
				$self->{USED_PROCS}++;
			};
		};

		# Балансировка процессов
		# Если загружены все процессы, добавляем
		if ($self->{USED_PROCS} >= $self->{n_processes})
		{
			# Добавляем процессы
			my $newnp = (($self->{n_processes} + $self->{delta_nproc}) < $self->{max_nproc})? ($self->{n_processes} + $self->{delta_nproc}):$self->{max_nproc};

			if ($newnp != $self->{n_processes})
			{
				$self->pm_notify("increase workers count to $newnp");
				$self->SUPER::n_processes($newnp);
				$pid = -10;
				$self->{_last_delta_time} = time();
			};
                }
		elsif (keys(%{$self->{PIDS}}) < $self->{min_nproc}) 
		{
			# Если количество процессов меньше минимального - добавляем
			$self->pm_notify("increase workers to minimal ".$self->{min_nproc});
			$self->SUPER::n_processes($self->{min_nproc});
			$self->{_last_delta_time} = time();
			$pid = -10;
		}
		elsif (($self->{USED_PROCS} < $self->{min_nproc}) && ((time() - $self->{_last_delta_time}) >= $self->{delta_time}))
		{
			# Если загруженных процессов меньше минимального количества, уменьшаем на delta_nproc до минимального значения

			my $newnp = (($self->{n_processes} - $self->{delta_nproc}) > $self->{min_nproc})? ($self->{n_processes} - $self->{delta_nproc}):$self->{min_nproc};

			if ($newnp != $self->{n_processes})
			{
				$self->pm_notify("decrease workers count to $newnp");

				# В цикле убиваем нужное количество незанятых процессов
				my $i = 0;
				foreach my $dpid (keys %{$self->{PIDS}})
				{
					# Убиваем только если процесс свободен
					if (!defined($self->{USEDPIDS}->{$dpid})) {
						$i++;
						if ($i <= ($self->{n_processes} - $newnp))
						{
							$self->pm_notify("kill worker $dpid");
							kill(SIGKILL, $dpid);
							delete($self->{PIDS}->{$dpid});
						}
						else
						{
							last;
						};
					};
				};
				$self->SUPER::n_processes($newnp);
				$self->{_last_delta_time} = time();
			};
		}
		elsif (keys(%{$self->{PIDS}}) < $self->{n_processes}) 
		{
			# Если количество процессов меньше текущего - добавляем
			$self->pm_notify("increase workers to ".$self->{n_processes});
			$self->{_last_delta_time} = time();
			$pid = -10;
		}
		elsif ($self->{USED_PROCS} >= ($self->{n_processes} - $self->{delta_nproc}))
		{
			# Если количество занятых рабочих процессов больше чем первое меньшее количество процессов относительно текущего, то отдаляем уменьшение процессов на delta_time
			$self->{_last_delta_time} = time();
		};

		if ($pid == 0)
		{
			usleep(100000);
		};
	};

	return $pid;
};

sub pm_pre_dispatch
{
	my $self = shift;
	$self->SUPER::pm_pre_dispatch();

	if (!msgsnd($self->{ipcqueue}, pack("l! l!", 1, $$), IPC_NOWAIT)) {
		print STDERR "Error when execute MSGSND in pm_pre_dispatch\n";
		$self->{msgsenderr} = 1;
	} else {
		$self->{msgsenderr} = 0;
	};

	# Счетчик запросов
	if (!defined($self->{requestcount})) {
		$self->{requestcount} = 1;
	} else {
		$self->{requestcount}++;
	};
};

sub pm_post_dispatch
{
	my $self = shift;

	if (!$self->{msgsenderr}) {
		msgsnd($self->{ipcqueue}, pack("l! l!", 2, $$), 0);
	};

	$self->SUPER::pm_post_dispatch();

	# Если определено максимальное количество запросов и оно превышено - выходим из чайлда
	if (defined($self->{max_requests}) && ($self->{max_requests} ne '') && ($self->{requestcount} >= $self->{max_requests})) {
		if ($self->{pm_loop_used}) {
			$self->{exit_flag} = 1;
		} else {
			# Если в цикле не используется pm_loop - выходим "жестко"
			exit;
		};
	};
};

sub pm_die
{
	my $self = shift;

	msgctl($self->{ipcqueue}, IPC_RMID, 0);

	$self->SUPER::pm_die();
};

sub pm_loop
{
	my $self = shift;

	$self->{pm_loop_used} = 1;

	return(!($self->{exit_flag}));
};

sub pm_notify {
	my ($this,$msg) = @_;
	if (defined($msg)) {
		$msg =~ s/\s*$/\n/;
		my $time = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime(time()));
		print STDERR $time, " - FastCGI: ".$this->role()." (pid $$): ".$msg;
	};
};

1;
