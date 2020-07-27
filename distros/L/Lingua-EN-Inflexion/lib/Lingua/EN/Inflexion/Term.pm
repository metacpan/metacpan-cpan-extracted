package Lingua::EN::Inflexion::Term;

use 5.010; use warnings; use Carp;
no if $] >= 5.018, warnings => "experimental::smartmatch";
use strict;

use Hash::Util 'fieldhash';

fieldhash my %term_of;

# Inside-out constructor...
sub new {
    my ($class, $term) = @_;

    my $object = bless do{ \my $scalar }, $class;

    $term_of{$object} = $term // croak "Missing arg to $class ctor";

    return $object;
}

# Replicate casing...
my $encase = sub {
    my ($original, $target) = @_;

    # Special case for 'I'
    return $target if $original eq 'I' || $target eq 'I';

    # Construct word-by-word case transformations...
    my @transforms
        = map { /\A[[:lower:][:^alpha:]]+\Z/            ? sub { lc shift }
              : /\A[[:upper:]][[:lower:][:^alpha:]]+\Z/ ? sub { ucfirst lc shift }
              : /\A[[:upper:][:^alpha:]]+\Z/            ? sub { uc shift }
              :                                           sub { shift }
              }
          split /\s+/, $original;

    if (!@transforms) {
        @transforms = sub {shift};
    }

    # Apply to target...
    $target =~ s{(\S+)}
                { my $transform = @transforms > 1 ? shift @transforms : $transforms[0];
                  $transform->($1);
                }xmseg;

    return $target;
};

# Report part-of-speech...
sub is_noun { 0 }
sub is_verb { 0 }
sub is_adj  { 0 }

# Default classical/unassimilated mode does nothing...
sub classical     { return shift; }
sub unassimilated { return shift->classical; }

# Coerce to original...
use Scalar::Util qw< refaddr blessed >;
use overload (
    q[qr]   => sub { return shift->as_regex();   },
    q[""]   => sub { return "$term_of{shift()}"; },
    q[0+]   => sub { return refaddr(shift);      },
    q[bool] => sub { return 1;                   },
    q[${}]  => sub { croak "Can't coerce ", ref(shift), ' object to scalar reference'; },
    q[@{}]  => sub { croak "Can't coerce ", ref(shift), ' object to array reference'; },
    q[%{}]  => sub { croak "Can't coerce ", ref(shift), ' object to hash reference'; },
    q[&{}]  => sub { croak "Can't coerce ", ref(shift), ' object to subroutine reference'; },
    q[*{}]  => sub { croak "Can't coerce ", ref(shift), ' object to typeglob reference'; },

    q[~~] => sub {
                my ($term, $other_arg) = @_;

                # Handle TERM ~~ TERM...
                if (blessed($other_arg) && $other_arg->isa(__PACKAGE__)) {
                    return lc($term->singular)          eq lc($other_arg->singular)
                        || lc($term->plural)            eq lc($other_arg->plural)
                        || lc($term->classical->plural) eq lc($other_arg->classical->plural);
                }

                # Otherwise just smartmatch against TERM as regex....
                else {
                    return $other_arg ~~ $term->as_regex;
                }
             },


    fallback => 1,
);

# Treat as regex...
sub as_regex {
    my ($self) = @_;
    my %seen;
    my $pattern = join '|', map { quotemeta } reverse sort grep { !$seen{$_}++ }
                  ($self->singular, $self->plural, $self->classical->plural);
    return qr{$pattern}i;
}


package Lingua::EN::Inflexion::Noun;
our @ISA = 'Lingua::EN::Inflexion::Term';

use Lingua::EN::Inflexion::Nouns;
use Lingua::EN::Inflexion::Indefinite;

# Report number of the noun...
sub is_plural   {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Nouns::is_plural( $term_of{$self} );
}

sub is_singular {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Nouns::is_singular( $term_of{$self} );
}

# Report part-of-speech...
sub is_noun { 1 }

# Return plural and singular forms of the noun...

my %noun_inflexion_of = (
  # CASE    TERM                            0TH      1ST     2ND     3RD
    nominative => {
            i          => { number => 'singular', person => 1,
                            singular => [qw<   I        I       you     it       >],
                            plural   => [qw<   we       we      you     they     >],
                       },
            you        => { number => 'singular', person => 2,
                            singular => [qw<   you      I       you     it       >],
                            plural   => [qw<   you      we      you     they     >],
                       },
            she        => { number => 'singular', person => 3,
                            singular => [qw<   she      I       you     she      >],
                            plural   => [qw<   they     we      you     they     >],
                       },
            he         => { number => 'singular', person => 3,
                            singular => [qw<   he       I       you     he       >],
                            plural   => [qw<   they     we      you     they     >],
                       },
            it         => { number => 'singular', person => 3,
                            singular => [qw<   it       I       you     it       >],
                            plural   => [qw<   they     we      you     they     >],
                       },
            we         => { number => 'plural', person => 1,
                            singular => [qw<   I        I       you     it       >],
                            plural   => [qw<   we       we      you     they     >],
                       },
            they       => { number => 'plural', person => 3,
                            singular => [qw<   it       I       you     it       >],
                            plural   => [qw<   they     we      you     they     >],
                       },
            one        => { number => 'singular', person => 3,
                            singular => [qw<   one      I       you     one      >],
                            plural   => [qw<   some     we      you     some     >],
                       },
            this       => { number => 'singular', person => 3,
                            singular => [qw<   this     this    this    this     >],
                            plural   => [qw<   these    these   these   these    >],
                       },
            that       => { number => 'singular', person => 3,
                            singular => [qw<   that     that    that    that     >],
                            plural   => [qw<   those    those   those   those    >],
                       },
            these      => { number => 'plural', person => 3,
                            singular => [qw<   this     this    this    this     >],
                            plural   => [qw<   these    these   these   these    >],
                       },
            those      => { number => 'plural', person => 3,
                            singular => [qw<   that     that    that    that     >],
                            plural   => [qw<   those    those   those   those    >],
                       },
            who        => { number => 'singular', person => 3,
                            singular => [qw<   who      who     who     who      >],
                            plural   => [qw<   who      who     who     who      >],
                       },
            whoever    => { number => 'singular', person => 3,
                            singular => [qw<   whoever  whoever whoever whoever  >],
                            plural   => [qw<   whoever  whoever whoever whoever  >],
                       },
            whosoever  => { number => 'singular', person => 3,
                            singular => [qw<   whosoever whosoever whosoever whosoever  >],
                            plural   => [qw<   whosoever whosoever whosoever whosoever  >],
                       },
        },
    objective => {
            me         => { number => 'singular', person => 1,
                            singular => [qw<   me       me      you     it       >],
                            plural   => [qw<   us       us      you     them     >],
                       },
            you        => { number => 'singular', person => 2,
                            singular => [qw<   you      me      you     it       >],
                            plural   => [qw<   you      us      you     them     >],
                       },
            her        => { number => 'singular', person => 3,
                            singular => [qw<   her      me      you     her      >],
                            plural   => [qw<   them     us      you     them     >],
                       },
            him        => { number => 'singular', person => 3,
                            singular => [qw<   him      me      you     him      >],
                            plural   => [qw<   them     us      you     them     >],
                       },
            it         => { number => 'singular', person => 3,
                            singular => [qw<   it       me      you     it       >],
                            plural   => [qw<   them     us      you     them     >],
                       },
            one        => { number => 'singular', person => 3,
                            singular => [qw<   one      me      you     one      >],
                            plural   => [qw<   some     us      you     some     >],
                       },
            us         => { number => 'plural', person => 1,
                            singular => [qw<   me       me      you     it       >],
                            plural   => [qw<   us       us      you     them     >],
                       },
            them       => { number => 'plural', person => 3,
                            singular => [qw<   it       me      you     it       >],
                            plural   => [qw<   them     us      you     them     >],
                       },
            this       => { number => 'singular', person => 3,
                            singular => [qw<   this     this    this    this     >],
                            plural   => [qw<   these    these   these   these    >],
                       },
            that       => { number => 'singular', person => 3,
                            singular => [qw<   that     that    that    that     >],
                            plural   => [qw<   those    those   those   those    >],
                       },
            these      => { number => 'plural', person => 3,
                            singular => [qw<   this     this    this    this     >],
                            plural   => [qw<   these    these   these   these    >],
                       },
            those      => { number => 'plural', person => 3,
                            singular => [qw<   that     that    that    that     >],
                            plural   => [qw<   those    those   those   those    >],
                       },
            whom       => { number => 'singular', person => 3,
                            singular => [qw<   whom     whom    whom    whom     >],
                            plural   => [qw<   whom     whom    whom    whom     >],
                       },
            whomever   => { number => 'singular', person => 3,
                            singular => [qw<   whomever  whomever whomever whomever  >],
                            plural   => [qw<   whomever  whomever whomever whomever  >],
                       },
            whomsoever => { number => 'singular', person => 3,
                            singular => [qw<   whomsoever whomsoever whomsoever whomsoever  >],
                            plural   => [qw<   whomsoever whomsoever whomsoever whomsoever  >],
                       },
        },
    possessive => {
            mine       => { number => 'singular', person => 1,
                            singular => [qw<   mine     mine    yours   its      >],
                            plural   => [qw<   ours     ours    yours   theirs   >],
                       },
            yours      => { number => 'singular', person => 2,
                            singular => [qw<   yours    mine    yours   its      >],
                            plural   => [qw<   yours    ours    yours   theirs   >],
                       },
            hers       => { number => 'singular', person => 3,
                            singular => [qw<   hers     mine    yours   hers     >],
                            plural   => [qw<   theirs   ours    yours   theirs   >],
                       },
            his        => { number => 'singular', person => 3,
                            singular => [qw<   his      mine    yours   his      >],
                            plural   => [qw<   theirs   ours    yours   theirs   >],
                       },
            its        => { number => 'singular', person => 3,
                            singular => [qw<   its      mine    yours   its      >],
                            plural   => [qw<   theirs   ours    yours   theirs   >],
                       },
            "one's"    => { number => 'singular', person => 3,
                            singular => [qw<   one's    mine    yours   one's    >],
                            plural   => [qw<   theirs   ours    yours   theirs   >],
                       },
            ours       => { number => 'plural', person => 1,
                            singular => [qw<   mine     mine    yours   its      >],
                            plural   => [qw<   ours     ours    yours   theirs   >],
                       },
            theirs     => { number => 'plural', person => 3,
                            singular => [qw<   its      mine    yours   its      >],
                            plural   => [qw<   theirs   ours    yours   theirs   >],
                       },
            whose      => { number => 'singular', person => 3,
                            singular => [qw<   whose    whose   whose   whose    >],
                            plural   => [qw<   whose    whose   whose   whose    >],
                       },
            whosever   => { number => 'singular', person => 3,
                            singular => [qw<   whosever whosever whosever whosever >],
                            plural   => [qw<   whosever whosever whosever whosever >],
                       },
            whosesoever=> { number => 'singular', person => 3,
                            singular => [qw<   whosesoever whosesoever whosesoever whosesoever >],
                            plural   => [qw<   whosesoever whosesoever whosesoever whosesoever >],
                       },
        },
    reflexive  => {
            myself     => { number => 'singular', person => 1,
                            singular => [qw<   myself     myself     yourself    itself      >],
                            plural   => [qw<   ourselves  ourselves  yourselves  themselves  >],
                       },
            yourself   => { number => 'singular', person => 2,
                            singular => [qw<   yourself   myself     yourself    itself      >],
                            plural   => [qw<   yourselves ourselves  yourselves  themselves  >],
                       },
            herself    => { number => 'singular', person => 3,
                            singular => [qw<   herself    myself     yourself    herself     >],
                            plural   => [qw<   themselves ourselves  yourselves  themselves  >],
                       },
            himself    => { number => 'singular', person => 3,
                            singular => [qw<   himself    myself     yourself    himself     >],
                            plural   => [qw<   themselves ourselves  yourselves  themselves  >],
                       },
            themself   => { number => 'singular', person => 3,
                            singular => [qw<   themselves myself     yourself    themselves  >],
                            plural   => [qw<   themselves ourselves  yourselves  themselves  >],
                       },
            itself     => { number => 'singular', person => 3,
                            singular => [qw<   itself     myself     yourself    itself      >],
                            plural   => [qw<   themselves ourselves  yourselves  themselves  >],
                       },
            oneself    => { number => 'singular', person => 3,
                            singular => [qw<   oneself    myself     yourself    oneself     >],
                            plural   => [qw<   oneselves  ourselves  yourselves  oneselves   >],
                       },
            ourselves  => { number => 'plural', person => 1,
                            singular => [qw<   myself     myself     yourself    itself      >],
                            plural   => [qw<   ourselves  ourselves  yourselves  themselves  >],
                       },
            yourselves => { number => 'plural', person => 2,
                            singular => [qw<   yourself   myself     yourself    itself      >],
                            plural   => [qw<   yourselves ourselves  yourselves  themselves  >],
                       },
            themselves => { number => 'plural', person => 3,
                            singular => [qw<   themselves myself     yourself    themselves  >],
                            plural   => [qw<   themselves ourselves  yourselves  themselves  >],
                       },
            oneselves  => { number => 'plural', person => 3,
                            singular => [qw<   oneself    myself     yourself    oneself     >],
                            plural   => [qw<   oneselves  ourselves  yourselves  oneselves   >],
                       },
        },
);

my $PREP_PAT = qr{ about   | above   | across  | after  | among   | around   | athwart
                 | at      | before  | behind  | below  | beneath | besides?
                 | between | betwixt | beyond  | but    | by      | during
                 | except  | for     | from    | into   | in      | near     | off
                 | of      | onto    | on      | out    | over    | since    | till
                 | to      | under   | until   | unto   | upon    | within   | without | with
                 }xmsi;

sub singular {
    my $self   = shift;
    my $person = shift // 0;

    my $term = $term_of{$self};

    # Prepositions imply objective or possessive...
    my $preposition = $term =~ s{ \A ( \s* $PREP_PAT \s+ ) }{}xi ? $1 : q{};

    return
        $preposition ?   $preposition
                       . $encase->( $term,
                               $noun_inflexion_of{objective }{lc $term}{singular}[$person]
                            // $noun_inflexion_of{possessive}{lc $term}{singular}[$person]
                            // $noun_inflexion_of{reflexive }{lc $term}{singular}[$person]
                            // $noun_inflexion_of{nominative}{lc $term}{singular}[$person]
                            // Lingua::EN::Inflexion::Nouns::convert_to_singular( $term, $person )
                         )
                     :   $encase->( $term,
                               $noun_inflexion_of{nominative}{lc $term}{singular}[$person]
                            // $noun_inflexion_of{objective }{lc $term}{singular}[$person]
                            // $noun_inflexion_of{possessive}{lc $term}{singular}[$person]
                            // $noun_inflexion_of{reflexive }{lc $term}{singular}[$person]
                            // Lingua::EN::Inflexion::Nouns::convert_to_singular( $term, $person )
                         );
}


sub plural {
    my $self   = shift;
    my $person = shift // 0;

    my $term = $term_of{$self};

    # Prepositions imply objective or possessive (or dative)...
    my $preposition = $term =~ s{ \A ( \s* $PREP_PAT \s+ ) }{}xi ? $1 : q{};

    return
          $preposition ?   $preposition
                         . $encase->( $term,
                                $noun_inflexion_of{objective }{lc $term}{plural}[$person]
                             // $noun_inflexion_of{possessive}{lc $term}{plural}[$person]
                             // $noun_inflexion_of{reflexive }{lc $term}{plural}[$person]
                             // $noun_inflexion_of{nominative}{lc $term}{plural}[$person]
                             // Lingua::EN::Inflexion::Nouns::convert_to_modern_plural($term,$person)
                           )
                       :   $encase->( $term,
                                $noun_inflexion_of{nominative}{lc $term}{plural}[$person]
                             // $noun_inflexion_of{objective }{lc $term}{plural}[$person]
                             // $noun_inflexion_of{possessive}{lc $term}{plural}[$person]
                             // $noun_inflexion_of{reflexive }{lc $term}{plural}[$person]
                             // Lingua::EN::Inflexion::Nouns::convert_to_modern_plural($term,$person)
                           );
}


sub indef_article {
    my ($self) = @_;

    return Lingua::EN::Inflexion::Indefinite::select_indefinite_article($self->singular);
}

sub indefinite {
    my ($self, $count) = @_;
    $count //= 1;

    if ($count == 1 ) {
        return Lingua::EN::Inflexion::Indefinite::prepend_indefinite_article($self->singular);
    }
    else {
        return "$count " . $self->plural;
    }
}


# Conversions to ordinal and cardinal numbers (with module loaded on demand)...
my $num2word = sub {
    state $load = require Lingua::EN::Nums2Words && Lingua::EN::Nums2Words::set_case('lower');
    Lingua::EN::Nums2Words::num2word(@_);
};

my $num2word_short_ordinal = sub {
    state $load = require Lingua::EN::Nums2Words && Lingua::EN::Nums2Words::set_case('lower');
    Lingua::EN::Nums2Words::num2word_short_ordinal(@_);
};

my $num2word_ordinal = sub {
    state $load = require Lingua::EN::Nums2Words && Lingua::EN::Nums2Words::set_case('lower');
    Lingua::EN::Nums2Words::num2word_ordinal(@_);
};

# These words may need an "and" before them...
my $LAST_WORD = qr{
       one    | two    | three | four | five | six | seven  | eight | nine | ten
     | eleven | twelve | teen  | ty
     | first  | second | third | [rfxnhe]th
}x;

# These words may need an "and" after them...
my $POWER_WORD = qr{
    hundred | thousand | \S+illion
}x;

sub cardinal {
    my $value = $term_of{ shift() };
    my $max_trans = shift();

    # Load the necessary module, and compensate for its persnicketiness...
    state $load = require Lingua::EN::Words2Nums;
    local $SIG{__WARN__} = sub{};

    # Make sure we have a number...
    $value = Lingua::EN::Words2Nums::words2nums($value) // $value;

    # If it's above threshold, return it as a number...
    return $value
        if defined $max_trans && $value >= $max_trans;

    # Otherwise, convert it to words...
    my $words = $num2word->($value);

    # Correct for proper English pronunciation...
    if ($value > 100) {
        $words =~ s{ ($POWER_WORD) \s+ (\S*$LAST_WORD) \b } {$1 and $2}gx;
        $words =~ s{    (?<! and ) \s+ (\S*$LAST_WORD) $  } { and $1}gx;
        $words =~ s{ ^ ([^,]+),([^,]+) $ }                  {$1$2}x;
    }

    return $words;
}

sub ordinal {
    my $value = $term_of{ shift() };
    my $max_trans = shift();

    # Load the necessary module, and compensate for its persnicketiness...
    state $load = require Lingua::EN::Words2Nums;
    local $SIG{__WARN__} = sub{};

    # Make sure we have a number...
    $value = Lingua::EN::Words2Nums::words2nums($value) // $value;

    # If it's above threshold, return it as a number...
    return $num2word_short_ordinal->($value)
        if defined $max_trans && $value >= $max_trans;

    # Otherwise, convert it to words...
    my $words = $num2word_ordinal->( $value );

    # Correct for proper English pronunciation...
    if ($value > 100) {
        $words =~ s{ ($POWER_WORD) \s+ (\S*$LAST_WORD) \b } {$1 and $2}gx;
        $words =~ s{    (?<! and ) \s+ (\S*$LAST_WORD) $  } { and $1}gx;
        $words =~ s{ ^ ([^,]+),([^,]+) $ }                  {$1$2}x;
    }

    return $words;
}


# Return a classical version of the term...
sub classical  { Lingua::EN::Inflexion::Noun::Classical->new(shift) }


package Lingua::EN::Inflexion::Noun::Classical;
our @ISA = 'Lingua::EN::Inflexion::Noun';

# Inside-out ctor expects a base-class object to clone...
sub new {
    my ($class, $orig_object) = @_;

    my $new_object = bless do{ \my $scalar }, $class;

    # Special case of "them" (because "it" -> "they" and "it -> "them" are ambiguous)...
    $term_of{$new_object}
         = $term_of{$orig_object} eq 'them' ? $term_of{$orig_object}
         :                                    $orig_object->singular;

    # Otherwise...

    return $new_object;
}

# Already a classical noun, so this is now idempotent...
sub classical { return shift }

# Classical plurals are different...
sub plural {
    my $self   = shift;
    my $person = shift // 0;
    my $term = $term_of{$self};

    return $encase->(
                $term,
                $noun_inflexion_of{lc $term}{plural}[$person]
                // Lingua::EN::Inflexion::Nouns::convert_to_classical_plural($term, $person)
           );
}

package Lingua::EN::Inflexion::Verb;
our @ISA = 'Lingua::EN::Inflexion::Term';

use Lingua::EN::Inflexion::Verbs;

# Utility sub that adjusts final consonants when they need to be doubled in inflexions...
my $truncate = sub {
    my ($term) = @_;

    # Apply the first relevant transform...
       $term =~ s{       ie \Z }{y}x
    or $term =~ s{       ue \Z }{u}x
    or $term =~ s{ ([auy])e \Z }{$1}x

    or $term =~ s{      ski \Z }{ski}x
    or $term =~ s{    [^b]i \Z }{}x

    or $term =~ s{ ([^e])e \Z }{$1}x

    or $term =~ m{ er \Z }x
    or $term =~ s{ (.[bdghklmnprstz][o]([n])) \Z }{$1}x

    or $term =~ s{ ([^aeiou][aeiouy]([bcdlgmnprstv])) \Z }{$1$2}x

    or $term =~ s{ e \Z }{}x;

    return $term;
};

# Report status of verb...
sub is_plural   {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_plural( $term_of{$self} );
}

sub is_singular {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_singular( $term_of{$self} );
}

sub is_present {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_present( $term_of{$self} );
}

sub is_past {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_past( $term_of{$self} );
}

sub is_pres_part {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_pres_part( $term_of{$self} );
}

sub is_past_part {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_past_part( $term_of{$self} );
}

# Report part-of-speech...
sub is_verb { 1 }


# Conversions...

sub singular {
    my $self   = shift;
    my $person = shift // 0;
    my $term = $term_of{$self};

    # Find the right inflexion...
    my $inflexion;

    # "To be" is special...
    if ($self =~ m{ \A (?: is | am | are ) \Z }x) {
        return $person == 0                         ? $term
             : $person == 2 || !$self->is_singular  ? 'are'
             : $person == 1                         ? 'am'
             :                                        'is'
    }

    # Third person uses the "notional" singular inflexion...
    elsif ($person == 3 || $person == 0) {
        # Is it a known inflexion???
        my $known = Lingua::EN::Inflexion::Verbs::convert_to_singular( $term );

        # Return with case-following...
        return $encase->( $term, $known eq '_' ? $term : $known );
    }

    # First and second person always use the uninflected (i.e. "notional "plural" form)...
    else {
        return plural($self);
    }
}

sub plural {
    my ($self) = @_;
    my $term = $term_of{$self};

    # Is it a known inflexion???
    my $known = Lingua::EN::Inflexion::Verbs::convert_to_plural( $term );

    # Return with case-following...
    return $encase->( $term, $known eq '_' ? $term : $known );
}

sub past {
    my ($self) = @_;
    my $term = $term_of{$self};
    my $root = $self->plural;

    # Is it a known inflexion???
    my $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_past( $term );

    if ($inflexion eq '_') {
        $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_past( $root );
    }

    # Otherwise use the standard pattern...
    if ($inflexion eq '_') {
        $inflexion = $truncate->($root) . 'ed';
    }

    # Return with case-following...
    return $encase->( $term, $inflexion );
}

sub pres_part {
    my ($self) = @_;
    my $term = $term_of{$self};
    my $root = $self->plural;

    # Is it a known inflexion???
    my $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_pres_part( $root );

    # Otherwise use the standard pattern...
    if ($inflexion eq '_') {
        $inflexion = $truncate->($root) . 'ing';
    }

    # Return with case-following...
    return $encase->( $term, $inflexion );
}

sub past_part {
    my ($self) = @_;
    my $term = $term_of{$self};
    my $root = $self->plural;

    # Is it a known inflexion???
    my $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_past_part( $root );

    # Otherwise use the standard pattern...
    if ($inflexion eq '_') {
        $inflexion = $truncate->($root) . 'ed';
    }

    # Return with case-following...
    return $encase->( $term, $inflexion );
}

sub indefinite {
    my ($self, $count) = @_;
    $count //= 1;

    return $count == 1 ? $self->singular
                       : $self->plural;
}

sub as_regex {
    my ($self) = @_;
    my %seen;
    my $pattern = join '|', map { quotemeta } reverse sort grep { !$seen{$_}++ }
                  ($self->singular, $self->plural,
                   $self->past, $self->past_part, $self->classical->pres_part);
    return qr{$pattern}i;
}




package Lingua::EN::Inflexion::Adjective;
our @ISA = 'Lingua::EN::Inflexion::Term';

# Load adjective tables, always taking first option...
my @adjectives = (
    # Determiners...
        'a'      =>  'some',
        'an'     =>  'some',

    # Demonstratives...
        'that'   =>  'those',
        'this'   =>  'these',

    # Possessives...
        'my'     =>  'our',
        'your'   =>  'your',
        'their'  =>  'their',
        'her'    =>  'their',
        'his'    =>  'their',
        'its'    =>  'their',
);

my (%adj_plural_of, %adj_singular_of, %adj_is_plural, %adj_is_singular);
while (my ($sing, $plur) = splice @adjectives, 0, 2) {
    $adj_is_singular{$sing}   = 1;
    $adj_singular_of{$plur} //= $sing;

    $adj_is_plural{$plur}   = 1;
    $adj_plural_of{$sing} //= $plur;
}

my %adj_possessive_inflexion = (
  # Term                             0TH    1ST   2ND    3RD
    'my'     =>  { singular => [qw<  my     my    your   its    >],
                   plural   => [qw<  our    our   your   their  >],
                 },
    'your'   =>  { singular => [qw<  your   my    your   its    >],
                   plural   => [qw<  your   our   your   their  >],
                 },
    'her'    =>  { singular => [qw<  her    my    your   her    >],
                   plural   => [qw<  their  our   your   their  >],
                 },
    'his'    =>  { singular => [qw<  his    my    your   his    >],
                   plural   => [qw<  their  our   your   their  >],
                 },
    'its'    =>  { singular => [qw<  its    my    your   its    >],
                   plural   => [qw<  their  our   your   their  >],
                 },
    'our'    =>  { singular => [qw<  my     my    your   its    >],
                   plural   => [qw<  our    our   your   their  >],
                 },
    'their'  =>  { singular => [qw<  its    my    your   its    >],
                   plural   => [qw<  their  our   your   their  >],
                 },
);


# Report part-of-speech...
sub is_adj { 1 }


# Report number of adjective...
sub is_plural   {
    my ($self) = @_;
    my $term = $term_of{$self};
    return $adj_is_plural{$term} || $adj_is_plural{lc $term}
        || !$adj_is_singular{$term} && !$adj_is_singular{lc $term};
}

sub is_singular   {
    my ($self) = @_;
    my $term = $term_of{$self};
    return $adj_is_singular{$term} || $adj_is_singular{lc $term}
        || !$adj_is_plural{$term} && !$adj_is_plural{lc $term};
}


# Conversions...

sub singular {
    my $self = shift;
    my $person = shift // 0;

    my $term = $term_of{$self};

    # Is it a composite possessive form???
    my $singular;
    if ($term =~ m{ \A (.*) 's? \Z }ixms) {
        $singular = Lingua::EN::Inflexion::Noun->new($1)->singular . q{'s};
    }

    # Otherwise, it's either a known inflexion, or uninflected...
    else {
        $singular = $adj_possessive_inflexion{lc $term}{singular}[$person]
                 // $adj_singular_of{$term}
                 // $adj_singular_of{lc $term}
                 // $term;
    }

    return $encase->($term, $singular);
}

sub plural {
    my $self = shift;
    my $person = shift // 0;
    my $term = $term_of{$self};
    my $plural = $term;

    # Is it a possessive form???
    if ($term =~ m{ \A (.*) 's? \Z }ixms) {
        $plural = Lingua::EN::Inflexion::Noun->new($1)->plural . q{'s};
        $plural =~ s{ s's \Z }{s'}xms
    }

    # Otherwise, it's either a known inflexion, or uninflected...
    else {
        $plural = $adj_possessive_inflexion{lc $term}{plural}[$person]
               // $adj_plural_of{$term}
               // $adj_plural_of{lc $term}
               // $term;
    }

    return $encase->($term, $plural);
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Lingua::EN::Inflexion::Term - Implements classes of LEI objects


=head1 VERSION

This document describes Lingua::EN::Inflexion::Term version 0.000001


=head1 DESCRIPTION

This module contains implementation code only.
See the documentation of Lingua::EN::Inflexion instead.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
