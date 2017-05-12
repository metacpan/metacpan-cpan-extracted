package Lingua::Align::LinkSearch::Viterbi;

use 5.005;
use strict;
use Lingua::Align::LinkSearch::GreedyWellFormed;
use Lingua::Align::Corpus::Treebank;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::LinkSearch::GreedyWellFormed);


sub search{
    my $self=shift;
    my ($linksST,$scores,$min_score,$src,$trg,
	$srctree,$trgtree,$linksTS)=@_;

    my %value=();
    foreach (0..$#{$scores}){
	if ($$scores[$_]>=$min_score){
	    $value{$$src[$_]}{$$trg[$_]}=$$scores[$_];
	}
    }
    if (ref($linksTS) ne 'HASH'){$linksTS={};}

    my $srcroot=$self->{TREES}->root_node($srctree);
    my $trgroot=$self->{TREES}->root_node($trgtree);

    my %link=();
    my %cost=();
    my $final = $self->align_nodes($srcroot,$trgroot,$srctree,$trgtree,\%value,
				   \%link,\%cost);

    # always align root nodes (good?)
    my $s = $srcroot;
    my $t = $trgroot;
    $$linksST{$s}{$t}=$value{$s}{$t};
    $$linksTS{$t}{$s}=$value{$s}{$t};

    $self->read_links($srcroot,$trgroot,$srctree,
		      \%link,\%value,
		      $linksST,$linksTS);

    $self->remove_already_linked($linksST,$linksTS,$scores,$src,$trg);
    return 1;
}


sub read_links{
    my $self=shift;
    my ($srcroot,$trgroot,$srctree,$link,$value,
	$linksST,$linksTS)=@_;

    my @c=$self->{TREES}->children($srctree,$srcroot);
    foreach my $s (@c){
	if (exists $$link{$s} && ref($$link{$s}) eq 'HASH'){
	    if (exists $$link{$s}{$trgroot}){
		my $t = $$link{$s}{$trgroot};
		$$linksST{$s}{$t}=$$value{$s}{$t};
		$$linksTS{$t}{$s}=$$value{$s}{$t};
		$self->read_links($s,$t,$srctree,$link,$value,
				  $linksST,$linksTS);
	    }
	}
    }
}

sub align_nodes{
    my $self=shift;
    my ($srcroot,$trgroot,$srctree,$trgtree,$value,$link,$cost,$indent)=@_;

#    print STDERR "$indent-- subtree $srcroot:$trgroot\n";
    if (defined $$cost{$srcroot}){
	if (defined $$cost{$srcroot}{$trgroot}){
	    return $$value{$srcroot}{$trgroot};
	}
    }

    my $score=0;
    foreach my $s ($self->{TREES}->children($srctree,$srcroot)){
	my ($BestScore,$BestNode)=(0,undef);
	# weak wellformedness: check alignment to target root
	my $ThisScore = $self->align_nodes($s,$trgroot,$srctree,$trgtree,
				       $value,$link,$cost,"$indent--");
	if ($ThisScore > $BestScore){
	    $BestScore=$ThisScore;
	    $BestNode=$trgroot;
	}

	foreach my $t ($self->{TREES}->subtree_nodes($trgtree,$trgroot)){
	    my $ThisScore = $self->align_nodes($s,$t,$srctree,$trgtree,$value,
					   $link,$cost,"$indent--");
	    if ($ThisScore > $BestScore){
		$BestScore=$ThisScore;
		$BestNode=$t;
	    }
	}
	if (defined $BestNode){
	    $$link{$s}{$trgroot}=$BestNode;
	    $$cost{$s}{$trgroot}=$BestScore;
	    $score+=$BestScore;
	    if ($self->{-verbose}){
		print STDERR "$indent--$s-->$BestNode ($BestScore)\n";
	    }
	}
    }

    $score+=$$value{$srcroot}{$trgroot};

##########################################
## normalize (if not switched off ...)
    if (not $self->{-skip_normalize}){
	if ($score){
	    my %linked=();
	    my @c=$self->{TREES}->subtree_nodes($srctree,$srcroot);
	    foreach my $s (@c){
		if (exists $$link{$s} && ref($$link{$s}) eq 'HASH'){
		    if (exists $$link{$s}{$trgroot}){
			my $t = $$link{$s}{$trgroot};
			$linked{$t}++;
		    }
		}
	    }
	    $linked{$trgroot}++;
	    
	    my $nrLinked=0;
	    my $nrLinks=0;
	    foreach (keys %linked){
		$nrLinked++;
		$nrLinks+=$linked{$_};
	    }
#	print STDERR "$indent--multiply score with $nrLinked/$nrLinks\n";
	    if ($nrLinks){
		$score*=$nrLinked/$nrLinks;
	    }
	}
    }
##########################################

    return $score;
}


1;
