package Lingua::Align::Features::Cooccurrence;

#
# DICE scores for various feature pairs
# (uses cooc-frequencies counted by coocfreq)
# features to be used are stored in the source & target freq files
#
# feature example: 
#    dice1=src.freq+trg.freq+cooc.freq
#
# means: - take source frequencies from src.freq (and source token IDs)
#        - take target frequencies from trg.freq (and target token IDs)
#        - take co-occurrence frequencies from cooc.freq (using token IDs)
#
# in src.freq and trg.freq there should be a line 
# starting with '#' followed by the feature-description (e.g., word:prefix=3)
#
# you can have as many dice score feature as you like
# the name of the feature has to start with 'dice'


use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Features::Tree);


sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){$self->{$_}=$attr{$_};}

    # make a Treebank object for processing trees
    $self->{TREES} = new Lingua::Align::Corpus::Treebank();
    $self->{COOC_FREQ_THR} = $attr{-cooc_freq_thr} || 2;

    return $self;
}



sub get_features{
    my $self=shift;
    my ($src,$trg,$srcN,$trgN,$FeatTypes,$values)=@_;

    foreach my $f (keys %{$FeatTypes}){
	if ($f=~/^dice/){

	    # read frequencies

	    if (not defined $self->{"COOCFREQ$f"}){
		my $coocfreq = $$FeatTypes{$f};
		my ($srcfreq,$trgfreq) = (undef,undef);
		if ($$FeatTypes{$f}=~/\+.*\+/){
		    ($srcfreq,$trgfreq,$coocfreq) = split(/\+/,$$FeatTypes{$f});
		}
		my ($s,$t) = $self->read_cooc_frequencies($f,$coocfreq);
		if (not defined $srcfreq){ $srcfreq = $s; }
		if (not defined $trgfreq){ $trgfreq = $t; }
		$self->read_frequencies($f,$srcfreq,$trgfreq);

	    }

	    # get source/target features & compute Dice score

	    my $srcword = $self->{"SRCFE$f"}->feature($src,$srcN);
	    my $trgword = $self->{"TRGFE$f"}->feature($trg,$trgN);
	    $$values{$f} = $self->dice($f,$srcword,$trgword);
	}
    }
}








sub read_frequencies{
    my $self=shift;
    my ($feat,$srcfreqfile,$trgfreqfile) = @_;

    print STDERR "read source frequencies from $srcfreqfile!\n" 
	if $self->{-verbose};

    $self->{"SRCVOC$feat"}={};
    $self->{"SRCFREQ$feat"}={};
    my $SrcFeat = __read_word_freq($srcfreqfile,
				   $self->{"SRCVOC$feat"},
				   $self->{"SRCFREQ$feat"},
				   $self->{SRC_FREQ_THR});

    # make a feature extractor for source node features
    $self->{"SRCFE$feat"} = new Lingua::Align::Features;
    $self->{"SRCFE$feat"}->initialize_features($SrcFeat);

    my @sorted = sort { $self->{"SRCFREQ$feat"}->{$b} <=> $self->{"SRCFREQ$feat"}->{$a}} keys %{$self->{"SRCFREQ$feat"}};
    foreach (0..$#sorted){
	$self->{"SRCRANK$feat"}->{$sorted[$_]}=$_;
    }

    print STDERR "read target frequencies from $trgfreqfile!\n" 
	if $self->{-verbose};

    $self->{"TRGVOC$feat"}={};
    $self->{"TRGFREQ$feat"}={};
    my $TrgFeat = __read_word_freq($trgfreqfile,
				   $self->{"TRGVOC$feat"},
				   $self->{"TRGFREQ$feat"},
				   $self->{TRG_FREQ_THR});

    # make a feature extractor for target node features
    $self->{"TRGFE$feat"} = new Lingua::Align::Features;
    $self->{"TRGFE$feat"}->initialize_features($TrgFeat);

    @sorted = sort { $self->{"TRGFREQ$feat"}->{$b} <=> $self->{"TRGFREQ$feat"}->{$a}} keys %{$self->{"TRGFREQ$feat"}};
    foreach (0..$#sorted){
	$self->{"TRGRANK$feat"}->{$sorted[$_]}=$_;
    }
}

sub read_cooc_frequencies{
    my $self=shift;
    my ($feat,$coocfreqfile) = @_;

    print STDERR "read co-occurrence frequencies from $coocfreqfile!\n" 
	if $self->{-verbose};

    $self->{"COOCFREQ$feat"}={};
    open F,"<$coocfreqfile" || 
	die "cannot open cooccurrence frequency file $coocfreqfile!\n";

    my ($srcfreqfile,$trgfreqfile)=('src.freq','trg.freq');

    my $count=0;    
    while (<F>){
	chomp;
	if (/^\#\s+source.*:\s*(\S+)\s*$/){   # source frequency file
	    $srcfreqfile=$1;
	    next;
	}
	if (/^\#\s+target.*:\s*(\S+)\s*$/){   # target frequency file
	    $trgfreqfile=$1;
	    next;
	}
	$count++;
	if ($self->{-verbose}){
	    if (not($count % 1000000)){
		print STDERR '.';
	    }
	    if (not($count % 20000000)){
		print STDERR " $count\n";
	    }
	}
	my ($srcid,$trgid,$freq)=split;
	if ($freq>$self->{COOC_FREQ_THR}){
#	    $self->{__COOCFREQ__}->{$srcid."\t".$trgid} = $freq;
	    $self->{"COOCFREQ$feat"}->{$srcid}->{$trgid} = $freq;
	}
    }
    print STDERR " done!\n";
    close F;
    return ($srcfreqfile,$trgfreqfile);
}



sub __read_word_freq{
    my ($freqfile,$VocHash,$FreqHash,$FreqThr) = @_;
    open F,"<$freqfile" || die "cannot open word frequency file $freqfile!\n";
    binmode(F,":utf8");

    my $feat=undef;
    while (<F>){
	if (/^\#\s*(\S*)\s*$/){
	    $feat = $1;
	    next;
	}
	chomp;
	my ($word,$id,$freq)=split;
	if ($freq>$FreqThr){
	    $VocHash->{$word}=$id;
	    $FreqHash->{$id}=$freq;
	}
    }
    close F;
    return $feat;
}




sub dice{
    my $self=shift;
    my ($feat,$src,$trg) = @_;

    if (exists $self->{"SRCVOC$feat"}->{$src}){
	my $sid = $self->{"SRCVOC$feat"}->{$src};
	if (exists $self->{"TRGVOC$feat"}->{$trg}){
	    my $tid = $self->{"TRGVOC$feat"}->{$trg};
	    if (exists $self->{"COOCFREQ$feat"}->{$sid}){
		if (exists $self->{"COOCFREQ$feat"}->{$sid}->{$tid}){
		    my $cooc = $self->{"COOCFREQ$feat"}->{$sid}->{$tid};
		    my $sfreq = $self->{"SRCFREQ$feat"}->{$sid};
		    my $tfreq = $self->{"TRGFREQ$feat"}->{$tid};
#		    print STDERR $cooc/($sfreq+$tfreq)," ($src=$trg)\n";
		    return 2*$cooc/($sfreq+$tfreq);
		}
	    }
	}
    }
    return 0;
}





1;
