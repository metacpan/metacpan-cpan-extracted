

package Lingua::Align::Corpus::Parallel::Moses;

use 5.005;
use strict;

use vars qw($VERSION @ISA);
@ISA = qw(Lingua::Align::Corpus::Parallel::Giza);

$VERSION = '0.01';

use Lingua::Align::Corpus;
use Lingua::Align::Corpus::Parallel::Giza;


sub read_next_alignment{
    my $self=shift;
    my ($src,$trg,$links)=@_;

    my $file=$_[3] || $self->{-alignfile};
    my $encoding=$_[4] || $self->{-encoding};
    my $ids=$_[5];

    if (exists $self->{-src_file}){
	$self->{SRC}->next_sentence($src);
    }
    if (exists $self->{-trg_file}){
	$self->{TRG}->next_sentence($trg);
    }

    my $fh=$self->open_file($file,$encoding);

    if ($_=<$fh>){
	chomp;
#	print STDERR $_;
	my @align = split(/\s+/);
	foreach my $l (@align){
	    my ($s,$t)=split(/\-/,$l);
	    $$links{$s}{$t}=1;
	}
	if (ref($ids) eq 'ARRAY'){
	    @{$ids}=$self->next_sentence_ids();
	}
	return 1;
    }
    return 0;    
}


1;
__END__

=head1 NAME

Lingua::Align::Corpus::Parallel::Moses - Perl extension to read sentence-aligned parallel corpora in Moses format

=head1 SYNOPSIS

  use Lingua::Align::Corpus::Parallel;

  my $corpus = new Lingua::Align::Corpus::Parallel(-srcfile => $srcfile,
                                                   -trgfile => $trgfile,
                                                   -type => 'moses');

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann, E<lt>j.tiedemann@rug.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
