package Lingua::Align::LinkSearch::Src2TrgWellFormed;

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
	    $value{$$src[$_].':'.$$trg[$_]}=$$scores[$_];
	}
    }

    if (ref($linksTS) ne 'HASH'){$linksTS={};}
#    my %linksTS=();

    foreach my $k (sort {$value{$b} <=> $value{$a}} keys %value){
	last if ($value{$k}<$min_score);
	my ($snid,$tnid)=split(/\:/,$k);

	next if (exists $$linksST{$snid});        # one link per source node!

	if (! $self->{-weak_wellformedness} ){    # weak wellformedness:
	    next if (exists $$linksTS{$tnid});    # -> allow multi-links
	}

	## check well-formedness .....
	if ($self->is_wellformed($srctree,$trgtree,$snid,$tnid,$linksST)){
	    # mark "weakly" wellformed with suffix 'w'
	    if (exists $$linksTS{$tnid}){
		$$linksST{$snid}{$tnid}=$value{$k}.'w';
		$$linksTS{$tnid}{$snid}=$value{$k}.'w';
	    }
	    else{
		$$linksST{$snid}{$tnid}=$value{$k};
		$$linksTS{$tnid}{$snid}=$value{$k};
	    }
	}
    }
    $self->remove_already_linked($linksST,$linksTS,$scores,$src,$trg);
    return 1;
}


sub is_wellformed{
    my $self=shift;
    my ($srctree,$trgtree,$snode,$tnode,$linksST)=@_;

    foreach my $s (keys %{$linksST}){
	my $src_is_desc = $self->{TREES}->is_descendent($srctree,$s,$snode);
	my $src_is_anc;
	if (not $src_is_desc){
	    $src_is_anc = $self->{TREES}->is_ancestor($srctree,$s,$snode);
	}

	foreach my $t (keys %{$$linksST{$s}}){
	    if ($src_is_desc){
		if (!$self->{TREES}->is_descendent($trgtree,$t,$tnode)){
		    return 0 if ($t ne $tnode);
		}
	    }
	    if ($src_is_anc){
		if (!$self->{TREES}->is_ancestor($trgtree,$t,$tnode)){
		    return 0 if ($t ne $tnode);
		}
	    }
	}
    }

    # all links are fine! ---> wellformed!
    return 1;
}




1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::Src2TrgWellFormed - Source-to-target alignment with constraints

=head1 SYNOPSIS

=head1 DESCRIPTION

This module implements an alignment strategy that greedily aligns the best scoring target tree node to each source tree node. Only one link per source tree node is allowed. Wellformedness constraints are enforced. The option "-weal_wellformedness" relaxes the constraint and allows multiple links per target node.

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
