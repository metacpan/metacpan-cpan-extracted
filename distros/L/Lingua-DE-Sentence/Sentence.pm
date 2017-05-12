package Lingua::DE::Sentence;

require 5.005_62;
use strict;
use warnings;
use locale;

use POSIX qw(locale_h);
require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( get_sentences get_acronyms set_acronyms add_acronyms
		     get_file_extensions set_file_extensions add_file_extensions);

our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

our @EXPORT = qw(get_sentences);

our $VERSION = '0.07';

# will be filled with known german abbrevations
my %ABBREVIATIONS;
# will be filled with some known file extensions
my %FILE_EXTENSIONS;

# contains "real" consonant sounds
# sch, ch, st, ss, ... are spoken as one sound, that's way ?> and the alternation
# bb, dd, ... are not so often, but often used in acronyms
my $CONSONANT = qr/
    (?>ff|ll|sch|ch|st|ss|mm|nn|pp|rr|tt|ck|pf|
     [bcdfghklmnpqrstvwxz])/x;

# common vocals in german
my $VOCAL = qr/[aeouiäöü]/;

# the characters that can be between sentences  (chr(150) is a dash, chr(160) is a nonbreaking whitespace)
my $LEADING_SENTENCE_CHAR = '[\s'.chr(150).chr(160).'?!>\#\.\-\*]';

# regexp for new lines (even DOS, or MAC - Mode)
my $NL = qr/(?>\r\n|\n|\r)/;

# Characters which could be quotation marks (171 and 187 are << and >> as one character)
my $QUOTE = q{\"\'<>} . chr(171) . chr(187);

# Punctation marks
my $PUNCT = q{\.!?};

# Preloaded methods go here.

sub get_sentences {
    # Set german locale
    my $old_locale = setlocale(LC_CTYPE);
    setlocale(LC_CTYPE, "de_DE");

    my ($text) = @_;
    my @pos = ();
    my @sentences;
    my ($leading_chars,$sent,$rest);
    my $last_pos = 0;
    while ($text =~ m/ (?!\w)                      # Sentence-End not at word characters
	               (?:                         
                          # normal end of Sentence like .?!
	                  [$PUNCT]                 # End of Sentence could be a punctation
	                  (?![^\w\r\n]*[$PUNCT,])  # and not as the first of some punctations (incl. comma)
	                  [$QUOTE()]*              # possibly followed by a quotation mark or bracket
	                |
                          # or an empty line
	                  (?=\s\s)                 # so there must be at least two whitespaces 
	                  (?=\s*?$NL \s*?$NL)      # exact, two end of lines (perhaps with spaces)
			|
	                  \Z)/gsxo)                 # or end of file 
    {
	($leading_chars,$sent) 
	    = substr($text,$last_pos,-$last_pos+pos($text)) 
		=~ /^($LEADING_SENTENCE_CHAR*)(.*)$/s;
	$rest = substr($text,pos($text),100);
	
	# fix empty sentences
	# every sentence has to include anything
	$sent !~ m/\w/ && next;
	
        # check only special cases, if not at end of text or paragraph
	if ($rest =~ m/^(?!\s*?$NL\s*?$NL)\s*\S/so) {
	    
            # fix bla bla" sagte er.
	    # in general it's a word followed by " or ' and followed by a lowercase word	    
	    $sent =~ /[$QUOTE]$/o && $rest =~ m/^[$QUOTE()\s]*([[:lower:]])/o && next;
	    
	    # fix enumerations
	    $sent =~ /\W\.\.[$QUOTE\)]?$/o && $rest !~ /^(?:\s*$NL){2}/o && next;
	          
	    # Abbrevations
	    # these are lower-Case words of length 1 (in german always)
	    # or in Abbr.-List (ignoriers Lower/UpperCase)
	    # or consists of only consonants
	    # or ends too curious, that means 4 consonants at the end
	    if ($sent =~ /([^\W\d]+)\.[$QUOTE\)]*?$/o) {
		length($1) == 1 and next;
		$_ = lc($1);
		$ABBREVIATIONS{$_} and next;
		/^$CONSONANT+$/o and next;
		/^$VOCAL+$/o and next;
		/$CONSONANT{4,}$/o and next; 
	    }

	    # Ordinal-Numbers like 1., 2., ...
	    # I treat all numbers till 39 as ordinal
	    # plus the numbers ending on ..00
	    $sent =~ /\d\.$/ && $sent =~ /(?<![\w\.\,])(\d+)\.$/ &&
		(($1 < 40) || (($_ = $1) =~ /00$/ and $_ != 1900 and $_ != 2000 and $_ != 2100)) && next;

	    # Rational Numbers, IP-Numbers, Phonenumbers like 127.32.2345
	    $sent =~ /\.$/ && $rest =~ /^\d/ && next;

	    # Something like Domain-Adresses, URLs and so on
	    $sent =~ m{ (?=[hfnmg]) 
			(?:http|file|ftp|news|mailto|gopher) 
			:// 
                        [\w\d\.\%\_\/\:\-]+ 
                        (?<!\.) \.$ 
                      }xm 
		&& next;
	    $rest =~ /^([[:lower:]][[:lower:]\d]*[\.\?:\/]?)+/o  
		&& $sent =~ /([[:lower:]\d]+[\.\?:\/])+$/o && next;

	    # fix something like: Ich muss mich auf verschiedene (!) Browser einrichten.
	    $sent =~ / \(  [$QUOTE\.!?\)]+  $/xo && next;

	    # fix filenames like "document1.doc"
	    # look in extension list or extension consists of consonants
	    if ($sent =~ /\.$/ && $rest =~ /^(\w{1,4})\b/) {
		$FILE_EXTENSIONS{$_ = lc($1)} && next;
		/^$CONSONANT+$/o && next;
	    }
	}    
	$last_pos = pos($text);
	push @sentences, $sent;
	push @pos, [pos($text) - length($sent) => pos($text)] if wantarray;
    }
    return wantarray ? (\@sentences, \@pos) : \@sentences;

    setlocale(LC_CTYPE, $old_locale);
}

sub get_acronyms {
    return keys %ABBREVIATIONS;
}

sub set_acronyms {
    %ABBREVIATIONS = map {$_ => 1} @_;
}

sub add_acronyms {
    $ABBREVIATIONS{$_} = 1 foreach (@_);
}

sub get_file_extensions {
    return keys %FILE_EXTENSIONS;
}

sub set_file_extensions {
    %FILE_EXTENSIONS = map {$_ => 1} @_;
}

sub add_file_extensions {
    $FILE_EXTENSIONS{$_} = 1 foreach (@_);
}

sub BEGIN {
    $ABBREVIATIONS{$_} = 1 foreach qw(
				     abb
				     abf
				     abg
				     abk
				     abs
				     abschn
				     abt
				     accel
				     adr
				     ahd
				     akk
				     al
				     ala
				     alas
				     angekl
				     angew
				     anh
				     ank
				     anm
				     antw
				     anw
				     ao
				     apl
				     apr
				     ariz
				     ark
				     ass
				     aufl
				     aug
				     aussch
				     az
				     bat
				     batt
				     battr
				     bd
				     begr
				     beif
   				    beil
				     beisp
				     bem
				     bes
				     betr
				     bez
				     bf
				     bfn
				     bg
				     bgbl
				     bhf
				     bl
				     brosch
				     bsp
				     bspw
				     btl
				     btto
				     bttr
				     bz
				     bzw
				     ca
				     calif
				     cand
				     cf
				     co
				     col
				     colo
				     conn
				     cresc
				     crt
				     ct
				     cwt
				     dat
				     decbr
				     dd
				     decresc
				     del
				     delin
				     des
				     desgl
				     dez
				     dgl
				     di
				     dim
				     dipl
				     dir
				     diss
				     do
				     doz
				     dptr
				     dr
				     dres
				     dt
				     dto
				     dtzd
				     dz
				     ebd
				     ed
				     edd
				     eidg
				     eigtl
				     einschl
				     em
				     entw
				     erdg
				     erg
				     esq
				     etc
				     ev
				     evtl
				     ew
				     exc
				     excud
				     exkl
				     expl
				     exz
				     fa
				     febr
				     fec
				     ff
				     fl
				     fla
				     fol
				     fr
				     frdl
				     frhr
				     frl
				     fud
				     ga
				     gbl
				     geb
				     gebr
				     gef
				     gefl
				     gefr
				     gegr
				     geh
				     gen
				     geogr
				     gesch
				     gest
				     get
				     gez
				     ggf
				     gr
				     grad
				     grundlag
				     habil
				     hbf
                                     hd
				     hg
				     hl
				     hll
				     hptst
				     hr
				     hrn
				     hrsg
				     hs
				     hss
				     ia
				     ib
				     ibd
				     id
				     ide
				     idg
				     ill
				     imp
				     impr
				     i
				     ii
				     iii
				     in
				     inc
				     incl
				     ind
				     inf
				     ing
				     inkl
				     inv
				     io
				     ir
				     it
				     iv
				     ix
				     jan
				     jb
				     jg
				     jgg
				     jh
				     jr
				     jun
				     kan
				    kans
				     kap
				     kart
				     kath
				     ken
				     kffr
				     kfm
				     kgl
				     kl
				     koll
				    komp
				     konj
				     kop
				     kr
				     krs
				     kt
				    kto
				     kv
				     ky
				     la
				     led
				     leg
				     lfd
				     lic
				     lim
				     liq
				     lit
				    ln
				     lnbd
				     lt
				     ltd
				     ltn
				     lz
				     ma
				     mag
				     mass
				     math
				    md
				     mdal
				     mgr
				    mhd
				     mi
				     mia
				     mich
				    mill
				     min
				     mio
				     miss
				     mlat
				     mlle
				     mlles
				     mm
				     mme
				     mmes
				     mnd
				     mo
				     mod
				     mrd
				     msgr
				     mskr
				     mss
				     mwst
				     nachf
				     nachm
				     nchf
				     nd
				     nebr
				     nev
				     nhd
				     nlat
				     nm
				     no
				     nom
				     nov
				     nr
				     nrn
				     obd
				     oblt
				     od
				     oh
				     okla
				     okt
				     op
				     oreg
				     pa
				     pag
				     part
				     pf
				     pfd
				     pinx
				     pkt
				     pl
				     plur
				     pos
				     pp
				     ppa
				     ppbd
				     prakt
				     prim
				     prof
				     prot
				     prov
				     rd
				     rec
				     ref
				     reform
				     reg
				     regt
				     resp
				     rev
				     rf
				     rfz
				     rgt
				     rhld
				     rit
				     riten
				     rp
				     s
				     sa
				     sc
				     schw
				     scil
				     sculps
				     se
				     sek
				     sel
				     sen
				     sept
				     sfr
				     sign
				     sing
				     sog
				     sost
				     sp
				     spvg
				     spvgg
				     ss
				     st
				     sta
				     stacc
				     std
				     sto
				     str
				     string
				     stud
				     sva
				     svw
				     taf
				     techn
				     ten
				     tenn
				     tex
				     theor
				     tit
				     tsd
				     uffz
				     ult
				     urspr
				     usf
				     usw
				     ut
				     v
				     var
				     vdt
				     verh
				     verm
				     vert
				     verw
				     verz
				     vgl
				     vi
				     vii
				     viii
				     vm
				     vogtl
				     vorm
				     vors
				     vp
				     vs
				     wg
				     wis
				     wwe
				     wwr
				     x
				     xi
				     xii
				     xiii
				     xiv
				     xv
				     xvi
				     xvii
				     xviii
				     xix
				     xx
                                     zb
                                     zhd
				     ziff
				     zs
				     zschr
				     ztr
				     zz
				     zzt
				     );

    $FILE_EXTENSIONS{$_} = 1 foreach qw(doc html txt ps gz zip tar pdf gif jpeg mp3 bmp tmp exe com bat 
					pl java c cc vbs pod pm phtml shtml dhtml php);
}

__END__

=head1 NAME

Lingua::DE::Sentence - Perl extension for tokenizing german texts into their sentences.

=head1 SYNOPSIS
	    
    use Lingua::DE::Sentence;
    my $sentences = get_sentences($text);
    foreach (@$sentences) {
	print $nr++, "\t$_";
    }

    or

    use Lingua::DE::Sentence;
    my ($sentences, $positions) = get_sentences($text);
    for (my $i=0; $i < scalar(@$sentences); $i++) {
	print "\n", $nr++, "\t", 
	      $positions->[$i]->[0], "-", $positions->[$i]->[1], 
	      "\t", $sentences->[$i];
    }

=head1 DESCRIPTION

The C<Lingua::DE::Sentence> module contains the function get_sentences,
which splits text into its constituent sentences.
The result can be either the list of sentences in the text or 
the list of sentences plus and a list of their absolute positions in the text
It's based on a regular expression to find possible endings of sentences and
many little rules to avoid exceptions like acronyms or numbers.

There is a large list of known abbrevations and a not so large list of known file extensions,
which ones are used to differences acronyms and filenames from endings of sentences.
They can be extented or exchanged if needed.

=head2 EXPORT

C<get_sentences> by default.

You can further export the following methods:
C<get_sentences>, C<get_acronyms>, C<set_acronyms>, C<add_acronyms>, 
C<get_file_extensions>, C<set_file_extensions>, C<add_file_extensions>.

=head1 ALGORITHM

Basically, I use a "big" regular expression to find possible sentence endings.
This regular expression find punctations (.?!) or sequences of punctations like ?? or !?,
perhaps followed by quotationmarks or brackets like "'), but never by comma.
An empty line is interpreted as sentence end, too. Of course, the end of text also.

Then, found possibilities of sentence endings are checked for exceptions.
To do this, I take 2 substrings, the first from the last sentence endings to the momentan position,
the second starts at the momentan positions and has a length of 100 chars.
So I can test the environment without any slow substitution and without using $`, ... .
Before I check, I cut leading spaces, 
or any other stuff from the beginning of the sentence and throw it away.
I use some heuristics:

=over 8

=item Empty sentences

Sentences without any word character don't make any sense.

=item Enumerations

Something like 7 .. 24 or 1, 2, ....

=item Abbreviations

One letter plus dot is in german nearly always an acronym. 
Life ain't easy, in an earlier version I had implemented the following rule:
Every lowercase letter like a., b. or so is interpreted as such one.
Uppercase letters can be regular, e.g. "Spieler A schoss den Ball zu Spieler B.".
I decided me to treat I, X, V and S as acronyms (I, X, V are roman letters, S. stands for "Seite").
For the other uppercase letters, I look where I found them.
Only if they are found in a short sentence (less than 25 chars), so they are acronyms.
Well, that sounds strange, but it's a cool and a functional algorithm.
Of course, something like "S.u.S.e" or "z.B." is always an abbreviation.
But in Names there are no rules, e.g. J. Edgar Hoover or F. A. Lange.
So, now every one letter plus dot is an abbrevation for me.
I'll work for a solution what looks a little bit ahead.
If A. is followed by words like 'der', 'die', 'das', it's often really a sentence end.

Another form of abbreviations are known acronyms,
I've listed ca. 370 ones. I hope, that's enough for the most cases.

Last I look, wether the word before the dot ends with a lot of consonants.
Or the word has only consonants or only vocals as letters.
So I'm able, to interprete "Dtschl." in the right way.

=item Ordinal-Numbers

0., 1., 2., ..., 39. just look like 1st, 2nd, 3rd, ..., 39th.
In more than 50 % these are just 1st, 2nd and so on.
So a sentence cannot end on these numbers.
Of course, to say: "Ich wurde geboren im Jahre 1843." is O.K..
Numbers ending at 00 like 100, 1000, ... are even more often used as 100th, 1000th, ... .
Of course, 1900, 2000 and 2100 are year numbers, not 1900th.
I respected it, too.

=item Rational Numbers, IP-Numbers, Phone-Numbers

Something like 127.32.2345.0 or 123.5 is fixed.

=item URLs

URLs often contains dots and question marks.
What looks like a URL will be right interpreted.
For me, a URL is something starting with http, file, ftp, ... .
Or it's a sequence of lowercase words divided by some punctations.
Lowercase is important, because many guys don't write a whitespace after the dot.
But even they start their sentences with an uppercase word.

=item Punctations in brackets.

In german, it's usual to mark parts of a sentence with a "(!)", "(?)", or "(?!)", ...
E.g.: "Ich muss mich auf verschiedene (!) Browser einrichten."
An open bracket before a punctation signalizes that.

=item Filenames

In many documents are strings like "readme.html", "dokument1.doc" and so on.
I have a short list of usual file extensions.
If the word after the dot has only consonants (like html, ...),
it's a file extension (or anything else, strange) for me too.
I hope that it solves the problem.

=back

Allthough these are many rules, they are implemented to run fast.
There are no substitutions, no $`, ... .

=head1 FUNCTIONS

=over 7

=item get_sentences( $text )

The get sentences function takes a scalar containing ascii text as an argument.
In scalar context it returns a reference to an array of sentences that the text has been split into.
In list context it returns a list of a reference to an array of sentences and 
of a reference to an array of the absolute positions of the sentences.
Every positions is an array of two elements, 
the first is the start and the second is the ending of the sentence.
Calling the function in list context needs a little bit (ca. 5%) more time,
because of the extra amount for the position list.
Returned sentences are trimmed of white spaces and sensless beginnings.

=item get_acronyms(    )

This function will return the defined list for acronyms.

=item set_acronyms( @my_acronyms )

This function replaces the predefined acronym list with the given list.
Feel free to suggest me missing acronyms.

=item add_acronyms( @acronyms )

This function is used for adding acronyms not supported by this code.

=item get_file_extensions(    )

This function will return the defined list for file extensions.

=item set_file_extensions( @my_file_extensions )

This function replaces the predfined file extension list with the given list.
Feel free to suggest me missing file extensions.

=item add_file_extensions( @extensions )

This function is used for adding file extensions not supported by this code.

=back

=head1 BUGS

Sentences like 'Spieler A schoss den Ball zu Spieler B.' are misinterpreted.
B. is always an acronym.
Similary are sentences wich ends on small numbers.

Many abbreviations and file extensions still misses,
feel free to contact me.

If a sentence starts with the incorrect quotes >>quote<<,
the '>>' characters are removed.
It's not really a bug, it's a feature.
The module intends, that these are quotings from email like

  Andrea Holstein wrote:
  > ...
  > ...
  >
  >

You should use the right form of quoting: <<quote>>.

There are texts with such a form of quoting: ,,quote''.
Well, the commata are removed, too.

This module tries to use a german locale setting.
It tries to set the locale on a POSIX OS to de_DE.
Neither on a non POSIX OS, neither you have installed german language locales,
the module won't function.

One of the greatest bugs is surely my bad English. Sorry.

=head1 AUTHOR

Andrea Holstein E<lt>andrea_holsten@yahoo.deE<gt>

=head1 SEE ALSO

       Lingua::EN::Sentence
       Text::Sentence

=head1 COPYRIGHT

       Copyright (c) 2001 Andrea Holstein. All rights reserved.

       This library is free software.
       You can redistribute it and/or modify it under the same terms as Perl itself.

=cut
