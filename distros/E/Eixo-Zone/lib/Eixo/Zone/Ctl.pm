package Eixo::Zone::Ctl;

use strict;

use IPC::Open3;

my $LOG = undef;

sub setLOG { $LOG = 1 }

sub __runSys{
	my ($self, $opc, @cmd) = @_;

	my ($w, $r, $e);

	my $echo;

	print join(" ", @cmd, "\n") if($LOG);

	my $pid = open3($w, $r, $e, @cmd);

	if($opc->{wait}){

		waitpid($pid, 0);

		if($? >> 8){
			die("Error [" . join(' ' , @cmd) . '] ' . join("", <$r>, <$e>));
		}
	}	

	if($opc->{echo}){

		$echo = join('', <$r>);

	}

	return $echo;
}

sub runSysWait{
	my ($self, @cmd) = @_;

	$self->__runSys({wait => 1}, @cmd);
}

sub runSysWaitEcho{
	my ($self, @cmd) = @_;

	$self->__runSys({

		wait => 1,

		echo=>1

	}, @cmd);
}

1;
