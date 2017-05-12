#

package Lingua::Align::Corpus::Parallel;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus);

use Lingua::Align::Corpus;

# sentence aligned
use Lingua::Align::Corpus::Parallel::Bitext;
use Lingua::Align::Corpus::Parallel::OPUS;
use Lingua::Align::Corpus::Parallel::OrderedIds;

# word aligned
use Lingua::Align::Corpus::Parallel::Giza;
use Lingua::Align::Corpus::Parallel::Moses;
use Lingua::Align::Corpus::Parallel::WPT;

# tree aligned
use Lingua::Align::Corpus::Parallel::STA;
use Lingua::Align::Corpus::Parallel::Dublin;


sub new{
    my $class=shift;
    my %attr=@_;

    if ($attr{-type}=~/(sta|stockholm)/i){
	return new Lingua::Align::Corpus::Parallel::STA(%attr);
    }
    if ($attr{-type}=~/dublin/i){
	return new Lingua::Align::Corpus::Parallel::Dublin(%attr);
    }
    if ($attr{-type}=~/giza/i){
	return new Lingua::Align::Corpus::Parallel::Giza(%attr);
    }
    if ($attr{-type}=~/moses/i){
	return new Lingua::Align::Corpus::Parallel::Moses(%attr);
    }
    if ($attr{-type}=~/wpt/i){
	return new Lingua::Align::Corpus::Parallel::WPT(%attr);
    }
    if ($attr{-type}=~/opus/i){
	return new Lingua::Align::Corpus::Parallel::OPUS(%attr);
    }
    if ($attr{-type}=~/(ordered|id)/i){
	return new Lingua::Align::Corpus::Parallel::OrderedIds(%attr);
    }
    return new Lingua::Align::Corpus::Parallel::Bitext(%attr);
}



sub add_to_buffer{
    my $self=shift;
    my ($src,$trg,$links,$ids)=@_;

    print STDERR "buffering src\n" if ($self->{-verbose}>1);
    my $ret = $self->{SRC}->add_to_buffer($src);
    print STDERR "buffering trg\n" if ($self->{-verbose}>1);
    $ret += $self->{TRG}->add_to_buffer($trg);
    
    # also add links and ids to the buffer
    $links = {} if (not ref($links));
    $ids = [] if (not ref($ids));
    print STDERR "buffering links\n" if ($self->{-verbose}>1);
    $self->SUPER::add_to_buffer($links);
    print STDERR "buffering ids\n" if ($self->{-verbose}>1);
    $self->SUPER::add_to_buffer($ids);

    return $ret;
}




sub next_alignment{
    my $self=shift;
    my ($src,$trg,$links,$file,$enc,$ids)=@_;

    if (ref($self->{SRC}) && ref($self->{TRG})){
	if ($self->{SRC}->read_from_buffer($src)){
	    if ($self->{TRG}->read_from_buffer($trg)){
		$links = {} if (not ref($links));
		$ids = [] if (not ref($ids));
		$self->SUPER::read_from_buffer($ids);
		$self->SUPER::read_from_buffer($links);
		return 1;
	    }
	}
    }

    return $self->read_next_alignment(@_);
}



sub read_next_alignment{
    my $self=shift;
    my ($src,$trg)=@_;
    return 0 if (not $self->{SRC}->next_sentence($src));
    return 0 if (not $self->{TRG}->next_sentence($trg));
    return 1;
}





# read sentence ID pairs from external file

sub next_sentence_ids{
    my $self=shift;

    my $fh;
    if ($self->{-sent_id_file}){
	$fh=$self->open_file($self->{-sent_id_file});

	while (<$fh>){
	    chomp;
	    if (/^\#+\s+(.*)$/){
		my $files=$1;
		($self->{SRCFILE},$self->{TRGFILE}) = split(/\t/,$files);
	    }
	    else{
		my ($srcid,$trgid) = split(/\t/);
		return ($srcid,$trgid,$self->{SRCFILE},$self->{TRGFILE});
	    }
	}
    }
    return ();
}

sub print_alignments{}
sub print_header{}
sub print_tail{}

sub make_corpus_handles{
    my $self=shift;
    my %attr=@_;

    my %srcattr=();
    my %trgattr=();
    foreach (keys %attr){
	if (/\-src_(.*)$/){$srcattr{'-'.$1}=$attr{$_};}
	elsif (/\-trg_(.*)$/){$trgattr{'-'.$1}=$attr{$_};}
    }
    $self->{-src_type} = $attr{-src_type} || 'text';
    $self->{-trg_type} = $attr{-trg_type} || 'text';

    $self->{SRC}=new Lingua::Align::Corpus(%srcattr);
    $self->{TRG}=new Lingua::Align::Corpus(%trgattr);
}

sub close{
    my $self=shift;
    if (exists $self->{SRC}){
	$self->{SRC}->close();
    }
    if (exists $self->{TRG}){
	$self->{TRG}->close();
    }
}


sub src_treebankID{
    return 1;
}

sub trg_treebankID{
    return 2;
}


sub src_treebank{
    return $_[0]->{SRC}->{-file};
}

sub trg_treebank{
    return $_[0]->{TRG}->{-file};
}




sub print_link_matrix{
    my $self=shift;
    my ($src,$trg,$links)=@_;

    my @srcwords = $self->{TREES}->get_all_leafs($src);
    my @trgwords = $self->{TREES}->get_all_leafs($trg);

    my @srcids = $self->{TREES}->get_all_leafs($src,'id');
    my @trgids = $self->{TREES}->get_all_leafs($trg,'id');

    my @trgchar=();
    my $maxTrgLen=0;
    foreach (0..$#trgwords){
	@{$trgchar[$_]}=split(//,$trgwords[$_]);
	if ($#{$trgchar[$_]}>$maxTrgLen){$maxTrgLen=$#{$trgchar[$_]};}
    }
    foreach my $t (0..$#trgwords){print STDERR '--';}
    print STDERR "-|--\n";
    foreach my $s (0..$#srcwords){
	foreach my $t (0..$#trgwords){
	    my $sid = $srcids[$s];
	    my $tid = $trgids[$t];
	    if (exists $$links{$sid}{$tid}){
		if ($$links{$sid}{$tid} eq 'S'){
		    print STDERR ' *';
		}
		else{print STDERR ' O';}
	    }
	    else{print STDERR '  ';}
	}
	print STDERR ' | ',$srcwords[$s],"\n";
    }
    foreach my $t (0..$#trgwords){print STDERR '--';}
    print STDERR "-|--\n";
#    for (my $x=$maxTrgLen;$x>=0;$x--){
    foreach my $x (0..$maxTrgLen){
	foreach my $t (0..$#trgwords){
	    printf STDERR "%2s",$trgchar[$t][$x];
	}
	print STDERR "\n";
    }
    print STDERR "\n\n";
}




sub compare_link_matrix{
    my $self=shift;
    my ($src,$trg,$links1,$links2)=@_;

    my @srcwords = $self->{TREES}->get_all_leafs($src);
    my @trgwords = $self->{TREES}->get_all_leafs($trg);

    my @srcids = $self->{TREES}->get_all_leafs($src,'id');
    my @trgids = $self->{TREES}->get_all_leafs($trg,'id');


    my @trgchar=();
    my $maxTrgLen=0;

    my ($countS,$countP,$countZ,$countD,$countMS,$countMP,$countWS,$countWP)=
	(0,0,0,0,0,0,0,0);

    print STDERR "\n\ncompare word alignments for: $src->{ID} -- $trg->{ID}\n";

    foreach (0..$#trgwords){
	@{$trgchar[$_]}=split(//,$trgwords[$_]);
	if ($#{$trgchar[$_]}>$maxTrgLen){$maxTrgLen=$#{$trgchar[$_]};}
    }
    foreach my $t (0..$#trgwords){print STDERR '--';}
    print STDERR "-|--\n";
    foreach my $s (0..$#srcwords){
	foreach my $t (0..$#trgwords){
	    my $sid = $srcids[$s];
	    my $tid = $trgids[$t];

	    if (exists $$links1{$sid}{$tid}){
		if ($$links1{$sid}{$tid}=~/(good|S)/){
		    if (exists $$links2{$sid}{$tid}){
			if ($$links2{$sid}{$tid}=~/(good|S)/){
			    print STDERR ' S';
			    $countS++;
			}
			else{
			    print STDERR ' z';
			    $countZ++;
			}
		    }
		    else{
			print STDERR ' *';
			$countWS++;
		    }
		}
		elsif (exists $$links2{$sid}{$tid}){
		    if ($$links2{$sid}{$tid}=~/(fuzzy|weak|P)/){
			print STDERR ' P';
			$countP++;
		    }
		    else{
			print STDERR ' d';
			$countD++;
		    }
		}
		else{
		    print STDERR ' +';
		    $countWP++;
		}
	    }
	    elsif (exists $$links2{$sid}{$tid}){
		if ($$links2{$sid}{$tid}=~/(fuzzy|weak|P)/){
		    print STDERR ' ·';
			$countMP++;
		}
		else{
		    print STDERR ' -';
		    $countMS++;
		}
	    }
	    else{print STDERR '  ';}
	}
	print STDERR ' | ',$srcwords[$s],"\n";
    }
    foreach my $t (0..$#trgwords){print STDERR '--';}
    print STDERR "-|--\n";
#    for (my $x=$maxTrgLen;$x>=0;$x--){
    foreach my $x (0..$maxTrgLen){
	foreach my $t (0..$#trgwords){
	    printf STDERR "%2s",$trgchar[$t][$x];
	}
	print STDERR "\n";
    }
    print STDERR "\n";

    printf STDERR "  %2d x %s",$countS,"(S) .... proposed = gold = S\n";
    printf STDERR "  %2d x %s",$countP,"(P) .... proposed = gold = P\n";

    printf STDERR "  %2d x %s",$countZ,"(z) .... proposed = P, gold = S (ok!)\n";
    printf STDERR "  %2d x %s",$countD,"(d) .... proposed = S, gold = P (ok!)\n";

    if ($countWS){print STDERR '! ';}else{print STDERR '  ';}
    printf STDERR "%2d x %s",$countWS,"(*) .... proposed = S, gold = not aligned (wrong!)\n";
    if ($countWP){print STDERR '! ';}else{print STDERR '  ';}
    printf STDERR "%2d x %s",$countWP,"(+) .... proposed = P, gold = not aligned (wrong!)\n";
    if ($countMS){print STDERR '! ';}else{print STDERR '  ';}
    printf STDERR "%2d x %s",$countMS,"(-) .... proposed = not aligned, gold = S (missing!)\n";
    printf STDERR "  %2d x %s",$countMP,"(·) .... proposed = not aligned, gold = P (missing!)\n\n";

    print "total: ",$countS+$countP+$countZ+$countD," correct, ";
    print $countMS+$countMP," missing, ";
    print $countWS+$countWP," wrong\n";

    my $nrA=$countS+$countP+$countZ+$countD+$countWS+$countWP;
    my $nrS=$countS+$countZ+$countMS;
    my $interAP=$countS+$countP+$countZ+$countD;
    my $interAS=$countS+$countZ;

    my $precision = $nrA ? $interAP/$nrA : 0;
    my $recall    = $nrS ? $interAS/$nrS : 0;
    my $AER       = ($nrA+$nrS) ? 1-($interAP+$interAS)/($nrA+$nrS) : 1;

    $self->{COUNTS}++;
    $self->{nrA}+=$nrA;
    $self->{nrS}+=$nrS;
    $self->{interAP}+=$interAP;
    $self->{interAS}+=$interAS;

    $self->{alignP}+=$precision;
    $self->{alignR}+=$recall;
    $self->{AER}+=$AER;

    printf "this sentence: precision = %5.4f",$precision;
    printf ", recall = %5.4f",$recall;
    printf ", AER = %5.4f\n",$AER;

    printf "      average: precision = %5.4f",$self->{alignP}/$self->{COUNTS};
    printf ", recall = %5.4f",$self->{alignR}/$self->{COUNTS};
    printf ", AER = %5.4f\n",$self->{AER}/$self->{COUNTS};


    my $totalPrecision = $self->{nrA} ? $self->{interAP}/$self->{nrA} : 0;
    my $totalRecall    = $self->{nrS} ? $self->{interAS}/$self->{nrS} : 0;
    my $totalAER       = ($self->{nrA}+$self->{nrS}) ? 
	1-($self->{interAP}+$self->{interAS})/($self->{nrA}+$self->{nrS}) : 1;
    printf "        total: precision = %5.4f",$totalPrecision;
    printf ", recall = %5.4f",$totalRecall;
    printf ", AER = %5.4f\n\n",$totalAER;
    

}





1;
__END__

=head1 NAME

Lingua::Align::Corpus::Parallel - Class factory for reading parallel corpora

=head1 SYNOPSIS

  use Lingua::Align::Corpus::Parallel;

  my $corpus = new Lingua::Align::Corpus::Parallel(-srcfile => $srcfile,
                                                   -trgfile => $trgfile);

  my @src=();
  my @trg=();
  while ($corpus->next_alignment(\@src,\@trg)){
     print "src> ";
     print join(' ',@src);
     print "\ntrg> ";
     print join(' ',@trg);
     print "============================\n";
  }

=head1 DESCRIPTION


A collection of modules for reading parallel sentence-aligned corpora.
Default format is plain text (see
L<Lingua::Align::Corpus::Parallel::Bitext>)


=head1 SEE ALSO

L<Lingua::Align::Corpus::Parallel::Bitext>,
L<Lingua::Align::Corpus::Parallel::Giza>,
L<Lingua::Align::Corpus::Parallel::Moses>,
L<Lingua::Align::Corpus::Parallel::OPUS>,
L<Lingua::Align::Corpus::Parallel::STA>

=head1 AUTHOR

Joerg Tiedemann, E<lt>jorg.tiedemann@lingfil.uu.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
