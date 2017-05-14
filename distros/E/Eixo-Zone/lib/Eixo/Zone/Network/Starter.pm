package Eixo::Zone::Network::Starter;

use strict;
use Eixo::Zone::Driver;
use Eixo::Zone::Network::Ctl;

use Eixo::Zone::Artifact::NetworkNS;
use Eixo::Zone::Artifact::NetworkVeth;

sub network_ctl{
	"Eixo::Zone::Network::Ctl";
}

sub init{
	my ($self, $resume, %data) = @_;

	my $n_data= $data{network};

	my $type = $n_data->{type};

	if($type eq 'simple'){
		$self->__initSimple($resume, %$n_data);
	}
}

	sub __initSimple{
		my ($self, $resume, %n_data) = @_;

		# we create a veth
		my $veth = Eixo::Zone::Artifact::NetworkVeth->new(

			$n_data{prefix},

			$self->network_ctl
		);


		$veth->create;

		$resume->addArtifact($veth);		

		# we configure the external extreme
		$veth->up("A");
		$veth->addr($n_data{external_addr}, "A");

		# we configure the inner extreme
		$self->__initSimpleInternalVeth($resume, $veth, %n_data);	

		# we set the correct init flag (if necessary)
		$resume->getPSInit->{SELF_NETWORK} = $n_data{SELF_NETWORK};
	
	}

		sub __initSimpleInternalVeth{
			my ($self, $resume, $veth, %n_data) = @_;

			#----------------------
			# addr asignation
			#----------------------
			my $f_addr = sub {

				if(my $addr = $n_data{internal_addr}){

					$veth->up("B");

					$veth->addr($addr, "B");
	
				}

			};

			#-----------------------
			# namespace asignation
			#-----------------------

			# existing namespace (easy)
			if(my $net_ns = $n_data{net_join}){

				$veth->setns($net_ns, "B");

				$f_addr->();
			}
			else{
				
				my $net_ns = $n_data{net_ns};

				if($net_ns eq "self"){

					$net_ns = "net_" . &Eixo::Zone::Driver::getPid;

				}

				# we need to create a new network namespace
				$self->__initNamespace($resume, $net_ns);

				$resume->addBatch(sub {

					# we join it
					$veth->setns($net_ns, "B");

					# addr configuration
					$f_addr->();

				});
				
			}
			

		}


sub __initNamespace{
	my ($self, $r, $net_ns, %n_data) = @_;

	$net_ns = Eixo::Zone::Artifact::NetworkNS->new(

			$net_ns,

			$self->network_ctl

	);

	$r->addArtifact($net_ns);

	$net_ns->create;

}


1;
