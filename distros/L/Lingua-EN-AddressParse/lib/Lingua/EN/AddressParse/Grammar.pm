=head1 NAME

Lingua::EN::AddressParse::Grammar - grammar tree for Lingua::EN::AddressParse

=head1 SYNOPSIS

Internal functions called from AddressParse.pm module

=head1 DESCRIPTION

Grammar tree of postal address syntax for Lingua::EN::AddressParse module.

The grammar defined here is for use with the Parse::RecDescent module.
Note that parsing is done depth first, meaning match the shortest string first.
To avoid premature matches, when one rule is a sub set of another longer rule,
it must appear after the longer rule. See the Parse::RecDescent documentation
for more details.

=head1 AUTHOR

Lingua::EN::AddressParse::Grammar was written by Kim Ryan, kimryan at cpan d-o-t or g

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Kim Ryan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
#-------------------------------------------------------------------------------

package Lingua::EN::AddressParse::Grammar;
use strict;
use warnings;
use Locale::SubCountry;

our $VERSION = '1.27';

#-------------------------------------------------------------------------------
# Rules that define valid orderings of an addresses components
# A (?) refers to an optional component, occurring 0 or more times.
# Optional items are returned as an array, which for our case will
# always consist of one element, when they exist.

my $non_usa_suburban_address_rules =
q{
    full_address :

    # Note: both sub property and property identifiers should be optional. This
    # will allow for cases such as 'Lot 123 Xyz Street' where Lot is in effect the house number, even though 'Lot' is grouped as a sub_property label
    # Also, cases such as 'SHOP 12A, CHAPEL RD STH' have no street number so are incomplete, but still may need to be parsed

    sub_property(?) property_identifier(?) street_untyped suburb subcountry post_code(?) country(?) non_matching(?)
    {
        # block of code to define actions upon successful completion of a
        # 'production' or rule

        $return =
        {
            # Parse::RecDescent lets you return a single scalar, which we use as
            # an anonymous hash reference
            sub_property            => $item[1][0],
            property_identifier     => $item[2][0],
            street_name             => $item[3],
            street_type             => '',
            suburb                  => $item[4],
            subcountry              => $item[5],
            post_code               => $item[6][0],
            country                 => $item[7][0],
            non_matching            => $item[8][0],
            type                    => 'suburban'
        }
    }
    |

    sub_property(?) property_identifier(?) street street_type suburb subcountry post_code(?) country(?) non_matching(?)
    {
        $return =
        {
            sub_property            => $item[1][0],
            property_identifier     => $item[2][0],
            street_name             => $item[3],
            street_type             => $item[4],
            suburb                  => $item[5],
            subcountry              => $item[6],
            post_code               => $item[7][0],
            country                 => $item[8][0],
            non_matching            => $item[9][0],
            type                    => 'suburban'
        }
    }
    |


};
#-------------------------------------------------------------------------------

my $usa_suburban_address_rules =
q{
    full_address :


    property_identifier(?) street_untyped sub_property(?) suburb subcountry post_code(?) country(?) non_matching(?)
    # (needs higher precedence than streets with types)

    {
        $return =
        {
            property_identifier     => $item[1][0],
            street_name             => $item[2],
            street_type             => '',
            sub_property            =>  $item[3][0],
            suburb                  => $item[4],
            subcountry              => $item[5],
            post_code               => $item[6][0],
            country                 => $item[7][0],
            non_matching            => $item[8][0],
            type                    => 'suburban'
        }
    }
    |

    property_identifier(?) street street_type abbrev_direction(?) sub_property(?) suburb subcountry post_code(?) country(?) non_matching(?)
    {
        $return =
        {
            property_identifier     => $item[1][0],
            street_name             => $item[2],
            street_type             => $item[3],
            street_direction_suffix => $item[4][0],
            sub_property            => $item[5][0],
            suburb                  => $item[6],
            subcountry              => $item[7],
            post_code               => $item[8][0],
            country                 => $item[9][0],
            non_matching            => $item[10][0],
            type                    => 'suburban'
        }
    }
    |

};

#-------------------------------------------------------------------------------
my $rural_address_rule =
q{
    property_name property_identifier street street_type suburb subcountry post_code(?) country(?) non_matching(?)
    {
        $return =
        {
           property_name       => $item[1],
           property_identifier => $item[2],
           street_name         => $item[3],
           street_type         => $item[4],
           suburb              => $item[5],
           subcountry          => $item[6],
           post_code           => $item[7][0],
           country             => $item[8][0],
           non_matching        => $item[9][0],
           type                => 'rural'
        }
    }
    |
    property_name street street_type suburb subcountry post_code(?) country(?) non_matching(?)
    {
        $return =
        {
           property_name       => $item[1],
           street_name         => $item[2],
           street_type         => $item[3],
           suburb              => $item[4],
           subcountry          => $item[5],
           post_code           => $item[6][0],
           country             => $item[7][0],
           non_matching        => $item[8][0],
           type                => 'rural'
        }
    }
    |
    property_name suburb subcountry post_code(?) country(?) non_matching(?)
    {
        $return =
        {
           property_name       => $item[1],
           suburb              => $item[2],
           subcountry          => $item[3],
           post_code           => $item[4][0],
           country             => $item[5][0],
           non_matching        => $item[6][0],
           type                => 'rural'
        }
    }
    |
};
#-------------------------------------------------------------------------------

my $post_box_rule =
q{
    post_box suburb subcountry post_code(?) country(?) non_matching(?)
    {
        $return =
        {
           post_box      => $item[1],
           suburb        => $item[2],
           subcountry    => $item[3],
           post_code     => $item[4][0],
           country       => $item[5][0],
           non_matching  => $item[6][0],
           type          => 'post_box'
        }
    }
    |
};
#-------------------------------------------------------------------------------

my $road_box_rule =
q{
    road_box street street_type suburb subcountry post_code(?) country(?) non_matching(?)
    {
        $return =
        {
           road_box      => $item[1],
           street_name   => $item[2],
           street_type   => $item[3],
           suburb        => $item[4],
           subcountry    => $item[5],
           post_code     => $item[6][0],
           country       => $item[7][0],
           non_matching  => $item[8][0],
           type          => 'road_box'
        }
    }
    |
    road_box suburb subcountry post_code(?) country(?) non_matching(?)
    {
        $return =
        {
           road_box      => $item[1],
           suburb        => $item[2],
           subcountry    => $item[3],
           post_code     => $item[4][0],
           country       => $item[5][0],
           non_matching  => $item[6][0],
           type          => 'road_box'
        }
    }
    |
};

#-------------------------------------------------------------------------------

my $non_matching_rule =
q{
    non_matching(?)
    {
       $return =
       {
          non_matching  => $item[1][0],
          type          => 'unknown'
       }
    }
};
#------------------------------------------------------------------------------
# Individual components that an address can be composed from. Components are
# expressed as literals or Perl regular expressions.
#------------------------------------------------------------------------------

my $sub_property =
q{

    sub_property:

        /SUITE \w+ /      
        |
        sub_property_type unit_number
        {
           $return = "$item[1]$item[2]"
        } 

    # Unit 34, Shop 12C

    sub_property_type:
        /(
        APARTMENT   | APT   |
        BAY         |
        DEPARTMENT  |
        FACTORY     |
        FLAT        |
        FRONT       |
        FRNT        |
        GATE        |
        KEY         |
        HANGAR      | HNGR  |
        KEY         |
        LOBBY       |
        LBBY        |
        LOT         |
        OFFICE      |
        OFC         |
        LOT         |
        NO          |
        PENTHOUSE   |
        PH          |
        PIER        |
        REAR (OF )? |
        ROOM        |
        RM          |
        SHOP        |
        SHED        |
        SUITE       | STE |
        TRAILER     |
        TRLR        |
        UNIT        |
        VILLA       |
        \#                # Note '#' is a common abbreviation for number in USA
        )\ /x

    unit_number:
        /(
        \d{1,6}           |
        \d{1,4}[A-Z]{0,2} | # such as 23B, 6AW
        \d{1,2}[A-Z]\d    | # such as 4A5
        [A-Z]\d[A-Z]      | # such as A5J
        [A-Z]{1,2}\d{0,4} | # such as # D512
        \d{1,3}-\d{1,3}     # such as # 200-204
        )\ /x    
};

#------------------------------------------------------------------------------

my $property_identifier =
q{
    property_identifier :

        /\d{1,4} 1\/2 /    |  # fractional number such as 22 1/2 (half numbers are valid in US)
        /\d{1,5}-\d{1,5} / |  # 1002-1006
        /\d{1,5}[A-Z]? /      # 10025A
};
#------------------------------------------------------------------------------

my $property_name =
q{
    # Property or station names like "Old Regret" or 'Never Fail'
    property_name : /\"[A-Z'-]{2,}( [A-Z'-]{2,})?\" / |
                    /\'[A-Z-]{2,}( [A-Z-]{2,})?\' /
};
#------------------------------------------------------------------------------

my $post_box =
q{

    post_box : post_box_type post_box_number
    {
        $return = "$item[1]$item[2]"
    }

    # NOTE: extended regexps not useful here, too many spaces to delimit
    post_box_type :
        /(
        GPO\ BOX  |
        LPO\ BOX  |
        P\ ?O\ BOX |
        PO\ BOX   |
        LOCKED\ BAG |
        PRIVATE\ BAG
        )\ /x  

    post_box_number : /[A-Z]?\d{1,6}[A-Z]? /
};
#------------------------------------------------------------------------------

my $road_box =
q{

    road_box : road_box_type road_box_number
    {
        $return = "$item[1]$item[2]"
    }

    road_box_type :
        /(
        CMB | # Community Mail Bag
        CMA | # Community Mail Agent
        CPA | # Community Postal Agent
        RMS | # Roadside Mail Service
        RMB | # Roadside Mail Box
        RSD   # Roadside Side Delivery
        )\ /x  # note space separator needed at end of token

    road_box_number : /[A-Z]?\d{1,5}[A-Z]? /

};
#------------------------------------------------------------------------------

my $street =
q{

    # Streets with no street type such as Road, Lane etc.  
    street_untyped :

        major_road |
        avenue_ordinal |
        street_name_single_word |
        street_noun |
        french_style |
        /AVENUE OF \w+ \w+ /   # The Americas, Two Rivers etc
        
    major_road :
        /([N|E|S|W] )?(COUNTY |STATE |US |FIRE )?(ALT|HIGHWAY|LANE|HWY|ROAD|RD|RTE|ROUTE) \d{1,3}\w? ([N|E|S|W|NORTH|EAST|SOUTH|WEST] )?/

    # Avenue C, 12 1/2 etc
    avenue_ordinal :
        /([N|E|S|W] )?AVENUE ([A-Z]|\d{1,2}( 1\/2)?) /
        
    # TO DO: N,E,S,W END suburb. End is valid street type but always with direction

    street_name_single_word:
        /([N|E|S|W] )?(ALDERSGATE|BROADWAY|BOARDWALK|BOULEVARD|BOWERY|ESPLANADE|KINGSWAY|QUEENSWAY|GREENWAY|PARKWAY|PONDWAY|RIVERBANK) /
        ...!street_type
        {
            $return = $item[1]
        }
        
    street_noun:
        /(THE|VIA) / any_word
        {
            $return = "$item[1]$item[2]"
        }
        
    french_style:    
        /RUE (DE |DES )?/ any_word
        {
            $return = "$item[1]$item[2]"
        }
             

    #---------------------------------------------------------------------------- 

    street:
                         
        street_prefix(?) street_name
        {
            if ( $item[1][0] )
            {
                $return = "$item[1][0]$item[2]"
            }            
            else
            {
                $return = $item[2];
            }
        }
        |
        # Like South Parade, West Street, Lower Rd.
        # Note: we don't included abbreviated direction here
        # Note: precedence is important here, this form is less common than above
        
        full_direction | general_prefix ...street_type
        {
            $return = $item[1];
        }        
           

    street_prefix : direction | general_prefix
    
    general_prefix:
        /(
        NEW|
        OLD|
        MT|MOUNT|
        DAME|
        SIR|
        UPPER|
        LOWER|
        LA|
        ST
        )\ /x 

    street_name :

        /(N |E |S |W |DR )?(MARTIN LUTHER|MARTIN L|ML) KING ([JS]R )?/ |
        /MALCOLM X /
        |
        street_name_ordinal
        |

        # WORD STREET_TYPE STREET_TYPE
        # Queen's Park Road, Grand Ridge Rd, Terrace Park Drive, Lane Cove Road etc
        any_word
        /(
        BEND|
        BRAE|
        BURN|
        CAY|
        CHASE|
        CIRCLE|
        CENTRAL|
        CLUB|
        COURT|
        CREST|
        CRESCENT|
        CROSS|
        CROSSING|
        COVE|
        EDGE|
        GARDEN|
        GATE|
        GREEN|
        GLEN|
        GROVE|
        HAVEN|
        HEATH|
        HILL|        
        HOLLOW|
        ISLAND|
        ISLE|
        KEY|
        KNOLL|
        LANDING|
        LANE|
        LOOP|
        PASS|
        PARK|
        PATH|
        PARKWAY|
        PLACE|
        PLAZA|
        PLEASANT|
        POINT|
        POINTE|
        RUN|
        RIDGE|
        SQUARE|
        TRAIL|
        VIEW|
        VILLAGE|
        VISTA
        )\ /x
        ...street_type
        {
            $return = "$item[1]$item[2]"
        }
        |

        # STREET_TYPE WORD STREET_TYPE
        # Glen Alpine Way, La Boheme Ave,  Grove Valley Ave, Green Bay Road
        /(
        CIRCLE|
        CLUB|
        COURT|
        CRESCENT|
        CROSS|
        GATE|
        GLADE|
        GLEN|
        GREENS?|
        GROVE|
        FAIRWAY|
        HOLLOW|
        HILL|
        ISLAND|
        KEY|
        KNOLL|
        LA|
        LANDING|
        LANE|
        LT|
        PARK|
        PLAZA|
        POINT|
        RIDGE|
        ST|
        TRAIL|
        VILLAGE
        )\ /x
        street_name_word ...street_type
        {
            $return = "$item[1]$item[2]"
        }
        |
        # TO DO: New York State has streets such as 'Dutch Street Road'
        #any_word /STREET / .../ROAD|RD /
        #{
        #    $return = "$item[1]$item[2]"
        #}
        #|        

        # Allow for street_type that can also occur as a street name, eg Park Lane, Green Street
        any_word ...street_type
        {
            $return = $item[1]
        }
        |
        # Persons name, such as John F Kennedy Boulevard
        title(?) any_word street_name_letter street_name_word
        {
            $return = "$item[1][0]$item[2]$item[3]$item[4]"
        }
        |
        street_name_words
        |
        street_name_letter


    # Tin Can Bay (Road), South Head (Road) etc
    street_name_words : street_name_word(1..3)
    {
        if ( $item[1][0] and $item[1][1] and $item[1][2] )
        {
           $return = "$item[1][0]$item[1][1]$item[1][2]"
        }
        elsif ( $item[1][0] and $item[1][1] )
        {
           $return = "$item[1][0]$item[1][1]"
        }
        else
        {
           $return = $item[1][0]
        }
    }

    # A  valid word that forms part of a street name. Use look ahead to prevent the
    # second name of a two word street_type being consumed too early. For example,
    # Street in Green Street
    # Even two letter streets such as 'By Street' are valid

    street_name_word: ...!street_type /[A-Z'-]{2,}\s+/
    {
        $return = $item[2]
    }


    # eg Bay 12th Ave, 42nd Street
    street_name_ordinal :
        any_word(?)
        /(
        \d{0,2}1ST    |
        \d{0,2}2ND    |
        \d{0,2}3RD    |
        \d{0,2}[4-9]TH |
        \d{0,2}0TH    |
        \d{0,1}11TH   |
        \d{0,1}12TH   |
        \d{0,1}13TH
        )\ /x
    {

        if ( $item[1][0] and $item[2] )
        {
           $return = "$item[1][0]$item[2]"
        }
        elsif ($item[2] )
        {
           $return = "$item[2]"
        }
    }

    street_name_letter:  /[A-Z]\s+/  # eg B (Street)

    street_type:

        /(
        # Place most frequent types first to speed up matching
        ST|STREET|
        RD|ROAD|
        LA|LN|LANE|
        AVE?|AVENUE|
        ALY?|ALLEY|
        ARC|ARCADE|
        BATTLEMENT|
        BROADWATER|
        BAYWAY|
        BVD|BLVD?|BOULEVARDE?|
        BND|BEND|
        BL|BOWL|
        BR|BRAE|
        BROW|
        CASCADES|
        CAY|
        CENTRE|
        CONCOURSE|
        CIR|CIRCLE|CRCLE|
        CCT|CRT|CIR|CIRCUIT|
        CHASE|
        CL|CLOSE|
        CROSS|CROSSOVER|CROSSING|
        CR?T|COURT|
        CV|COVE|
        CRES|CRS|CR|CRESCENT|
        CREST|
        CROFT|
        DELL|
        DEVIATION|
        DRIFTWAY|
        DR|DRV|DRIVE|
        ENCLOSURE|
        ENTRANCE|
        ESP|ESPLANADE|
        EXP|EXPW?Y|EXPRESSWAY|
        FAIRWAY|
        FW?Y|FREEWAY|
        GATE|
        GLADE|
        GRANGE|
        GLN|GLEN|
        GREENS?|GRN|
        GR|GROVE|
        HAVEN|
        HEATH|
        HL|HILL|
        HWA?Y|HIGHWAY|
        HOLE|
        HOLLOW|
        ISLE?|IS|  # Note that Island is a valid street type, but can get confused with suburb name, such as: Main St Clare Island. So don't include it
        KEY|
        KNOLL|
        LANTERNS|
        LANDING|
        LOOP|
        MEWS|
        MINNOW|
        OVERFLOW|
        OVERLOOK|
        OVAL|
        PASS|
        PASSAGE|PSGE|PSG|
        PATH|
        PDE|PARADE|
        PK|PARK|
        PARKWAY|PKWY|
        PENINSULA|
        PIERS|
        PIKE|
        PL|PLACE|
        PLZ|PLAZA|
        PORTICO|
        PROMENADE|
        PT|POINTE?|
        RAMBLE|
        RDG|RIDGE|
        RETREAT|
        RIDE|RDE|
        RISE|RSE|
        RUN|
        RDY|ROADWAY|
        ROW|
        SLIP|
        SQ|SQUARE|
        TCE|TRCE|TER|TERRACE|
        TRL|TRAIL|
        TPKE|TURNPIKE|
        TURN|
        THROUGHWAY|       
        WL?K|WALK|
        WY|WAY|WYNDE|
        WAYS  # such as in 'The Five Ways'
        )\ /x  # note space separator needed at end of token
};

#------------------------------------------------------------------------------
# Suburbs can be up to three words
# Examples:  Dee Why or St. Johns Park, French's Forest

my $suburb =
q
{
    suburb_prefix :

        street_prefix  |
        /CAPE / |
        /FORT|FT /   
        /LAKE / 

    suburb: 
        any_word /BY THE SEA /
        {
               $return = "$item[1]$item[2]"
        }
        |
        /LAND O LAKES /                
        |
        # such as  Washington Valley, Lane Cove West, Little Egg Harbour Township
        suburb_prefix(?) any_word suburb_word(0..2)
        {
            if ( $item[1][0] )
            {
                if ($item[3][0] and $item[3][1])
                {
                    $return = "$item[1][0]$item[2]$item[3][0]$item[3][1]"
                }
                elsif ( $item[3][0] )
                {
                   $return = "$item[1][0]$item[2]$item[3][0]"
                }
                else
                {
                   $return = "$item[1][0]$item[2]"
                }
            }
            else
            {
               if ($item[3][0] and $item[3][1])
                {
                    $return = "$item[2]$item[3][0]$item[3][1]"
                }
                elsif ( $item[3][0] )
                {
                   $return = "$item[2]$item[3][0]"
                }
                else
                {
                   $return = "$item[2]"
                }
            }
        }
        |
        # such as Kippa-ring or Brighton-Le-Sands
        /[A-Z]{2,}-[A-Z]{2,}(-[A-Z]{2,})? /

    suburb_word: ...!subcountry any_word
};
#------------------------------------------------------------------------------
my $common_terms =
q
{
    # For use in first or second word of double or triple word street names or suburbs
    # such as  Moore Park West
    any_word: /[A-Z'-]{2,}\s+/
    {
        $return = $item[1]
    }

    direction: full_direction | abbrev_direction

    full_direction:
        /(
        NORTH |
        NTH|
        EAST  |
        SOUTH |
        STH|
        WEST
        )\ /x

   abbrev_direction:
        /(
        N  |
        NE |
        NW |
        E  |
        S  |
        SE |
        SW |
        W
        )\ /x
        
 title:
        /(
        REV |
        DR 
        )\ /x        
};

#------------------------------------------------------------------------------

# note that Northern territory codes can be abbreviated to 3 digits
# Example 0800, 800, 2099
my $australian_post_code = q{ post_code: /\d{4} ?/  | /8\d{2} ?/ };

my $new_zealand_post_code = q{ post_code: /\d{4} ?/ };

# Thanks to Steve Taylor for supplying format of Canadian post codes
# Example is K1B 4L7
my $canadian_post_code = q{ post_code: /[A-Z]\d[A-Z] \d[A-Z]\d ?/ };

# Thanks to Mike Edwards for supplying US zip code formats
my $US_post_code =       q{ post_code: /\d{5}(-?\d{4})? ?/};

# Thanks to Mark Summerfield for supplying UK post code formats
# Example is SW1A 9ET

my $UK_post_code =
q{
    post_code: outward_code inward_code
    {
        $return = "$item[1]$item[2]"
    }

   outward_code :
     /(EC[1-4]|WC[12]|S?W1)[A-Z] / | # London specials
     /[BGLMS]\d\d? / |               # Single letter
     /[A-Z]{2}\d\d? /                # Double letter

   inward_code : /\d[ABD-HJLNP-UW-Z]{2} ?/
};


my $Australia =
q{
    country:
        /(AUSTRALIA|AUST|AU) ?/
};

my $Canada =
q{
    country:
        /CANADA ?/
};

my $New_Zealand =
q{
    country:
        /(NEW ZEALAND|NZ) ?/
};

my $US =
q{
    country:
        /(UNITED STATES OF AMERICA|UNITED STATES|USA?) ?/
};

my $UK =
q{
    country:
        /(GREAT BRITAIN|UNITED KINGDOM|UK|GB) ?/
};

my $non_matching =  q{ non_matching: /.*/ };

#-------------------------------------------------------------------------------
sub _create
{
    my $address = shift;

    # User can specify country either as full name or 2 letter
    # abbreviation, such as Australia or AU
    my $country = Locale::SubCountry->new($address->{country});

    $address->{country_code} = $country->country_code;

    my $grammar = '';
    if ( $address->{country_code} eq 'US' )
    {
        $grammar .= $usa_suburban_address_rules;
    }
    else
    {
        $grammar .= $non_usa_suburban_address_rules;
    }

    $grammar .= $rural_address_rule;
    $grammar .= $post_box_rule;
    $grammar .= $road_box_rule;
    $grammar .= $non_matching_rule;
    $grammar .= $sub_property;
    $grammar .= $property_identifier;
    $grammar .= $property_name;
    $grammar .= $post_box;
    $grammar .= $road_box;
    $grammar .= $street;
    $grammar .= $suburb;
    $grammar .= $common_terms;

    my $subcountry_grammar = "    subcountry :\n";

    # Loop over all sub countries to create a grammar for all subcountry
    # combinations for this country. The grammar for Australia will look like
    #
    # subcountry :  /NSW / |
    #               /QLD / |
    #               /NEW SOUTH WALES /
    #               /QUEENSLAND / |

    my @all_codes = $country->all_codes;
    my $last_code = pop(@all_codes);

    foreach my $code (@all_codes)
    {
        $subcountry_grammar .= "\t/$code / | \n";
    }
    # No alternation character needed for last code
    $subcountry_grammar .= "\t/$last_code /\n";

    if ( not $address->{abbreviated_subcountry_only} )
    {
        $subcountry_grammar .= "| \n";

        my @all_full_names = $country->all_full_names;
        my $last_full_name = pop(@all_full_names);


        foreach my $full_name (@all_full_names)
        {
            $full_name = uc(_clean_sub_country_name($full_name));
            $subcountry_grammar .= "\t/$full_name / |\n";
        }

        $last_full_name = _clean_sub_country_name($last_full_name);
        $subcountry_grammar .= "\t/$last_full_name /\n";
    }

    $grammar .= $subcountry_grammar;

    if ( $address->{country_code} eq 'AU' )
    {
       $grammar .= $australian_post_code;
       $grammar .= $Australia;

    }
    elsif ( $address->{country_code} eq 'CA' )
    {
       $grammar .= $canadian_post_code;
       $grammar .= $Canada;
    }

    elsif ( $address->{country_code} eq 'GB' )
    {
       $grammar .= $UK_post_code;
       $grammar .= $UK;
    }
    elsif ( $address->{country_code} eq 'NZ' )
    {
       $grammar .= $new_zealand_post_code;
       $grammar .= $New_Zealand;
    }
    elsif ( $address->{country_code} eq 'US' )
    {
       $grammar .= $US_post_code;
       $grammar .= $US;
    }
    else
    {
        die "Invalid country code or name: $address->{country}";
    }

    $grammar .= $non_matching;

    return($grammar);
}
#-------------------------------------------------------------------------------
# Some sub countries contain descriptive text, such as
# "Swansea [Abertawe GB-ATA]" in UK, Wales , which should be removed

sub _clean_sub_country_name
{
    my ($sub_country_name) = @_;

    my $cleaned_sub_country_name;
    if ( $sub_country_name =~ /\[/ )
    {
        # detect any portion in square brackets
        $sub_country_name =~ /^(\w.*) \[.*\]$/;
        $cleaned_sub_country_name = $1;
    }
    else
    {
        $cleaned_sub_country_name = $sub_country_name;
    }
    return($cleaned_sub_country_name)
}
#-------------------------------------------------------------------------------
1;
