=head1 NAME

Lingua::EN::NameParse -  extract the components of a person or couples full name, from free form text 

=head1 SYNOPSIS

    use Lingua::EN::NameParse qw(clean case_surname);

    # optional configuration arguments
    my %args =
    (
        auto_clean      => 1,
        lc_prefix       => 1,
        initials        => 3,
        allow_reversed  => 1,
        joint_names     => 0,
        extended_titles => 0
    );

    my $name = Lingua::EN::NameParse->new(%args);

    $error = $name->parse("Estate Of Lt Col AB Van Der Heiden (Hold Mail)");
    unless ( $error )    
    {
        print($name->report);
        
            Case all             : Estate Of Lt Col AB Van Der Heiden (Hold Mail)
            Case all reversed    : Van Der Heiden, Lt Col AB
            Salutation           : Dear Friend
            Type                 : Mr_A_Smith
            Parsing Error        : 0
            Error description :  : 
            Parsing Warning      : 1
            Warning description  : ;non_matching text found : (Hold Mail)
            
            COMPONENTS
            initials_1           : AB
            non_matching         : (Hold Mail)
            precursor            : Estate Of
            surname_1            : Van Der Heiden
            title_1              : Lt Col        
    
        %name_comps = $name->components;
        $surname = $name_comps{surname_1}; 

        $correct_casing = $name->case_all; 

        $correct_casing = $name->case_all_reversed ; 

        $salutation = $name->salutation(salutation => 'Dear',sal_default => 'Friend')); 
        
        $good_name = clean("Bad Na9me   "); # "Bad Name"
  
        %my_properties = $name->properties;
        $number_surnames = $my_properties{number}; # 1
    }
    

    $lc_prefix = 0;
    $correct_case = case_surname("DE SILVA-MACNAY",$lc_prefix); # A stand alone function, returns: De Silva-MacNay
    
    $error = $name->parse("MR AS & D.E. DE LA MARE");
    %my_properties = $name->properties;
    $number_surnames = $my_properties{number}; # 2
    

=head1 DESCRIPTION


This module takes as input one person's name or a couples name in
free format text such as,

    Mr AB & M/s CD MacNay-Smith
    MR J.L. D'ANGELO
    Estate Of The Late Lieutenant Colonel AB Van Der Heiden

and attempts to parse it. If successful, the name is broken
down into components and useful functions can be performed such as :

   converting upper or lower case values to name case (Mr AB MacNay   )
   creating a personalised greeting or salutation     (Dear Mr MacNay )
   extracting the names individual components         (Mr,AB,MacNay   )
   determining the type of format the name is in      (Mr_A_Smith     )


If the name(s) cannot be parsed you have the option of cleaning the name(s)
of bad characters, or extracting any portion that was parsed and the
portion that failed.

This module can be used for analysing and improving the quality of
lists of names.


=head1 DEFINITIONS

The following terms are used by NameParse to define the components
that can make up a name.

   Precursor   - Estate of (The Late), Right Honourable ...
   Title       - Mr, Mrs, Ms., Sir, Dr, Major, Reverend ...
   Conjunction - word to separate two names, such as "And" or &
   Initials    - 1-3 letters, each with an optional space and/or dot
   Surname     - De Silva, Van Der Heiden, MacNay-Smith, O'Reilly ...
   Suffix      - Snr., Jnr, III, V ...

Refer to the component grammar defined within the code for a complete
list of combinations.

'Name casing' refers to the correct use of upper and lower case letters
in peoples names, such as Mr AB McNay.

To describe the formats supported by NameParse, a short hand representation
of the name is used. The following formats are currently supported :

    Mr_John_Smith_&_Ms_Mary_Jones
    Mr_A_Smith_&_Ms_B_Jones
    Mr_&Ms_A_&_B_Smith
    Mr_A_&_Ms_B_Smith
    Mr_&_Ms_A_Smith
    Mr_A_&_B_Smith
    John_Smith_&_Mary_Jones
    John_&_Mary_Smith
    A_Smith_&_B_Jones

    Mr_John_Adam_Smith
    Mr_John_A_Smith
    Mr_John_Smith
    Mr_A_Smith
    John_Adam_Smith
    John_A_Smith
    J_Adam_Smith
    John_Smith
    A_Smith
    John

Precursors and suffixes may be applied to single names that have a surname


=head1 METHODS

=head2 new

The C<new> method creates an instance of a name object and sets up
the grammar used to parse names. This must be called before any of the
following methods are invoked. Note that the object only needs to be
created ONCE, and should be reused with new input data. Calling C<new>
repeatedly will significantly slow your program down.

Various setup options may be defined in a hash that is passed as an optional
argument to the C<new> method. Note that all the arguments are optional. You
need to define the combination of arguments that are appropriate for your
usage.

   my %args =
   (
      auto_clean     => 1,
      lc_prefix      => 1,
      initials       => 3,
      allow_reversed => 1
   );


   my $name = Lingua::EN::NameParse->new(%args);


=over 4

=item auto_clean

When this option is set to a positive value, any call to the C<parse> method
that fails will attempt to 'clean' the name and then reparse it. See the
C<clean> method for details. This is useful for dirty data with embedded
unprintable or non alphabetic characters.

=item lc_prefix

When this option is set to a positive value, it will force the C<case_all>
and C<components> methods to lower case the first letter of each word that
occurs in the prefix portion of a surname. For example, Mr AB de Silva,
or Ms AS von der Heiden.

=item initials

Allows the user to control the number of letters that can occur in the initials.
Valid settings are 1,2 or 3. If no value is supplied a default of 2 is used.

=item allow_reversed

When this option is set to a positive value, names in reverse order will be
processed. The only valid format is the surname followed by a comma and the
rest of the name, which can be in any of the combinations allowed by non
reversed names. Some examples are:

Smith, Mr AB
Jones, Jim
De Silva, Professor A.B.

The program changes the order of the name back to the non reversed format, and
then performs the normal parsing. Note that if the name can be parsed, the fact
that it's order was originally reversed, is not recorded as a property of the
name object.

=item joint_names

When this option is set to a positive value, joint names are accounted for:

Mr_A_Smith_&Ms_B_Jones
Mr_&Ms_A_&B_Smith
Mr_A_&Ms_B_Smith
Mr_&Ms_A_Smith
Mr_A_&B_Smith

Note that if this option is not specified, than by default joint names are
ignored. Disabling joint names speeds up the processing a lot.

=item extended_titles

When this option is set to a positive value, all combinations of titles,
such as Colonel, Mother Superior are used. If this value is not set, only
the following titles are accounted for:

    Mr
    Ms
    M/s
    Mrs
    Miss
    Dr
    Sir
    Dame


Note that if this option is not specified, than by default extended titles
are ignored. Disabling extended titles speeds up the parsing.

=back

=head2 parse

    $error = $name->parse("MR AC DE SILVA");

The C<parse> method takes a single parameter of a text string containing a
name. It attempts to parse the name and break it down into the components

Returns an error flag. If the name was parsed successfully, it's value is 0,
otherwise a 1. This step is a prerequisite for the following methods.


=head2 case_all

    $correct_casing = $name->case_all;

The C<case_all> method converts the first letter of each component to
capitals and the remainder to lower case, with the following exceptions-

   initials remain capitalised
   surname spelling such as MacNay-Smith, O'Brien and Van Der Heiden are preserved
   - see C<surname_prefs.txt> for user defined exceptions

A complete definition of the capitalising rules can be found by studying
the case_surname function.

The method returns the entire cased name as text.

=head2 case_all_reversed

    $correct_casing = $name->case_all_reversed;

The C<case_all_reversed> method applies the same type of casing as
C<case_all>. However, the name is returned as surname followed by a comma
and the rest of the name, which can be any of the combinations allowed
for a name, except the title. Some examples are: "Smith, John", "De Silva, A.B."
This is useful for sorting names alphabetically by surname.

The method returns the entire reverse order cased name as text.


=head2 components

   %my_name = $name->components;
   $cased_surname = $my_name{surname_1};


The C<components> method does the same thing as the C<case_all> method,
but returns the name cased components in a hash. The following keys are used
for each component:

   precursor
   title_1
   title_2
   given_name_1
   given_name_2
   initials_1
   initials_2
   middle_name
   conjunction_1
   conjunction_2
   surname_1
   surname_2
   suffix

If a component has no matching data for a given name, it will not appear in the hash

If the name could not be parsed, this method returns null. If you assign the return
value to a hash, you should check the error status returned by the C<parse> method first.
Ohterwise, you will get an odd number of values assigned to the hash.


=head2 case_surname

   $correct_casing = case_surname("DE SILVA-MACNAY" [,$lc_prefix]);

C<case_surname> is a stand alone function that does not require a name
object. The input is a text string. An optional input argument controls the
casing rules for prefix portions of a surname, as described above in the
C<lc_prefix> section.

The output is a string converted to the correct casing for surnames.
See C<surname_prefs.txt> for user defined exceptions

This function is useful when you know you are only dealing with names that
do not have initials like "Mr John Jones". It is much faster than the case_all
method, but does not understand context, and cannot detect errors on strings
that are not personal names.


=head2 surname_prefs.txt

Some surnames can have more than one form of valid capitalisation, such as
MacQuarie or Macquarie. Where the user wants to specify one form as the default,
a text file called surname_prefs.txt should be created and placed in the same
location as the NameParse module. The text file should contain one surname per
line, in the capitalised form you want, such as

   Macquarie
   MacHado

NameParse will still operate if the file does not exist

=head2 salutation

    $salutation = $name->salutation(salutation => 'Dear',sal_default => 'Friend',sal_type => 'given_name'));

The C<salutation> method converts a name into a personal greeting,
such as "Dear Mr & Mrs O'Brien" or "Dear Sue and John"

Optional parameters may be specided in a hash as follows:


    salutation:

    The greeting word such as 'Dear' or 'Greetings'. If not spefied than 'Dear' is used

    sal_default:

    The default word used when a personalised salution cannot be generated. If not
    specified, than 'Friend' is used.

    sal_type:

    Can be either 'given_name' such as 'Dear Sue' or 'title_plus_name' such as 'Dear Ms Smith'
    If not specified, than 'given_name' is used.

If an error is detected during parsing, such as with the name "AB Smith & Associates",
then the value of sal_default is used instead of a given name, or a title and surname.
If the input string contains a conjunction, an 's' is added to the value of sal_default.

If the name contains a precursor, a default salutation is produced.

=head2 clean

   $good_name = clean("Bad Na9me");

C<clean> is a stand alone function that does not require a name object.
The input is a text string and the output is the string with:

   all repeating spaces removed
   all characters not in the set (A-Z a-z - ' , . &) removed


=head2 properties

The C<properties> method returns all the properties of the name,
non_matching, number and type, as a hash.

=over 4

=item type

The type of format a name is in, as one of the following strings:

    Mr_A_Smith_&Ms_B_Jones
    Mr_&Ms_A_&B_Smith
    Mr_A_&Ms_B_Smith
    Mr_&Ms_A_Smith
    Mr_A_&B_Smith
    Mr_John_Adam_Smith
    Mr_John_A_Smith
    Mr_John_Smith
    Mr_A_Smith
    John_Adam_Smith
    John_A_Smith
    J_Adam_Smith
    John_Smith
    A_Smith
    John
    unknown


=item non_matching

Returns any unmatched section that was found.

=back

=head2 report

Create a formatted text report to standard output listing
- the input string,
- the name and value of each defined component
- any non matching component


=head1 LIMITATIONS

The huge number of character combinations that can form a valid names makes
it is impossible to correctly identify them all. Firstly, there are many
ambiguities, which have no right answer.

   Macbeth or MacBeth, are both valid spellings
   Is ED WOOD E.D. Wood or Edward Wood
   Is 'Mr Rapid Print' a name or a company
   Does  John Bradfield Smith have a middle name of Bradfield, or a surname of Bradfield-Smith?

One approach is to have large lookup files of names and words, statistical rules
and fuzzy logic to attempt to derive context. This approach gives high levels of
accuracy but uses a lot of your computers time and resources.

NameParse takes the approach of using a limited set of rules, based on the
formats that are commonly used by business to represent peoples names. This
gives us fairly high accuracy, with acceptable speed and program size.

NameParse will accept names from many countries, like Van Der Heiden,
De La Mare and Le Fontain. Having said that, it is still biased toward English,
because the precursors, titles and conjunctions are based on English usage.

Names with two or more words, but no separating hyphen are not recognized.
This is a real quandary as Indian, Chinese and other names can have several
components. If these are allowed for, any component after the surname
will also be picked up. For example in "Mr AB Jones Trading As Jones Pty Ltd"
will return a surname of "Jones Trading".

Because of the large combination of possible names defined in the grammar, the
program is not very fast, except for the more limited C<case_surname> subroutine.
See the "Future Directions" section for possible speed ups.

As the parser has a very limited understanding of context, the "John_Adam_Smith"
name type is most likely  to cause problems, as it contains no known tokens
like a title. A string such as "National Australia Bank" would be accepted
as a valid name, first name National etc. Supplying  a list of common pronouns
as exceptions could solve this problem.


=head1 REFERENCES

"The Wordsworth Dictionary of Abbreviations & Acronyms" (1997)

Australian Standard AS4212-1994 "Geographic Information Systems -
Data Dictionary for transfer of street addressing information"


=head1 FUTURE DIRECTIONS

Define grammar for other languages. Hopefully, all that would be needed is
to specify a new module with its own grammar, and inherit all the existing
methods. I don't have the knowledge of the naming conventions for non-english
languages.

=head1 REPOSITORY

L<https://github.com/kimryan/Lingua-EN-NameParse>


=head1 SEE ALSO

L<Lingua::EN::AddressParse>, L<Lingua::EN::MatchNames>, L<Lingua::EN::NickNames>,
L<Lingua::EN::NameCase>, L<Parse::RecDescent>


=head1 BUGS

Names with accented characters (acute, circumfelx etc) will not be parsed
correctly. A work around is to replace the character class [a-z] with \w
in the appropriate rules in the grammar tree, but this could lower the accuracy
of names based purely on ASCII text.

=head1 CREDITS

Thanks to all the people who provided ideas and suggestions, including -

   Damian Conway,  author of Parse::RecDescent
   Mark Summerfield author of Lingua::EN::NameCase,
   Ron Savage, Alastair Adam Huffman, Douglas Wilson
   Peter Schendzielorz

=head1 AUTHOR

NameParse was written by Kim Ryan <kimryan at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Kim Ryan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
#-------------------------------------------------------------------------------

package Lingua::EN::NameParse;

use strict;
use warnings;

use Lingua::EN::NameParse::Grammar;
use Parse::RecDescent;

use Exporter;
use vars qw (@ISA @EXPORT_OK);

our $VERSION = '1.38';
@ISA       = qw(Exporter);
@EXPORT_OK = qw(clean case_surname);

#-------------------------------------------------------------------------------
# Create a new instance of a name parsing object. This step is time consuming
# and should normally only be called once in your program.

sub new
{
    my $class = shift;
    my %args = @_;

    my $name = {};
    bless($name,$class);

    # Default to 2 initials per name. Can be overwritten if user defines
    # 'initials' as a key in the hash supplied to new method.
    $name->{initials} = 2;

    my $current_key;
    foreach my $current_key (keys %args)
    {
        $name->{$current_key} = $args{$current_key};
    }

    my $grammar = Lingua::EN::NameParse::Grammar::_create($name);
    $name->{parse} = new Parse::RecDescent($grammar);

    return ($name);
}
#-------------------------------------------------------------------------------
# Attempt to parse a string and retrieve it's components and properties
# Requires a name object to have been created with the 'new' method'
# Returns: an error code, 0 for success, 1 for failure

sub parse
{
    my $name = shift;
    my ($input_string) = @_;

    chomp($input_string);

    # If reverse ordered names are allowed, swap the surname component, before
    # the comma, with the rest of the name. Rejoin the name, replacing comma
    # with a space.

    if ( $name->{allow_reversed} and $input_string =~ /,/ )
    {
        my ($first,$second) = split(/,/,$input_string);
        $input_string = join(' ',$second,$first);
    }

    $name->{comps} = ();
    $name->{properties} = ();
    $name->{properties}{type} = 'unknown';
    $name->{error} = 0;
    $name->{error_desc} = '';
    $name->{warning} = 0;
    $name->{warning_desc} = '';

    $name->{original_input} = $input_string;
    $name->{input_string} = $input_string;

    $name = _pre_parse($name);
    unless ( $name->{error} )
    {
        if ( $name->{auto_clean} )
        {
            $name->{input_string} = clean($name->{input_string});
        }        
        $name = _assemble($name);
        _validate($name);
    }

   return($name->{error});
}
#-------------------------------------------------------------------------------
# Clean the input string. Can be called as a stand alone function.

sub clean
{
    my ($input_string) = @_;

    # remove illegal characters
    $input_string =~ s/[^A-Za-z\-\'\.&\/ ]//go;

    # remove repeating spaces
    $input_string =~ s/  +/ /go ;

    # remove any remaining leading or trailing space
    $input_string =~ s/^ //;

    return($input_string);
}

#-------------------------------------------------------------------------------
# Given a name object, apply correct capitalisation to each component of a person's name.
# Return all cased components in a hash.
# Else return no value. 


sub components
{
    my $name = shift;

    if ( $name->{properties}{type} eq 'unknown'  )
    {
        return;
    }
    else
    {
        my %orig_components = %{ $name->{comps} };

        my ($current_key,%cased_components);
        foreach $current_key ( keys %orig_components )
        {
            my $cased_value;
            if ( $current_key =~ /initials/ ) # initials_1, possibly initials_2
            {
                $cased_value = uc($orig_components{$current_key});
            }
            elsif ( $current_key =~ /surname|suffix/ )
            {
               $cased_value = case_surname($orig_components{$current_key},$name->{lc_prefix});
            }
            elsif ( $current_key eq 'type')
            {
               $cased_value = $orig_components{$current_key};
            }            
            else
            {
                $cased_value = _case_word($orig_components{$current_key});
            }

            $cased_components{$current_key} = $cased_value;
        }
        return(%cased_components);
    }
}

#-------------------------------------------------------------------------------
# Hash of of lists, indicating the order that name components are assembled in.
# Each list element is itself the name of the key value in a name object.
# Used by the case_all and case_all_reversed  methods.
# These hashes are created here globally, as quite a large overhead is
# imposed if the are created locally, each time the method is invoked

my %component_order=
(
    'Mr_John_Smith_&_Ms_Mary_Jones' => ['title_1','given_name_1','surname_1','conjunction_1','title_2','given_name_2','surname_2'],
    'Mr_A_Smith_&_Ms_B_Jones' => ['title_1','initials_1','surname_1','conjunction_1','title_2','initials_2','surname_2'],
    'Mr_&_Ms_A_&_B_Smith'     => ['title_1','conjunction_1','title_2','initials_1','conjunction_2','initials_2','surname_1'],
    'Mr_A_&_Ms_B_Smith'       => ['title_1','initials_1','conjunction_1','title_2','initials_2','surname_1'],
    'Mr_&_Ms_A_Smith'         => ['title_1','conjunction_1','title_2','initials_1','surname_1'],
    'Mr_A_&_B_Smith'          => ['title_1','initials_1','conjunction_1','initials_2','surname_1'],
    'John_Smith_&_Mary_Jones' => ['given_name_1','surname_1','conjunction_1','given_name_2','surname_2'],
    'John_&_Mary_Smith'       => ['given_name_1','conjunction_1','given_name_2','surname_1'],
    'A_Smith_&_B_Jones'       => ['initials_1','surname_1','conjunction_1','initials_2','surname_2'],

    'Mr_John_Adam_Smith'      => ['precursor','title_1','given_name_1','middle_name','surname_1','suffix'],
    'Mr_John_A_Smith'         => ['precursor','title_1','given_name_1','initials_1','surname_1','suffix'],
    'Mr_John_Smith'           => ['precursor','title_1','given_name_1','surname_1','suffix'],
    'Mr_A_Smith'              => ['precursor','title_1','initials_1','surname_1','suffix'],
    'John_Adam_Smith'         => ['precursor','given_name_1','middle_name','surname_1','suffix'],
    'John_A_Smith'            => ['precursor','given_name_1','initials_1','surname_1','suffix'],
    'J_Adam_Smith'            => ['precursor','initials_1','middle_name','surname_1','suffix'],
    'John_Smith'              => ['precursor','given_name_1','surname_1','suffix'],
    'A_Smith'                 => ['precursor','initials_1','surname_1','suffix'],
    'John'                    => ['given_name_1']
);


# only include names with a single surname
my %reverse_component_order=
(
   'Mr_&_Ms_A_&_B_Smith'  => ['surname_1','title_1','conjunction_1','title_2','initials_1','conjunction_1','initials_2'],
   'Mr_A_&_Ms_B_Smith'    => ['surname_1','title_1','initials_1','conjunction_1','title_2','initials_2'],
   'Mr_&_Ms_A_Smith'      => ['surname_1','title_1','title_1','conjunction_1','title_2','initials_1'],
   'Mr_A_&_B_Smith'       => ['surname_1','title_1','initials_1','conjunction_1','initials_2'],
   'John_&_Mary_Smith'    => ['surname_1','given_name_1','conjunction_1','given_name_2'],

   'Mr_John_Adam_Smith'   => ['surname_1','title_1','given_name_1','middle_name','suffix'],
   'Mr_John_A_Smith'      => ['surname_1','title_1','given_name_1','initials_1','suffix'],
   'Mr_John_Smith'        => ['surname_1','title_1','given_name_1','suffix'],
   'Mr_A_Smith'           => ['surname_1','title_1','initials_1','suffix'],
   'John_Adam_Smith'      => ['surname_1','given_name_1','middle_name','suffix'],
   'John_A_Smith'         => ['surname_1','given_name_1','initials_1','suffix'],
   'J_Adam_Smith'         => ['surname_1','initials_1','middle_name','suffix'],
   'John_Smith'           => ['surname_1','given_name_1','suffix'],
   'A_Smith'              => ['surname_1','initials_1','suffix'],
   'John'                 => ['given_name_1']
);

#-------------------------------------------------------------------------------
# Apply correct capitalisation to a person's entire name
# If the name type is unknown, return undef
# Else, return a string of all cased components in correct order

sub case_all
{
    my $name = shift;

    my @cased_name;

    if ( $name->{properties}{type} eq 'unknown' )
    {
        return undef;
    }

    unless ( $component_order{$name->{properties}{type}} )
    {
        # component order missing in array defined above
        warn "Component order not defined for: $name->{properties}{type}";
        return;
    }

    my %component_vals = $name->components;
    my @order = @{ $component_order{$name->{properties}{type}} };

    foreach my $component_key ( @order )
    {
        # As some components such as precursors are optional, they will appear
        # in the order array but may or may not have have a value, so only
        # process defined values
        if ( $component_vals{$component_key} )
        {
           push(@cased_name,$component_vals{$component_key});
        }
    }
    if ( $name->{comps}{non_matching} )
    {
       # Despite errors, try to name case non-matching section. As the format
       # of this section is unknown, surname case will provide the best
       # approximation, but still fail on initials of more than 1 letter
       push(@cased_name,case_surname($name->{comps}{non_matching},$name->{lc_prefix}));
    }

    return(join(' ',@cased_name));
}

#-------------------------------------------------------------------------------
=head1 case_all_reversed

Apply correct capitalisation to a person's entire name and reverse the order
so that surname is first, followed by the other components, such as: Smith, Mr John A
Useful for creating a list of names that can be sorted by surname.

If name type is unknown , returns null

If the name type has a joint name, such as 'Mr_A_Smith_Ms_B_Jones', return null,
as it is ambiguous which surname to place at the start of the string

Else, returns a string of all cased components in correct reversed order

=cut

sub case_all_reversed
{
    my $name = shift;

    my @cased_name_reversed;

    unless ( $name->{properties}{type} eq 'unknown'  )
    {
        unless ( $reverse_component_order{$name->{properties}{type} } )
        {
            # this type of name should not be reversed, such as two surnames
            return;
        }
        my %component_vals = $name->components;
        my @reverse_order = @{ $reverse_component_order{$name->{properties}{type} } };

        foreach my $component_key ( @reverse_order )
        {
            # As some components such as precursors are optional, they will appear
            # in the order array but may or may not have have a value, so only
            # process defined values

            my $component_value = $component_vals{$component_key};
            if ( $component_value )
            {
                if ($component_key eq 'surname_1')
                {
                    $component_value .= ',';
                }
                push(@cased_name_reversed,$component_value);
            }
        }
    }
    return(join(' ',@cased_name_reversed));
}
#-------------------------------------------------------------------------------
# The user may specify their own preferred spelling for surnames.
# These should be placed in a text file called surname_prefs.txt
# in the same location as the module itself.

BEGIN
{
   # Obtain the full path to NameParse module, defined in the %INC hash.
   my $prefs_file_location = $INC{"Lingua/EN/NameParse.pm"};
   # Now substitute the name of the preferences file
   $prefs_file_location =~ s/NameParse\.pm$/surname_prefs.txt/;

   if ( open(PREFERENCES_FH,"<$prefs_file_location") )
   {
      my @surnames = <PREFERENCES_FH>;
      foreach my $name ( @surnames )
      {
         chomp($name);
         # Build hash, lower case name is key for case insensitive
         # comparison, while value holds the actual capitalisation
         $Lingua::EN::surname_preferences{lc($name)} = $name;
      }
      close(PREFERENCES_FH);
   }
}
#-------------------------------------------------------------------------------
# Apply correct capitalisation to a person's surname. Can be called as a
# stand alone function.

sub case_surname
{
    my ($surname,$lc_prefix) = @_;

    unless ($surname)
    {
        return('');
    }

    # If the user has specified a preferred capitalisation for this
    # surname in the surname_prefs.txt, it should be returned now.
    if ($Lingua::EN::surname_preferences{lc($surname)} )
    {
        return($Lingua::EN::surname_preferences{lc($surname)});
    }

    # Lowercase everything
    $surname = lc($surname);

    # Now uppercase first letter of every word. By checking on word boundaries,
    # we will account for apostrophes (D'Angelo) and hyphenated names
    $surname =~ s/\b(\w)/\u$1/g;

    # Name case Macs and Mcs
    # Exclude names with 1-2 letters after prefix like Mack, Macky, Mace
    # Exclude names ending in a,c,i,o,z or j, typically Polish or Italian

    if ( $surname =~ /\bMac[a-z]{2,}[^a|c|i|o|z|j]\b/i  )
    {
        $surname =~ s/\b(Mac)([a-z]+)/$1\u$2/ig;

        # Now correct for "Mac" exceptions
        $surname =~ s/MacHin/Machin/;
        $surname =~ s/MacHlin/Machlin/;
        $surname =~ s/MacHar/Machar/;
        $surname =~ s/MacKle/Mackle/;
        $surname =~ s/MacKlin/Macklin/;
        $surname =~ s/MacKie/Mackie/;

        # Portuguese
        $surname =~ s/MacHado/Machado/;

        # Lithuanian
        $surname =~ s/MacEvicius/Macevicius/;
        $surname =~ s/MacIulis/Maciulis/;
        $surname =~ s/MacIas/Macias/;
    }
    elsif ( $surname =~ /\bMc/i )
    {
        $surname =~ s/\b(Mc)([a-z]+)/$1\u$2/ig;
    }
    # Exceptions (only 'Mac' name ending in 'o' ?)
    $surname =~ s/Macmurdo/MacMurdo/;


    if ( $lc_prefix )
    {
        # Lowercase first letter of every word in prefix. The trailing space
        # prevents the surname from being altered. Note that spellings like
        # d'Angelo are not accounted for.
        $surname =~ s/\b(\w+ )/\l$1/g;
    }

    # Correct for possessives such as "John's" or "Australia's". Although this
    # should not occur in a person's name, they are valid for proper names.
    # As this subroutine may be used to capitalise words other than names,
    # we may need to account for this case. Note that the 's' must be at the
    # end of the string
    $surname =~ s/(\w+)'S(\s+)/$1's$2/;
    $surname =~ s/(\w+)'S$/$1's/;

    # Correct for roman numerals, excluding single letter cases I,V and X,
    # which will work with the above code
    $surname =~ s/\b(I{2,3})\b/\U$1/i;  # 2nd, 3rd
    $surname =~ s/\b(IV)\b/\U$1/i;      # 4th
    $surname =~ s/\b(VI{1,3})\b/\U$1/i; # 6th, 7th, 8th
    $surname =~ s/\b(IX)\b/\U$1/i;      # 9th
    $surname =~ s/\b(XI{1,3})\b/\U$1/i; # 11th, 12th, 13th

    return($surname);
}
#-------------------------------------------------------------------------------
# Create a personalised greeting from one or two person's names
# Returns the salutation as a string, such as "Dear Mr Smith", or "Dear Sue"

sub salutation
{
    my $name = shift;
    my %args = @_;

    my $salutation = 'Dear';
    my $sal_default = 'Friend';
    my $sal_type = 'title_plus_surname';

    # Check to see if we should override defualts with any user specified preferences
    if ( %args )
    {
        foreach my $current_key (keys %args)
        {
            $current_key eq 'salutation' and $salutation = $args{$current_key};
            $current_key eq 'sal_default' and $sal_default = $args{$current_key};
            $current_key eq 'sal_type' and $sal_type = $args{$current_key};
        }
    }


    my @greeting;
    push(@greeting,$salutation);

    # Personalised salutations cannot be created for Estates or people
    # without some title
    if
    (
        $name->{error} or
        ( $name->{comps}{precursor} and  $name->{comps}{precursor} =~ /ESTATE/)
    )
    {
        # Despite an error, the presence of a conjunction probably
        # means we are dealing with 2 or more people.
        # For example Mr AB Smith & John Jones
        if ( $name->{input_string} =~ / (AND|&) / )
        {
           $sal_default .= 's';
        }
        push(@greeting,$sal_default);
    }
    else
    {
        my %component_vals = $name->components;

        if ( $sal_type eq 'given_name')
        {
            if ( $component_vals{'given_name_1'} )
            {
                push(@greeting,$component_vals{'given_name_1'});
                if ( $component_vals{'given_name_2'} )
                {
                    push(@greeting,$component_vals{'conjunction_1'});
                    push(@greeting,$component_vals{'given_name_2'});
                }
            }
            else
            {
                # No given name such as 'A_Smith','J_Adam_Smith','Mr_A_Smith'
                # Must use default
                push(@greeting,$sal_default);
            }
        }
        elsif ( $sal_type eq 'title_plus_surname' )
        {
            if ( $name->{properties}{number} == 1 )
            {
                if ( $component_vals{'title_1'} )
                {
                    push(@greeting,$component_vals{'title_1'});
                    push(@greeting,$component_vals{'surname_1'});
                }
                else
                {
                    # No title such as 'A_Smith','J_Adam_Smith', so must use default
                    push(@greeting,$sal_default);
                }
            }
            elsif ( $name->{properties}{number} == 2 )
            {
                # a joint name

                my $type = $name->{properties}{type};
                if ( $type eq 'Mr_&Ms_A_Smith' or $type eq 'Mr_A_&Ms_B_Smith' or $type eq 'Mr_&Ms_A_&B_Smith' )
                {
                    # common surname
                    push(@greeting,$component_vals{'title_1'});
                    push(@greeting,$component_vals{'conjunction_1'});
                    push(@greeting,$component_vals{'title_2'});
                    push(@greeting,$component_vals{'surname_1'});

                }
                elsif ( $type eq 'Mr_A_Smith_&Ms_B_Jones' or $type eq 'Mr_John_Smith_&Ms_Mary_Jones' )
                {
                    push(@greeting,$component_vals{'title_1'});
                    push(@greeting,$component_vals{'surname_1'});
                    push(@greeting,$component_vals{'conjunction_1'});
                    push(@greeting,$component_vals{'title_2'});
                    push(@greeting,$component_vals{'surname_2'});
                }
                else
                {
                    # No title such as A_Smith_&B_Jones', 'John_Smith_&Mary_Jones'
                    # Must use default
                    push(@greeting,$sal_default);
                }
            }
        }
        else
        {
            warn "Invalid sal_type : ", $sal_type;
            push(@greeting,$sal_default);
        }
    }
    return(join(' ',@greeting));
}
#-------------------------------------------------------------------------------
# Return all name properties as a hash

sub properties
{
    my $name = shift;
    return(%{ $name->{properties} });
}

#-------------------------------------------------------------------------------
# Create a text report to standard output listing
# - the input string,
# - the name of each defined component, if it exists
# - any non matching component

sub report
{
    my $name = shift;
    
    my %props = $name->properties;
    
    my $fmt = "%-20.20s : %s\n";

    printf($fmt,"Original Input",$name->{original_input});
    printf($fmt,"Cleaned Input",$name->{input_string});
    printf($fmt,"Case all",$name->case_all);
    if ($name->case_all_reversed)
    {
        printf($fmt,"Case all reversed",$name->case_all_reversed);    
    }
    else
    {
        printf($fmt,"Case all reversed",'not applicable');
    }
    
    
    printf($fmt,"Salutation",$name->salutation(salutation => 'Dear',sal_default => 'Friend', sal_type => 'title_plus_surname'));
    printf($fmt,"Type", $props{type});
    printf($fmt,"Number", $props{number});
    printf($fmt,"Parsing Error", $name->{error});
    printf($fmt,"Error description : ", $name->{error_desc});
    printf($fmt,"Parsing Warning", $name->{warning});
    printf($fmt,"Warning description", $name->{warning_desc});    
    
 
    unless ($props{type} eq 'unknown')
    {
        my %comps = $name->components;
        if ( %comps )
        {
            print("\nCOMPONENTS\n");
            foreach my $value ( sort keys %comps)
            {
                 if ($value and $comps{$value})
                {
                    printf($fmt,$value,$comps{$value});
                }
            }
        }
    }
}    
#-------------------------------------------------------------------------------

# PRIVATE METHODS

#-------------------------------------------------------------------------------

sub _pre_parse
{
    my $name = shift;
    
    # strip all full stops    
    $name->{input_string}  =~ s/\.//g;
    
    # Fold all text to upper case, as these are used in all regular expressions withun thr grammar tree
    $name->{input_string}  = uc($name->{input_string});
    
    # Check that common reserved word (as found in company names) do not appear
    if ( $name->{input_string} =~
         /\BPTY LTD$|\BLTD$|\BPLC$|ASSOCIATION|DEPARTMENT|NATIONAL|SOCIETY/ )
    {
        $name->{error} = 1;
        $name->{comps}{non_matching} = $name->{input_string};
        $name->{error_desc} = 'Reserved words found in name';
    }

    # For the case of a single name such as 'Voltaire' we need to add a trailing space
    # to the input string. This is because the grammar tree expects a terminator (the space)
    # optionally followed by other productions or non matching text
    $name->{input_string} .= ' ';
    if ( $name->{input_string} =~ /^[A-Z]{2,}(\-)?[A-Z]{0,}$/ )
    {
        $name->{input_string} .= ' ';
    }
    return($name);

}
#-------------------------------------------------------------------------------
# Initialise all components to empty string. Assemble hashes of components
# and properties as part of the name object
#
sub _assemble
{
    my $name = shift;

    # Use Parse::RecDescent to do the parsing. 'full_name' is a label for the complete grammar tree
    # defined in Lingua::EN::NameParse::Grammar
    my $parsed_name = $name->{parse}->full_name($name->{input_string});
    
    # Place components into a separate hash, so they can be easily returned
    # for the user to inspect and modify.
    
    my @all_comps = qw(precursor title_1 given_name_1 initials_1 middle_name surname_1 conjunction_1 
    title_2 given_name_2 initials_2 surname_2 conjunction_2 suffix non_matching);
    
    foreach my $comp (@all_comps)
    {
        # set all components to empty string, as any of them could be accessed, even if they don't exist
         $name->{comps}{$comp} = '';
        if (defined($parsed_name->{$comp}))
        {
            # Copy over existing components.
             $name->{comps}{$comp} = _trim_space($parsed_name->{$comp});  
        }  
    }

    $name->{properties}{number} = 0;
    $name->{properties}{number} = $parsed_name->{number};
    $name->{properties}{type}   = $parsed_name->{type};

    return($name);
}
#-------------------------------------------------------------------------------
# For correct matching, the grammar of each component must include the trailing space that separates it
# from any following word. This should now be removed from the components, and will be restored by the
# case_all and salutation methods, if called.

sub _trim_space
{
    my ($string) = @_;
    if ($string)
    {
        $string =~ s/ $//;
    }   
    return($string);
}
#-------------------------------------------------------------------------------
# Check if any name components have illegal characters, or do not have the
# correct syntax for a valid name.


sub _validate
{
    my $name = shift;
     my %comps = $name->components;

    if ( $comps{non_matching} )
    {
        $name->{warning} = 1;
        $name->{warning_desc} .= ";non_matching text found : $comps{non_matching}";
    }
    elsif ( $name->{input_string} =~ /[^A-Za-z\-\'\.,&\/ ]/ )
    {
        # illegal characters found
        $name->{error} = 1;
        $name->{error_desc} = 'illegal characters found';
    }      
    

    if ( not _valid_name($comps{given_name_1}) )
    {
        $name->{warning} = 1;
        $name->{warning_desc} .= ";no vowel sound in given_name_1 : $comps{given_name_1}";
    }
    elsif ( not _valid_name($comps{middle_name}) )
    {
        $name->{warning} = 1;
        $name->{warning_desc} .= ";no vowel sound in middle_name : $comps{middle_name}";
    }

    elsif ( not _valid_name($comps{surname_1}) )
    {
        $name->{warning} = 1;
        $name->{warning_desc} .= ";no vowel sound in surname_1 : $comps{surname_1}";

    }
    elsif ( not _valid_name($comps{surname_2}) )
    {
        $name->{warning} = 1;
        $name->{warning_desc} .= ";no vowel sound in surname_2 : $comps{surname_2}";
    }
}
#-------------------------------------------------------------------------------
# If the name has an assigned value, check that it contains a vowel sound,
# or matches the exceptions to this rule.
# Returns 1 if name is valid, otherwise 0

sub _valid_name
{
    my ($name) = @_;
    if ( not $name )
    {
        return(1);
    }
    # Names should have a vowel sound,
    # valid exceptions are Ng, Tsz,Md, Cng,Hng,Chng etc
    elsif ( $name and $name =~ /[AEIOUYJ]|^(NG|TSZ|MD|(C?H|[PTS])NG)$/i )
    {
        return(1);
    }
    else
    {
        return(0);
    }
}
#-------------------------------------------------------------------------------
# Upper case first letter, lower case the rest, for all words in string
sub _case_word
{
    my ($word) = @_;

    if ($word)
    {
        $word =~ s/(\w+)/\u\L$1/g;
    }    
    
    return($word);
}
#-------------------------------------------------------------------------------
return(1);
