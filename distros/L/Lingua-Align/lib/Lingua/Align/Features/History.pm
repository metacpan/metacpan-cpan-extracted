package Lingua::Align::Features::History;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Features::Tree);


sub get_features{
    my $self=shift;
    my ($src,$trg,$srcN,$trgN,$FeatTypes,$values,$links,$softcount)=@_;

}


# What else can we do?
#
# - other (more specific) history features?!
#   (e.g., category labels between established links in subtree?)
# - treat good & fuzzy links differently in training
# - test the "proper" & inside/outside versions?
#



#----------------------------------------------------------------
#
# history features
#
#----------------------------------------------------------------


# linked_children
#
# - look at link predictions for all *immediate* children nodes 
#   of the current subtree pair
# - normalize number of linked children nodes 
#   by largest number of nodes on either source or target language side
# - in alignment: use prediction likelihood as "soft count"

sub linked_children{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my @srcchildren=$self->{TREES}->children($src,$sn);
    my @trgchildren=$self->{TREES}->children($trg,$tn);
    my $nr=0;
    foreach my $s (@srcchildren){
	foreach my $t (@trgchildren){
	    if (exists $$links{$s}){
		if (exists $$links{$s}{$t}){
		    if ($softcount){                 # prediction mode:
			$nr+=$$links{$s}{$t};        # use prediction prob
#			if ($softcount>0.5){$nr++;}  # (use classification)
		    }
		    else{$nr++;}                     # training mode
		}
	    }
	}
    }
    # normalize by the size of the larger subtree
    # problem: might give us scores > 1 (is this a problem?)
    if ($nr){
	if ($#srcchildren > $#trgchildren){
	    if ($#srcchildren>=0){
		$$values{linkedchildren}=$nr/($#srcchildren+1);
	    }
	}
	elsif ($#trgchildren>=0){
	    $$values{linkedchildren}=$nr/($#trgchildren+1);
	}
    }
}


# linked_subtree
#
# same as linked_subtree but cosider all nodes in the subtree!

sub linked_subtree{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my @srcchildren=$self->{TREES}->subtree_nodes($src,$sn);
    my @trgchildren=$self->{TREES}->subtree_nodes($trg,$tn);
    my $nr=0;
    foreach my $s (@srcchildren){
	foreach my $t (@trgchildren){
	    if (exists $$links{$s}){
		if (exists $$links{$s}{$t}){
		    if ($softcount){
			$nr+=$$links{$s}{$t};
		    }
#		    else{     # normal training: distinguish good/fuzzy/weak!
#			if ($$links{$s}{$t}=~/(fuzzy|P)/){ $nr+=0.5; }
#			elsif ($$links{$s}{$t}=~/(weak)/){ $nr+=0.25; }
#			else{ $nr++; }
#		    }
		    else{$nr++;}
		}
	    }
	}
    }
    if ($nr){
	if ($#srcchildren > $#trgchildren){
	    if ($#srcchildren>=0){
		$$values{linkedsubtree}=$nr/($#srcchildren+1);
	    }
	}
	elsif ($#trgchildren>=0){
	    $$values{linkedsubtree}=$nr/($#trgchildren+1);
	}
    }
}



# linked_parent
#
# - for top-down classification: 
#   return whether parent nodes are linked or not
# - in alignment mode: return prediction likelihood

sub linked_parent{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my $srcparent=$self->{TREES}->parent($src,$sn);
    my $trgparent=$self->{TREES}->parent($trg,$tn);
    my $nr=0;
    if (exists $$links{$srcparent}){
	if (exists $$links{$srcparent}{$trgparent}){
	    if ($softcount){
		$nr+=$$links{$srcparent}{$trgparent};
#		if ($softcount>0.5){$nr++;}
	    }
	    else{$nr++;}
	}
    }
    if ($nr){
	$$values{linkedparent}=$nr;
    }
}


# linked_parent_distance
#
# - for top-down prediction: 
#   measure the distance between the linked parent 
#   and the parent of the current link candidate
# - in case of multiple links (or multiple link likelihoods):
#   compute average distance

sub linked_parent_distance{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my $srcparent=$self->{TREES}->parent($src,$sn);
    my $trgparent=$self->{TREES}->parent($trg,$tn);

    my $nrlinks=0;
    my $dist=0;

    my ($start,$end)=$self->{TREES}->subtree_span($trg,$tn);
    my $trgpos=($start+$end)/2;

    if (exists $$links{$srcparent}){
	foreach my $l (keys %{$$links{$srcparent}}){
	    $nrlinks++;
	    my ($start,$end)=$self->{TREES}->subtree_span($trg,$l);
	    my $pos=($start+$end)/2;
	    if ($softcount){
		$dist+=$$links{$srcparent}{$trgparent}*(abs($pos-$trgpos));
	    }
	    else{
		$dist+=abs($pos-$trgpos);
	    }
	}
    }

    if ($nrlinks){
	$dist/=$nrlinks;
	my $trgsize=$#{$$trg{TERMINALS}}+1;
	$dist/=$trgsize;
	if ($dist){
	    $$values{linkedparentdist}=1-$dist;
	}
    }
}






# alternative history features .... not used yet
#
# linked_children_proper
# linked_subtree_proper
#     --> normalize with total number of src & trg nodes
#     --> scores are always between 0 and 1
#     (punishes nodes with many children too much?!)

sub linked_children_proper{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my @srcchildren=$self->{TREES}->children($src,$sn);
    my @trgchildren=$self->{TREES}->children($trg,$tn);
    my $nr=0;
    my $total=0;
    foreach my $s (@srcchildren){
	if (exists $$links{$s}){
	    foreach my $t (@trgchildren){
		if (exists $$links{$s}{$t}){
		    if ($softcount){$nr+=$$links{$s}{$t};}
		    else{$nr++;}
		}
	    }
	    foreach my $t (keys %{$$links{$s}}){
		if ($softcount){$total+=$$links{$s}{$t};}
		else{$total++;}	
	    }
	}
    }
    if ($nr){
	$$values{linkedchildren2}=$nr/$total;
    }
}

sub linked_subtree_proper{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my @srcchildren=$self->{TREES}->subtree_nodes($src,$sn);
    my @trgchildren=$self->{TREES}->subtree_nodes($trg,$tn);
    my $nr=0;
    my $total=0;
    foreach my $s (@srcchildren){
	if (exists $$links{$s}){
	    foreach my $t (@trgchildren){
		if (exists $$links{$s}{$t}){
		    if ($softcount){$nr+=$$links{$s}{$t};}
		    else{$nr++;}
		}
	    }
	    foreach my $t (keys %{$$links{$s}}){
		if ($softcount){$total+=$$links{$s}{$t};}
		else{$total++;}	
	    }
	}
    }
    if ($nr){
	$$values{linkedsubtree2}=$nr/$total;
    }
}


# linked_children_inside_outside
#
# ratio between links within the subtree pair 
# and links outside of the subtree pair

sub linked_children_inout{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my @srcchildren=$self->{TREES}->children($src,$sn);
    my @trgchildren=$self->{TREES}->children($trg,$tn);

    my %trgLeafIDs=();
    foreach (@trgchildren){$trgLeafIDs{$_}=1;}

    my $inside=0;
    my $outside=0;

    foreach my $s (@srcchildren){
	if (exists $$links{$s}){
	    foreach my $t (keys %{$$links{$s}}){
		if (exists $trgLeafIDs{$t}){
		    if ($softcount){$inside+=$$links{$s}{$t};}
		    else{$inside++;}
		}
		else{
		    if ($softcount){$outside+=$$links{$s}{$t};}
		    else{$outside++;}
		}
	    }
	}
    }
    if ($inside){
	$$values{linkedchildren3}=$inside/($inside+$outside);
    }
}


# linked_subtree_inside_outside
#
# ratio between links within the subtree pair 
# and links outside of the subtree pair

sub linked_subtree_inout{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my @srcchildren=$self->{TREES}->subtree_nodes($src,$sn);
    my @trgchildren=$self->{TREES}->subtree_nodes($trg,$tn);

    my %trgLeafIDs=();
    foreach (@trgchildren){$trgLeafIDs{$_}=1;}

    my $inside=0;
    my $outside=0;

    foreach my $s (@srcchildren){
	if (exists $$links{$s}){
	    foreach my $t (keys %{$$links{$s}}){
		if (exists $trgLeafIDs{$t}){
		    if ($softcount){$inside+=$$links{$s}{$t};}
		    else{$inside++;}
		}
		else{
		    if ($softcount){$outside+=$$links{$s}{$t};}
		    else{$outside++;}
		}
	    }
	}
    }
    if ($inside){
	$$values{linkedsubtree3}=$inside/($inside+$outside);
    }
}





sub linked_subtree_catpos{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$softcount)=@_;
    my @srcchildren=$self->{TREES}->subtree_nodes($src,$sn);
    my @trgchildren=$self->{TREES}->subtree_nodes($trg,$tn);
    my $nr=0;
    foreach my $s (@srcchildren){
	foreach my $t (@trgchildren){
	    if (exists $$links{$s}){
		if (exists $$links{$s}{$t}){
		    my $scat;
		    my $tcat;
		    if (exists $src->{NODES}->{$s}->{cat}){
			$scat=$src->{NODES}->{$s}->{cat};
		    }
		    elsif (exists $src->{NODES}->{$s}->{pos}){
			$scat=$src->{NODES}->{$s}->{pos};
		    }
		    if (exists $trg->{NODES}->{$t}->{cat}){
			$tcat=$trg->{NODES}->{$t}->{cat};
		    }
		    elsif (exists $trg->{NODES}->{$t}->{pos}){
			$tcat=$src->{NODES}->{$t}->{pos};
		    }
		    if ($scat && $tcat){
			if ($softcount){
			    $$values{"linkedsub_$scat\_$tcat"}=$$links{$s}{$t};
			}
			else{
			    $$values{"linkedsub_$scat\_$tcat"}=1;
			}
		    }
		}
	    }
	}
    }
}






# linked_neighbors
#

sub linked_neighbors{
    my $self=shift;
    my ($values,$src,$trg,$sn,$tn,$links,$srcdist,$trgdist,$softcount)=@_;

    my $s = $self->{TREES}->neighbor($src,$sn,$srcdist);
    my $t = $self->{TREES}->neighbor($trg,$tn,$trgdist);

    if ($s && $t){
	if (exists $$links{$s}){
	    if (exists $$links{$s}{$t}){
		if ($softcount){
		    $values->{"linked$srcdist$trgdist"} = $$links{$s}{$t};
		}
		else{
		    $values->{"linked$srcdist$trgdist"} = 1;
		}
	    }
	}
    }
}





1;
