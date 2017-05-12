package Word;
use 5.006;
use strict;
use warnings;
use MLDBM qw(DB_File Storable);
use Fcntl;
our $VERSION = '1.02';


my %t_word;		# Tied word hash	1.01
my %word;		# Cached word hash - cached on demand when
			# new word occurs	1.01

my $hash_tied = 0;	# gets set to 1 when first used 1.01
my $path = "";

################################################################################
#
# hash arrays for tracking parts of verbs,nouns,adj and adv
# allows for lookups to the dictionary form from secondary forms 
#
################################################################################

my %infinitive_index;
my %past_index;
my %participle_index;
my %third_index;
my %gerund_index;
my %singular_index;
my %plural_index;
my %baseadj_index;
my %compadj_index;
my %superadj_index;
my %baseadv_index;
my %compadv_index;
my %superadv_index;

################################################################################
#
# Trackes whether the above hashes are loaded
#
################################################################################

my $indexes_loaded = 0;

################################################################################
#
# Flags for Conjunctions
#
################################################################################

my $C_COORD 	= 1;		# coordinating conjunctions 1.01
my $C_SUBORD	= 2;		# subordinating conjunctions 1.01

################################################################################
#
# Flags for Prepositions
#
################################################################################

my $PR_REGULAR 	= 1;		# Standard preposition 1.01
my $PR_ADVERB	= 2;		# Adverbal preposition 1.01 

################################################################################
#
# Flags for Adjectives and Adverbs 
#
################################################################################

my $A_BASE = 1;				# base form 1.01
my $A_COMPARATIVE = 2;		# comparative adjective 1.01
my $A_SUPERLATIVE = 4;		# superlative adjective 1.01

################################################################################
#
# Flags for Determiners
#
################################################################################

my $D_QUESTION 	= 	1;	# question/subordinate clause determiner 1.01
my $D_STANDALONE = 	2;	# standalone capable determiner 1.01
my $D_PLURAL	=	4;	# plural capable determiner 1.01
my $D_SINGULAR	=	8;	# singular capable determiner 1.01

################################################################################
#
# Flags for Pronouns
#
################################################################################

my $PN_FIRST		= 1;		# first person 1.01
my $PN_SECOND		= 2;		# second person 1.01
my $PN_THIRD 		= 4;		# third person 1.01
my $PN_SINGULAR 	= 8;		# singular 1.01
my $PN_PLURAL		= 16;		# plural 1.01
my $PN_MASCULINE	= 32;		# masculine 1.01
my $PN_FEMININE		= 64;		# feminine 1.01
my $PN_NEUTER 		= 128;		# neuter 1.01
my $PN_NOMINATIVE	= 1 << 8;	# nominative 1.01
my $PN_ACCUSATIVE	= 2 << 8;	# accusative 1.01
my $PN_GENITIVE		= 4 << 8;	# genitive 1.01
my $PN_PERSON		= 8 << 8;	# person 1.01
my $PN_PLACE		= 16 << 8;	# place 1.01
my $PN_THING		= 32 << 8;	# thing 1.01
my $PN_REFLEXIVE	= 64 << 8;	# reflexive 1.01
my $PN_QUESTION 	= 128 << 8;	# question word 1.01
my $PN_ADJECTIVAL	= 1 << 16;	# acts as an adjective, my, your 1.01
my $PN_STANDALONE	= 2 << 16;	# can be free standing 1.01

################################################################################
#
# Flags for the noun 
#
################################################################################

my $N_NUMBERLESS	= 1;	# Number not an issue or either 1.01
my $N_SINGULAR		= 2;	# 1.01
my $N_PLURAL		= 4;	# 1.01
my $N_PROPER		= 8;	# 1.01
my $N_STARTER		= 16;	# Can start a Subject 1.01
my $N_MASCULINE		= 32;	# Gender most useful in tracking agreement 1.01
my $N_FEMININE		= 64;	# between Pronouns and Nouns 1.01
my $N_NEUTER		= 128;	# 1.01

################################################################################
#
# Flags for the verb
#
################################################################################

my $V_INFINITIVE	= 1;	# general verb flags 1.01
my $V_PAST		= 2;	# 1.01
my $V_PARTICIPLE	= 4;	# 1.01
my $V_THIRD		= 8;	# third person sing present 1.01
my $V_GERUND		= 16;	# 1.01
my $V_PRESENT		= 32;	# all other present forms 1.01
my $V_STARTER		= 64;	# can start a verb structure 1.01

################################################################################
#
# Flags for Tracking Person implied by word 
# Used to track agreement between verbs and nouns.
# Used with verb_persons() and noun_persons().
#
################################################################################

my $P_1PS	= 1;		# First Person Singular 1.01
my $P_2PS	= 2;		# Second Person Singular 1.01
my $P_3PS	= 4;		# Third Person Singular 1.01
my $P_1PP	= 8;		# First Person Plural 1.01
my $P_2PP	= 16;		# Second Person Plural 1.01
my $P_3PP	= 32;		# Third Person Plural 1.01
my $P_ALL 	= $P_1PS | $P_2PS | $P_3PS | $P_1PP | $P_2PP | $P_3PP; # 1.01  

################################################################################
#
# Constructor for Word 
#
################################################################################

sub new { # ver 1.02

    my $class = shift;
    my $self = {};

    bless ($self,$class);
    
    # find out where the data is
    if ($path eq "") { get_path() }

    # Load referencing indexes
    &load_indexes() if (!$indexes_loaded);
    
    # Make sure hash tied
    if (!$hash_tied) { tie_hash() }
    
    # load current word info, otherwise
    # can be loaded later with a call to
    # text() method
    $self->text(shift) if @_;

    # establish most likely parts of speech this word assumes
    $self->prioritize();
    
    return $self;
}

################################################################################
#
# Get/Set the Text for this word.  This will be the element
# that governs all other reads or writes to this object
# 1.01
# 1.02 added expression test CJM 1/20/2002
#
################################################################################

sub text { # ver 1.02

    my ($self,$T) = @_;
    
    # Text can be sent in to set the text or, in enclosed in the normal
    # regular expression slashes (//) can be used to test to see if this word
    # matches the regular expressions.  If a regular expression is sent in
    # the return is boolean, otherwise the text of the current string.
    # NOTE: expression being sent in must be single quoted!!!
    if (defined $T) {

        # is it a regular expression?
        if ($T =~ /^\//) {

            # clean off slashes
            $T =~ s/^\///;
            $T =~ s/\/$//;

            # return results of the matching test
            return $self->{Text} =~ /$T/;
        }
        # not a regular expression - just set the text
        else { $self->{Text} = $T }
    }
    
    # Make sure record loaded from TIE hash into active local hash
    $self->load_tie();

    # return text of word
    return $self->{Text};
}

################################################################################
#
# get the path value form the local system.dat file
#
################################################################################

sub get_path { # 1.02

    my $L;
    my @F;

    # only load $path if needed
    if ($path eq "") {

        # try to open the local system.dat
        if (!(open F,"system.dat")) {

            # system.dat not local, hope data in local directory
            print "system.dat not found, defaulting to local directory\n";
            $path = './';
        }
        else {

            # look for the path entry
            while ($L = <F>) {

                # clean off the \n
                chomp $L;

                # clean out any spaces
                $L =~ s/\s//g;

                # pull the record apart
                @F = split /\=/,$L;

                # compare label on lowercase
                $F[0] = lc $F[0];

                # if this is the path line, use it and leave
                if ($F[0] eq "path") {

                    $path = $F[1];

                    # make sure path ends with slash
                    if (!($path =~ /\/$/)) { $path .= '/' }

                    # all done
                    last;
                }
            } 
        }
    }
}

################################################################################
#
# Cache the tie hash into the local hash if the word exists
#
################################################################################

sub load_tie { # ver 1.02

    my $self = shift;

    # $W is the string of the object
    my $W = $self->{Text};
    
    # does the string exist in the local hash '$word' 
    if (!exists $word{$W}) {

        # doesn't exist in $word, is it in the tie hash t_word?
        if (exists $t_word{$W}) {

            # yes, load it in from the tie hash
            $word{$W} = $t_word{$W};
        }
        else {
            # no, use the default - unknown
            print "Word: ",$W," not found, using -unknown- instead\n";
            $W = "unknown";
            $self->{Text} = $W;

            # load it in from the tie hash
            $word{$W} = $t_word{$W};
        }
    }
}

################################################################################
#
# Routines to load hashes used to find dictionary form or
# sub forms of a given word.  Used for Nouns to know the 
# plural or singular, Verbs to get between the Inf, Part,
# Past, Pres, and Gerund forms, Adjectives and Adverbs
# to move between the comparative and superlative forms
#
################################################################################

sub load_indexes { # ver 1.02

    # var to hold scratch array pointer
    my $A;	
    
    # open the file of verb parts
    open F,$path."verb.txt" || die "could not open $path"."verb.txt\n";

    # process the file
    while (<F>) {
        chomp;

        # allocate new array
        $A = [];

        # and shove the verb parts into it
        @$A = split /,/;

        # load hash table indexes for each
        # part of the verb
        $infinitive_index{$A->[0]} = $A;
        $past_index{$A->[1]} = $A;
        $participle_index{$A->[2]} = $A;
        $third_index{$A->[3]} = $A;
        $gerund_index{$A->[4]} = $A;
    }
    close F;
    
    # open file of noun parts
    open F,$path."noun.txt" || die "could not open $path"."noun.txt\n";

    # process nouns
    while (<F>) {
        chomp;

        # get new array for noun
        $A = [];

        # and shove the verb parts into it
        @$A = split /,/;

        # load hash table indexes for each
        # part of the verb
        $singular_index{$A->[0]} = $A;
        $plural_index{$A->[1]} = $A;
    }
    close F;
    
    # open file of adjective parts
    open F,$path."adjective.txt" || die "could not open $path"."adjective.txt\n";

    # process adjectives
    while (<F>) {
        chomp;
       
        # allocate array 
        $A = [];

        # and shove the verb parts into it
        @$A = split /,/;

        # load hash table indexes for each
        # part of the verb
        $baseadj_index{$A->[0]} = $A;
        $compadj_index{$A->[1]} = $A;
        $superadj_index{$A->[2]} = $A;
    }
    close F;
    
    # Open file of adverb parts
    open F,$path."adverb.txt" || die "could not open $path"."adverb.txt\n";

    # Process adverbs
    while (<F>) {
        chomp;

        # Allocate array for adverb
        $A = [];

        # and shove the verb parts into it
        @$A = split /,/;

        # load hash table indexes for each
        # part of the verb
        $baseadv_index{$A->[0]} = $A;
        $compadv_index{$A->[1]} = $A;
        $superadv_index{$A->[2]} = $A;
    }
    close F;
    
    # indicate indexes loaded
    $indexes_loaded = 1;
}

################################################################################
#
# Delete the word record for the current object
#
################################################################################

sub delete_word { # ver 1.02

    my $self = shift;
    my $W = $self->{Text};
    
    # delete from the main word hash and the tie hash
    delete $word{$W};
    delete $t_word{$W};
}

################################################################################
#
# Makes an array of prioritized parts of speech for the word
# based on the BNC frequency count
#
################################################################################


sub prioritize { # ver 1.02

    my $self = shift;

    # hash of POS => frequencies
    my %H;

    # scratch var for keys of %H
    my $K;

    # get the frequencies for each Part of Speech for the word
    if ($self->noun()) { $H{Noun} = $self->noun_freq() }
    if ($self->verb()) { $H{Verb} = $self->verb_freq() }
    if ($self->adjective()) { $H{Adjective} = $self->adjective_freq() }
    if ($self->adverb()) { $H{Adverb} = $self->adverb_freq() }
    if ($self->modal()) { $H{Modal} = $self->modal_freq() }
    if ($self->pronoun()) { $H{Pronoun} = $self->pronoun_freq() }
    if ($self->determiner()) { $H{Determiner} = $self->determiner_freq() }
    if ($self->preposition()) { $H{Preposition} = $self->preposition_freq() }
    if ($self->conjunction()) { $H{Conjunction} = $self->conjunction_freq() }
    
    # allocate an array to hold the ordered POS priorities based on
    # frequency
    $self->{Priority} = [];
    
    # sort the POS names by the frequency held in their element
    foreach $K (sort { $H{$a} <=> $H{$b} } keys %H) {
        push @{$self->{Priority}},$K; 
    }

    # reverse it
    @{$self->{Priority}} = reverse @{$self->{Priority}};
    
    # return the reference to the priority array held in $self
    return $self->{Priority};
}

################################################################################
#
# return 1st, 2nd, 3rd etc. choice for part of speech
# based on BNC using the prioritized array from prioritize()
# Takes a number as the arg (0|1|2) etc, and returns the string
# of the POS that would be the first, second, third etc choise.
#
################################################################################

sub choice ($) { # ver 1.02

    my $self = shift;
    my $choice = shift;

    # if choice is out of range, return ""
    if ($choice > @{$self->{Priority}}) { return "" };
    
    # otherwise return string of POS
    return @{$self->{Priority}}->[$choice - 1];
}

################################################################################
#
# Part of Speech Section 
#
# The following routines can be used as boolean tests for the part of
# speech of a word.  They return the flag set for the word, which will
# be a positive number (flags must be designed so that at least 1 flag
# is always set) if the word is the requested part of speech.  In this
# way an entire flag set can be gotten into an integer if desired.  
# The entire flag set can also be set by sending the appropriate settings
# into the function as the first argument.
#
################################################################################


################################################################################
#
# Basic frame for getting the part of speech.  Called by other part of
# speech functions, like noun, verb, etc.  Not intended to be called 
# directly itself.
#
################################################################################


sub part_of_speech { # ver 1.02

    # name of flag set to use
    my $F = shift;
    my $self = shift;	

    # $W is text of word
    my $W = $self->{Text};
    
    # was an integer flag set sent in as a further argument
    if (@_) {

        # Set the new flags
        $word{$W}->{$F} = shift;

        # Update the Tied hash
        $t_word{$W} = $word{$W};
    }

    # return the flag set if it exists otherwise 0.  This is a test for
    # whether something is a given POS or not
    if (exists $word{$W}->{$F}) { return $word{$W}->{$F} }
    else { return 0 }
}

################################################################################
#
# The part of speech methods call the part_of_speech function listed above with
# an argument indicating which flag bank to set/read. 
#
################################################################################


sub noun { # ver 1.02
    return part_of_speech ("Noun_Flags",@_);
}

sub verb { # ver 1.02
    return part_of_speech ("Verb_Flags",@_);
}

sub adjective { # ver 1.02
    return part_of_speech ("Adjective_Flags",@_);
}

sub adverb { # ver 1.02
    return part_of_speech ("Adverb_Flags",@_);
}

sub modal { # ver 1.02
    return part_of_speech ("Modal_Flags",@_);
}

sub pronoun { # ver 1.02
    return part_of_speech ("Pronoun_Flags",@_);
}

sub preposition { # ver 1.02
    return part_of_speech ("Preposition_Flags",@_);
}

sub determiner { # ver 1.02
    return part_of_speech ("Determiner_Flags",@_);
}

sub conjunction { # ver 1.02
    return part_of_speech ("Conjunction_Flags",@_);
}

################################################################################
#
# Part of Speech Frequency Section 
#
# The following routines are use to get/set the frequency for the word
# when used as the requested part of speech.  By sending in a number as
# an argument, the frequency value can be updated.  In any case, the final
# frequency is returned as an integer.
#
################################################################################


################################################################################
#
# Basic frame for getting the frequency by POS type.  Called by other
# frequency functions, like noun_freq. Not intended to be called 
# directly itself.
#
################################################################################


sub frequency { # ver 1.02

    # which frequency field to work on
    my $F = shift;	

    my $self = shift;		

    # text of the word
    my $W = $self->{Text};	
    
    # set frequency if it was sent in
    if (@_) {	

        # Get the new frequency
        $word{$W}->{$F} = shift;

        # Update the Tied hash
        $t_word{$W} = $word{$W};
    }

    # return the frequency if it exists
    if (exists $word{$W}->{$F})	{ return $word{$W}->{$F} }
    else { return 0 }
}

################################################################################
#
# The frequency methods call the frequency function with
# an argument indicating which frequency to set/read. 
#
################################################################################


sub noun_freq { # ver 1.02
    return frequency ("Noun_Freq",@_);
}

sub verb_freq { # ver 1.02
    return frequency ("Verb_Freq",@_);
}

sub adjective_freq { # ver 1.02
    return frequency ("Adjective_Freq",@_);
}

sub adverb_freq { # ver 1.02
    return frequency ("Adverb_Freq",@_);
}

sub modal_freq { # ver 1.02
    return frequency ("Modal_Freq",@_);
}

sub pronoun_freq { # ver 1.02
    return frequency ("Pronoun_Freq",@_);
}

sub preposition_freq { # ver 1.02
    return frequency ("Preposition_Freq",@_);
}

sub determiner_freq { # ver 1.02
    return frequency ("Determiner_Freq",@_);
}

sub conjunction_freq { # ver 1.02
    return frequency ("Conjunction_Freq",@_);
}

sub present_freq { # ver 1.02
    return frequency ("Present_Freq",@_);
}

sub past_freq { # ver 1.02
    return frequency ("Past_Freq",@_);
}


################################################################################
#
# Flag Methods Section
#
# The following methods are used to get/set flags in the flag banks 
# for the various parts of speech.  
#
################################################################################


################################################################################
#
# Basic frame to get/set indivitual flags in the flag banks for the 
# various parts of speech.  Not intended to be called 
# directly
#
################################################################################


sub flags { # ver 1.02

    # name of flag bank to process
    my $FB = shift;

    # which flag to work on
    my $F = shift;

    my $self = shift;

    # text of the word to work on
    my $W = $self->{Text};
    
    # optional additiona arg: 0 - turn on and 1 - turn off
    if (@_) {

        # get the command to turn on/off
        my $S = shift;

        # if the flag bank doesn't exist yet init to 0
        if (!exists $word{$W}->{$FB}) { $word{$W}->{$FB} = 0 }

        # adjust flagbank based on $S
        $word{$W}->{$FB} = $S ? $word{$W}->{$FB} | $F : $word{$W}->{$FB} & ~$F;

        # update tied hash
        $t_word{$W} = $word{$W};
    }

    # return setting of flag in flag bank
    return $word{$W}->{$FB} & $F;
}


################################################################################
#
# Conjunction Flags 
#
################################################################################


sub coord_conjunction { # ver 1.02
    return flags("Conjunction_Flags",$C_COORD,@_);
}

sub subord_conjunction { # ver 1.02
    return flags("Conjunction_Flags",$C_SUBORD,@_);
}

################################################################################
#
# Preposition Flags
#
################################################################################


sub adverb_preposition { # ver 1.02
    return flags("Preposition_Flags",$PR_ADVERB,@_);
}


################################################################################
#
# Adjective Flags
# Adjectives and adverbs require a little extra work because
# of a unique three way flag setting.  When  one is turned on,
# the other two should be off.
#
################################################################################


sub comparative_adjective { # ver 1.02

    # if arg was sent in adjust flags
    if (@_ == 2) {  
      
        my $self = $_[0];

        # $S is either 1 or 0, turn on/off
        my $S = $_[1];

        # set flags
        if ($S) {
            # if setting comparative, turn off 
            # superaltive and base flags with call to flags
            flags("Adjective_Flags",$A_SUPERLATIVE,$self,0);
            flags("Adjective_Flags",$A_BASE,$self,0);
        } 
        else {
            # if clearing comparative, turn off superlative
            # and set base by default 
            flags("Adjective_Flags",$A_SUPERLATIVE,$self,0);
            flags("Adjective_Flags",$A_BASE,$self,1);
        }
    }

    # this will adjust the comparative flag as needed
    return flags("Adjective_Flags",$A_COMPARATIVE,@_);
}

sub superlative_adjective { # ver 1.02

    # if arg sent in, adjust flags
    if (@_ == 2) {  
        
        my $self = $_[0];

        # $S is 0 or 1 for turn on/off
        my $S = $_[1];
        if ($S) {
            # if setting superlative, turn off 
            # comparative and base flags with call to flags
            flags("Adjective_Flags",$A_COMPARATIVE,$self,0);
            flags("Adjective_Flags",$A_BASE,$self,0);
        } 
        else {
            # if clearing superlative, turn off comparative
            # and set base by default 
            flags("Adjective_Flags",$A_COMPARATIVE,$self,0);
            flags("Adjective_Flags",$A_BASE,$self,1);
        }
    }

    # this will adjust the comparative flag as needed
    return flags("Adjective_Flags",$A_SUPERLATIVE,@_);
}

sub base_adjective { # ver 1.02

    # if arg sent in, adjust flags
    if (@_ == 2) {  		

        my $self = $_[0];

        # base flag cannot be turned off since it is the
        # default.  If any arg is sent, base flag will be turned
        # on, comparative and superlative flags will be 
        # turned  off. 
        flags("Adjective_Flags",$A_COMPARATIVE,$self,0);
        flags("Adjective_Flags",$A_SUPERLATIVE,$self,0);

        return flags("Adjective_Flags",$A_BASE,$self,1);
    }
    
    # no argument was sent
    return flags("Adjective_Flags",$A_BASE,@_);
}

################################################################################
#
# Adverb Flags
# Adjectives and adverbs require a little extra work because
# of a unique three way flag setting.  When  one is turned on,
# the other two should be off.
#
################################################################################


sub comparative_adverb { # ver 1.02

    # if arg sent in, adjust flags
    if (@_ == 2) {  	

        my $self = $_[0];

        # $S is ether 0 or 1 for turn off/on
        my $S = $_[1];

        if ($S) {
            # if setting comparative, turn off 
            # superaltive and base flags with call to flags
            flags("Adverb_Flags",$A_SUPERLATIVE,$self,0);
            flags("Adverb_Flags",$A_BASE,$self,0);
        } 
        else {
            # if clearing comparative, turn off superlative
            # and set base by default 
            flags("Adverb_Flags",$A_SUPERLATIVE,$self,0);
            flags("Adverb_Flags",$A_BASE,$self,1);
        }
    }

    # this will adjust the comparative flag as needed
    return flags("Adverb_Flags",$A_COMPARATIVE,@_);
}

sub superlative_adverb { # ver 1.02

    # if arg sent in, adjust flags
    if (@_ == 2) {  		

        my $self = $_[0];

        # $S is either 0 or 1 for turn off/on
        my $S = $_[1];
        if ($S) {
            # if setting superlative, turn off 
            # comparative and base flags with call to flags
            flags("Adverb_Flags",$A_COMPARATIVE,$self,0);
            flags("Adverb_Flags",$A_BASE,$self,0);
        } 
        else {
            # if clearing superlative, turn off comparative
            # and set base by default 
            flags("Adverb_Flags",$A_COMPARATIVE,$self,0);
            flags("Adverb_Flags",$A_BASE,$self,1);
        }
    }

    # this will adjust the comparative flag as needed
    return flags("Adverb_Flags",$A_SUPERLATIVE,@_);
}

sub base_adverb { # ver 1.02

    # if arg sent in, adjust flags
    if (@_ == 2) { 

        my $self = $_[0];

        # base flag cannot be turned off since it is the
        # default.  If any arg is sent, base flag will be turned
        # on, comparative and superlative flags will be 
        # turned  off. 
        flags("Adverb_Flags",$A_COMPARATIVE,$self,0);
        flags("Adverb_Flags",$A_SUPERLATIVE,$self,0);
        return flags("Adverb_Flags",$A_BASE,$self,1);
    }
    
    # no argument was sent
    return flags("Adverb_Flags",$A_BASE,@_);
}

################################################################################
#
# Determiner Flags
#
################################################################################

sub singular_determiner { # ver 1.02
    return flags("Determiner_Flags",$D_SINGULAR,@_);
}

sub plural_determiner { # ver 1.02
    return flags("Determiner_Flags",$D_PLURAL,@_);
}

sub standalone_determiner { # ver 1.02
    return flags("Determiner_Flags",$D_STANDALONE,@_);
}

sub question_determiner { # ver 1.02
    return flags("Determiner_Flags",$D_QUESTION,@_);
}

################################################################################
#
# Pronoun Flags
#
################################################################################


sub first_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_FIRST,@_);
}

sub second_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_SECOND,@_);
}

sub third_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_THIRD,@_);
}

sub singular_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_SINGULAR,@_);
}

sub plural_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_PLURAL,@_);
}

sub masculine_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_MASCULINE,@_);
}

sub feminine_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_FEMININE,@_);
}

sub neuter_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_NEUTER,@_);
}

sub nominative_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_NOMINATIVE,@_);
}

sub accusative_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_ACCUSATIVE,@_);
}

sub genitive_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_GENITIVE,@_);
}

sub person_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_PERSON,@_);
}

sub place_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_PLACE,@_);
}

sub thing_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_THING,@_);
}

sub reflexive_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_REFLEXIVE,@_);
}

sub question_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_QUESTION,@_);
}

sub adjectival_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_ADJECTIVAL,@_);
}

sub standalone_pronoun { # ver 1.02
    return flags("Pronoun_Flags",$PN_STANDALONE,@_);
}

################################################################################
#
# Noun Flags
#
################################################################################


sub singular_noun { # ver 1.02
    return flags("Noun_Flags",$N_SINGULAR,@_);
}

sub plural_noun { # ver 1.02
    return flags("Noun_Flags",$N_PLURAL,@_);
}

sub numberless_noun { # ver 1.02
    return flags("Noun_Flags",$N_NUMBERLESS,@_);
}

sub proper_noun { # ver 1.02
    return flags("Noun_Flags",$N_PROPER,@_);
}

sub masculine_noun { # ver 1.02
    return flags("Noun_Flags",$N_MASCULINE,@_);
}

sub feminine_noun { # ver 1.02
    return flags("Noun_Flags",$N_FEMININE,@_);
}

sub neuter_noun { # ver 1.02
    return flags("Noun_Flags",$N_NEUTER,@_);
}

sub starter_noun { # ver 1.02
    return flags("Noun_Flags",$N_STARTER,@_);
}

################################################################################
#
# Verb Flags
#
################################################################################


sub infinitive_verb { # ver 1.02
    return flags("Verb_Flags",$V_INFINITIVE,@_);
}

sub past_verb { # ver 1.02
    return flags("Verb_Flags",$V_PAST,@_);
}

sub participle_verb { # ver 1.02
    return flags("Verb_Flags",$V_PARTICIPLE,@_);
}

sub third_verb { # ver 1.02
    return flags("Verb_Flags",$V_THIRD,@_);
}

sub gerund_verb { # ver 1.02
    return flags("Verb_Flags",$V_GERUND,@_);
}

sub present_verb { # ver 1.02
    
    # 1.02 added V_THRID - CM
    return flags("Verb_Flags",$V_PRESENT | $V_THIRD,@_);
}

sub starter_verb { # ver 1.02
    return flags("Verb_Flags",$V_STARTER,@_);
}

################################################################################
#
# Dictionary Section
# Dictionary entries returned for Noun (singular form), Verb (infinitive)
# Adjectives and Adverbs (base, not comparative or superlative)
# Used where dictionary form may be different from the word's appearance
# in the sentence.
#
################################################################################


################################################################################
#
# Simple dialog to get and verify word with a prompt
#
################################################################################

sub get_word { # ver 1.02
    my $prompt = shift;
    my $got_it = 0;
    my $W;
    my $R;
    
    while (!$got_it) {
        print "$prompt: ";
        $W = <>;
        chomp $W;
        print "$W correct? (y/n/q): ";
        $R = <>;
        chomp $R;
        if ($R =~ /^(y|Y)$/) { $got_it = 1 }
        elsif ($R =~ /^(q|Q)$/) {
            $got_it = 1;
            $R = "";
        }
    }
    return $R;
}

################################################################################
#
# revised and improved dictionary lookup using verb.txt
# noun.txt, adjective.txt and adverb.txt
# and crossreferencing hashes 1.02 CJM 1/18/2002
#
################################################################################


sub noun_dictionary { # ver 1.02

    my $self = shift;

    # N is the text
    my $N = $self->text();
    
    # use the cross reference index if this is a plural
    if ($self->plural_noun()) {

        # if it exists return the dictionary form, else ""
        if (exists $plural_index{$N}) { return $plural_index{$N}->[0] }
        else { return "" }
    }
    # Singular form is the dictionary form
    else { return $self->text() } 
}



################################################################################
#
# Verb forms are special in that the infinitive returned depends
# on both the text of the word and the part of the verb that it is.
# Thus 'found' could return found or find, depending on whether
# it is an infintive (to found a university) or a participle
# for find (I have found it).  If no arg is given for verb part,
# it will return the first infinitive that it finds.  
# Possible forms are: Infintive, Past, Participle, Third, Gerund
#
################################################################################

sub verb_dictionary { # ver 1.02
    my $self = shift;
    my $V = $self->text();
    my $form;
    
    # get the form of the verb we are checking if entered
    if (@_) { $form = shift } 
    
    # catch the 'to be' debacle
    if ($V =~ /^(am|is|are|was|were|be|being|been)$/) { return "be" }
    
    # lookup based on specific form passed in
    elsif (defined $form) { 
        if ($form eq "Infinitive" && exists $infinitive_index{$V}){ 
            return $infinitive_index{$V}->[0]; 
        }
        elsif ($form eq "Past" && exists $past_index{$V}) { 
            return $past_index{$V}->[0];
        }
        elsif ($form eq "Participle" && exists $participle_index{$V}) { 
            return $participle_index{$V}->[0];
        }
        elsif ($form eq "Third"  && exists $third_index{$V}) { 
            return $third_index{$V}->[0];
        }
        elsif ($form eq "Gerund" && exists $gerund_index{$V}) { 
            return $gerund_index{$V}->[0];
        }
        else { return "" } # couldn't find it 
    }
    
    # use cross referencing hashes for anything else
    # this usually works, but it is safest to specify
    # the incoming form and use the code above
    
    # the infinitive is the dictionary form
    elsif ($self->infinitive_verb()) { return $V }

    # use the indexes elsewhere
    elsif (exists $past_index{$V}) { return $past_index{$V}->[0] }
    elsif (exists $participle_index{$V}) { 
        return $participle_index{$V}->[0];
    }
    elsif (exists $third_index{$V}) { return $third_index{$V}->[0] }
    elsif (exists $gerund_index{$V}) { return $gerund_index{$V}->[0] }
    else { return "" }	# couldn't find anything
}

sub adjective_dictionary { # ver 1.02

    my $self = shift;
    my $A = $self->text();
    
    # just use cross references on comparative or superlative.
    if ($self->comparative_adjective()) {
        if (exists $compadj_index{$A}) { return $compadj_index{$A}->[0] }
        else { return "" }
    }
    elsif ($self->superlative_adjective()) {
        if (exists $superadj_index{$A}) { return $superadj_index{$A}->[0] }
        else { return "" }
    }
    elsif ($self->base_adjective()) { return $A }
    else { return "" }
}

sub adverb_dictionary { # ver 1.02

    my $self = shift;
    my $A = $self->text();
    
    # just use cross references on comparative or superlative.
    if ($self->comparative_adverb()) {
        if (exists $compadv_index{$A}) { return $compadv_index{$A}->[0] }
        else { return "" }
    }
    elsif ($self->superlative_adverb()) {
        if (exists $superadv_index{$A}) { return $superadv_index{$A}->[0] }
        else { return "" }
    }
    elsif ($self->base_adverb()) { return $A }
    else { return "" }
}

################################################################################
#
# Persons Section
# Routines designed to indicate what persons (1st singular, 3rd plural,
# etc) a given noun, pronoun or verb is indicating.  Returns the 
# possibilities in the form of a common set of integer flags that can be
# 'anded' together to see where possible subject/verb agreement
# exists.
#
################################################################################


sub noun_persons { # ver 1.02
    my $self = shift;
    
    # nouns by themselves will always be 3rd person
    # numberless nouns can be both
    return $P_3PS | $P_3PP if $self->numberless_noun();

    # singular and proper nouns are singular
    return $P_3PS if $self->singular_noun() || $self->proper_noun();

    # plural nouns are plural
    return $P_3PP if $self->plural_noun();
}

sub pronoun_persons { # ver 1.02

    my $self = shift;
    
    # if pronoun can be used in singular or plural
    if ($self->plural_pronoun() && $self->singular_pronoun()) {
        return $P_1PS if $self->first_pronoun();
        return $P_2PS if $self->second_pronoun();

        return $P_3PS if $self->third_pronoun();
    } 
    elsif ($self->singular_pronoun()) {
        return $P_1PS if $self->first_pronoun();
        return $P_2PS if $self->second_pronoun();
        return $P_3PS if $self->third_pronoun();
    } 
    elsif ($self->plural_pronoun()) {
        return $P_1PP if $self->first_pronoun();
        return $P_2PP if $self->second_pronoun();
        return $P_3PP if $self->third_pronoun();
    } 
    else { return 0 }
}

sub verb_persons { # ver 1.02

    my $self = shift;

    # text of word
    my $W = $self->{Text};
    
    # if not a verb anyway return 0
    return 0 if !$self->verb();

    # get the abnormal 'be' word handled
    return $P_1PS if $W eq "am";
    return $P_2PS | $P_2PP | $P_1PP | $P_3PP if $W eq "are";
    return $P_3PS if $W eq "is";
    return $P_1PS | $P_3PS if $W eq "was";
    return $P_2PS | $P_2PP | $P_1PP | $P_3PP if $W eq "were";

    # 1.02 fixed order of  final checks, 3rd must come first
    # since it is also present tense CJM 
    # 3rd singular persons 1/17/2000
    if ($self->third_verb()) {
        return $P_3PS;
    }
    # Present except for 3rd
    elsif ($self->present_verb()){
        return $P_ALL & ~$P_3PS;
    }
    # Past persons
    elsif ($self->past_verb()) {
        return $P_ALL;
    }
}

################################################################################
#
# added to make it easy for modal verbs to set persons
# 1.02 CJM 1/16/2002
#
################################################################################

sub modal_persons { # ver 1.02
    return $P_ALL; # Simple modals don't have extra froms
}

################################################################################
#
# Support Routines Section
# Routines for loading and support the databases
#
################################################################################


################################################################################
#
# Called with first instance of a word to set up the
# tied hashes.
#
################################################################################

sub tie_hash { # ver 1.02
    
    # make sure path known
    get_path();

    no strict;
    tie %t_word,'MLDBM',$path."word.db", O_CREAT|O_RDWR,0666 || 
      die "could not tie $path"."word.db\n";
    use strict;
    
    # set hash to tied  
    $hash_tied = 1;	 
}

################################################################################
#
# The following four functions are used for importing/exporting 
# between a binary hash file and a text data file
#
################################################################################
 
sub bin2dec { # ver 1.02
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub dec2bin { # ver 1.02
    return unpack("B32", pack("N",shift));
}

################################################################################
#
# Import words from text database, word.txt, into binary, word.db
# 1.02 Added record level version field _Ver: CJM 1/14/2001
#
################################################################################

sub import_word { # ver 1.02
    my @F;
    my $L;
    my $C;
    my $K;
    
    # make sure data path known
    get_path();

    # make sure hash is tied to file
    &tie_hash if (!$hash_tied);
    
    # pregrab space in case this helps speed
    keys (%t_word) = 100000;
    
    # let it know we started
    print "Loading word.db from word.txt\n";

    # open the word.txt text file 
    open FILE,$path."word.txt" or die "Could not open file word.txt\n";

    # set the counter to 0
    $C = 0;

    # strict might have some problems with this
    no strict;

    # process file
    while ($L = <FILE>) {
        chomp $L;
        
        # split the line
        @F = split(/,/,$L);

        # load the t_word hash
        $t_word{$F[0]} = {	
           "Text" => $F[0],
            "_Ver" => $F[1],
            "Noun_Flags" => bin2dec($F[2]),
            "Verb_Flags" => bin2dec($F[3]),
            "Adjective_Flags" => bin2dec($F[4]),
            "Adverb_Flags" => bin2dec($F[5]),
            "Modal_Flags" => bin2dec($F[6]),
            "Pronoun_Flags" => bin2dec($F[7]),
            "Preposition_Flags" => bin2dec($F[8]),
            "Determiner_Flags" => bin2dec($F[9]),
            "Conjunction_Flags" => bin2dec($F[10]),
            "Noun_Freq" => $F[11],
            "Verb_Freq" => $F[12],
            "Adjective_Freq" => $F[13],
            "Adverb_Freq" => $F[14],
            "Modal_Freq" => $F[15],
            "Pronoun_Freq" => $F[16],
            "Preposition_Freq" => $F[17],
            "Determiner_Freq" => $F[18],
            "Conjunction_Freq" => $F[19],
            "Present_Freq" => $F[20],
            "Past_Freq" => $F[21]
        };
 
        # increment counter
        $C++;

        # provide some feedback during long load
        if (!($C % 200)) { print "$C records loaded\n" }
    }

    # turn strict back on
    use strict;

    close FILE;

} ### end of import_word

################################################################################
#
# Export words to text database, word.txt, from binary, word.db
# 1.02 Added record level version field _Ver: CJM 1/14/2001
#
################################################################################


sub export_word { # ver 1.02
    my $K;
    my $C;
    my $L;
    
    # make sure hash tied to file
    &tie_hash if (!$hash_tied);

    # open the word.txt text file for output
    open OUT,"> $path"."word.txt" || die "could not open file $path"."word.txt\n";
    
    # load the hash file into ram
    foreach $K (keys %t_word) { $word{$K} = $t_word{$K} }
    
    # dump Ram copy to file
    foreach $K (sort keys %word) {
        $L = $word{$K}->{Text};
        $L .= ",";
        $L .= $word{$K}->{_Ver};
        $L .= ",";
        if ($word{$K}->{Noun_Flags}){
            $L .= dec2bin($word{$K}->{Noun_Flags});
        } 
        $L .= ",";
        if ($word{$K}->{Verb_Flags}){
            $L .= dec2bin($word{$K}->{Verb_Flags}); 
        }
        $L .= ",";
        if ($word{$K}->{Adjective_Flags}){
            $L .= dec2bin($word{$K}->{Adjective_Flags}); 
        }
        $L .= ",";
        if ($word{$K}->{Adverb_Flags}){
            $L .= dec2bin($word{$K}->{Adverb_Flags});
        } 
        $L .= ",";
        if ($word{$K}->{Modal_Flags}){
            $L .= dec2bin($word{$K}->{Modal_Flags});
        } 
        $L .= ",";
        if ($word{$K}->{Pronoun_Flags}){
            $L .= dec2bin($word{$K}->{Pronoun_Flags});
        } 
        $L .= ",";
        if ($word{$K}->{Preposition_Flags}){
            $L .= dec2bin($word{$K}->{Preposition_Flags});
        } 
        $L .= ",";
        if ($word{$K}->{Determiner_Flags}){
            $L .= dec2bin($word{$K}->{Determiner_Flags});
        }
        $L .= ",";
        if ($word{$K}->{Conjunction_Flags}){
            $L .= dec2bin($word{$K}->{Conjunction_Flags});
        } 
        $L .= ",";
        if ($word{$K}->{Noun_Freq}){
            $L .= $word{$K}->{Noun_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Verb_Freq}){
            $L .= $word{$K}->{Verb_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Adjective_Freq}){
            $L .= $word{$K}->{Adjective_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Adverb_Freq}){
            $L .= $word{$K}->{Adverb_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Modal_Freq}){
            $L .= $word{$K}->{Modal_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Pronoun_Freq}){
            $L .= $word{$K}->{Pronoun_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Preposition_Freq}){
            $L .= $word{$K}->{Preposition_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Determiner_Freq}){
            $L .= $word{$K}->{Determiner_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Conjunction_Freq}){
            $L .= $word{$K}->{Conjunction_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Persent_Freq}){
            $L .= $word{$K}->{Present_Freq}; 
        }
        $L .= ",";
        if ($word{$K}->{Past_Freq}){
            $L .= $word{$K}->{Past_Freq}; 
        }

        # increment counter
        $C++;
         
        # provide some feedback if long export
        print "$C records exported\n" if ($C %200);

        # dump record out
        print OUT "$L\n";
    }
    
    close OUT;
    
    # give final tally
    print "$C records exported\n";
}


1;
__END__

=head1 NAME

Harvey::Word - Perl extension for creating word objects

=head1 SYNOPSIS

  use Harvey::Word;
  my $W = Word->new("grape");

    Word object module for Harvey.  Looks up information on
    a word for all forms and gives information to calling objects.

    Version 1.02 Overhauled and improved word.txt/word.db database.
    Added better cross referencing to move between verb, noun, adj and
    adverb forms.

=head1 DESCRIPTION

  The purpose of the Word module is to create Word objects that can be 
  queried for syntactic information about the word.

    Version 1.01, words can be queried for their dictionary form, part 
    of speech, many attributes on the basis of the part of speech, 
    frequency, what persons are possible, i.e. 1st singular, 3rd plural, 
    etc., and the likeliest parts of speech that the word could be based 
    on the frequencies in the BNC.

    Most methods which return a characteristic of the word can also be 
    used to turn on or off the characteristic by passing a 0 or 1 for
    boolean flags, text for text queries and numbers for the frequency.

    The data is used from a TIE hash database, but can be exported/imported
    from the ASCII file word.txt using the export_word and import_word 
    functions.  

  The following methods are supported:

    new: 	Constructor.
    text: 	Get the text of the word. Version 1.02 - added the ability
                to pass in a standard expression for pattern matching
                against the text of the object, in which case a boolean
                is returned.
    load_tie:	Load a word record from the TIE hash (%t_word) into the 
    		memory hash (%word). Done automatically from the constructor.
    prioritize: Returns an ordered array of the most likely parts of speech
		for a given word based on the BNC frequency counts.
    choice:	Returns an array of strings of the most likely POS choices 
                for a word object based on BNC freqeuncy counts.
    noun:	Retuns the noun flags if the word is a noun, otherwise 0.  Can
		be used as a boolean test for whether the word can be a noun, 
		but also can set or retieve the noun flags for a word, which are
		stored as bytes in an integer.  To set the flags, send in an 
		integer as the argument.  	
    verb:	Same as noun, but for verbs.
    adjective:	Same as noun, but for adjectives.
    adverb:	Same as noun, but for adverbs.
    modal:	Same as noun, but for modals.
    pronoun:	Same as noun, but for pronouns.
    preposition:	Same as noun, but for prepositions.
    determiner:	Same as noun, but for determiners.
    conjunction:	Same as noun, but for conjunctions.
    noun_freq:	Gets/set the noun frequency.
    verb_freq:	Gets/set the verb frequency.
    adjective_freq:	Gets/set the adjective frequency.
    adverb_freq:	Gets/set the adverb frequency.
    modal_freq:	Gets/set the modal frequency.
    pronoun_freq:	Gets/set the pronoun frequency.
    preposition_freq:	Gets/set the preposition frequency.
    delete_word: Destroy the current word object
    determiner_freq:	Gets/set the determiner frequency.
    conjunction_freq:	Gets/set the conjunction frequency.
    coord_conjunction: 	Gets/set coordinating flag for conjunctions.
    subord_conjunction: 	Gets/set subordinating flag for conjunctions.
    adverb_preposition:	Gets/set whether preposition can be used 
    			alone as adverb.
    base_adjective:	Gets/set base flag for adjectives.
    comparative_adjective:	Gets/set comparative flag for adjectives.
    superlative_adjective:	Gets/set superlative flag for adjectives.
    base_adverb:	Gets/set base adverb flag.
    comparative_adverb:	Gets/set comparative adverb flag.
    superlative_adverb:	Gets/set superlative adverb flag.
    singular determiner: 	Gets/set singular flag for determiners.
    plural_determiner:	Get/set plural flag for determiners.
    standalone_determiner:	Get/set standalone flag for determiners.
    question_determiner:	Get/set question flag for determiners.
    first_pronoun:	Get/set first person flag for pronouns.
    second_pronoun:	Get/set second person flag for pronouns.
    third_pronoun:	Get/set third person flag for pronouns.
    singular_pronoun:	Get/set singular flag for pronouns.
    plural_pronoun:	Get/set plural flag for pronouns.
    masculine_pronoun:	Get/set masculine flag for pronouns.
    feminine_pronoun:	Get/set feminine flag for pronouns.
    neuter_pronoun:	Get/set neuter flag for pronouns.
    nominative_pronoun:	Get/set nominative flag for pronouns.
    accusativey_pronoun:	Get/set accusative flag for pronouns.
    genitive_pronoun:	Get/set genitive flag for pronouns.
    person_pronoun:	Get/set person flag for pronouns.
    place_pronoun:	Get/set place flag for pronouns.
    thing_pronoun:	Get/set thing flag for pronouns.
    reflexive_pronoun:	Get/set reflexive flag for pronouns.
    question_pronoun:	Get/set question flag for pronouns.
    adjectival_pronoun:	Get/set adjectival flag for pronouns: our your
    standalone_pronoun:	Get/set standalone flag for pronouns: ours yours
    singular_noun:	Get/set singular flag for nouns.
    plural_noun:	Get/set plural flag for nouns.
    numberless_noun:	Get/set numberless flag for nouns.
    proper_noun:	Get/set proper flag for nouns.
    masculine_noun:	Get/set masculine flag for nouns.
    feminine_noun:	Get/set feminine flag for nouns.
    neuter_noun:	Get/set neuter flag for nouns.
    starter_noun:	Get/set starter flag for nouns.
    infinitive_verb:	Get/set infinitive flag for verbs.
    past_verb:	Get/set infinitive flag for verbs.
    participle_verb:	Get/set infinitive flag for verbs.
    third_verb:	Get/set infinitive flag for verbs.
    gerund_verb:	Get/set infinitive flag for verbs.
    present_verb:	Get/set infinitive flag for verbs.
    starter_verb:	Get/set infinitive flag for verbs.
    noun_dictionary:	Get/set dictionary form for a noun, ie. singular.
    verb_dictionary:	Get/set dictionary form for a verb, ie. infinitive,
                        1.02 added argument to verb_dictionary.  Pass in
                        the verb part (Present|Past|Third|Infinitive|Gerrund
                        |Participle) to determine the most likely infinitive.
    adjective_dictionary: Get/set dictionary form for a adjective i.e. base
    adverb_dictionary:	Get/set dictionary form for a adverb, i.e. base form
    noun_persons:	Returns the possible persons for a noun.  The 'persons'
			functions return an Integer with the possible persons
			(i.e. first singular, second plural, etc) stored as
			bits.  This makes it easy to check for Subject verb
			agreement or pronoun/noun agreement by 'anding' the
			flags together.
    pronoun_persons:	Returns the possible persons for a pronoun.
    verb_persons:	Returns the possible persons for a verb.
    modal_persons:  Added with 1.02 since modals have slightly different
                    person patterns, e.g. can as a modal works with 'he',
                    while can as a verb does not.
    tie_hash:	Ties the hash, %t_word to the file dic/word.db.	
    import_word:	Builds the hash TIE file 'dic/word.db' from
			the text file 'word.txt'.
    export_word:	Exports data from the TIE file 'dic/word.db' 
			to the text file 'word.txt'.

=head2 EXPORT

None by default.


=head1 AUTHOR

Chris Meyer, E<lt>chris@mytechs.comE<gt> www.mytechs.com

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

L<perl>.

=cut
