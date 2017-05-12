package Lingua::Align::LinkSearch::Threshold;

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
    $self->{-min_score} = $attr{-min_score} || 0.5;

    return $self;
}

sub search{
    my $self=shift;
    my ($linksST,$scores,$min_score,$src,$trg)=@_;

    if (not defined $min_score){$min_score=$self->{-min_score};}

    my %linksTS=();
    foreach (0..$#{$scores}){
	if ($$scores[$_]>=$min_score){
	    $$linksST{$$src[$_]}{$$trg[$_]}=$$scores[$_];
	    $linksTS{$$trg[$_]}{$$src[$_]}=$$scores[$_];
	}
    }
    $self->remove_already_linked($linksST,\%linksTS,$scores,$src,$trg);
    return 1;
}


1;
__END__

=head1 NAME

Lingua::Align::LinkSearch::Threshold - Greedy linking with score thresholds

=head1 SYNOPSIS

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
