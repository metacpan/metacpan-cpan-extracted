package Lingua::YaTeA::NodeSet;

use strict;
use warnings;

use UNIVERSAL;
use Scalar::Util qw(blessed);

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{  
    my ($class) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{ROOT_NODE} = ();
    $this->{NODES} = [];
    return $this;
}



sub addNode
{
    my ($this,$node) = @_;
    push @{$this->{NODES}}, $node; 
    $this->updateRoot;
}

sub getNodes
{
    my ($this) = @_;
    return $this->{NODES};
}


sub setRoot
{
    my ($this) = @_;
    my $node;
    foreach $node (@{$this->getNodes})
    {
	if ((blessed($node)) && ($node->isa('Lingua::YaTeA::RootNode')))
	{
	    $this->{ROOT_NODE} =  $node;
	    return;
	} 
    }
    die "No root node\n";
}


sub getRoot
{
    my ($this,$root) = @_;
    return $this->{ROOT_NODE}; 

}



sub getNode
{
    my ($this,$index) = @_;
    return $this->getNodes->[$index];
}

sub updateRoot
{
    my ($this) = @_;
    my %nodes_id;
    my $node;
    foreach $node (@{$this->getNodes})
    {
	$nodes_id{$node->getID}++;
    }

    if(scalar @{$this->getNodes} == 0)
    {
	undef $this->{ROOT_NODE};
    }
    else
    {
	if
	    (
	     (!defined $this->getRoot)
	     ||
	     (!exists $nodes_id{$this->getRoot->getID})
	     ||
	     ((blessed($this->getRoot)) && (!$this->getRoot->isa('Lingua::YaTeA::RootNode')))
	    )
	{
	    
	    $this->setRoot;
	}
    }
}



sub copy
{
    my ($this) = @_;
    my $new_set = Lingua::YaTeA::NodeSet->new;
    my $node = $this->getRoot;
    my $depth = 0;

    $node->copyRecursively($new_set, $depth);
    $this->addFreeNodes($new_set);
    return $new_set;
}

sub addFreeNodes
{
    my ($this,$new_set) = @_;
    my $node;
   
    foreach $node (@{$this->getNodes})
    {
	
	if ((blessed($node)) && ($node->isa('Lingua::YaTeA::RootNode'))
	    &&
	    ($node ne $this->getRoot)
	    )
	    
	{
	    $node->copyRecursively($new_set);
	}
    }

}

sub fillNodeLeaves
{
    my ($this,$index_set) = @_;
    my $counter = 0;
  
    $this->getRoot->fillLeaves(\$counter,$index_set, 0);
}



sub updateLeaves
{
    my ($this,$index_set) = @_;
    my $counter = 0;
    $this->getRoot->updateLeaves(\$counter,$index_set);
}

sub searchFreeNodes
{
  my ($this,$words_a) = @_;
  my $node;
  my @free_nodes;
 
  #  print STDERR "sFN1\n";

  foreach $node (@{$this->getNodes})
  {
  #  print STDERR "sFN2\n";
      if((blessed($node)) && ($node->isa('Lingua::YaTeA::RootNode')))
      {
	  push @free_nodes, $node;	  
      }
  }

  #  print STDERR "sFN3\n";

  return \@free_nodes;
}



sub removeNodes{
    my ($this,$root_node,$words_a,$fh) = @_;
    my @tmp;
    my $node;
    my @unplugged;
    my $previous;
    while ($node = pop @{$this->getNodes})
    {
	if($node->getID == $root_node->getID)
	{
	    if ((blessed($node)) && ($node->isa('Lingua::YaTeA::InternalNode')))
	    {
		if(
		    (blessed($node->getFather->getLeftEdge)) && ($node->getFather->getLeftEdge->isa('Lingua::YaTeA::InternalNode' )
		     &&
		     ($node->getFather->getLeftEdge->getID == $node->getID)
		    )
		    )
		   
		{
		    $node->{FATHER}->{LEFT_EDGE} = $node->searchHead(0);
		}
		else
		{
		    if(
			(blessed($node->getFather->getRightEdge)) && ($node->getFather->getRightEdge->isa('Lingua::YaTeA::InternalNode' )
			 &&
			 ($node->getFather->getRightEdge->getID == $node->getID)
			)
			)
			
		    {
			$node->{FATHER}->{RIGHT_EDGE} = $node->searchHead(0);
		    }
		}
	    }
	    if ((blessed($node->getLeftEdge)) && ($node->getLeftEdge->isa('Lingua::YaTeA::Node')))
	    {
#		print $fh "rebless left:" . $node->getLeftEdge->getID . "\n";
		undef $node->getLeftEdge->{FATHER};
		bless($node->getLeftEdge,'Lingua::YaTeA::RootNode');
		$previous = -1;
		if($node->getLeftEdge->isDiscontinuous(\$previous,$words_a,$fh)->[0] == -1)
		{
		    push @unplugged,$node->getLeftEdge;
		}
		$node->{LEFT_EDGE} = $node->getLeftEdge->searchHead(0);
		
	    }
	    if ((blessed($node->getRightEdge)) && ($node->getRightEdge->isa('Lingua::YaTeA::Node')))
	    {
#		print $fh "rebless right:" . $node->getRightEdge->getID . "\n";
		undef $node->getRightEdge->{FATHER};
		bless($node->getRightEdge,'Lingua::YaTeA::RootNode');
#		$node->getRightEdge->printRecursively($words_a,$fh);
		$previous = -1;
		if($node->getRightEdge->isDiscontinuous(\$previous,$words_a,$fh)->[0] == -1)
		{
		    push @unplugged,$node->getRightEdge;
		}
		$node->{RIGHT_EDGE} = $node->getRightEdge->searchHead(0);
	    }
	}
	else
	{
	    push @tmp,$node;
	}
    }
    
    
    @{$this->getNodes} = @tmp;
    $this->updateRoot;
    return \@unplugged;
}



sub hitchMore
{
    my ($this,$added_node_set,$added_index_set,$words_a,$fh) = @_;
    my $free_nodes_a = $this->searchFreeNodes($words_a);
    my $node;
    my $pivot;
    my $hook_node;
    my $hook_place;
    my $below;
    my %integrated;

    if(scalar @$free_nodes_a != 0)
    {
	foreach $node (@$free_nodes_a)
	{
	    
	    if(
		($node != $added_node_set->getNode(0)->searchRoot)
		&&
		(!exists $integrated{$node->getID})
		)
	    {
		$pivot = $node->searchHead(0)->getIndex;
		if($added_index_set->getLast == $pivot)
		{
		    ($hook_node,$hook_place) = $node->getNodeOfLeaf($pivot,$added_index_set->getFirst,$words_a);
		}
		else
		{
		    if($added_index_set->getFirst == $pivot)
		    {
			($hook_node,$hook_place) = $node->getNodeOfLeaf($pivot,$added_index_set->getLast,$words_a);
		    }
		}
	
		if ((blessed($hook_node)) && ($hook_node->isa('Lingua::YaTeA::Node')))
		{
		    if($hook_node->hitch($hook_place,$added_node_set->getRoot,$words_a))
		    {
			
			$integrated{$added_node_set->getRoot->getID}= 1;
		    }
		}
	    }
	}
    }
}


sub findHierarchy
{
    my ($this,$pivot,$added_index_set,$added_node_set) = @_;
    my $node;
    my $pivot_node;
    my $pivot_place;
    my $left_most;
    my $right_most;
    my $recorded;
    my $depth = 0;
  
    foreach $node (@{$this->getNodes})
    {
	$depth = 0;
	if ((blessed($node)) && ($node->isa('Lingua::YaTeA::RootNode')))
	{
	    ($pivot_node,$pivot_place) = $node->searchLeaf($pivot,\$depth);
	    
	    if ((blessed($pivot_node)) && ($pivot_node->isa('Lingua::YaTeA::Node')))
	    {
		$left_most = $node->searchLeftMostLeaf;
		$depth = 0;
		$right_most = $node->searchRightMostLeaf(\$depth);
		$recorded = $node;
		last;
	    }
	}
    }

    if(
	(defined $left_most)
	&& 
	(defined $right_most)
	)
    {
	if($right_most->getIndex == $added_index_set->getLast)
	{
	    if($left_most->getIndex > $added_index_set->getFirst)
	    {
		($pivot_node,$pivot_place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
		return ($pivot_node,$pivot_place,$recorded);
	    }
	    if($left_most->getIndex < $added_index_set->getFirst)
	    {
		return ($pivot_node,$pivot_place,$added_node_set->getRoot);
	    }
	    die "not defined";
	}

	if($right_most->getIndex == $added_index_set->getFirst)
	{
	    ($pivot_node,$pivot_place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
	    return ($pivot_node,$pivot_place,$recorded);
	}

	if($left_most->getIndex == $added_index_set->getLast)
	{
	   
	    if($added_node_set->getRoot->searchHead(0)->getIndex == $left_most->getIndex)
	    {
		return ($pivot_node,$pivot_place,$added_node_set->getRoot);
	    }
	    else
	    {
		($pivot_node,$pivot_place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
		return ($pivot_node,$pivot_place,$recorded);
	    }
	}

	if($left_most->getIndex == $added_index_set->getFirst)
	{
	    if($right_most->getIndex > $added_index_set->getLast)
	    {
		return ($pivot_node,$pivot_place,$added_node_set->getRoot);
	    }
	    if($right_most->getIndex < $added_index_set->getLast)
	    {
		($pivot_node,$pivot_place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
		return ($pivot_node,$pivot_place,$recorded);
	    }
	}
	if($left_most->getIndex > $added_index_set->getFirst)
	{
	    if($right_most->getIndex < $added_index_set->getLast)
	    {
		($pivot_node,$pivot_place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
		return ($pivot_node,$pivot_place,$recorded);
	    }
	    else
	    {
		($pivot_node,$pivot_place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
		return ($pivot_node,$pivot_place,$recorded);
	    }
	    die "not defined";
	}

	if($left_most->getIndex < $added_index_set->getFirst)
	{
	    if($right_most->getIndex > $added_index_set->getLast)
	    {
		return ($pivot_node,$pivot_place,$added_node_set->getRoot->searchLeftMostNode);  
	    }
	    if($recorded->searchHead(0)->getIndex == $pivot)
 	    {
		
 		($pivot_node,$pivot_place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
 		return ($pivot_node,$pivot_place,$recorded);
 	    }
	    else
	    {
		return;
	    }
	}
	die "not defined";
    }
}


sub getNodeWithPivot
{
    my ($this,$pivot) = @_;
    my $node;
     
    foreach $node (@{$this->getNodes})
    {
	if (
	    (blessed($node->getLeftEdge)) && ($node->getLeftEdge->isa('Lingua::YaTeA::TermLeaf'))
	    &&
	    ($node->getLeftEdge->getIndex == $pivot)
	    )
	    
	{
	    return ($node,"LEFT");
	}

	if (
	    (blessed($node->getRightEdge)) && ($node->getRightEdge->isa('Lingua::YaTeA::TermLeaf'))
	    &&
	    ($node->getRightEdge->getIndex == $pivot)
	    )
	    
	{
	    return ($node,"RIGHT");
	}
    }
    
    return;
}



sub addNodes
{
    my ($this,$node_set) = @_;
    my $node;
    foreach $node (@{$node_set->getNodes})
    {
	$this->addNode($node);
    }
}




sub print
{
    my ($this,$words_a,$fh) = @_;
    if(scalar @{$this->getNodes} != 0)
    {
	if(defined $fh)
	{
	    if(defined $this->getRoot)
	    {
		print $fh "ROOT_NODE :" . $this->getRoot->getID . "\n";
	    }
	    else
	    {
		print $fh "ROOT_NODE :NO ROOT NODE\n";
	    }
	    print $fh "NODES : \n"; 
	    $this->getRoot->printRecursively($words_a,$fh);
	}
	else
	{
	    if(defined $this->getRoot)
	    {
		print "ROOT_NODE :" . $this->getRoot->getID . "\n";
	    }
	    else
	    {
		print "ROOT_NODE :NO ROOT NODE\n";
	    }
	    print "NODES : \n"; 
	    $this->getRoot->printRecursively($words_a);
	}
    }
    else
    {
	if(defined $fh)
	{
	    print $fh "NodeSet is empty\n";
	}
	else
	{
	    print "NodeSet is empty\n";
	}
    }
}


sub printAllNodes
{
    my ($this,$words_a,$fh) = @_;
    my $node;
    if(!defined $fh)
    {
	$fh = \*STDERR;
    }
     if(defined $this->getRoot)
     {
	 print $fh "ROOT_NODE :" . $this->getRoot->getID . "\n";
     }
    else
    {
	print $fh "ROOT_NODE :NO ROOT NODE\n";
    }
    print $fh "NODES : \n"; 

    foreach $node (@{$this->getNodes})
    {
	$node->printSimple($words_a,$fh);
    }
    print $fh "\n";
}


sub printParenthesised
{
    my ($this,$words_a,$fh) = @_;
    my $analysis = "";

#    print STDERR $this->getRoot;
     if(defined $fh)
    {
	$this->getRoot->buildParenthesised(\$analysis,$words_a);
	print $fh $analysis . "\n";
    }
    else
    {
	$this->getRoot->buildParenthesised(\$analysis,$words_a);
	print $analysis . "\n";
    }
}

sub searchRootNodeForLeaf
{
    my ($this,$index) = @_;
    my ($node,$place) = $this->getNodeWithPivot($index);
    if (defined $node) {
	return $node->searchRoot;
    } else {
	return ;
    }
}

sub fillIndexSet
{
    my ($this,$index_set) = @_;
    my $node;
    
    foreach $node (@{$this->getNodes})
    {
	if ((blessed($node)) && ($node->isa('Lingua::YaTeA::RootNode')))
	{
	    $node->fillIndexSet($index_set);
	}
    }
    $index_set->removeDoubles;
}

sub searchHeads
{
    my ($this,$words_a) = @_;
    my %heads;
    my $root;
    my $root_head;
    my $free_nodes_a = $this->searchFreeNodes($words_a);

    foreach $root (@$free_nodes_a)
    {
	$root_head = $root->searchHead(0);
	if ((defined $root_head)&&((blessed($root_head)) && ($root_head->isa('Lingua::YaTeA::TermLeaf')))) {
	    $heads{$root_head->getIndex}++;
	}
    }
    return \%heads;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::NodeSet - Perl extension for ???

=head1 SYNOPSIS

  use Lingua::YaTeA::NodeSet;
  Lingua::YaTeA::NodeSet->();

=head1 DESCRIPTION


=head1 METHODS

=head2 new()


=head2 addNode()


=head2 getNodes()


=head2 setRoot()


=head2 getRoot()


=head2 getNode()


=head2 updateRoot()


=head2 copy()


=head2 addFreeNodes()


=head2 fillNodeLeaves()


=head2 updateLeaves()


=head2 searchFreeNodes()


=head2 removeNodes{()


=head2 hitchMore()


=head2 findHierarchy()


=head2 getNodeWithPivot()


=head2 addNodes()


=head2 print()


=head2 printAllNodes()


=head2 printParenthesised()


=head2 searchRootNodeForLeaf()


=head2 fillIndexSet()


=head2 searchHeads()


=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
