package Lingua::Stem::Fr;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::Stem::Fr ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ();
our @EXPORT_OK = qw (stem stem_word clear_stem_cache stem_caching);
our @EXPORT = ();

our $VERSION = '0.02';


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
    my $locale     = 'fr';
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

	$word = lc $word;

	# Check against cache of stemmed words
	if ($Stem_Caching && exists $Stem_Cache->{$word}) {
		return $Stem_Cache->{$word}; 
	}

	our($RV, $R1, $R2);


	### u, i between vowels into upper case.
	$word =~ s/([aeiouyâàëéêèïîôûù])([ui])([aeiouyâàëéêèïîôûù])/$1.uc($2).$3/eg;

	### y preceded or followed by a vowel into upper case.
	$word =~ s/([aeiouyâàëéêèïîôûù])(y)/$1.uc($2)/eg;
	$word =~ s/(y)([aeiouyâàëéêèïîôûù])/uc($1).$2/eg;

	### u after q into upper case.
	$word =~ s/(q)(u)/$1.uc($2)/eg;

	#### RV is defined as follows 
	$RV = $word;

	#### If the first two letters are vowels
	if($word =~ /^[aeiouyâàëéêèïîôûù][aeiouyâàëéêèïîôûù]/) {

		#### RV is the region after the third letter
		unless ( $RV =~ s/^...// ) {
			$RV = "";
		}

	} elsif ( $word =~ /^.+?[aeiouyâàëéêèïîôûù].+/ ) {

			#### RV is after the first vowel not beginning or end the word
			$RV =~ s/^.+?[aeiouyâàëéêèïîôûù]//;

	} else {

			#### RV is the end of the word
			$RV = "";

	}

	#print "Word=$word\nRV=$RV\n";

	#### Defining R1 and R2
	$R1 = $word;

	#### R1 is the region after the first non-vowel following a 
	#### vowel, or is the null region at the end of the word if 
	#### there is no such non-vowel. 

	unless($R1 =~ s/^.*?[aeiouyâàëéêèïîôûù][^aeiouyâàëéêèïîôûù]//) {
		$R1 = "";
	}

	#print "R1=$R1\n";

	#### R2 is the region after the first non-vowel following a 
	#### vowel in R1, or is the null region at the end of the 
	#### word if there is no such non-vowel. 

	$R2 = $R1;

	if($R2) {
		unless($R2 =~ s/^.*?[aeiouyâàëéêèïîôûù][^aeiouyâàëéêèïîôûù]//) {
			$R2 = "";
		}
	}

	#print "R2=$R2\n";

	#### Step 1: Standard suffix removal 

	my $step1 = 0;

	#### Search for the longest among the following suffixes, 
	#### and perform the action indicated
	
	my @suffix = qw(
		ance   iqUe   isme
		able   iste   eux
		ances   iqUes   ismes
		ables   istes
	);

	#### delete if in R2 
	$step1 += stem_killer( $R2, "", "", @suffix );

	@suffix = qw(
		trice   ateur   ation
		atrices   ateurs   ations
	);

	#### delete if in R2 
	#### if preceded by ic, delete if in R2 
	#print "Word=$word RV=$RV R1=$R1 R2=$R2\n";
	$step1 += stem_killer( $R2, "ic", "",    @suffix )
		   || stem_killer( $R1, "ic", "iqU", @suffix )
		   || stem_killer( $R2, "",   "",    @suffix );


	@suffix = qw(
		logie   logies
	);

	#### replace with log if in R2 
	$step1 += stem_killer( $R2, "", "log", @suffix );

	@suffix = qw(
		usion   ution   usions   utions
	);

	#### replace with u if in R2 
	$step1 += stem_killer( $R2, "", "u", @suffix );

	@suffix = qw(
		ence   ences
	);

	#### replace with ent if in R2 
	$step1 += stem_killer( $R2, "", "ent", @suffix );

	@suffix = qw(
		issement   issements
	);

	#### delete if in R1 and preceded by a non-vowel
	if ( nvprec( $R1, @suffix ) ) {
		$step1 += stem_killer( $R1, "", "",    @suffix);
	}

	@suffix = qw(
		ement   ements
	);

	#### delete if in RV 
	#### if preceded by iv, delete if in R2 
	#### (and if further preceded by at, delete if in R2), otherwise, 
	#### if preceded by eus, delete if in R2, else replace by eux if in R1, otherwise, 
	#### if preceded by abl or iqU, delete if in R2, otherwise, 
	#### if preceded by ièr or Ièr, replace by i if in RV 
	$step1 += stem_killer( $RV, "ativ",      "",    @suffix )
		   || stem_killer( $R2, "iv",        "",    @suffix )
		   || stem_killer( $R2, "(abl|iqU)", "",    @suffix )
		   || stem_killer( $R2, "(ièr|Ièr)", "i",   @suffix )
		   || stem_killer( $R2, "eus",       "",    @suffix )
		   || stem_killer( $R1, "eus",       "eux", @suffix )
		   || stem_killer( $RV, "",          "",    @suffix );

	@suffix = qw(
		ité   ités
	);

	#### delete if in R2 
	#### if preceded by abil, delete if in R2, else replace by abl, otherwise, 
	#### if preceded by ic, delete if in R2, else replace by iqU, otherwise, 
	#### if preceded by iv, delete if in R2 
	$step1 += stem_killer( $R2,   "(abil|ic|iv)",  "",    @suffix )
		   || stem_killer( $word, "abil",          "abl", @suffix )
		   || stem_killer( $word, "ic",            "iqU", @suffix )
		   || stem_killer( $R2,   "",              "",    @suffix );


	@suffix = qw(
		if   ive   ifs   ives
	);

	#### delete if in R2 
	#### if preceded by at, delete if in R2 
	#### (and if further preceded by ic, delete if in R2, else replace by iqU)
	$step1 += stem_killer( $R2,   "icat", "",    @suffix)
		   || stem_killer( $R2,   "at",   "",    @suffix)
		   || stem_killer( $word, "icat", "iqU", @suffix)
		   || stem_killer( $R2,   "",     "",    @suffix);

	@suffix = qw(
		eaux
	);

	#### replace with eau
	$step1 += stem_killer( $word, "", "eau", @suffix);

	@suffix = qw(
		aux
	);

	#### replace with eau
	$step1 += stem_killer( $R1, "", "al", @suffix);

	@suffix = qw(
		euse   euses
	);

	#### delete if in R2, else replace by eux if in R1 
	$step1 += stem_killer( $R2, "", "",    @suffix)
		   || stem_killer( $R1, "", "eux", @suffix);

	@suffix = qw(
		emment
	);

	#### replace with ent
	my $sufstep2 += stem_killer( $RV, "", "ent",    @suffix);

	@suffix = qw(
		amment
	);

	#### replace with ant
	$sufstep2 += stem_killer( $RV, "", "ant",    @suffix);


	@suffix = qw(
		ment   ments
	);

	#### delete if preceded by a vowel in RV
	if ( vprec ( $RV, @suffix) ) {
		$sufstep2 += stem_killer( $RV, "", "",    @suffix);
	}



	#### Step 2: Verb suffixes 

	#### Do step 2a if no ending was removed by step 1. 
	my $step2a = 0;
	if( ($step1 == 0) || ($sufstep2 > 0) ) {

		#### Search for the longest among the following suffixes in RV, 
		#### and if found, delete. 
		@suffix = qw(
			îmes   ît   îtes   i   ie   ies   ir   ira
			irai   iraIent   irais   irait   iras   irent
			irez   iriez   irions   irons   iront   is   issaIent
			issais   issait   issant   issante   issantes
			issants   isse   issent   isses   issez   issiez
			issions   issons   it
		);
		if ( nvprec( $RV, @suffix) ) {
			#print "word:$word RV:$RV R1:$R1 R2:$R2\n";
			$step2a += stem_killer( $RV, "", "", @suffix );
		}
	}

	my $step2b = 0;
	if ( $step2a == 0 ) {

		@suffix = qw(
			ions
		);

		#### delete if in R2 
		$step2b += stem_killer( $R2, "", "",    @suffix);

		@suffix = qw(
			é   ée   ées   és   èrent   er   era   erai
			eraIent   erais   erait   eras   erez   eriez
			erions   erons   eront   ez   iez
		);

		#### delete
		$step2b += stem_killer( $RV, "", "",    @suffix);

		#print "Avant word:$word RV:$RV R1:$R1 R2:$R2\n";
		@suffix = qw(
			âmes   ât   âtes   a   ai   aIent   ais   ait
			ant   ante   antes   ants   as   asse   assent
			asses   assiez   assions
		);

		#### delete 
		#### if preceded by e, delete
		$step2b += stem_killer( $RV, "e", "",    @suffix)
			    || stem_killer( $RV, "",  "",    @suffix);
		#print "Apres word:$word RV:$RV R1:$R1 R2:$R2\n";

	}


	my $step4 = 1;
	if ( $step1 > 0 || $step2a > 0 || $step2b > 0 ) {
		#### Step 3
		#### Replace final Y with i or final ç with c
		if ( $word =~ /Y$|ç$/ ) {
			$word =~ s/Y$/i/;
			$word =~ s/ç$/c/;
			$step4 = 0;
		}
	}

	if ( $step4 == 1 && $step1 == 0 && $step2a == 0 && $step2b == 0 ) {
		#### Step 4
		#### If the word ends s, not preceded by a, i, o, u, è or s, delete it. 
		#print "word:$word RV:$RV\n";
		if ( $word =~ /[^aiouès]s$/ ) {
			stem_killer( $word , "", "", "s" );
		}

		@suffix = qw(
			ent
		);

		#### delete if in R2
		stem_killer( $R2, "", "",    @suffix);

		@suffix = qw(
			ion
		);

		#### delete if in R2 and preceded by s or t
		if ( $R2 =~ /ion$/ && $RV =~ /tion|sion/ ) {
			stem_killer( $R2, "", "",    @suffix);
		}

	     #(So note that ion is removed only when it is in R2 - as well as being in RV - and preceded by s or t which must be in RV.) 


		@suffix = qw(
			ier   ière   Ier   Ière
		);

		#### replace with i
		stem_killer( $RV, "", "i",    @suffix);

		@suffix = qw(
			e
		);

		#### e delete
		#print "word:$word RV:$RV R1:$R1 R2:$R2\n";
		stem_killer( $RV, "", "",    @suffix);

		@suffix = qw(
			ë
		);

		#### if preceded by gu, delete
		if ( $RV =~ /guë$/ ) {
			stem_killer( $RV, "", "",    @suffix);
		}
	}

	#### Always do Step 5 and Step 6
	#### step 5 : Undouble
	####  If the word ends enn, onn, ett, ell or eill, delete the last letter
	$word =~ s/enn$/en/;
	$word =~ s/onn$/on/;
	$word =~ s/ett$/et/;
	$word =~ s/ell$/el/;
	$word =~ s/eill$/eil/;

	#### step 6 :Un-accent
	#### If the words ends é or è followed by at least one non-vowel,
	#### remove the accent from the e
	$word =~ s/[éè]([^aeiouyâàëéêèïîôûù]+?)$/e$1/;

	#### And finally:
	#### Turn any remaining I, U and Y letters into lower case. 
	$word =~ s/([IUY])/lc($1)/eg;

	return $word;

}

sub nvprec {

	my($where, @list) = @_;
	use vars qw($RV $R1 $R2 $word);
	foreach my $p ( sort { length($b) <=> length($a) } @list) {
		if ($where =~ /[^aeiouyâàëéêèïîôûù]$p$/) {
			return 1;
		}
	}
	return;
}

sub vprec {

	my($where, @list) = @_;
	use vars qw($RV $R1 $R2 $word);
	foreach my $p ( sort { length($b) <=> length($a) } @list) {
		if ($where =~ /[aeiouyâàëéêèïîôûù]$p$/) {
			return 1;
		}
	}
	return;
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

Lingua::Stem::Fr - Perl French Stemming

=head1 SYNOPSIS

    use Lingua::Stem::Fr;

    my $stems = Lingua::Stem::Fr::stem({ -words => $word_list_reference,
                                         -locale => 'fr',
                                         -exceptions => $exceptions_hash,
                                      });

    my $stem = Lingua::Stem::Fr::stem_word( $word );


=head1 DESCRIPTION

This module use the a modified version of the Porter Stemming Algorithm to return a stemmed words.

The algorithm is implemented as described in:

http://snowball.tartarus.org/french/stemmer.html

with some improvement.

The code is carefully crafted to work in conjunction with the L<Lingua::Stem>
module by Benjamin Franz.
This french version is based too, on the work of Aldo Calpini (Italian Version)

=head1 METHODS

=over 4

=item

stem({ -words => \@words, -locale => 'fr', -exceptions => \%exceptions });                                                                                
Stems a list of passed words. Returns an anonymous list reference to the stemmed
words.

Example:

    my $stemmed_words = Lingua::Stem::Fr::stem({ -words => \@words,
                                                 -locale => 'fr',
                                                 -exceptions => \%exceptions,
                                              });

=item stem_word( $word );

Stems a single word and returns the stem directly.

Example:

    my $stem = Lingua::Stem::Fr::stem_word( $word );

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


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options

  -ACX
	-n
	Lingua::Stem::Fr

=item 0.02

Minor change in documentation and disable of limitation to perl 5.8.3+

=back

=head1 SEE ALSO

You can see the French stemming algorithm from Mr Porter here :

http://snowball.tartarus.org/french/stemmer.html


Another French stemming tool in Perl (French page) :

http://www.univ-nancy2.fr/pers/namer/Telecharger_Flemm.html

=head1 AUTHOR

Sébastien Darribere-Pleyt, E<lt>sebastien.darribere@lefute.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Aldo Calpini <dada@perl.it>

Copyright (C) 2004 by Sébastien Darribere-Pleyt <sebastien.darribere@lefute.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
