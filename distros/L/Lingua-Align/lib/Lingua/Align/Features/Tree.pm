package Lingua::Align::Features::Tree;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Features);


sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){$self->{$_}=$attr{$_};}

    # make a Treebank object for processing trees
    $self->{TREES} = new Lingua::Align::Corpus::Treebank();

    return $self;
}


sub get_features{
    my $self=shift;
    my ($src,$trg,$srcN,$trgN,$FeatTypes,$values)=@_;
    $self->label_features($src,$trg,$srcN,$trgN,$FeatTypes,$values);
    $self->tree_features($src,$trg,$srcN,$trgN,$FeatTypes,$values);
}



#-------------------------------------------------------------------
# sub routines for the different feature types 
# (this is time consuming and should be optimized!?)


sub label_features{
    my $self=shift;
    my ($srctree,$trgtree,$srcnode,$trgnode,$FeatTypes,$values)=@_;

    ## category or POS pair

    if (exists $$FeatTypes{catpos}){
	my $key='catpos_';
	if (exists $srctree->{NODES}->{$srcnode}->{cat}){
	    $key.=$srctree->{NODES}->{$srcnode}->{cat};
	}
	elsif (exists $srctree->{NODES}->{$srcnode}->{pos}){
	    $key.=$srctree->{NODES}->{$srcnode}->{pos};
	}
	$key.='_';
	if (exists $trgtree->{NODES}->{$trgnode}->{cat}){
	    $key.=$trgtree->{NODES}->{$trgnode}->{cat};
	}
	elsif (exists $trgtree->{NODES}->{$trgnode}->{pos}){
	    $key.=$trgtree->{NODES}->{$trgnode}->{pos};
	}
	$$values{$key}=1;
    }

    # edge labels
    # (relation to (first) parent) 

    if (exists $$FeatTypes{edge}){
	my $key='edge_';
	if (exists $srctree->{NODES}->{$srcnode}->{RELATION}){
	    if (ref($srctree->{NODES}->{$srcnode}->{RELATION}) eq 'ARRAY'){
		$key.=$srctree->{NODES}->{$srcnode}->{RELATION}->[0];
	    }
	}
	$key.='_';
	if (exists $trgtree->{NODES}->{$trgnode}->{RELATION}){
	    if (ref($trgtree->{NODES}->{$trgnode}->{RELATION}) eq 'ARRAY'){
		$key.=$trgtree->{NODES}->{$trgnode}->{RELATION}->[0];
	    }
	}
	$$values{$key}=1;
    }


}


sub tree_features{
    my $self=shift;
    my ($srctree,$trgtree,         # entire parse tree (source & target)
	$srcnode,$trgnode,         # current tree nodes
	$FeatTypes,$values)=@_;    # feature types to be returned in values

    ## tree span similarity:
    ## take the middle of each subtree-span and 
    ## compute the relative closeness of these positions

    if (exists $$FeatTypes{treespansim}){
	my $srclength=$#{$srctree->{TERMINALS}};
	my $trglength=$#{$trgtree->{TERMINALS}};
	my ($srcstart,$srcend)=$self->{TREES}->subtree_span($srctree,$srcnode);
	my ($trgstart,$trgend)=$self->{TREES}->subtree_span($trgtree,$trgnode);
	my $relsrc=0;
	if ($srclength){
	    $relsrc=($srcstart+$srcend-2)/(2*$srclength);
	}
	my $reltrg=0;
	if ($trglength){
	    $reltrg=($trgstart+$trgend-2)/(2*$trglength);
	}
	$$values{treespansim}=1-abs($relsrc-$reltrg);
    }

    ## tree-level similarity:
    ## similarity of relatie tree levels of given nodes
    ## (tree-level = distance from root)

    if (exists $$FeatTypes{treelevelsim}){
	my $dist1=$self->{TREES}->distance_to_root($srctree,$srcnode);
	my $size1=$self->{TREES}->tree_size($srctree);
	my $dist2=$self->{TREES}->distance_to_root($trgtree,$trgnode);
	my $size2=$self->{TREES}->tree_size($trgtree);
	my $diff=abs($dist1/$size1-$dist2/$size2);
	$$values{treelevelsim}=1-$diff;
    }

    ## ratio between the number of source language words and 
    ## the number of target language words dominated by the given nodes

    if (exists $$FeatTypes{nrleafsratio}){

	my $nrsrcleafs = $self->{TREES}->get_nr_leafs($srctree,$srcnode);
	my $nrtrgleafs = $self->{TREES}->get_nr_leafs($trgtree,$trgnode);

	if ($nrsrcleafs && $nrtrgleafs){
	    if ($nrsrcleafs>$nrtrgleafs){
		$$values{nrleafsratio}=$nrtrgleafs/$nrsrcleafs;
	    }
	    else{
		$$values{nrleafsratio}=$nrsrcleafs/$nrtrgleafs;
	    }
	}
    }
}




1;
