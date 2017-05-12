package Lingua::YaTeA::Tree;
use strict;
use warnings;
use Lingua::YaTeA::IndexSet;
use UNIVERSAL;
use Scalar::Util qw(blessed);

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{NODE_SET} = ();
    $this->{HEAD} = ();
    $this->{RELIABILITY} = ();
    $this->{INDEX_SET} = Lingua::YaTeA::IndexSet->new();
    $this->{SIMPLIFIED_INDEX_SET} = Lingua::YaTeA::IndexSet->new();
    return $this;
}


sub setHead
{
    my ($this) = @_;

    my $root = $this->getNodeSet->getRoot;
    $this->{HEAD} = $root->searchHead(0);
}



sub setReliability
{
    my ($this,$reliability) = @_;
    $this->{RELIABILITY} = $reliability;
}



sub fillNodeLeaves
{
    my ($this) = @_;
    $this->getNodeSet->fillNodeLeaves($this->getIndexSet);
}

sub getIndexSet
{
    my ($this) = @_;
    return $this->{INDEX_SET};
}

sub getNodeSet
{
    my ($this) = @_;

#     print STDERR "gNS1\n";

    return $this->{NODE_SET};
}


sub setSimplifiedIndexSet
{
    my ($this,$original) = @_;
    $this->{SIMPLIFIED_INDEX_SET} = $original->copy;
}

sub copy
{
    my ($this) = @_;
    my $new = Lingua::YaTeA::Tree->new;
    if(defined $this->getNodeSet)
    {
	$new->{NODE_SET} = $this->getNodeSet->copy;
    	$new->{HEAD} = $new->setHead;
    }
    $new->{INDEX_SET} = $this->getIndexSet->copy;
    $new->{SIMPLIFIED_INDEX_SET} = $this->getSimplifiedIndexSet->copy;
    return $new;
}


sub getSimplifiedIndexSet
{
    my ($this) = @_;
    return $this->{SIMPLIFIED_INDEX_SET};
}


sub getRoot
{
    my ($this) = @_;
    return $this->getNodeSet->getRoot;
}

sub updateRoot
{
    my ($this) = @_;
    $this->getNodeSet->updateRoot;
}





sub setNodeSet
{
    my ($this,$node_set) = @_;
    $this->{NODE_SET} = $node_set;
}


sub addNodes
{
    my ($this,$node_set) = @_;
    $this->getNodeSet->addNodes($node_set);
   
}



sub print
{
    my ($this,$words_a,$fh) = @_;
    if(!defined $fh)
    {
	$fh = \*STDERR;
    }
    print $fh $this . "\n";
    print $fh "index set ";
    $this->getIndexSet->print($fh);
    print $fh "\n";
    if(defined $this->getSimplifiedIndexSet)
    {
	print $fh "simplified index set ";
	$this->getSimplifiedIndexSet->print($fh);
	print $fh "\n";
    }
    print $fh "node set : ";
    if(defined $this->getNodeSet)
    {
	$this->getNodeSet->printAllNodes($words_a,$fh);
    }
}


sub printParenthesised
{
    my ($this,$words_a,$fh) = @_;
   # print "(" . $this . ")";
    $this->getNodeSet->printParenthesised($words_a,$fh);
}


sub getHead
{
    my ($this) = @_;
    return $this->{HEAD};
}

sub getReliability
{
    my ($this) = @_;
    return $this->{RELIABILITY};
}

sub setIndexSet
{
    my ($this,$original) = @_;
    $this->{INDEX_SET} = $original->copy;
}

sub check
{
    my ($this,$phrase) = @_;
    my $if;
    my $depth = 0;

    $this->getRoot->buildIF(\$if,$phrase->getWords, \$depth);
    $if =~ s/ +$//;
    
    if($if eq $phrase->getIF)
    {
	return 1;
    }
    else
    {
#	print "Arbre mal forme :" .$if . "\n";
# 	$this->getNodeSet->printAllNodes($phrase->getWords);
 	warn "\nArbre mal forme :\'" .$if . "\' pour \'" . $phrase->getIF."\'\n";
	return 0;
    }
}

sub getIncludedNodes
{
    my ($this,$free_nodes_a,$parsing_direction) = @_;
    my $node;
    my $index_set;
    my %index_key_to_nodes;
    my @index_sets;
    my $included_a;
    my $included;
    my @node_inclusions;
    foreach $node (@$free_nodes_a)
    {
	$index_set = Lingua::YaTeA::IndexSet->new;
	$node->fillIndexSet($index_set);
	$index_key_to_nodes{$index_set->joinAll('-')} = $node;
	push @index_sets, $index_set;
    }   
    foreach $index_set (@index_sets)
    {
	$included_a = $index_set->getIncluded(\@index_sets,$parsing_direction);
	foreach $included (@{$included_a})
	{
	    my @pair;
	    $pair[0] = $index_key_to_nodes{$index_set->joinAll('-')};
	    $pair[1] = $index_key_to_nodes{$included->joinAll('-')};
	    ($pair[2],$pair[3]) = $index_set->getIncludedContext($included);
	    push @node_inclusions,\@pair;
	}
    }
    
    return \@node_inclusions;
}

sub plugNodePairs
{
    my ($this,$parsing_pattern_set,$parsing_direction,$tag_set,$words_a,$fh) = @_;
    my $free_nodes_a;
    my $inclusions_a;
    my $pair_a;
    my $above;
    my $below;
    my $success;
    my $additional_node_set;
#    $this->print($words_a,$fh);
    $free_nodes_a = $this->getNodeSet->searchFreeNodes();
    if(scalar @$free_nodes_a  > 1)
    {
#	print $fh "NB FREE: ". scalar @$free_nodes_a . "\n";
	$inclusions_a = $this->getIncludedNodes($free_nodes_a,$parsing_direction);
	
	foreach $pair_a (@$inclusions_a)
	{
	    $above = $pair_a->[0];
	    $below = $pair_a->[1];
	   
	    ($success,$additional_node_set) = $above->plugInternalNode($below,$pair_a->[2],$pair_a->[3],$parsing_pattern_set,$words_a,$parsing_direction,$tag_set,$fh);
	    if($success == 1)
	    {
		$this->addNodes($additional_node_set);
		
		$this->getSimplifiedIndexSet->removeIndex($pair_a->[1]->searchHead(0)->getIndex);
		$this->updateRoot;
#		print $fh "accrochage reussi\n";
		return 1;
	    }
	  #   else
# 	    {
# 		print $fh "accrochage impossible\n";
# 	    }
	}
	##### TODO: tenter d'accrocher des sous-arbres adjacents ou proches: il existe un patron pour TeteArbre1 [trou: ex: "of a"] TeteArbre2
    }
    return 0;
}



sub completeDiscontinuousNodes
{
    my ($this,$parsing_pattern_set,$parsing_direction,$tag_set,$words_a,$fh) = @_;
    my $previous = -1;
    my $discontinuous_infos_a;
    my $free_nodes_a = $this->getNodeSet->searchFreeNodes($words_a);
    my $discontinuous_nodes_a = $this->getDiscontinuousNodes($free_nodes_a,$words_a,$fh);
    
    foreach $discontinuous_infos_a (@$discontinuous_nodes_a)
    {
	$previous = $discontinuous_infos_a->[1];
	$discontinuous_infos_a = $discontinuous_infos_a->[0]->isDiscontinuous(\$previous,$words_a,$fh);
	if ((blessed($discontinuous_infos_a->[0])) && ($discontinuous_infos_a->[0]->isa('Lingua::YaTeA::Node')))
	{
# 	    print $fh "dis_a : ". join ("\n",@$discontinuous_infos_a) . "\n";
# 	    print $fh "id:" . $discontinuous_infos_a->[0]->getID . "\n";
# 	    $this->print($words_a,$fh);
   
	    if($discontinuous_infos_a->[0]->completeGap($discontinuous_infos_a->[1], $discontinuous_infos_a->[2],$this,$parsing_pattern_set,$parsing_direction,$tag_set,$words_a,$fh) == 1)
	    {
# 		print $fh  "completeGap pour " . $discontinuous_infos_a->[0]->getID . " est OK\n";
# 		$this->print($words_a,$fh);
		$previous = -1;
		if(
		   ($discontinuous_infos_a = $discontinuous_infos_a->[0]->isDiscontinuous(\$previous,$words_a,$fh))
		   &&
		   ((blessed($discontinuous_infos_a->[0])) && ($discontinuous_infos_a->[0]->isa('Lingua::YaTeA::Node')))
		   )
		{
#		    print $fh "push : " . $discontinuous_infos_a->[0]->getID . "\n";
		    push @$discontinuous_nodes_a,$discontinuous_infos_a;
		}
	    } 
	}
    }
}

sub getDiscontinuousNodes
{
    my ($this,$free_nodes_a,$words_a,$fh) = @_;
    my $free_node;
    my $previous = -1;
    my $discontinuous_infos_a;
    my @discontinuous;

    foreach $free_node (@$free_nodes_a)
    {
	$previous = -1;
	$discontinuous_infos_a = $free_node->isDiscontinuous(\$previous,$words_a,$fh);
	if ((blessed($discontinuous_infos_a->[0])) && ($discontinuous_infos_a->[0]->isa('Lingua::YaTeA::Node'))){
	    push @discontinuous,$discontinuous_infos_a;
	}
    }
    return \@discontinuous;
   

}

sub removeDiscontinuousNodes
{
    my ($this,$words_a,$fh) = @_;
    my $discontinuous;
    my $modified = 0;
    my @unplugged;
#    print $fh "tree id: ". $this ."\n";
    my $discontinuous_nodes_a = $this->getDiscontinuousNodes($this->getNodeSet->getNodes,$words_a,$fh);
    while (scalar @$discontinuous_nodes_a != 0)
    {
	foreach $discontinuous (@$discontinuous_nodes_a)
	{
#	    print $fh "discon a degager " .$discontinuous->[0]->getID . "\n";
#	    $discontinuous->[0]->printRecursively($words_a,$fh);
	    
	    push @unplugged, @{$this->getNodeSet->removeNodes($discontinuous->[0],$words_a,$fh)};
	    $modified = 1;
	}
	$discontinuous_nodes_a = $this->getDiscontinuousNodes($this->getNodeSet->getNodes,$words_a,$fh);
    }

    $this->updateRoot;
  
    return ($modified,\@unplugged);
}




sub integrateIslandNodeSets
{
    my ($this,$node_sets,$index_set,$new_trees_a,$words_a,$tagset,$fh) = @_;
    my $to_add;
    my $save;
    my $tree;
    my $i;
    my $integrated = 0;
    my @new_trees;
#     print $fh "index set a integrer :";
#     $index_set->print($fh);
#     print $fh "\nsimplifie :";
#     $this->getSimplifiedIndexSet->print($fh);
#     print $fh "\n";

    if(! $index_set->moreThanOneInCommon($this->getIndexSet))
    {
	if(scalar @$node_sets > 1)
	{
	    $save = $this->copy;
	}
	
	
	for ($i=0; $i < scalar @$node_sets; $i++)
	{
	    if($i == 0)
	    {
		$tree = $this;
	    }
	    else
	    {
		$tree = $save->copy;
	    }
	    
	    $to_add = $node_sets->[$i]->copy;

	    $to_add->getRoot->linkToIsland;
	    if($tree->append($to_add,$index_set,$new_trees_a,$words_a,$tagset,$fh))
	    {
		$integrated = 1;
	# 	print $fh "RES/\n";
# 		$tree->getNodeSet->printAllNodes($words_a,$fh);
	    }
	    else
	    {
		push @$new_trees_a, $tree;
	    }
	}
	
    }
    else
    { # islands are incompatible
	push @$new_trees_a, $this;
    }
    return ($integrated);
}

sub append
{
    my ($this,$added_node_set,$added_index_set,$concurrent_trees_a,$words_a,$tagset,$fh) = @_;
    my $addition = 0;
    my $pivot;
    my $mode;
    my $root;
    my $index_set;
    my $modified = 0;
 #    print $fh "append: " . $this . " \n";
#     $added_node_set->print($words_a,$fh);
#     print $fh "DANS\n";
    
    if(!defined $this->getNodeSet)
    {
	$this->setNodeSet($added_node_set);
	$pivot = -1;
	if ($this->getSimplifiedIndexSet->simplify($added_index_set,$added_node_set,$this,$pivot) == -1 ) {return -1;}
	push @$concurrent_trees_a, $this;
	return 1;
    }
 #   $this->getNodeSet->print($words_a,$fh);
#     print STDERR "a1\n";
    
    # if($added_index_set->testSyntacticBreakAndRepetition($words_a,$tagset))
#     {

	
	$pivot = $added_node_set->getRoot->searchHead(0)->getIndex;
# 	print $fh "pivot :" . $pivot . "\n";
# 	print $fh "a chercger dans ";
# 	$this->getIndexSet->print($fh);
# 	print STDERR "a2\n";
	if(! $this->getIndexSet->indexExists($pivot))
	{
	    $pivot = $this->getIndexSet->searchPivot($added_index_set);
	}
# 	print STDERR "a3\n";
	if(defined $pivot)
	{
	    $index_set = Lingua::YaTeA::IndexSet->new;
	    $root = $this->getNodeSet->searchRootNodeForLeaf($pivot);
	    
	    if (defined $root) { # Added by Thierry 02/03/2007
# 		warn "==> $root\n";
#		print $fh "tourve root :" .$root->getID . "\n";
		$root->fillIndexSet($index_set);
	    }
	}
	else
	{
	    $index_set = $this->getIndexSet;
	}
	#  print STDERR "a4\n";

# 	warn "===>$index_set\n";
	$mode = $index_set->defineAppendMode($added_index_set,$pivot,$fh);

	#  print STDERR "a5\n";

# 	warn "<<<<\n";
	if(defined $mode)
	{
#	    print $fh "mode :" .$mode. "\n";
	    #  print STDERR "$mode\n";

	    if($mode eq "DISJUNCTION")
	    {
#		print $fh "disjuncted\n";
		($modified,$addition) = $this->appendDisjuncted($added_node_set,$fh);	
	    }
	    else
	    {
		if($mode =~ /INCLUSION/)
		{
#		    print $fh "inclusion\n";
		    ($modified,$addition) = $this->appendIncluded($mode,$root,$index_set,$added_node_set,$added_index_set,$pivot,$words_a,$fh);	
		    
		}
		else
		{
		    if($mode =~ /ADJUNCTION/)
		    {
#			 print $fh "adjuction\n";
			($modified,$addition) = $this->appendAdjuncts($root,$index_set,$added_node_set,$added_index_set,$pivot,$concurrent_trees_a,$words_a,$fh);	
			if ($addition == -1) {return -1;}
		    }
		}
	    }
	    if($modified == 1)
	    {
		if ($this->getSimplifiedIndexSet->simplify($added_index_set,$added_node_set,$this,$pivot,$fh) == -1) {return -1;}  
#		print $fh "push " . $this . "\n";
		push @$concurrent_trees_a, $this;
	    }
	}
	
   #  }
#     else
#     {
# 	print $fh "passe pas le syntactic break\n";
#     }
    
    if($addition == 1)
    {
	
	return 1;
    }
    return 0;
}



sub appendAdjuncts
{
    my ($this,$root,$index_set,$added_node_set,$added_index_set,$pivot,$concurrent_trees_a,$words_a,$fh) = @_;
    my $type;
    my $place;
    my $above;
    my $root2;
    my $tree_save = $this->copy;
    my $added_save = $added_node_set->copy;
    my $sub_index_set_save = $index_set->copy;
    my $added_index_set_save = $added_index_set->copy;
    my $depth = 0;
    my $appended = 0;
    my $modified = 0;
    if($added_node_set->getRoot->searchHead(0)->getIndex == $pivot )
    {
#	print $fh "pivot est tete de l'ajout\n";
	my $tree2 = $tree_save->copy;
#	$tree2->print($words_a,$fh);
	my $added2 = $added_save->copy;
	$root2 = $tree2->getNodeSet->searchRootNodeForLeaf($pivot);
	if (defined $root) { # Added by Thierry 02/03/2007
	    ($above,$place) = $root2->searchLeaf($pivot,\$depth); 
#	    print $fh "above: " . $above->getID . "  plcae: " . $place ."\n";
	    
	    if(
	       ($above->{"LINKED_TO_ISLAND"} == 0)
	       ||
	       ($above->getEdgeStatus($place) eq "MODIFIER")
	       ||
	       (
		($above->{"LINKED_TO_ISLAND"} == 1)
		&&
		(
		 ($added2->getRoot->{"LINKED_TO_ISLAND"} == 1)
		 # ||
# 		 ($above->searchHead(0)->getIndex == $pivot) 
		 )
		)
	       )
	    {
		if($above->hitch($place,$added2->getRoot,$words_a,$fh))
		{
		    
		    if ($tree2->getSimplifiedIndexSet->simplify($added_index_set,$added2,$tree2,$pivot) != -1 ) 
		    {
#			print $fh "arbre modifie  " . $tree2 . "\n";
			$tree2->addNodes($added2);
			#$tree2->updateRoot;
			$root2->searchRoot->hitchMore($tree2->getNodeSet->searchFreeNodes($words_a),$tree2,$words_a,$fh);
			$tree2->updateRoot;
			push @$concurrent_trees_a,$tree2;
			$appended = 1;
		    }
		    else
		    {
			$appended = -1;
		    }
		}
	    }
	 #    else
# 	    {
# 		print $fh "Linked to island above: " .$above->getID . "\n";
# 	    }
	}
	
    }
    if($root->searchHead(0)->getIndex == $pivot)
    {
#	print $fh "pivot est tete du hook" . $root->getID. " \n";
#	$this->print($words_a,$fh);
	($above,$place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
	if (defined $above) { # Added by Thierry Hamon 31/01/2007 - to check
#	    print $fh "above: " . $above->getID . "  plcae: " . $place ."\n";
	if($above->hitch($place,$root,$words_a,$fh))
	{
	    $this->addNodes($added_node_set);
	    $above->searchRoot->hitchMore($this->getNodeSet->searchFreeNodes($words_a),$this,$words_a,$fh);
	    $this->updateRoot;
	     $appended = 1;
	    $modified = 1;
	}
    }
    }

    return ($modified,$appended);
}

sub appendIncluded
{
    my ($this,$mode,$root,$index_set,$added_node_set,$added_index_set,$pivot,$words_a,$fh) = @_;
    my $above;
    my $above_index_set;
    my $below;
    my $below_index_set;
    my $type;
    my $place;
    my $intermediate_node;
    my $depth = 0;
    #  print STDERR "I1\n";
    if($mode =~ /REVERSED/)
    {
	$above = $added_node_set->getRoot;
	#  print STDERR "Ib1\n";
	$above_index_set = $added_index_set;
	$below = $root;
	$below_index_set = $index_set;
	
    }
    else
    {
	$above = $root;
	$above_index_set = $index_set;
	$below = $added_node_set->getRoot;
	#  print STDERR "Ic1\n";
	$below_index_set = $added_index_set;
    }
    #  print STDERR "I2\n";

    $type = $below_index_set->appendPosition($pivot);
   
    #  print STDERR "$type\n";
 #    print $fh "pivot " . $pivot . "\n";
#     print $fh "cherche1 dans " . $above->getID ."\n";
#     $above->printRecursively($words_a,$fh);
    ($above,$place) = $above->searchLeaf($pivot,\$depth);
#    print $fh "above1 ok " . $above->getID . " place:" . $place. "\n";
    #  print STDERR "I3\n";


    if(defined $above)
    {
	($above,$intermediate_node,$place) = $above->getHookNode($type,$place,$below_index_set,$fh);
	#  print STDERR "I4\n";
	if(defined $above)
	{
#	print $fh "above2 ok " . $above->getID . " place:" . $place. "\n";
	    #  print STDERR "I5\n";

	    if($above->hitch($place,$below,$words_a,$fh))
	    {
#	    $above->printRecursively($words_a,$fh);
		# print STDERR "I6c\n";
		$this->addNodes($added_node_set);
		#  print STDERR "I7c\n";

# XXXX
		
		$above->searchRoot->hitchMore($this->getNodeSet->searchFreeNodes($words_a),$this,$words_a,$fh);

		#print STDERR "I8\n";

		$this->updateRoot;
		# print STDERR "I9\n";
		return (1,1);
	    }
	}
    }
    return (0,0);
}

sub appendDisjuncted
{
    my ($this,$added_node_set) = @_;
    $this->addNodes($added_node_set);
    return (1,1);
}

sub getAppendContexts
{
    my ($this,$mode,$pivot,$root,$index_set,$added_node_set,$added_index_set,$words_a)  = @_;
    my @contexts;
    my $place;
    my $above;
    my $below;
    my $tree_save = $this->copy;
    my $added_save = $added_node_set->copy;
    my $sub_index_set_save = $index_set->copy;
    my $added_index_set_save = $added_index_set->copy;
    my $depth = 0;
    if($mode =~ /INSERTION/)
    {
	if($mode =~ /REVERSED/)
	{
	    ($above,$place) =  $added_node_set->getRoot->searchLeaf($pivot,\$depth);
	    $below = $root;	    
	}
	else
	{
	    ($above,$place) = $root->searchLeaf($pivot,\$depth);
	    $below = $added_node_set->getRoot;
	}
	my $context = {"ABOVE"=>$above, "PLACE"=>$place, "BELOW" => $below, "TREE"=>$this, "INDEX_SET"=>$index_set, "ADDED_NODE_SET"=>$added_node_set, "ADDED_INDEX_SET"=>$added_index_set};
	push @contexts, $context;
    }
    else
    {

	if($mode !~ /MIDDLE/)
	{
	    ($above,$place) = $added_node_set->getRoot->searchLeaf($pivot,\$depth);
	    $below = $root;
	    my $context = {"ABOVE"=>$above, "PLACE"=>$place, "BELOW" => $below, "TREE"=>$this, "INDEX_SET"=>$index_set, "ADDED_NODE_SET"=>$added_node_set, "ADDED_INDEX_SET"=>$added_index_set};
	    push @contexts, $context;
	    if($root->{"LINKED_TO_ISLAND"} == 0) # conserver cette condion ?
	    {
		my $tree2 = $tree_save->copy;

		my $added2 = $added_save->copy;
		($above,$place) =   $tree2->getNodeSet->getNodeWithPivot($pivot);
		$below = $added2->searchRootNodeForLeaf($pivot);
		if (defined $below) { # Added by Thierry 02/03/2007
		    my $context2 = {"ABOVE"=>$above, "PLACE"=>$place, "BELOW" => $below, "TREE"=>$tree2, "INDEX_SET"=>$sub_index_set_save, "ADDED_NODE_SET"=>$added2, "ADDED_INDEX_SET"=>$added_index_set_save};
		    push @contexts, $context2;
		}
	    }
	}
	
	else
	{
	    ($above,$place) =  $added_node_set->getRoot->searchLeaf($pivot,\$depth);
	    $below = $this->getNodeSet->searchRootNodeForLeaf($pivot);
	    if (defined $below) { # Added by Thierry 02/03/2007
		my $context = {"ABOVE"=>$above, "PLACE"=>$place, "BELOW" => $below, "TREE"=>$this, "INDEX_SET"=>$index_set, "ADDED_NODE_SET"=>$added_node_set, "ADDED_INDEX_SET"=>$added_index_set};
		push @contexts, $context;
	    }
	}
    }
    return \@contexts;
}

sub updateIndexes
{
    my ($this,$phrase_index_set,$words_a) = @_;
    my $heads_h;
    my $index_set = Lingua::YaTeA::IndexSet->new;
    my $simplified_index_set = $phrase_index_set->copy;
    $this->getNodeSet->fillIndexSet($index_set);
    

    $heads_h = $this->getNodeSet->searchHeads($words_a);
    if ($simplified_index_set->simplifyWithSeveralPivots($index_set,$this->getNodeSet,$this,$heads_h) == -1 ) {return -1;}

    @{$this->getIndexSet->getIndexes} = @{$index_set->getIndexes};
    @{$this->getSimplifiedIndexSet->getIndexes} = @{$simplified_index_set->getIndexes};
}

1;

__END__

=head1 NAME

Lingua::YaTeA::Tree - Perl extension for ???

=head1 SYNOPSIS

  use Lingua::YaTeA::Tree;
  Lingua::YaTeA::Tree->();

=head1 DESCRIPTION


=head1 METHODS


=head2 new()


=head2 setHead()


=head2 setReliability()


=head2 fillNodeLeaves()


=head2 getIndexSet()


=head2 getNodeSet()


=head2 setSimplifiedIndexSet()


=head2 copy()


=head2 getSimplifiedIndexSet()


=head2 getRoot()


=head2 updateRoot()


=head2 setNodeSet()


=head2 addNodes()


=head2 print()


=head2 printParenthesised()


=head2 getHead()


=head2 getReliability()


=head2 setIndexSet()


=head2 check()


=head2 completeDiscontinuousNodes()


=head2 getDiscontinuousNodes()


=head2 removeDiscontinuousNodes()


=head2 integrateIslandNodeSets()


=head2 append()


=head2 appendAdjuncts()


=head2 appendIncluded()


=head2 appendDisjuncted()


=head2 getAppendContexts()


=head2 updateIndexes()


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
