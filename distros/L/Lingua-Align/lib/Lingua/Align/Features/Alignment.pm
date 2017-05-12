package Lingua::Align::Features::Alignment;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Features::Tree);

use Lingua::Align::Corpus::Parallel::Giza;
use Lingua::Align::Corpus::Parallel::Moses;


## word alignment features from GIZA++ word alignments

sub get_features{
    my $self=shift;
    my ($src,$trg,$srcN,$trgN,$FeatTypes,$values)=@_;

    my ($insideEF,$outsideEF);
    my ($insideFE,$outsideFE);

    # Moses links (GIZA++ Viterbi after symmetrization)
    # feature = proportion of inside links
    if ((exists $$FeatTypes{moses}) || (exists $$FeatTypes{moseslink})){
	($insideEF,$outsideEF) = $self->moses_links($src,$trg,$srcN,$trgN);
	if (exists $$FeatTypes{moses}){
	    if ($insideEF || $outsideEF){
		$$values{moses} = $insideEF/($insideEF+$outsideEF);
	    }
	}

	# moseslink = 1 if srcN and trgN are aligned terminal nodes
	if (exists $$FeatTypes{moseslink}){
	    if ($insideEF && 
		$self->{TREES}->is_terminal($src,$srcN) && 
		$self->{TREES}->is_terminal($trg,$trgN)){
		$$values{moseslink}=1;
	    }
	}
    }

    # GIZA++ features
    if ((exists $$FeatTypes{gizae2f}) || (exists $$FeatTypes{giza})){
	($insideEF,$outsideEF) = $self->gizae2f($src,$trg,$srcN,$trgN);
    }
    if ((exists $$FeatTypes{gizaf2e}) || (exists $$FeatTypes{giza})){
	($insideFE,$outsideFE) = $self->gizaf2e($src,$trg,$srcN,$trgN);
    }

    # proportion of inside links (src->trg)
    if (exists $$FeatTypes{gizae2f}){
	if ($insideEF || $outsideEF){
	    $$values{gizae2f} = $insideEF/($insideEF+$outsideEF);
	}
    }

    # proportion of inside links (trg->src)
    if (exists $$FeatTypes{gizaf2e}){
	if ($insideFE || $outsideFE){
	    $$values{gizaf2e} = $insideFE/($insideFE+$outsideFE);
	}
    }

    # proportion of inside links (src->trg & trg->src combined)
    if (exists $$FeatTypes{giza}){
	if ($insideEF || $outsideEF || $insideFE || $outsideFE){
	    $$values{giza} = ($insideEF+$insideFE)/
		($insideEF+$insideFE+$outsideEF+$outsideFE);
	}
    }

}




sub gizae2f{
    my $self=shift;
    my ($src,$trg,$srcN,$trgN)=@_;

    if ($src->{ID} ne $self->{LASTGIZA_SRC_ID}){
	$self->{LASTGIZA_SRC_ID} = $src->{ID};
	$self->read_next_giza_links($src,$trg,'GIZA_E2F',
				    $self->{-gizaA3_e2f},
				    $self->{-gizaA3_e2f_encoding},
				    $self->{-gizaA3_e2f_ids});
    }

    # get leaf nodes dominated by the given node in the tree

    my @srcleafs = $self->{TREES}->get_leafs($src,$srcN,'id');
    my @trgleafs = $self->{TREES}->get_leafs($trg,$trgN,'id');

    my %srcLeafIDs=();
    foreach (@srcleafs){$srcLeafIDs{$_}=1;}
    my %trgLeafIDs=();
    foreach (@trgleafs){$trgLeafIDs{$_}=1;}

    my %InsideLink=();
    my %OutsideLink=();

    foreach my $s (@srcleafs){
	foreach my $t (keys %{$self->{GIZA_E2F}->{S2T}->{$s}}){
	    if (exists $trgLeafIDs{$t}){
		$InsideLink{"$s:$t"}=1;
	    }
	    else{
		$OutsideLink{"$s:$t"}=1;
	    }
	}
    }

    foreach my $t (@trgleafs){
	foreach my $s (keys %{$self->{GIZA_E2F}->{T2S}->{$t}}){
	    if (exists $srcLeafIDs{$s}){
		$InsideLink{"$s:$t"}=1;
	    }
	    else{
		$OutsideLink{"$s:$t"}=1;
	    }
	}
    }

    my $inside=scalar keys %InsideLink;
    my $outside=scalar keys %OutsideLink;

    return ($inside,$outside);

}



sub gizaf2e{
    my $self=shift;
    my ($src,$trg,$srcN,$trgN)=@_;

    if ($trg->{ID} ne $self->{LASTGIZA_TRG_ID}){
	$self->{LASTGIZA_TRG_ID} = $trg->{ID};
	$self->read_next_giza_links($trg,$src,'GIZA_F2E',
				    $self->{-gizaA3_f2e},
				    $self->{-gizaA3_f2e_encoding},
				    $self->{-gizaA3_f2e_ids});
    }

    # get leaf nodes dominated by the given node in the tree

    my @srcleafs = $self->{TREES}->get_leafs($src,$srcN,'id');
    my @trgleafs = $self->{TREES}->get_leafs($trg,$trgN,'id');

    my %srcLeafIDs=();
    foreach (@srcleafs){$srcLeafIDs{$_}=1;}
    my %trgLeafIDs=();
    foreach (@trgleafs){$trgLeafIDs{$_}=1;}

    my %InsideLink=();
    my %OutsideLink=();

    foreach my $s (@srcleafs){
	foreach my $t (keys %{$self->{GIZA_F2E}->{T2S}->{$s}}){
	    if (exists $trgLeafIDs{$t}){
		$InsideLink{"$s:$t"}=1;
	    }
	    else{
		$OutsideLink{"$s:$t"}=1;
	    }
	}
    }

    foreach my $t (@trgleafs){
	foreach my $s (keys %{$self->{GIZA_F2E}->{S2T}->{$t}}){
	    if (exists $srcLeafIDs{$s}){
		$InsideLink{"$s:$t"}=1;
	    }
	    else{
		$OutsideLink{"$s:$t"}=1;
	    }
	}
    }

    my $inside=scalar keys %InsideLink;
    my $outside=scalar keys %OutsideLink;

    return ($inside,$outside);

}


sub read_next_giza_links{
    my $self=shift;
    my ($src,$trg,$key,$file,$encoding,$idfile)=@_;

    if (not exists $self->{$key}){
	$self->{$key} = new Lingua::Align::Corpus::Parallel::Giza(
				 -alignfile => $file,
				 -encoding => $encoding,
				 -sent_id_file => $idfile);
    }

#    print STDERR "read from $file($idfile) ....";

    my @srcwords=();
    my @trgwords=();
    my %wordlinks=();
    my @ids=();

    # need to delete initial letters for numeric comparisons
    my $srcID=$$src{ID};
    my $trgID=$$trg{ID};
    $srcID=~s/^[^0-9]+//;
    $trgID=~s/^[^0-9]+//;

    # temporary variables for link IDs
    my ($srcLinkID,$trgLinkID);

    # read GIZA++ Viterbi word alignment for next sentence pair
    # (check IDs if there is an ID file to do that!)
    do {
	@srcwords=();
	@trgwords=();
	%wordlinks=();
	@ids=();
	if (not $self->{$key}->next_alignment(\@srcwords,\@trgwords,
					      \%wordlinks,
					      undef,undef,\@ids)){
	    if ($self->{-verbose}){
		print STDERR "reached EOF (looking for $$src{ID}:$$trg{ID})\n";
	    }
	    return 0;
	}

	# need to delete initial letters for numeric comparisons
	$srcLinkID=$ids[0];
	$trgLinkID=$ids[1];
	$srcLinkID=~s/^[^0-9]+//;
	$trgLinkID=~s/^[^0-9]+//;

#	if (($$src{ID}<$ids[0]) || ($$trg{ID}<$ids[1])){
	if (($srcID<$srcLinkID) || ($trgID<$trgLinkID)){
	    if ($self->{-verbose}>1){
		print STDERR "gone too far? (looking for $$src{ID}:$$trg{ID}";
		print STDERR " - found ($ids[0]:$ids[1])\n";
	    }
	    $self->{$key}->add_to_buffer(\@srcwords,\@trgwords,
					 \%wordlinks,\@ids);
	    # I just assume that IDs are ordered --> do not try to read further
	    return 0;
	}

	if ($self->{-verbose}>1){
	    if (@ids){
#		if (($$src{ID} ne $ids[0]) || ($$trg{ID} ne $ids[1])){
		if (($srcID ne $srcLinkID) || ($trgID ne $trgLinkID)){
		    print STDERR "skip this GIZA++ alignment!";
		    print STDERR " ($$src{ID}/$ids[0] $$trg{ID}/$ids[1])\n";
		}
	    }
	}
    }
    until ((not defined $ids[0]) || 
	   (($srcID eq $srcLinkID) && ($trgID eq $trgLinkID)));

#	   (($$src{ID} eq $ids[0]) && ($$trg{ID} eq $ids[1])) ||
#	   (($$src{ID} eq "s$ids[0]") && ($$trg{ID} eq "s$ids[1]")));

    # get terminal node IDs

    my @srcids = @{$src->{TERMINALS}};
    my @trgids = @{$trg->{TERMINALS}};

    # make the mapping from word position to ID

    my %srcPos2ID=();
    foreach (0..$#srcids){
	my $pos=$_+1;
	$srcPos2ID{$pos}=$srcids[$_];
    }
    my %trgPos2ID=();
    foreach (0..$#trgids){
	my $pos=$_+1;
	$trgPos2ID{$pos}=$trgids[$_];
    }

    # save word links with node IDs

    $self->{$key}->{S2T} = {};
    $self->{$key}->{T2S} = {};

    foreach my $s (keys %wordlinks){
	my $sid = $srcPos2ID{$s};
	my $tid = $trgPos2ID{$wordlinks{$s}};
	$self->{$key}->{S2T}->{$sid}->{$tid}=1;
	$self->{$key}->{T2S}->{$tid}->{$sid}=1;
    }
}




sub moses_links{
    my $self=shift;
    my ($src,$trg,$srcN,$trgN)=@_;

    if ($src->{ID} ne $self->{LASTMOSES_SRC_ID}){
	$self->{LASTMOSES_SRC_ID} = $src->{ID};
	$self->read_next_moses_links($src,$trg,'MOSES',
				     $self->{-moses_align},
				     $self->{-moses_align_encoding},
				     $self->{-moses_align_ids});
    }

    # get leaf nodes dominated by the given node in the tree

    my @srcleafs = $self->{TREES}->get_leafs($src,$srcN,'id');
    my @trgleafs = $self->{TREES}->get_leafs($trg,$trgN,'id');

    my %srcLeafIDs=();
    foreach (@srcleafs){$srcLeafIDs{$_}=1;}
    my %trgLeafIDs=();
    foreach (@trgleafs){$trgLeafIDs{$_}=1;}

    my $inside=0;
    my $outside=0;

    foreach my $s (@srcleafs){
	foreach my $t (keys %{$self->{MOSES}->{S2T}->{$s}}){
	    if (exists $trgLeafIDs{$t}){
		$inside++;
	    }
	    else{$outside++;}
	}
    }

    foreach my $t (@trgleafs){
	foreach my $s (keys %{$self->{MOSES}->{T2S}->{$t}}){
	    if (exists $srcLeafIDs{$s}){
		$inside++;
	    }
	    else{$outside++;}
	}
    }

    return ($inside,$outside);

}



sub read_next_moses_links{
    my $self=shift;
    my ($src,$trg,$key,$file,$encoding,$idfile)=@_;

    if (not exists $self->{$key}){
	$self->{$key} = new Lingua::Align::Corpus::Parallel::Moses(
				 -alignfile => $file,
				 -encoding => $encoding,
                                 -sent_id_file => $idfile);
    }

    my @srcwords=();
    my @trgwords=();
    my %wordlinks=();
    my @ids=();

    # need to delete initial letters for numeric comparisons
    my $srcID=$$src{ID};
    my $trgID=$$trg{ID};
    $srcID=~s/^[^0-9]+//;
    $trgID=~s/^[^0-9]+//;

    # temporary variables for link IDs
    my ($srcLinkID,$trgLinkID);

    # read Moses word alignment for next sentence pair
    # (check IDs if there is an ID file to do that!)
    do {
	@srcwords=();
	@trgwords=();
	%wordlinks=();
	@ids=();
	if (not $self->{$key}->next_alignment(\@srcwords,\@trgwords,
					      \%wordlinks,
					      undef,undef,\@ids)){
	    if ($self->{-verbose}){
		print STDERR "reached EOF (looking for $$src{ID}:$$trg{ID})\n";
	    }
	    return 0;
	    
	}

	# need to delete initial letters for numeric comparisons
	$srcLinkID=$ids[0];
	$trgLinkID=$ids[1];
	$srcLinkID=~s/^[^0-9]+//;
	$trgLinkID=~s/^[^0-9]+//;

#	if (($$src{ID}<$ids[0]) || ($$trg{ID}<$ids[1])){
	if (($srcID<$srcLinkID) || ($trgID<$trgLinkID)){
	    if ($self->{-verbose}>1){
		print STDERR "gone too far? (looking for $$src{ID}:$$trg{ID}";
		print STDERR " - found ($ids[0]:$ids[1])\n";
	    }
	    $self->{$key}->add_to_buffer(\@srcwords,\@trgwords,
					 \%wordlinks,\@ids);
	    # I just assume that IDs are ordered --> do not try to read further
	    return 0;
	}

	if ($self->{-verbose}>1){
	    if (@ids){
#		if (($$src{ID} ne $ids[0]) || ($$trg{ID} ne $ids[1])){
		if (($srcID ne $srcLinkID) || ($trgID ne $trgLinkID)){
		    print STDERR "skip this MOSES alignment!";
		    print STDERR "($$src{ID}/$ids[0] $$trg{ID}/$ids[1])\n";
		}
	    }
	}
    }
    until ((not defined $ids[0]) || 
	   (($srcID eq $srcLinkID) && ($trgID eq $trgLinkID)));
#	   (($$src{ID} eq $ids[0]) && ($$trg{ID} eq $ids[1])));

    # get terminal node IDs

    my @srcids = @{$src->{TERMINALS}};
    my @trgids = @{$trg->{TERMINALS}};

    # make the mapping from word position to ID

    my %srcPos2ID=();
    foreach (0..$#srcids){
	my $pos=$_;
	$srcPos2ID{$pos}=$srcids[$_];
    }
    my %trgPos2ID=();
    foreach (0..$#trgids){
	my $pos=$_;
	$trgPos2ID{$pos}=$trgids[$_];
    }

    # save word links with node IDs

    foreach my $s (keys %wordlinks){
	my $sid = $srcPos2ID{$s};
	foreach my $t (keys %{$wordlinks{$s}}){
	    my $tid = $trgPos2ID{$t};
	    $self->{$key}->{S2T}->{$sid}->{$tid}=1;
	    $self->{$key}->{T2S}->{$tid}->{$sid}=1;
	}
    }
    return 1;
}




1;
