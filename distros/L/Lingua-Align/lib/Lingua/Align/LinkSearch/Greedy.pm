package Lingua::Align::LinkSearch::Greedy;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::LinkSearch);

sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    return $self;
}

sub search{
    my $self=shift;
    my ($linksST,$scores,$min_score,$src,$trg)=@_;

    my %value=();
    foreach (0..$#{$scores}){
	if ($$scores[$_]>=$min_score){
	    $value{$$src[$_].':'.$$trg[$_]}=$$scores[$_];
	}
    }

    my %linksTS=();
    foreach my $k (sort {$value{$b} <=> $value{$a}} keys %value){
	last if ($value{$k}<$min_score);
	my ($snid,$tnid)=split(/\:/,$k);
	next if (exists $$linksST{$snid});
	next if (exists $linksTS{$tnid});
	$$linksST{$snid}{$tnid}=$value{$k};
	$linksTS{$tnid}{$snid}=$value{$k};
    }

    $self->remove_already_linked($linksST,\%linksTS,$scores,$src,$trg);
    return 1;
}


1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::Greedy - Simple greedy search for links

=head1 SYNOPSIS

=head1 DESCRIPTION

This module implements a greedy best-first alignment strategy that allows one-to-one links only (competitive linking).

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
