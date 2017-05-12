package Lingua::Align::LinkSearch::AssignmentWellFormed;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::LinkSearch::Assignment);


sub search{
    my $self=shift;
    my ($linksST,$scores,$min_score,$src,$trg,
	$srctree,$trgtree,$linksTS)=@_;
    $self->assign($linksST,$scores,$min_score,
		  $src,$trg,
		  $srctree,$trgtree,$linksTS);
    my %NotWell=();
    while ($self->check_wellformedness($srctree,$trgtree,$linksST,\%NotWell)){
    	my @sorted = sort { $NotWell{$a} <=> $NotWell{$b} } keys %NotWell;
    	my ($s,$t) = split(/\:/,$sorted[0]);
    	print STDERR "remove link $s --> $t\n";
    	delete $$linksST{$s}{$t};
    	if (not scalar keys %{$$linksST{$s}}){delete $$linksST{$s};}
    	delete $$linksTS{$t}{$s};
    	if (not scalar keys %{$$linksTS{$t}}){delete $$linksTS{$t};}
	%NotWell=();
    }

    $self->remove_already_linked($linksST,$linksTS,$scores,$src,$trg);
    return 1;
}


sub check_wellformedness{
    my $self=shift;
    my ($srctree,$trgtree,$linksST,$NotWell)=@_;
    my $NrNotWell=0;
    foreach my $s (keys %{$linksST}){
	foreach my $t (keys %{$$linksST{$s}}){
	    if (not $self->is_wellformed($srctree,$trgtree,$s,$t,$linksST)){
		$$NotWell{"$s:$t"}=$$linksST{$s}{$t};
#		print STDERR "not wellformed: $s --> $t ($$linksST{$s}{$t})\n";
		$NrNotWell++;
	    }
	}
    }
    return $NrNotWell;
}


1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::AssignmentWellFormed - Alignment as an assignment problem with additional constraints

=head1 SYNOPSIS

=head1 DESCRIPTION

This module does the same as L<Lingua::Align::LinkSearch::Assignment> but removes links which violate wellformedness constraints in a post-processing step.

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
