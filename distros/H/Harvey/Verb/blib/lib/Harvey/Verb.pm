package Verb;
use 5.006;
use strict;
use warnings;
our $VERSION = '1.02';

my $DEBUG = undef;

################################################################################
#
# Sentence type flags
#
################################################################################

my $S_STATEMENT = 0;
my $S_QUESTION  = 1;
my $S_COMMAND   = 2;

################################################################################
#
# Hash used to test for whether a word is a question word
#
################################################################################

my $question_words = { 	 # ver 1.02

    who   => undef,
    what  => undef,
    when  => undef,
    where => undef,
    how   => undef,
    why   => undef 
};

################################################################################
#
# Values for Modalities:  at the moment rather add hoc.  These will be thought
# through better as the semantic section develops.  They are here for the 
# purpose of general development.  In any case, a more thought out structure
# of modalities (or semantic meaning) will be represented by a number 
# reference as in this code
#
################################################################################

my $M_NONE		= 0;
my $M_CAN 		= 1;
my $M_MUST		= 2;
my $M_MAY		= 3;
my $M_MIGHT		= 4;
my $M_WANT		= 5;
my $M_NEED		= 6;
my $M_SHOULD		= 7;
my $M_WOULD		= 8;
my $M_COULD		= 9;
my $M_LIKE		= 10;
my $M_HATE		= 11;
my $M_WILL		= 12;
my $M_PREPARED		= 13;
my $M_INTEREST		= 14;
my $M_FORCE		= 15;
my $M_SCHEDULED		= 16;
my $M_WILLINGNESS	= 17;
my $M_DISINTEREST 	= 18;
my $M_CONSIDERING   = 19;
my $M_START 		= 20;
my $M_FINISH        = 21;
my $M_FEAR		= 22;
my $M_REQUEST		= 23;
my $M_BELIEF		= 24;
my $M_HELP		= 25;
my $M_KNOW		= 26;
my $M_AVOIDANCE		= 27;
my $M_DECISION		= 28;
my $M_DISALLOW      = 29;
my $M_COMMAND		= 30;
my $M_DARE		= 31;
my $M_EXECUTION		= 32;
my $M_STRIVE		= 33;
my $M_NEGLECT		= 34;
my $M_ATTEND_TO		= 35;
my $M_REPENTENCE	= 36;
my $M_CONTEMPLATE	= 37;
my $M_REMEMBER 		= 38;

################################################################################
#
# Generic strings for the various modalities listed above for the purpose of
# printing out parsed verb conjugations
#
################################################################################

my @modal_names = qw / none ability requirement allowance 
			possiblity want need obligation
			subjunctive subjunctive_ablility 
			like dislike intention preparedness 
			interest force scheduled willingness
			disinterest consider start 
                    finished fear request belief help 
		    know avoidance decision disallow 
			command risk execution strive neglect 
                    attend_to repentence contemplate 
			remember/;

################################################################################
#
# Hash used to test whether a verb is a simple modal (one tense, no conjugation
# and uses a bare infinitive) and return the modality if it is
#
################################################################################

my $modals = { # ver 1.02

    can    => $M_CAN,
    could  => $M_COULD,
    shall  => $M_WILL,
    should => $M_SHOULD,
    may    => $M_MAY,
    might  => $M_MIGHT,
    will   => $M_WILL,
    would  => $M_WOULD,
    must   => $M_MUST 
};

################################################################################
#
# Verbs that act like modals with 'to' plus infinitive.  A modal expresses a
# relationship between the subject and the verb, not the object of the sentence.
# Many verbs can act like modals and chain into long chains of modals leading
# up to the final verb, which is the real verb of the sentence.  The following
# hashes contain sets of verbs which do this in various ways:  the following
# by adding 'to' plus an infinitive.  When the hash is checked for a 'to' 
# modal, it returns the modality.
#
# The following sets are for study purposes and are by no means complete.
#
################################################################################

my $to_modals = { 	 # ver 1.02

    have     => $M_MUST,
    want     => $M_WANT,
    need     => $M_NEED,
    like     => $M_LIKE,
    hate     => $M_HATE,
    love     => $M_LIKE, 
    desire   => $M_WANT,
    start    => $M_START,
    begin    => $M_START,
    wish     => $M_WANT,
    ask      => $M_REQUEST,
    request  => $M_REQUEST,
    help     => $M_HELP,
    choose   => $M_DECISION,
    decide   => $M_DECISION,
    act      => $M_EXECUTION,
    continue => $M_EXECUTION,
    come     => $M_EXECUTION,
    demand   => $M_COMMAND,
    dare     => $M_DARE,
    expect   => $M_WILL,
    plan     => $M_WILL, 
    help     => $M_HELP,
    fight    => $M_STRIVE,
    cease    => $M_FINISH,
    forbid   => $M_DISALLOW,
    forget   => $M_NEGLECT,
    force    => $M_FORCE,
    remember => $M_ATTEND_TO,
    go       => $M_EXECUTION,
    be       => $M_SCHEDULED,
    try      => $M_STRIVE,
};

################################################################################
#
# These verbs can act just like a modal, i.e., they just need an infinitive,
#
################################################################################

my $verb_modals = {	 # ver 1.02

    help => $M_HELP,
    let  => $M_MAY,
    see  => $M_KNOW,
    hear => $M_KNOW,
    go   => $M_EXECUTION,
    make => $M_FORCE 
};

################################################################################
#
# These verbs also act like modals, but differ from the 'to' modals in that
# they simply use some other preposition and may use the infinitive or gerund
# form of the verb.
#
################################################################################

my $prep_modals = { # ver 1.02

    dream        => [{
        Prep     => "about",
        Verb     => "Gerund",
        Modality => $M_CONTEMPLATE}],
    forgive      => [{
        Prep     => "for",
        Verb     => "Gerund",
        Modality => $M_FORCE}],
    insist       => [{
        Prep     => "on",
        Verb     => "Gerund",
        Modality => $M_COMMAND }],
    believe      => [{ 
        Prep     => 'in',
        Verb     => 'Gerund',
        Modality => $M_BELIEF }],
    help         => [{
        Prep     => 'with',
        Verb     => 'Gerund',
        Modality => $M_HELP }],
    think        => [{
        Prep     => 'about',
        Verb     => 'Gerund',
        Modality => $M_CONTEMPLATE}, {
        Prep     => 'of',
        Verb     => 'Gerund',
        Modality => $M_REMEMBER}]
};

################################################################################
#
# These verbs act just like modals except that they use the gerund form of the
# verb.  Motice that there is lots of cross over.  'Help' can work many ways:
#
# I will help fix the car. I will help you fix the car.  I will help to fix
# the car.  I will help with fixing the car. I helped fixing the car. etc.
# ad nauseum.
#
################################################################################

my $gerund_modals = { # ver 1.02

    start   => $M_START,
    begin   => $M_START,
    finish  => $M_FINISH,
    stop    => $M_FINISH,
    like    => $M_LIKE,
    hate    => $M_HATE,
    avoid   => $M_AVOIDANCE,
    go      => $M_EXECUTION,
    love    => $M_LIKE,
    enjoy   => $M_LIKE,
    savored => $M_LIKE 
};

################################################################################
#
# Predicate adjective modals are some form of 'to be' plus and adjective, then
# some preposition followed by an infinitive or a gerund
#
################################################################################


my $pred_adj_modals = {	 # ver 1.02

    able         => { 	
        Prep     => "to", 
        Verb     => "Infinitive", 
        Modality => $M_CAN },
    going        => {	
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_WILL},
    interested   => {
        Prep     => "in",
        Verb     => "Gerund",
        Modality => $M_INTEREST},
    ready        => {	
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_PREPARED},
    eager        => {  
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_WANT},
    happy        => {  
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_WILLINGNESS},
    loathe       => { 
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_HATE},
    tired        => {	
        Prep     => "of",
        Verb     => "Gerund",
        Modality => $M_DISINTEREST},
    thinking     => {
        Prep     => "about",
        Verb     => "Gerund",
        Modality => $M_CONSIDERING},
    done         => {	
        Prep     => "NONE",
        Verb     => "Gerund",
        Modality => $M_FINISH},
    through      => {	
        Prep     => "NONE",
        Verb     => "Gerund",
        Modality => $M_FINISH},
    finished     => {	
        Prep     => "NONE",
        Verb     => "Gerund",
        Modality => $M_FINISH},
    afraid       => { 
        Prep     => "of",
        Verb     => "Gerund",
        Modality => $M_FEAR },
};


################################################################################
#
# Object Modals are some form of 'have', plus an object, some preposition and
# an infinitive or a gerund.  The object is the key to the hash.
#
################################################################################


my $object_modals = {	 # ver 1.02

    desire       => {	
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_WANT },
    ability      => {	
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_CAN },
    need         => {	
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_NEED },
    opportunity  => {	
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_MAY },
    chance       => {	
        Prep     => "to",
        Verb     => "Infinitive",
        Modality => $M_MAY },
    interest     => {
        Prep     => "in",
        Verb     => "Gerund",
        Modality => $M_INTEREST },
    fear         => { 	
        Prep     => "of",
        Verb     => "Gerund",
        Modality => $M_FEAR }
};

################################################################################
#
# The following flags are used to maintain Tense information.  They are 'anded'
# or 'ored' against the $self->{Tense} integer to maintain tense data for the
# current object
#
################################################################################

my $T_PRESENT 		= 1;
my $T_PAST		= 2;
my $T_PROGRESSIVE	= 4;
my $T_PERFECT		= 8;
my $T_PASSIVE		= 16;
my $T_INFINITIVE 	= 32;

################################################################################
#
# Parsing hashes:  the parse() function uses parsing hashes to guide it through
# the parsing process.  These hashes hand off to one another based on what 
# happens while working through the sentence.  The most common verbs, in
# particular the helping verbs do, have, be and the modals, have their own
# startup hashes.  Other verbs startup with the generic hashes present_p and
# past_p.  See the $am_p startup hash to get a feel for how the hashes work.
# The hashes are evaluated in the parse() method.  By convention, exact word
# matches to a key is lower case:  flags and tests to be run are upper and low
# case.
#
################################################################################

################################################################################
#
# hashes for forms of 'to be', the startup hashes are am_p, is_p, are_p, was_p
# and were_p
#
################################################################################
 
my $am_being_taken = { # ver 1.02

    Debug         => "in am_being_taken",
    Add_Tense     => $T_PASSIVE,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $am_being = { # ver 1.02

    Debug         => "in am_being",
    Add_Tense     => $T_PROGRESSIVE,
    Set_Verb      => "Gerund",	
    Set_Used      => 1,
    Allow_Adverbs => 1,
    Participle    => $am_being_taken
};

my $am_taking = { # ver 1.02

    Debug         => "in am_taking",
    Add_Tense     => $T_PROGRESSIVE,
    Set_Verb      => "Gerund",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $am_taken = { # ver 1.02

    Debug         => "in am_taken",
    Add_Tense     => $T_PASSIVE,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $am_p = { # ver 1.02

    Debug         => "in am_p",		# show message if DEBUG = 1
    Set_Tense     => $T_PRESENT,    # set $self->{Tense} to value
    Set_Persons   => "Verb",        # set $self->{Persons} using Verb arg
    Set_Verb      => "Present",     # use Present arg when setting verb
    Set_Used      => 1,				# indicate this word used in Verb complex
    being         => $am_being,     # branch to $am_being if matches 'being'
    Gerund        => $am_taking,    # branch to $am_taking if gerund form
    Participle    => $am_taken,     # branch to $am_taken if participle form
    Allow_Adverbs => 1              # allow and collect interleaving adverbs
};

my $is_p = { # ver 1.02

    Debug         => "in is_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    being         => $am_being,
    Gerund        => $am_taking,
    Participle    => $am_taken,
    Allow_Adverbs => 1
};

my $are_p = { # ver 1.02

    Debug         => "in are_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    being         => $am_being,		
    Gerund        => $am_taking, 
    Participle    => $am_taken,
    Allow_Adverbs => 1
};

my $was_taking = { # ver 1.02

    Debug     => "in was_taking",
    Add_Tense => $T_PROGRESSIVE,
    Set_Verb  => "Gerund",
    Set_Used  => 1
};

my $was_taken = { # ver 1.02

    Debug         => "in was_taken",
    Add_Tense     => $T_PASSIVE,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $was_being_taken = { # ver 1.02

    Debug         => "in was_being_taken",
    Add_Tense     => $T_PASSIVE,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $was_being = { # ver 1.02

    Debug         => "in was_being",
    Add_Tense     => $T_PROGRESSIVE,
    Set_Verb      => "Gerund",
    Set_Used      => 1,
    Allow_Adverbs => 1,
    Participle    => $was_being_taken
};

my $was_p = { # ver 1.02

    Debug         => "in was_p",
    Set_Tense     => $T_PAST,
    Set_Persons   => "Verb",
    Set_Verb      => "Past",
    Set_Used      => 1,
    being         => $was_being,	
    Gerund        => $was_taking, 
    Participle    => $was_taken,
    Allow_Adverbs => 1
};

my $were_p = { # ver 1.02

    Debug         => "in were_p",
    Set_Tense     => $T_PAST,
    Set_Persons   => "Verb",
    Set_Verb      => "Past",
    Set_Used      => 1,
    being         => $was_being,	
    Gerund        => $was_taking,
    Participle    => $was_taken,
    Allow_Adverbs => 1
};

################################################################################
#
# hashes for tenses starting with a form of 'to have'
#
################################################################################

my $have_been_being_taken = { # ver 1.02

    Debug         => "in have_been_being_taken",
    Add_Tense     => $T_PASSIVE,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $have_been_being = { # ver 1.02

    Debug         => "in have_been_being",
    Add_Tense     => $T_PROGRESSIVE,
    Set_Verb      => "Gerund",
    Set_Used      => 1,
    Allow_Adverbs => 1,
    Participle    => $have_been_being_taken # test
};

my $have_been_taking = { # ver 1.02

    Debug         => "in have_been_taking",
    Add_Tense     => $T_PROGRESSIVE,
    Set_Verb      => "Gerund",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $have_been_taken = { # ver 1.02

    Debug         => "in have_been_taken",
    Add_Tense     => $T_PASSIVE,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $have_been = { # ver 1.02

    Debug         => "in have_been",
    Add_Tense     => $T_PERFECT,
    Set_Verb      => "Participle",
    Set_Used      => 1,
    Allow_Adverbs => 1,
    being         => $have_been_being,		
    Gerund        => $have_been_taking,
    Participle    => $have_been_taken
};

my $have_taken = { # ver 1.02

    Debug         => "in have_taken",
    Add_Tense     => $T_PERFECT,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $have_p = { # ver 1.02

    Debug         => "in have_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    been          => $have_been,		
    Participle    => $have_taken,	
    Allow_Adverbs => 1
};

my $has_p = { # ver 1.02

    Debug         => "in has_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    been          => $have_been,	
    Participle    => $have_taken,	
    Allow_Adverbs => 1
};

my $had_been_being_taken = { # ver 1.02

    Debug         => "in had_been_being_taken",
    Add_Tense     => $T_PASSIVE,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $had_been_being = { # ver 1.02

    Debug         => "in am_being_taken",
    Add_Tense     => $T_PROGRESSIVE,
    Set_Verb      => "Gerund",
    Set_Used      => 1,
    Allow_Adverbs => 1,
    Participle    => $had_been_being_taken
};

my $had_been_taking = { # ver 1.02

    Debug         => "in had been taking",
    Add_Tense     => $T_PROGRESSIVE,
    Set_Verb      => "Gerund",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $had_been_taken = { # ver 1.02

    Debug         => "in had been taken",
    Add_Tense     => $T_PASSIVE,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $had_been = { # ver 1.02

    Debug         => "in had_been",
    Add_Tense     => $T_PERFECT,
    Set_Verb      => "Participle",
    Set_Used      => 1,
    Allow_Adverbs => 1,
    being         => $had_been_being,		
    Gerund        => $had_been_taking,		
    Participle    => $had_been_taken
};

my $had_taken = { # ver 1.02

    Debug         => "in had_taken",
    Add_Tense     => $T_PERFECT,
    Set_Verb      => "Participle",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $had_p = { # ver 1.02

    Debug         => "in had_p",
    Set_Tense     => $T_PAST,
    Set_Persons   => "Verb",
    Set_Verb      => "Past",
    Set_Used      => 1,
    been          => $had_been,			
    Participle    => $had_taken,	
    Allow_Adverbs => 1
};

################################################################################
#
# hashes for verb structures starting with 'to do'
#
################################################################################


my $do_infinitive = { # ver 1.02

    Debug         => "in do_infinitive",
    Set_Verb      => "Infinitive",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $do_p = { # ver 1.02

    Debug         => "in do_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    Infinitive    => $do_infinitive,  # check for an infintive
    Allow_Adverbs => 1
};

my $does_p = { # ver 1.02

    Debug         => "in does_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    Infinitive    => $do_infinitive,
    Allow_Adverbs => 1
};

my $did_p = { # ver 1.02

    Debug         => "in did_p",
    Set_Tense     => $T_PAST,
    Set_Persons   => "Verb",
    Set_Verb      => "Past",
    Set_Used      => 1,
    Infinitive    => $do_infinitive,
    Allow_Adverbs => 1
};

my $modal_have = { # ver 1.02

    Debug         => "in modal_have",
    Set_Tense     => $T_INFINITIVE,
    Set_Verb      => "Infinitive",
    Set_Used      => 1,
    been          => $have_been,	
    Participle    => $have_taken,	
    Allow_Adverbs => 1
};

my $modal_be = { # ver 1.02

    Debug         => "in modal_be",
    Set_Tense     => $T_INFINITIVE,
    Set_Verb      => "Infintive",
    Set_Used      => 1,
    being         => $am_being,		
    Gerund        => $am_taking,  
    Participle    => $am_taken,
    Allow_Adverbs => 1
};

my $modal_infinitive = { # ver 1.02

    Debug         => "in modal_infinitive",
    Set_Tense     => $T_INFINITIVE,
    Set_Verb      => "Infinitive",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $gerund_modal = { # ver 1.02

    Debug         => "in gerund_modal",
    Create_Modal  => 1,
    No_Increment  => 1,				# do not move onto next word
    being         => $am_being,
    Gerund        => $am_taking,
    Allow_Adverbs => 1
};

my $prep_prep = { # ver 1.02

    Debug         => "in prep_prep",
    Set_Used      => 1,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    being         => $am_being,
    Gerund        => $am_taking,
    Allow_Adverbs => 1,
    Allow_All     => 1    
};

my $prep_modal = { # ver 1.02

    Debug         => "in prep_modal",
    Create_Modal  => 1,
    Set_Used      => 1,
    Prep_Check    => $prep_prep,
    No_Increment  => 1,
    Allow_All     => 1,
    Allow_Adverbs => 1
};

my $verb_modal_infinitive = { # ver 1.02

    Debug         => "in verb_modal_infinitive",
    Set_Tense     => $T_INFINITIVE,
    Set_Verb      => "Infinitive",
    Allow_Adverbs => 1,
    Set_Used      => 1
};

my $verb_modal = { # ver 1.02

    Debug         => "in verb_modal",
    Create_Modal  => 1,
    Set_Used      => 1,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $verb_modal_infinitive,
    No_Increment  => 1,
    Allow_Adverbs => 1,
    Allow_All     => 1			# allow any word to interleave
};

my $object_prep = { # ver 1.02

    Debug         => "in object_prep",
    Set_Used      => 1,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    being         => $am_being,
    Gerund        => $am_taking,
    Allow_Adverbs => 1
};

my $object_modal = { # ver 1.02

    Debug             => "in object_modal",
    Create_Modal      => 1,	       # make current verb into a modal
    Set_Used          => 1,            # and store it in the modal array
    Object_Prep_Check => $object_prep, # then reset the current object
    Allow_Adverbs     => 1
};

my $pred_adj_prep = { # ver 1.02

    Debug         => "in pred_adj_prep",
    Set_Used      => 1,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    being         => $am_being,
    Gerund        => $am_taking,
    Allow_Adverbs => 1
};

my $pred_adj_modal = { # ver 1.02

    Debug               => "in pred_adj_modal",
    Create_Modal        => 1,
    Set_Used            => 1,
    Pred_Adj_Prep_Check => $pred_adj_prep,   # check for pred adj modal verbs
    Allow_Adverbs       => 1
};

my $to_modal = { # ver 1.02

    Debug         => "in to_modal",
    Create_Modal  => 1,
    Set_Used      => 1,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    Allow_Adverbs => 1
};

my $present_p = { # ver 1.02

    Debug         => "in present_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    Allow_Adverbs => 1
};

my $past_p = { # ver 1.02

    Debug         => "in past_p",
    Set_Tense     => $T_PAST,
    Set_Persons   => "Verb",
    Set_Verb      => "Past",
    Set_Used      => 1,
    Allow_Adverbs => 1
};

my $can_p = { # ver 1.02

    Debug         => "in can_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    Allow_Adverbs => 1
};

my $will_p = { # ver 1.02

    Debug         => "in will_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Verb",
    Set_Verb      => "Present",
    Set_Used      => 1,
    Allow_Adverbs => 1
};

my $must_p = { # ver 1.02

    Debug         => "in must_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Modal",
    Set_Used      => 1,
    Set_Verb      => "Present",
    Create_Modal  => 1,
    Modality      => $M_MUST,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    Allow_Adverbs => 1
};

my $may_p = { # ver 1.02

    Debug         => "in may_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Modal",
    Set_Used      => 1,
    Set_Verb      => "Present",
    Create_Modal  => 1,
    Modality      => $M_MAY,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    Allow_Adverbs => 1 
};

my $might_p = { # ver 1.02

    Debug         => "in might_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Modal",
    Set_Used      => 1,
    Set_Verb      => "Present",
    Create_Modal  => 1,
    Modality      => $M_MIGHT,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    Allow_Adverbs => 1 
};

my $would_p = { # ver 1.02

    Debug         => "in would_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Modal",
    Set_Used      => 1,
    Set_Verb      => "Present",
    Create_Modal  => 1,
    Modality      => $M_WOULD,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    Allow_Adverbs => 1
};

my $should_p = { # ver 1.02

    Debug         => "in should_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Modal",
    Set_Used      => 1,
    Set_Verb      => "Present",
    Create_Modal  => 1,
    Modality      => $M_SHOULD,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    Allow_Adverbs => 1
};

my $could_p = { # ver 1.02

    Debug         => "in could_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Modal",
    Set_Used      => 1,
    Set_Verb      => "Present",
    Create_Modal  => 1,
    Modality      => $M_COULD,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    Allow_Adverbs => 1 
};


my $ought_p = { # ver 1.02

    Debug         => "in ought_p",
    Set_Tense     => $T_PRESENT,
    Set_Persons   => "Modal",
    Set_Used      => 1,
    Set_Verb      => "Present",
    Create_Modal  => 1,
    Modality      => $M_SHOULD,
    be            => $modal_be,
    have          => $modal_have,
    Infinitive    => $modal_infinitive,
    Allow_Adverbs => 1,
    Skip          => '/^to$/',
};

################################################################################
#
# Startup hash with all words that can directly startup the parsing process
#
################################################################################

my $root_p = { # ver 1.02

    am     => $am_p,
    is     => $am_p,
    are    => $am_p,
    was    => $was_p,
    were   => $was_p,
    have   => $have_p,
    has    => $have_p,
    had    => $had_p,
    do     => $do_p,
    does   => $does_p,
    did    => $did_p,
    can    => $can_p,
    must   => $must_p,
    may    => $may_p,
    might  => $might_p,
    should => $should_p,
    would  => $would_p,
    could  => $could_p,
    will   => $will_p,
    ought  => $ought_p
};

################################################################################
#
# Constructor for Verb 
#
################################################################################

sub new { # ver 1.02

    my $class = shift;
    my $self = {};

    bless ($self,$class);

    # Sentences are passed in as arrays of Word.  If an array is sent in, parse
    # it, otherwise just set up a blank array 
    if (@_) {
        
        # setup and initialize $self->{Words} array
        $self->words(shift);

        # find the best parsing for the array
        $self->best();               
    }
    else {
        $self->words([]);
    } 
    return $self;
}

################################################################################
#
# Initialize the array of words
#
################################################################################

sub initialize { # ver 1.02

    my $self = shift;
    
    # Initialize the index to the current word in the array
    $self->{Word_Index} = 0;

    # Set the current Word object in the sentence array
    $self->{Word} = @{$self->{Words}}->[$self->{Word_Index}];

    # Set up an array to recieve any modal chains that may appear
    $self->{Modals} = [];

    # Set up an array to receive any adverbs that may appear
    $self->{Adverbs} = [];

    # Clear out the Tense Integer
    $self->{Tense} = 0;

    # Clear out the Persons Integer
    $self->{Persons} = 0;

    # This will hold the infinitive of the main verb
    $self->{Verb} = "";

    # This Integer is a bit map of words in the array that are verbs
    $self->{Used} = 0;

    # Initialize sentence type to statement
    $self->{Sentence_Type} = $S_STATEMENT;
}

################################################################################
#
# Methods for moving around on the array of words
#
################################################################################

sub words { # ver 1.02

    my $self = shift;

    if (@_) {

        # Get the array
        $self->{Words} = shift;
        
        # Initialize Vars
        $self->initialize();
        
        # nothing sent in, will be loaded by hand, ie when modal created
        if (@{$self->{Words}} == 0) {
            return; 
        }
    }	
    return $self->{Words};
}

################################################################################
#
# Methods for moving around on the array of words ($self->{Words}) and set
# a handle to the current word object in $self->{Word} and keep an index to
# the current word in $self->{Word_Index}.  They also perform validity checks
# and return 0 if the method fails (begining or end of array), otherwise, 
# they return a handle to the newly current word object.
#
################################################################################

sub next_word { # ver 1.02

    my $self = shift;
    
    # Make sure we are not at the end
    if ($self->{Word_Index} < @{$self->{Words}} - 1) { 
        $self->{Word_Index}++; 
    }
    else { 
        # oops at the end of the array
        return 0; 
    }
    # Set the current Word object
    $self->{Word} = @{$self->{Words}}->[$self->{Word_Index}];
    
    # Return the current Word object
    return $self->{Word};
}

sub prev_word { # ver 1.02

    my $self = shift;
    
    # Make sure we are not at the beginning
    if ($self->{Word_Index} > 0) { 
        $self->{Word_Index}--; 
    }
    else { 
        # oops at the beginning of the array
        return 0; 
    }
    # Set the current Word object
    $self->{Word} = @{$self->{Words}}->[$self->{Word_Index}];
    
    # Return the current Word object
    return $self->{Word};
}

sub first_word { # ver 1.02

    my $self = shift;
    
    # Set index to front
    $self->{Word_Index} = 0;
    
    # Set the current Word object
    $self->{Word} = @{$self->{Words}}->[$self->{Word_Index}];
    
    # Return the current Word object
    return $self->{Word};
}

sub last_word { # ver 1.02

    my $self = shift;
    
    # Set index to end
    $self->{Word_Index} = @{$self->{Words}} - 1;
    
    # Set the current Word object
    $self->{Word} = @{$self->{Words}}->[$self->{Word_Index}];
    
    # Return the current Word object
    return $self->{Word};
}

################################################################################
#
# Go to the specified word in the array and return an object handle to it.
# If a + or - is used with the number argument for location, then the placement
# is made relative to the current location
#
################################################################################

sub goto_word { # ver 1.02

    my ($self,$location) = @_;
    
    # if no location is used, return a handle to the current object
    if (!defined $location) { 
        return $self->{Word}; 
    }
    
    # adjust relative to current position if + or - used
    if ($location =~ /^(\+\-)/) {
        $location = $location + $self->{Word_Index};
    }
    
    # verify that location is in range for the array
    if ($location < 0 || $location >= @{$self->{Words}}) {
        return 0;
    }
    
    # set the standard object vars
    $self->{Word_Index} = $location;
    $self->{Word} = @{$self->{Words}}->[$location];
    
    # return a handle to the object
    return $self->{Word};
}

################################################################################
#
# Puts references to verb objects that are modals onto the 
# modal stack '@{$seld->{Modals}}', returns an array reference to modals used
#
# When modals are created, a new Verb object is created for them and the 
# tense and modality info is pulled from the current object and placed into it.
# The stack of modals are thus stored as an array of verb objects in the array
# $self->{Modals}
#
################################################################################

sub modal_stack { # ver 1.02

    my ($self, $modal) = @_;
    
    if (defined $modal) { 
        push @{$self->{Modals}}, $modal;
    }
    
    return $self->{Modals};
}


################################################################################
#
# Routines to set and get the Used Flags, which indicate the
# words in the array used by the verb structure
#
################################################################################

################################################################################
#
# Used to set bits in the flag set $self->{Used}.  If not arg is passed in
# no changes occur to the flag set.
#
#    Inputs: 	0 - clear flag set
#		1 - turn on bit for current word object
#    Outputs:	Always returns  $self->{Used}
#
################################################################################

sub used { # ver 1.02
    
    my ($self,$arg) = @_;
    
    if (defined $arg) {
        if ($arg == 0) { 
            $self->{Used} = 0;
        }
        elsif ($arg == 1) { 
            $self->{Used} |= 1 << $self->{Word_Index};
        }
    }

    return $self->{Used};
}

################################################################################
#
# verb_cnt() and best() work together to figure out the best parsing for
# the word array in the Verb object.  The parsing which uses the most
# words wins. If the number of words is the same, break tie by weighting
# starters on exact matches over common verb starters over any verb starter
# Stores the result as a number (0|1|2).  Leaves the Object parsed using the
# best parsing.
#
################################################################################


sub verb_cnt { # ver 1.02

    my $self = shift;

    # get the used bit map
    my $used = $self->used();
    my $cnt = 0;
    
    # keep going till $used is shifted out of bits
    while ($used) {
        
        # if the low bit is on, count it
        $cnt++ if ($used % 2);

        # move onto next bit
        $used >>= 1;        
    }
    return $cnt;
}

################################################################################
#
# uses verb_cnt() above to calculate the best of the 
# three parsing methods
#
################################################################################

sub best(){ # ver 1.02

    my $self = shift;

    # array of parsing results
    my @p;

    # var to track best result
    my $b;
    
    # try each parsing and store results
    $self->parse(0);
    $p[0] = $self->verb_cnt();
    $self->parse(1);
    $p[1] = $self->verb_cnt();
    $self->parse(2);
    $p[2] = $self->verb_cnt();
    
    # see if parsing 1 beats parsing 0
    $b = $p[1] > $p[0] ? 1 : 0;

    # see if parsing 2 beats winner of above
    $b = $p[2] > $p[$b] ? 2 : $b;
    
    # store result
    $self->{Best} = $b;
    
    # leave object in best state
    $self->parse($b);
    
    # return result
    return $b;
}

################################################################################
#
# This section contains methods for querying the characteristics
# of the verb
#
################################################################################

################################################################################
#
# Get a string rendering of the complete tense
#
################################################################################

sub complete_tense { # ver 1.02
    
    my $self = shift;

    # gathers ordered strings of tense and verb info to be returned
    my @desc;

    # scratch var to hold handles to modals while being processed
    my $M;
    
    # no verb or even incomplete modal found
    if (!$self->tenses() && @{$self->{Modals}} == 0) {

        return "no verbs found";
    }

    # if we have modals, run through the chain of modals in the array of 
    # verb objects $self->{Modals}
    if (@{$self->{Modals}} != 0) { 

        foreach $M  (@{$self->{Modals}}) {

            # store the modal tense info into the @desc array
            if ($M->present()) { push @desc,"present" }
            if ($M->past()) { push @desc,"past" }
            if ($M->perfect()) { push @desc,"perfect" }
            if ($M->progressive()) { push @desc,"progressive" }
            if ($M->passive()) { push @desc,"passive" }

            # store the meaning of the modal
            push @desc,$M->verb();

            # store chit chat
            push @desc,"modality for the";
        }
    }

    # Get the tense info for the main verb
    if ($self->present()) { push @desc,"present" }
    if ($self->past()) { push @desc,"past" }
    if ($self->perfect()) { push @desc,"perfect" }
    if ($self->progressive()) { push @desc,"progressive" }
    if ($self->passive()) { push @desc,"passive" }
    if ($self->infinitive()) { push @desc,"infinitive" }

    # Add a little text
    push @desc,"of";

    # Add the infinitive of the main verb
    push @desc,$self->verb();

    # join the desc array with spaces and return
    return join " ",@desc;	
}

################################################################################
#
# Show the adverbs used in the sentence
#
################################################################################

sub show_adverbs { # ver 1.02
    
    my $self = shift;

    # scratch array ref var
    my $R;
    my $L;

    # gathers ordered strings of adverbs
    my @desc;

    # scratch var to hold handles to modals while being processed
    my $M;
    
    # no verbs or modals found
    if (!$self->tenses() && @{$self->{Modals}} == 0) {

        return "no adverbs found";
    }

    # if we have modals, run through the chain of modals in the array of 
    # verb objects $self->{Modals}
    if (@{$self->{Modals}} != 0) { 

        # process the modals
        foreach $M (@{$self->{Modals}}) {
    
            # get the adverbs
            $R = $M->adverbs();

            # if there aren't any, move on
            if (!@{$R}) { 
                next;
            }
            else {
                # store name of modal, a label
                push @desc,$M->verb()." adverbs: ";

                # and the adverbs set with a space
                $L = join " ",@{$R};
                push @desc,$L;
            }
        }
    }

    # get the adverbs for the main verb
    if (@{$self->{Adverbs}}) { 
        push @desc,$self->verb()." adverbs: ";
        $L = join " ",@{$self->{Adverbs}};
        push @desc,$L;
    }

    # join the desc array with spaces and return
    $L = join " ",@desc;
    return $L;	
}

################################################################################
#
# get/set all tenses flags at once. The tenses can be set all at once, by
# sending in a complete integer flag set as an argument.  In any case, the
# final complete flagset is returned.  
#
################################################################################

sub tenses { # ver 1.02
    
    my ($self, $arg) = @_;
    
    if (defined $arg) { $self->{Tense} = $arg }

    return $self->{Tense};
}

################################################################################
#
# used with the following wrapper methods to set/get individual
# tense flags
#
################################################################################

sub tense { # ver 1.02
    
    my ($flag, $self, $arg) = @_;
    
    # turning bit on or off ?   
    if (defined $arg) {
        
        # turn it on	
        if ($arg) { $self->{Tense} |= $flag }
        
        # turn it off
        else { $self->{Tense} &= ~$flag }
    }
    # return the flag
    return $self->{Tense} & $flag;
}

sub present { return tense($T_PRESENT,@_) }

sub past { return tense($T_PAST,@_) }

sub perfect { return tense($T_PERFECT,@_) }

sub progressive { return tense($T_PROGRESSIVE,@_) }

sub passive { return tense($T_PASSIVE,@_) }

sub infinitive { return tense($T_INFINITIVE,@_) }

################################################################################
#
# Get/set Persons:  the persons informtion is a bit set indicating which 
# persons are possible for the current verb (ie. 1st sing, 2nd sing, 3rd sing
# 1st pl, etc)  If modals are present, the information is kept in the first
# modal of the $self->{Modals} array.  Otherwise in the main Verb object 
# itself.
#
################################################################################

sub persons { # ver 1.02

    my ($self,$arg) = @_;

    # Working Var for modal object
    my $M;
    
    # are modals present?
    if (@{$self->{Modals}} != 0) {

        # set a pointer to the first modal
        $M = @{$self->{Modals}}->[0];

        # set persons if an arg was sent in
        if (defined $arg) { $M->persons($arg) }

        # return current persons
        return $M->persons();
    }
    else {
        # no modals present, set persons if arg present
        if (defined $arg) { $self->{Persons} = $arg }

	# return current persons 
        return $self->{Persons};
    }
}

################################################################################
#
# Get/Set the infinitive of the main verb
#
################################################################################

sub verb { # ver 1.02

    my ($self,$arg) = @_;
    
    # If arg sent in, set the infinitive
    if (defined $arg) { $self->{Verb} = $arg }
    
    # return the infinitive
    return $self->{Verb};
}

################################################################################
#
# Get/Set the adverb array
#
################################################################################

sub adverbs { # ver 1.02

    my ($self,$arg) = @_;

    # If arg sent in, get the adverb array
    if (defined $arg) { @{$self->{Adverbs}} = @{$arg} }

    return $self->{Adverbs}; 
}

################################################################################
#
# Sentence Type Methods
#
################################################################################

################################################################################
#
# returns the type as INT, can be set by sending in
# $S_COMMAND, $S_QUESTION or $S_STATEMENT as args
#
################################################################################

sub sentence_type { # ver 1.02

    my ($self,$type) = @_;
    
    if ($type) { $self->{Sentence_Type} = $type }
    
    return $self->{Sentence_Type};
}

################################################################################
#
# Set/get statement, arg of 1 sets to statement
#
################################################################################

sub statement { # ver 1.02
    
    my ($self,$set) = @_;
    
    if ($set) { $self->{Sentence_Type} = $S_STATEMENT }
    
    return ($self->{Sentence_Type} == $S_STATEMENT);
}

################################################################################
#
# Set/get command, arg of 1 sets to command
#
################################################################################

sub command { # ver 1.02
    
    my ($self,$set) = @_;
    
    if ($set) { $self->{Sentence_Type} = $S_COMMAND }
    
    return ($self->{Sentence_Type} == $S_COMMAND);
}

################################################################################
#
# Set/get question, arg of 1 sets to question
#
################################################################################

sub question { # ver 1.02
    
    my ($self,$set) = @_;
    
    if ($set) { $self->{Sentence_Type} = $S_QUESTION }
    
    return ($self->{Sentence_Type} == $S_QUESTION);
}

################################################################################
#
# The look_ahead method is used by the parse() method to look ahead on the
# array for various conditions.  The parse() method would otherwise be 
# restricted to evaluating things only as they come up.  
# Two arguments are used: $test and $skip.  $test is an array of tests which
# must be met on sequential word objects.  If the a given test fails, then
# the corresponding $skip test is applied to see if the word qualifies for 
# being skipped over.  If it does not, or we run out of words before all tests
# are passed, we return 0, else 1.  
# The look_ahead function is used with wrapper functions which specify the 
# arrays of tests to be used.
# Temporary scratch keys are often used in the $self hash by the test functions.
#
################################################################################

sub look_ahead { # ver 1.02

    my ($self,$tests,$skips) = @_;

    # The location in the array will be retored upon completion
    my $save_location = $self->{Word_Index};

    # Function pointer to current test to pass
    my $test;

    # Function pointer to current skip test
    my $skip;
    
    # loop through words and tests
    while ($self->next_word() && ($test = shift @{$tests})) {
        
        # set up corresponding skip test if sent in
        if (defined $skips) { $skip = shift @{$skips} }
        
        # look for a match for the test
        while (!($test->($self))) {
            
            # test didn't pass, see if skip is used here and valid
            if (!$skip ||
              (!($skip->($self)) || !($self->next_word()))) {
                
                # skip failed, return 0
                $self->goto_word($save_location); 
                return 0;
            }
        }
    }

    # restore settings
    $self->goto_word($save_location);
    
    # if some tests are left, return 0, else 1 for success. 
    return (@{$tests} ? 0 : 1);
}

################################################################################
#
# look for the preposition and verb form specified by the 
# prep_modal hash 
#
################################################################################

sub prep_modal_check { # ver 1.02
    
    my $self = shift;

    # handle to current word object
    my $W = $self->{Word};

    # a given prepostional modal verb may have more than one preposition, e.g.
    # think of working, think about working.  Therefore there is an array of
    # hashes for each one.  $P is a scratch var pointing to the current hash
    # to be checked
    my $P;

    # tracks which hash in the array is currently used.  This will be 
    # stored in $self->{Prep_Modal_Index} so that later on we will know
    # which preposition, verb type and modality to use.
    my $index = 0;
    
    # step through array of hashes for possible prepositional modal
    foreach $P ( @{$prep_modals->{$self->verb()}} ) {
        
        # save the stuff to check for in temporary nodes of the 
        # $self hash, these will be used by the subroutines when
        # they are run in the look_ahead function
        $self->{Preposition_Tmp} = $P->{Prep};
        $self->{Verb_Form_Tmp} = $P->{Verb};
        
        # define the array of tests to send to look_ahead
        my $test = [
            
            sub { 
                my $self = shift; 

                # was the preposition found?
                return $self->{Word}->text() eq $self->{Preposition_Tmp}
            },
            sub { 
                my $self = shift;

                # set a handle to the current word object
                my $W = $self->{Word};

                # if we are looking for a gerund and it is one, return
                # true, otherwise, we are looking for an infinitive
                if ($self->{Verb_Form_Tmp} eq "Gerund") {
                    return $W->gerund_verb();
                }
                else {
                    return $W->infinitive_verb();
                }
            }
        ];
        
        # define tests for allowing a skip of an interleaving word
        my $skip = [
            
            # allow adverbs
            sub { 
                return shift->{Word}->adverb() ? 1 : 0 
            },

            # allow anything
            sub { return 1 }
        ];
        
        if ($W->text() eq $self->{Preposition_Tmp}) {
            
            # we are already on the preposition, don't need first test
            shift @$test;
            shift @$skip;
        }
        
        # call look_ahead to see if the tests past
        if ($self->look_ahead($test,$skip)) {
            
            # save index of hash that was successful
            $self->{Prep_Modal_Index} = $index;

            # return success
            return 1;
        }
        
        # increment index as we move though the hashes
        $index++;
        
    }
    
    # nothing found
    return 0;
}

################################################################################
#
# look for the preposition and verb form specified by the 
# object modal hash 
#
################################################################################

sub object_modal_check { # ver 1.02
    
    my $self = shift;

    # pointer to current word
    my $W = $self->{Word};
    
    # save the stuff to check for in temporary nodes of the $self hash
    $self->{Preposition_Tmp} = $object_modals->{$W->text()}->{Prep};
    $self->{Verb_Form_Tmp} = $object_modals->{$W->text()}->{Verb};
    
    # define the tests to pass
    my $test = [

        # look for the preposition first
        sub { 
            my $self = shift;
            return $self->{Word}->text() eq $self->{Preposition_Tmp};
        },

        # then conditionally check for a Gerund or Infinitive
        sub { 
            my $self = shift;
            my $W = $self->{Word};

            if ($self->{Verb_Form_Tmp} eq "Gerund") {
                return $W->gerund_verb();
            }
            else {
                return $W->infinitive_verb();
            }
        }
    ];
    
    # If NONE specified for the preposition, remove the first test
    if ($self->{Preposition_Tmp} eq "NONE") { shift @{$test} }
    
    # Allow adverbs in any case
    my $skip = [
        sub { return shift->{Word}->adverb() ? 1 : 0 },
        sub { return shift->{Word}->adverb() ? 1 : 0 }
    ];
    
    # return the results of the look_ahead function
    return $self->look_ahead($test,$skip);
}

################################################################################
#
# look ahead for a gerund
#
################################################################################

sub gerund_modal_check { # ver 1.02
    
    my $self = shift;
    
    # just find a gerund
    my $test = [sub { return shift->{Word}->gerund_verb() }];

    # allow interleaving adverbs
    my $skip = [sub { return shift->{Word}->adverb() ? 1 : 0 }];
    
    # return the results of look_ahead
    return $self->look_ahead($test,$skip);
}

################################################################################
#
# look for the preposition and verb form specified by the 
# predicate adjective hash
#
################################################################################

sub pred_adj_modal_check { # ver 1.02
    
    my $self = shift;

    # handle to current word
    my $W = $self->{Word};
    
    # save the stuff to check for in temporary nodes of the 
    # $self hash
    $self->{Preposition_Tmp} = $pred_adj_modals->{$W->text()}->{Prep};
    $self->{Verb_Form_Tmp} = $pred_adj_modals->{$W->text()}->{Verb};
    
    # define tests
    my $test = [

        # test for the preposition
        sub { 
            my $self = shift;
            return $self->{Word}->text() eq $self->{Preposition_Tmp};
        },

        # test for the gerund or infinitive
        sub { 
            my $self = shift;
            my $W = $self->{Word};
            if ($self->{Verb_Form_Tmp} eq "Gerund") {
                return $W->gerund_verb();
            }
            else {
                return $W->infinitive_verb();
            }
        }
    ];

    # remove the preposition test if NONE specified
    if ($self->{Preposition_Tmp} eq "NONE") { shift @{$test} }

    # set skip to allow adverbs
    my $skip = [sub { return shift->{Word}->adverb() ? 1 : 0 }];
    
    # return look_ahead results
    return $self->look_ahead($test,$skip);
}

################################################################################
#
# look for an infinitive, allow adverbs to be skipped
#
################################################################################

sub modal_infinitive_check { # ver 1.02

    my $self = shift;
    
    # test word for infinitive
    my $test = [sub { return shift->{Word}->infinitive_verb() }];

    # allow adverbs
    my $skip = [sub { return shift->{Word}->adverb() ? 1 : 0 }];
    
    # return look_ahead results
    return $self->look_ahead($test,$skip);
}

################################################################################
#
# look for 'to' plus 'infinitive'
# allow 'yuck' adverbs because someone might do it
#
################################################################################

sub to_infinitive_check { # ver 1.02

    my $self = shift;
    
    # set up tests
    my $test = [

        # check for word matching 'to'
        sub { return shift->{Word}->text('/^to$/') },

        # check for word with infinitive attribute
        sub { return shift->{Word}->infinitive_verb() }
    ];

    # set up skips - allow adverbs for both cases
    my $skip = [
        sub { return shift->{Word}->adverb() ? 1 : 0 },
        sub { return shift->{Word}->adverb() ? 1 : 0 }
    ];

    # return look_ahead results
    return $self->look_ahead($test,$skip);
}

################################################################################
#
# look for an 'infinitive'
# allow anything to be skipped
#
################################################################################

sub infinitive_check { # ver 1.02

    my $self = shift;
    
    # test for infinitive
    my $test = [sub { return shift->{Word}->infinitive_verb() }];

    # allow anything to interleave during infinitive search
    my $skip = [sub { return 1 }];
    
    # if we are already on an infinitive we don't need to test
    if ($self->{Word}->infinitive_verb()) {
        return 1;
    }

    # otherwise return results of look_ahead
    return $self->look_ahead($test,$skip);
}

################################################################################
#
# look for a 'participle'
# allow anything to be skipped
#
################################################################################

sub participle_check { # ver 1.02

    my $self = shift;
    
    # test for the participle
    my $test = [sub { return shift->{Word}->participle_verb() }];

    # allow anything to appear during participle check
    my $skip = [sub { return 1 }];
    
    # if we are already on the participle no test needed
    if ($self->{Word}->participle_verb()) {
        return 1;
    }

    # return results of look_ahead
    return $self->look_ahead($test,$skip);
}

################################################################################
#
# Determine the infinitive for the verb and store in $self->{Verb}
# Used by parse()
#
################################################################################

sub set_verb { # ver 1.02

    my ($self,$W,$Part) = @_;
    
    # the word object needs to know what part of the verb is being entered
    # to find the infinitive.  e.g. fell, could be present: i fell a tree or
    # past: i fell down a hill
    # third means the third person singular form: e.g. falls
    if ($Part eq "Present") {
        if ($W->third_verb()) { $self->verb($W->verb_dictionary("Third")) }
        else { $self->verb($W->verb_dictionary("Infinitive")) }
    }
    else { $self->verb($W->verb_dictionary($Part)) }
}

################################################################################
#
# looks for a starter verb that is a string match to a hash table entry as
# listed in root_p, e.g. am => $am_p.  Used to find a starting place to start
# parsing.  Starters found this way have precedence over the other methods
#
################################################################################

sub find_exact_starter { # ver 1.02

    my $self = shift;

    # pointer to the hash table
    my $P = $root_p;

    # pointer to the word object
    my $W = $self->first_word();
    
    # look for starting verb based on direct match
    # of word in root hash
    while (!exists $P->{$W->text()}) {

        # move on to next word or fail
        $W = $self->next_word() || return 0;
    }
    
    # found something, return the the next hash pointer
    return $P->{$W->text()};
}

################################################################################
#
# looks for a starter verb that is most commonly a verb based on BNC frequency
#
################################################################################

sub find_common_verb_starter { # ver 1.02

    my $self = shift;

    # pointer to the parsing hashes
    my $P = $root_p;

    # pointer to the current word object
    my $W = $self->first_word();
    
    # look for starting verb based on it being
    # present or past and being a verb by first
    # choice
    while (!($W->choice(1) eq "Verb" &&
      ($W->present_verb() || $W->past_verb()))) {

        # move onto next word or die
        $W = $self->next_word() || return 0; 
    }
    
    # found something, return the correct
    # starting hash pointer
    return $W->past_verb ? $past_p : $present_p;
}

################################################################################
#
# looks for any word that could possibly be a verb starter, whether it is 
# most frequently used as a verb or not.
#
################################################################################

sub find_any_verb_starter { # ver 1.02

    my $self = shift;

    # Pointer to parsing hashes
    my $P = $root_p;

    # Pointer to current word
    my $W = $self->first_word();
    
    # look for any present or past verb we can find
    while (!($W->present_verb() || $W->past_verb())) { 

        # move onto next word or die
        $W = $self->next_word() || return 0;
    }
    
    # found something, return the correct
    # hash pointer
    return $W->past_verb ? $past_p : $present_p;
}

################################################################################
#
# Main parsing method: main routine for parsing the verb tense of the array
# of words that was passed in when the object was created.  Works with the
# parsing hashes and parsing functions listed above.
#
################################################################################


sub parse { # ver 1.02

    my $self = shift;    

    # level 0 exact text match with hash
    # level 1 use only verbs that are most frequently verbs
    # level 3 use any possible verb
    my $level = @_ ? shift : 0;
    my $P;			# set to the root parsing hash
    my $W;			# Reference to current Word Object
    my $V;			# Reference to secondary Verb Objects
    my $track_modality; # Used to track potential modality
    
    # fresh initializtion of vars in $self
    $self->initialize();
    
    # find a starting point on basis of $level
    if ($level == 0) {
        if (!($P = $self->find_exact_starter())) { return 0 }
    }
    elsif ($level == 1) {
        if (!($P = $self->find_common_verb_starter())) { return 0 }
    }
    elsif ($level == 2 ) {
        if (!($P = $self->find_any_verb_starter())) { return 0 }
    }
    else { return 0 }
    
    # Set pointer to current word object
    $W = $self->{Word};
    
    # Establish sentence type
    if ($self->{Word_Index} == 0) {

        # Verb is at beginning of sentence, question or command
        if (($W->text() eq 'do' && !$self->infinitive_check()) ||
          ($W->text() eq 'have' && !$self->participle_check()) ||
          $W->text() eq 'be' || (!$W->text('/^(do|have)$/') &&
          !exists $modals->{$W->text()} && $W->infinitive_verb())) {

            # it must be a command
            $self->command(1);
        }
        else { 
            # must be a question
            $self->question(1);
        }
    }
    else { 
	# not at beginning: is a statement unless question word starts
        if (exists $question_words->{$self->{Words}->[0]->text()}) {
            $self->question(1);
        }
        else {
            $self->statement(1);
        }
    }
    
    # process this hash and any other chained hashes.  $P points to the
    # current parsing hash
    while (1) {
        
        # show any debugging messages found in the hash
        if ($DEBUG) {
            if ($P->{Debug}) { print "\tDEBUG: ",$P->{Debug},"\n" }
        }
        
        # Execute Set_Tense directive
        if (exists $P->{Set_Tense}) { $self->tenses($P->{Set_Tense}) }
        
        # Execute Add_Tense directive
        if (exists $P->{Add_Tense}) { $self->{Tense} |= $P->{Add_Tense} }
        
        # Execute Set_Used directive to indicate this word is a verb
        if (exists $P->{Set_Used}) { $self->used(1) }
        
        # Execute the Set_Persons directive
        if (exists $P->{Set_Persons}) { 

            # the Word object needs to know if object is verb or modal
            if ($P->{Set_Persons} eq "Verb") { 
                $self->persons($W->verb_persons());
            }
            elsif ($P->{Set_Persons} eq "Modal") {
                $self->persons($W->modal_persons());
            }
        }
        
        # Execute the Set_Verb directive
        if (exists $P->{Set_Verb}) {
            # if modality is set in the hash, use this for the infinitive
            if ($P->{Modality}) {
                $self->{Verb} = ($modal_names[$P->{Modality}]);
            }
            # Otherwise, set the verb to the infinitive 
            else { $self->set_verb($W,$P->{Set_Verb}) }
        }
        
        # Execute the Create_Modal directive
        if (exists $P->{Create_Modal}) {

            # Create a new verb object to hold the modal
            $V = Verb->new();       

            # add the new object to the current objects modal array
            $self->modal_stack($V);

            # move the tenses from the current object to its modal object
            $V->tenses($self->tenses());

            # move the persons to the modal object
            $V->persons($self->{Persons});

            # move the infinitive to the modal object
            $V->verb($self->verb());

            # move the adverbs
            $V->adverbs($self->{Adverbs});

            # clear this objects tenses
            $self->tenses(0);

            # clear this objects persons
            $self->{Persons} = 0;

            # clear this objects infinitive
            $self->verb("");

            # clear the adverbs
            $self->{Adverbs} = [];
        }
        
        # move onto the next word in array unless No_Increment directive
        if (!exists $P->{No_Increment}) { 
            $W = $self->next_word() || return 1;
        }
        
        # Execute Goto_Word directive if it exists
        if ($P->{Goto_Word}) {
            $W = goto_word($P->{Goto_Word}) || return 1;
        }
        
        # Execute Skip directive if it exists        
        if (exists $P->{Skip}) {

            # skip matches to the regular expression in $P->{Skip}
            while ($W->text($P->{Skip})) {

                # next word or die
                ($W = $self->next_word()) || return 1;
            }
        }
        
        # look for branching
        
        while (1) {
            
            # Match on the text of the current word?
            if (exists $P->{$W->text()}) {

                # branch to the hash listed for this string 
                $P = $P->{$W->text()};

                print "DEBUG: match on text branch\n" if $DEBUG;
                last; 
            }
            
            # Check of the preposition that should accompany the object
            # modal found above
            elsif (exists $P->{Object_Prep_Check} &&
              exists $self->{Preposition_Tmp} && 
              ($self->{Preposition_Tmp} eq $W->text() ||
              $self->{Preposition_Tmp} eq "NONE")) {

                # branch to the hash listed in the hashes 
                # Objcect_Prep_Check element
                $P = $P->{Object_Prep_Check};

                # if NONE was specified for the prep, backup and continue
                if ($self->{Preposition_Tmp} eq "NONE") { 
                    $W = $self->prev_word();
                }

                print "DEBUG: object_prep_check branch\n" if $DEBUG;
                last;
            }
            
            # Check for prepositions for the prepositional modal
            elsif (exists $P->{Prep_Check} &&
              exists $self->{Preposition_Tmp} && 
              $self->{Preposition_Tmp} eq $W->text()) {

                # branch to the hash listed under Prep_Check
                # in the hash
                $P = $P->{Prep_Check};

                print "DEBUG: prep_check branch\n" if $DEBUG;
                last;
            }
            
            # Check for prep that goes with the pred adj modal?
            elsif (exists $P->{Pred_Adj_Prep_Check} &&
              exists $self->{Preposition_Tmp} && 
              ($self->{Preposition_Tmp} eq $W->text() ||
              $self->{Preposition_Tmp} eq "NONE")) {

                # branch to hash listed in Pred_Adj_Prep_Check
                # of the current hash
                $P = $P->{Pred_Adj_Prep_Check};

                # if NONE listed for the preposition, backup and continue
                # parsing
                if ($self->{Preposition_Tmp} eq "NONE") {
                    $W = $self->prev_word();
                }

                print "DEBUG: pred_adj_prep_check branch\n" if $DEBUG;
                last;
            }
            
            # can/will trap since they can be both verb and modal
            # make sure verb infinitive is can or will, it was the
            # present tense and not third person (4th bit on persons)
            elsif ($self->infinitive_check() &&
              exists $modals->{$self->verb()} && 
              $self->tenses() == $T_PRESENT  &&
              !($self->persons() & 4) ) {

                # set modality into Verb
                $self->verb($modal_names[$modals->{$self->verb()}]);

                # adjust the persons
                $self->persons($W->modal_persons());

                # make sure used set
                $self->used(1);

                # branch to verb modal handler
                $P = $verb_modal;

                print "DEBUG: can/will trap branch\n" if $DEBUG;
                last;
            } 
            
            # Match on Gerund Test?
            elsif (exists $P->{Gerund} && $W->gerund_verb()) { 

                # branch to hash listed in Gerund of current hash
                $P = $P->{Gerund};

                print "DEBUG: gerund test branch\n" if $DEBUG;
                last;
            }
            
            # Match on Particple Test?
            elsif (exists $P->{Participle} && $W->participle_verb()) { 

                # branch to hash listed under Participle of current hash
                $P = $P->{Participle};

                print "DEBUG: participle test branch\n" if $DEBUG;
                last;
            }
            
            # Match on Infinitive Test?
            elsif (exists $P->{Infinitive} && $W->infinitive_verb()) { 

                # branch to hash listed under Infinitive of current hash
                $P = $P->{Infinitive};

                print "DEBUG: infinitive test branch\n" if $DEBUG;
                last;
            }
            
            # Allow_Adverbs?
            elsif (exists $P->{Allow_Adverbs} && $W->choice(1) eq "Adverb") {

                # swallow any adverbs
                while ($W->choice(1) eq "Adverb") { 

                    # list them as part of verb
                    $self->used(1);

                    # store them in the local objects Adverbs array
                    push @{$self->{Adverbs}},$W->text();

                    # move onto next word or die
                    $W = $self->next_word() || return 1;
                }
                print "DEBUG: Allow_Adverbs branch\n" if $DEBUG;
                
                # look for more stuff
                next;
            }
            
            # Check of object modal verb
            elsif ($self->verb() eq "have" &&
              exists $object_modals->{$W->text()} &&
              $self->object_modal_check()) {

                # set the verb to the modality of the object modal
                $self->verb($modal_names[$object_modals->{$W->text()}->{Modality}]);

                # branch to object modal handling hash
                $P = $object_modal;

                print "DEBUG: object_modal branch\n" if $DEBUG;
                last;
            } 
            
            # Check for prepositional modal
            elsif (exists $prep_modals->{$self->verb()} &&
              $self->prep_modal_check()) {

                # set pointer to prep_modal hash
                my $ptr = $prep_modals->{$self->verb()};

                # store the modality in $self->{Verb}
                $self->verb($modal_names[$ptr->[$self->{Prep_Modal_Index}]->{Modality}]);

                # branch to the prepositional modal hash
                $P = $prep_modal;

                print "DEBUG: prepositional_modal branch\n" if $DEBUG;
                last;
            } 
            
            # Check of a 'to modal'
            elsif ($W->text('/^to$/') && 
              $self->infinitive_check() &&
              exists $to_modals->{$self->verb()} ) {

                # set the modality
                $self->verb($modal_names[$to_modals->{$self->verb()}]);

                # indicate the 'to' used in the verb complex
                $self->used(1);

                # branch to the to_modal handler
                $P = $to_modal;

                print "DEBUG: to_modal branch\n" if $DEBUG;
                last;
            } 
            
            # Check for a gerund modal
            if (exists $gerund_modals->{$self->verb()} &&
              ($W->gerund_verb() ||
              $self->gerund_modal_check())) {

                # set the modality into the Verb field
                $self->verb($modal_names[$gerund_modals->{$self->verb()}]);

                # branch to the gerund modal handler hash
                $P = $gerund_modal;

                print "DEBUG: gerund_modal branch\n" if $DEBUG;
                last;
            } 
            
            # Check for a predicate adjective modal
            if ($self->verb() eq "be" &&
              exists $pred_adj_modals->{$W->text()} &&
              $self->pred_adj_modal_check()) {

                # Set the modality into the Verb field
                $self->verb($modal_names[$pred_adj_modals->{$W->text()}->{Modality}]);

                # Branch to the pred_adj modal handler hash
                $P = $pred_adj_modal;

                print "DEBUG: pred_adj_modal branch\n" if $DEBUG;
                last;
            } 
            
            # Check for verb modal
            elsif (exists $verb_modals->{$self->verb()} && 
              $self->infinitive_check()) {

                # Set the modality into the Verb field
                $self->verb($modal_names[$verb_modals->{$self->verb()}]);

                # make sure used is set
                $self->used(1);

                # branch to the verb_modal hash
                $P = $verb_modal;

                print "DEBUG: verb_modal branch\n" if $DEBUG;
                last;
            } 
            
            # skip bucket, contitionally pass over stuff, since noun
            # object don't exist yet, some slack has been open up
            # for instances where determiners and adjectives might
            # legitimately show up without breaking the verb parsing
            elsif (exists $to_modals->{$self->verb()} ||
              # allow to modals to keep looking for 'to'
               
              # allow object modals to find object 
              $self->verb() eq "have" || 

              # Execute Allow_All directive
              exists $P->{Allow_All} ||

              # allow parsing to get from do, does or did to rest of
              # verb
              ($self->question() && ($self->tenses() == $T_PRESENT ||
              $self->tenses() == $T_PAST ||
              $self->tenses() == 0))) {

                # move onto next word or die
                $W = $self->next_word() || return 1;

                print "DEBUG: skip_bucket branch\n" if $DEBUG;
            }
            
            else {

                # if we get here past all the branching options
                # then we are done and the parsing is complete
                return 1;
            }
        }
    }
}

1;
__END__

=head1 NAME

Harvey::Verb - Harvey module for parsing verbs.

=head1 SYNOPSIS

  use Harvey::Verb;

  The is still very much a development module.  See the website:
  www.mytechs.com for more details on the project.

  Verb.pm builds on top of Word.pm, which provides the Word objects which
  are used by Verb.pm.

  See Word.pm for information on using Word.pm to obtain information about
  Word objects.  Verb objects are created by passing an array of Word objects
  (A) which constitute a sentence, as an argument to the Verb object
  constructor.  $V = Verb->new(\@A);

  The Verb object parses the verb in the sentence upon initialization to the
  best apparent parsing.  The Verb object can then be queried for information
  about the verb object using the following methods.

  See the Harvey module for a simple dialog routine that uses the Verb module
  to parse sentences and pull the verb information from them.

=head1 DESCRIPTION

  The following methods constitute the interface to this object:

  new 
    Constructor.  Send in an array reference to a block of word objects 
    (Word.pm) to have the verb information parsed and made available.  If
    no argument is passed in, then a blank verb is set up which can be
    manually stuffed with information.

  words 
    Method to load or retrieve word arrays from the object.  If a word array
    is loaded manually after the initialization of the object, then the 
    parsing must be performed by a call to parse() or best().

  used 
    Returns an integer with bits set indicating which words in the array
    are used in the verb complex.  This will be used to match verbs against
    nouns in a sentence when the noun module comes out.

  best
    Calculates the best parsing of the sentence based on how many word are
    involved in the parsing and whether they are started off by the most
    common verb starters.

  complete_tense 
    Returns a string rendition of the tense of the verb in the word array.

  show_adverbs 
    Returns the adverbs in the verb complex as strings for show.

  tenses 
    Returns the Int which stores the tenses, and/or, sets the tenses if an
    Int is sent in.  Used mainly to set up modal verb objects from scratch.

  present
    Get/Set present tense.  Input of 1 or 0 sets or clears the present 
    tense.  All calls return the final status of the present tense flag.

  past
    Get/set past tense as above.

  perfect
    Get/set perfect tense as above.

  progressive
    Get/set progressive tense as above.

  infinitive
    Get/set infinitive flag as above.

  persons
    Get/set the persons information.  The persons information is stored
    in an integer with a flag for the 1st pers sing, 2nd sing. 3rd sing,
    etc.  Send in an integer to set it.  The current values is alwasys
    returned.  Verbs, Noun object (when they come out) both indicate what
    possible persons they would support.  This allows for convient checking
    of subject verb agreement.

  verb
    Gets/set the infinitive of the main verb as a string

  adverbs
    Get/sets the array of adverbs found in the sentence.  Arguments are 
    passed in and out as a reference to an array.

  sentence_type
    Get/sets the sentence type.  Arg in and out is an integer.  
    0 = statement, 1 = question, 2 = command.

  statement
    Get/set whether the sentence is a statement.

  question
    Get/set whether the sentence is a question.

  command
    Get/set whether the sentence is a command.

  best
    Finds the best parsing based on the number of words (more is better) 
    in the verb structure and obviousness of the leadoff verb. 

  parse
    Performs the parsing of the object.  Takes three possible integer
    arguments (0|1|2).  0: always start parsing on exact matches to 
    helping verbs or modals; 1: always start parsing on verbs the are
    most frequently used as verbs; 2: allow any potential verb to start
    the parsing.  0 is default


=head2 EXPORT

None by default.


=head1 AUTHOR

Chris Meyer<lt>chris@mytechs.com<gt>

=head1 COPYWRITE

  Copywrite (c) 2002, Chris Meyer.  All rights reserved.  This is 
  free software and can be used under the same terms as Perl itself.

=head1 VERSION 

  1.02

=head1 RELATED LIBRARIES

  My heartfelt thanks to Adam Kilgarriff for his work on the BNC 
  (British National Corpus) which forms the basis for the word.db.
  I have added and massaged it a bit, but I would never have gotten
  this far without it.  The BNC can be visited at
  http://www.itri.brighton.ac.uc/~Adam.Kilgarriff/bnc-readme.html.

=head1 DATA LOCATION

  Harvey uses algorithms AND data to work.  The program looks for 
  a file called 'system.dat' in the startup directory.  In this file
  it looks for a line that reads 'path=your_path', where your_path
  is the directory where the data resides.  

=head1 HARVEY

  The accompanying Harvey module comes with a simple dialog routine 
  that uses Verb.pm to demonstrate the parsing of sentence.

L<perl>.

=cut
