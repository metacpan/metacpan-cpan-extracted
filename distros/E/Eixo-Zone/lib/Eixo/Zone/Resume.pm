package Eixo::Zone::Resume;

use strict;

sub new{

	return bless({

		pid=>$_[1],

		__batchs=>[],

		__artifacts=>[],

	});
}

sub artifacts{

	my $a = $_[0]->{__artifacts} || [];

	wantarray ? @$a : $a;

}


sub batch{

	$_->() foreach(@{$_[0]->{__batchs}});

	$_[0];
}

sub addBatch{

	push @{$_[0]->{__batchs}}, $_[1];

}

sub addArtifact{

	push @{$_[0]->{__artifacts}}, $_[1];
}

sub getPSInit{

	my $ps_init = $_[0]->getArtifacts(

		type=>"Eixo::Zone::Artifact::PSInit"
	);	

}

sub getArtifacts{
	my ($self, %args) = @_;

	my @artifacts = @{$_[0]->{__artifacts}};

	if(my $t = $args{type}){

		@artifacts = grep {

			$_->isa($t)

		} @artifacts;
	}

	wantarray ? @artifacts : 

			(@artifacts > 1) ? \@artifacts : 

			$artifacts[0];
}

1;
