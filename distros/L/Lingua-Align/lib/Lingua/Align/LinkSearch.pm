#-*-perl-*-

package Lingua::Align::LinkSearch;

=head1 NAME

Lingua::Align::LinkSearch - Search algorithms for tree alignment

=head1 SYNOPSIS

    my $aligner = new Lingua::Align::LinkSearch(-link_search => $type);
    $aligner->search(\%links,\@scores,$min_score,\@src,\@trg)

=head1 DESCRIPTION

Class factory for searching the best tree alignment based on local
link scores Various strategies have been implemented. Use the argument
C<-link_search> in the constructor to choose from the following
search strategies:

 threshold .............. greedy search with score thresholds
 assignment ............. bipartite graph matching (assignment problem)
 greedy ................. greedy search
 greedyWellformed ....... greedy search with well-formedness constraints
 greedyFinal ............ add step to link unlinked nodes (if wellformed)
 greedyFinalAnd ......... add step to link still unlinked nodes
 src2trg ................ source-to-target alignment (one link / source)
 trg2src ................ target-to-source alignment (one link / target)
 src2trgWellFormed ...... src2trg with wellformedness constraints
 intersection ........... intersection between src2trg and trg2src
 NTfirst ................ align non-terminals nodes first
 NTonly ................. align only non-terminals
 Tonly .................. align only termnal nodes
 PaCoMT ................. used in PaCoMT project
 cascaded ............... conbine search strategies (sequentially)

=cut

use 5.005;
use strict;

use FileHandle;
use Lingua::Align::LinkSearch::Threshold;
use Lingua::Align::LinkSearch::Greedy;
use Lingua::Align::LinkSearch::GreedyWellFormed;
use Lingua::Align::LinkSearch::GreedyFinal;
use Lingua::Align::LinkSearch::GreedyFinalAnd;
use Lingua::Align::LinkSearch::Src2Trg;
use Lingua::Align::LinkSearch::Src2TrgWellFormed;
use Lingua::Align::LinkSearch::Trg2Src;
use Lingua::Align::LinkSearch::Intersection;
use Lingua::Align::LinkSearch::NTFirst;
use Lingua::Align::LinkSearch::NTonly;
use Lingua::Align::LinkSearch::Tonly;
use Lingua::Align::LinkSearch::Assignment;
use Lingua::Align::LinkSearch::PaCoMT;
use Lingua::Align::LinkSearch::Cascaded;
use Lingua::Align::LinkSearch::Viterbi;
use Lingua::Align::LinkSearch::AssignmentWellFormed;


sub new{
    my $class=shift;
    my %attr=@_;

#    my $type = $attr{-link_search} || 'greedy';
    my $type = $attr{-link_search} || 'threshold';

    if ($type=~/^cascaded/i){
	return new Lingua::Align::LinkSearch::Cascaded(%attr);
    }
    if ($type=~/^viterbi/i){
	return new Lingua::Align::LinkSearch::Viterbi(%attr);
    }
    if ($type=~/paco/i){
	return new Lingua::Align::LinkSearch::PaCoMT(%attr);
    }

    # NT nodes first using the search strategy specified thereafter
    if ($type=~/^nt.*first/i){
	return new Lingua::Align::LinkSearch::NTFirst(%attr);
    }
    if ($type=~/and/i){
	return new Lingua::Align::LinkSearch::GreedyFinalAnd(%attr);
    }
    if ($type=~/final/i){
	return new Lingua::Align::LinkSearch::GreedyFinal(%attr);
    }

    # NT nodes first but "final" and "and" are handled before
    if ($type=~/nt.*first/i){
	return new Lingua::Align::LinkSearch::NTFirst(%attr);
    }

    if ($type=~/ntonly/i){
	return new Lingua::Align::LinkSearch::NTonly(%attr);
    }
    if ($type=~/tonly/i){
	return new Lingua::Align::LinkSearch::Tonly(%attr);
    }
    if ($type=~/src2trg.*well.*form/i){
	return new Lingua::Align::LinkSearch::Src2TrgWellFormed(%attr);
    }
    if ($type=~/src2trg/i){
	return new Lingua::Align::LinkSearch::Src2Trg(%attr);
    }
    if ($type=~/trg2src/i){
	return new Lingua::Align::LinkSearch::Trg2Src(%attr);
    }
    if ($type=~/inter/i){
	return new Lingua::Align::LinkSearch::Intersection(%attr);
    }
    if ($type=~/(assign|munkres).*wellform/i){
	return new Lingua::Align::LinkSearch::AssignmentWellFormed(%attr);
    }
    if ($type=~/(assign|munkres)/i){
	return new Lingua::Align::LinkSearch::Assignment(%attr);
    }
    if ($type=~/well.*formed/i){
	return new Lingua::Align::LinkSearch::GreedyWellFormed(%attr);
    }
    if ($type=~/greedy/i){
	return new Lingua::Align::LinkSearch::Greedy(%attr);
    }
    return new Lingua::Align::LinkSearch::Threshold(%attr);
}


# virtual method for checking additional constraints such as wellformedness
# (check if a proposed link would meet the constraints!)

sub check_constraints{
    my $self=shift;
    my ($srctree,$trgtree,$snode,$tnode,$linksST)=@_;
}

# remove all candidates which are linked already (exactly that link)

sub remove_existing_links{
    my ($self,$linksST,$scores,$src,$trg)=@_;
    my (@newscores,@newsrc,@newtrg);
    foreach (0..$#{$scores}){
	if (exists $$linksST{$$src[$_]}){
	    if (exists $$linksST{$$src[$_]}{$$trg[$_]}){
		next;
	    }
	}
	push(@newscores,$$scores[$_]);
	push(@newsrc,$$src[$_]);
	push(@newtrg,$$trg[$_]);
    }
    @{$scores}=@newscores;
    @{$src}=@newsrc;
    @{$trg}=@newtrg;
}


# remove all candidates for which both nodes already have ANY link

sub remove_already_linked{
    my ($self,$linksST,$linksTS,$scores,$src,$trg)=@_;
    my (@newscores,@newsrc,@newtrg);
    foreach (0..$#{$scores}){
	if (exists $$linksST{$$src[$_]}){
	    if (exists $$linksTS{$$trg[$_]}){
		next;
	    }
	}
	push(@newscores,$$scores[$_]);
	push(@newsrc,$$src[$_]);
	push(@newtrg,$$trg[$_]);
    }
    @{$scores}=@newscores;
    @{$src}=@newsrc;
    @{$trg}=@newtrg;
}



1;
__END__


=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann, E<lt>jorg.tiedemann@lingfil.uu.seE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
