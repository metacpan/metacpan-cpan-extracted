package Lingua::Align::LinkSearch::PaCoMT;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::LinkSearch::GreedyWellFormed);

use Lingua::Align::LinkSearch;

sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    $self->{LINKNT} = 
	new Lingua::Align::LinkSearch(-link_search =>'NTonlyGreedyWellformed');

    $self->{LINKT} = 
	new Lingua::Align::LinkSearch(-link_search =>'TonlyGreedyWellformed');

    $self->{FINAL} = 
	new Lingua::Align::LinkSearch(-link_search =>'GreedyWeaklyWellformedFinal');

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

    $self->{LINKNT}->search($linksST,$scores,$min_score,
			    $src,$trg,
			    $stree,$ttree,$linksTS);
    $self->{LINKT}->search($linksST,$scores,$min_score,
			   $src,$trg,
			   $stree,$ttree,$linksTS);
    $self->{FINAL}->search($linksST,$scores,$min_score,
			   $src,$trg,
			   $stree,$ttree,$linksTS);

    return 1;

}


1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::PaCoMT - Link search used in the PaCoMT project

=head1 SYNOPSIS

  use YADWA;

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
