package Lingua::Align::LinkSearch::Cascaded;

#
# cascaded link search: define a sequence of link-search algorithms
#                       to be applied for incremental alignment
#
# The sequence is specified like this:
#
# -link_search = cascaded:strategy1-strategy2-...-strategyN
#
# (names of the strategies separated by '-') any strategy supported by 
# LinkSearch is allowed here. For example:
#
# NTonlySrc2TrgWeaklyWellformed (align NT nodes only using a source-to-target
#                                strategy, checking for weak wellformedness)
# TonlyGreedyWellformed         (align terminals only using a greedy alignment
#                                strategy (1:1 links only) and check for
#                                wellformedness)
# Src2TrgWeaklyWellformed       (align nodes with a source-to-target strategy,
#                                check for weak wellformedness)
# ......
#

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::LinkSearch);

use Lingua::Align::LinkSearch;

sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    my $cascade = $self->{-link_search} || 
	'cascaded:NTonlyGreedyWellformed-GreedyWeaklyWellformedFinal';

    $cascade=~/^[^:]*:\s*(.*)\s*$/;
    @{$self->{CASCADE}} = split(/\-/,$1);
    @{$self->{LINKSEARCH}}=();
    foreach (0..$#{$self->{CASCADE}}){
	$self->{LINKSEARCH}->[$_] = 
	    new Lingua::Align::LinkSearch(-link_search=>$self->{CASCADE}->[$_]);
    }

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

    my ($correct,$wrong,$total);

    foreach my $aligner (@{$self->{LINKSEARCH}}){
	$aligner->search($linksST,$scores,$min_score,
			 $src,$trg,
			 $stree,$ttree,$linksTS);
    }
    return 1;
}


1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::Cascaded - cascaded link search strategies

=head1 SYNOPSIS

=head1 DESCRIPTION

This module allows to combine several alignment inference strategies into a "cascade of linking steps". Use the constructor option '-link_search' to specify the steps to be taken. The syntax is (strategies separated by '-'):

 cascaded:strategy1-strategy2-...

("strategy1", "strategy2" ... are valid alignment strategies which will be applied in the order they are specified in the attribute value above)

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
