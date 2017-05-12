package Lingua::Align::LinkSearch::GreedyWellFormed;

use 5.005;
use strict;
use Lingua::Align::LinkSearch::Greedy;
use Lingua::Align::Corpus::Treebank;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::LinkSearch::Greedy);


sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    # set weak wellformedness
    if ($attr{-link_search}=~/weak/i){
	$self->{-weak_wellformedness} = 1;
    }

    # for tree manipulation
    $self->{TREES} = new Lingua::Align::Corpus::Treebank();

    return $self;
}


sub search{
    my $self=shift;
    my ($linksST,$scores,$min_score,$src,$trg,
	$srctree,$trgtree,$linksTS)=@_;

    my %value=();
    foreach (0..$#{$scores}){
	if ($$scores[$_]>=$min_score){
	    $value{$$src[$_].':'.$$trg[$_]}=$$scores[$_];
	}
    }

    if (ref($linksTS) ne 'HASH'){$linksTS={};}
#    my %linksTS=();

    foreach my $k (sort {$value{$b} <=> $value{$a}} keys %value){
	last if ($value{$k}<$min_score);
	my ($snid,$tnid)=split(/\:/,$k);

	# check if these nodes have been linked already
	# for "weak" wellformedness: skip only of both are linked already
	# otherwise: do not allow mulit-links!

	if ($self->{-weak_wellformedness}){
	    next if ((exists $$linksST{$snid}) && (exists $$linksTS{$tnid}));
	}
	else{
	    next if ((exists $$linksST{$snid}) || (exists $$linksTS{$tnid}));
	}

	## check well-formedness .....
	if ($self->is_wellformed($srctree,$trgtree,$snid,$tnid,$linksST)){
	    $$linksST{$snid}{$tnid}=$value{$k};
	    $$linksTS{$tnid}{$snid}=$value{$k};
	}
#	else{
#	    print STDERR "($snid:$tnid) not wellformed! --> skip\n"
#		if ($self->{-verbose});
#	}
    }
    $self->remove_already_linked($linksST,$linksTS,$scores,$src,$trg);
    return 1;
}



sub check_constraints{
    my $self=shift;
    return $self->is_wellformed(@_);
}


sub is_wellformed{
    my $self=shift;
    my ($srctree,$trgtree,$snode,$tnode,$linksST)=@_;

    # source -> target links
    foreach my $s (keys %{$linksST}){

	my $src_is_desc = $self->{TREES}->is_descendent($srctree,$s,$snode);
	my $src_is_anc;
	if (not $src_is_desc){
	    $src_is_anc = $self->{TREES}->is_ancestor($srctree,$s,$snode);
	}

	foreach my $t (keys %{$$linksST{$s}}){
	    next if ($s eq $snode && $t eq $tnode);  # identical link is OK!

	    my $trg_is_desc = $self->{TREES}->is_descendent($trgtree,$t,$tnode);
	    my $trg_is_anc;
	    if (not $trg_is_desc){
		$trg_is_anc = $self->{TREES}->is_ancestor($trgtree,$t,$tnode);
	    }
	    
	    if ($src_is_desc){              # both nodes are descendents
		next if ($trg_is_desc);
		if ($self->{-weak_wellformedness}){
		    next if ($t eq $tnode);     
		}
	    }
	    elsif ($src_is_anc){            # both are ancestors
		next if ($trg_is_anc);
		if ($self->{-weak_wellformedness}){
		    next if ($t eq $tnode);
		}
	    }
	    elsif ($s eq $snode){
		if ($self->{-weak_wellformedness}){
		    next if ($trg_is_desc || $trg_is_anc);
		}
	    }
	    else{                           # both are not connected
		next if (not ($trg_is_desc || $trg_is_anc));
	    }
	    return 0;                       # otherwise: not well-formed!
	}
    }

    return 1;
}




1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::GreedyWellFormed - Greedy search with wellformedness constraints

=head1 SYNOPSIS

=head1 DESCRIPTION

This module does the same as L<Lingua::Align::LinkSearch::Greedy> but adds a wellformedness constraint (no links across subtrees). The option "-weak_wellformedness" relaxes this constraint by allowing multiple links to one node.

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann, E<lt>j.tiedemanh@rug.nl@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
