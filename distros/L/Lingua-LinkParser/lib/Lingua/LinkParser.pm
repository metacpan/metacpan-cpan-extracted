package Lingua::LinkParser;

require 5.005;
use strict;
use Carp;
use Lingua::LinkParser::Sentence;
use Lingua::LinkParser::Linkage;
use Lingua::LinkParser::Dictionary;

require Exporter;
require DynaLoader;

use vars qw(@ISA $VERSION $DATA_DIR);

@ISA = qw(DynaLoader);
$VERSION = '1.17';

=head1 NAME

Lingua::LinkParser - Perl module implementing the Link Grammar Parser by Sleator, Temperley and Lafferty at CMU.

=head1 SYNOPSIS

  use Lingua::LinkParser;
 
  our $parser = new Lingua::LinkParser;
  my $sentence = $parser->create_sentence("This is the turning point.");
  my @linkages = $sentence->linkages;
  # If there are NO LINKAGES, set min_null_count to a positive number:
  # $parser->opts('min_null_count' => 1);
  # See scripts/parse.pl for examples.
  foreach $linkage (@linkages) {
      print ($parser->get_diagram($linkage));
  }

=head1 DESCRIPTION

To quote the Link Grammar documentation, "the Link Grammar Parser is a syntactic parser of English, based on link grammar, an original theory of English syntax. Given a sentence, the system assigns to it a syntactic structure, which consists of set of labeled links connecting pairs of words."

This module provides acccess to the parser API using Perl objects to easily analyze linkages. The module organizes data returned from the parser API into an object hierarchy consisting of, in order, sentence, linkage, sublinkage, and link. If this is unclear to you, see the several examples in the 'eg/' directory for a jumpstart on using these objects. The current Lingua::LinkParser module is based on version 4.2 of the Link Grammar parser API.

The objects within this module should not be confused with the types familiar to users of the Link Parser API. The objects used in this module reorganize the API data in a way more usable and friendly to Perl users, and do not exactly represent the types used in the API. For example, an object of class"Lingua::LinkParser::Sentence does not directly correspond to the struct type "Sentence" of the API; rather, it is a Perl object that provides methods to access the underlying API functions.

This documentation should be supplemented with the extensive texts included with the Link Parser and on the Link Parser web site in order to understand its vernacular and general usage. Lingua::LinkParser::Definitions stores the basic link type documentation, and allows in-program retrieval of this information for convenience.

Note that most of the objects have overloading behavior, such that if you print an object, you will see a sensible text representation of that object, such as a linkage diagram.

=over

=item $parser = new Lingua::LinkParser( Lang => "en" )

This returns a new Lingua::LinkParser object, loads dictionary files, and sets basic configuration. This constructor no longer takes a full path to the dictionary files; they are expected to exist in the locations standard to the 4.2 parser distribution.

=item $parser->opts(OPTION_NAME => OPTION_VALUE, ...)

This sets the parser option OPTION_NAME to the value specified by OPTION_VALUE.  A full list of these options is found at the end of this document, as well as in the Link Parser distribution documentation.

=item $sentence = $parser->create_sentence(TEXT)

Creates and assigns a sentence object (Lingua::LinkParser::Sentence) using the supplied value. This object is used in subsequent creation and analysis of linkages.

=item $sentence->length

Returns the number of words in the tokenized sentence, including the boundary words and punctuation.

=item $sentence->num_linkages

Returns the number of linkages found for $sentence.

=item $sentence->num_valid_linkages

Returns the number of valid linkages for $sentence

=item $sentence->num_linkages_post_processed

Returns the number of linkages that were post-processed.

=item $sentence->null_count

Returns the number of null links used in parsing the sentence.

=item $sentence->num_violations

Returns the number of post processing violations for $sentence.

=item $sentence->get_word(NUM)

Returns the word (with original spelling) at position NUM, which is 1-indexed.

=item $linkage = $sentence->linkage(NUM)

Assigns a linkage object (Lingua::LinkParser::Linkage) for linkage NUM of sentence $sentence. NUM is 1-indexed.

=item @linkages = $sentence->linkages

Assigns a list of linkage objects for all linkages of $sentence.

=item $linkage->num_words

Returns the number of words within $linkage.

=item $linkage->get_words

Returns a list of words within $linkage

=item $linkage->words

Returns a list of ::Word objects for $linkage.

=item $linkage->num_sublinkages

Returns the number of sublinkages for linkage $linkage.

=item $linkage->compute_union

Combines the sublinkages for $linkage into one, possibly with crossing links.

=item $linkage->violation_name

Returns the name of a rule violated by post-processing of the linkage.

=item $linkage->constituent_tree

Returns a Perl data structure that represents the constituent tree for the linkage. See scripts/constituent-tree.pl for an example of processing the tree.

=item $sublinkage = $linkage->sublinkage(NUM)

Assigns a sublinkage object (Lingua::LinkParser::Linkage::Sublinkage) for sublinkage NUM of linkage $linkage, which is 1-indexed.

=item @sublinkages = $linkage->sublinkages

Assigns an array of sublinkage objects.

=item $sublinkage->get_word(NUM)

Returns the word for the sublinkage at position NUM, 1-indexed.

=item $sublinkage->words

Returns a list of ::Word objects for $sublinkage.

=item $sublinkage->num_links

Returns the number of links for sublinkage $sublinkage.

=item $word->text

Returns the post-parse word text.

=item $word->position

Returns the number for the word's position in a sentence.

=item @links = $word->links

Returns a list of link objects for the word.

=item $link = $sublinkage->link(NUM)

Assigns a link object (Lingua::LinkParser::Link) for link NUM of sublinkage
$sublinkage. NUM is 1-indexed.

=item @links = $sublinkage->links

Assigns an array of link objects.

=item $link->num_domains

Returns the number of domains for the sublinkage.

=item $link->domain_names

Returns a list of the domain names for $link.

=item $link->label

Returns the "intersection" label for $link.

=item $link->llabel

Returns the left label for $link.

=item $link->rlabel

Returns the right label for $link.

=item $link->lword

Returns the number of the left word for $link.

=item $link->rword

Returns the number of the right word for $link.

=item $link->length

Returns the length of the link.

=item $link->linklabel

Only for link objects created via a word object, this returns the label for the link from the word object that created it.

=item $link->linkword

Only for link objects created via a word object, this returns the word text which the link points *to* from the object that created it.

=item $link->linkposition

Only for link objects created via a word object, this returns the number of the word which the link points *to* from the object that created it.

=item $parser->get_diagram($linkage)

Returns an ASCII pretty-printed diagram of the specified linkage or sublinkage.

=item $parser->get_postscript($linkage, MODE)

Returns Postscript code for a diagram of the specified linkage or sublinkage.

=item $parser->get_domains($linkage)

Returns formatted ASCII text showing the links and domains for the specified linkage or sublinkage.

=item $parser->print_constituent_tree($linkage, MODE)

Returns an ASCII formatted tree displaying the constituent parse tree for $linkage. MODE is an integer with the following meanings: '1' will display the tree using a nested Lisp format, '2' specifies that a flat tree is displayed with brackets, and '0' results in no structure, a null string being returned.

=back


=head1 OTHER FUNCTIONS

A few higher-level functions have also been provided.

=over

=item @bigstruct = $sentence->get_bigstruct
 

Assigns a potentially large data structure merging all linkages/sublinkages/links for $sentence. This structure is an array of hashes, with a single array entry for each word in the sentence. This function is only useful for high-level analysis of sentence grammar; most applications should be served by using the above functions.
 
This array has the following structure:

 @bigstruct = ( %{ 'word'  => 'WORD',
                 'links' => %{
                    'LINKTYPE_LINKAGENUM' => 'TARGETWORDNUM',...
                 },
                }
           , ...);

Where LINKAGENUM is the number of the linkage for $sentence, and LINKTYPE is the link type label. TARGETWORDNUM is the number of the word to which each link connects.
 
get_bigstruct() can be useful in finding, for example, all links for a given word in a given sentence:
 
   $sentence = $parser->create_sentence(
        "Architecture is present in nearly every civilized society.");
   @bigstruct = $sentence->get_bigstruct;

   print "\nword 8: ", $bigstruct[8]->{word}, "\n";

   while (($k,$v) = each %{$bigstruct[8]->{links}} )
        { print " $k => ", $bigstruct[$v]->{word}, "\n"; }

This would output:
 
   word 8: society.n
    Dsu => every.d
    Jp => in
    A => civilized.a
 
Signifying that for word "society", links are found of type A (pre-noun adjective) with "civilized" (tagged 'a' for adjective), type Jp (preposition to object) with "in", and type Dsu (noun determiner, singular-mass) with word "every", which is tagged 'd' for determiner.

The following example adds the usage of a Lingua::LinkParser::Definitions object to display the link definitions along with the link types. Note that this is an optional module, and is only really useful for human-readable display:

   use Lingua::LinkParser::Definitions qw(define);

   $sentence = $parser->create_sentence(
        "Architecture is present in nearly every civilized society.");
   @bigstruct = $sentence->get_bigstruct;

   print "\nword $i: ", $bigstruct[$i]->{word}, "\n";

   while (($k,$v) = each %{$bigstruct[$i]->{links}} )
        { print " $k => ", $bigstruct[$v]->{word}, " (", define($k), ")\n"; }

Yielding:

   word 8: society.n
    Dsu => every.d (D connects determiners to nouns: "THE DOG chased A CAT and SOME BIRDS".  )
    Jp => in (J connects prepositions to their objects: "The man WITH the HAT is here".  )
    A => civilized.a (A connects pre-noun ("attributive") adjectives to following nouns: "The BIG DOG chased me", "The BIG BLACK UGLY DOG chased me".)

=back

=head1 LINK PARSER OPTIONS

The following list of options may be set or retrieved with Lingua::LinkParser object with the function:

    $parser->opts(OPTION, [VALUE])

Supplying no VALUE returns the current value for OPTION. Note that not all of the options are implemented by the API, and instead are intended for use by the program. A more complete list of these options may be found in the parser documentation.

 verbosity
  The level of detail reported during processing, 0 reports nothing.

 linkage_limit
  The maximum number of linkages to process for a sentence.

 disjunct_cost
  Determines the maximum disjunct cost used during parsing, where the cost of a disjunct is equal to the maximum cost of all of its connectors.

 min_null_count
 max_null_count
  The range of null links to parse.

 null_block
  Sets the block count ratio for null linkages; a value of '4' causes a linkage of 1, 2, 3, or 4 null links to have a null cost of 1.

 short_length
  Limits the number length of links to this value (the number of words a link can span).

 islands_ok
  Allows 'islands' of links (links not connected to the 'wall') when set.

 max_parse_time
  Determines the approximate maximum time permitted for parsing.

 max_memory
  Determines the maximum memory allowed during parsing.

 timer_expired
 memory_exhausted
 resources_exhausted
 reset_resources
  These options tell whether the timer or memory constraints have been exceeded during parsing.

 cost_model_type

 screen_width
  Sets the screen width for pretty-print functions.

 allow_null
  Allow or disallow null links in linkages.

 display_walls
  Toggles the display of linkage "walls".

 all_short_connectors
  If true, then all connectors have length restrictions imposed on them.


=head1 AUTHOR

Danny Brian, danny@brians.org

=head1 SEE ALSO

http://www.abisource.com/projects/link-grammar/
http://www.link.cs.cmu.edu/link/.

=cut

  sub new {
    my $class = shift;
    my %arg = @_;
    $arg{Lang}      ||= "en";

    my $self = bless {
            _opts => parse_options_create(),
            _dict => dictionary_create_lang( $arg{Lang} )
    }, $class;
    foreach (keys %arg) {
        if (/^[a-z]/) {
            $self->opts($_ => $arg{$_});
        }
    }
    unless ($self->dict) {
        croak "Dictionary creation failed";
    }
    return $self;
  }

  sub dict { $_[0]->{_dict} }

  sub opts {
    my $self = shift;
    my $return = 1;
    if (@_ == 0) { return $self->{_opts} }
    if (@_ == 1) {
        eval("\$return = Lingua::LinkParser::parse_options_get_$_[0](\$self->{_opts})");
        if ($@) { croak $@ };
    } else {
        my %arg = @_;
        foreach my $key (keys %arg) {
            eval("Lingua::LinkParser::parse_options_set_$key(\$self->{_opts},'$arg{$key}')");
            if ($@) { croak $@ };
        }
    }
    Lingua::LinkParser::parse_options_reset_resources($self->{_opts});
    $return;
  }

  sub create_sentence {
    my $self = shift;
    my $text = shift;
    my $sentence = new Lingua::LinkParser::Sentence($text,$self);
    $sentence;
  }

  sub get_diagram {
    my $self = shift;
    my $linkage = shift;
    linkage_print_diagram($linkage->{linkage});
  }

  sub get_postscript {
    my $self    = shift;
    my $linkage = shift;
    my $mode    = shift;
    $mode     ||= 0;
    linkage_print_postscript($linkage->{linkage}, $mode);
  }

  sub print_constituent_tree {
    my $self = shift;
    my $linkage = shift;
    my $mode = shift;
    linkage_print_constituent_tree($linkage->{linkage},$mode);
  }

  sub get_domains {
    my $self = shift;
    my $linkage = shift;
    linkage_print_links_and_domains($linkage->{linkage});
  }

  sub DESTROY {
    my $self = shift;
    if ($self->{_dict}) { Lingua::LinkParser::dictionary_delete($self->{_dict}); }
    if ($self->{_opts}) { Lingua::LinkParser::parse_options_delete($self->{_opts});     }
    $self = {};
  }

  sub close {
    my $self = shift;
    $self->DESTROY();
  }

bootstrap Lingua::LinkParser $VERSION;

1;
__END__


