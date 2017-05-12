=head1 NAME

Finance::CompanyNames - Functions for finding company names in English free text

=head1 SYNOPSIS

    use Finance::CompanyNames;
    
    my $corps = {
        MSFT => 'Microsoft'
      , INTC => 'Intel'
      , etc...
    };
    
    Finance::CompanyNames::Init($corps)
    $hashref = Finance::CompanyNames::Match($freetext);
    
=head1 DESCRIPTION

Finance::CompanyNames finds company names in English text.  The user provides
a list of company names they wish to find, and the body of text to search.
The module then uses natural language processing techniques to find those
names or their variants in the text.  For example, if a company is alternately
referred to as "XYZ", "XYZ Corp.", "XYZ Corporation", and "The XYZ Corporation",
Finance::CompanyNames will recognize all variants.

=head1 INTERFACE

=head2 Initialization

It is necessary to call Finance::CompanyNames::Init() before anything else.
The argument to this function is a reference to a hash.  The canonical use
is to use stock tickers as the keys and company names as values.  However, you
are free to use anything for the keys.

=head2 Searching

Finance::CompanyNames::Match searches a body of text for company names.  The only
argument is a scalar containing the text.  The return value is a reference to a hash
of references to hashes.  The keys are the stock ticker symbols of company names
found in the text, or other keys you may have used in Init().  The values are hashes
with keys "freq" and "contexts".  "freq" is the number of times the company was seen
in the text, and "contexts" is a reference to an array storing the bit of text
mentioning the company.

For example:

$rv = {
    INTC => {
        freq     => 10
      , contexts => [
            "blah blah blah blah blah Intel blah blah blah blah"
          , "blah Intel Corp. blah blah blah blah blah blah"
        ]
    }
};

=head1 NOTE

Please note that Finance::CompanyNames allocates a massive amount of memory.
It loads a complete English wordlist as well as a list of English root words
and their affixes.  This requires approximately 20MB of memory on the author's
computer.  It is possible for a future version to behave differently.  Please
mail the author if you have an improvement.

Also please note this module only works with English text, due to the included
word and stem lists.

=head1 AUTHORS

Finance::CompanyNames is a product of Gilder, Gagnon, Howe, & Co. LLC.
Mail GGHC Skunkworks <cpan@gghcwest.com> regarding this software.

=head1 LICENSE

Finance::CompanyNames is distributed under the Artistic License, the same
terms under which Perl itself is distributed.

=cut

package Finance::CompanyNames;

use strict;
use Finance::CompanyNames::TextSupport;

use vars qw(@ISA @EXPORT_OK $VERSION %quants %names %wholeNames %leaders %abbrevs $avgLength $stems $dict $threshold);

$VERSION = 1.0;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(Init Match);

#### Init Function -- initialize the set of names/tickers to be matched.

# parameter $data is a ref to hash of ticker => name

sub Init {
    my $data = shift;

    %quants = ();
    %names = ();
    %wholeNames = ();
    %leaders = ();
    %abbrevs = ();
    
    $abbrevs{IBM} = "IBM";
    $abbrevs{ATT} = "T";
    $abbrevs{NEC} = "NIPNY";
    $abbrevs{RCN} = "RCNC";

    $stems = Finance::CompanyNames::TextSupport::pandkStems();
    $dict = Finance::CompanyNames::TextSupport::linuxDict();
    
    get_info($data);
    
    $threshold = 0.65;

}


######### find matches in a string
# parameter is a string
# returns a ref to a hash where each key is the ticker of a match.
# the hash entry keyed by a symbol is a 
# ref to a hash with the following members:
#     -- freq : # of times that ticker's name matched in the string
#     -- contexts: a ref to an array of strings that are the contexts 
#                  in which those matches were found



sub Match {
    my $s = shift;
    
    my %utica = matches($s);

    return \%utica;
}


############# HELPERS ---------------------------------------

sub matches
{
    my ($str) = @_;
    my @lexems = get_lexems($str);

    my ($i, $incr, $context, $lexem, $lower, $allUpper);
    
    my %utica = ();
    my ($ms, $mtic, $abbrev, $uniq);
    my ($kk, $nn, $ss);
    my ($chainBegin, $chainEnd, $links, $wordBuff, $lastMatch, $mid, $contextLength);

    $chainBegin = -1;
    
    my $nLex = scalar(@lexems);
    for ($i = 0, $incr = 1; $i < $nLex; $i += $incr)
    {
	$ms = 0;
	$mtic = "";
	$abbrev = 0;
	($lexem,$incr)  = aggregateLetters(\@lexems, $i);

	if(length($lexem) >= 3 && exists $abbrevs{$lexem}) {
	    $ms = $threshold;
	    $mtic = $abbrevs{$lexem};
	    $abbrev = 1;
	}

	# Check if the lexem exists as a leader
	if (exists $leaders{$lexem})
	{
	    my $nLeaders = scalar(@{$leaders{$lexem}});
	    my @score = ();

	    for (my $j = 0; $j < $nLeaders; $j++)
	    {
		my $ticker = $leaders{$lexem}[$j];
		my $parts = $names{$ticker};

		$uniq = 0;

		$score[$j] = match_lead($parts, \@lexems, $i + $incr, $ticker);

		 ($kk, $nn, $ss) = @{$score[$j]};

		$lower = $lexem;
		$lower =~ tr/[A-Z]/[a-z]/;

		$_ = $lexem;
		$allUpper = ! /[a-z]/;

		if($kk == 1 && $quants{$lexem} == 1 && ! exists $stems->{$lower} && ! exists $dict->{$lower} && ! $allUpper) {

		    $uniq = 1;
		    $kk++;
		    
		}

		$ss = $kk / $nn;
	    
		if ($ms < $ss)
		{
		    $ms = $ss;
		    $mtic = $ticker;
		}	 
	    }
	}


	# Attempt to disambiguate #1: max score
	my $isMatch = 0;
	if($ms >= $threshold) { # match is found
	    $isMatch = 1;

	    $_ = $mtic;
	    if(/may/i) {
#		print "found $mtic: $mtic, $kk, $nn (" . getContext($i, \@lexems, 10);
	    }
	    if($chainBegin == -1) {
		$links = {};
		$chainBegin = $i;
	    }
	    $lastMatch = $i + $incr - 1;
	    $wordBuff = int($kk + 1 + 0.5);
	    
	    if(! exists $links->{$mtic}) {
		$links->{$mtic} = 1;
	    }
	    else {
		$links->{$mtic}++;
	    }
	}

	if(((!$isMatch) || $i >= $nLex - 1)  &&  $chainBegin != -1) {
	    
	    if(exists $quants{$lexem} && $quants{$lexem} < 0.25) {
		$wordBuff+= $avgLength;
	    }
	    
	    
	    
	    if($i > $lastMatch + $wordBuff || $i >= $nLex - 1 ) {
		$chainEnd = $lastMatch;
		$mid = int( ($chainBegin + $chainEnd) / 2);
		$contextLength = 20 + $mid - $chainBegin;
		$context = getContext($mid, \@lexems, $contextLength);
		
		
		foreach $mtic (keys %$links) {
		    
		    if(! exists $utica{$mtic}) {
			$utica{$mtic} = {};
			$utica{$mtic}->{freq} = 0;
			$utica{$mtic}->{contexts} = [];
		    }
		    
		    if($utica{$mtic}->{freq} <= 5) {
			push(@{$utica{$mtic}->{contexts}}, $context);
		    }
		    $utica{$mtic}->{freq} += $links->{$mtic};
		}
		$chainBegin = -1;
	    }
	}
    }

    return %utica;
}

sub match_lead
{
    my ($parts, $lexems, $i, $ticker) = @_;
   
    my $n = scalar(@$parts);


    my $k = 1;
    my $go = 1;

    my $s = 0;
    my ($incr, $lexem);

    for (my $j = 1, $incr = 1; $j < $n && $i < scalar(@$lexems); $j++, $i += $incr) 
    {
	($lexem, $incr) = aggregateLetters($lexems, $i);
	my $part = $parts->[$j];
	# fix Bank of Montreal

	if ($part eq $lexem)
	{
	    if(validWord($lexem)) {
		$k++ if $go;
	    }
	    else {
		$k += 0.5 if $go;
	    }
	}
	else
	{
	    $go = 0;
	    if (exists($quants{$lexem}))
	    {
		$s += $quants{$lexem};
	    }
	}
    }



    return [$k, $n, $s];
}

sub validWord {
    my ($lexem) = @_;

    $_ = $lexem;
    my $allUpper = ! /[a-z]/;

    return ($allUpper || length($lexem) > 2);
}

sub getContext {
    my ($i, $lexems, $contextSize) = @_;

    my($context, $min, $max);

    $context = "...";
    $min = $i - $contextSize;
    $max = $i + $contextSize;
    if($min < 0) {
	$min = 0;
    }
    if($max > scalar(@$lexems)) {
	$max = scalar(@$lexems);
    }

    for($i = $min; $i <= $max; $i++) {
	if (defined $lexems->[$i]) {
	    $context = $context . " " . $lexems->[$i];
	}
    }

    $context = $context . " ...";

    return $context;
}

sub get_info
{  
    my $data = shift;

    $avgLength = 0;

    while(my ($ticker, $name) = each(%$data)) {

	next if ($ticker !~ /[\w]+/ || $name !~ /[\w]+/ );

	my @particles = split /[^\w]+/, $name;

	next if (!scalar(@particles));
	shift @particles if ($particles[0] eq "");
	next if (!scalar(@particles));

	my (@agParticles, $w);


	my($i, $incr);
	for($i = 0, $incr = 1; $i < scalar(@particles); $i += $incr) {
	    ($w, $incr) = aggregateLetters(\@particles, $i);
	    push(@agParticles, $w);
	}

	$names{$ticker} = \@agParticles;

	$avgLength += scalar(@agParticles);

	$wholeNames{$ticker} = $name;

	my $word = $agParticles[0];
	push(@{$leaders{$word}}, $ticker);	
	for (my $k = 0; $k < @agParticles; $k++)
	{
	    $word = $agParticles[$k];
	    
	    $quants{$word}++;
	}         
    }
    
    while (my ($ww, $quant) = each(%quants))
    {
	$quants{$ww} = 1 / $quant;
    } 

    $avgLength = int($avgLength / scalar(keys %names) + 0.5);

}

sub aggregateLetters {
    my ($words, $i) = @_;

    my $done = 0;
    my $len = 1;
    my $word = $words->[$i];
    my $res = $word;

    if(length($word) == 1) {
	while((! $done) && ($i + $len) < scalar(@$words)) {
	    $word = $words->[$i + $len];
	    if(length($word) == 1) {
		$res .= $word;
		$len++;
	    }
	    else {
		$done = 1;
	    }
	}
    }

    return ($res, $len);

}

sub get_lexems
{
    my $str = shift;

    $_ = $str;

    my @words = split /[^\w]+/;
    
    return @words;
}


1;
