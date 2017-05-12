
package Lingua::Align::Corpus::Parallel::OrderedIds;

# Bitext in which sentences with the same ID's are aligned
# and IDs are numeric and sorted numerically
#

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Parallel::Bitext);

use Lingua::Align::Corpus::Parallel::Bitext;



sub read_next_alignment{
    my $self=shift;
    my ($src,$trg)=@_;

    return 0 if (not $self->{SRC}->next_sentence($src));
    return 0 if (not $self->{TRG}->next_sentence($trg));


    while ($src->{ID} ne $trg->{ID}){
	while ($src->{ID} > $trg->{ID}){
	    return 0 if (not $self->{TRG}->next_sentence($trg));
	}
	return 1 if ($src->{ID} eq $trg->{ID});
	while ($src->{ID} < $trg->{ID}){
	    return 0 if (not $self->{SRC}->next_sentence($src));
	}
    }
    return 1;

}




1;
__END__

=head1 NAME

Lingua::Align::Corpus::Parallel::OrderedIds - read parallel corpora with ordered sentence IDs

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
