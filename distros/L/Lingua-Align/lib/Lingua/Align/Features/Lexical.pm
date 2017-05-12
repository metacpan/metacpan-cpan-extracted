package Lingua::Align::Features::Lexical;

#
# this is basically a collection of inside/outside scores using 
# probabilistic dictionaries (usually from Moses/Giza++)
#
# TODO:
# - make it possible to use several alternative dictionaries
# - match scores using ordinary (non-probabilistic) dictionaries
# - scores between other attributes? (POS labels, other factors? etc)
# - negative scores for matches between inside and outside nodes?
#


use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Features::Tree);


sub get_features{
    my $self=shift;
    my ($src,$trg,$srcN,$trgN,$FeatTypes,$values)=@_;
    $self->lex_inside_features($src,$trg,$srcN,$trgN,$FeatTypes,$values);
    $self->lex_outside_features($src,$trg,$srcN,$trgN,$FeatTypes,$values);
}


sub initialize_features{
    my $self=shift;
    $self->SUPER::initialize_features(@_);
    if ($self->{FEATURE_TYPES_STRING}=~/(inside|outside)/){
	$self->load_moses_lex();
    }
}


sub load_moses_lex{
    my $self=shift;

    return 1 if ((exists $self->{LEXE2F}) && (exists $self->{LEXF2E}));

    my $lexe2f = $self->{-lexe2f} || 'moses/model/lex.0-0.e2f';
    my $encoding = $self->{-lexe2f_encoding} || 'utf8';

    if (-e $lexe2f){
	print STDERR "load $lexe2f ....";
	open F,"<$lexe2f" || die "cannot open lexe2f file '$lexe2f'\n";
	binmode(F,":encoding($encoding)");
	while (<F>){
	    chomp;
	    my ($src,$trg,$score)=split(/\s+/);
	    $self->{LEXE2F}->{$src}->{$trg}=$score;
	}
	close F;
	print STDERR " done!\n";
    }

    my $lexf2e = $self->{-lexf2e} || 'moses/model/lex.0-0.f2e';
    if (-e $lexf2e){
	print STDERR "load $lexe2f ....";
	open F,"<$lexf2e" || die "cannot open lexf2e file '$lexf2e'\n";
	binmode(F,":encoding($encoding)");
	while (<F>){
	    chomp;
	    my ($trg,$src,$score)=split(/\s+/);
	    $self->{LEXF2E}->{$trg}->{$src}=$score;
	}
	close F;
	print STDERR " done!\n";
    }
}

sub lex_inside_features{
    my $self=shift;
    my ($srctree,$trgtree,         # entire parse tree (source & target)
	$srcnode,$trgnode,         # current tree nodes
	$FeatTypes,$values)=@_;    # feature types to be returned in values


    # do nothing if we don't need inside features
    return 0 if ($self->{FEATURE_TYPES_STRING}!~/inside/);


    # get leaf nodes dominated by the given node in the tree

    my @srcleafs = $self->{TREES}->get_leafs($srctree,$srcnode);
    my @trgleafs = $self->{TREES}->get_leafs($trgtree,$trgnode);

    ## lower casing if necessary

    if ($self->{-lex_lower}){
	for (0..$#srcleafs){
	    $srcleafs[$_]=lc($srcleafs[$_]);
	}
	for (0..$#trgleafs){
	    $trgleafs[$_]=lc($trgleafs[$_]);
	}
    }


    ## lexical inside scores
    ## ----------------------------------------
    ## original Dublin Subtree aligner scores
    ## ----------------------------------------
    ## insideST1 ...... un-normalized inside score a(s|t)
    ## insideST1 ...... un-normalized inside score a(t|s)
    ## insideST2 ...... normalized inside score a(s|t)
    ## insideST2 ...... normalized inside score a(t|s)
    ## ----------------------------------------
    ## the same without considering NULL links
    ## ----------------------------------------
    ## insideST3 ...... un-normalized inside score a(s|t)
    ## insideST3 ...... un-normalized inside score a(t|s)
    ## insideST4 ...... normalized inside score a(s|t)
    ## insideST4 ...... normalized inside score a(t|s)


    if (exists $$FeatTypes{insideST1}){
	$$values{insideST1} = 
	    $self->zhechev_scoreXY_NULL(\@srcleafs,\@trgleafs,
				   $self->{LEXE2F},$self->{LEXF2E},0);
    }
    if (exists $$FeatTypes{insideTS1}){
	$$values{insideTS1} = 
	    $self->zhechev_scoreXY_NULL(\@trgleafs,\@srcleafs,
				   $self->{LEXF2E},$self->{LEXE2F},0);
    }

    if (exists $$FeatTypes{insideST2}){
	$$values{insideST2} = 
	    $self->zhechev_scoreXY_NULL(\@srcleafs,\@trgleafs,
				   $self->{LEXE2F},$self->{LEXF2E},1);
    }
    if (exists $$FeatTypes{insideTS2}){
	$$values{insideTS2} = 
	    $self->zhechev_scoreXY_NULL(\@trgleafs,\@srcleafs,
				   $self->{LEXF2E},$self->{LEXE2F},1);
    }

    ## without NULL links

    if (exists $$FeatTypes{insideST3}){
	$$values{insideST3} = 
	    $self->zhechev_scoreXY(\@srcleafs,\@trgleafs,
				   $self->{LEXE2F},$self->{LEXF2E},0);
    }
    if (exists $$FeatTypes{insideTS3}){
	$$values{insideTS3} = 
	    $self->zhechev_scoreXY(\@trgleafs,\@srcleafs,
				   $self->{LEXF2E},$self->{LEXE2F},0);
    }

    if (exists $$FeatTypes{insideST4}){
	$$values{insideST4} = 
	    $self->zhechev_scoreXY(\@srcleafs,\@trgleafs,
				   $self->{LEXE2F},$self->{LEXF2E},1);
    }
    if (exists $$FeatTypes{insideTS4}){
	$$values{insideTS4} = 
	    $self->zhechev_scoreXY(\@trgleafs,\@srcleafs,
				   $self->{LEXF2E},$self->{LEXE2F},1);
    }


    ## combine src-trg and trg-src as in the 
    ## Dublin Tree Aligner (without normalization)

    if (exists $$FeatTypes{inside1}){
	my $insideST1;
	if (exists $$values{insideST1}){$insideST1=$$values{insideST1};}
	else{
	    $insideST1= $self->zhechev_scoreXY_NULL(\@srcleafs,\@trgleafs,
				       $self->{LEXE2F},$self->{LEXF2E},0);
	}
	my $insideTS1;
	if (exists $$values{insideTS1}){$insideTS1=$$values{insideTS1};}
	else{
	    $insideTS1=	$self->zhechev_scoreXY_NULL(\@trgleafs,\@srcleafs,
				       $self->{LEXF2E},$self->{LEXE2F},0);
	}
	$$values{inside1}=$insideST1*$insideTS1;

    }

    ## (with normalization)

    if (exists $$FeatTypes{inside2}){
	my $insideST2;
	if (exists $$values{insideST2}){$insideST2=$$values{insideST2};}
	else{
	    $insideST2=	$self->zhechev_scoreXY_NULL(\@srcleafs,\@trgleafs,
				       $self->{LEXE2F},$self->{LEXF2E},1);
	}
	my $insideTS2;
	if (exists $$values{insideTS2}){$insideTS2=$$values{insideTS2};}
	else{
	    $insideTS2=	$self->zhechev_scoreXY_NULL(\@trgleafs,\@srcleafs,
				       $self->{LEXF2E},$self->{LEXE2F},1);
	}
	$$values{inside2}=$insideST2*$insideTS2;
#	$$values{inside2}=$insideST2+$insideTS2;
    }


    ## -------------------------------------------
    ## now with the scores without NULL links

    if (exists $$FeatTypes{inside3}){
	my $insideST3;
	if (exists $$values{insideST3}){$insideST3=$$values{insideST3};}
	else{
	    $insideST3= $self->zhechev_scoreXY(\@srcleafs,\@trgleafs,
				       $self->{LEXE2F},$self->{LEXF2E},0);
	}
	my $insideTS3;
	if (exists $$values{insideTS3}){$insideTS3=$$values{insideTS3};}
	else{
	    $insideTS3=	$self->zhechev_scoreXY_NULL(\@trgleafs,\@srcleafs,
				       $self->{LEXF2E},$self->{LEXE2F},0);
	}
	$$values{inside3}=$insideST3*$insideTS3;
    }

    ## (with normalization)

    if (exists $$FeatTypes{inside4}){
	my $insideST4;
	if (exists $$values{insideST4}){$insideST4=$$values{insideST4};}
	else{
	    $insideST4=	$self->zhechev_scoreXY(\@srcleafs,\@trgleafs,
				       $self->{LEXE2F},$self->{LEXF2E},1);
	}
	my $insideTS4;
	if (exists $$values{insideTS2}){$insideTS4=$$values{insideTS4};}
	else{
	    $insideTS4=	$self->zhechev_scoreXY(\@trgleafs,\@srcleafs,
				       $self->{LEXF2E},$self->{LEXE2F},1);
	}
	$$values{inside4}=$insideST4*$insideTS4;
    }


    ## alterantive definition of inside scores:
    ## use max instead of averaged sum!


    if (exists $$FeatTypes{maxinsideST}){
	$$values{maxinsideST} = 
	    $self->maxscoreXY(\@srcleafs,\@trgleafs,$self->{LEXE2F});
    }
    if (exists $$FeatTypes{maxinsideTS}){
	$$values{maxinsideTS} = 
	    $self->maxscoreXY(\@trgleafs,\@srcleafs,$self->{LEXF2E});
    }


    if (exists $$FeatTypes{maxinside}){

	my $ST;
	if (exists $$values{maxinsideST}){$ST=$$values{maxinsideST};}
	else{$ST=$self->maxscoreXY(\@srcleafs,\@trgleafs,$self->{LEXE2F});}

	my $TS;
	if (exists $$values{maxinsideTS}){$TS=$$values{maxinsideTS};}
	else{$TS=$self->maxscoreXY(\@trgleafs,\@srcleafs,$self->{LEXF2E});}

	$$values{maxinside}=$ST*$TS;
    }


    ## yet another alterantive definition of inside scores:
    ## use max instead of averaged sum &
    ## compute average instead of multiplying prob's

    if (exists $$FeatTypes{avgmaxinsideST}){
	$$values{avgmaxinsideST} = 
	    $self->avgmaxscoreXY(\@srcleafs,\@trgleafs,$self->{LEXE2F});
    }
    if (exists $$FeatTypes{avgmaxinsideTS}){
	$$values{avgmaxinsideTS} = 
	    $self->avgmaxscoreXY(\@trgleafs,\@srcleafs,$self->{LEXF2E});
    }


    if (exists $$FeatTypes{avgmaxinside}){

	my $ST;
	if (exists $$values{avgmaxinsideST}){$ST=$$values{avgmaxinsideST};}
	else{$ST=$self->avgmaxscoreXY(\@srcleafs,\@trgleafs,$self->{LEXE2F});}

	my $TS;
	if (exists $$values{avgmaxinsideTS}){$TS=$$values{avgmaxinsideTS};}
	else{$TS=$self->avgmaxscoreXY(\@trgleafs,\@srcleafs,$self->{LEXF2E});}

	$$values{avgmaxinside}=$ST*$TS;
    }


    ## finally: another definition
    ## union of all prob's (is that justifyable?)

    if (exists $$FeatTypes{unioninsideST}){
	$$values{unioninsideST} = 
	    $self->unionscoreXY(\@srcleafs,\@trgleafs,$self->{LEXE2F});
    }
    if (exists $$FeatTypes{unioninsideTS}){
	$$values{unioninsideTS} = 
	    $self->unionscoreXY(\@trgleafs,\@srcleafs,$self->{LEXF2E});
    }

    if (exists $$FeatTypes{unioninside}){
	my $ST;
	if (exists $$values{unioninsideST}){$ST=$$values{unioninsideST};}
	else{$ST=$self->unionscoreXY(\@srcleafs,\@trgleafs,$self->{LEXE2F});}

	my $TS;
	if (exists $$values{unioninsideTS}){$TS=$$values{unioninsideTS};}
	else{$TS=$self->unionscoreXY(\@trgleafs,\@srcleafs,$self->{LEXF2E});}

	$$values{unioninside}=$ST*$TS;
    }
}



sub lex_outside_features{
    my $self=shift;
    my ($srctree,$trgtree,         # entire parse tree (source & target)
	$srcnode,$trgnode,         # current tree nodes
	$FeatTypes,$values)=@_;    # feature types to be returned in values


    # do nothing if we don't need outside features
    return 0 if ($self->{FEATURE_TYPES_STRING}!~/outside/);


    ## lexical outside scores
    ## -----------------------
    ## similar as for the inside scores but for outside words

    ## get leafs outside of current subtrees
    my @srcout = $self->{TREES}->get_outside_leafs($srctree,$srcnode);
    my @trgout = $self->{TREES}->get_outside_leafs($trgtree,$trgnode);

    ## lower casing if necessary

    if ($self->{-lex_lower}){
	for (0..$#srcout){
	    $srcout[$_]=lc($srcout[$_]);
	}
	for (0..$#trgout){
	    $trgout[$_]=lc($trgout[$_]);
	}
    }

    if (exists $$FeatTypes{outsideST1}){
	$$values{outsideST1} = $self->zhechev_scoreXY_NULL(\@srcout,\@trgout,
				   $self->{LEXE2F},$self->{LEXF2E},0);
    }
    if (exists $$FeatTypes{outsideTS1}){
	$$values{outsideST1} = $self->zhechev_scoreXY_NULL(\@trgout,\@srcout,
				   $self->{LEXF2E},$self->{LEXE2F},0);
    }

    if (exists $$FeatTypes{outsideST2}){
	$$values{outsideST2} = $self->zhechev_scoreXY_NULL(\@srcout,\@trgout,
				   $self->{LEXE2F},$self->{LEXF2E},1);
    }
    if (exists $$FeatTypes{outsideTS2}){
	$$values{outsideTS2} = $self->zhechev_scoreXY_NULL(\@trgout,\@srcout,
				   $self->{LEXF2E},$self->{LEXE2F},1);
    }


    ## without NULL links

    if (exists $$FeatTypes{outsideST3}){
	$$values{outsideST3} = $self->zhechev_scoreXY(\@srcout,\@trgout,
				   $self->{LEXE2F},$self->{LEXF2E},0);
    }
    if (exists $$FeatTypes{outsideTS3}){
	$$values{outsideST3} = $self->zhechev_scoreXY(\@trgout,\@srcout,
				   $self->{LEXF2E},$self->{LEXE2F},0);
    }

    if (exists $$FeatTypes{outsideST4}){
	$$values{outsideST4} = $self->zhechev_scoreXY(\@srcout,\@trgout,
				   $self->{LEXE2F},$self->{LEXF2E},1);
    }
    if (exists $$FeatTypes{outsideTS4}){
	$$values{outsideTS4} = $self->zhechev_scoreXY(\@trgout,\@srcout,
				   $self->{LEXF2E},$self->{LEXE2F},1);
    }



    ## outside scores a la Dublin Tree Aligner
    ## (without normalization)

    if (exists $$FeatTypes{outside1}){
	my $outsideST1;
	if (exists $$values{outsideST1}){$outsideST1=$$values{outsideST1};}
	else{
	    $outsideST1= $self->zhechev_scoreXY(\@srcout,\@trgout,
				       $self->{LEXE2F},$self->{LEXF2E},0);
	}
	my $outsideTS1;
	if (exists $$values{outsideTS1}){$outsideTS1=$$values{outsideTS1};}
	else{
	    $outsideTS1=$self->zhechev_scoreXY(\@trgout,\@srcout,
				       $self->{LEXF2E},$self->{LEXE2F},0);
	}
	$$values{outside1}=$outsideST1*$outsideTS1;
    }

    ## outside scores a la Dublin Tree Aligner
    ## (with normalization)

    if (exists $$FeatTypes{outside2}){
	my $outsideST2;
	if (exists $$values{outsideST2}){$outsideST2=$$values{outsideST2};}
	else{
	    $outsideST2= $self->zhechev_scoreXY_NULL(\@srcout,\@trgout,
				       $self->{LEXE2F},$self->{LEXF2E},1);
	}
	my $outsideTS2;
	if (exists $$values{outsideTS2}){$outsideTS2=$$values{outsideTS2};}
	else{
	    $outsideTS2= $self->zhechev_scoreXY_NULL(\@trgout,\@srcout,
				       $self->{LEXF2E},$self->{LEXE2F},1);
	}
	$$values{outside2}=$outsideST2*$outsideTS2;


# 	if ($$values{outside2}){

# 	    my @srcleafs = $self->{TREES}->get_leafs($srctree,$srcnode);
# 	    my @trgleafs = $self->{TREES}->get_leafs($trgtree,$trgnode);

# 	    print STDERR "inside: src = ";
# 	    print STDERR join(' ',@srcleafs);
# 	    print STDERR "\ninside: trg = ";
# 	    print STDERR join(' ',@trgleafs);
# 	    print STDERR "\n-----------$$values{inside2}------------------\n";

# 	    print STDERR "outside: src = ";
# 	    print STDERR join(' ',@srcout);
# 	    print STDERR "\noutside: trg = ";
# 	    print STDERR join(' ',@trgout);
# 	    print STDERR "\n-----------$$values{outside2}------------------\n";
# 	}

    }



    ## outside scores a la Dublin Tree Aligner
    ## (without normalization)

    if (exists $$FeatTypes{outside3}){
	my $outsideST3;
	if (exists $$values{outsideST3}){$outsideST3=$$values{outsideST3};}
	else{
	    $outsideST3= $self->zhechev_scoreXY(\@srcout,\@trgout,
				       $self->{LEXE2F},$self->{LEXF2E},0);
	}
	my $outsideTS3;
	if (exists $$values{outsideTS1}){$outsideTS3=$$values{outsideTS1};}
	else{
	    $outsideTS3=$self->zhechev_scoreXY(\@trgout,\@srcout,
				       $self->{LEXF2E},$self->{LEXE2F},0);
	}
	$$values{outside3}=$outsideST3*$outsideTS3;
    }

    ## outside scores a la Dublin Tree Aligner
    ## (with normalization)

    if (exists $$FeatTypes{outside4}){
	my $outsideST4;
	if (exists $$values{outsideST4}){$outsideST4=$$values{outsideST4};}
	else{
	    $outsideST4= $self->zhechev_scoreXY(\@srcout,\@trgout,
				       $self->{LEXE2F},$self->{LEXF2E},1);
	}
	my $outsideTS4;
	if (exists $$values{outsideTS4}){$outsideTS4=$$values{outsideTS4};}
	else{
	    $outsideTS4= $self->zhechev_scoreXY(\@trgout,\@srcout,
				       $self->{LEXF2E},$self->{LEXE2F},1);
	}
	$$values{outside4}=$outsideST4*$outsideTS4;

    }



    ## union of prob's


    if (exists $$FeatTypes{unionoutsideST}){
	$$values{unionoutsideST} = 
	    $self->unionscoreXY(\@srcout,\@trgout,$self->{LEXE2F});
    }
    if (exists $$FeatTypes{unionoutsideTS}){
	$$values{unionoutsideTS} = 
	    $self->unionscoreXY(\@trgout,\@srcout,$self->{LEXF2E});
    }


    if (exists $$FeatTypes{unionoutside}){

	my $ST;
	if (exists $$values{unionoutsideST}){$ST=$$values{unionoutsideST};}
	else{$ST=$self->unionscoreXY(\@srcout,\@trgout,$self->{LEXE2F});}

	my $TS;
	if (exists $$values{unionoutsideTS}){$TS=$$values{unionoutsideTS};}
	else{$TS=$self->unionscoreXY(\@trgout,\@srcout,$self->{LEXF2E});}

	$$values{unionoutside}=$ST*$TS;
    }

    if (exists $$FeatTypes{maxoutsideST}){
	$$values{maxoutsideST} = 
	    $self->maxscoreXY(\@srcout,\@trgout,$self->{LEXE2F});
    }
    if (exists $$FeatTypes{maxoutsideTS}){
	$$values{maxoutsideTS} = 
	    $self->maxscoreXY(\@trgout,\@srcout,$self->{LEXF2E});
    }


    ## max instead of average


    if (exists $$FeatTypes{maxoutside}){

	my $ST;
	if (exists $$values{maxoutsideST}){$ST=$$values{maxoutsideST};}
	else{$ST=$self->maxscoreXY(\@srcout,\@trgout,$self->{LEXE2F});}

	my $TS;
	if (exists $$values{maxoutsideTS}){$TS=$$values{maxoutsideTS};}
	else{$TS=$self->maxscoreXY(\@trgout,\@srcout,$self->{LEXF2E});}

	$$values{maxoutside}=$ST*$TS;
    }

    if (exists $$FeatTypes{avgmaxoutsideST}){
	$$values{avgmaxoutsideST} = 
	    $self->avgmaxscoreXY(\@srcout,\@trgout,$self->{LEXE2F});
    }
    if (exists $$FeatTypes{avgmaxoutsideTS}){
	$$values{avgmaxoutsideTS} = 
	    $self->avgmaxscoreXY(\@trgout,\@srcout,$self->{LEXF2E});
    }


    # average instead of product

    if (exists $$FeatTypes{avgmaxoutside}){

	my $ST;
	if (exists $$values{avgmaxoutsideST}){$ST=$$values{avgmaxoutsideST};}
	else{$ST=$self->avgmaxscoreXY(\@srcout,\@trgout,$self->{LEXE2F});}

	my $TS;
	if (exists $$values{avgmaxoutsideTS}){$TS=$$values{avgmaxoutsideTS};}
	else{$TS=$self->avgmaxscoreXY(\@trgout,\@srcout,$self->{LEXF2E});}

	$$values{avgmaxoutside}=$ST*$TS;
    }


}



## this is the implementation of the original Dublin Subtree aligner scores
## (including NULL links)

sub zhechev_scoreXY_NULL{
    my $self=shift;
    my ($src,$trg,$lex,$invlex,$normalize)=@_;

    return 1 if ((not @{$src}) && (not @{$trg}));

#    print STDERR join(' ',@{$src});
#    print STDERR "\n";
#    print STDERR join(' ',@{$trg});
#    print STDERR "\n--------------------------------\n";

    my @SRC=@{$src};
    my @TRG=@{$trg};
    push (@SRC,'NULL');      # add NULL words!
    push (@TRG,'NULL');      # on both sides

#    return 0 if (not @{$trg});
#    return 0 if (not @{$src});

    my $a=1;
    foreach my $s (@SRC){
	my $sum=0;

	# if one of the source words does not exist in the lexicon:
	# --> sum(s) is going to be zero
	# --> a(s|t) is going to be zero --> just ignore
	# (or should we return 0?)
	if (not exists($lex->{$s})){
	    if ($self->{-verbose}>1){
		print STDERR "no entry in lexicon for $s! --> ignore!\n";
	    }
	    next;
#	    return 0;
	}

	foreach my $t (@TRG){

	    if ($t eq 'NULL'){
		if ($s eq 'NULL'){                       # NULL --> NULL
		    if (not $sum){                       # no score otherwise
			$sum+=1;                         # = 1?!? (ok?)
#			print STDERR "add 1 for $s - $t\n";
		    }
		}
	    }

	    if (not exists($invlex->{$t})){
		next if ($t eq 'NULL');         # this is ok for NULL links
		if ($self->{-verbose}>1){
		    print STDERR "no entry in lexicon for $t! --> ignore!\n";
		}
		return 0;
	    }

	    if (exists($lex->{$s}->{$t})){
		$sum+=$lex->{$s}->{$t};
#		print STDERR "add $lex->{$s}->{$t} for $s - $t\n";
	    }
	}
	return 0 if (not $sum);  # sum=0? --> immediately stop and return 0

	if ($normalize){
	    $sum/=($#TRG+1);  # normalize sum by number of target tokens
	}
#	print STDERR "multiply $sum with $a\n";
	$a*=$sum;                # multiply with previous a(s|t)
    }
#    print STDERR "final score = $a\n";

    return $a;
#    return log($a);
#    return 1/(0-log($a));

}




## inside/outside scores without NULL link prob's

sub zhechev_scoreXY{
    my $self=shift;
    my ($src,$trg,$lex,$invlex,$normalize)=@_;

    return 0 if (not @{$trg});
    return 0 if (not @{$src});

    my $a=1;
    foreach my $s (@{$src}){
	my $sum=0;

	# if one of the source words does not exist in the lexicon:
	# --> sum(s) is going to be zero
	# --> a(s|t) is going to be zero --> just ignore
	# (or should we return 0?)
	if (not exists($lex->{$s})){
	    if ($self->{-verbose}>1){
		print STDERR "no entry in lexicon for $s! --> ignore!\n";
	    }
	    next;
#	    return 0;
	}

	foreach my $t (@{$trg}){
	    if (not exists($invlex->{$t})){
		if ($self->{-verbose}>1){
		    print STDERR "no entry in lexicon for $t! --> ignore!\n";
		}
		next;
	    }

	    if (exists($lex->{$s}->{$t})){
		$sum+=$lex->{$s}->{$t};
#		print STDERR "add $lex->{$s}->{$t} for $s - $t\n";
	    }
	}
	return 0 if (not $sum);  # sum=0? --> immediately stop and return 0

	if ($normalize){
	    $sum/=($#{$trg}+1);  # normalize sum by number of target tokens
	}
	$a*=$sum;                # multiply with previous a(s|t)
    }
    return $a;
}




# this is similar to the standard inside/outside scores
# but taking the max link value instead of the (normalized) sum

sub maxscoreXY{
    my $self=shift;
    my ($src,$trg,$lex)=@_;

    return 0 if (not @{$trg});
    return 0 if (not @{$src});

    my $a=1;
    foreach my $s (@{$src}){
	my $max=0;

	# if one of the source words does not exist in the lexicon:
	# --> max(s) is going to be zero
	# --> a(s|t) is going to be zero --> just ignore
	# (or should we return 0?)
	if (not exists($lex->{$s})){
	    if ($self->{-verbose}>1){
		print STDERR "no entry in lexicon for $s! --> ignore!\n";
	    }
	    next;
#	    return 0;
	}

	foreach my $t (@{$trg}){
	    if (exists($lex->{$s})){
		if (exists($lex->{$s}->{$t})){
		    if ($lex->{$s}->{$t}>$max){
			$max=$lex->{$s}->{$t};
		    }
		}
	    }
	}

	if (not $max){           # sum=0? --> immediately stop and return 0
	    return 0;
	}
#	return 0 if (not $max);  # sum=0? --> immediately stop and return 0

	$a*=$max;                # multiply with previous a(s|t)
    }
    return $a;
}



# this is similar to the standard inside/outside scores
# but taking the max link value instead of the (normalized) sum

sub avgmaxscoreXY{
    my $self=shift;
    my ($src,$trg,$lex)=@_;

    return 0 if (not @{$trg});
    return 0 if (not @{$src});

    my $a=0;
    foreach my $s (@{$src}){
	my $max=0;

	# if one of the source words does not exist in the lexicon:
	# --> max(s) is going to be zero
	# --> a(s|t) is going to be zero --> just ignore
	# (or should we return 0?)
	if (not exists($lex->{$s})){
	    if ($self->{-verbose}>1){
		print STDERR "no entry in lexicon for $s! --> ignore!\n";
	    }
	    next;
#	    return 0;
	}

	foreach my $t (@{$trg}){
	    if (exists($lex->{$s})){
		if (exists($lex->{$s}->{$t})){
		    if ($lex->{$s}->{$t}>$max){
			$max=$lex->{$s}->{$t};
		    }
		}
	    }
	}

#	if (not $max){           # sum=0? --> immediately stop and return 0
#	    return 0;
#	}
#	return 0 if (not $max);  # sum=0? --> immediately stop and return 0

	$a+=$max;                # multiply with previous a(s|t)
    }

    $a/=($#{$src}+1);
    return $a;
}





# this is another definition of inside/outside scores
# --> take the union of all prob's according to additon rule of prob's

sub unionscoreXY{
    my $self=shift;
    my ($src,$trg,$lex)=@_;

    return 0 if (not @{$trg});
    return 0 if (not @{$src});

    my $score=0;
    foreach my $s (@{$src}){
	next if (not exists($lex->{$s}));
	foreach my $t (@{$trg}){
	    if (exists($lex->{$s})){
		if (exists($lex->{$s}->{$t})){
		    $score+=$lex->{$s}->{$t}-$score*$lex->{$s}->{$t};
		}
	    }
	}
    }
    return $score;
}






1;
