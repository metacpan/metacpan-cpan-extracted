package Lingua::EN::Tagger;

our $VERSION = '0.31';

use warnings;
use strict;

use 5.008000;

use Carp;
use File::Spec;
use FileHandle;
use HTML::TokeParser;
use Lingua::Stem::En;
use Storable;
use Memoize;

# Class variables
our %_LEXICON;          # this holds the word lexicon
our %_HMM;              # this holds the hidden markov model for English grammar
our $MNP;               # this holds the compiled maximal noun phrase regex
our ($lexpath, $word_path, $tag_path);
our ($NUM, $GER, $NNP, $ADJ, $PART, $NN, $PREP, $DET, $PAREN, $QUOT, $SEN, $WORD);

BEGIN {     #  REGEX SETUP
    sub get_exp {
        my ($tag) = @_;
        return unless defined $tag;
        return qr|<$tag>[^<]+</$tag>\s*|;
    }

    $NUM  = get_exp('cd');
    $GER  = get_exp('vbg');
    $ADJ  = get_exp('jj[rs]*');
    $PART = get_exp('vbn');
    $NN   = get_exp('nn[sp]*');
    $NNP  = get_exp('nnp');
    $PREP = get_exp('in');
    $DET  = get_exp('det');
    $PAREN= get_exp('[lr]rb');
    $QUOT = get_exp('ppr');
    $SEN  = get_exp('pp');
    $WORD = get_exp('\p{IsWord}+');

    ($lexpath) = __FILE__ =~ /(.*)\.pm/;
    $word_path = File::Spec->catfile($lexpath, 'pos_words.hash');
    $tag_path = File::Spec->catfile($lexpath, 'pos_tags.hash');

    memoize(\&Lingua::EN::Tagger::stem,
                     TIE => [ 'Memoize::ExpireLRU',
                             CACHESIZE => 1000,
                            ]);

    memoize(\&Lingua::EN::Tagger::_assign_tag,
                    TIE => ['Memoize::ExpireLRU',
                            CACHESIZE => 10000,
                            ]);
}


######################################################################

=head1 NAME

Lingua::EN::Tagger - Part-of-speech tagger for English natural language processing.


=head1 SYNOPSIS

    # Create a parser object
    my $p = new Lingua::EN::Tagger;

    # Add part of speech tags to a text
    my $tagged_text = $p->add_tags($text);

    ...

    # Get a list of all nouns and noun phrases with occurrence counts
    my %word_list = $p->get_words($text);

    ...

    # Get a readable version of the tagged text
    my $readable_text = $p->get_readable($text);


=head1 DESCRIPTION

The module is a probability based, corpus-trained tagger that assigns POS tags to
English text based on a lookup dictionary and a set of probability values.  The tagger
assigns appropriate tags based on conditional probabilities - it examines the
preceding tag to determine the appropriate tag for the current word.
Unknown words are classified according to word morphology or can be set to
be treated as nouns or other parts of speech.

The tagger also extracts as many nouns and noun phrases as it can, using a
set of regular expressions.

=head1 CONSTRUCTOR

=over


=item new %PARAMS

Class constructor.  Takes a hash with the following parameters (shown with default
values):

=over

=item unknown_word_tag => ''

Tag to assign to unknown words

=item stem => 0

Stem single words using Lingua::Stem::EN

=item weight_noun_phrases => 0

When returning occurrence counts for a noun phrase, multiply the value
by the number of words in the NP.

=item longest_noun_phrase => 5

Will ignore noun phrases longer than this threshold. This affects
only the get_words() and get_nouns() methods.

=item relax => 0

Relax the Hidden Markov Model: this may improve accuracy for
uncommon words, particularly words used polysemously

=back

=cut

######################################################################

sub new {
    my ($class, %params) = @_;
    my $self = {unknown_word_tag => '',
                stem => 0,
                weight_noun_phrases => 0,
                longest_noun_phrase => 5,
                lc => 1,
                tag_lex => 'tags.yml',
                word_lex => 'words.yml',
                unknown_lex => 'unknown.yml',
                word_path => $word_path,
                tag_path => $tag_path,
                relax => 0,
                debug => 0,
                %params};

    bless $self, $class;

    unless (-f $self->{'word_path'} and -f $self->{'tag_path'}){
        carp "Couldn't locate POS lexicon, creating new one" if $self->{'debug'};
        $self->install();
    } else {
        %_LEXICON = %{retrieve($self->{'word_path'})}; # A hash of words and corresponding parts of speech
        %_HMM = %{retrieve($self->{'tag_path'})};   # A hash of adjacent part of speech tags and the probability of each
    }

    $MNP = $self->_get_max_noun_regex();
    $self->_reset();

    return $self;
}

######################################################################

=back

=head1 METHODS

=over

=item add_tags TEXT

Examine the string provided and return it fully tagged (XML style)

=cut

######################################################################
sub add_tags {
    my ($self, $text) = @_;

    my $tags = $self->add_tags_incrementally($text);
    $self->_reset;
    return $tags;
}

######################################################################

=item add_tags_incrementally TEXT

Examine the string provided and return it fully tagged (XML style) but
do not reset the internal part-of-speech state between invocations.

=cut

######################################################################
sub add_tags_incrementally {
    my ($self, $text) = @_;

    return unless $self->_valid_text($text);

    my @text = $self->_clean_text($text);
    my $t = $self->{'current_tag'}; # shortcut
    my (@tags) =
        map {
            $t = $self->_assign_tag($t, $self->_clean_word($_))
                    || $self->{'unknown_word_tag'} || 'nn';
           "<$t>$_</$t>"
        } @text;
    $self->{'current_tag'} = $t;
    return join ' ', @tags;
}

######################################################################

=item get_words TEXT

Given a text string, return as many nouns and
noun phrases as possible.  Applies L<add_tags> and involves three stages:

=over

    * Tag the text
    * Extract all the maximal noun phrases
    * Recursively extract all noun phrases from the MNPs

=back

=cut

######################################################################
sub get_words {
    my ($self, $text) = @_;

    return unless $self->_valid_text($text);

    my $tagged = $self->add_tags($text);

    if($self->{'longest_noun_phrase'} <= 1){
        return $self->get_nouns($tagged);
    } else {
        return $self->get_noun_phrases($tagged);
    }
}


######################################################################

=item get_readable TEXT

Return an easy-on-the-eyes tagged version of a text string.  Applies
L<add_tags> and reformats to be easier to read.

=cut

######################################################################
sub get_readable {
    my ($self, $text) = @_;

    return unless $self->_valid_text($text);

    my $tagged =  $self->add_tags($text);
    $tagged =~ s/<\p{IsLower}+>([^<]+)<\/(\p{IsLower}+)>/$1\/\U$2/go;
    return $tagged;
}


######################################################################

=item get_sentences TEXT

Returns an anonymous array of sentences (without POS tags) from a text.

=cut

######################################################################
sub get_sentences {
    my ($self, $text) = @_;

    return unless $self->_valid_text($text);
    my $tagged = $self->add_tags($text);
    my @sentences;
    {
        local $self->{'lc'};
        $self->{'lc'} = 0;
        @sentences = map {$self->_strip_tags($_)}
                     split /<\/pp>/, $tagged;
    }

    foreach (@sentences){
        s/ ('s?) /$1 /g;
        s/ ([\$\(\[\{]) / $1/g;
        s/ (\P{IsWord}+) /$1 /g;
        s/ (`+) / $1/g;
        s/ (\P{IsWord}+)$/$1/;
        s/^(`+) /$1/;
        s/^([\$\(\[\{]) /$1/g;
    }
    return \@sentences;
}


###########################################
# _valid_text TEXT
#
# Check whether the text is a valid string
###########################################
sub _valid_text {
    my ($self, $text) = @_;
    if(!defined $text){
        # $text is undefined, nothing to parse
        carp "method call on uninitialized variable" if $self->{'debug'};
        return undef;
    } elsif (ref $text){
        # $text is a scalar reference, don't parse
        carp "method call on a scalar reference" if $self->{'debug'};
        return undef;
    } elsif ($text =~ /^\s*$/){
        # $text is defined as an empty string, nothing to parse
        return undef;
    } else {
        # $text is valid
        return 1;
    }
}


sub lower_case {
	my ($self, $lc) = @_;
	if($lc){
		$self->{'lc'} = 1;
	} else {
		$self->{'lc'} = 0;
	}
}

#####################################################################
# _strip_tags TEXT
#
# Return a text string with the XML-style part-of-speech tags removed.
#####################################################################
sub _strip_tags {
    my ($self, $text) = @_;
    return unless $self->_valid_text($text);

    $text =~ s/<[^>]+>//gs;
    $text =~ s/\s+/ /gs;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;
    if($self->{'lc'}){
        return lc($text);
    } else {
        return $text;
    }
}


#####################################################################
# _clean_text TEXT
#
# Strip the provided text of HTML-style tags and separate off
# any punctuation in preparation for tagging
#####################################################################
sub _clean_text {
    my ($self, $text) = @_;
    return unless $self->_valid_text($text);

    # Strip out any markup and convert entities to their proper form
    my $html_parser;
    utf8::decode($text);
    $html_parser = HTML::TokeParser->new(\$text);

    my $cleaned_text = $html_parser->get_text;
    while($html_parser->get_token){
        $cleaned_text .= ($html_parser->get_text)." ";
    }

    # Tokenize the text (splitting on punctuation as you go)
    my @tokenized = map {$self->_split_punct($_)}
                            split /\s+/, $cleaned_text;
    my @words = $self->_split_sentences(\@tokenized);
    return @words;
}


#####################################################################
# _split_sentences ARRAY_REF
#
# This handles all of the trailing periods, keeping those that
# belong on abbreviations and removing those that seem to be
# at the end of sentences. This method makes some assumptions
# about the use of capitalization in the incoming text
#####################################################################
sub _split_sentences {
    my ($self, $array_ref) = @_;
    my @tokenized = @{$array_ref};

    my @PEOPLE = qw/jr mr ms mrs dr prof esq sr sen sens rep reps gov attys attys supt det mssrs rev/;
    my @ARMY = qw/col gen lt cmdr adm capt sgt cpl maj brig/;
    my @INST = qw/dept univ assn bros ph.d/;
    my @PLACE = qw/arc al ave blvd bld cl ct cres exp expy dist mt mtn ft fy fwy hwy hway la pde pd plz pl rd st tce/;
    my @COMP = qw/mfg inc ltd co corp/;
    my @STATE = qw/ala ariz ark cal calif colo col conn del fed fla ga ida id ill ind ia kans kan ken ky la me md is mass mich minn miss mo mont neb nebr nev mex okla ok ore penna penn pa dak tenn tex ut vt va wash wis wisc wy wyo usafa alta man ont que sask yuk/;
    my @MONTH = qw/jan feb mar apr may jun jul aug sep sept oct nov dec/;
    my @MISC = qw/vs etc no esp/;
    my %ABBR = map {$_, 0}
            (@PEOPLE, @ARMY, @INST, @PLACE, @COMP, @STATE, @MONTH, @MISC);

    my @words;
    for(0 .. $#tokenized){
        if (defined $tokenized[$_ + 1]
                and $tokenized[$_ + 1] =~ /[\p{IsUpper}\W]/
                and $tokenized[$_] =~ /^(.+)\.$/){

            # Don't separate the period off words that
            # meet any of the following conditions:
            #  1. It is defined in one of the lists above
            #  2. It is only one letter long: Alfred E. Sloan
            #  3. It has a repeating letter-dot: U.S.A. or J.C. Penney
            unless(defined $ABBR{lc $1}
                    or $1 =~ /^\p{IsLower}$/i
                    or $1 =~ /^\p{IsLower}(?:\.\p{IsLower})+$/i){
                push @words, ($1, '.');
                next;
            }
        }
        push @words, $tokenized[$_];
    }

    # If the final word ends in a period...
    if(defined $words[$#words] and $words[$#words] =~ /^(.*\p{IsWord})\.$/){
        $words[$#words] = $1;
        push @words, '.';
    }

    return @words;
}


###########################################################################
# _split_punct TERM
#
# Separate punctuation from words, where appropriate. This leaves trailing
# periods in place to be dealt with later. Called by the _clean_text method.
###########################################################################
sub _split_punct {
    local $_ = $_[1];

    # If there's no punctuation, return immediately
    return $_ if /^\p{IsWord}+$/;

    # Sanity checks
    s/\W{10,}/ /og;         # get rid of long trails of non-word characters

    # Put quotes into a standard format
    s/`(?!`)(?=.*\p{IsWord})/` /og;         # Shift left quotes off text
    s/"(?=.*\p{IsWord})/ `` /og;            # Convert left quotes to ``
    s/(?<![\p{IsWord}\s'])'(?=.*\p{IsWord})/ ` /go; # Convert left quotes to `
    s/"/ '' /og;                    # Convert (remaining) quotes to ''
    s/(?<=\p{IsWord})'(?!')(?=\P{IsWord}|$)/ ' /go; # Separate right single quotes

    # Handle all other punctuation
    s/--+/ - /go;                   # Convert and separate dashes
    s/,(?!\p{IsDigit})/ , /go;               # Shift commas off everything but numbers
    s/:$/ :/go;                     # Shift semicolons off
    s/(\.\.\.+)/ $1 /;              # Shift ellipses off
    s/([\(\[\{\}\]\)])/ $1 /go;     # Shift off brackets
    s/([\!\?#\$%;~|])/ $1 /go;      # Shift off other ``standard'' punctuation

    # English-specific contractions
    s/(?<=\p{IsAlpha})'([dms])\b/ '$1/go;      # Separate off 'd 'm 's
    s/n't\b/ n't/go;                        # Separate off n't
    s/'(ve|ll|re)\b/ '$1/go;                # Separate off 've, 'll, 're

    return split;
}


#####################################################################
# _assign_tag TAG, WORD (memoized)
#
# Given a preceding tag TAG, assign a tag to WORD.
# Called by the choose_tag method.
# This subroutine is a modified version of the Viterbi algorithm
# for part of speech tagging
#####################################################################
sub _assign_tag {
    my ($self, $prev_tag, $word) = @_;

    if ($self->{'unknown_word_tag'} and $word eq "-unknown-"){
        # If the 'unknown_word_tag' value is defined,
        # classify unknown words accordingly
        return $self->{'unknown_word_tag'};
    } elsif ($word eq "-sym-"){
        # If this is a symbol, tag it as a symbol
        return "sym";
    }

    my $best_so_far = 0;

    my $w = $_LEXICON{$word};
    my $t = \%_HMM;

    ##############################################################
    # TAG THE TEXT
    # What follows is a modified version of the Viterbi algorithm
    # which is used in most POS taggers
    ##############################################################
    my $best_tag;

    foreach my $tag (keys %{$t->{$prev_tag}}){
        # With the $self->{'relax'} var set, this method
        # will also include any `open classes' of POS tags
        my $pw;
        if(defined ${$w->{$tag}}){
            $pw = ${$w->{$tag}};
        } elsif ($self->{'relax'} and  $tag =~ /^(?:jj|nn|rb|vb)/){
            $pw = 0;
        } else {
            next;
        }

        # Bayesian logic:
        # P =  P($tag | $prev_tag) * P($tag | $word)
        my $probability = $t->{$prev_tag}{$tag} * ($pw + 1);

        # Set the tag with maximal probability
        if($probability > $best_so_far) {
            $best_so_far = $probability;
            $best_tag = $tag;
        }
    }

    return $best_tag;
}


############################################################################
# _reset
#
# this subroutine will reset the preceding tag to a sentence ender (PP).
# This prepares the first word of a new sentence to be tagged correctly.
############################################################################
sub _reset {
    my ($self) = @_;
    $self->{'current_tag'} = 'pp';
}


#####################################################################
# _clean_word WORD
#
# This subroutine determines whether a word should be considered in its
# lower or upper case form. This is useful in considering proper nouns
# and words that begin sentences. Called by L<choose_tag>.
#####################################################################
sub _clean_word {
    my ($self, $word) = @_;

    if (defined $_LEXICON{$word}) {
        # seen this word as it appears (lower or upper case)
        return $word;

    } elsif (defined $_LEXICON{lcfirst $word}) {
        # seen this word only as lower case
        return lcfirst $word;

    } else {
        # never seen this word. guess.
        return $self->_classify_unknown_word($word);
    }
}


#####################################################################
# _classify_unknown_word WORD
#
# This changes any word not appearing in the lexicon to identifiable
# classes of words handled by a simple unknown word classification
# metric. Called by the _clean_word method.
#####################################################################
sub _classify_unknown_word {
    my ($self, $word) = @_;

    local $_ = $word;

    if(m/[\(\{\[]/){ # Left brackets
        $word = "*LRB*";

    } elsif(m/[\)\]\}]/o){ # Right brackets
        $word = "*RRB*";

    } elsif (m/^-?(?:\p{IsDigit}+(?:\.\p{IsDigit}*)?|\.\p{IsDigit}+)$/){ # Floating point number
        $word = "*NUM*";

    } elsif (m/^\p{IsDigit}+[\p{IsDigit}\/:-]+\p{IsDigit}$/){ # Other number constructs
        $word = "*NUM*";

    } elsif (m/^-?\p{IsDigit}+\p{IsWord}+$/o){  # Ordinal number
        $word = "*ORD*";

    } elsif (m/^\p{IsUpper}[\p{IsUpper}\.-]*$/o) { # Abbreviation (all caps)
        $word = "-abr-";

    } elsif (m/\p{IsWord}-\p{IsWord}/o){ # Hyphenated word
        my ($h_suffix) = m/-([^-]+)$/;

        if ($h_suffix and defined ${$_LEXICON{$h_suffix}{'jj'} }){
            # last part of this is defined as an adjective
            $word = "-hyp-adj-";
        } else {
            # last part of this is not defined as an adjective
            $word = "-hyp-";
        }

    } elsif (m/^\W+$/o){ # Symbol
        $word = "-sym-";

    } elsif ($_ eq ucfirst) { # Capitalized word
        $word = "-cap-";

    } elsif (m/ing$/o) { # Ends in 'ing'
        $word = "-ing-";

    } elsif(m/s$/o) { # Ends in 's'
        $word = "-s-";

    } elsif (m/tion$/o){ # Ends in 'tion'
        $word = "-tion-";

    } elsif (m/ly$/o){ # Ends in 'ly'
        $word = "-ly-";

    } elsif (m/ed$/o){ # Ends in 'ed'
        $word = "-ed-";

    } else { # Completely unknown
        $word = "-unknown-";
    }

    return $word;
}


#####################################################################
# stem WORD (memoized)
#
# Returns the word stem as given by L<Lingua::Stem::EN>. This can be
# turned off with the class parameter 'stem' => 0.
#####################################################################
sub stem {
    my ($self, $word) = @_;
    return $word unless $self->{'stem'};

    my $stemref = Lingua::Stem::En::stem(-words => [ $word ]);
    return $stemref->[0];
}


#####################################################################
# _get_max_noun_regex
#
# This returns a compiled regex for extracting maximal noun phrases
# from a POS-tagged text.
#####################################################################
sub _get_max_noun_regex {
    my $regex = qr/
        (?:$NUM)?(?:$GER|$ADJ|$PART)*   # optional number, gerund - adjective -participle
            (?:$NN)+                    # Followed by one or more nouns
            (?:
                (?:$PREP)*(?:$DET)?(?:$NUM)? # Optional preposition, determinant, cardinal
                (?:$GER|$ADJ|$PART)*    # Optional gerund-adjective -participle
                (?:$NN)+                # one or more nouns
            )*
        /xo;
    return $regex;
}


######################################################################

=item get_proper_nouns TAGGED_TEXT

Given a POS-tagged text, this method returns a hash of all proper nouns
and their occurrence frequencies. The method is greedy and will
return multi-word phrases, if possible, so it would find ``Linguistic
Data Consortium'' as a single unit, rather than as three individual
proper nouns. This method does not stem the found words.

=cut

######################################################################
sub get_proper_nouns {
    my ($self, $text) = @_;

    return unless $self->_valid_text($text);

    my @trimmed =   map {$self->_strip_tags($_)}
                            ($text =~ /($NNP+)/gs);
    my %nnp;
    foreach my $n (@trimmed) {
        next unless length($n) < 100; # sanity check on word length
        $nnp{$n}++ unless $n =~ /^\s*$/;
    }


    # Now for some fancy resolution stuff...
    foreach (keys %nnp){
        my @words = split /\s/;

        # Let's say this is an organization's name --
        # (and it's got at least three words)
        # is there a corresponding acronym in this hash?
        if (scalar @words > 2){
            # Make a (naive) acronym out of this name
            my $acronym = join '', map{/^(\p{IsWord})\p{IsWord}*$/} @words;
            if (defined $nnp{$acronym}){
                # If that acronym has been seen,
                # remove it and add the values to
                # the full name
                $nnp{$_} += $nnp{$acronym};
                delete $nnp{$acronym};
            }
        }
    }

    return %nnp;
}


######################################################################

=item get_nouns TAGGED_TEXT

Given a POS-tagged text, this method returns all nouns and their
occurrence frequencies.

=cut

######################################################################
sub get_nouns {
    my ($self, $text) = @_;

    return unless $self->_valid_text($text);

    my @trimmed =   map {$self->_strip_tags($_)}
                            ($text =~ /($NN)/gs);

    my %return;
    foreach my $n (@trimmed) {
        $n = $self->stem($n);
        next unless length($n) < 100; # sanity check on word length
        $return{$n}++ unless $n =~ /^\s*$/;
    }

    return %return;
}


######################################################################

=item get_max_noun_phrases TAGGED_TEXT

Given a POS-tagged text, this method returns only the maximal noun phrases.
May be called directly, but is also used by L<get_noun_phrases>

=cut

######################################################################
sub get_max_noun_phrases {
    my ($self, $text) = @_;

    return unless $self->_valid_text($text);

    my @mn_phrases = map {$self->_strip_tags($_)}
                            ($text =~ /($MNP)/gs);

    my %return;
    foreach my $p (@mn_phrases) {
        $p = $self->stem($p)
            unless $p =~ /\s/; # stem single words
        $return{$p}++ unless $p =~ /^\s*$/;
    }

    return %return;
}


######################################################################

=item get_noun_phrases TAGGED_TEXT

Similar to get_words, but requires a POS-tagged text as an argument.

=cut

######################################################################
sub get_noun_phrases {
    my ($self, $text) = @_;

    return unless $self->_valid_text($text);

    my $found;
    my $phrase_ext = qr/(?:$PREP|$DET|$NUM)+/xo;

    # Find MNPs in the text, one sentence at a time
    # Record and split if the phrase is extended by a (?:$PREP|$DET|$NUM)
    my @mn_phrases =  map {$found->{$_}++ if m/$phrase_ext/; split /$phrase_ext/}
                    ($text =~ /($MNP)/gs);

    foreach(@mn_phrases){
        # Split the phrase into an array of words, and
        # create a loop for each word, shortening the
        # phrase by removing the word in the first position
        # Record the phrase and any single nouns that are found
        my @words = split;

        for(0 .. $#words){
            $found->{join(" ", @words)}++ if scalar @words > 1;
            my $w = shift @words;
            $found->{$w}++ if $w =~ /$NN/;
        }
    }

    my %return;
    foreach(keys %{$found}){
        my $k = $self->_strip_tags($_);
        my $v = $found->{$_};

        # We weight by the word count to favor long noun phrases
        my @space_count = $k =~ /\s+/go;
        my $word_count = scalar @space_count + 1;

        # Throttle MNPs if necessary
        next if $word_count > $self->{'longest_noun_phrase'};

        $k = $self->stem($k) unless $word_count > 1; # stem single words
        my $multiplier = 1;
        $multiplier = $word_count if $self->{'weight_noun_phrases'};
        $return{$k} += ($multiplier * $v);
    }

    return %return;
}


######################################################################

=item install

Reads some included corpus data and saves it in a stored hash on the
local file system. This is called automatically if the tagger can't
find the stored lexicon.

=cut

######################################################################
sub install {
    my ($self) = @_;

    carp "Creating part-of-speech lexicon" if $self->{'debug'};
    $self->_load_tags($self->{'tag_lex'});
    $self->_load_words($self->{'word_lex'});
    $self->_load_words($self->{'unknown_lex'});
    store \%_LEXICON, $self->{'word_path'};
    store \%_HMM, $self->{'tag_path'};
}


########################################################
#       LOAD THE 2-GRAMS INTO A HASH FROM YAML DATA
#
# This is a naive (but fast) YAML data parser. It will
# load a YAML document with a collection of key: value
# entries ({pos tag}: {probability}) mapped onto
# single keys ({tag}). Each map is expected to be on a
# single line; i.e., det: { jj: 0.2, nn: 0.5, vb: 0.0002 }
#########################################################
sub _load_tags {
    my ($self, $lexicon) = @_;

    my $path = File::Spec->catfile($lexpath, $lexicon);
    my $fh = new FileHandle $path or die "Could not open $path: $!";
    while(<$fh>){
        next unless my ($key, $data) = m/^"?([^\{"]+)"?: \{ (.*) \}/;
        my %tags = split /[:,]\s+/, $data;
        foreach(keys %tags){
            $_HMM{$key}{$_} = $tags{$_};
        }
    }
    $fh->close;
}


#########################################################
#       LOAD THE WORD LEXICON INTO A HASH FROM YAML DATA
#
# This is a naive (but fast) YAML data parser. It will
# load a YAML document with a collection of key: value
# entries ({pos tag}: {count}) mapped onto single
# keys ({word}). Each map is expected to be on a
# single line; i.e., key: { jj: 103, nn: 34, vb: 1 }
#########################################################
sub _load_words {
    my ($self, $lexicon) = @_;

    my $path = File::Spec->catfile($lexpath, $lexicon);

    my $fh = new FileHandle $path or die "Could not open $path: $!";
    while(<$fh>){
        next unless my ($key, $data) = m/^"?([^\{"]+)"?: \{ (.*) \}/;
        my %tags = split /[:,]\s+/, $data;
        foreach(keys %tags){
            $_LEXICON{$key}{$_} = \$tags{$_};
        }
    }
    $fh->close;
}


############################
#       RETURN TRUE
############################
1;


__END__

=back

=head1 AUTHORS

    Aaron Coburn <acoburn@apache.org>

=head1 CONTRIBUTORS

    Maciej Ceglowski <developer@ceglowski.com>
    Eric Nichols, Nara Institute of Science and Technology

=head1 COPYRIGHT AND LICENSE

    Copyright 2003-2010 Aaron Coburn <acoburn@apache.org>

    This program is free software; you can redistribute it and/or modify
    it under the terms of version 3 of the GNU General Public License as
    published by the Free Software Foundation.

=cut
