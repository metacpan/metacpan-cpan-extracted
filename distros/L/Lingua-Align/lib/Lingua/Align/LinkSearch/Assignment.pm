package Lingua::Align::LinkSearch::Assignment;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::LinkSearch::GreedyWellFormed);

use Algorithm::Munkres;

sub search{
    my $self=shift;
    my ($linksST,$scores,$min_score,$src,$trg,
	$srctree,$trgtree,$linksTS)=@_;
    $self->assign($linksST,$scores,$min_score,
		  $src,$trg,
		  $srctree,$trgtree,$linksTS);
    $self->remove_already_linked($linksST,$linksTS,$scores,$src,$trg);
    return 1;
}


sub assign{
    my $self=shift;
    my ($linksST,$scores,$min_score,$src,$trg,
	$srctree,$trgtree,$linksTS)=@_;

    my $max=1;       # max score --> use cost=max-score

    # inefficent way to assign position IDs to nodeIDs
    my %SrcIds=();
    my @SrcNodes=();
    my $nr=0;
    foreach (@{$src}){
	if (not exists $SrcIds{$_}){
	    $SrcIds{$_}=$nr;$SrcNodes[$nr]=$_;
	    $nr++;
	}
    }
    my %TrgIds=();
    my @TrgNodes=();
    my $nr=0;
    foreach (@{$trg}){
	if (not exists $TrgIds{$_}){
	    $TrgIds{$_}=$nr;$TrgNodes[$nr]=$_;
	    $nr++;
	}
    }

    # make cost matrix (simply use $max-score)
    my @matrix=();
    foreach (0..$#{$scores}){
	$matrix[$SrcIds{$$src[$_]}][$TrgIds{$$trg[$_]}] = $max-$$scores[$_];
    }

    for my $s (0..$#SrcNodes){
	for my $t (0..$#TrgNodes){
	    if (not $matrix[$s][$t]){
		$matrix[$s][$t]=$max;
	    }
	}
    }


    # assign connections
    my @assignment=();
    &Algorithm::Munkres::assign(\@matrix,\@assignment);

    if (ref($linksTS) ne 'HASH'){$linksTS={};}

    # save links
    foreach (0..$#assignment){
	next if (not $matrix[$_][$assignment[$_]]);
	my $score=$max-$matrix[$_][$assignment[$_]];
	next if ($score<$min_score);
	my ($snid,$tnid);
	$snid = $SrcNodes[$_];
	$tnid = $TrgNodes[$assignment[$_]];
	$$linksST{$snid}{$tnid}=$max-$matrix[$_][$assignment[$_]];
	$$linksTS{$tnid}{$snid}=$max-$matrix[$_][$assignment[$_]];
    }
    return 1;
}


1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::Assignment - Alignment as an assignment problem in bipartite graphs

=head1 SYNOPSIS

=head1 DESCRIPTION

This module uses the Kuhn-Munkres algorithm using Algorithm::Munkres to assign links between tree nodes. In this way, alignment is treated as an assignment problem in a bipartite graph. As a consequence, only one-to-one alignments will be found. Well-formedness constraints for tree alignment cannot be enforced.


=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Hungarian_algorithm>

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
