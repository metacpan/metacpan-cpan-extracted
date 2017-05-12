package Lingua::Stem::It;

use strict;


use Exporter;
use Carp;
use vars qw (@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);
BEGIN {
    @ISA         = qw (Exporter);
    @EXPORT      = ();
    @EXPORT_OK   = qw (stem stem_word clear_stem_cache stem_caching);
    %EXPORT_TAGS = ();
}
$VERSION = "0.02";

my $Stem_Caching  = 0;
my $Stem_Cache    = {};


sub stem {
    return [] if ($#_ == -1);
    my $parm_ref;
    if (ref $_[0]) {
        $parm_ref = shift;
    } else {
        $parm_ref = { @_ };
    }
    
    my $words      = [];
    my $locale     = 'it';
    my $exceptions = {};
    foreach (keys %$parm_ref) {
        my $key = lc ($_);
        if ($key eq '-words') {
            @$words = @{$parm_ref->{$key}};
        } elsif ($key eq '-exceptions') {
            $exceptions = $parm_ref->{$key};
        } elsif ($key eq '-locale') {
            $locale = $parm_ref->{$key};
        } else {
            croak (__PACKAGE__ . "::stem() - Unknown parameter '$key' with value '$parm_ref->{$key}'\n");
        }
    }
    
    local( $_ );
    foreach (@$words) {
        # Flatten case
        $_ = lc $_;

        # Check against exceptions list
        if (exists $exceptions->{$_}) {
			$_ = $exceptions->{$_};
			next;
		}

        # Check against cache of stemmed words
        my $original_word = $_;
        if ($Stem_Caching && exists $Stem_Cache->{$original_word}) {
            $_ = $Stem_Cache->{$original_word}; 
            next;
        }

	$_ = stem_word($_);

        $Stem_Cache->{$original_word} = $_ if $Stem_Caching;
    }
    $Stem_Cache = {} if ($Stem_Caching < 2);
    
    return $words;

}

sub stem_word {

	our($word) = @_;
	my @suffix;

	$word = lc $word;

	# Check against cache of stemmed words
	if ($Stem_Caching && exists $Stem_Cache->{$word}) {
		return $Stem_Cache->{$word}; 
	}

	our($RV, $R1, $R2);

	#### First, replace all acute accents by grave accents.
	$word =~ s/é/è/g;

	### put u after q, and u, i between vowels into upper case.
	$word =~ s/([aàeèiìoòuù])([ui])([aàeèiìoòuù])/$1.uc($2).$3/eg;

	#### RV is defined as follows 
	$RV = $word;

	#### If the second letter is a consonant,
	if($word =~ /^.[^aàeèiìoòuù]/) {

		#### RV is the region after the next following vowel
		$RV =~ s/^..[^aàeèiìoòuù]*[aàeèiìoòuù]//;

	#### or if the first two letters are vowels
	} elsif ($word =~ /^[aàeèiìoòuù][^aàeèiìoòuù]/) {

		#### RV is the region after the next consonant
		$RV =~ s/^..[aàeèiìoòuù]*[^aàeèiìoòuù]//;

	#### and otherwise (consonant-vowel case)
	} else {

		#### RV is the region after the third letter
		$RV =~ s/^...//;
	}

	#print "RV=$RV\n";

	#### Defining R1 and R2
	$R1 = $word;

	#### R1 is the region after the first non-vowel following a 
	#### vowel, or is the null region at the end of the word if 
	#### there is no such non-vowel. 

	unless($R1 =~ s/^.*?[aàeèiìoòuù][^aàeèiìoòuù]//) {
		$R1 = "";
	}

	#print "R1=$R1\n";

	#### R2 is the region after the first non-vowel following a 
	#### vowel in R1, or is the null region at the end of the 
	#### word if there is no such non-vowel. 

	$R2 = $R1;

	if($R2) {
		unless($R2 =~ s/^.*?[aàeèiìoòuù][^aàeèiìoòuù]//) {
			$R2 = "";
		}
	}

	#print "R2=$R2\n";

	#### Step 0: Attached pronoun 
	##### Search for the longest among the following suffixes
	my @pronoun = qw(
		ci   gli   la   le   li   lo   mi   ne   si   ti   vi   
		sene   gliela   gliele   glieli   glielo   gliene   
		mela   mele   meli   melo   mene   
		tela   tele   teli   telo   tene   
		cela   cele   celi   celo   cene   
		vela   vele   veli   velo   vene 
	);

	#### following one of 
	#### (a) ando   endo
	#### (b) ar   er   ir 
	#### in RV. 
	#### In case of (a) the suffix is deleted, 
	#### in case (b) it is replace by e

		stem_killer( $RV, "[ae]ndo", "",  @pronoun )
	or	stem_killer( $RV, "[aei]r",  "e", @pronoun );


	#### Step 1: Standard suffix removal 

	my $step1 = 0;

	#### Search for the longest among the following suffixes, 
	#### and perform the action indicated
	
	@suffix = qw(
		anza   anze   
		ico   ici   ica   ice   iche   ichi   
		ismo   ismi   
		abile   abili   ibile   ibili   
		ista   iste   isti   istà   istè   istì   
		oso   osi   osa   ose   
		mente   
		atrice   atrici 
	);

	#### delete if in R2 
	$step1 += stem_killer( $R2, "", "", @suffix );

	@suffix = qw(
		icazione   icazioni   icatore   icatori
		azione   azioni   atore   atori
	);

	#### delete if in R2 
	#### if preceded by ic, delete if in R2 
	$step1 += stem_killer( $R2, "", "", @suffix );

	@suffix = qw(
		logia   logie 
	);

	#### replace with log if in R2 
	$step1 += stem_killer( $R2, "", "log", @suffix );

	@suffix = qw(
		uzione   uzioni   usione   usioni 
	);

	#### replace with u if in R2 
	$step1 += stem_killer( $R2, "", "u", @suffix );

	@suffix = qw(
		enza   enze 
	);

	#### replace with ente if in R2 
	$step1 += stem_killer( $R2, "", "ente", @suffix );

	@suffix = qw(
		amento   amenti   imento   imenti 
	);

	#### delete if in RV 
	$step1 += stem_killer( $RV, "", "", @suffix );

	@suffix = qw(
		amente 
	);

	#### delete if in R1 
	#### if preceded by iv, delete if in R2 
	#### (and if further preceded by at, delete if in R2), otherwise, 
	#### if preceded by os, ic or abil, delete if in R2 
	$step1 += stem_killer( $R2, "ativ",         "", @suffix )
		   || stem_killer( $R2, "iv",           "", @suffix )
		   || stem_killer( $R2, "(os|ic|abil)", "", @suffix )
		   || stem_killer( $R1, "",             "", @suffix );

	@suffix = qw(
		ità
	);

	#### delete if in R2 
	#### if preceded by abil, ic or iv, delete if in R2 
	$step1 += stem_killer( $R2, "(abil|ic|iv)", "", @suffix )
		   || stem_killer( $R2, "",             "", @suffix );


	@suffix = qw(
		ivo   ivi   iva   ive 
	);

	#### delete if in R2 
	#### if preceded by at, delete if in R2 
	#### (and if further preceded by ic, delete if in R2) 
	$step1 += stem_killer( $R2, "icat", "", @suffix)
		   || stem_killer( $R2, "at",   "", @suffix)
		   || stem_killer( $R2, "",     "", @suffix);


	#### Step 2: Verb suffixes 

	#### Do step 2 if no ending was removed by step 1. 
	if($step1 == 0) {

		#### Search for the longest among the following suffixes in RV, 
		#### and if found, delete. 
		stem_killer( $RV, "", "", qw(
			ammo   ando   ano   are   arono   asse   assero   assi   assimo   
			ata   ate   ati   ato   ava   avamo   avano   avate   avi   avo   
			emmo   enda   ende   endi   endo   erà   erai   eranno   ere   
			erebbe   erebbero   erei   eremmo   eremo   ereste   eresti   
			erete   erò   erono   essero   ete   eva   evamo   evano   evate   
			evi   evo   Yamo   iamo   immo   irà   irai   iranno   ire   
			irebbe   irebbero   irei   iremmo   iremo   ireste   iresti   
			irete   irò   irono   isca   iscano   isce   isci   isco   iscono   
			issero   ita   ite   iti   ito   iva   ivamo   ivano   ivate   
			ivi   ivo   ono   uta   ute   uti   uto   ar   er 
		));	
	}

	#### Step 3a 
	#### Delete a final a, e, i, o, à, è, ì or ò if it is in RV, 
	#### and a preceding i if it is in RV
	if($RV =~ s/i?[aeioàèìò]$//) {
		$word =~ s/i?[aeioàèìò]$//;
	#} else {
	#	if($RV =~ s/[aeioàèìò]$//) {
	#		$word =~ s/[aeioàèìò]$//;
	#	}
	}

	#### Step 3b 
	#### Replace final ch (or gh) with c (or g) if in RV
	if($RV =~ s/([cg])h$/$1/) {
		$word =~ s/([cg])h$/$1/;
	}

	#### Finally,
	#### turn I and U back into lower case 
	$word =~ s/([IU])/lc($1)/eg;

	return $word;

}

sub stem_killer {
	my($where, $pre, $with, @list) = @_;
	use vars qw($RV $R1 $R2 $word);
	my $done = 0;
	foreach my $P (sort { length($b) <=> length($a) } @list) {
		if($where =~ /$pre$P$/) {
			$R2 =~ s/$pre$P$/$with/;
			$R1 =~ s/$pre$P$/$with/;
			$RV =~ s/$pre$P$/$with/;
			$word =~ s/$pre$P$/$with/;
			$done = 1;
			last;
		}
	}
	return $done;
}

sub stem_caching {
    my $parm_ref;
    if (ref $_[0]) {
        $parm_ref = shift;
    } else {
        $parm_ref = { @_ };
    }
    my $caching_level = $parm_ref->{-level};
    if (defined $caching_level) {
        if ($caching_level !~ m/^[012]$/) {
            croak(__PACKAGE__ . "::stem_caching() - Legal values are '0','1' or '2'. '$caching_level' is not a legal value");
        }
        $Stem_Caching = $caching_level;
    }
    return $Stem_Caching;
}    

sub clear_stem_cache {
    $Stem_Cache = {};
}
	

1;
__END__

=head1 NAME

Lingua::Stem::It - Porter's stemming algorithm for Italian

=head1 SYNOPSIS

    use Lingua::Stem::It;
    my $stems = Lingua::Stem::It::stem({ -words => $word_list_reference,
                                         -locale => 'it',
                                         -exceptions => $exceptions_hash,
                                      });
    
    my $stem = Lingua::Stem::It::stem_word( $word );                                      

=head1 DESCRIPTION

This module applies the Porter Stemming Algorithm to its parameters,
returning the stemmed words.

The algorithm is implemented exactly (I hope :-) as described in:

    http://snowball.tartarus.org/algorithms/italian/stemmer.html

The code is carefully crafted to work in conjunction with the L<Lingua::Stem>
module by Benjamin Franz, from which I've also borrowed some functionalities
(caching and exception list).

=head1 METHODS

=over 4

=item stem({ -words => \@words, -locale => 'it', -exceptions => \%exceptions });

Stems a list of passed words. Returns an anonymous list reference to the stemmed 
words.

Example:

  my $stemmed_words = Lingua::Stem::It::stem({ -words => \@words,
                                               -locale => 'it',
                                               -exceptions => \%exceptions,
                          });

=item stem_word( $word );

Stems a single word and returns the stem directly.

Example:

  my $stem = Lingua::Stem::It::stem_word( $word );

=item stem_caching({ -level => 0|1|2 });

Sets the level of stem caching.

'0' means 'no caching'. This is the default level.

'1' means 'cache per run'. This caches stemming results during a single
    call to 'stem'.

'2' means 'cache indefinitely'. This caches stemming results until
    either the process exits or the 'clear_stem_cache' method is called.

=item clear_stem_cache;

Clears the cache of stemmed words

=back

=cut

=head2 EXPORT

None by default.

=head1 AUTHOR

Aldo Calpini, dada@perl.it

=head1 SEE ALSO

 Lingua::Stem

=head1 COPYRIGHT

Copyright (c) Aldo Calpini, dada@perl.it. All rights reserved.

This library is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut
