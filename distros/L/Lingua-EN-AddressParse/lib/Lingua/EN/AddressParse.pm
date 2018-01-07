=head1 NAME

Lingua::EN::AddressParse - extract components of a street address from free format text

=head1 SYNOPSIS

    use Lingua::EN::AddressParse;

    my %args =
    (
      country     => 'US',
      auto_clean  => 1,
      force_case  => 1,
      abbreviate_subcountry => 0,
      abbreviated_subcountry_only => 0,
      force_post_code => 0
    );

    my $address = Lingua::EN::AddressParse->new(%args);
    $error = $address->parse("40 1/2 N OLD MASSACHUSETTS AVE APT 3B Washington Valley Washington 98100: HOLD MAIL");
       
    print $address->report;       
       
        Country address format  'US'
        Address type            'suburban'
        Non matching part       'HOLD MAIL '
        Error                   '1'
        Error descriptions      'non matching section : HOLD MAIL '
        Warning                 '1'
        Warning description     ''
        Case all                '40 1/2 N Old Massachusetts Ave Apt 3B Washington Valley WA 98100'
        COMPONENTS              ''
        base_street_name        'Old Massachusetts'
        post_code               '98100'
        property_identifier     '40 1/2'
        street_direction_prefix 'N'
        street_name             'N Old Massachusetts'
        street_type             'Ave'
        sub_property_identifier '3B'
        sub_property_type       'Apt'
        subcountry              'WASHINGTON'
        suburb                  'Washington Valley'       

    %address_components = $address->components;
    print $address_components{sub_property_type};       # APT
    print $address_components{sub_property_identifier}; # 3B
    print $address_components{property_identifier};     # 40 1/2
   
    %address_properties = $address->properties;
    print $address_properties{type};            # suburban
    print $address_properties{non_matching};    # : HOLD MAIL

    $correct_casing = $address->case_all;


=head1 DESCRIPTION

This module takes as input a suburban, rural or postal address in free format
text such as,

    3080 28TH AVE N ST PETERSBURG, FL 33713-3810
    12 1st Avenue N Suite # 2 Somewhere CA 12345 USA
    C/O JOHN, KENNETH JR POA 744 WIND RIVER DR SYLVANIA, OH 43560-4317

    9 Church Street, Abertillery, Mid Glamorgan NP13 1DA
    27 Bury Street, Abingdon, Oxfordshire OX14 3QT

    2A O'CONNELL ST KEW NSW 2123
    12/3-5 AUBREY ST MOUNT VICTORIA VICTORIA 3133
    "OLD REGRET" WENTWORTH FALLS NSW 2782 AUSTRALIA
    GPO Box K318, HAYMARKET, NSW 2000

 
and attempts to parse it. If successful, the address is broken
down into it's components and useful functions can be performed such as :

    converting upper or lower case values to title case (2A O'Connell St Kew NSW 2123)
    extracting the addresses individual components      (2A,O'Connell,St,KEW,NSW,2123)
    determining the type of format the address is in    ('suburban')


If the address cannot be parsed you have the option of cleaning the address
of bad characters, or extracting any portion that was parsed and the portion
that failed.

This module can be used for analysing and improving the quality of
lists of residential and postal addresses.

By using a large combination of regular expressiosn with look ahead analysis, patterns
can be parsed that confuse many other parsers. Examples are

Street names with several street types: Lane Cove Road
Suburbs which include street types: Smith Road St Marys
Suburbs that include state names: Fort Washington Washington

=head1 DEFINITIONS

The following terms are used by AddressParse to define the components that
can make up an address.

    Pre cursor : C/O MR A Smith...
    Sub property identifier : Level 1A Unit 2, Apartment B, Lot 12, Suite # 12 ...
    Property Identifier : 12/66A, 24-34, 2A, 23B/12C, 12/42-44, 2.5
    Property name   : "Old Regret"
    Post Box        : GP0 Box K123, LPO 2345, RMS 23 ...
    Road Box        : RMB 24A, RMS 234 ...
    Street Direction: North, SE, Sth. etc
    Street name     : O'Hare, New South Head, The Causeway, Broadway
    Street type     : Road, Rd., St, Lane, Highway, Crescent, Circuit ...
    Suburb          : Dee Why, St. John's Wood ...
    Sub country     : NSW, New South Wales, ACT, NY, New Jersey AZ ...
    Post (zip) code : 2062, 34532-1234, SG12A 9ET
    Country         : Australia, UK, US or Canada



The main  address formats  currently supported are as follows. (a ? means the component is optional):

    'suburban' : sub_property(?) property_identifier(?) street street_type suburb subcountry post_code(?)country(?)

    OR for the USA
    'suburban' : property_identifier(?) street street_type sub_property(?) suburb subcountry post_code(?) country(?)

    'rural'    : property_name suburb subcountry post_code(?) country(?)
    'post_box' : post_box suburb subcountry post_code(?) country(?)
    'road_box' : road_box street street_type suburb subcountry post_code(?) country(?)
    'road_box' : road_box suburb subcountry post_code(?) country(?)
    
Note that suburb and subcountry are not optional. The accuracy of the parser is
improved by providing as much context as possible. Proding a suburb can ehlp to
identify street names that would itherwise be ambigious.

For the case where you only have a street address, dummy (but still valid) values can be used
for suburb (such as 'Somewhere') and sub country (such as 'NY'). These dummy values will
be parsed  but can be ignored.

All formats may contain a precursor

Refer to the component grammar defined in the Lingua::EN::AddressParse::Grammar
module for a complete list of combinations.


=head1 METHODS

=head2 new

The C<new> method creates an instance of an address object and sets up
the grammar used to parse addresses. This must be called before any of the
following methods are invoked. Note that the object only needs to be
created once, and can be reused with new input data.

Various setup options may be defined in a hash that is passed as an
optional argument to the C<new> method.

    my %args =
    (
      country     => 'US',
      auto_clean  => 1,
      force_case  => 1,
      abbreviate_subcountry => 1,
      abbreviated_subcountry_only => 1,
      force_post_code => 1
    );

    my $address = Lingua::EN::AddressParse->new(%args);

=over 4

=item country

The country argument must be specified. It determines the possible list of
valid sub countries (states, counties etc, defined in the Locale::SubCountry
module) and post code formats. Either the full name or abbreviation may be
specified. The currently supported country names and codes are:

    AU or Australia
    CA or Canada
    GB or United Kingdom
    US or United States

All forms of upper/lower case are acceptable in the country's spelling. If a
country name is supplied that the module doesn't recognise, it will die.

=item force_case (optional)

This option only applies to the C<case_all> method, see below.

=item auto_clean (optional)

When this option is set to a positive value, the input string is
'cleaned' to try and normalise bad patterns. The type of cleaning
includes

    remove non alphanumeric characters
    remove full stops
    remove redundant white space
    add missing space separators
    expand abbreviations to more common forms
    remove bracketed annotations
    fix badly formed sub property identifiers

=item abbreviate_subcountry (optional)

When this option is set to a positive value, the sub country is forced to it's
abbreviated form, so "New South Wales" becomes "NSW". If the sub country is
already abbreviated then it's value is not altered.

=item abbreviated_subcountry_only (optional)

When this option is set to a positive value, only the abbreviated form
of sub country is allowed, such as "NSW" and not "New South Wales". This
will make parsing quicker and ensure that addresses comply with postal
standards that normally permit only abbreviated sub countries.

It also avoids matching a sub_country name too early, as in the case of 'Port Washington New Jersey'
Normally, 'Washington would be consumed as the sub country, but by first converting
the address to 'Port Washington NJ' we avoid this problem


=item force_post_code (optional)

When this option is set to a positive value, the address must contain
a post code. If it does not then an error flag is raised. If this option
is set to 0 than a post code is optional.

By default for this option is true.

=back

=head2 parse

    $error = $address->parse("12/3-5 AUBREY ST VERMONT VIC 3133");

The C<parse> method takes a single parameter of a text string containing a
address. It attempts to parse the address and break it down into the components
described below. If the address is parsed successfully, a 0 is returned,
otherwise a 1.

Note that you can successfully parse all the components of an address and still
have an error returned. This occurs when you have non matching data following
a valid address. To check if the data is unusable, you also need to use the
C<properties> method to check the address type is 'unknown'

This method is a prerequisite for all the following methods.

=head2 components

    %address = $address->components($upper_case_all);
    $suburb = $address{suburb};
    
If the optional argument $upper_case_all is set to a postive value, all components
are converted to upper case.
    

The C<components> method returns all the address components in a hash. The
following keys are used for each component:


    pre_cursor - such as 'C/O Mr A Smith'
    po_box_type - such as 'Private Boxes'
    post_box
    road_box
    sub_property_type
    sub_property_identifier
    property_identifier
    property_name
    level - such as 12th Floor
    building - such as Tower A
    street_direction_prefix (such as East, NW, North etc)
    base_street_name (the name with direction removed, such as "Main" in "East Main St")
    street_name (the full street name such as "East Main")
    street_type
    street_direction_suffix (US only, abbreviated only such as N, SE etc)
    suburb
    subcountry
    post_code
    country

If a component has no matching data for a given address, it's values will be
set to the empty string.

Each component is converted to title case, meaning the first letter of each
component is set to capitals and the remainder to lower case.

Proper name capitalisations such as MacNay and O'Brien are observed

The following components are not converted to title case:

    post_box
    road_box
    subcountry
    post_code
    country
    street_direction_suffix
    
If your input data is all upper case and you want to retian that format for parsed
data, you will need to apply the 'uc' function to each component.

=head2 case_all

    $correct_casing = $address->case_all;

The C<case_all> method does the same thing as the C<components> method except
the entire address is returned as a title cased text string.

If the force_case option was set in the C<new> method above, address case the
entire input string, including any unmatched sections after a recognisable address
that failed parsing. This option is useful when you know you have invalid data,
but you still want to title case what you have.

=head2 properties

The C<properties> method returns several properties of the address as a hash.
The  following keys are used for each property -

    type - either suburban ,rural,post_box,road_box,unknown
    non_matching - any trailing string not part the address


Additional properties can be accessed with the following

  $address->{original_input}
  $address->{input_string} - string after auto_clean option has been applied
  $address->{country_code} - abbreviated Country address format (as defined in the C<new> method)
  $address->{error} - error flag, 0 = good, 1 = error
  $address->{error_desc} - text to describe the type of parsing error
  $address->{warning} - warning flag, 0 = good, 1 = warning
  $address->{warning_desc} - text to to describe the type of parsing warning(s)
  
Warnings mean that the address has parsed but there may still be errors within it's components  


=head2 report

Create a formatted text report

    the input string
    the cleaned input string
    the country type
    the address type
    any non matching part of input string
    if any parsing errors occurred
    error description
    if any parsing warning occurred
    warning description

    the name and value of each defined component


Returns a string containing a multi line formatted text report

=head1 DEPENDENCIES

L<Lingua::EN::NameParse>, L<Locale::SubCountry>, L<Parse::RecDescent>

=head1 BUGS

=head1 LIMITATIONS

Streets such as 'The Esplanade' will return a street of 'The Esplanade' and a
street type of null string.

The abbreviation 'St' can be interpreted as either street or Saint. This leads to
ambiguities such as '12 East St Thomas Lane'. This could be 'East Street', suburb of
'Thomas Lane' or 'East St Thomas Lane'. And the first pattern is the more common,
that is what will match.

For US addresses, an ambiguity arises between a street directional suffix and
a suburb directional prefix, such as '12 Main St S Springfield CA 92345'. Is it South
Main St, or South Springfield? The parser assumes that 'S' belongs to the street
description.

The huge number of character combinations that can form a valid address makes
it is impossible to correctly identify them all.

Valid addresses must contain:

    property address, suburb, subcountry (aka state) in that order.

This format is widely accepted in Australia and the US.

UK addresses will often include suburb, town, city and county, formats that
are very difficult to parse.

Property names must be enclosed in single or double quotes like "Old Regret"

Because of the large combination of possible addresses defined in the grammar,
the program is not very fast.


=head1 REFERENCES

"The Wordsworth Dictionary of Abbreviations & Acronyms" (1997)

Australian Standard AS4212-1994 "Geographic Information Systems -
Data Dictionary for transfer of street addressing information"

ISO 3166-2:1998, Codes for the representation of names of countries
and their subdivisions. Also released as AS/NZS 2632.2:1999


=head1 SEE ALSO

AddressParse is designed to identify properties, which have a unique physical
location. L<Geo::StreetAddress::US> will also parse addresses for the USA, and can handle
locations defined by street intersections, such as: "Hollywood & Vine, Los Angeles, CA"
"Mission Street at Valencia Street, San Francisco, CA"


    L<Lingua::EN::NameParse>
    L<Geo::StreetAddress::US>
    L<Parse::RecDescent>
    L<Locale::SubCountry>

See L<http://www.upu.int/post_code/en/postal_addressing_systems_member_countries.shtml>
for a list of different addressing formats from around the world. And also
L<http://www.bitboost.com/ref/international-address-formats.html>

=head1 REPOSITORY

L<https://github.com/kimryan/Lingua-EN-AddressParse>

=head1 TO DO

Define grammar for other languages. Hopefully, all that would be needed is
to specify a new module with its own grammar, and inherit all the existing
methods. I don't have the knowledge of the naming conventions for non-english
languages.

=head1 AUTHOR

AddressParse was written by Kim Ryan <kimryan at cpan d o t org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Kim Ryan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

#------------------------------------------------------------------------------

package Lingua::EN::AddressParse;

use strict;
use Carp;
use warnings;
use Lingua::EN::AddressParse::Grammar;
use Lingua::EN::NameParse;
use Parse::RecDescent;

our $VERSION = '1.27';

#------------------------------------------------------------------------------
# Create a new instance of an address parsing object. This step is time
# consuming and should normally only be called once in your program.

sub new
{
    my $class = shift;
    my %args = @_;


    unless (defined $args{country} and $args{country} =~ /^(AU|Australia|GB|United Kingdom|US|United States|CA|Canada)$/ )
    {
        croak "Cannot start parser. You must specify a value for the country in the options hash.\nValid options are AU,GB,US or CA.\n";
    }
    
    my $address = {};
    bless($address,$class);

    # option defaults
    $address->{'force_post_code'} = 1;

    # Add error checking for invalid keys?
    foreach my $curr_key (keys %args)
    {
        $address->{$curr_key} = $args{$curr_key};
    }

    # create the grammar tree (this is country dependent)
    my $grammar = Lingua::EN::AddressParse::Grammar::_create($address);

    $address->{parse} = Parse::RecDescent->new($grammar);

    return ($address);
}
#------------------------------------------------------------------------------
sub parse
{
    my $address = shift;
    my ($input_string) = @_;

    # Save original data so we can check effect of auto cleaning
    $address->{original_input} = $input_string;

    # Convert to all upper case. This will allow for faster regexp matching in
    # the grammar tree
    $address->{input_string} = uc($input_string);

    chomp($address->{input_string});

    my $pre_cursor;
    ($pre_cursor,$address->{input_string}) = _extract_precursor($address->{input_string});
    
    # Replace commas (which can be used to chunk sections of addresses) with spaces
    $address->{input_string} =~ s/,/ /g;
    
    if ( $address->{auto_clean} )
    {
        $address->{input_string} = _clean($address);
    }    

    my $po_box_type;
    ($po_box_type,$address->{input_string}) = _extract_po_box_type($address->{input_string});
    
    my $level;
    ($level,$address->{input_string}) = _extract_level($address->{input_string});
    
    my $building;
    ($building,$address->{input_string}) = _extract_building($address->{input_string});    
    

    
    # Normalise sub property ID, 4/22-24 => UNIT 4 22-24, 4 12 => Unit 4 12
    if ($address->{country_code} ne 'US' and $address->{input_string} =~ /^(\d{1,4}[A-Z]{0,2})[\/| ](\d+[ \w-].*)$/ )
    {
        $address->{input_string} = "UNIT $1 $2";     
    }    

    # We need to add a trailing space to the input string. This is because the grammar
    # tree expects a terminator (the space) fro every production, optionally followed
    # by other productions or any final non matching text.
    # This space will be removed in the _assemble function
    $address->{input_string} .= ' ';

    $address = _assemble($address,$pre_cursor,$po_box_type,$level,$building);
    _validate($address);


    return($address,$address->{error});
}

#------------------------------------------------------------------------------
# Apply correct capitalisation to each component of an address

sub components
{
    my $address = shift;
    my ($uc_all) = @_;

    my %orig_components = %{ $address->{components} };

    my (%cased_components);
    foreach my $curr_key ( keys %orig_components )
    {
        my ($cased_value, $curr_value);
        
        if ( $orig_components{$curr_key})
        {
            $curr_value = $orig_components{$curr_key};
        }
        else
        {
            $curr_value = '';
        }
                
        
        if ($uc_all)
        {
            $cased_components{$curr_key} = uc($curr_value);
            next;            
        }
        

        if ( $curr_key =~ /^(base_street_name|street_name|street_type|suburb|property_name|sub_property|pre_cursor|po_box_type|level|building)/ )
        {

            if ( $curr_key eq 'street_name' and$curr_value =~ /^US HIGHWAY (.*)/ )
            {
                $cased_value = "US Highway $1";
            }
            elsif  ( $curr_key eq 'sub_property_identifier' )
            {
                # UNIT, APT ... 12D etc

                my @words = split(/ /,$curr_value);
                my @cased_words;
                my $cased_string;
                foreach my $word (@words)
                {
                    my $cased_word;
                    if ( $word =~ /^\d{1,3}(ST|ND|RD|TH)$/)
                    {
                        # ordinal component, as in  3rd Floor
                        $cased_word = lc($word);
                    }
                    elsif ( length($word) > 1 and $word !~ /\d/ )
                    {
                        # only need to title case words such as UNIT
                        $cased_word = Lingua::EN::NameParse::case_surname($word);
                    }
                    else
                    {
                        $cased_word = $word;
                    }
                    push(@cased_words,$cased_word);

                }
                $cased_value = join(' ',@cased_words);
            }
            else
            {
                if ($curr_value)
                {
                    # Surnames can be used for street's or suburbs so this method
                    # will give correct capitalisation for most cases
                    $cased_value = Lingua::EN::NameParse::case_surname($curr_value);
                }
                else
                {
                    $cased_value = '';
                }
            }
        }
        # retain street_direction,sub country and countries capitalisation, usually uppercase
        elsif ($curr_key =~ /street_direction/)
        {
            if (length($curr_value) == 1 or length($curr_value) == 2)
            {
                # N, SE etc is capitalised
                $cased_value =$curr_value;
            }
            elsif (length($curr_value) > 2)
            {
                $cased_value = Lingua::EN::NameParse::case_surname($curr_value);
            }
            else
            {
                $cased_value = '';
            }
        }
        # retain sub country and countries capitalisation, as usually uppercase
        else
        {
            $cased_value = uc($curr_value);
        }
        $cased_components{$curr_key} = $cased_value;
    }
    return(%cased_components);
}
#------------------------------------------------------------------------------
# Apply correct capitalisation to an entire address

sub case_all
{
    my $address = shift;

    my @cased_address;

    unless ( $address->{properties}{type} eq 'unknown' )
    {

        # Hash of of lists, indicating the order that address components are assembled in.
        # Each list element is itself the name of the key value in an address object.

        my %component_order=
        (
           'rural'   => [ qw/pre_cursor property_name suburb subcountry post_code country/],
           'post_box'=> [ qw/pre_cursor post_box suburb po_box_type subcountry post_code country/ ],
           'road_box'=> [ qw/pre_cursor road_box street_name street_type suburb subcountry post_code country/ ]

        );
        if ( $address->{country} eq 'US' )
        {
           $component_order{'suburban'} = [ qw/pre_cursor property_identifier street_name  street_type street_direction_suffix  building level sub_property_type sub_property_identifier suburb subcountry post_code country/];
        }
        else
        {
           $component_order{'suburban'} = [ qw/pre_cursor building level sub_property_type sub_property_identifier property_identifier street_name  street_type suburb subcountry post_code country/ ];
        }

        my %component_vals = $address->components;
        my @order = @{ $component_order{$address->{properties}{type} } };

        foreach my $component ( @order )
        {
            # As some components such as property name are optional, they will appear
            # in the order array but may or may not have have a value, so check
            # for undefined values
            if ( $component_vals{$component} )
            {
                push(@cased_address,$component_vals{$component});
            }
        }
    }

    if ( $address->{error} and $address->{force_case} )
    {
        # Despite errors, try to name case non-matching section. As the format
        # of this section is unknown, surname case will provide the best
        # approximation
        push(@cased_address,&Lingua::EN::NameParse::case_surname($address->{properties}{non_matching}));
    }

    return(join(' ',@cased_address));
}
#------------------------------------------------------------------------------
sub properties
{
    my $address = shift;
    return(%{ $address->{properties} });
}

#------------------------------------------------------------------------------
# Create a text report to standard output listing
# - the input string,
# - the name of each defined component
# - any non matching component

sub report
{
    my $address = shift;

    my $report = '';

    _fmt_report_line(\$report,"Original Input",$address->{original_input});
    _fmt_report_line(\$report,"Cleaned Input",$address->{input_string});
    _fmt_report_line(\$report,"Country address format",$address->{country_code});

    my %props = $address->properties;
    if ( $props{type} )
    {
        _fmt_report_line(\$report,"Address type",$props{type});
    }


    _fmt_report_line(\$report,"Non matching part",$props{non_matching});
    _fmt_report_line(\$report,"Error",$address->{error});
    _fmt_report_line(\$report,"Error descriptions",$address->{error_desc});
    _fmt_report_line(\$report,"Warning",$address->{error});
    _fmt_report_line(\$report,"Warning description",$address->{warning_desc});    
    _fmt_report_line(\$report,"Case all",$address->case_all);


    _fmt_report_line(\$report,"COMPONENTS",'');
    my %comps = $address->components;
    foreach my $comp ( sort keys %comps)
    {
        if (defined($comps{$comp})  )
        {
            _fmt_report_line(\$report,$comp,$comps{$comp});
        }
    }

    return($report);
}


#------------------------------------------------------------------------------

# PRIVATE METHODS

#------------------------------------------------------------------------------

sub _assemble
{

    my $address = shift;
    my ($pre_cursor,$po_box_type,$level,$building) = @_;

    # Parse the address according to the rules defined in the AddressParse::Grammar module,
    # $::RD_TRACE  = 1;  # for debugging RecDescent output
    # Use Parse::RecDescent to do the parsing. 'full_address' is a label for the complete grammar tree
    my $parsed_address = $address->{parse}->full_address($address->{input_string});

    # Place components into a separate hash, so they can be easily returned to the user to inspect and modify
    $address->{components} = ();

    if ($pre_cursor)
    {
        $address->{components}{'pre_cursor'} = $pre_cursor;
    }
    else
    {
        $address->{components}{'pre_cursor'} = '';
    }
    
    if ($level)
    {
        $address->{components}{'level'} = $level;
    }
    else
    {
        $address->{components}{'level'} = '';
    }
    
    if ($building)
    {
        $address->{components}{'building'} = $building;
    }
    else
    {
        $address->{components}{'building'} = '';
    }       
        

    if ($po_box_type)
    {
        $address->{components}{'po_box_type'} = $po_box_type;
    }
    else
    {
        $address->{components}{'po_box_type'} = '';
    }
  

    $address->{components}{post_box} = '';
    if ( $parsed_address->{post_box} )
    {
        $address->{components}{post_box} = $parsed_address->{post_box};
    }

    $address->{components}{road_box} = '';
    if ( $parsed_address->{road_box} )
    {
        $address->{components}{road_box} = $parsed_address->{road_box};
    }

    $address->{components}{property_name} = '';
    if ( $parsed_address->{property_name} )
    {
        $address->{components}{property_name} = $parsed_address->{property_name};
    }

    $address->{components}{sub_property_identifier} = '';
    $address->{components}{sub_property_type} = '';
    
    if ( $parsed_address->{sub_property} )
    {
        if ($parsed_address->{sub_property} =~ /^(#|[A-Z]{1,}) (.*)$/ )
        {
            # Such as Unit 24, # 4A etc
            $address->{components}{sub_property_type} = $1;
            $address->{components}{sub_property_identifier} = $2;
        }
        elsif ($parsed_address->{sub_property} =~ /^(\d\w\w) (.*)$/ )
        {
            # Such as 1st Floor
            $address->{components}{sub_property_type} = $2;
            $address->{components}{sub_property_identifier} = $1;
        }        
    }

    $address->{components}{property_identifier} = '';
    if ( $parsed_address->{property_identifier} )
    {
        $address->{components}{property_identifier} = $parsed_address->{property_identifier};
    }
    
    ($address->{components}{street_direction_prefix},$address->{components}{base_street_name}) = _get_street_direction($parsed_address->{street_name});

    $address->{components}{street_name} = '';
    $address->{components}{street_type} = '';
    if ( $parsed_address->{street_name} )
    {
        # Streets such as 'The Corso' will parse as street_name = 'The' and street_type = 'Corso', so seperate out
        if ( $parsed_address->{street_name} eq 'THE ' )
        {
             $address->{components}{street_name} = 'THE ' . $parsed_address->{street_type};
        }
        else
        {
            $address->{components}{street_name} = $parsed_address->{street_name};
            $address->{components}{street_type} = $parsed_address->{street_type};
        }
    }

    $address->{components}{street_direction_suffix} = '';
    if ( $parsed_address->{street_direction_suffix} )
    {
        $address->{components}{street_direction_suffix} =  $parsed_address->{street_direction_suffix};
    }


    $address->{components}{suburb} = '';
    if ( $parsed_address->{suburb} )
    {
        $address->{components}{suburb} =  $parsed_address->{suburb};
    }

    $address->{components}{subcountry} = '';
    if ( $parsed_address->{subcountry} )
    {
        my $sub_country = $parsed_address->{subcountry};

        # Force sub country to abbreviated form, South Australia becomes SA, Michigan become MI etc
        if ($address->{abbreviate_subcountry})
        {
            my $country = Locale::SubCountry->new($address->{country});
            my $code = $country->code($sub_country);
            if ( $code ne 'unknown' )
            {
                $address->{components}{subcountry} = $code;
            }
            # sub country already abbreviated
            else
            {
                $address->{components}{subcountry} = $sub_country;
            }
        }
        else
        {
           $address->{components}{subcountry} = $sub_country;
        }
    }

    $address->{components}{post_code} = '';
    if ( $parsed_address->{post_code} )
    {
        $address->{components}{post_code} = $parsed_address->{post_code};
    }

    $address->{components}{country} = '';
    if ( $parsed_address->{country} )
    {
        $address->{components}{country} = $parsed_address->{country};
    }

    $address->{properties} = ();

    $address->{properties}{non_matching} = '';
    if ( $parsed_address->{non_matching} )
    {
        $address->{properties}{non_matching} = $parsed_address->{non_matching};
    }
    $address->{properties}{type} = $parsed_address->{type};
    
    _trim_trailing_space($address);

    return($address);
}

#-------------------------------------------------------------------------------
#
sub _get_street_direction
{
    my ($street_name) = @_;

    my $street_direction;
    my $base_street_name;

    unless ($street_name)
    {
        return;
    }

    my @words = split(/\s/,$street_name);
    if (@words > 1)
    {
        if  ( $words[0] =~ /^(N|NE|NW|E|S|SE|SW|W|NORTH|EAST|SOUTH|WEST|NTH|STH)$/ )
        {
            $street_direction = $1;
            shift(@words);
            $base_street_name = join(' ',@words);
        }
        else
        {
            $street_direction = '';
            $base_street_name = $street_name;
            
        }
    }
    else
    {
        $base_street_name = $street_name;
    }
    return($street_direction,$base_street_name);

}

#------------------------------------------------------------------------------
# Check for several different types of syntax errors

sub _validate
{
    my $address = shift;
    $address->{error} = 0;
    $address->{error_desc} = '';
    $address->{warning} = 0;
    $address->{warning_desc} = '';

    if ( $address->{properties}{non_matching} )
    {
        $address->{error} = 1;
        $address->{error_desc} = 'non matching section : ' . $address->{properties}{non_matching};
    }
    else
    {
        if ( $address->{properties}{type} eq 'unknown' )
        {
            $address->{error} = 1;
            $address->{error_desc} .= 'unknown address format';
        }
        else
        {
            if ($address->{force_post_code} and not $address->{components}{post_code})
            {
                $address->{error} = 1;
                $address->{error_desc} .= ':no post code';
            }

            # illegal characters found, note a '#' can appear as an abbreviation for number in USA addresses
            if ( $address->{input_string} =~ /[^"A-Z0-9'\-\.,&#\/ ]/ )
            {
                # Note, if auto_clean is on, illegal characters will have been removed
                # for second parsing and no error flag or message reported
                $address->{error} = 1;
                $address->{error_desc} .= ':illegal chars';
            }
            if ( $address->{properties}{type} eq 'suburban' )
            {
                my $street = $address->{components}{street_name};
                if ($street !~ /\d/ )
                {
                    # Not an ordinal or single letter street type
                    if ( _check_vowel($address->{components}{base_street_name}) )
                    {
                        # street name must have a vowel sound,
                        $address->{warning} = 1;
                        $address->{warning_desc} .= ";no vowel sound in street word : $address->{components}{base_street_name}";
                    }
                }
            }

            if ( _check_vowel($address->{components}{suburb}) )
            {
                $address->{warning} = 1;
                $address->{warning_desc} .= ";no vowel sound in suburb word : $address->{components}{suburb}";
            }
        }
    }
}
#-------------------------------------------------------------------------------
# Purge the input string of illegal or redundant characters.
# Correct malformed patterns

sub _clean
{
    my $address = shift;

    my ($input) = $address->{input_string};

    # Remove annotations enclosed in brackets, such as 1 Smith St (Cnr Brown St)
    $input =~ s|\(.*\)||;
   
   # Normalise half house numbers, such as 12.5 to 12 1/2. This is needed now before full stops are stripped out         
    $input =~ s|^(\d{1,4})\.5 |$1 1/2 |;        

    # strip full stops, remove illegal characters
    # & can be part of property name
    # hash (#) may denote number for USA address
    # quotes can occur as property name delimiters

    $input =~ s|[^A-Za-z0-9&#/'" -]||go;

    # remove repeating, leading and trailing spaces
    $input =~ s|  +| |go ;
    $input =~ s|^ ||;
    $input =~ s| $||;


    # Expand abbreviations that are too short

    $input =~ s/LAKE ST (GEORGE|CLAIR)/LAKE SAINT $1/; # otherwise St gets consumed to early as 'Street'
    $input =~ s| CSEWY | CAUSEWAY |;

    # Standardise abbreviations

    $input =~ s|STR |ST |;
    $input =~ s|TERR |TERRACE |;
    
    $input =~ s|^FCTR?Y |FACTORY |;
    $input =~ s|^FACT?R?Y? |FACTORY |;

    $input =~ s|LVL |LEVEL |; # sub property identifiers
    $input =~ s|^UN? |UNIT |;
    $input =~ s|^U(\d+)|UNIT $1|;

    # Fix badly formed number dividers such as home unit format of 14/ 12 becomes 14/12, 2- 7A becomes 2-7A
    $input =~ s|/ |/|;
    $input =~ s| /|/|;
    $input =~ s|- |-|;
    $input =~ s| -|-|;    

    # Remove redundant spaces in property identifiers,  21 B Smith St becomes 21B Smith St

    if ( $input !~ /^\d+ [A-Z] (ST|AVE)/ )
    {
        # Don't remove space before single letter streets such as 21 B Street
        if ( $address->{country_code} eq 'US' )
        {
            # Note cannot use N,E,S,W as they can be street direction prefix, as in 1 E MAIN STREET
            # Assume that the direction prefix is the more likely case
            $input =~ s|^(\d+) ([A-DF-MO-RT-VX-Z] )|$1$2|;
        }
        else
        {
            $input =~ s|^(\d+) ([A-Z] )|$1$2|;
        }
    }

    # Normalise sub property identifiers
    if ( $address->{country_code} eq 'US' )
    {
        # Fix US sub property identifiers that appear after street name and type
        # add space between # or 'Apt' and the number so #2 becomes '# 2'
        $input =~ s| #(\d)| # $1|;
        $input =~ s| #([A-Z])| # $1|;
        $input =~ s| (APT)(\d)| $1 $2|i;
        
        $input =~ s| (APT)-(\w)| $1 $2|i;

        # remove redundant space so # 34 B becomes # 34B
        $input =~ s| # (\d+) (\w) | # $1$2 |;

        # remove redundant '#'
        $input =~ s/ (APT|SUITE|UNIT) #/ $1 /;
        # still to test
    }
    else
    {
        # Add a space to separate sub property type from number, UNIT2 becomes UNIT 2
        $input =~ s/^(UNIT|LOT|APT|SHOP)(\d)/$1 $2/;
    }

    # Remove redundant slash or dash
    # Unit 1B/22, becomes Unit 1B 22, Flat 2-12 becomes Flat 2 12    
    $input =~ s/^([A-Z]{2,}) (\d+[A-Z]?)[\/-]/$1 $2 /;
    # Unit J1/ 39 becomes  Unit J1 39
    $input =~ s/^([A-Z]{2,}) ([A-Z]\d{0,3})[\/-]/$1 $2 /;


    # remove dash that does not from a sequence, such as D-5 or 22-A
    $input =~ s|([A-Z])-(\d)|$1$2|;
    $input =~ s|(\d)-([A-Z])|$1$2|;
    

    return($input);
}
#-------------------------------------------------------------------------------
# Remove any "care of" type of precursor from the main address
# such as: C/O BRAKEFIELD  BETTY S PO BOX 214 GULF HAMMOCK, FL 32639-0214
# It will later be saved as an attribute in the address object

sub _extract_precursor
{
    my ($input) = @_;
    my ($pre_cursor,$address_start,$address_end);

    if ($input =~ m{^(C/O.*?|ATTN.*?) (\d+|PO BOX)( .*)})
    {
        $pre_cursor = $1;
        $address_start = $2;
        $address_end = $3;
        return($pre_cursor, $address_start . $address_end);
    }
    else
    {
        return('',$input)
    }
}
#-------------------------------------------------------------------------------
# Remove any level or floor info such as:
# 12 Smith St Floor 2
# Level 22 Suite 3 12 Main St
# It will later be saved as an attribute in the address object

sub _extract_level
{
    my ($input) = @_;
    my ($level);
    
    if    
    (
        # Level info could be at start of string so first space is optional
        # TO DO, add lower?, mezz, BASEMENT etc?
        $input =~ / ?((GROUND|FIRST|SECOND|THIRD|FOURTH|FIFTH|SIXTH) (FLOOR|FLR|FL) )/ or      
        $input =~ / ?(\d{1,2}(ST|ND|RD|TH) (FLOOR|FLR|FL) )/ or       
        $input =~ / ?(LEVEL (\d{1,2}|[GM])[\/ -])/ or
        $input =~ / ?((FLOOR|FLR|FL) \d{1,2}[\/ -])/
     )
    {
        $level = $1;
        $level =~ s|/||;
        $level =~ s|-||;
        $input =~ s/$level//;
    }
 
    return($level,$input);
}
#-------------------------------------------------------------------------------
# Remove any building info such as:
# Building 2 Level 12 123 Smith St
# 12 Main St Tower A Level 2
# It will later be saved as an attribute in the address object

sub _extract_building
{
    my ($input) = @_;
    my ($building);
    
    my $building_label = qr{BLOCK|BLDG?|BUILDING|TOWER};
    my $id = qr{[A-Z]|A[A-Z]|\d+|\d{1,3}[A-Z]|[A-Z]\d{1,3}}; #  AA or 12  or 32C or C12
    
    if    
    (
        $input =~ /^($building_label $id) / or $input =~ / ($building_label $id) /
     )
    {
        $building = $1;
        $building =~ s|/||;
        $building =~ s|-||;
        $input =~ s/$building//;
    }
    # TO DO, North, East etc Building? 
    
    
    my $name = qr{[A-Z]+}; #
    my $house;
    
    # Allow for x house at start of text only. Not for example: 12 Gate House Road, suburb
    if ( $input =~  /^(($name )?$name HOUSE) /   )
    {
        $house = $1;       
        $input =~ s/$house//;
        $building .= $house;
    }
 
    return($building,$input);
}

#-------------------------------------------------------------------------------
# Remove any description that follows the suburb after the main address
# such as: PO BOX 1305 BIBRA LAKE PRIVATE BOXES WA 6965"
# It will be saved as an address attribute

sub _extract_po_box_type
{
    my ($input) = @_;
    my ($po_box_type,$address_start,$address_end);

    if ($input =~ /^(.*?) (PRIVATE BOXES)( .*)$/ )
    {
        $address_start = $1;
        $po_box_type = $2;
        $address_end = $3;
        return($po_box_type, $address_start . $address_end);
    }
    else
    {
        return('',$input)
    }
}
#------------------------------------------------------------------------------
# For correct matching, the grammar of each component must include the
# trailing space that separates it from any following word. This should
# now be removed from each component

sub _trim_trailing_space
{
    my ($address) = @_;
    
    foreach my $key (keys %{ $address->{components} } )
    {
        if ($address->{components}{$key} )
        {
            $address->{components}{$key}  =~ s/ $//g;
        }
    }         
}
#------------------------------------------------------------------------------

sub _fmt_report_line
{
    my ($report_ref,$label,$value) = @_;    
    $$report_ref .= sprintf("%-23.23s '%s'\n",$label,$value);
}
#------------------------------------------------------------------------------

sub _check_vowel
{
    my ($str) = @_;

    my @words = split(/ /,$str);
    foreach my $word (@words)
    {
        #  Saint, Mount, Junior, Senior (as in Dr Martin Luther King Snr)
        if ( length($word) > 1 and $word !~ /[AEIOUY]|ST|MT|DR|JN?R|SN?R/ )  
        {
            return(1);
        }
    }
    return(0);
}
#------------------------------------------------------------------------------

return(1);
