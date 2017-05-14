package Eixo::Zone::Starter;

#
# Initialization Routine
#
use strict;
use Eixo::Zone::Resume;

use Eixo::Zone::FS::Ctl;
use Eixo::Zone::Driver;

use Eixo::Zone::Artifact::PSInit;
use Eixo::Zone::Artifact::FSVolumeTmp;
use Eixo::Zone::Artifact::FSVolumeProc;


use Eixo::Zone::Network::Starter;

sub ctl_fs{
	"Eixo::Zone::FS::Ctl"
}

sub ctl_ps{
	"Eixo::Zone::Driver";
}

sub init{
	my ($self, %args) = @_;

	my $r = Eixo::Zone::Resume->new();

	my $starter = $self->__initInit($r, %args);

	$self->__initVolumes($r, %args);

	$self->__initNetwork($r, %args);

	($starter) ? $starter->() : $r->batch();

}

sub __initInit{
	my ($self, $r, %args) = @_;

	return unless($args{init});

	my $ps_init = Eixo::Zone::Artifact::PSInit->new(

		sub {

			$r->batch;

			$args{init}->();

		},

		$r,

		$self->ctl_ps
	);

	$r->addArtifact($ps_init);

	my %args_init = ();

	$args_init{MOUNTS} = 1 if($args{volumes});

	sub {
		$ps_init->start(%args_init);

		$r->{pid} = $ps_init->{pid};

		$r;
	}
}

sub __initNetwork{
	my ($self, $r, %args) = @_;

	return unless($args{network});

	Eixo::Zone::Network::Starter->init(

		$r,

		%args

	);
}

sub __initVolumes{
	my ($self, $r, %args) = @_;

	if($args{self_proc}){
		$self->__initProc($r, %args);
	}

	foreach my $path (keys %{$args{volumes}}){

		$self->__initVolume($r, $path, %{$args{volumes}->{$path}});
	}

}

sub __initVolume{
	my ($self, $r,$path, %data) = @_;

	return $self->__initVolumeTmp($r, $path, %data) if($data{type} eq  'tmpfs');

	return $self->__initVolumeProc($r, $path, %data) if($data{type} eq  'procfs');

}

sub __initVolumeTmp{
	my ($self, $r, $path, %data) = @_;

	my $tmp_volume;

	$r->addArtifact(

		$tmp_volume = Eixo::Zone::Artifact::FSVolumeTmp->new(

			size=>$data{size},	

			path=>$path,

			ctl=>$self->ctl_fs

		)

	);	

	$r->addBatch(sub {

		$tmp_volume->mount;

	});
}

sub __initVolumeProc{
	my ($self, $r, $path, %data) = @_;

	my $proc_volume;

	$r->addArtifact(

		$proc_volume = Eixo::Zone::Artifact::FSVolumeProc->new(

			size=>$data{size},

			path=>$path,

			ctl=>$self->ctl_fs

		)

	);

	$r->addBatch(sub {

		$proc_volume->mount

	});
}

1;
