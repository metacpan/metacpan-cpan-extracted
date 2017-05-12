package Lingua::Align::LinkSearch::GreedyFinalAnd;

#
# do some base alignment and then greedily add links between nodes
# that are not aligned yet (without wellformedness check!)
#

use 5.005;
use strict;

use vars qw($VERSION @ISA);
@ISA = qw(Lingua::Align::LinkSearch::GreedyFinal);
$VERSION = '0.01';

use Lingua::Align::LinkSearch;


sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    my $BaseSearch = $attr{-link_search} || 'greedy_final_and';
    $BaseSearch =~s/\_?[Aa]nd//;
    $attr{-link_search} = $BaseSearch;
    $self->{BASESEARCH} = new Lingua::Align::LinkSearch(%attr);

    # for tree manipulation
    $self->{TREES} = new Lingua::Align::Corpus::Treebank();

    return $self;
}

sub search{
    my $self=shift;
    my ($linksST,$scores,$min_score,
	$src,$trg,
	$stree,$ttree,$linksTS)=@_;

    if (ref($linksTS) ne 'HASH'){$linksTS={};}

    # first do the base search algorithm
    $self->{BASESEARCH}->search($linksST,$scores,$min_score,
				$src,$trg,
				$stree,$ttree,$linksTS);

    foreach my $n (sort {$$scores[$b] <=> $$scores[$a]} (0..$#{$scores})){
	last if ($$scores[$n] < $min_score);

	next if (exists $$linksST{$$src[$n]});
	next if (exists $$linksTS{$$trg[$n]});

#	print STDERR "final_and: add link between $$src[$n] & $$trg[$n]\n";
	$$linksST{$$src[$n]}{$$trg[$n]}=$$scores[$n];
	$$linksTS{$$trg[$n]}{$$src[$n]}=$$scores[$n];
    }
    $self->remove_already_linked($linksST,$linksTS,$scores,$src,$trg);
    return 1;
}


1;
