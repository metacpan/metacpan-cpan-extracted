package Eixo::Zone::Network::Ctl;

use strict;
use parent qw(Eixo::Zone::Ctl);

my $CMD_IP;
my $CMD_BRCTL;
my $CMD_ROUTE;

BEGIN{

	$CMD_IP = `env which ip`; chomp($CMD_IP); 

	unless($CMD_IP){

		die(__PACKAGE__ . ':: not ip command found');
	}

	$CMD_BRCTL = `env which brctl`; chomp($CMD_BRCTL);

	unless($CMD_BRCTL){

		die(__PACKAGE__ . ':: not brctl command found');

	}

	$CMD_ROUTE = `env which route`; chomp($CMD_ROUTE);

	unless($CMD_ROUTE){

		die(__PACKAGE__ . ':: not route command found');
	}

}

#=========================
#	 Links
#=========================

sub link_up_ns{
	my ($self, $name, $ns) = @_;

	my @cmd = $self->link_up($name,'--ns');	

	$self->ns_exec($ns, @cmd);
}

sub link_up{
	my ($self, $name) = @_;

	my $in_ns = grep {$_ eq '--ns'} @_;

	my @cmd = (

		$CMD_IP,

		'link',

		'set',

		'dev',

		$name, 

		'up'

	);

	return @cmd if($in_ns);

	$self->runSysWait(@cmd);
}

sub link_addr_ns{
	my ($self, $name, $net, $ns) = @_;

	my @cmd = $self->link_addr($name, $net, '--ns');	

	$self->ns_exec($ns, @cmd);
}

sub link_addr{
	my ($self, $name, $net) = @_;

	my $in_ns = grep {$_ eq '--ns'} @_;

	my @cmd = (
	
		$CMD_IP,
			
		'addr',

		'add',

		$net,

		'dev',

		$name, 

	);

	return @cmd if($in_ns);

	$_[0]->runSysWait(@cmd);
}

sub link_create{
	my ($self, $name_a, $name_b, $type) = @_;

	$type = $type || 'veth';

	$_[0]->runSysWait(

		$CMD_IP, 

		'link', 
		
		'add', 
	
		$name_a, 

		'type', 

		$type, 

		'peer', 

		'name', 

		$name_b

	);
}

sub link_delete{
	my ($self, $name) = @_;

	$_[0]->runSysWait(

		$CMD_IP, 

		'link',

		'delete',

		$name
	);
}

sub link_exists{
	my ($self, $name) = @_;

	grep { $_->{name} eq $name} $self->link_list;
}


sub link_list{
	my ($self) = @_;

	my $info = $_[0]->runSysWaitEcho($CMD_IP, 'link', 'list');

	map {

		my @parts  = map { $_ =~ s/\:?\s*$//; $_ } split(/\s+/, $_);

		{
			dev => $parts[0],

			name=>$parts[1]

		}

	} grep { $_ =~ /^\s*\d+\:/ } split(/\n/, $info);
}

sub link_setns{
	my ($self, $link, $namespace) = @_;

	$self->runSysWait(


		$CMD_IP,
		
		'link',

		'set',

		$link,

		'netns',

		$namespace

	);

	
}

#=========================
#	 Namespace
#=========================

sub ns_create{
	my ($self, $name) = @_;

	$_[0]->runSysWait($CMD_IP, 'netns', 'add', $name);	
}

sub ns_list{
	my ($self) = @_;

	$_[0]->runSysWaitEcho($CMD_IP, 'netns', 'list');
}

sub ns_delete{
	my ($self, $name) = @_;

	$_[0]->runSysWait($CMD_IP, 'netns', 'delete', $name);
}

sub ns_exec{
	my ($self, $namespace, @cmd) = @_;

	my $method = "runSysWait";

	if(grep { $_ eq '--with_echo'} @_){

		@cmd = grep {$_ ne "--with_echo"} @cmd;

		$method = "runSysWaitEcho";
	}

	$_[0]->$method(

		$CMD_IP,

		'netns',

		'exec',

		$namespace,

		@cmd

	);
}

sub ns_exists{
	my ($self, $namespace) = @_;

	grep {

		$_ eq $namespace

	} split(/\n/, $self->ns_list); 

}

#==============================================
#	      Bridge utilities
#==============================================

sub bridge_create{
	my ($self, $name) = @_;

	my $in_ns = grep {$_ eq '--ns'} @_;

	my @cmd = (

		$CMD_BRCTL,

		'addbr',

		$name
	);

	return @cmd if($in_ns);

	$self->runSysWait(@cmd);
}

sub bridge_create_ns{
	my ($self, $name, $ns) = @_;

	my @cmd = $self->bridge_create($name,'--ns');	

	$self->ns_exec($ns, @cmd);
}

sub bridge_rm{
	my ($self, $name) = @_;

	my $in_ns = grep {$_ eq '--ns'} @_;

	my @cmd = (

		$CMD_BRCTL,

		'delbr',

		$name

	);

	return @cmd if($in_ns);

	$self->runSysWait(@cmd);
}

sub bridge_rm_ns{
	my ($self, $name, $ns) = @_;

	my @cmd = $self->bridge_rm($name,'--ns');	

	$self->ns_exec($ns, @cmd);
}

sub bridge_addif{
	my ($self, $name, $dev) = @_;

	my $in_ns = grep {$_ eq '--ns'} @_;

	my @cmd = (

		$CMD_BRCTL,

		'addif',

		$name, 

		$dev

	); 
	
	return @cmd if($in_ns);
	
	$self->runSysWait(@cmd);
}

sub bridge_addif_ns{
	my ($self, $name, $dev, $ns) = @_;

	my @cmd = $self->bridge_addif($name, $dev, "--ns");

	$self->ns_exec(@cmd);

}

sub bridge_delif{
	my ($self, $name, $dev) = @_;

	$self->runSysWait(

		$CMD_BRCTL,

		'delif',

		$name, 

		$dev

	);

}

sub bridge_exists_ns{
	my ($self, $name, $ns) = @_;

	grep {
		$_->{name} eq $name;

	} $self->bridge_list_ns($ns);
}

sub bridge_exists{
	my ($self, $name) = @_;

	grep {

		$_->{name} eq $name;

	} $self->bridge_list;
}

sub bridge_list_ns{
	my ($self, $ns) = @_;

	$self->bridge_list($ns, "--ns");
}

sub bridge_list{
	my ($self) = @_;

	my ($blank, @l);

	if(grep {$_ eq '--ns'} @_){

		($blank, @l) = split(/\n/, $self->ns_exec($_[1], $CMD_BRCTL, "show", "--with_echo"));
	}
	else{

		($blank, @l) = split(/\n/, $self->runSysWaitEcho($CMD_BRCTL, 'show'));

	}


	my @bridges;
	my $i = -1;

	foreach my $l (@l){

		if($l =~ /([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)?/){

			$bridges[++$i] = {

				name=>$1,
				id=>$2,
				stp=>$3,
				interfaces=>$4 ? [$4] : []
				

			};

		}
		elsif($l =~ /^\s+([^\s]+)\s*$/){

			push @{$bridges[$i]->{interfaces}}, $1;
		}
	}

	@bridges;
}

#=========================
#	  Route
#=========================

sub route_add{
	my ($self, $destiny, $netmask, $dev) = @_;

	my @args;

	$destiny eq 'default' ? push @args, 'default' : push @args, '-net', $destiny;

	$netmask ? push @args, 'netmask', $netmask : undef;

	push @args, 'dev', $dev;

	print join(" ", $CMD_ROUTE, 'add', @args, "\n");

	$self->runSysWait(

		$CMD_ROUTE,

		'add',

		@args

	);
	
}

sub route_del{
	my ($self, $destiny) = @_;

	$self->runSysWait(

		$CMD_ROUTE,

		'del',

		$destiny

	);
}

sub route_exists{
	my ($self, $destiny) = @_;

	map {
	
		$_->{destiny} eq $destiny

	} $self->route_show;
}

sub route_show{
	my ($self) = @_;

	my ($blank, @l) = split(/\n/, $self->runSysWaitEcho($CMD_ROUTE));

	map {

		my ($destiny, $gateway, $genmask, $index, $metric, $ref, $use, $dev) = 

			split(/\s+/, @l);

		{

			destiny=>$destiny,

			gateway=>$gateway,

			genmask=>$genmask,

			index=>$index,

			metric=>$metric,

			ref=>$ref,

			use=> $use,

			dev=>$dev
		}

	} @l;
}


1;
