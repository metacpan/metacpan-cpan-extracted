package Lingua::Align::LinkSearch::Intersection;

use 5.005;
use strict;
use vars qw(@ISA);
use Lingua::Align::LinkSearch::Src2Trg;
use Lingua::Align::LinkSearch::Trg2Src;

@ISA=qw(Lingua::Align::LinkSearch::Src2Trg Lingua::Align::LinkSearch::Trg2Src);


sub search{
    my $self=shift;
    my ($links,$scores,$min_score,$src,$trg)=@_;

    my %linksST=();
    my %linksTS=();

    my ($c1,$w1,$total1)=
     $self->searchSrc2Trg(\%linksST,$scores,$min_score,$src,$trg);
    my ($c2,$w2,$total2)=
     $self->searchTrg2Src(\%linksTS,$scores,$min_score,$src,$trg);

    if ($total1 <=> $total2){
	print STDERR "strange: total is different for src2trg & trg2src\n";
    }

    foreach my $s (keys %linksST){
	foreach my $t (keys %{$linksST{$s}}){
	    if (exists $linksTS{$t}){
		if (exists $linksTS{$t}{$s}){
		    if ($linksST{$s}{$t}>=$min_score){
			$$links{$s}{$t}=$linksST{$s}{$t};
		    }
		}
	    }
	}
    }
    return 1;
}




1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::Intersection - Intersection between source-to-target and target-to-source alignment

=head1 SYNOPSIS

=head1 DESCRIPTION

This modules implements the intersection of Src2Trg and Trg2Src alignments.

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
