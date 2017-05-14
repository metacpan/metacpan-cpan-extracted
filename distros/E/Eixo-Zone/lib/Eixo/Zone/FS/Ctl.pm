package Eixo::Zone::FS::Ctl;

use strict;
use parent qw(Eixo::Zone::Ctl);

my $MOUNT_CMD;

my $UMOUNT_CMD;

my $MOUNTED_REG = qr/^(\w+)\s+on([^\s]+)\s+type\s+(\w+)\s+\(([^\)]+)\)/;  

BEGIN{

	$MOUNT_CMD = `env which mount`; chomp($MOUNT_CMD); 

	$UMOUNT_CMD = `env which umount`; chomp($UMOUNT_CMD); 

}

#
# tmpfs
#
sub tmpfsCreate{
	my ($self, %data) = @_;

	my $size = $data{size} || '512m';

	my $path = $data{path};

	$self->__mountTmpfs($size, $path);
}

sub procfsCreateAndMount{
	my ($self, %data) = @_;

	$self->__mountProcfs();
	
}

#
# mount
#
sub mount{
	my ($self, %data) = @_;

}

	sub __umount{
		my ($self, $device) = @_;

		$self->runSysWait(

			$UMOUNT_CMD,

			$device
		);
	}

	sub __mounted{
		my ($self) = @_;

		map {

			$_ =~ /$MOUNTED_REG/;

			{

				device=>$1,
	
				path => $2,

				type=>$3,

				params=>$4
			}

		} grep {

			$_ =~ $MOUNTED_REG

		} split(

			/\n/,

			$self->runSysWaitEcho(

				$MOUNT_CMD

			)
		);
	}

	sub __mountTmpfs{
		my ($self, $size, $path) = @_;
		
		$self->runSysWait(

			$MOUNT_CMD,

			'-t',

			'tmpfs',

			'-o',

			"size=$size",

			"tmpfs",

			$path

		);
	}

	sub  __mountProcfs{
		my ($self) = @_;

		$self->runSysWait(


			$MOUNT_CMD, 

			'-t',

			'proc',

			'proc',

			'/proc'

		);

	}

	sub __mountBind{
		my ($self, $old, $new) = @_;

		$self->runSysWait(

			$MOUNT_CMD,

			'-B',

			$old,

			$new
		);
	}
