

package Lingua::Align::Corpus::Parallel::Giza;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Parallel::Bitext);


use Lingua::Align::Corpus;
use Lingua::Align::Corpus::Parallel::Bitext;


	

sub read_next_alignment{
    my $self=shift;
    my ($src,$trg,$links)=@_;

    my $file=$_[3] || $self->{-alignfile};
    my $encoding=$_[4] || $self->{-encoding};
    my $ids=$_[5];

    my $fh=$self->open_file($file,$encoding);

    while (<$fh>){
	if (/^\#\s+Sentence pair \(([0-9]+)\) source length ([0-9]+) target length ([0-9]+) alignment score : (.*)$/){
	    $self->{SENT_PAIR}=$1;
	    $self->{SRC_LENGTH}=$2;
	    $self->{TRG_LENGTH}=$3;
	    $self->{ALIGN_SCORE}=$4;
	    my $srcline = <$fh>;
	    chomp $srcline;
	    @{$src}=split(/\s+/,$srcline);
	    my $trgline = <$fh>;
	    chomp $trgline;
	    @{$trg}=();

	    while ($trgline=~/(\S+)\s+\(\{\s*([^\}]*?)\s*\}\)\s+/g){
		push (@{$trg},$1);
		my @wordlinks = split(/\s+/,$2);
		my $trgid=$#{$trg};
		foreach (@wordlinks){
		    $$links{$_}=$trgid;
		}
	    }

	    if (ref($ids) eq 'ARRAY'){
 		@{$ids}=$self->next_sentence_ids();
	    }
	    return 1;
	}
    }
    return 0;
}


1;
__END__

=head1 NAME

Lingua::Align::Corpus::Parallel::Giza - Read the Viterbi word alignment produced by GIZA++

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
