package Eixo::Zone;

use 5.018002;
use strict;
use warnings;

use Eixo::Zone::Driver;
use Eixo::Zone::Starter;

my @NS = qw(

	user
	pid
	net
	mnt
	uts
	
);

sub create{
	my ($self, %args) = @_;

	Eixo::Zone::Starter->init(%args);
}

# if we dont pass anything, a hash of flags is passed
sub same_namespace{
	my ($self, $pid1, $pid2, $namespace) = @_;

	$namespace = lc($namespace);

	kill(0, $pid1) || die("Eixo::Zone::same_namespace: pid1 ($pid1) doesn't exist");

	kill(0, $pid2) || die("Eixo::Zone::same_namespace: pid1 ($pid2) doesn't exist");

	unless(!$namespace || grep { $_ eq $namespace } @NS) {
		die("Eixo::Zone::same_namespace: $namespace unknown");
	}
	
	if($namespace){

		return $self->__same_namespace($pid1, $pid2, $namespace);
	}

	my %same_namespace;

	foreach(@NS){

		$same_namespace{$_} = $self->__same_namespace($pid1, $pid2, $_);
	}
}

	sub __same_namespace{
		my ($self, $p1, $p2, $namespace) = @_;

		(stat("/proc/$p1/ns/$namespace"))[1] == (stat("/proc/$p2/ns/$namespace"))[1];
	}
1;
__END__

=pod

=head1 NAME

Eixo::Zone - Perl's Linux namespace manipulation tool

=head1 DESCRIPTION

Perl's native Linux namespaces manipulation tool

=head1 Installation

You need a Linux kernel >= 3.12 for namespaces.

You also need brige-utils package for managing network bridges.

=head1 ENTITIES

=head2 Zone

A zone is a set of namespaces clumped together as a entity

=head2 






