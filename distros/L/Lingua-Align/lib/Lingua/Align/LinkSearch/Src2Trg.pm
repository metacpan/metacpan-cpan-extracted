package Lingua::Align::LinkSearch::Src2Trg;

use 5.005;
use strict;
use vars qw(@ISA);
use Lingua::Align::LinkSearch::Greedy;

@ISA = qw(Lingua::Align::LinkSearch::Greedy);



sub search{
    my $self=shift;
    return $self->searchSrc2Trg(@_);
}

sub searchSrc2Trg{
    my $self=shift;
    my ($linksST,$scores,$min_score,$src,$trg)=@_;
    
    my %value=();

    my %BestSrc=();
    my %BestLink=();

    foreach (0..$#{$scores}){
	if ($$scores[$_]>=$min_score){
	    if ($$scores[$_]>$BestSrc{$$src[$_]}){
		$BestSrc{$$src[$_]}=$$scores[$_];
		$BestLink{$$src[$_]}=$$trg[$_];
	    }
	}
    }

    my %linksTS=();
    foreach my $s (keys %BestSrc){
	$$linksST{$s}{$BestLink{$s}}=$BestSrc{$s};
	$linksTS{$BestLink{$s}}{$s}=$BestSrc{$s};
    }

    $self->remove_already_linked($linksST,\%linksTS,$scores,$src,$trg);
    return 1;
}


1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::Src2Trg - Source-to-target alignment

=head1 SYNOPSIS

=head1 DESCRIPTION

This module implements an alignment strategy that greedily aligns the best scoring target tree node to each source tree node. Only one link per source tree node is allowed.

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann, E<lt>j.tiedemanh@rug.nl@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
