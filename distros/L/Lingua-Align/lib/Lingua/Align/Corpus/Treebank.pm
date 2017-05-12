package Lingua::Align::Corpus::Treebank;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus);

use Lingua::Align::Corpus;
use Lingua::Align::Corpus::Treebank::Penn;
use Lingua::Align::Corpus::Treebank::Berkeley;
use Lingua::Align::Corpus::Treebank::Stanford;
use Lingua::Align::Corpus::Treebank::TigerXML;
use Lingua::Align::Corpus::Treebank::AlpinoXML;


sub new{
    my $class=shift;
    my %attr=@_;

    if ($attr{-type}=~/tiger/i){
	return new Lingua::Align::Corpus::Treebank::TigerXML(%attr);
    }
    if ($attr{-type}=~/alpino/i){
	return new Lingua::Align::Corpus::Treebank::AlpinoXML(%attr);
    }
    if ($attr{-type}=~/stanford/i){
	return new Lingua::Align::Corpus::Treebank::Stanford(%attr);
    }
    if ($attr{-type}=~/berkeley/i){
	return new Lingua::Align::Corpus::Treebank::Berkeley(%attr);
    }
    return new Lingua::Align::Corpus::Treebank::Penn(%attr);
}


sub close{
    my $self=shift;
    my $file=shift || $self->{-file};
    $self->close_file($file);
}


# next sentence returns a tree for the next sentence
# (here: only virtual function ....)
sub read_next_sentence{}

sub next_sentence_id{}            # return next sentence ID and move to next
sub next_sentence_id_would_be{}   # return next sentence ID and stay at current


sub root_node{
    my $self=shift;
    my ($tree)=@_;
    if (exists $tree->{ROOTNODE}){
	return $tree->{ROOTNODE};
    }
    foreach (keys %{$tree->{NODES}}){
	if ((not exists $tree->{NODES}->{$_}->{PRENTS}) || 
	    (scalar @{$tree->{NODES}->{$_}->{PRENTS}} == 0)){
	    $tree->{ROOTNODE}=$_;
	    return $_;
	}
    }
    return undef;  # no root node? ---> no tree structure?
}

sub distance_to_root{
    my $self=shift;
    my ($tree,$node)=@_;
#    return 0 if (not defined $node);
#    return 0 if ($node eq '');
    if (exists $tree->{NODES}->{$node}->{TREELEVEL}){
	return $tree->{NODES}->{$node}->{TREELEVEL};
    }
    my $this=$node;
    my $count=0;
    while (exists $tree->{NODES}->{$this}->{PARENTS}){
	last if (scalar @{$tree->{NODES}->{$this}->{PARENTS}} == 0);
	$count++;
	$this=$tree->{NODES}->{$this}->{PARENTS}->[0];
	last if (not exists $tree->{NODES}->{$this});
    }
    $tree->{NODES}->{$node}->{TREELEVEL}=$count;
    return $count;
}

sub tree_size{
    my $self=shift;
    my $tree=shift;
    return $tree->{TREESIZE} if (exists $tree->{TREESIZE});
    my $size=0;
    foreach my $n (keys %{$tree->{NODES}}){
	my $level=$self->distance_to_root($tree,$n);
	if ($level>$size){$size=$level;}
    }
    $tree->{TREESIZE} = $size;   # cache tree size for later calls!
    return $size;
}

sub get_all_nodes{
    my $self=shift;
    my $tree=shift;
    return sort keys %{$tree->{NODES}};
}

sub get_all_leafs{
    my $self=shift;
    my ($tree,$attr)=@_;
    $attr = 'word' if (not defined $attr);
    my @words=();
    if (ref($tree->{TERMINALS}) eq 'ARRAY'){
	foreach my $n (@{$tree->{TERMINALS}}){
	    push(@words,$tree->{NODES}->{$n}->{$attr});
	}
    }
    return @words;
}

sub is_nonterminal{
    my $self=shift;
    my ($tree,$node)=@_;
    if (exists $tree->{NODES}){
	if (exists $tree->{NODES}->{$node}){
	    if (exists $tree->{NODES}->{$node}->{CHILDREN}){
		return 1;
	    }
	    if (exists $tree->{NODES}->{$node}->{CHILDREN2}){
		return 1;
	    }
	}
    }
    return 0;
}

sub is_terminal{
    my $self=shift;
    return not $self->is_nonterminal(@_);

    ## caching this information? not really necessary .... 
    # 
    # if (exists $_[0]->{NODES}){
    # 	if (exists $_[0]->{NODES}->{$_[1]}){
    # 	    if (exists $_[0]->{NODES}->{$_[1]}->{TERMINAL_NODE}){
    # 		return 1;
    # 	    }
    # 	}
    # }
    # if (not $self->is_nonterminal(@_)){
    # 	$_[0]->{NODES}->{$_[1]}->{TERMINAL_NODE} = 1;
    # 	return 1;
    # }
    # $_[0]->{NODES}->{$_[1]}->{NONTERMINAL_NODE} = 1;
    # return 0;
}

 sub is_descendent{
    my $self=shift;
    my ($tree,$desc,$anc)=@_;

    # look at ancestor relation cache first
    if (exists $tree->{__IS_ANCESTOR__}){
	if (exists $tree->{__IS_ANCESTOR__}->{$anc}){
	    if (exists $tree->{__IS_ANCESTOR__}->{$anc}->{$desc}){
		return $tree->{__IS_ANCESTOR__}->{$anc}->{$desc};
	    }
	}
    }

    my @parents=();
    if (exists $tree->{NODES}->{$desc}->{PARENTS}){
	@parents = @{$tree->{NODES}->{$desc}->{PARENTS}};
    }
    while (@parents){
	my $p=shift(@parents);
	if ($p eq $anc){
	    $tree->{__IS_ANCESTOR__}->{$anc}->{$desc}=1; # add relation to cache
	    return 1;
	}
	if ($self->is_descendent($tree,$p,$anc)){
	    $tree->{__IS_ANCESTOR__}->{$anc}->{$desc}=1;
	    $tree->{__IS_ANCESTOR__}->{$anc}->{$p}=1;
	    return 1;
	}
	$tree->{__IS_ANCESTOR__}->{$anc}->{$p}=0;
    }
    $tree->{__IS_ANCESTOR__}->{$anc}->{$desc}=0;
    return 0;
}


sub is_ancestor{
    my $self=shift;
    my ($tree,$anc,$desc)=@_;
    return $self->is_descendent($tree,$desc,$anc);
}


# get all parents for a given node in a given tree

sub parents{
    my $self=shift;
    my ($tree,$node)=@_;
    if (exists $tree->{NODES}->{$node}->{PARENTS}){
	return @{$tree->{NODES}->{$node}->{PARENTS}};
    }
    return ();
}

# get (first) parent

sub parent{
    my $self=shift;
    my ($tree,$node)=@_;
    if (exists $tree->{NODES}->{$node}->{PARENTS}){
	return $tree->{NODES}->{$node}->{PARENTS}->[0];
    }
    return undef;
}

# get all children

sub children{
    my $self=shift;
    my ($tree,$node)=@_;
    if (exists $tree->{NODES}->{$node}->{CHILDREN}){
	return @{$tree->{NODES}->{$node}->{CHILDREN}};
    }
    return ();
}

# return yield of subtree == get_leafs

sub yield{
  my $self=shift;
  return $self->get_leafs(@_);
}

# get all nodes in the subtree

sub subtree_nodes{
    my $self=shift;
    my ($tree,$node)=@_;
    my @subtree=();
    my @children=$self->children($tree,$node);
    foreach my $c (@children){
	push (@subtree,$c);
	push (@subtree,$self->subtree_nodes($tree,$c));
    }
    return @subtree;
}

# get all sister nodes

sub sisters{
    my $self=shift;
    my ($tree,$node)=@_;
    my @sisters=();
    if (exists $tree->{NODES}->{$node}->{PARENTS}){
	foreach my $p (@{$tree->{NODES}->{$node}->{PARENTS}}){
	    foreach my $s (@{$tree->{NODES}->{$p}->{CHILDREN}}){
		if ($node ne $s){
		    push(@sisters,$s);
		}
	    }
	}
    }
    return @sisters;
}


# get neighbor nodes
# $pos gives the distance to the current node
# $pos > 0 ---> right neighbors
# $pos < 0 ---> left neighbors

sub neighbor{
    my ($self,$tree,$node,$pos)=@_;

    # terminal node? --> easy!

    if ($self->is_terminal($tree,$node)){
	my ($start,$end) = $self->subtree_span($tree,$node);
	my $n = $start + $pos;
	
	if ($#{$tree->{TERMINALS}} >= $n-1){
	    return $tree->{TERMINALS}->[$n-1];
	}
    }

    # non-terminals: get left/right neighbors iteratively
    # (this only gives sister nodes dominated by the same parent)
    # (should we also try to move into neighboring sub-trees?)

    else{
	for (0..$pos){

	    if ($pos>0){ $node = $self->right_neighbor($tree,$node); }
	    else {       $node = $self->left_neighbor($tree,$node); }

	    if (! $node){ return undef; }
	    return $node;
	}
    }

    return undef;
}




sub left_neighbor{
    my ($self,$tree,$node)=@_;

    if (exists $tree->{NODES}->{$node}->{LEFTNEIGHBOR}){
	return $tree->{NODES}->{$node}->{LEFTNEIGHBOR};
    }

    my ($parent) = $self->parent($tree,$node);
    if ($parent){
	my @children = $self->children($tree,$parent);
	my $left=undef;
	foreach my $c (@children){
	    if ($c eq $node){
		$tree->{NODES}->{$node}->{LEFTNEIGHBOR} = $left;
		return $left;
	    }
	    $left = $c;
	}
    }
    $tree->{NODES}->{$node}->{LEFTNEIGHBOR} = undef;
    return undef;
}


sub right_neighbor{
    my ($self,$tree,$node)=@_;

    if (exists $tree->{NODES}->{$node}->{RIGHTNEIGHBOR}){
	return $tree->{NODES}->{$node}->{RIGHTNEIGHBOR};
    }

    my ($parent) = $self->parent($tree,$node);
    if ($parent){
	my @children = $self->children($tree,$parent);
	foreach my $c (0..$#children-1){
	    if ($children[$c] eq $node){
		$tree->{NODES}->{$node}->{RIGHTNEIGHBOR} = $children[$c+1];
		return $children[$c+1];
	    }
	}
    }
    $tree->{NODES}->{$node}->{RIGHTNEIGHBOR} = undef;
    return undef;
}




sub is_unary_subtree{
    my $self=shift;
    my ($tree,$node,$child)=@_;
    if (exists $tree->{NODES}){
	if (exists $tree->{NODES}->{$node}){
	    if (exists $tree->{NODES}->{$node}->{CHILDREN}){
		if ($#{$tree->{NODES}->{$node}->{CHILDREN}} == 0){
		    $$child = $tree->{NODES}->{$node}->{CHILDREN}->[0];
		    return 1;
		}
	    }
	}
    }
    return 0;
}

sub get_outside_leafs{
    my $self=shift;
    my ($tree,$node,$attr)=@_;
    $attr = 'word' if (not defined $attr);

    ## check if subtree leafs with the specified attr are already stored
    if (exists($tree->{NODES}->{$node}->{OUTLEAFS})){
	if (exists($tree->{NODES}->{$node}->{OUTLEAFS}->{$attr})){
	    if (ref($tree->{NODES}->{$node}->{OUTLEAFS}->{$attr}) eq 'ARRAY'){
		return @{$tree->{NODES}->{$node}->{OUTLEAFS}->{$attr}};
	    }
	}
	## if we have IDs --> get the attribute from the nodes
	elsif (exists($tree->{NODES}->{$node}->{OUTLEAFS}->{id})){
	    if (ref($tree->{NODES}->{$node}->{OUTLEAFS}->{id}) eq 'ARRAY'){
		my @ids = @{$tree->{NODES}->{$node}->{OUTLEAFS}->{id}};
		my @val=();
		foreach my $i (@ids){
		    push (@val,$tree->{NODES}->{$i}->{$attr});
		}
		return @val;
	    }
	}
    }

    my @leafs=@{$tree->{TERMINALS}};
    my @ids = $self->get_leafs($tree,$node,'id');

    my %inside=();
    foreach (@ids){$inside{$_}=1;}

    my @outside=();
    foreach (@leafs){
	if (!exists($inside{$_})){
	    push(@outside,$tree->{NODES}->{$_}->{$attr});
	}
    }
    ## cache this
    @{$tree->{NODES}->{$node}->{OUTLEAFS}->{$attr}}=@outside;
    return @outside;
}



sub get_nr_leafs{
    my $self=shift;
    my ($tree,$node)=@_;

    if (exists $tree->{NODES}->{$node}){

	# leaf nodes --> just one alone ....
	return 1 if (! exists $tree->{NODES}->{$node}->{CHILDREN});

	# check cached value
	if (exists($tree->{NODES}->{$node}->{NR_LEAFS})){
	    return $tree->{NODES}->{$node}->{NR_LEAFS};
	}
	if (exists($tree->{NODES}->{$node}->{LEAFS})){
	    my ($key,$val)=each %{$tree->{NODES}->{$node}->{LEAFS}};
	    if (ref($tree->{NODES}->{$node}->{LEAFS}->{$key}) eq 'ARRAY'){
		$tree->{NODES}->{$node}->{NR_LEAFS} = 
		    scalar @{$tree->{NODES}->{$node}->{LEAFS}->{$key}};
		return $tree->{NODES}->{$node}->{NR_LEAFS};
	    }
	}
	my @leafs = $self->get_leafs($tree,$node);
	$tree->{NODES}->{$node}->{NR_LEAFS} = scalar @leafs;
	return $tree->{NODES}->{$node}->{NR_LEAFS};
    }
    return 0;
}



sub get_leafs{
    my $self=shift;
    my ($tree,$node,$attr)=@_;
    return () if (ref($tree) ne 'HASH');
    return () if (ref($tree->{NODES}) ne 'HASH');

    $attr = 'word' if (not defined $attr);

    if (exists $tree->{NODES}->{$node}){

	# I am a leaf! --> return my attr
	if (! exists $tree->{NODES}->{$node}->{CHILDREN}){
	    if (exists $tree->{NODES}->{$node}->{$attr}){
		return ($tree->{NODES}->{$node}->{$attr});
	    }
	    return ();
	}

	## check if subtree leafs with the specified attr 
	## are already stored in cache
	elsif (exists($tree->{NODES}->{$node}->{LEAFS})){
	    if (exists($tree->{NODES}->{$node}->{LEAFS}->{$attr})){
		if (ref($tree->{NODES}->{$node}->{LEAFS}->{$attr}) eq 'ARRAY'){
		    return @{$tree->{NODES}->{$node}->{LEAFS}->{$attr}};
		}
	    }
	    ## if we have IDs --> get the attribute from the nodes
	    elsif (exists($tree->{NODES}->{$node}->{LEAFS}->{id})){
		if (ref($tree->{NODES}->{$node}->{LEAFS}->{id}) eq 'ARRAY'){
		    my @ids = @{$tree->{NODES}->{$node}->{LEAFS}->{id}};
		    my @val=();
		    foreach my $i (@ids){
			push (@val,$tree->{NODES}->{$i}->{$attr});
		    }
		    @{$tree->{NODES}->{$node}->{LEAFS}->{$attr}} = @val;
		    return @val;
		}
	    }
	}

	if (ref($tree->{NODES}->{$node}->{CHILDREN}) eq 'ARRAY'){
	    my @leafs=();
	    foreach my $c (@{$tree->{NODES}->{$node}->{CHILDREN}}){
		push(@leafs,$self->get_leafs($tree,$c,$attr));
	    }
	    ## cache subtree leafs ....
	    @{$tree->{NODES}->{$node}->{LEAFS}->{$attr}} = @leafs;
	    $tree->{NODES}->{$node}->{NR_LEAFS} = scalar @leafs;
	    return @leafs;
	}

	print STDERR "WARNING: Something must be wrong here!\n";

	if (exists $tree->{NODES}->{$node}->{$attr}){
	    return ($tree->{NODES}->{$node}->{$attr});
	}
    }
    return ();
}


sub subtree_span{
    my $self=shift;
    my ($tree,$node)=@_;
    if (exists $tree->{NODES}->{$node}->{begin}){
	if (exists $tree->{NODES}->{$node}->{end}){
	    return ($tree->{NODES}->{$node}->{begin},
		    $tree->{NODES}->{$node}->{end});
	}
    }

    my @leafs = $self->get_leafs($tree,$node,'id');
    my %hash=();
    foreach (@leafs){$hash{$_}=1;}
    my $start=9999999;
    my $end=0;
    foreach (0..$#{$tree->{TERMINALS}}){
	if (exists $hash{$tree->{TERMINALS}->[$_]}){
	    if ($_<$start-1){$start = $_+1;}
	    if ($_>=$end){$end = $_+1;}
	}
    }
    if ($start<9999999 && $end>0){
	$tree->{NODES}->{$node}->{begin} = $start;
	$tree->{NODES}->{$node}->{end} = $end;
	return ($start,$end);
    }
    print STDERR "Strange? no start & end of the tree-span? ('$node' $start-$end)\n";
    return ();
}

sub print_sentence{
    my $self=shift;
    return $self->print_tree(@_);
}

sub print_tree{
    my $self=shift;
    my $tree=shift;
    return '';
}

1;
__END__


=head1 NAME

Lingua::Align::Corpus::Treebank - Factory class for reading treebanks

=head1 SYNOPSIS

    my $treebank = new Lingua::Align::Corpus::Treebank(-file => $corpusfile,
                                                       -type => 'TigerXML');

  my %tree=();
  while ($treebank->next_sentence(\%tree)){
    print $treebank->print_sentence(\%tree);
    print "\n";
  }

=head1 DESCRIPTION

Factory class of modules for reading treebanks in different formats. The default format is the Penn Treebank format. Other supported formats are the format produced by the Berkeley parser, the Stanford parser (including typed dependencies), TigerXML and Alpino XML.

=head2 EXPORT

=head1 SEE ALSO

L<Lingua::Align::Corpus>
L<Lingua::Align::Corpus::Treebank::Penn>
L<Lingua::Align::Corpus::Treebank::Berkeley>
L<Lingua::Align::Corpus::Treebank::Stanford>
L<Lingua::Align::Corpus::Treebank::TigerXML>
L<Lingua::Align::Corpus::Treebank::AlpinoXML>


=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
