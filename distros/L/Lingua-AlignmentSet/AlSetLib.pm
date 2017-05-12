package Lingua::AlSetLib;
$VERSION=1.1;
use strict;
use Dumpvalue;

# input: array of integers
# output: array of contiguous integer arrays
sub getContiguousSequences {
    my $array=shift;
    my $dumper = new Dumpvalue;
    
    my @sortedArray = sort {$a <=> $b} @$array;
#    print "sorted ARRay:\n";
#    print $dumper->dumpValue(\@sortedArray);
    my $sequences=[];
    my $numSeq=0;

    if (@$array > 0){
	my $former = $sortedArray[0];
	push @{$sequences->[$numSeq]},$former;
	for (my $i=1;$i<@sortedArray;$i++){
	    if ($sortedArray[$i]== ($former+1)){
		push @{$sequences->[$numSeq]},$sortedArray[$i];
	    }else{
		$numSeq++;
		push @{$sequences->[$numSeq]},$sortedArray[$i];
	    }
	    $former=$sortedArray[$i];
	}
    }
#    print "SEQUENCES (best $longuestSequence):\n";
#    print $dumper->dumpValue($sequences);
    return $sequences;
}

sub getLonguestContiguousSequence {
    my $array=shift;
    my $dumper = new Dumpvalue;
    
    my @sortedArray = sort {$a <=> $b} @$array;
#    print "sorted ARRay:\n";
#    print $dumper->dumpValue(\@sortedArray);
    my $sequences=[];
    my ($currentLength,$greatestLength,$longuestSequence,$numSeq)=(0,0,0,0);

    if (@$array > 0){
	my $former = $sortedArray[0];
	push @{$sequences->[$numSeq]},$former;
	$currentLength++;
	$greatestLength=$currentLength;
	$longuestSequence = $numSeq;
	for (my $i=1;$i<@sortedArray;$i++){
	    if ($sortedArray[$i]== ($former+1)){
		push @{$sequences->[$numSeq]},$sortedArray[$i];
		$currentLength++;
		if ($currentLength > $greatestLength){
		    $greatestLength=$currentLength;
		    $longuestSequence = $numSeq;
		}
	    }else{
		$numSeq++;
		push @{$sequences->[$numSeq]},$sortedArray[$i];
		$currentLength=1;
		if ($currentLength > $greatestLength){
		    $greatestLength=$currentLength;
		    $longuestSequence = $numSeq;
		}
	    }
	    $former=$sortedArray[$i];
	}
    }
#    print "SEQUENCES (best $longuestSequence):\n";
#    print $dumper->dumpValue($sequences);
    return $sequences->[$longuestSequence];
}

sub ibm1Prob {
    my ($src,$trg,$pt_s)=@_;
    my @wsrc=split(/ /, $src);
    my @wtrg=split(/ /, $trg);
    my $numWs = scalar(@wsrc);
    my $numWt = scalar(@wtrg);

    # IBM1 SRC->TRG
    if (@wsrc>1){
	unshift @wtrg,"NULL";
	$numWt++;
    }
    my $prod=1;
    for my $ws (@wsrc){
	my $sum=0;	    
	for my $wt (@wtrg){
	    my $srctrg="$ws ||| $wt";
	    $sum+=$pt_s->{$srctrg};
	    #print "\t$srctrg => $pt_s->{$srctrg} ( $sum )\n";
	}
	$prod*=$sum;
    }
    #calcul de la probabilitat ibm1
#    my $ibm1_st=$prod/($numWt**$numWs);
    my $ibm1_st=$prod;
    if ($ibm1_st==0){
	$ibm1_st=1.0e-40;
    }
#    print "$src | $trg ==> prod:$prod I:$numWt J:$numWs ibmst: $ibm1_st\n";
    return $ibm1_st;
}

# INPUT: ref to array A, ref to array B
# OUTPUT: list of positions of array A where array B begins in A
# EX: A=(4,5,8,3,9,22,8,3) B=(8,3) output=(2,6)
sub findArrayInAnother {
    my ($refToSubArray,$refToArray)=@_;
    my @startPosi;
    my $numSub = scalar(@$refToSubArray);
    my $numArray=scalar(@$refToArray);
    if ($numArray >= $numSub){
	for (my $i=0;$i<$numArray;$i++){
	    my $failed=0;
	    my $subi=0;
	    while (!$failed && $subi<$numSub){
		if ($refToSubArray->[$subi] ne $refToArray->[$i+$subi]){$failed=1;}
		$subi++;
	    }
	    if (!$failed){push @startPosi,$i;}
	}
    }
    return @startPosi;
}

#########################################################
### SUBROUTINES COPIED FROM ALGORITHM::DIFF CPAN MODULE #
#########################################################
sub _withPositionsOfInInterval
{
    my $aCollection = shift;    # array ref
    my $start       = shift;
    my $end         = shift;
    my $keyGen      = shift;
    my %d;
    my $index;
    for ( $index = $start ; $index <= $end ; $index++ )
    {
        my $element = $aCollection->[$index];
        my $key = &$keyGen( $element, @_ );
        if ( exists( $d{$key} ) )
        {
            unshift ( @{ $d{$key} }, $index );
        }
        else
        {
            $d{$key} = [$index];
        }
    }
    return wantarray ? %d : \%d;
}

sub _replaceNextLargerWith
{
    my ( $array, $aValue, $high ) = @_;
    $high ||= $#$array;

    # off the end?
    if ( $high == -1 || $aValue > $array->[-1] )
    {
        push ( @$array, $aValue );
        return $high + 1;
    }

    # binary search for insertion point...
    my $low = 0;
    my $index;
    my $found;
    while ( $low <= $high )
    {
        $index = ( $high + $low ) / 2;

        # $index = int(( $high + $low ) / 2);  # without 'use integer'
        $found = $array->[$index];

        if ( $aValue == $found )
        {
            return undef;
        }
        elsif ( $aValue > $found )
        {
            $low = $index + 1;
        }
        else
        {
            $high = $index - 1;
        }
    }

    # now insertion point is in $low.
    $array->[$low] = $aValue;    # overwrite next larger
    return $low;
}

sub _longestCommonSubsequence
{
    my $a        = shift;    # array ref or hash ref
    my $b        = shift;    # array ref or hash ref
    my $counting = shift;    # scalar
    my $keyGen   = shift;    # code ref
    my $compare;             # code ref

    if ( ref($a) eq 'HASH' )
    {                        # prepared hash must be in $b
        my $tmp = $b;
        $b = $a;
        $a = $tmp;
    }

    # Check for bogus (non-ref) argument values
    if ( !ref($a) || !ref($b) )
    {
        my @callerInfo = caller(1);
        die 'error: must pass array or hash references to ' . $callerInfo[3];
    }

    # set up code refs
    # Note that these are optimized.
    if ( !defined($keyGen) )    # optimize for strings
    {
        $keyGen = sub { $_[0] };
        $compare = sub { my ( $a, $b ) = @_; $a eq $b };
    }
    else
    {
        $compare = sub {
            my $a = shift;
            my $b = shift;
            &$keyGen( $a, @_ ) eq &$keyGen( $b, @_ );
        };
    }

    my ( $aStart, $aFinish, $matchVector ) = ( 0, $#$a, [] );
    my ( $prunedCount, $bMatches ) = ( 0, {} );

    if ( ref($b) eq 'HASH' )    # was $bMatches prepared for us?
    {
        $bMatches = $b;
    }
    else
    {
        my ( $bStart, $bFinish ) = ( 0, $#$b );

        # First we prune off any common elements at the beginning
        while ( $aStart <= $aFinish
            and $bStart <= $bFinish
            and &$compare( $a->[$aStart], $b->[$bStart], @_ ) )
        {
            $matchVector->[ $aStart++ ] = $bStart++;
            $prunedCount++;
        }

        # now the end
        while ( $aStart <= $aFinish
            and $bStart <= $bFinish
            and &$compare( $a->[$aFinish], $b->[$bFinish], @_ ) )
        {
            $matchVector->[ $aFinish-- ] = $bFinish--;
            $prunedCount++;
        }

        # Now compute the equivalence classes of positions of elements
        $bMatches =
          _withPositionsOfInInterval( $b, $bStart, $bFinish, $keyGen, @_ );
    }
    my $thresh = [];
    my $links  = [];

    my ( $i, $ai, $j, $k );
    for ( $i = $aStart ; $i <= $aFinish ; $i++ )
    {
        $ai = &$keyGen( $a->[$i], @_ );
        if ( exists( $bMatches->{$ai} ) )
        {
            $k = 0;
            for $j ( @{ $bMatches->{$ai} } )
            {

                # optimization: most of the time this will be true
                if ( $k and $thresh->[$k] > $j and $thresh->[ $k - 1 ] < $j )
                {
                    $thresh->[$k] = $j;
                }
                else
                {
                    $k = _replaceNextLargerWith( $thresh, $j, $k );
                }

                # oddly, it's faster to always test this (CPU cache?).
                if ( defined($k) )
                {
                    $links->[$k] =
                      [ ( $k ? $links->[ $k - 1 ] : undef ), $i, $j ];
                }
            }
        }
    }

    if (@$thresh)
    {
        return $prunedCount + @$thresh if $counting;
        for ( my $link = $links->[$#$thresh] ; $link ; $link = $link->[0] )
        {
            $matchVector->[ $link->[1] ] = $link->[2];
        }
    }
    elsif ($counting)
    {
        return $prunedCount;
    }

    return wantarray ? @$matchVector : $matchVector;
}

sub LCS
{
    my $a = shift;                  # array ref
    my $b = shift;                  # array ref or hash ref
    my $matchVector = _longestCommonSubsequence( $a, $b, 0, @_ );
    my @retval;
    my $i;
    for ( $i = 0 ; $i <= $#$matchVector ; $i++ )
    {
        if ( defined( $matchVector->[$i] ) )
        {
            push ( @retval, $a->[$i] );
        }
    }
    return wantarray ? @retval : \@retval;
}

sub LCS_ratio
{
    my $a = shift;                          # array ref
    my $b = shift;                          # array ref or hash ref
     
    my $lon=_longestCommonSubsequence( $a, $b, 1, @_ );
#    if ($lon>0){print "LCS:$lon\n";}
    my $ratio;
    #Aquí hago el ratio de la similitud cogiendo como valor total la longitud de la frase que sea más larga
    my $m=scalar(@$a);
    my $n=scalar(@$b);
   if (($m >= $n) && ($m != 0) && ($n != 0)){$ratio=$lon/$m;}
    elsif(($m < $n) && ($m != 0) && ($n != 0)){$ratio=$lon/$n;}
    else{$ratio=0;}

    return ($ratio);
}

sub traverse_sequences
{
    my $a                 = shift;          # array ref
    my $b                 = shift;          # array ref
    my $callbacks         = shift || {};
    my $keyGen            = shift;
    my $matchCallback     = $callbacks->{'MATCH'} || sub { };
    my $discardACallback  = $callbacks->{'DISCARD_A'} || sub { };
    my $finishedACallback = $callbacks->{'A_FINISHED'};
    my $discardBCallback  = $callbacks->{'DISCARD_B'} || sub { };
    my $finishedBCallback = $callbacks->{'B_FINISHED'};
    my $matchVector = _longestCommonSubsequence( $a, $b, 0, $keyGen, @_ );

    # Process all the lines in @$matchVector
    my $lastA = $#$a;
    my $lastB = $#$b;
    my $bi    = 0;
    my $ai;

    for ( $ai = 0 ; $ai <= $#$matchVector ; $ai++ )
    {
        my $bLine = $matchVector->[$ai];
        if ( defined($bLine) )    # matched
        {
            &$discardBCallback( $ai, $bi++, @_ ) while $bi < $bLine;
            &$matchCallback( $ai,    $bi++, @_ );
        }
        else
        {
            &$discardACallback( $ai, $bi, @_ );
        }
    }

    # The last entry (if any) processed was a match.
    # $ai and $bi point just past the last matching lines in their sequences.

    while ( $ai <= $lastA or $bi <= $lastB )
    {

        # last A?
        if ( $ai == $lastA + 1 and $bi <= $lastB )
        {
            if ( defined($finishedACallback) )
            {
                &$finishedACallback( $lastA, @_ );
                $finishedACallback = undef;
            }
            else
            {
                &$discardBCallback( $ai, $bi++, @_ ) while $bi <= $lastB;
            }
        }

        # last B?
        if ( $bi == $lastB + 1 and $ai <= $lastA )
        {
            if ( defined($finishedBCallback) )
            {
                &$finishedBCallback( $lastB, @_ );
                $finishedBCallback = undef;
            }
            else
            {
                &$discardACallback( $ai++, $bi, @_ ) while $ai <= $lastA;
            }
        }

        &$discardACallback( $ai++, $bi, @_ ) if $ai <= $lastA;
        &$discardBCallback( $ai, $bi++, @_ ) if $bi <= $lastB;
    }

    return 1;
}

#diff computes the smallest set of additions and deletions necessary to turn the first sequence into the second, and returns a description of these changes. The description is a list of hunks; each hunk represents a contiguous section of items which should be added, deleted, or replaced. (Hunks containing unchanged items are not included.)
# EXAMPLES:
#   @diffs     = diff( \@seq1, \@seq2 );
#   $diffs_ref = diff( \@seq1, \@seq2 );
sub diff
{
    my $a      = shift;    # array ref
    my $b      = shift;    # array ref
    my $retval = [];
    my $hunk   = [];
    my $discard = sub {
        push @$hunk, [ '-', $_[0], $a->[ $_[0] ] ];
    };
    my $add = sub {
        push @$hunk, [ '+', $_[1], $b->[ $_[1] ] ];
    };
    my $match = sub {
        push @$retval, $hunk
            if 0 < @$hunk;
        $hunk = []
    };
    traverse_sequences( $a, $b,
        { MATCH => $match, DISCARD_A => $discard, DISCARD_B => $add }, @_ );
    &$match();
    return wantarray ? @$retval : $retval;
}

###### END ALGORITHM::DIFF FUNCTIONS


sub max {
    my ($a,$b)=@_;
    if ($a > $b) {return $a;}
    else {return $b};
}

sub min {
    my ($a,$b)=@_;
    if ($a < $b) {return $a;}
    else {return $b};
}

### copy-paste of Algorithm::MinMax module (to avoid having dependencies)
sub minmax {
	my @array = @{ $_[ 1 ] };
	my @result;
	if( scalar( @array ) == 0 ) {
		return @result;
	} 
	if( scalar( @array ) == 1 ) {
		$result[ 0 ] = $array[ 0 ];
		$result[ 1 ] = $array[ 0 ];
		return @result;
	}
	my @min_cand;
	my @max_cand;
	my $r = scalar( @array ) - 2;
	my $k = 0;
	for( my $i = 0; $i <= $r ; $i = $i + 2 ) {
		if( $array[ $i ] < $array[ $i + 1 ] ) {
			$min_cand[ $k ] = $array[ $i ];
			$max_cand[ $k ] = $array[ $i + 1 ];
		} else {
			$min_cand[ $k ] = $array[ $i + 1 ];
			$max_cand[ $k ] = $array[ $i ];
		}
		++$k;
	}
	if( scalar( @array ) % 2 != 0 ) {
		if( $min_cand[ 0 ] < $array[ $r + 1 ] ) {
			$max_cand[ $k ] = $array[ $r + 1 ];
		} else {
			$min_cand[ $k ] = $array[ $r + 1 ];
		}
	}
	my $m = $min_cand[ 0 ];
	for( my $i = 1; $i < scalar( @min_cand ); ++$i ) {
		if( $min_cand[ $i ] < $m ) {
			$m = $min_cand[ $i ];
		}
	}
	$result[ 0 ] = $m;
	$m = $max_cand[ 0 ];
	for( my $i = 1; $i < scalar( @max_cand ); ++$i ) {
		if( $max_cand[ $i ] > $m ) {
			$m = $max_cand[ $i ];
		}
	}
	$result[ 1 ] = $m;
	@result;
}

### END Algorithm::MinMax function



sub escapeRegExp {
    my $line = shift;
    # regExp characters to escape: \ | ( ) [  {  ^ $ * + ? .
    $line =~ s/\\/\\\\/g;
    $line =~ s/\|/\\\|/g;
    $line =~ s/\(/\\\(/g;
    $line =~ s/\)/\\\)/g;
    $line =~ s/\[/\\\[/g;
    $line =~ s/\{/\\\}/g;
    $line =~ s/\^/\\\^/g;
    $line =~ s/\$/\\\$/g;
    $line =~ s/\*/\\\*/g;
    $line =~ s/\+/\\\+/g;
    $line =~ s/\?/\\\?/g;
    $line =~ s/\./\\\./g;
    return $line;
}

1;
