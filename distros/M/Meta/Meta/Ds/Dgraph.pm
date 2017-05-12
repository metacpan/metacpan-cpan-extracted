#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Dgraph;

use strict qw(vars refs subs);
use Meta::Ds::Ohash qw();
use Meta::Ds::Oset qw();
use Meta::Utils::Output qw();
use Meta::Utils::Arg qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.13";
@ISA=qw();

#sub new($);
#sub nodes($);
#sub node_size($);
#sub node_has($$);
#sub node_data($$);
#sub node_insert($$$);
#sub node_remove($$);
#sub edges($);
#sub edge_size($);
#sub edge_has($$$);
#sub edge_data($$$);
#sub edge_insert($$$$);
#sub edge_remove($$$);
#sub edge_ou($$);
#sub edge_ou_size($$);
#sub edge_in($$);
#sub edge_in_size($$);
#sub print($$);
#sub numb_cycl($$$);
#sub all_ou($$$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
#	Meta::Utils::Arg::check_arg($class,"SCALAR");
	my($self)={};
	bless($self,$class);
	$self->{NODE}=Meta::Ds::Ohash->new();
	$self->{EDGE}=Meta::Ds::Ohash->new();
	$self->{EDGE_OU}={};
	$self->{EDGE_IN}={};
	return($self);
}

sub nodes($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,1);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
	return($self->{NODE});
}

sub node_size($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,1);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
	return($self->{NODE}->size());
}

sub node_has($$) {
	my($self,$node)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,2);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
	return($self->{NODE}->has($node));
}

sub node_data($$) {
	my($self,$node)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,2);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
	return($self->{NODE}->get($node));
}

sub node_insert($$$) {
	my($self,$node,$data)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,3);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
#	Meta::Utils::Arg::check_arg($data,"ANY");
	if($self->node_has($node)) {
		throw Meta::Error::Simple("graph already has node [".$node."]");
	}
	$self->{NODE}->insert($node,$data);
	$self->{EDGE_OU}->{$node}=Meta::Ds::Oset->new();
	$self->{EDGE_IN}->{$node}=Meta::Ds::Oset->new();
}

sub node_remove($$) {
	my($self,$node)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,2);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
	my($seto)=$self->{EDGE_OU}->{$node};
	$seto->reset();
	while(!$seto->over()) {
		my($curr)=$seto->curr();
		$self->edge_remove($node,$curr);
		$seto->next();
	}
	my($seti)=$self->{EDGE_IN}->{$node};
	$seti->reset();
	while(!$seti->over()) {
		my($curr)=$seti->curr();
		$self->edge_remove($curr,$node);
		$seti->next();
	}
	$self->{EDGE_OU}->{$node}=undef;#remove the edge out
	$self->{EDGE_IN}->{$node}=undef;#remove the edge in
	$self->{NODE}->remove($node);
}

sub edges($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,1);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
	return($self->{EDGE});
}

sub edge_size($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,1);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
	return($self->{EDGE}->size());
}

sub edge_has($$$) {
	my($self,$nod1,$nod2)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,3);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($nod1,"ANY");
#	Meta::Utils::Arg::check_arg($nod2,"ANY");
	$self->{NODE}->check_has($nod1);
	$self->{NODE}->check_has($nod2);
	my($newe)=$nod1.$;.$nod2;
	return($self->{EDGE}->has($newe));
}

sub edge_data($$$) {
	my($self,$nod1,$nod2)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,3);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($nod1,"ANY");
#	Meta::Utils::Arg::check_arg($nod2,"ANY");
	$self->{NODE}->check_has($nod1);
	$self->{NODE}->check_has($nod2);
	my($newe)=$nod1.$;.$nod2;
	return($self->{EDGE}->get($newe));
}

sub edge_insert($$$$) {
	my($self,$nod1,$nod2,$data)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,4);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($nod1,"ANY");
#	Meta::Utils::Arg::check_arg($nod2,"ANY");
#	Meta::Utils::Arg::check_arg($data,"ANY");
	$self->{NODE}->check_has($nod1);
	$self->{NODE}->check_has($nod2);
	if($self->edge_has($nod1,$nod2)) {
		throw Meta::Error::Simple("graph has the edge [".$nod1."][".$nod2."]");
	}
	my($newe)=$nod1.$;.$nod2;
	$self->{EDGE}->insert($newe,$data);
	$self->{EDGE_OU}->{$nod1}->insert($nod2);
	$self->{EDGE_IN}->{$nod2}->insert($nod1);
}

sub edge_remove($$$) {
	my($self,$nod1,$nod2)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,3);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($nod1,"ANY");
#	Meta::Utils::Arg::check_arg($nod2,"ANY");
	$self->{NODE}->check_has($nod1);
	$self->{NODE}->check_has($nod2);
	my($newe)=$nod1.$;.$nod2;
	$self->{EDGE}->check_has($newe);
	$self->{EDGE}->remove($newe);
	$self->{EDGE_OU}->{$nod1}->remove($nod2);
	$self->{EDGE_IN}->{$nod2}->remove($nod1);
}

sub edge_ou($$) {
	my($self,$node)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,2);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
	return($self->{EDGE_OU}->{$node});
}

sub edge_ou_size($$) {
	my($self,$node)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,2);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
	return($self->edge_ou($node)->size());
}

sub edge_in($$) {
	my($self,$node)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,2);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
	return($self->{EDGE_IN}->{$node});
}

sub edge_in_size($$) {
	my($self,$node)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,2);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
	return($self->edge_in($node)->size());
}

sub print($$) {
	my($self,$file)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,2);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($file,"ANY");
	print $file "nodes:\n";
	$self->{NODE}->print($file);
	print $file "edges:\n";
	my($edge)=$self->{EDGE};
	$self->{EDGE}->print($file);
}

sub numb_cycl($$$) {
	my($self,$verb,$file)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,3);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($verb,"ANY");
#	Meta::Utils::Arg::check_arg($file,"ANY");
#	my($unvi)=Meta::Ds::Set::copy("Meta::Ds::Set",$self->nodes());
	my($unvi);
	my($resu)=0;
	while($unvi->size()>0) {
		my($prim)=$unvi->any();
		my($stac)=Meta::Ds::Stack->new();
		my($csta)=Meta::Ds::Stack->new();
		$stac->push($prim);
		while($stac->size()) {
			my($curr)=$stac->pop();
			if($unvi->hasnt($curr)) {
				$resu++;
				if($verb) {
					print $file "cycle [".$curr."]\n";
					print $file "=============\n";
					$csta->print($file);
				}
			} else {
				$unvi->remove($curr);
				$csta->push($curr);
				$stac->push_set($self->edge_ou($curr));
#				$self->node_remove($curr);
			}
		}
	}
	return($resu);
}

sub all_ou($$$$) {
	my($self,$node,$hash,$list)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,4);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Dgraph");
#	Meta::Utils::Arg::check_arg($node,"ANY");
#	Meta::Utils::Arg::check_arg($hash,"HASHref");
#	Meta::Utils::Arg::check_arg($list,"ARRAYref");
	if(!$self->node_has($node)) {
		throw Meta::Error::Simple("don't have the node [".$node."]\n");
	}
	my($edge_ou)=$self->edge_ou($node);
	for(my($i)=0;$i<$edge_ou->size();$i++) {
		my($curr)=$edge_ou->elem($i);
		#Meta::Utils::Output::print("adding [".$curr."]\n");
		if(!defined($hash->{$curr})) {
			$hash->{$curr}=defined;
			push(@$list,$curr);
		}
	}
	for(my($i)=0;$i<$edge_ou->size();$i++) {
		my($curr)=$edge_ou->elem($i);
		$self->all_ou($curr,$hash,$list);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Dgraph - data structure that represents a graph.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Dgraph.pm
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Dgraph qw();
	my($graph)=Meta::Ds::Dgraph->new();
	$graph->node_insert("mark",undef);
	$graph->node_insert("doron",undef);
	$graph->edge_insert("mark","doron",undef);

=head1 DESCRIPTION

This is a library to let you create a graph like data structure.
The library gives services like the n'th node, n'th edge etc...
The graphs are directional.
The extra that this library gives you over the regular Graph.pm
module is that this one can have extra information (whatever you
want) on the nodes and edges of the graph.

=head1 FUNCTIONS

	new($)
	nodes($)
	node_size($)
	node_has($$)
	node_data($$)
	node_insert($$$)
	node_remove($$)
	edges($)
	edge_size($)
	edge_has($$$)
	edge_data($$$)
	edge_insert($$$$)
	edge_remove($$$)
	edge_ou($$)
	edge_ou_size($$)
	edge_in($$)
	edge_in_size($$)
	print($$)
	numb_cycl($$$)
	all_ou($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Dgraph object.

=item B<nodes($)>

Return the set of nodes in the graph.

=item B<node_size($)>

return number of nodes in the graph.

=item B<node_has($$)>

This will return whether the graph has this node or not.

=item B<node_data($$)>

This method retrieves the data associated with the node.

=item B<node_insert($$$)>

Insert a new node into the graph.

=item B<node_remove($$)>

This removes a node with all edges attached

=item B<edges($)>

Return the set of edges in the graph.

=item B<edge_size($)>

Returns number of edges in the graph.

=item B<edge_has($$$)>

This method returns whether there is already an edge in the graph with
the nodes you request.

=item B<edge_data($$$)>

This method retrieves the data object associated with the edge.

=item B<edge_insert($$$$)>

Insert a new edge into the graph.

=item B<edge_remove($$$)>

This removes an edge from the graph (both nodes remain in the graph).

=item B<edge_ou($$)>

This gives you the set of all nodes this edge connects to.

=item B<edge_ou_size($$)>

This gives you how many edges go out of a node.

=item B<edge_in($$)>

This gives you the set of all nodes this edge connects from.

=item B<edge_in_size($$)>

This gives you how many edges go in to a node.

=item B<print($$)>

Print the current graph to a file.
The input is the file to print to.

=item B<numb_cycl($$$)>

This method returns the number of cycles in the graph and acts verbosly
accoding to the flag given to it.
This is also receives the name of the file to be verbose into...

=item B<all_ou($$$$)>

This method will add the nodes which are outwardly connected (recursivly)
to the hash given to it.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV Pdmt stuff
	0.01 MV perl packaging
	0.02 MV PDMT
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV more thumbnail stuff
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Ohash(3), Meta::Ds::Oset(3), Meta::Error::Simple(3), Meta::Utils::Arg(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
