package Lingua::YaTeA::Node;
use strict;
use warnings;
use Data::Dumper;
use UNIVERSAL;
use Lingua::YaTeA::TermLeaf;
use Lingua::YaTeA::MultiWordTermCandidate;
use Lingua::YaTeA::MonolexicalTermCandidate;
use Scalar::Util qw(blessed);

our $id = 0;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$level) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{ID} = $id++;
    $this->{LEVEL} = $level;
    $this->{LEFT_EDGE} = ();
    $this->{LEFT_STATUS} = ();
    $this->{RIGHT_EDGE} = ();
    $this->{RIGHT_STATUS} = ();
    $this->{DET} = ();
    $this->{PREP}= ();
    $this->{LINKED_TO_ISLAND} = 0;
    return $this;
}

sub addEdge
{
    my ($this,$edge,$status) = @_;
    my %mapping =("M"=>"MODIFIER", "H"=>"HEAD","C1"=>"COORDONNE1", "C2"=>"COORDONNE2" );
    if (!defined $this->{LEFT_EDGE}){ # si le fils gauche est vide, on le remplit
	$this->{LEFT_EDGE} =  $edge;
	$this->{LEFT_STATUS} = $mapping{$status};
    }
    else{
	$this->{RIGHT_EDGE} = $edge; # sinon, on remplit le fils droit
	$this->{RIGHT_STATUS} = $mapping{$status};
    }
}




sub getEdgeStatus
{
    my ($this,$place) = @_;
    return $this->{$place.'_STATUS'};
}

sub getLeftEdgeStatus
{
    my ($this) = @_;
    return $this->{LEFT_STATUS};
}

sub getRightEdgeStatus
{
    my ($this) = @_;
    return $this->{RIGHT_STATUS};
}

sub getNodeStatus
{
    my ($this) = @_;
    my $father;
    if ((blessed($this)) && ($this->isa('Lingua::YaTeA::Edge')))
    {
	$father = $this->{FATHER};
	if ($father->{LEFT_EDGE} == $this)
	{
	    return $father->{LEFT_STATUS};
	}
	else
	{
	    return $father->{RIGHT_STATUS};
	}
    }
    else
    {
	return "ROOT";
    }
}

sub getNodePosition
{
    my ($this) = @_;
    my $father;
     if ((blessed($this)) && ($this->isa('Lingua::YaTeA::Edge')))
     {
	 $father = $this->{FATHER};
	 if ($father->{LEFT_EDGE} == $this)
	{
	    return "LEFT";
	}
	 else
	 {
	     return "RIGHT";
	 }
     }
}

sub getHead
{
    my ($this) = @_;
    if($this->{LEFT_STATUS} eq "HEAD")
    {
	return $this->{LEFT_EDGE};
    }
    return $this->{RIGHT_EDGE};
}



sub getModifier
{
    my ($this) = @_;
    if($this->{LEFT_STATUS} eq "MODIFIER")
    {
	return $this->{LEFT_EDGE};
    }
    return $this->{RIGHT_EDGE};
}

sub getLeftEdge
{
    my ($this) = @_;
    return $this->getEdge("LEFT");
}

sub getRightEdge
{
    my ($this) = @_;
    return $this->getEdge("RIGHT");
}

sub getEdge
{
    my ($this,$position) = @_;
    return $this->{$position."_EDGE"};
}

sub getID
{
    my ($this) = @_;
    return $this->{ID};

}

sub getLevel
{
    my ($this) = @_;
    return $this->{"LEVEL"};
}



sub getDeterminer
{
    my ($this) = @_;
    return $this->{DET};
}

sub getPreposition
{
    my ($this) = @_;
    return $this->{PREP};
}

sub linkToFather
{
    my ($this,$uncomplete_a,$status) = @_;
    my $father;
    if (scalar @$uncomplete_a != 0)
    {
	$father = $uncomplete_a->[$#$uncomplete_a];
	$this->{FATHER} = $father;
	$father->addEdge($this,$status);
    }
    
}

sub fillLeaves
{
    my ($this,$counter_r,$index_set, $depth) = @_;

    $depth++;
    if ($depth < 50) { # Temporary added by Thierry Hamon 02/03/2007
	if ($this->getLeftEdge eq "")
	{
	    $this->{LEFT_EDGE} = Lingua::YaTeA::TermLeaf->new($index_set->getIndex($$counter_r++));
	}
	else
	{
	    $this->getLeftEdge->fillLeaves($counter_r,$index_set, $depth);
	}
	
	if (defined $this->getPreposition)
	{
	    $this->{PREP} = Lingua::YaTeA::TermLeaf->new($index_set->getIndex($$counter_r++));
	}
	if (defined $this->getDeterminer)
	{
	    $this->{DET} = Lingua::YaTeA::TermLeaf->new($index_set->getIndex($$counter_r++));
	}
	if ($this->getRightEdge eq "")
	{
	    $this->{RIGHT_EDGE} = Lingua::YaTeA::TermLeaf->new($index_set->getIndex($$counter_r++));
	}
	else
	{
	    $this->getRightEdge->fillLeaves($counter_r,$index_set, $depth);
	}
    } else {
	warn "fillLeaves: Going out a deep recursive method call (more than 50 calls)\n";
    }
}






sub searchHead
{
    my ($this, $depth) = @_;
   # print $this->getID . "\n";
    my $head = $this->getHead;
#    print STDERR "==> $depth\r";
    
    if(defined $head) {
	$depth++;
	if ($depth < 50) {
	    return $head->searchHead($depth);
	} else  {
	    warn "searchHead: Going out a deep recursive method call (more than 50 calls)\n";
	    return undef;
	}
    }
}

sub isLinkedToIsland
{
    my ($this) = @_;
    return $this->{"LINKED_TO_ISLAND"};
}


sub printSimple
{
    my ($this,$words_a,$fh) = @_;
    my $left_edge;
    my $right_edge;
    if(!defined $fh)
    {
	$fh = \*STDERR;
    }
    print $fh "\t\t[" . ref($this) ."\n";
    print $fh "\t\tid: " . $this->getID . "\n";
    print $fh "\t\tlevel:" . $this->getLevel;
    print $fh "\t\tlinked to island:" . $this->isLinkedToIsland. "\n";
    

    $left_edge = $this->getLeftEdge;
    print $fh "\t\tleft_edge: ";
    if((blessed($left_edge)) && ($left_edge->isa("Lingua::YaTeA::RootNode")))
    {
	print $fh $left_edge->getID . "\n";
    }
    else
    {
	$left_edge->print($words_a,$fh);
    }
    print $fh "\t\tleft_status: " . $this->getLeftEdgeStatus . "\n";
    if (defined $this->{PREP})
    {
	print $fh "\t\tprep: " ;
	$this->{PREP}->print($words_a,$fh);
	print $fh "\n";
    }
    if (defined $this->{DET})
    {
	print $fh "\t\tdet: ";
	$this->{DET}->print($words_a,$fh);
	print  $fh "\n";
    }
    print $fh "\t\tright_edge: ";
    $right_edge = $this->getRightEdge;
    $right_edge->print($words_a,$fh);
    print $fh "\t\tright_status: " . $this->getRightEdgeStatus . "\n";
    print $fh "\t\t]\n";
}

sub printRecursively
{
    my ($this,$words_a,$fh) = @_;
    my $left_edge;
    my $right_edge;
    if(!defined $fh)
    {
	$fh = \*STDERR;
    }
    print $fh "\t\t[" .ref($this) ."\n";
    print $fh "\t\tid: " . $this->getID . "\n";
    print $fh "\t\tlevel:" . $this->getLevel;
    print $fh "\t\tlinked to island:" . $this->isLinkedToIsland. "\n";;
    if((blessed($this)) && ($this->isa('Lingua::YaTeA::InternalNode')))
    {
	$this->printFather($fh);
    }
    $left_edge = $this->getLeftEdge;
    print $fh "\t\tleft_edge: ";
    $left_edge->print($words_a,$fh);

    print $fh "\t\tstatus: " . $this->getLeftEdgeStatus . "\n";
    if (defined $this->getPreposition)
    {
	print $fh "\t\tprep: ";
	if ((blessed($this->getPreposition)) && ($this->getPreposition->isa('Lingua::YaTeA::TermLeaf')))
	{
	    $this->getPreposition->print($words_a,$fh); 
	}
	else
	{
	    print $fh $this->getPreposition;
	}
	print  $fh "\n";
    }
    if (defined $this->getDeterminer)
    {
	print $fh "\t\tdet: ";
	if ((blessed($this->getPreposition)) && ($this->getPreposition->isa('Lingua::YaTeA::TermLeaf')))
	{
	    $this->getDeterminer->print($words_a,$fh);
	}
	else
	{
	    print $fh $this->getDeterminer;
	}
	print  $fh "\n";
    }
    print $fh "\t\tright_edge: ";
    $right_edge = $this->getRightEdge;

    $right_edge->print($words_a,$fh);
    print $fh "\t\tstatus: " . $this->getRightEdgeStatus . "\n";
    
    print $fh "\t\t]\n";
    

    if ((blessed($left_edge)) && ($left_edge->isa("Lingua::YaTeA::Node")))
    {
	$left_edge->printRecursively($words_a,$fh);
    }
    if ((blessed($right_edge)) && ($right_edge->isa("Lingua::YaTeA::Node")))
    {
	$right_edge->printRecursively($words_a,$fh);
    }
}

sub searchRoot
{
    my ($this) = @_;
    if((blessed($this)) && ($this->isa('Lingua::YaTeA::RootNode')))
    {
	return $this;
    }
    #  print STDERR "S1 ($this)\n";
    $this->getFather->searchRoot;
}

sub hitchMore
{
    my ($this,$free_nodes_a,$tree,$words_a,$fh) = @_;

    my $pivot;
    my $node;
    my $position;
    my $above;
    my $below;
    my $mode;
    my $depth = 0;
    my $head;
    my $place;
    my $previous;
    my $next;
    my $included_index;
    my $sub_index_set = Lingua::YaTeA::IndexSet->new;
    $this->fillIndexSet($sub_index_set,0);
    my $added_index_set;
    #print $fh "hitchMore dans\n";
    #$this->printRecursively($words_a,$fh);
    #  print $fh scalar(@$free_nodes_a) . "h1\n";


    foreach my $n (@$free_nodes_a)
    {
	
	if($n->getID != $this->getID)
	{
#	    print $fh "free: \n";
#	    $n->printRecursively($words_a,$fh);
	    $head= $n->searchHead(0);
	    if((defined $head)&&((blessed($head)) && $head->isa('Lingua::YaTeA::TermLeaf')))
	    {
		$pivot = $head->getIndex;
#	    print $fh "pivot " . $pivot . "\n";
		$added_index_set = Lingua::YaTeA::IndexSet->new;
		$n->fillIndexSet($added_index_set,0);
		$depth = 0;
		($node,$position) = $this->searchLeaf($pivot,\$depth);
		if ((blessed($node)) && ($node->isa('Lingua::YaTeA::Node')))
		{
		
		    ($mode) = $sub_index_set->defineAppendMode($added_index_set,$pivot);
		    if(defined $mode)
		    {
		    #  print STDERR "mode1 = $mode\n";
			if($mode ne "DISJUNCTION")
			{

			    if($mode =~ /INCLUSION/)
			    {
#			print $fh "inclusion\n";
				if($mode =~ /REVERSED/)
				{
#			    print $fh "reversed\n";
				    $depth = 0;
				    ($previous,$next) = $added_index_set->getIncludedContext($sub_index_set);
				    #($above,$place) = $n->searchLeaf($pivot,\$depth);
				    ($above,$place) = $n->searchLeaf($pivot,\$depth);
				    $below = $node;
				}
				else
				{
				    $depth = 0;
				    ($previous,$next) = $sub_index_set->getIncludedContext($added_index_set);
				    ($above,$place) = $node->searchLeaf($pivot,\$depth);
				    $below = $n;
				}
				if($place eq "LEFT")
				{
				    while
					(
					 ($above->searchRightMostLeaf(\$depth)->getIndex < $below->searchRightMostLeaf(\$depth)->getIndex)
					 &&
					 (! ((blessed($above)) && ($above->isa('Lingua::YaTeA::RootNode'))))
					 &&
					 ($above->getFather->getLeftEdge->searchRightMostLeaf(\$depth)->getIndex < $below->searchRightMostLeaf(\$depth)->getIndex)
					)
				    {
					$above = $above->getFather;
				    }
				}
				else
				{
				    if($place eq "RIGHT")
				    {
					while
					    (
					     ($above->searchLeftMostLeaf(\$depth)->getIndex > $below->searchLeftMostLeaf(\$depth)->getIndex)
					     &&
					     (! ((blessed($above)) && ($above->isa('Lingua::YaTeA::RootNode'))))
					     &&
					     ($above->getFather->getRightEdge->searchLeftMostLeaf(\$depth)->getIndex > $below->searchLeftMostLeaf(\$depth)->getIndex)
					    )
					{
					    $above = $above->getFather;
					}
				    }
				}
			    }
			    else
			    {
				if($mode eq "ADJUNCTION")
				{
#			    print $fh "adjunction\n";
				    #  print STDERR "hm1\n";
				    $depth = 0;
				    ($above,$place) = $node->searchLeaf($pivot,\$depth);
				    #  print STDERR "hm2\n";
				    $below = $n;
				}
			    }
			    # print STDERR "hm3\n";
			    
			    if($above->hitch($place,$below,$words_a,$fh))
			    {
				$tree->updateRoot;
			    }
#		    print $fh "apres hitch dans hitchmore\n";
#		    $above->printRecursively($words_a,$fh);
			    # print STDERR "hm4\n";

			}
			else
			{
			    die;
			}
		    }

		}
		else
		{
		    $depth = 0;
		    $head = $this->searchHead(0);
		    if ((defined $head) && ((blessed($head)) && ($head->isa('Lingua::YaTeA::TermLeaf'))))
		    {
			$pivot = $head->getIndex;
			($node,$position) = $n->searchLeaf($pivot,\$depth);
			if ((blessed($node)) && ($node->isa('Lingua::YaTeA::Node')))
			{
			    ($mode) = $added_index_set->defineAppendMode($sub_index_set,$pivot);
			    
			    if(defined $mode)
			    {
				if($mode ne "DISJUNCTION")
				{
				    #  print STDERR "mode2 = $mode\n";
				    if($mode =~ /INCLUSION/)
				    {
					if($mode =~ /REVERSED/)
					{
					    $depth = 0;
					    ($above,$place) = $this->searchLeaf($pivot,\$depth);
					    $below = $node;
					}
					else
					{
					    $depth = 0;
					    ($above,$place) = $n->searchLeaf($pivot,\$depth);
					    $below = $this;
					}
				    }
				    else
				    {
					if($mode eq "ADJUNCTION")
					{
					    $depth = 0;
					    ($above,$place) = $n->searchLeaf($pivot,\$depth);
					    $below = $this;
					}
				    }

				    $above->hitch($place,$below,$words_a);
				}
			    }
			}
		    }
		}
	    }

	}
    }
}


sub hitch
{
    my ($this,$place,$to_add,$words_a,$fh) = @_;
    if(defined $fh)
    {
#	print $fh "hook\n";
	
	#  print STDERR "hi1\n";
#	$this->printRecursively($words_a,$fh);
#	print $fh "to add\n";
#	$to_add->printRecursively($words_a,$fh);
    }
    if($this->checkCompatibility($place,$to_add,$fh))
    {
    #  print STDERR "hi2\n";
# 	 if(defined $fh)
# 	 {
# 	     print $fh "compatibles\n";
# 	 }
	if ((blessed($to_add)) && ($to_add->isa('Lingua::YaTeA::RootNode')))
	{
	    bless ($to_add,'Lingua::YaTeA::InternalNode');
	}
    #  print STDERR "hi3\n";
	if ((blessed($this->{$place."_EDGE"})) && ($this->{$place."_EDGE"}->isa('Lingua::YaTeA::InternalNode')))
	{
	    $to_add->plugSubNodeSet($this->{$place."_EDGE"});
	}

    #  print STDERR "hi4\n";
	$to_add->setFather($this);
    #  print STDERR "hi5\n";
	$this->{$place."_EDGE"} = $to_add;
	 #	 print STDERR "hi6a\n";
	 $to_add->updateLevel($this->getLevel + 1);
	 #print STDERR "hi7a\n";
	
	return 1;
	
    }
    else
    {
	#incompatible nodes
	return 0;
    }
}

sub freeFromFather
{
    my ($this) = @_;
    undef $this->{FATHER};
    bless ($this,'Lingua::YaTeA::RootNode');
}


sub plugSubNodeSet
{
    my ($this,$to_plug) = @_;
    my $head_position = $this->getHeadPosition;
    my $head_node;
    my $depth = 0;

    if ((blessed($this->{$head_position . "_EDGE"})) && ($this->{$head_position . "_EDGE"}->isa('Lingua::YaTeA::TermLeaf')))
    {
	$this->{$head_position . "_EDGE"} = $to_plug;
	$to_plug->setFather($this);
    }
    else
    {
	($head_node,$head_position) = $this->{$head_position . "_EDGE"}->searchLeaf($to_plug->searchHead(0)->getIndex,\$depth);
	$head_node->{$head_position . "_EDGE"} = $to_plug;
	$to_plug->setFather($head_node);
    }
}

sub checkCompatibility
{
    my ($this,$place,$to_add,$fh) = @_;

    #  print STDERR "cC1\n";
# 	if(defined $fh)
# 	{
# 	    print $fh "place: " . $place  ."\n";
# 	}
    if($this->getID != $to_add->getID)
    {
    #  print STDERR "cC3\n";
# 	if(defined $fh)
# 	{
# 	    print $fh "differents\n";
# 	}
# 	if(defined $fh)
# 	{
# 	    print $fh "tete add: " . $to_add->searchHead(0)->getIndex . "\n";
# 	    print $fh "tete hook: " . $this->getEdge($place)->searchHead(0)->getIndex . "\n";
# 	}
	if($to_add->searchHead(0)->getIndex == $this->getEdge($place)->searchHead(0)->getIndex)
	{
	  #   if(defined $fh)
# 	    {
# 		print $fh "ca colle\n";
# 	    }
    #  Print STDERR "cC3\n";
	    if($this->checkNonCrossing($to_add,$fh))
	    {
	# 	if(defined $fh)
# 		{
# 		    print $fh "croisent pas\n";
# 		}
    #  print STDERR "cC4\n";
		return 1;
	    }
    #  print STDERR "cC5\n";
	    return 0;
	}
	return 0;
    }
    return 0;
}





sub checkNonCrossing
{
    my ($this,$to_add,$fh) = @_;

    my $previous = -1;
    my $gap;
    my $above_index_set = Lingua::YaTeA::IndexSet->new;
   

    #  print STDERR "cNC1\n";

    $this->fillIndexSet($above_index_set,0);
  
    #  print STDERR "cNC2\n";

    my $above_gaps_a = $above_index_set->getGaps;
   
    #  print STDERR "cNC2b\n";
    my $to_add_index_set;
    my $index;
    my $pivot;
    my @both;
    
    my $i;
    my %filled_gaps;
    my @gaps;

    #  print STDERR scalar(@$above_gaps_a) . "\n";


    if(scalar @$above_gaps_a > 1)
    {
	#  print STDERR "cNC3a\n";
	$to_add_index_set = Lingua::YaTeA::IndexSet->new;
	#  print STDERR "cNC3b\n";
	$to_add->fillIndexSet($to_add_index_set,0);
	#  print STDERR "cNC4\n";
	foreach $index (@{$to_add_index_set->getIndexes})
	{
	    #  print STDERR "cNC5\n";
	    foreach $gap (@$above_gaps_a)
	    {
		if(exists $gap->{$index})
		{
		    $filled_gaps{$gap} = $gap;
		}
	    }
	}
	#  print STDERR "cNC6\n";
	@gaps = values %filled_gaps;
	#  print STDERR "cNC7\n";

	if(scalar @gaps > 1)
	{
	    if(scalar @gaps == 2)
	    {
		#  print STDERR "cNC8\n";
		$pivot = $above_index_set->searchPivot($to_add_index_set);
		if(defined $pivot)
		{
		    #  print STDERR "cNC9\n";
		    push @both, keys %{$gaps[0]};
		    push @both, keys %{$gaps[1]};
		    @both = sort (@both);
		    $previous = -1;
		    #  print STDERR "cNC10\n";

		    for ($i=0; $i < scalar @both; $i++)
		    {
			#  print STDERR "cNC11\n";
			$index = $both[$i];

			if(
			    ($index != $previous+1)
			    &&
			    ($pivot == $previous+1) 
			    &&
			    (
			     (!defined $both[$i+1])
			     ||
			     ($pivot == $both[$i+1])
			    )
			    )
			{
			    return 1;
			}
			$previous = $index;
		    }
		    return 0;
		}
	    }
	    return 0;
	}
    }
    #  print STDERR "cNC(F)\n";

    return 1;
}



sub copyRecursively
{
    my ($this,$new_set,$father, $depth_r) = @_;
    my $new;
    my $field;
    my $edge;
    my @fields = ('LEVEL','LEFT_STATUS','RIGHT_STATUS','DET','PREP','LINKED_TO_ISLAND');
    $$depth_r++;
    if ($$depth_r < 50) { # Temporary added by Thierry Hamon 09/02/2012
	if ((blessed($this)) && ($this->isa('Lingua::YaTeA::RootNode')))
	{
	    $new = Lingua::YaTeA::RootNode->new;
	    $new_set->{ROOT_NODE} = $new;
	}
	else
	{
	    $new = Lingua::YaTeA::InternalNode->new;
	    $new->{FATHER} = $father;
	}
	foreach $field (@fields)
	{
	    $new->{$field} = $this->{$field};
	}
	$new_set->addNode($new);
	if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::TermLeaf')))
	{
	    $new->{LEFT_EDGE} = $this->getLeftEdge;
	}
	else{
	    $edge = $this->getLeftEdge;
	    if(defined $edge)
	    {
		$new->{LEFT_EDGE} = $edge->copyRecursively($new_set,$new, $depth_r);
	    }
	}
	if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::TermLeaf')))
	{
	    $new->{RIGHT_EDGE} = $this->getRightEdge;
	}
	else
	{
	    $edge = $this->getRightEdge;
	    if(defined $edge)
	    {
		$new->{RIGHT_EDGE} = $edge->copyRecursively($new_set,$new, $depth_r);
	    }
	}
    } else {
	warn "copyRecursively: Going out a deep recursive method call (more than 50 calls)\n";
	$new = $this;
	# return undef;
    }
    return $new;
 
}


sub searchLeftMostLeaf
{
    my ($this) = @_;
    my $left_most;
    my $left;
   
    $left = $this->getLeftEdge;
    if ((blessed($left)) && ($left->isa('Lingua::YaTeA::Node')))
    {
	$left = $left->searchLeftMostLeaf;
    }
    return $left;
}



sub searchRightMostLeaf
{
    my ($this,$depth_r) = @_;
    my $right;
    $$depth_r++;
    if ($$depth_r < 50) { # Temporary added by sophie Aubin 14/01/2008
	
	$right = $this->getRightEdge;
	
	if ((blessed($right)) && ($right->isa('Lingua::YaTeA::Node')))
	{
	    $right = $right->searchRightMostLeaf($depth_r);
	}
	return $right;
    }
    else
    {
	warn "searchRightMostLeaf: Going out a deep recursive method call (more than 50 calls)\n";
	return undef;
    }
}





sub getPreviousWord
{
    my ($this,$place) = @_;
    my $depth = 0;
    if($place eq "LEFT")
    {
	if ((blessed($this)) && ($this->isa('Lingua::YaTeA::RootNode')))
	{
	    return;
	}
	else
	{
	    return $this->getFather->getPreviousWord($this->getNodePosition);
	}
    }
    else
    {
	if(defined $this->getDeterminer)
	{
	    return $this->getDeterminer;
	}
	if(defined $this->getPreposition)
	{
	    return $this->getPreposition;
	}
	if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::Node')))
	{
	    return $this->getLeftEdge->searchRightMostLeaf(\$depth);
	}
	else
	{
	    return $this->getLeftEdge;
	}
    }
    
}




sub getNextWord
{
    my ($this,$place) = @_;
    if($place eq "RIGHT")
    {
	if((blessed($this)) && ($this->isa('Lingua::YaTeA::RootNode')))
	{
	    return;
	}
	else
	{
	    return $this->getFather->getNextWord($this->getNodePosition);
	}
    }
    else
    {
	if(defined $this->getPreposition)
	{
	    return $this->getPreposition;
	}
	if(defined $this->getDeterminer)
	{
	    return $this->getDeterminer;
	}
	if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::Node')))
	{
	    return $this->getRightEdge->searchLeftMostLeaf;
	}
	else
	{
	    return $this->getRightEdge;
	}
    }    
}




sub findWordContext
{
    my ($this,$word_index,$place) = @_;
  
    my $next;
    my $previous;

    $previous = $this->getPreviousWord($place);
    $next = $this->getNextWord($place);

    if((!defined $previous)&&(!defined $next))
    {
	die "Index not found\n";
    }
    return ($previous,$next);
}


sub buildIF
{
    my ($this, $if_r, $words_a, $depth_r) = @_;
    
    $$depth_r++;
    if ($$depth_r < 50) { # Temporary added by Thierry Hamon 09/02/2012
	if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::InternalNode')))
	{
	    $this->getLeftEdge->buildIF($if_r,$words_a,$depth_r);
	}
	else
	{
	    $$if_r .= $this->getLeftEdge->getIF($words_a) . " ";
	}
	
	if(defined $this->getPreposition)
	{
	    $$if_r .= $this->getPreposition->getIF($words_a) . " ";	
	}


	if(defined $this->getDeterminer)
	{
	    $$if_r .= $this->getDeterminer->getIF($words_a) . " ";	
	}

	if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::InternalNode')))
	{
	    $this->getRightEdge->buildIF($if_r,$words_a,$depth_r);
	}
	else
	{
	    $$if_r .= $this->getRightEdge->getIF($words_a) . " ";
	}
    } else {
	warn "buildIF: Going out a deep recursive method call (more than 50 calls)\n";
	return undef;
    }
    
}

sub buildParenthesised
{
    my ($this,$analysis_r,$words_a) = @_;
    my %abr = ("MODIFIER" => "M", "HEAD" => "H", "COORDONNE1" => "C1", "COORDONNE2" => "C2");
    $$analysis_r .= "( ";
    if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::InternalNode')))
    {
	$this->getLeftEdge->buildParenthesised($analysis_r,$words_a);
    }
    else
    {
	#$$analysis_r .= $this->getLeftEdge->getIF($words_a) . "<=" .$abr{$this->getLeftEdgeStatus} . "=" . $this->getLeftEdge->getPOS($words_a) . "> ";
	$$analysis_r .= $this->getLeftEdge->getIF($words_a) . "<=" .$abr{$this->getLeftEdgeStatus} . "> ";
    }
    
    if(defined $this->getPreposition)
    {
	#$$analysis_r .= $this->getPreposition->getIF($words_a) . " ";
	$$analysis_r .= $this->getPreposition->getIF($words_a) . "<=P> ";	
    }


    if(defined $this->getDeterminer)
    {
	# $$analysis_r .= $this->getDeterminer->getIF($words_a) . " ";
	$$analysis_r .= $this->getDeterminer->getIF($words_a) . "<=D> ";	
    }

    if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::InternalNode')))
    {
	$this->getRightEdge->buildParenthesised($analysis_r,$words_a);
    }
    else
    {
	# $$analysis_r .= $this->getRightEdge->getIF($words_a) . "<=" .$abr{$this->getRightEdgeStatus} . "=" . $this->getRightEdge->getPOS($words_a) . "> ";
	$$analysis_r .= $this->getRightEdge->getIF($words_a) . "<=" .$abr{$this->getRightEdgeStatus} . "> ";
    }
    if((blessed($this)) && ($this->isa('Lingua::YaTeA::InternalNode')))
    {
	# $$analysis_r .= ")<=" . $abr{$this->getNodeStatus} . "=" .$this->searchHead(0)->getPOS($words_a) . "> ";
	$$analysis_r .= ")<=" . $abr{$this->getNodeStatus} .  "> ";
    }
    else
    {
	$$analysis_r .= ")";
    }
}




sub searchLeaf
{
    my ($this,$index,$depth_r) = @_;
    my $node;
    my $position;
    #  print STDERR "SL1\n";
    $$depth_r++;
    if ($$depth_r < 50) { # Temporary added by sophie Aubin 14/01/2008
	
	if(( blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::Node')))
	{
	    #  print STDERR "SL2a\n";
	    ($node,$position) = $this->getLeftEdge->searchLeaf($index,$depth_r);
	}
	else
	{
	    #  print STDERR "SL2b\n";
	    if($this->getLeftEdge->getIndex == $index)
	    {
		return ($this,"LEFT");
	    }
	}
	#  print STDERR "SL3\n";
	
	if(!defined $node)
	{
	    if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::Node')))
	    {
		#  print STDERR "SL4a\n";
		($node,$position) = $this->getRightEdge->searchLeaf($index,$depth_r);
	    }
	    else
	    {
		#  print STDERR "SL4b\n";
		if($this->getRightEdge->getIndex == $index)
		{
		    return ($this,"RIGHT");
		}
	    }
	}
    }
    else
    {
	warn "searchLeaf: Going out a deep recursive method call (more than 50 calls)\n";
	return undef;
    }
    #  print STDERR "SL5\n";
    return ($node,$position); 
}

sub updateLeaves
{
    my ($this,$counter_r,$index_set) = @_;
    
    if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::TermLeaf')))

    {
	$this->{LEFT_EDGE} = Lingua::YaTeA::TermLeaf->new($index_set->getIndex($$counter_r++));
    }
    else
    {
	$this->getLeftEdge->updateLeaves($counter_r,$index_set);
    }
    
    if (defined $this->getPreposition)
    {
	$this->{PREP} = Lingua::YaTeA::TermLeaf->new($index_set->getIndex($$counter_r++));
    }
    if (defined $this->getDeterminer)
    {
	$this->{DET} = Lingua::YaTeA::TermLeaf->new($index_set->getIndex($$counter_r++));
    }
    if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::TermLeaf')))
    {
	$this->{RIGHT_EDGE} = Lingua::YaTeA::TermLeaf->new($index_set->getIndex($$counter_r++));
    }
    else
    {
	$this->getRightEdge->updateLeaves($counter_r,$index_set);
    }
}


sub buildTermList
{
    my ($this,$term_candidates_a,$words_a,$phrase_occurrences_a,$phrase_island_set,$offset,$maximal) = @_;
   
    my $left;
    my $right;

#     map {print STDERR "++>" . $_->getIF()} @$words_a;
 
    my $term_candidate = Lingua::YaTeA::MultiWordTermCandidate->new;
#     print STDERR "\nID : " . $term_candidate->getID . "\n";

    my %abr = ("MODIFIER" => "M", "HEAD" => "H", "COORDONNE1" => "C1", "COORDONNE2" => "C2");
    
    $term_candidate->editKey("( ");
    
    $term_candidate->setOccurrences($phrase_occurrences_a,$$offset,$maximal);

    my $old_offset = $$offset;

    $$offset = 0;

    # left edge is a term leaf
    if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::TermLeaf')))
    {
# 	print STDERR $this->getLeftEdge->getIF($words_a) . "\n";
	$term_candidate->editKey($this->getLeftEdge->getIF($words_a) . "<=" . $abr{$this->getLeftEdgeStatus} . "=" . $this->getLeftEdge->getPOS($words_a) . "=" . $this->getLeftEdge->getLF($words_a). "> ");

	my $mono =  Lingua::YaTeA::MonolexicalTermCandidate->new;
	$mono->editKey("( " . $this->getLeftEdge->getIF($words_a)."<=S=".$this->getLeftEdge->getPOS($words_a) . "=" . $this->getLeftEdge->getLF($words_a). "> )");
	$mono->addWord($this->getLeftEdge,$words_a);

	$mono->setOccurrences($phrase_occurrences_a,$$offset+$old_offset,$this->getLeftEdge->getLength($words_a),0);

	push @$term_candidates_a, $mono;

	$term_candidate->addWord($this->getLeftEdge,$words_a);
	$term_candidate->getIndexSet->addIndex($this->getLeftEdge->getIndex);
	
	$left = $mono;
#  	print STDERR "==>$$offset\n";
	$$offset += $this->getLeftEdge->getLength($words_a) +1;
#  	print STDERR "====>$$offset\n";

    }
    # left edge is a node
    else
    {
# 	$$offset = 0;

	$$offset += $old_offset;
	$left = $this->getLeftEdge->buildTermList($term_candidates_a,$words_a,$phrase_occurrences_a,$phrase_island_set,$offset,0);
	$$offset -= $old_offset;
	$term_candidate->editKey($left->getKey . "<=" . $abr{$this->getLeftEdge->getNodeStatus} . "=" .$this->getLeftEdge->searchHead(0)->getPOS($words_a) . "> ");
	push @{$term_candidate->getWords},@{$left->getWords};
	$term_candidate->addIndexSet($left->getIndexSet);

# 	$$offset += $old_offset;

    }
    if (defined $this->getPreposition)
    {
	$term_candidate->editKey($this->getPreposition->getIF($words_a) . "<=".$this->getPreposition->getPOS($words_a)  . "=" . $this->getPreposition->getLF($words_a) . "> ");
	$$offset += $this->getPreposition->getLength($words_a) +1;
	$term_candidate->{PREPOSITION} = $this->getPreposition->getWord($words_a);
	$term_candidate->addWord($this->getPreposition,$words_a);
	$term_candidate->getIndexSet->addIndex($this->getPreposition->getIndex);
    }
    if (defined $this->getDeterminer)
    {
	$term_candidate->editKey($this->getDeterminer->getIF($words_a) . "<=" . $this->getDeterminer->getPOS($words_a) . "=" . $this->getDeterminer->getLF($words_a) . "> ");
	$$offset += $this->getDeterminer->getLength($words_a) +1;
	$term_candidate->{DETERMINER} = $this->getDeterminer->getWord($words_a);
	$term_candidate->addWord($this->getDeterminer,$words_a);
	$term_candidate->getIndexSet->addIndex($this->getDeterminer->getIndex);
    }
    if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::TermLeaf')))
    {
	$term_candidate->editKey($this->getRightEdge->getIF($words_a) . "<=" . $abr{$this->getRightEdgeStatus} . "=" . $this->getRightEdge->getPOS($words_a)  . "=" . $this->getRightEdge->getLF($words_a). "> ");

	my $mono =  Lingua::YaTeA::MonolexicalTermCandidate->new;
	$mono->editKey("( " . $this->getRightEdge->getIF($words_a). "<=S=".$this->getRightEdge->getPOS($words_a) . "=" . $this->getRightEdge->getLF($words_a). "> )");
	$mono->addWord($this->getRightEdge,$words_a);
	$mono->setOccurrences($phrase_occurrences_a,$$offset+$old_offset,$this->getRightEdge->getLength($words_a),0);
	push @$term_candidates_a, $mono;

	$term_candidate->addWord($this->getRightEdge,$words_a);
	$term_candidate->getIndexSet->addIndex($this->getRightEdge->getIndex);

	$right = $mono;
#  	print STDERR "===>$$offset\n";
	$$offset += $this->getRightEdge->getLength($words_a) +1;
#  	print STDERR "==>$$offset\n";
    }
    # left edge is a node
    else
    {
# 	print STDERR "=== Call\n";
	$$offset += $old_offset;
	$right = $this->getRightEdge->buildTermList($term_candidates_a,$words_a,$phrase_occurrences_a,$phrase_island_set,$offset,0);
	$$offset -= $old_offset;
       
# 	print STDERR "=== End of Call\n";
	$term_candidate->editKey($right->getKey . "<=" . $abr{$this->getRightEdge->getNodeStatus} . "=" .$this->getRightEdge->searchHead(0)->getPOS($words_a) . "> ");
	push @{$term_candidate->getWords},@{$right->getWords};
	$term_candidate->addIndexSet($right->getIndexSet);

    }

    $term_candidate->editKey(")");
  
   #  if((blessed($this)) && ($this->isa('Lingua::YaTeA::InternalNode')))
#     {
# 	$term_candidate->editKey("<=" . $abr{$this->getNodeStatus} . "=" .$this->searchHead(0)->getPOS($words_a) . "> ");
#     }
   
    if($this->getHeadPosition eq "LEFT")
    {
	$term_candidate->{ROOT_HEAD} = $left;
	$term_candidate->{ROOT_MODIFIER} = $right;
	$term_candidate->{MODIFIER_POSITION} = "AFTER";

	$left->setROOT($term_candidate);
	$right->setROOT($term_candidate);
    }
    else
    {
	$term_candidate->{ROOT_HEAD} = $right;
	$term_candidate->{ROOT_MODIFIER} = $left;
	$term_candidate->{MODIFIER_POSITION} = "BEFORE";
	$left->setROOT($term_candidate);
	$right->setROOT($term_candidate);
    }

#     print STDERR "\nID : " . $term_candidate->getID . "(" . $$offset . ")\n";
    
    $term_candidate->completeOccurrences($$offset);

#     print STDERR ">>>exit\n";
    $term_candidate->setIslands($phrase_island_set,$left,$right);

    push @$term_candidates_a, $term_candidate;

      $$offset += $old_offset;

    return $term_candidate;
}




sub getHeadPosition
{
    my ($this) = @_;
    if($this->{LEFT_STATUS} eq "HEAD")
    {
	return "LEFT";
    }
    return "RIGHT";
}

sub getModifierPosition
{
    my ($this) = @_;
    if($this->{LEFT_STATUS} eq "MODIFIER")
    {
	return "LEFT";
    }
    return "RIGHT";
}


sub searchLeftMostNode
{
 my ($this) = @_;
    
    my $left;
   
    $left = $this->getLeftEdge;
    if ((blessed($left)) && ($left->isa('Lingua::YaTeA::Node')))
    {
	$left = $left->searchLeftMostNode;
    }
    return $this;
}

sub searchRightMostNode
{
 my ($this) = @_;
    
    my $right;
   
    $right = $this->getRightEdge;
    if ((blessed($right)) && ($right->isa('Lingua::YaTeA::Node')))
    {
	$right = $right->searchRightMostNode;
    }
    return $this;
}

sub fillIndexSet
{
    my ($this,$index_set, $depth) = @_;
    $depth++;
    if ($depth < 50) { # Temporary added by thierry Hamon 02/03/2007
	if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::TermLeaf')))
	{
	    $index_set->addIndex($this->getLeftEdge->getIndex);	
	}
	else
	{
	    $this->getLeftEdge->fillIndexSet($index_set,$depth);
	}
	if (defined $this->getPreposition)
	{
	    $index_set->addIndex($this->getPreposition->getIndex);
	}
	if (defined $this->getDeterminer)
	{
	    $index_set->addIndex($this->getDeterminer->getIndex);
	}
	if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::TermLeaf')))
	{
	    $index_set->addIndex($this->getRightEdge->getIndex);	
	}
	else
	{
	    if(defined $this->getRightEdge)
	    {
# 	warn "vvvvv\n";
# 	warn $this->getRightEdge->getRightEdge . "\n";
# 	warn "$this\n";
# 	warn "-----\n";
		$this->getRightEdge->fillIndexSet($index_set,$depth);
	    }
	}
    } else {
	warn "fillIndexSet: Going out a deep recursive method call (more than 50 calls)\n";
    }
}

sub plugInternalNode
{
    my ($this,$internal_node,$previous_index,$next_index,$parsing_pattern_set,$words_a,$parsing_direction,$tag_set,$fh) = @_;
    my $record;
    my $intermediate_node_set;
    my $new_previous_index;
    my $new_next_index;
#     print $fh "plugInternalNode\n";
#     print $fh "previous : ". $previous_index . "\n";
#     print $fh "above:";
#     $this->printRecursively($words_a,$fh);
#     print $fh "internal node :" ;
#     $internal_node->printRecursively($words_a,$fh);
    my ($node,$place) = $this->searchRoot->getNodeOfLeaf($previous_index,$internal_node->searchHead(0)->getIndex,$words_a,$fh);
    
 #   print $fh $node->getID . "  -> place : ". $place . "\n";
    if($place =~ /LEFT|RIGHT/)
    {
	if(!defined $node)
	{
	    die;
	}
	else{

	    if(
	       ((blessed($node->getEdge($place))) && ($node->getEdge($place)->isa('Lingua::YaTeA::Node')))
	       ||
	       ($node->getEdge($place)->getIndex != $previous_index)
	       ||
	       ($node->getEdgeStatus($place) ne "HEAD")
	       )
	    {
		$new_previous_index = $node->searchHead(0)->getIndex;
		if($new_previous_index < $internal_node->searchHead(0)->getIndex)
		{
		    $previous_index = $new_previous_index;
		}
	    }
	}
    }
    ($node,$place) = $this->searchRoot->getNodeOfLeaf($next_index,$internal_node->searchHead(0)->getIndex,$words_a,$fh);
#    print $fh "second choix:" . $node->getID . "  -> place : ". $place . "(next=" .$next_index .")\n";
    if($place =~ /LEFT|RIGHT/)
    {
	if(
	   ((blessed($node->getEdge($place))) && ($node->getEdge($place)->isa('Lingua::YaTeA::Node')))
	   ||
	   ($node->getEdge($place)->getIndex != $next_index)
	   ||
	   ($node->getEdgeStatus($place) ne "HEAD")
	   )
	{
	    $new_next_index = $node->searchHead(0)->getIndex;
	    if($new_next_index > $internal_node->searchHead(0)->getIndex)
	    {
		$next_index  = $new_next_index;
	    }
	}
	#	   print $fh "nouveau next? : " .$next_index ."\n";
    }

    my $left_index_set = Lingua::YaTeA::IndexSet->new;
    $left_index_set->addIndex($previous_index);
    $left_index_set->addIndex($internal_node->searchHead(0)->getIndex);
    my $right_index_set = Lingua::YaTeA::IndexSet->new;
    $right_index_set->addIndex($internal_node->searchHead(0)->getIndex);
    $right_index_set->addIndex($next_index);
   
    my $attached = 0;
    my $depth = 0;
    my $pos = $words_a->[$previous_index]->getPOS . " " .$words_a->[$internal_node->searchHead(0)->getIndex]->getPOS  ;
#    print $fh "nouveau pos: ". $pos . "\n";
    if ($record = $parsing_pattern_set->existRecord($left_index_set->buildPOSSequence($words_a,$tag_set)))
    {
	$intermediate_node_set = $this->getParseFromPattern($left_index_set,$record,$parsing_direction,$words_a);

	$intermediate_node_set->getRoot->hitch('RIGHT',$internal_node,$words_a);
	($node,$place) = $this->getNodeOfLeaf($previous_index,$internal_node->searchRightMostLeaf(\$depth)->getIndex,$words_a,$fh);
	if(defined $node)
	{
	    if(
		# prevent syntactic break
		($place ne "PREP")  
		&&
		($place ne "DET")
		)
	    {
		if($node->hitch($place,$intermediate_node_set->getRoot,$words_a))
		{
		    $attached = 1;
		}
		else
		{
		    $internal_node->freeFromFather;
		}
	    }
	}
    }
    if($attached == 0)
    {
	$pos = $words_a->[$internal_node->searchHead(0)->getIndex]->getPOS  . " " . $words_a->[$next_index]->getPOS ;
# 	 print $fh "nouveau pos2: ". $pos . "\n";
# 	print $fh "right index set:";
# 	$right_index_set->print($fh);
# 	print $fh "\n";
	if ($record = $parsing_pattern_set->existRecord($right_index_set->buildPOSSequence($words_a,$tag_set)))
	{
#	    print $fh "trouve pattern\n";
	    $intermediate_node_set = $this->getParseFromPattern($right_index_set,$record,$parsing_direction,$words_a);
	    $intermediate_node_set->getRoot->hitch('LEFT',$internal_node,$words_a,$fh);
#	    print $fh "apres oermier hitch\n";
#	    $intermediate_node_set->getRoot->printRecursively($words_a,$fh);
#	    print $fh "next index::" . $next_index . "\n";
	    ($node,$place) = $this->getNodeOfLeaf($next_index,$internal_node->searchRightMostLeaf->getIndex,$words_a,$fh);

	    if(defined $node)
	    {
#		print $fh "second hitch " . $node->getID . "\n";
		if($node->hitch($place,$intermediate_node_set->getRoot,$words_a,$fh))
		{
		    $attached = 1;
		}
		else
		{
		    $internal_node->freeFromFather;
		}
	    }
	}
    }
#    print $fh "resultat:";
#    $this->printRecursively($words_a,$fh);
    return ($attached,$intermediate_node_set);
}


sub getHigherHookNode
{
    my ($this,$index,$position,$to_insert,$fh)  = @_;
    my $node = $this;
   #  	if(defined $fh)
# 	{
# 	    print $fh "entree higher:" . $node->getID . " p: ". $position . "\n";
	    
# 	} 
    if($index < $to_insert)
    {
# 	if(defined $fh)
# 	{
# 	    print $fh "post_insertion\n";
# 	}
	if(
	   ((blessed($node)) && ($node->isa('Lingua::YaTeA::InternalNode')))
	   &&
	   ($node->getFather->getEdgeStatus($position) eq "HEAD")
	   &&
	   (
	    ($position eq "LEFT")
	    &&
	    ($node->getRightEdge->searchLeftMostLeaf->getIndex < $to_insert)
	    )
	   ||
	   (
	    ($position eq "RIGHT")
	    &&
	    ($node->getFather->getRightEdge->searchLeftMostLeaf->getIndex < $to_insert)
	    )
	   )
	{
	    ($node,$position) = $this->getFather->getHigherHookNode($index,$position,$to_insert,$fh);
	}
	
    }
    else
    {
	if($index > $to_insert)
	{
	 #    if(defined $fh)
# 	    {
# 		print $fh "ante_insertion\n";
# 	    }
	    if(
	       ((blessed($node)) && ($node->isa('Lingua::YaTeA::InternalNode')))
	        &&

	       ($node->getEdgeStatus($position) eq "HEAD")
	       &&
		(
	       (
		($position eq "LEFT")
		&&
		($node->getFather->getLeftEdge->searchRightMostLeaf->getIndex > $to_insert)
		)
	       ||
	       (
		($position eq "RIGHT")
		&&
		($node->getLeftEdge->searchRightMostLeaf->getIndex > $to_insert)
		)
		)
	       )
	    {
		$position = $this->getNodePosition;
		($node,$position) = $this->getFather->getHigherHookNode($index,$position,$to_insert,$fh);
	    }
	}
    }
    return ($node,$position);
}


sub getNodeOfLeaf
{
    my ($this,$index,$to_insert,$words_a,$fh) = @_;
    my $node;
    my $position;
   
    #$fh = \*STDERR;
  #   if(defined $fh)
#     {
# 	print $fh "getNodeOfLeaf -- " .$this->getID ." index :" . $index . " insert: ".$to_insert . "\n";
#    }
    if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::TermLeaf')))
    {
# 	if(defined $fh)
# 	{
# 	    print $fh $this->getID  . ": leftedge est une feuille\n";
	    
# 	}
	if ($this->getLeftEdge->getIndex == $index)
	{
	#     if(defined $fh)
# 	    {
# 		print $fh "TROUVE1 " .$index  . "\n";
# 	    }
	    ($node,$position) = $this->getHigherHookNode($index,"LEFT",$to_insert,$fh);
	    	   
	}
	
    }
    else
    {
# 	if(defined $fh)
# 	{
# 	    print $fh $this->getID . ": leftedge est un noeud \n";
# 	}
	($node,$position) = $this->getLeftEdge->getNodeOfLeaf($index,$to_insert,$words_a,$fh);	
    }
    
    if (defined $this->getPreposition)
    {
	if($this->getPreposition->getIndex == $index)
	{
	    return ($this,"PREP");
	}
    }
    if (defined $this->getDeterminer)
    {
	if($this->getDeterminer->getIndex == $index)
	{
	    return ($this,"DET");
	}
    }
    
    if 	(! ((blessed($node)) && ($node->isa('Lingua::YaTeA::Node'))))
    {
	if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::TermLeaf')))
	{
	  #   if(defined $fh)
# 	    {
# 		print $fh $this->getID  . ": rightedge est une feuille\n";
# 	    }
	    if($this->getRightEdge->getIndex == $index)
 	    {
	# 	if(defined $fh)
# 		{
# 		    print $fh "TROUVE2 " .$index  . "\n";
# 		}
		($node,$position) = $this->getHigherHookNode($index,"RIGHT",$to_insert,$fh);
	    }
	}
	else
	{
	  #   if(defined $fh)
# 	    {
# 		print $fh $this->getID . ": rightedge est un noeud \n";
# 	    }
	    ($node,$position) = $this->getRightEdge->getNodeOfLeaf($index,$to_insert,$words_a,$fh);
	}
    }
   #  if
# 	(
# 	 (defined $fh)
# 	 &&
# 	 (defined $node)
# 	 )
#     {
# 	print $fh "le gagnant est: " . $node->getID  . " place: ".$position . "\n";

# 	}     
    return ($node,$position);
}



sub getParseFromPattern
{
    my ($this,$index_set,$pattern_record,$parsing_direction,$words_a) = @_;
    my $pattern;
    my $node_set;
    $pattern = $this->chooseBestPattern($pattern_record->{PARSING_PATTERNS},$parsing_direction);
    $node_set = $pattern->getNodeSet->copy;
    $node_set->fillNodeLeaves($index_set);
    
    return $node_set;
}



sub chooseBestPattern
{
    my ($this,$patterns_a,$parsing_direction) = @_;
    
    my @tmp = sort {$this->sortPatternsByPriority($a,$b,$parsing_direction)} @$patterns_a;
  
    my @sorted = @tmp;

    return $sorted[0];
}



sub isDiscontinuous
{
    my ($this,$previous_r,$words_a,$fh) = @_;
    my $next_node;
    my $infos_a;
#    print $fh "Test discontinu:" . $this->getID . "\n";
       
    if((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::TermLeaf')))
    {
#	print $fh "left : TermLeaf\n"; 
	if(
	    ($$previous_r != -1)
	    &&
	    ($this->getLeftEdge->getIndex > $$previous_r +1)
	    )
	{
	    $infos_a->[0] = -1;
	    $infos_a->[1] = $$previous_r;
	    $infos_a->[2] = $this->getLeftEdge->getIndex;
	    return $infos_a;
	}
	else
	{
	    $$previous_r = $this->getLeftEdge->getIndex; 
#	    print $fh "nouveau previous1: " . $$previous_r . "\n";
	}
    }
    else
    {
#	print $fh "left : node\n"; 
	$infos_a = $this->getLeftEdge->isDiscontinuous($previous_r,$words_a,$fh);
	if($infos_a->[0] == -1)
	{
#	    print $fh " retour: celui la est disconoinut\n";
	    $infos_a->[0] = $this;
	}
	else
	{
	    if ((blessed($infos_a->[0])) && ($infos_a->[0]->isa('Lingua::YaTeA::Node')))
	    {
		
		return $infos_a;
	    }
	}
    }

    if (defined $this->getPreposition)
    {
#	print $fh "y a prep\n";
       if(
	    ($$previous_r != -1)
	    &&
	    ($this->getPreposition->getIndex > $$previous_r +1)
	    )
	{
	    $infos_a->[0] = $this;
	    $infos_a->[1] = $$previous_r;
	    $infos_a->[2] = $this->getPreposition->getIndex;
	    return $infos_a;
	}
       else
       {
	   $$previous_r = $this->getPreposition->getIndex;
#	   print $fh "nouveau previous2: " . $$previous_r . "\n";
      }
    }

    if (defined $this->getDeterminer)
    {
#	print $fh "y a det\n";
	if(
	    ($$previous_r != -1)
	    &&
	    ($this->getDeterminer->getIndex > $$previous_r +1)
	    )
	{
	    $infos_a->[0] = $this;
	    $infos_a->[1] = $$previous_r;
	    $infos_a->[2] = $this->getDeterminer->getIndex;
#	    print $fh "sortie dans det\n";
	    return $infos_a;
	}
	else
	{
	    $$previous_r = $this->getDeterminer->getIndex;
#	    print $fh "nouveau previous3: " . $$previous_r . "\n";
	}
    }

    if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::TermLeaf')))
    {
	# print $fh "right : TermLeaf\n"; 
	# print $fh $this->getRightEdge . " -" ;
	# print $fh $this->getRightEdge->getIndex . "_ ";
	# print $fh $$previous_r . "\n";
	if(
	    ($$previous_r != -1)
	    &&
	    ($this->getRightEdge->getIndex > $$previous_r +1)
	    )
	{
	    $infos_a->[0] = $this;
	    $infos_a->[1] = $$previous_r;
	    $infos_a->[2] = $this->getRightEdge->getIndex;
	    return $infos_a;
	}
	else
	{
	   
	  $$previous_r = $this->getRightEdge->getIndex; 
#	  print $fh "nouveau previous4: " . $$previous_r . "\n";
	}
    }
    else
    {
#	print $fh "right : Node\n"; 
	if((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::Node')))
	{
	    if($this->getRightEdge->searchLeftMostLeaf->getIndex > $$previous_r+1)
	    {
		$infos_a->[0] = $this;
		$infos_a->[1] = $$previous_r;
		$infos_a->[2] = $this->getRightEdge->searchLeftMostLeaf->getIndex;
		return $infos_a;
#	    print $fh "sortie dans right\n";
	    }
	    $infos_a = $this->getRightEdge->isDiscontinuous($previous_r,$words_a,$fh);
	}
	else
	{
	   $infos_a->[0] = 0; 
	}


	if($infos_a->[0] == -1)
	{
	    $infos_a->[0] = $this;
	}
	if ((blessed($infos_a->[0])) && ($infos_a->[0]->isa('Lingua::YaTeA::Node')))
	{
	    return $infos_a;
	}
    }
    $infos_a->[0] = 0;
    return $infos_a;
}


sub adjustPreviousAndNext
{
    my ($this,$previous,$next,$tree) = @_;
    my $new_prev;
    my $new_next;
    my $node;
    my $place;
    my $depth = 0;
    if($this->getLeftEdge->searchHead(0)->getIndex != $previous)
    {

	($node,$place) = $this->searchLeaf($previous,\$depth);
	if(defined $node)
	{
	    while 
		(
		 ((blessed($node)) && ($node->isa('Lingua::YaTeA::InternalNode')))
		 &&
		 (!defined $node->getPreposition)
		 &&
		 ($node->getFather->getID != $this->getID)
		)
	    {
		$node = $node->getFather;
	    }
	    
	    $previous = $node->searchHead(0)->getIndex;
	}
    }
    else
    {
	$new_prev = $previous;
    }
    if($this->getRightEdge->searchHead(0)->getIndex != $next)
    {
	($node,$place) = $this->searchLeaf($next,\$depth);
	if(defined $node)
	{
	    while 
		(
		 ((blessed($node)) && ($node->isa('Lingua::YaTeA::InternalNode')))
		 &&
		 (!defined $node->getPreposition)
		 &&
		 ($node->getFather->getID != $this->getID)
		)
	    {
		$node = $node->getFather;
	    }
	    $next = $node->searchHead(0)->getIndex;
	}
    }
    else
    {
	$new_next = $next;
    }
    return ($new_prev,$new_next);
}


sub completeGap
{
    my ($this,$previous,$next,$tree,$parsing_pattern_set,$parsing_direction,$tag_set,$words_a,$fh) = @_;
    my $index = $previous +1;
    my $gap_index_set = Lingua::YaTeA::IndexSet->new;
    my $sub_pos;
    my $pattern;
    my $position;
    my $node_set;
    my $additional_node_set;
    my $partial_index_set;
    my $success = 0;
  #   print $fh "\n----------------------------------------\ncompleteGap " .$this->getID ." --> p=" .$previous . " n=" .$next . "\n";
#     $this->printRecursively($words_a,$fh);
    while ($index < $next)
    {
	$gap_index_set->addIndex($index++);
    }

    
    if($gap_index_set->getSize > 1) # multi-word gap
    {
	$sub_pos = $gap_index_set->buildPOSSequence($words_a,$tag_set);
#	    print $fh "pos seq: " .$sub_pos . "\n"; 
	($pattern,$position) = $this->getPartialPattern($gap_index_set,$tag_set,$parsing_direction,$parsing_pattern_set,$words_a);
	if ((blessed($pattern)) && ($pattern->isa('Lingua::YaTeA::ParsingPattern')))
	{
	    $partial_index_set = $gap_index_set->getPartial($pattern->getLength,$position);
	    $node_set = $pattern->getNodeSet->copy;
	    $node_set->fillNodeLeaves($partial_index_set);
	    ($success,$additional_node_set) = $this->plugInternalNode($node_set->getRoot,$previous,$next,$parsing_pattern_set,$words_a,$parsing_direction,$tag_set,$fh);
	    if($success == 1)
	    {
		$tree->addNodes($node_set);
		$tree->addNodes($additional_node_set);
		if ($tree->getSimplifiedIndexSet->simplify($partial_index_set,$additional_node_set,$tree,-1) == -1 ) {return 0;}
		if ($gap_index_set->simplify($partial_index_set,$additional_node_set,$tree,-1) == -1 ) {return 0;}
		$tree->updateRoot;
		return 1;
	    }
	    
	}
	else
	{
	    $success = 0;
	}
	if($success == 0)
	{
	    $success = $this->insertProgressively($previous,$next,$parsing_direction,$gap_index_set,$tree,$tag_set,$parsing_pattern_set,$words_a,$fh);
	    if($success == 0)
	    {
		return 0;
	    }
# 		print $fh "apres insertProgressiveley\n";
# 		$this->printRecursively($words_a,$fh);
	    return 1;
	}
	
    }
    else # one word gap
    {
	$success = $this->insertOneWord($gap_index_set->getFirst,$previous,$next,$parsing_direction,$tree,$tag_set,$parsing_pattern_set,$words_a,$fh);
	if($success == 1)
	{
	    $gap_index_set->removeIndex($gap_index_set->getFirst);  
	    # 	print $fh "apres insertOneWord\n";
# 		$this->printRecursively($words_a,$fh);
	}
# 	    else
# 	    {
# 		print $fh "echec insertOneWord\n";
# 	    }
	
	return $success;
    }
#     print $fh "fin complete Gap2\n";
#     $this->printRecursively($words_a,$fh);
    
    return 1;
    
}

sub insertProgressively
{
    my ($this,$previous,$next,$parsing_direction,$gap_index_set,$tree,$tag_set,$parsing_pattern_set,$words_a,$fh) = @_;
    my $success;
#    print $fh "insertProgresivley " . $previous . " n :" . $next . "\n";
    if($parsing_direction eq "LEFT")
    {
	$success = $this->insertOneWord($gap_index_set->getFirst,$previous,$next,$parsing_direction,$tree,$tag_set,$parsing_pattern_set,$words_a,$fh);
	if($success == 0)
	{
	    $success = $this->insertOneWord($gap_index_set->getLast,$previous,$next,$parsing_direction,$tree,$tag_set,$parsing_pattern_set,$words_a,$fh);  
	    if($success == 1)
	    {
		$gap_index_set->removeIndex($gap_index_set->getLast);  
	    }
	}
	else
	{
	    $gap_index_set->removeIndex($gap_index_set->getFirst);
	}
    }
    
    if($parsing_direction eq "RIGHT")
    {
	$success = $this->insertOneWord($gap_index_set->getLast,$previous,$next,$parsing_direction,$tree,$tag_set,$parsing_pattern_set,$words_a,$fh);
	if($success == 0)
	{
	    $success = $this->insertOneWord($gap_index_set->getFirst,$previous,$next,$parsing_direction,$tree,$tag_set,$parsing_pattern_set,$words_a,$fh); 
	     if($success == 1)
	    {
		$gap_index_set->removeIndex($gap_index_set->getFirst);  
	    }
	}
	else
	{
	    $gap_index_set->removeIndex($gap_index_set->getLast);  
	}
    }

    return $success;
    
}

sub insertOneWord
{
    my ($this,$index,$previous,$next,$parsing_direction,$tree,$tag_set,$parsing_pattern_set,$words_a,$fh) = @_;
    my $pos;
    my $record;
    my $node_set;
    my $index_set;
    my $above;
    my $hook_node;
    my $place;
    my $attached = 0;
    my $node;
    my $new_previous;
    my $new_next;
    my %other_place = ("LEFT" => "RIGHT", "RIGHT" => "LEFT");
#    print $fh "insertion mot n: " . $index  . " entre " . $previous . " et  " . $next . "\n";

    if($tag_set->existTag('DETERMINERS',$words_a->[$index]->getPOS))
    {
	while($this->searchLeftMostLeaf->getIndex > $index)
	{
	    if ((blessed($this)) && ($this->isa('Lingua::YaTeA::InternalNode')))
	    {
		$this = $this->getFather
	    }
	    else
	    {
		return 0;
	    }
	}
	if(!defined $this->getDeterminer)
	{
	    $this->addDeterminer($index);
	    $tree->getSimplifiedIndexSet->removeIndex($index);
	    $tree->getIndexSet->addIndex($index);
#	    print $fh "reussi\n";
	    return 1;
	}
	else
	{
	    return 0;
	}
    }
    else
    {
	if(! $tag_set->existTag('PREPOSITIONS',$words_a->[$index]->getIF))
	{

	    ($node,$place) = $this->searchRoot->getNodeOfLeaf($previous,$index,$words_a);
#	    print $fh "dans le noeud courant:" . $node->getID .  " p:" . $place . "\n";
	    if ((defined $place) && ($place =~ /EDGE/))
	    {
		if(!defined $node)
		{
		    die;
		}
		else{
		    if(
		       ((blessed($node->getEdge($place))) && ($node->getEdge($place)->isa('Lingua::YaTeA::Node')))
		       ||
		       ($node->getEdge($place)->getIndex != $previous)
		       ||
		       ($node->getEdgeStatus($place) ne "HEAD")
		       )
		    {
			$new_previous = $node->getEdge($place)->searchHead(0);
			if($new_previous->getIndex < $index)
			{
			    $previous = $new_previous->getIndex;
			}
		    }
#		    print $fh "nouveau previous? : " .$previous ."\n";

		}
	    }
	    ($node,$place) = $this->searchRoot->getNodeOfLeaf($next,$index,$words_a,$fh);
#	    print $fh "dans le noeud tete:" . $node->getID .  " p:" . $place . "\n";
	    if(!defined $node)
	    {
		die;
	    }
	    if (
		(defined $node) 
		&& 
		($place =~ /(LEFT|RIGHT)/)
#		(isa($node,'Lingua::YaTeA::Edge'))
		)
	    {
		
# 		print $fh "place : " . $place ." (next=" .$next .")\n";
# 		print $fh "statut de " . $place . " dans " . $node->getID ." = " .$node->getEdgeStatus($place) . "\n";

		if(
		   ((blessed($node->getEdge($place))) && ($node->getEdge($place)->isa('Lingua::YaTeA::Node')))
		   ||
		   ($node->getEdge($place)->getIndex != $next)
		   ||
		   ($node->getEdgeStatus($place) ne "HEAD")
		   )
		{
		    $new_next = $node->searchHead(0);
		    if ((defined $new_next)
			&&
			($new_next->getIndex > $index)
		       )
		    {
			$next = $new_next->getIndex;
		    }
		    else
		    {
			return 0;
		    }
		}
	
#		print $fh "nouveau next? : " .$next ."\n";
	    }
	    if($parsing_direction eq "LEFT") # left-first search
	    {
		$index_set = Lingua::YaTeA::IndexSet->new;
		$index_set->addIndex($previous);
		$index_set->addIndex($index);
		$pos = $index_set->buildPOSSequence($words_a,$tag_set);
#		print $fh "POS: " . $pos . "\n";
		if ($record = $parsing_pattern_set->existRecord($pos))
		{
		    
		    $node_set = $this->getParseFromPattern($index_set,$record,$parsing_direction,$words_a);
		    ($hook_node,$place) = $this->getNodeOfLeaf($previous,$index,$words_a);
		    if((defined $hook_node) && ($hook_node->hitch($place,$node_set->getRoot,$words_a)))
		    {
			$tree->addNodes($node_set);
			$tree->getSimplifiedIndexSet->removeIndex($index);
			$tree->getIndexSet->addIndex($index);
			$attached = 1;
		    } else {
			if (!defined $hook_node) {
			    warn "hook_node undefined";
			}
		    }
		}
		if($attached == 0)
		{
		    $index_set = Lingua::YaTeA::IndexSet->new;
		    
		    $index_set->addIndex($index);
		    $index_set->addIndex($next);
		    $pos = $index_set->buildPOSSequence($words_a,$tag_set);

		    if ($record = $parsing_pattern_set->existRecord($pos))
		    {
			
			$node_set = $this->getParseFromPattern($index_set,$record,$parsing_direction,$words_a);
			($hook_node,$place) = $this->getNodeOfLeaf($next,$index,$words_a);
			if($hook_node->hitch($place,$node_set->getRoot,$words_a))
			{
			    $tree->addNodes($node_set);
			    $tree->getSimplifiedIndexSet->removeIndex($index);
			    $tree->getIndexSet->addIndex($index);
			    $attached = 1;
			}
		    }
		}
		
	    }
	    if( # right-first search
		($parsing_direction eq "RIGHT")
		||
		($attached == 0)
		)
	    {
		$index_set = Lingua::YaTeA::IndexSet->new;
		
		$index_set->addIndex($index);
		$index_set->addIndex($next);
# 		print $fh "recherche pattern pour ";
# 		$index_set->print($fh);
# 		print $fh "\n";
		$pos = $index_set->buildPOSSequence($words_a,$tag_set);
#		print $fh "POS: " . $pos . "\n";
		if ($record = $parsing_pattern_set->existRecord($pos))
		{
#		    print $fh "trouve\n";
		    $node_set = $this->getParseFromPattern($index_set,$record,$parsing_direction,$words_a);

		    ($hook_node,$place) = $this->getNodeOfLeaf($next,$index,$words_a,$fh);
		    if ((blessed($hook_node)) && ($hook_node->isa('Lingua::YaTeA::Node')))
		    {
			if($hook_node->hitch($place,$node_set->getRoot,$words_a))
			{
			    $tree->addNodes($node_set);
			    $tree->getSimplifiedIndexSet->removeIndex($index);
			    $tree->getIndexSet->addIndex($index);
			    $attached = 1;
			}
		    }
		    else
		    {
			if($node_set->getRoot->hitch("LEFT",$this,$words_a))
			{
			    $tree->addNodes($node_set);
			    $tree->getSimplifiedIndexSet->removeIndex($index);
			    $tree->getIndexSet->addIndex($index);
			    $attached = 1;
			}
			
		    }
		}
		if($attached == 0)
		{
		    $index_set = Lingua::YaTeA::IndexSet->new;
		    $index_set->addIndex($previous);
		    $index_set->addIndex($index);
		    
		   #  print $fh "recherche pattern pour ";
# 		    $index_set->print($fh);
# 		    print $fh "\n";
		    $pos = $index_set->buildPOSSequence($words_a,$tag_set);
	#	    print $fh "POS: " . $pos . "\n";
		    if ($record = $parsing_pattern_set->existRecord($pos))
		    {
			$node_set = $this->getParseFromPattern($index_set,$record,$parsing_direction,$words_a,$fh);

			($hook_node,$place) = $this->getNodeOfLeaf($previous,$index,$words_a,$fh);

			if ((blessed($hook_node)) && ($hook_node->isa('Lingua::YaTeA::Node')))
			{
		# 	    print $fh "hook: ". $hook_node->getID . " place:".$place."\n"; 
# 			    print $fh "root :" . $node_set->getRoot->getID . "\n";
			    if($hook_node->hitch($place,$node_set->getRoot,$words_a,$fh))
			    {
				$tree->addNodes($node_set);
				$tree->getSimplifiedIndexSet->removeIndex($index);
				$tree->getIndexSet->addIndex($index);
				$attached = 1;
			    }
			}
			else
			{
			   
			    if($node_set->getRoot->hitch("RIGHT",$this,$words_a))
			    {
				$tree->addNodes($node_set);
				$tree->getSimplifiedIndexSet->removeIndex($index);
				$tree->getIndexSet->addIndex($index);
				$attached = 1;
			    }
			    
			}
		    }
		}
	    }
	}
    }
#    print $fh "reussi "  .$attached . " \n";
    return $attached;
}

sub getPartialPattern
{
   my ($this,$simplified_index_set,$tag_set,$parsing_direction,$parsing_pattern_set,$words_a) = @_;
   my $pattern;
   my $position;
   my $POS  = $simplified_index_set->buildPOSSequence($words_a,$tag_set);
   if($parsing_direction eq "LEFT")
   {
       ($pattern,$position) = $this->getPatternsLeftFirst($POS,$parsing_pattern_set,$parsing_direction);
   }
   else{
       ($pattern,$position) = $this->getPatternsRightFirst($POS,$parsing_pattern_set,$parsing_direction);
   }
   return ($pattern,$position);
}



sub getPatternsLeftFirst
{
    my ($this,$POS,$parsing_pattern_set,$parsing_direction) = @_;
    my $pattern;
    my $position = "LEFT";
    if (
	($pattern = $this->getPatternOnTheLeft($POS,$parsing_pattern_set,$parsing_direction))
	&&
	($pattern == 0)
	)
    {
	$pattern = $this->getPatternOnTheRight($POS,$parsing_pattern_set,$parsing_direction);
	$position = "RIGHT";
    }
    return ($pattern,$position);
}

sub getPatternsRightFirst
{
    my ($this,$POS,$parsing_pattern_set,$parsing_direction) = @_;
    my $pattern;
    my $position = "RIGHT";
    if (
	($pattern = $this->getPatternOnTheRight($POS,$parsing_pattern_set,$parsing_direction))
	&&
	($pattern == 0)
	)
    {
	$pattern = $this->getPatternOnTheLeft($POS,$parsing_pattern_set,$parsing_direction);
	$position = "LEFT";
    }
    
    return ($pattern,$position);
}

sub getPatternOnTheLeft
{
    my ($this,$POS,$parsing_pattern_set,$parsing_direction) = @_;
    my @selection;
    my $key;
    my $record;
    my $pattern;
    my $qm_key;

    while (($key,$record) = each %{$parsing_pattern_set->getRecordSet})
    {
	$qm_key = quotemeta($key);
	if ($POS =~ /^$qm_key/)
	{
	    foreach $pattern (@{$record->getPatterns})
	    {
		push @selection, $pattern;
	    }
	}
    }
    $pattern = $this->chooseBestPattern(\@selection,$parsing_direction);
    return $pattern;
}

sub getPatternOnTheRight
{
    my ($this,$POS,$parsing_pattern_set,$parsing_direction) = @_;
    my @selection;
    my $key;
    my $record;
    my $pattern;
    my $qm_key;

    while (($key,$record) = each %{$parsing_pattern_set->getRecordSet})
    {
	$qm_key = quotemeta($key);
	if ($POS =~ /$qm_key$/)
	{
	    foreach $pattern (@{$record->getPatterns})
	    {
		push @selection, $pattern;
	    }
	}
    }
    $pattern = $this->chooseBestPattern(\@selection,$parsing_direction);
    return $pattern;
}


# sub chooseBestPattern
# {
#     my ($this,$patterns_a,$parsing_direction) = @_;
    
#     my @tmp = sort {$this->sortPatternsByPriority($a,$b,$parsing_direction)} @$patterns_a;
#     my @sorted = @tmp;
    
#     return $sorted[0];
# }

sub sortPatternsByPriority
{
    my ($this,$first,$second,$parsing_direction) = @_;

    if($first->getDirection eq $parsing_direction)
    {
	if($second->getDirection eq $parsing_direction)
	{
	    if($first->getNumContentWords > $second->getNumContentWords)
	    {
		return -1;
	    }
	    else
	    {
		if($first->getNumContentWords < $second->getNumContentWords)
		{
		    return 1;
		}
		else
		{
		    return ($second->getPriority <=> $first->getPriority);
		}
	    }
	}
	else
	{
	    return -1;
	}
    }
    else
    {
	if($second->getDirection eq $parsing_direction)
	{
	    return 1;
	}
	else
	{
	    if($first->getNumContentWords > $second->getNumContentWords)
	    {
		return -1;
	    }
	    else
	    {
		if($first->getNumContentWords < $second->getNumContentWords)
		{
		    return 1;
		}
		else
		{
		    return ($second->getPriority <=> $first->getPriority);
		}
	    }
	}
    }
}

sub addDeterminer
{
    my ($this,$index) = @_;
    my $new_leaf = Lingua::YaTeA::TermLeaf->new($index);
    $this->{DET} = $new_leaf;
}

sub getHookNode
{
    my ($this,$insertion_type,$place,$below_index_set,$fh) = @_;
    my $hook = $this;
    my $intermediate;
    my $depth = 0;
    my $right_most;
    my %other_place = ("LEFT"=>"RIGHT", "RIGHT"=>"LEFT");
#    print $fh "type insertion : " . $insertion_type . "\n";
    if($insertion_type eq "RIGHT")
    {
	##### SA debug 14/01/2008
#	print $fh "right most : " .$hook->getLeftEdge->searchRightMostLeaf->getIndex . "\n";

	if(
	   ($hook->getEdgeStatus($place) eq "MODIFIER")
	   &&
	   ($hook->getEdge($other_place{$place})->searchRightMostLeaf->getIndex > $below_index_set->getFirst)
	   )
	{
	    undef $hook;
	}
	else
	{
# 	    if(! isa($hook,'Lingua::YaTeA::RootNode'))
# 	    {
# 		print $fh "status :". $hook->getEdgeStatus($place) . "\n";
# 		print $fh "frere: " . $hook->getEdge($other_place{$place})->searchRightMostLeaf->getIndex . "\n";
# 	    }
	    while (
		   (! ((blessed($hook)) && ($hook->isa('Lingua::YaTeA::RootNode'))))
		   &&
		   (	       
		    (
		     ($place eq "RIGHT")
		     &&
		     ($hook->getEdge($other_place{$place})->searchRightMostLeaf->getIndex > $below_index_set->getFirst)
		     )
		    ||
		    (
		     ($place eq "LEFT")
		     &&
		     ($hook->getFather->getLeftEdge->searchRightMostLeaf->getIndex > $below_index_set->getFirst)
		     )
	            )
		   &&
		   ($hook->getEdgeStatus($place) eq "HEAD")
		   )
	    {
		$intermediate = $hook;
#		print $fh "on entre la\n";
		if ((blessed($hook)) && ($hook->isa('Lingua::YaTeA::InternalNode')))
		{
		    $place = $hook->getNodePosition;
		    $hook = $hook->getFather;
		}
		else
		{
		    undef $hook;
		    last;
		}
#		print $fh "right most : " .$hook->getLeftEdge->searchRightMostLeaf->getIndex . "\n";
	    }
	    if(defined $intermediate)
	    {
		if($intermediate->searchLeftMostLeaf->getIndex < $below_index_set->getFirst)
		{
		    undef $hook; 
		}
	    }
	}
    }

    if($insertion_type eq "LEFT")
    {
#	print $fh "left most : " .$hook->getRightEdge->searchLeftMostLeaf->getIndex . "\n";
	while ($hook->getRightEdge->searchLeftMostLeaf->getIndex < $below_index_set->getFirst)
	{
	    $intermediate = $hook;
	    if ((blessed($hook)) && ($hook->isa('Lingua::YaTeA::InternalNode')))
	    {
	        $hook = $hook->getFather;
	    }
	    else
	    {
		undef $hook;
		last;
	    }
	}
	if(defined $intermediate)
	{
	    if($intermediate->searchRightMostLeaf(\$depth)->getIndex > $below_index_set->getLast)
	    {
		undef $hook; 
	    }
	}
    }
    
    return ($hook,$intermediate,$place);
}

sub linkToIsland
{
    my ($this) = @_;
    $this->{"LINKED_TO_ISLAND"} = 1;
    if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::Node')))
    {
	$this->getLeftEdge->linkToIsland;
    }
    if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::Node')))
    {
	$this->getRightEdge->linkToIsland;
    }
    
}

1;

__END__

=head1 NAME

Lingua::YaTeA::Node - Perl extension for ???

=head1 SYNOPSIS

  use Lingua::YaTeA::Node;
  Lingua::YaTeA::Node->();

=head1 DESCRIPTION


=head1 METHODS

=head2 new()


=head2 addEdge()


=head2 getEdgeStatus()


=head2 getLeftEdgeStatus()


=head2 getRightEdgeStatus()


=head2 getNodeStatus()


=head2 getNodePosition()


=head2 getHead()


=head2 getModifier()


=head2 getLeftEdge()


=head2 getRightEdge()


=head2 getEdge()


=head2 getID()


=head2 getLevel()


=head2 getDeterminer()


=head2 getPreposition()


=head2 linkToFather()


=head2 fillLeaves()


=head2 searchHead()


=head2 printSimple()


=head2 printRecursively()


=head2 searchRoot()


=head2 hitchMore()


=head2 hitch()


=head2 freeFromFather()


=head2 plugSubNodeSet()


=head2 checkCompatibility()


=head2 checkNonCrossing()


=head2 copyRecursively()


=head2 searchLeftMostLeaf()


=head2 searchRightMostLeaf()


=head2 getPreviousWord()


=head2 getNextWord()


=head2 findWordContext()


=head2 buildIF()


=head2 buildParenthesised()


=head2 searchLeaf()


=head2 updateLeaves()


=head2 buildTermList()


=head2 getHeadPosition()


=head2 getModifierPosition()


=head2 searchLeftMostNode()


=head2 searchRightMostNode()


=head2 fillIndexSet()


=head2 plugInternalNode()


=head2 getNodeOfLeaf()


=head2 getParseFromPattern()


=head2 chooseBestPattern()


=head2 isDiscontinuous()


=head2 adjustPreviousAndNext()


=head2 completeGap()


=head2 insertProgressively()


=head2 insertOneWord()


=head2 getPartialPattern()


=head2 getPatternsLeftFirst()


=head2 getPatternsRightFirst()


=head2 getPatternOnTheLeft()


=head2 getPatternOnTheRight()


=head2 sortPatternsByPriority()


=head2 addDeterminer()


=head2 getHookNode()


=head2 linkToIsland()



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
