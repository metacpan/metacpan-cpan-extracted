
package Lingua::EN::Conjugate;

use Data::Dumper;
require Exporter;

@ISA = qw( Exporter );

@EXPORT_OK = qw(
  conjugate
  conjugations
  participle
  past
  gerund
  s_form
  @tenses
  @pron
  %irreg
  %no_double
);

use warnings;
use strict;
#use diagnostics;

use Lingua::EN::Contraction qw(contract_n_t contract_other);


if (eval "use Memoize") {
memoize('stem');
memoize('participle');
memoize('past');
memoize('gerund');
memoize('s_form');
}

use vars qw(
  $VERSION
  %irreg
  @pron
  @tenses
  %conj
  %no_double
  %tense_patterns

);

$VERSION = '0.311';
@pron    = qw(I you we he she it they);


our @modal = qw(may might must be being been am are is was were do does did should could would have has had will can shall);



our $modal_re = '\b(?:' . join("|", @modal) . ')';
$modal_re = qr/$modal_re/i;
our $pronoun_re = '\b(?:' . join("|", @pron) . ')\b';
$pronoun_re = qr/$pronoun_re/i;



@tenses = qw (
	present		present_prog
	past		past_prog
	past_prog	used_to
	perfect		past_perfect
	perfect_prog	past_perfect_prog
	modal		modal_prog
	modal_perf_prog	conjunctive_present
	imperative
);

%tense_patterns = (
 
	ACTIVE => {
    #	TENSE		STATEMENT		QUESTION
    present      => [ '@ PRESENT *',           	'PRESENT @ *' ],
    present_do   => [ '@ DO * INF',     	'DO @ * INF' ],
    present_prog => [ '@ BE * GERUND',  	'BE @ * GERUND' ],
    past         => [ '@ PAST *',              	'PAST @ *' ],
    past_do      => [ '@ did * INF',    	'did @ * INF' ],
    past_prog    => [ '@ WAS * GERUND', 	'WAS @ * GERUND' ],
    used_to      => [ '@ used to * INF',     	'N/A' ],
    perfect      => [ '@ HAVE * PART',  	'HAVE @ * PART' ],
    past_perfect => [ '@ had * PART',   	'had @ * PART' ],
    perfect_prog => [ '@ HAVE * been GERUND', 	'HAVE @ * been GERUND' ],
    past_perfect_prog =>
                    [ '@ had * been GERUND', 	'had @ * been GERUND' ],
    modal      =>   [ '@ MODAL * INF',       	'MODAL @ * INF' ],
    modal_prog =>   [ '@ MODAL * be GERUND', 	'MODAL @ * be GERUND' ],
    modal_perf =>   [ '@ MODAL * have PART', 	'MODAL @ * have PART' ],
    modal_perf_prog =>
                    [ '@ MODAL * have been GERUND', 'MODAL @ * have been GERUND' ],
    conjunctive_present => [ '@ INF',    	'N/A' ],
    imperative          => [ 'IMPERATIVE', 	'N/A' ] },
	
	PASSIVE => {
    present      => [ '@ BE * PART',           	'BE @ * PART' ],
    present_prog => [ '@ BE * being PART',      'BE @ * being PART' ],
    past         => [ '@ WAS * PART',           'WAS @ * PART' ],
    past_prog    => [ '@ WAS * being PART',     'WAS @ * being PART' ],
    perfect      => [ '@ HAVE * been PART',  	'HAVE @ * been PART' ],
    past_perfect => [ '@ had * been PART',   	'had @ * been PART' ],
    modal      =>   [ '@ MODAL * be PART',      'MODAL @ * be PART' ],
    modal_perf =>   [ '@ MODAL * have been PART', 'MODAL @ * have been PART' ]
	}
      #  				@ = pronoun, * = not
);

%irreg = _irreg();


$no_double{$_} = 1 for _no_double();




sub conjugate {

    my %params = @_;

   #parameters:
    our ($inf, $modal, $passive, $allow_contractions, $question, $negation, $no_pronoun);

   #forms of the verb determined by "init_verb":
    #our ($part, $past, $gerund, $s_form,);

    $inf =
      defined $params{verb} ? $params{verb} : warn "must define a verb!!\n",
      return undef;
    $inf =~ s/^ *| *$//g;
    $inf =~ s/  *//g;

    $modal = defined $params{modal} ? $params{modal} : 'will';
    $passive = defined $params{passive} ? $params{passive} : undef;
    $allow_contractions = defined $params{allow_contractions}? $params{allow_contractions}: undef;
    $no_pronoun = defined $params{no_pronoun}? $params{no_pronoun} : undef;


    unless ( $modal =~ $modal_re ) {
        warn "$modal is not a modal verb!!\n";
        return 0;
    }

    $question = defined $params{question} ? $params{question} : 0;
    $negation = defined $params{negation} ? $params{negation} : undef;

   # ( $part, $past, $gerund, $s_form ) = init_verb($inf);

    if (   ref $params{pronoun}
        or ref $params{tense}
        or !defined $params{pronoun}
        or !defined $params{tense} )
    {
        my $ret = {};
        my @t =
            ref $params{tense}     ? @{ $params{tense} }
          : defined $params{tense} ? $params{tense}
          :                          @tenses;

        for my $t (@t) {

            my @p =
              ref $params{pronoun} ? grep { defined _conj($inf, $t, $_ ) }
              @{ $params{pronoun} }
              : defined $params{pronoun} ? $params{pronoun}
              :   grep { defined _conj( $inf, $t, $_ ) } @pron;

            for my $p (@p) {
                next unless defined _conj($inf, $t, $p );
                $ret->{$t}{$p} = _conj($inf, $t, $p );
            }
        }

        if (wantarray) {
            my @return = ();
            for my $t ( keys %{$ret} ) {
                for my $p ( keys %{ $ret->{$t} } ) {

                    push @return, $ret->{$t}{$p};
                }
            }
            return @return;
        }
        else { return $ret }
    }

    return _conj($inf, $params{tense}, $params{pronoun} );


sub _conj {

        my ( $inf, $tense, $pronoun ) = @_;
	my $part = participle($inf);
	my $past = past($inf);
	my $gerund = gerund($inf);
	my $s_form = s_form($inf);


        # special cases...
        if ( match_any( $inf, qw(should could would can shall will may might must))) {
		return undef unless $tense eq 'present';
	}
	if ( $inf !~ $modal_re ) {
        if ( $tense eq 'present' and (defined $negation or $question) and not defined $passive) {
            $tense = 'present_do';
        }
        if ( $tense eq 'past' and (defined $negation or $question) and not defined $passive) {
	    $tense = 'past_do'; 
	}
	}

	if ( $tense eq 'conjunctive_present' and defined $negation ) {
		return undef;
	
	}

	my $active_passive = $passive ? 'PASSIVE' : 'ACTIVE';

        my $pattern = $tense_patterns{$active_passive}{$tense}[$question] or return undef;

	if ($no_pronoun) { 
		$pattern =~ s/^\@ //;
	}
	
        $pattern =~ s/\@/$pronoun/;
	

        if ( $pattern eq 'N/A' ) { return undef; }
        $pattern =~ s/DO/DO($pronoun)/e;
        $pattern =~ s/WAS/WAS($pronoun)/e;
        $pattern =~ s/HAVE/HAVE($pronoun)/e;
        $pattern =~ s/MODAL/$modal/;
        $pattern =~ s/BE/BE($pronoun)/e;
        $pattern =~ s/GERUND/$gerund/;
        $pattern =~ s/PART/$part/;
        if ( $pattern =~ /PRESENT/ ) {
            my $p = PRESENT( $inf, $s_form, $pronoun ) or return undef;
            $pattern =~ s/PRESENT/$p/;
        }
        elsif ( $pattern =~ /IMPERATIVE/ ) {
            my $i = IMPERATIVE( $inf, $negation, $pronoun ) or return undef;
            $pattern =~ s/IMPERATIVE/$i/;
        }
        elsif ( $pattern =~ /PAST/ ) {
          
	    my $p = $inf =~ /^be$/ ? WAS($pronoun) : $past ;
            $pattern =~ s/PAST/$p/;
        }
        elsif ( $pattern =~ /INF/ ) {
            return undef unless defined $inf;
            $pattern =~ s/INF/$inf/;
        }

        if ($negation) {
            $pattern =~ s/\*/not/;
	    if ($negation eq 'n_t') {
		$pattern = contract_n_t($pattern);
	    }
        }
	else {
		$pattern =~ s/ ?\*( ?)/$1/;
	}

	if ($allow_contractions) {
	   $pattern = contract_other($pattern);
	}

        return $pattern;

}


sub IMPERATIVE {
    my $inf      = shift;
    my $negation = shift;
    my $pronoun  = shift;

    if ( $pronoun =~ /we/i ) {
        my $retval = "let us";
        if ( defined $negation ) {
		$retval .= " not";
	}
        $retval .= " $inf";
	return $retval;
    }
    elsif ( $pronoun =~ /you/i ) {
        if ( $negation ) {
            return "do not $inf";
        }
        else {
            return "$inf";
        }
    }
    else {
        return undef;
    }
}

}
sub match_any {
	my $a = shift;
	my @b = @_;
	for (@b) { return 1 if $a =~ /\b$_\b/i ; }
	return undef;
}


sub PRESENT {
    my $inf     = shift;
    my $s_form  = shift;
    my $pronoun = shift;

    if ( $inf =~ /^be$/i )   { return BE($pronoun); }
    if ( $inf =~ /^have$/i ) { return HAVE($pronoun); }
    if (defined $s_form and match_any($pronoun, qw(he she it))) { return $s_form; }
 
    return $inf;
}


sub BE {
    my $pronoun = shift;
    if ( $pronoun eq 'I' ) { return 'am' }

 if (match_any($pronoun, qw(he she it))) { return 'is'; }

    return 'are';
}

sub WAS {
    my $pronoun = shift;
 if (match_any($pronoun, qw(I he she it))) { return 'was'; }

    return 'were';
}

sub HAVE {
    my $pronoun = shift;
 if (match_any($pronoun, qw(he she it))) { return 'has'; }
    return 'have';
}

sub DO {
    my $pronoun = shift;
 if (match_any($pronoun, qw(he she it))) { return 'does'; }
    return 'do';
}

sub conjugations {

    my ( $tense, $pronoun, $result, @_tenses );

    my %params = @_;

    my @pnouns = defined $params{pronoun} ? 
		 (ref $params{pronoun}? @{ $params{pronoun} } : $params{pronoun}) 
		: qw(I you he we they);

    my $conjugs = conjugate(@_);

    @_tenses = grep { defined $conjugs->{$_} } @tenses;

    $result = "";
    foreach ( $tense = 0 ; $tense <= $#_tenses ; $tense += 2 ) {
        my $t1 = $_tenses[$tense];
        my $t2 = $tense < scalar @_tenses ? $_tenses[ $tense + 1 ] : undef;
        $result .= centered( uc( $_tenses[$tense] ),       35, "-" );
        $result .= " ";
        $result .= centered( uc( $_tenses[ $tense + 1 ] ), 35, "-" )
          if defined $t2;
        $result .= "\n";
        for $pronoun (@pnouns) {
            my $s1 =
              defined $conjugs->{$t1}{$pronoun}
              ? $conjugs->{$t1}{$pronoun}
              : '';
            my $s2 =
                 defined $t2
              && defined $conjugs->{$t2}{$pronoun}
              ? $conjugs->{$t2}{$pronoun}
              : '';
            $result .= sprintf "%-35s %-35s\n", $s1, $s2;

        }
    }
    return $result;

    sub centered {
        my ( $string, $len, $fill ) = @_;
        $fill = " " unless defined $fill;
        my $result = $fill x ( ( $len - length($string) ) / 2 - 1 );
        $result .= " ";
        $result .= $string;
        $result .= " ";
        $result .= $fill x ( $len - length($result) );
        return $result;
    }
}




sub stem {

    my $inf = shift;
    my $stem = $inf;

    if ( $stem =~ /[bcdfghjklmnpqrstvwxyz][aeiou][bcdfghjklmnpqrstv]$/ ) {

       #if the word ends in CVC pattern (but final consonant is not w,x,y, or z)
       # and if the stress is not on the penultimate syllable, then double
       # the final consonant.
       #
       # The stop list (stored in %no_double) is a list of words ending in CVC, with the stress
       # on the penultimate syllable such as visit, happen, enter, etc.

        $stem =~ s/(\w)$/$1$1/ unless $no_double{$stem};

    }
    return $stem;
}

sub participle {

	my $inf = shift;
	return $irreg{$inf}{part} if defined $irreg{$inf};

	my $stem = stem($inf);

    my $part = $stem . 'ed';
    $part =~ s/([bcdfghjklmnpqrstvwxyz])eed$/$1ed/;
    $part =~ s/([bcdfghjklmnpqrstvwxyz])yed$/$1ied/;
    $part =~ s/eed$/ed/;


	return $part;

}

sub past {

	my $inf = shift;
	return $irreg{$inf}{past} if defined $irreg{$inf};
	return participle($inf);
}

sub gerund {

	my $inf = shift;
	my $stem = stem($inf);


    my $gerund = $stem . 'ing';
    $gerund =~ s/(.[bcdfghjklmnpqrstvwxyz])eing$/$1ing/;
    $gerund =~ s/ieing$/ying/;
	return $gerund;

}

sub s_form {

	my $inf = shift;
	my $s_form;
#may might must be being been am are is was were do does did should could would have has had will can shall
       if ( $inf eq 'be') { $s_form = 'is'; }
    elsif ( $inf eq 'do') { $s_form = 'does'; }
    elsif ( $inf eq 'have') { $s_form = 'has'; }
    elsif ( $inf =~ $modal_re ) { $s_form = $inf; }

    elsif ( $inf =~ /[ho]$|ss$/ ) {
        $s_form = $inf . "es";
    }
    elsif ( $inf =~ /[bcdfghjklmnpqrstvwxyz]y$/ ) {
	$s_form = $inf;
        $s_form =~ s/y$/ies/;
    }

    else {
        $s_form = $inf . "s";
    }

    return $s_form;

}


1;

=head1 NAME

Lingua::EN::Conjugate - Conjugation of English verbs

=head1 SYNOPSIS

	use Lingua::EN::Conjugate qw( conjugate conjugations contraction);
	

	print conjugate( 'verb'=>'look', 
				'tense'=>'perfect_prog', 
				'pronoun'=>'he',
				'negation'=>'not' );  
 
			# "he was not looking"


	my $go = conjugate( 'verb'=>'go', 
				'tense'=>[qw(past modal_perf)], 
				'modal'=>'might') ; 
				
			# returns a hashref  
   
	print $go->{modal_perf}{I};   # "I might have gone"
			 	


	my @be = conjugate( 'verb'=>'be', 
				'pronoun'=>[qw(I we)], 
				'tense'=>'past_prog',
				'negation'=>'n_t' );

			# returns an array
	print $be[0];   # "I wasn't going"


	#pretty printed table of conjugations

	print conjugations( 'verb'=>'walk', 
				'question'=>1, 
				'allow_contractions'=>1, 
				'modal'=>'should', 
				'negation'=>'n_t');
 ------------- PRESENT ------------- ---------- PRESENT_PROG -----------
 don't I walk                        am I not walking
 don't you walk                      aren't you walking
 doesn't he walk                     isn't he walking
 don't we walk                       aren't we walking
 don't they walk                     aren't they walking
 -------------- PAST --------------- ------------ PAST_PROG ------------
 didn't I walk                       wasn't I walking
 didn't you walk                     weren't you walking
 didn't he walk                      wasn't he walking
 didn't we walk                      weren't we walking
 didn't they walk                    weren't they walking
 ----------- PRESENT_DO ------------ ------------- PAST_DO -------------
 don't I walk                        didn't I walk
 don't you walk                      didn't you walk
 doesn't he walk                     didn't he walk
 don't we walk                       didn't we walk
 don't they walk                     didn't they walk
 ------------ PAST_PROG ------------ ------------- PERFECT -------------
 wasn't I walking                    haven't I walked
 weren't you walking                 haven't you walked
 wasn't he walking                   hasn't he walked
 weren't we walking                  haven't we walked
 weren't they walking                haven't they walked
 ---------- PAST_PERFECT ----------- ---------- PERFECT_PROG -----------
 hadn't I walked                     haven't I been walking
 hadn't you walked                   haven't you been walking
 hadn't he walked                    hasn't he been walking
 hadn't we walked                    haven't we been walking
 hadn't they walked                  haven't they been walking
 -------- PAST_PERFECT_PROG -------- -------------- MODAL --------------
 hadn't I been walking               shouldn't I walk
 hadn't you been walking             shouldn't you walk
 hadn't he been walking              shouldn't he walk
 hadn't we been walking              shouldn't we walk
 hadn't they been walking            shouldn't they walk
 -------------- MODAL -------------- --------- MODAL_PERF_PROG ---------
 shouldn't I walk                    shouldn't I have been walking
 shouldn't you walk                  shouldn't you have been walking
 shouldn't he walk                   shouldn't he have been walking
 shouldn't we walk                   shouldn't we have been walking
 shouldn't they walk                 shouldn't they have been walking





=head1 DESCRIPTION

This module constructs various verb tenses in English.  

Thanks to Susan Jones for the list of irregular verbs and an explanation of English verb tenses L<http://www2.gsu.edu/~wwwesl/egw/grlists.htm>.

=over

=item past($infinitive)

past tense form of the verb: "go" -> "went"

=item participle($infinitive)

past participle form of the verb: "go" -> "gone"

=item gerund($infinitive)

"-ing" form of the verb: "go" -> "going"

=item s_form($infinitive)

third person singular form of the verb: "go" -> "goes"

=item conjugate('verb'=> 'go' , OPTIONS)

In scalar context with tense and pronoun defined as scalars, only one conjugation is returned.

In scalar context with tense and pronoun undefined or defined as array refs, a hashref keyed by tense and pronoun is returned.

In array context, it returns an array of conjugated forms ordered by tense, then pronoun.


=item verb

'verb'=>'coagulate'

The only required parameter.  The verb should be in its infinitive form (no "is", "was" etc.) and without a "to" tacked on the front.

=item tense

 'tense'=>'past'
 'tense'=>['modal_perf', 'used_to']

If no 'tense' argument is supplied, all applicable tenses are returned.  

=item passive

 'passive' => 1
 'passive' => undef (default)

If specified, the passive voice is used.  Some tenses, such as Imperiative, are disabled when the passive option is used.


=item pronoun

 'pronoun'=>'he'
 'pronoun'=>[qw(I we you)]

If no 'pronoun' argument is supplied, all applicable pronouns are returned.

=item question

 'question' => 1
 'question' => 0  (default)

In case you're playing Jeapordy

=item negation

 'negation'=> 'not'
 'negation'=> 'n_t'
 'negation'=> undef  (default)

Changes "do" to "do not" or "don't" depending on which value you request.
For words where you can't use "n't" (like "am") or where it feels clumsy or antique (like "may"), 
this will substitute "not" for "n_t" as appropriate. 

=item modal

 'modal' => one of: may, might, must, should, could, would, will (default), can, shall.

Specifies what modal verb to use for the modal tenses.


L<http://www.kyrene.k12.az.us/schools/brisas/sunda/verb/1help.htm> 

=item allow_contractions

  'allow_contractions'=>1  allows "I am"->"I'm", "they are"->"they're" and so on
  'allow_contractions'=>0  (default)

The negation rule above is applied before the allow_contractions rule is checked:

	allow_contractions =>1, negation=>n_t : "he isn't walking"; 
	allow_contractions =>0, negation=>n_t : "he isn't walking";
	allow_contractions =>1, negation=>not : "he's not walking";
	allow_contractions =>0, negation=>not " "he is not walking";


=item conjugations()
  
   returns a pretty-printed table of conjugations.  (code stolen from L<Lingua::IT::Conjugate>)

=back

=head2 EXPORT

None by default. You can export the following functions and variables:

	conjugate
        conjugations
	past
	participle
	gerund
	s_form
	@tenses
	@pronouns

=head1 BUGS

=head1 TODO

 HAVE TO + Verb
 HAVE GOT TO + Verb
 BE ABLE TO + Verb
 OUGHT TO + Verb
 BE SUPPOSED TO + Verb

=head1 AUTHOR

Russ Graham, russgraham@gmail.com

=head1 SEE ALSO

=over

=item

L<Lingua::IT::Conjugate>

=item

L<Lingua::PT::Conjugate>

=item

L<Lingua::EN::Contraction>

=back

=cut

sub _irreg {
    my %irreg;    for (split /\n/, _irreg_data()) {
	    next unless /\w/;
	    my ( $verb, $simp, $part ) = split /-/, $_;
	    $verb =~ s/\(.*//;
	    $simp =~ s/\/.*//;
	    $part =~ s/\/.*//;
	    ( $verb, $simp, $part ) =
	      map { s/^\s*|\s*$//g; $_ } ( $verb, $simp, $part );
	    $irreg{$verb} = { past => $simp, part => $part };
    }


	return %irreg;
    #print "$verb, $simp, $part\n";

}

sub _irreg_data {
return <<EOF;
awake - awoke - awoken
be - was, were - been
bear - bore - born
beat - beat - beat
become - became - become
begin - began - begun
bend - bent - bent
beset - beset - beset
bet - bet - bet
bid - bid/bade - bid/bidden
bind - bound - bound
bite - bit - bitten
bleed - bled - bled
blow - blew - blown
break - broke - broken
breed - bred - bred
bring - brought - brought
broadcast - broadcast - broadcast
build - built - built
burn - burned/burnt - burned/burnt
burst - burst - burst
buy - bought - bought
cast - cast - cast
catch - caught - caught
choose - chose - chosen
cling - clung - clung
come - came - come
cost - cost - cost
creep - crept - crept
cut - cut - cut
deal - dealt - dealt
dig - dug - dug
dive - dove/dived - dived
do - did - done
draw - drew - drawn
dream - dreamed/dreamt - dreamed/dreamt
drive - drove - driven
drink - drank - drunk
dye - dyed - dyed
eat - ate - eaten
fall - fell - fallen
feed - fed - fed
feel - felt - felt
fight - fought - fought
find - found - found
fit - fit - fit
flee - fled - fled
fling - flung - flung
fly - flew - flown
forbid - forbade - forbidden
forget - forgot - forgotten
forego - forewent - foregone
forgo - forwent - forgone
forgive - forgave - forgiven
forsake - forsook - forsaken
freeze - froze - frozen
get - got - gotten
give - gave - given
go - went - gone
grind - ground - ground
grow - grew - grown
hang - hung - hung
have - had - had
hear - heard - heard
hide - hid - hidden
hit - hit - hit
hold - held - held
hurt - hurt - hurt
keep - kept - kept
kneel - knelt - knelt
knit - knit - knit
know - knew - know
lay - laid - laid
lead - led - led
leap - leaped/lept - leaped/lept
learn - learned/learnt - learned/learnt
leave - left - left
lend - lent - lent
let - let - let
lie - lay - lain
light - lit/lighted - lighted
lose - lost - lost
make - made - made
mean - meant - meant
meet - met - met
misspell - misspelled/misspelt - misspelled/misspelt
mistake - mistook - mistaken
mow - mowed - mowed/mown
overcome - overcame - overcome
overdo - overdid - overdone
overtake - overtook - overtaken
overthrow - overthrew - overthrown
pay - paid - paid
plead - pled - pled
prove - proved - proved/proven
put - put - put
quit - quit - quit
read - read - read
rid - rid - rid
ride - rode - ridden
ring - rang - rung
rise - rose - risen
run - ran - run
saw - sawed - sawed/sawn
say - said - said
see - saw - seen
seek - sought - sought
sell - sold - sold
send - sent - sent
set - set - set
sew - sewed - sewed/sewn
shake - shook - shaken
shave - shaved - shaved/shaven
shear - shore - shorn
shed - shed - shed
shine - shone - shone
shoe - shoed - shoed/shod
shoot - shot - shot
show - showed - showed/shown
shrink - shrank - shrunk
shut - shut - shut
sing - sang - sung
sink - sank - sunk
sit - sat - sat
sleep - slept - slept
slay - slew - slain
slide - slid - slid
sling - slung - slung
slit - slit - slit
smite - smote - smitten
sow - sowed - sowed/sown
speak - spoke - spoken
speed - sped - sped
spend - spent - spent
spill - spilled/spilt - spilled/spilt
spin - spun - spun
spit - spit/spat - spit
split - split - split
spread - spread - spread
spring - sprang/sprung - sprung
stand - stood - stood
steal - stole - stolen
stick - stuck - stuck
sting - stung - stung
stink - stank - stunk
stride - strod - stridden
strike - struck - struck
string - strung - strung
strive - strove - striven
swear - swore - sworn
sweep - swept - swept
swell - swelled - swelled/swollen 
swim - swam - swum
swing - swung - swung
take - took - taken
teach - taught - taught
tear - tore - torn
tell - told - told
think - thought - thought
thrive - thrived/throve - thrived
throw - threw - thrown
thrust - thrust - thrust
tread - trod - trodden
understand - understood - understood
uphold - upheld - upheld
upset - upset - upset
wake - woke - woken
wear - wore - worn
weave - weaved/wove - weaved/woven
wed - wed - wed
weep - wept - wept
wind - wound - wound
win - won - won
withhold - withheld - withheld
withstand - withstood - withstood
wring - wrung - wrung
write - wrote - written
EOF

}
sub _no_double{
return qw(
 abandon accouter accredit adhibit administer alter anchor answer attrit audit
 author ballot banner batten bedizen bespatter betoken bewilder billet blacken
 blither blossom bother brighten broaden broider burden caparison catalog censor
 center charter chatter cheapen chipper chirrup christen clobber cluster coarsen
 cocker coedit cohabit concenter corner cover covet cower credit custom dampen
 deafen decipher deflower delimit deposit develop differ disaccustom discover
 discredit disencumber dishearten disinherit dismember dispirit dither dizen
 dodder edit elicit embitter embolden embosom embower empoison empower enamor
 encipher encounter endanger enfetter engender enlighten enter envelop envenom
 environ exhibit exit fasten fatten feather fester filter flatten flatter
 flounder fluster flutter foreshorten founder fritter gammon gather gladden
 glimmer glisten glower greaten hamper hanker happen harden harken hasten
 hearten hoarsen honor imprison inhabit inhibit inspirit interpret iron laten
 launder lengthen liken limber limit linger litter liven loiter lollop louden
 lower lumber madden malinger market matter misinterpret misremember monitor
 moulder murder murmur muster number offer open order outmaneuver overmaster
 pamper pilot pivot plaster plunder powder power prohibit reckon reconsider
 recover redden redeliver register rejigger remember renumber reopen reposit
 rewaken richen roister roughen sadden savor scatter scupper sharpen shatter
 shelter shimmer shiver shorten shower sicken smolder smoothen soften solicit
 squander stagger stiffen stopper stouten straiten strengthen stutter suffer
 sugar summon surrender swelter sypher tamper tauten tender thicken threaten
 thunder totter toughen tower transit tucker unburden uncover unfetter unloosen
 upholster utter visit vomit wander water weaken whiten winter wonder worsen
);
}
