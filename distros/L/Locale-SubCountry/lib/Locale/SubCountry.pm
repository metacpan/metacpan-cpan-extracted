=head1 NAME

Locale::SubCountry - Convert state, province, county etc. names to/from ISO 3166-2 codes, get all states in a country

=head1 SYNOPSIS

    use Locale::SubCountry;
    
    my $fr = Locale::SubCountry->new('France');
    if ( not $fr )
    {
        die "Invalid country or code: France\n";
    }
    else
    {
        print($fr->country,"\n");        # France
        print($fr->country_code,"\n");   # FR
        print($fr->country_number,"\n"); # 250

        if (  $fr->has_sub_countries )
        {
            print($fr->code('Hautes-Alpes '),"\n");       # 05
            print($fr->full_name('03'),"\n");             # Allier
            my $upper_case = 1;
            print($fr->full_name('02',$upper_case),"\n"); # AINSE
            print($fr->level('02'),"\n");                 # Metropolitan department
            print($fr->level('A'),"\n");                  # Metropolitan region
            print($fr->level('BL'),"\n");                 # Overseas territorial collectivity
            print($fr->levels,"\n");                      # Metropolitan region => 22, Metropolitan department => 96 ...
 
            my @fr_names  = $fr->all_full_names;    # Ain, Ainse, Allier...
            my @fr_codes   = $fr->all_codes;        # 01, 02, 03 ...
            my %fr_names_keyed_by_code  = $fr->code_full_name_hash;  # 01 => Ain...
            my %fr_codes_keyed_by_name  = $fr->full_name_code_hash;  # Ain => 01 ...

            foreach my $code ( sort keys %fr_names_keyed_by_code )
            {
               printf("%-3s : %s\n",$code,$fr_names_keyed_by_code{$code});            
            }
        }
    }

    # Methods for fetching all country codes and names in the world

    my $world = Locale::SubCountry::World->new();
    my @all_countries     = $world->all_full_names;
    my @all_country_codes = $world->all_codes;

    my %all_countries_keyed_by_name = $world->full_name_code_hash;
    my %all_country_keyed_by_code   = $world->code_full_name_hash;


=head1 DESCRIPTION

This module allows you to convert the full name for a country's administrative
region to the code commonly used for postal addressing. The reverse look up
can also be done.

Lists of sub country codes are useful for web applications that require a valid
state, county etc to be entered as part of a users location.

Sub countries are termed as states in the US and Australia, provinces
in Canada and counties in the UK and Ireland. Other terms include region,
department, city and territory. Countries such as France have several
levels of sub countries, such as Metropolitan department, Metropolitan region etc.

Names and ISO 3166-2 codes for all sub countries in a country can be
returned as either a hash or an array.

Names and ISO 3166-1 codes for all countries in the world can be
returned as either a hash or an array. This in turn can be used to
fetch every sub country from every country (see examples/demo.pl).

Sub country codes are defined in "ISO 3166-2,
Codes for the representation of names of countries and their subdivisions".


=head1 METHODS

Note that the following methods duplicate some of the functionality of the
Locale::Country module (part of the Locale::Codes bundle). They are provided
here because you may need to first access the list of  countries and
ISO 3166-1 codes, before fetching their sub country data. If you only need
access to country data, then Locale::Country should be used.

Note also the following method names are also used for sub country objects.
(interface polymorphism for the technically minded). To avoid confusion, make
sure that your chosen method is acting on the correct type of object.

    all_codes
    all_full_names
    code_full_name_hash
    full_name_code_hash


=head2  Locale::SubCountry::World->new()

The C<new> method creates an instance of a world country object. This must be
called before any of the following methods are invoked. The method takes no
arguments.


=head2 full_name_code_hash (for world objects)

Given a world object, returns a hash of full name/code pairs for every country,
keyed by country name.

=head2 code_full_name_hash  for world objects)

Given a world object, returns a hash of full name/code pairs for every country,
keyed by country code.


=head2 all_full_names (for world objects)

Given a world object, returns an array of all country full names,
sorted alphabetically.

=head2 all_codes (for world objects)

Given a world object, returns an array of all country ISO 3166-1 codes,
sorted alphabetically.


=head2 Locale::SubCountry->new()

The C<new> method creates an instance of a sub country object. This must be
called before any of the following methods are invoked. The method takes a
single argument, the name of the country that contains the sub country
that you want to work with. It may be specified either by the ISO 3166-1
alpha-2  code or the full name. For example:

    AF - Afghanistan
    AL - Albania
    DZ - Algeria
    AO - Angola
    AR - Argentina
    AM - Armenia
    AU - Australia
    AT - Austria


If the code is specified, such as 'AU'  the format may be in capitals or lower case
If the full name is specified, such as 'Australia', the format must be in title case
If a country name or code is specified that the module doesn't recognised, it will issue a warning.

=head2 country

Returns the current country name of a sub country object. The format is in title case,
such as 'United Kingdom'

=head2 country_code

Given a sub country object, returns the alpha-2 ISO 3166-1 code of the country,
such as 'GB'


=head2 code

Given a sub country object, the C<code> method takes the full name of a sub
country and returns the sub country's alpha-2 ISO 3166-2 code. The full name can appear
in mixed case. All white space and non alphabetic characters are ignored, except
the single space used to separate sub country names such as "New South Wales".
The code is returned as a capitalised string, or "unknown" if no match is found.

=head2 full_name

Given a sub country object, the C<full_name> method takes the alpha-2 ISO 3166-2 code
of a sub country and returns the sub country's full name. The code can appear
in mixed case. All white space and non alphabetic characters are ignored. The
full name is returned as a title cased string, such as "South Australia".

If an optional argument is supplied and set to a true value, the full name is
returned as an upper cased string.

=head2 level

Given a sub country object, the C<level> method takes the alpha-2 ISO 3166-2 code
of a sub country and returns the sub country's level . Examples are city,
province,state and district, and usually relates to the a regions size.
The level is returned as a  string, or "unknown" if no match is found.


=head2 has_sub_countries

Given a sub country object, the C<has_sub_countries> method returns 1 if the
current country has sub countries, or 0 if it does not. Some small countries
such as New Caledonia" do not have sub countries.


=head2 full_name_code_hash  (for sub country objects)

Given a sub country object, returns a hash of all full name/code pairs,
keyed by sub country name. If the country has no sub countries, returns undef.

=head2 code_full_name_hash  (for sub country objects)

Given a sub country object, returns a hash of all code/full name pairs,
keyed by sub country code. If the country has no sub countries, returns undef.


=head2 all_full_names  (for sub country objects)

Given a sub country object, returns an array of all sub country full names,
sorted alphabetically. If the country has no sub countries, returns undef.

=head2 all_codes  (for sub country objects)

Given a sub country object, returns an array of all sub country alpha-2 ISO 3166-2 codes.
If the country has no sub countries, returns undef.


=head1 SEE ALSO

All codes have been downloaded from the latest version of the Alioth project
L<https://pkg-isocodes.alioth.debian.org/>


L<Locale::Country>,L<Lingua::EN::AddressParse>,
L<Geo::StreetAddress::US>,L<Geo::PostalAddress>,L<Geo::IP>
L<WWW::Scraper::Wikipedia::ISO3166> for obtaining ISO 3166-2 data

ISO 3166-1 Codes for the representation of names of countries and their
subdivisions - Part 1: Country codes

ISO 3166-2 Codes for the representation of names of countries and their
subdivisions - Part 2: Country subdivision code


L<http://www.statoids.com/statoids.html> is a good source for sub country codes plus
other statistical data.


=head1 LIMITATIONS

The ISO 3166-2 standard romanizes the names of provinces and regions in non-latin
script areas, such as Russia and South Korea. One Romanisation is given for each
province name. For Russia, the BGN (1947) Romanization is used.

Several sub country names have more than one code, and may not return
the correct code for that sub country. These entries are usually duplicated
because the name represents two different types of sub country, such as a
province and a geographical unit. Examples are:

    AZERBAIJAN : Lankaran; LA (the Municipality), LAN (the Rayon) [see note]
    AZERBAIJAN : Saki; SA,SAK [see note]
    AZERBAIJAN : Susa; SS,SUS
    AZERBAIJAN : Yevlax; YE,YEV
    LAOS       : Vientiane VI the Vientiane, VT the Prefecture
    MOZAMBIQUE : Maputo; MPM (City),L (Province)

Note: these names are spelt with  diacrtic characters (such as two dots above
some of the 'a' characters). This causes utf8 errors on some versions
of Perl, so they are omitted here. See the Locale::SubCountry::Codes module
for correct spelling


=head1 AUTHOR

Locale::SubCountry was written by Kim Ryan <kimryan at cpan dot org>.

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2018 by Kim Ryan.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 CREDITS

Ron Savage for many corrections to the data


Terrence Brannon produced Locale::US, which was the starting point for
this module.



=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Kim Ryan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#-------------------------------------------------------------------------------

package Locale::SubCountry::World;
use strict;
use warnings;
use locale;
use Exporter;
use JSON;
use Locale::SubCountry::Codes;

#-------------------------------------------------------------------------------


our $VERSION = '2.04';

# Define all the methods for the 'world' class here. Note that because the
# name space inherits from the Locale::SubCountry name space, the
# package wide variables $SubCountry::country and $Locale::SubCountry::subcountry are
# accessible.


#-------------------------------------------------------------------------------
# Create new instance of a SubCountry::World object

sub new
{
    my $class = shift;

    my $world = {};
    bless($world,$class);
    return($world);
}

#-------------------------------------------------------------------------------
# Returns a hash of code/name pairs for all countries, keyed by  country code.

sub code_full_name_hash
{
    my $world = shift;
    return(  %{ $Locale::SubCountry::country{_code_keyed} } );
}
#-------------------------------------------------------------------------------
# Returns a hash of name/code pairs for all countries, keyed by country name.

sub full_name_code_hash
{
    my $world = shift;
    return( %{ $Locale::SubCountry::country{_full_name_keyed} } );
}
#-------------------------------------------------------------------------------
# Returns sorted array of all country full names

sub all_full_names
{
    my $world = shift;
    return ( sort keys %{ $Locale::SubCountry::country{_full_name_keyed} });
}
#-------------------------------------------------------------------------------
# Returns sorted array of all two letter country codes

sub all_codes
{
    my $world = shift;
    return ( sort keys %{ $Locale::SubCountry::country{_code_keyed} });
}

#-------------------------------------------------------------------------------

package Locale::SubCountry;
our $VERSION = '2.04';

#-------------------------------------------------------------------------------
# Initialization code which will be run first to create global data structure.
# Read in the list of abbreviations and full names defined in the
# Locale::SubCountry::Codes package

{

    unless ( $Locale::SubCountry::Codes::JSON )
    {
      die "Could not locate Locale::SubCountry::Codes::JSON variable";
    }

    # Get all the data from the Locale::SubCountry::Codes package and place into a structure

    # Note: will fail on badly formed JSON data
    my $json_text = $Locale::SubCountry::Codes::JSON;
    my $json = JSON->new->allow_nonref;
    
    my $all_codes_ref = $json->decode($json_text);
    
        
    foreach my $country_ref ( @{ $all_codes_ref->{'3166-1'} })
    {             
        # Create doubly indexed hash, keyed by country code and full name.
        # The user can supply either form to create a new sub_country
        # object, and the objects properties will hold both the countries
        # name and it's code.

        $Locale::SubCountry::country{_code_keyed}{$country_ref->{alpha_2}} = $country_ref->{name};
        $Locale::SubCountry::country{_full_name_keyed}{$country_ref->{name}} = $country_ref->{alpha_2};
        
        # Get numeric code for country, such as Australia = '036'
        $Locale::SubCountry::country{$country_ref->{name}}{_numeric }= $country_ref->{numeric};
    }

     
    foreach my $sub_country_ref ( @{ $all_codes_ref->{'3166-2'} })
    {    
        my ($country_code,$sub_country_code) = split(/\-/,$sub_country_ref->{code});
        my $sub_country_name =  $sub_country_ref->{name};
         
        $Locale::SubCountry::subcountry{$country_code}{_code_keyed}{$sub_country_code} = $sub_country_name;
        $Locale::SubCountry::subcountry{$country_code}{_full_name_keyed}{$sub_country_name} = $sub_country_code;        
        $Locale::SubCountry::subcountry{$country_code}{$sub_country_code}{_level} = $sub_country_ref->{type};
        
        # Record  level occurence in a country
        $Locale::SubCountry::subcountry{$country_code}{_levels}{$sub_country_ref->{type}}++; 
       
    }
}

#-------------------------------------------------------------------------------
# Create new instance of a sub country object

sub new
{
    my $class = shift;
    my ($country_or_code) = @_;

    my ($country,$country_code);

    # Country may be supplied either as a two letter code, or the full name
    if ( length($country_or_code) == 2 )
    {
        $country_or_code = uc($country_or_code); # lower case codes may be used, so fold to upper case
        if ( $Locale::SubCountry::country{_code_keyed}{$country_or_code} )
        {
            $country_code = $country_or_code;
            # set country to it's full name
            $country = $Locale::SubCountry::country{_code_keyed}{$country_code};
         }
        else
        {
          warn "Invalid country code: $country_or_code chosen";
          return(undef);
        }
    }
    else
    {
        if ( $Locale::SubCountry::country{_full_name_keyed}{$country_or_code} )
        {
            $country = $country_or_code;
            $country_code = $Locale::SubCountry::country{_full_name_keyed}{$country};
        }
        else
        {
            warn "Invalid country name: $country_or_code chosen, names must be in title case";
            return(undef);

        }
    }

    my $sub_country = {};
    bless($sub_country,$class);
    $sub_country->{_country} = $country;
    $sub_country->{_country_code} = $country_code;
    $sub_country->{_numeric} = $Locale::SubCountry::country{$country}{_numeric};


    return($sub_country);
}

#-------------------------------------------------------------------------------
# Returns the current country's name of the sub country object

sub country
{
    my $sub_country = shift;
    return( $sub_country->{_country} );
}
#-------------------------------------------------------------------------------
# Returns the current country's alpha2 code of the sub country object

sub country_code
{
    my $sub_country = shift;
    return( $sub_country->{_country_code} );
}

#-------------------------------------------------------------------------------
# Returns the current country's numeric code of the sub country object

sub country_number
{
    my $sub_country = shift;
    return( $sub_country->{_numeric} );
}

#-------------------------------------------------------------------------------
# Given the full name for a sub country, return the ISO 3166-2 code

sub code
{
    my $sub_country = shift;
    my ($full_name) = @_;

    unless ( $sub_country->has_sub_countries )
    {
        # this country has no sub countries
        return;
    }

    my $orig = $full_name;

    $full_name = _clean($full_name);

    my $code = $Locale::SubCountry::subcountry{$sub_country->{_country_code}}{_full_name_keyed}{$full_name};

    # If a code wasn't found, it could be because the user's capitalization
    # does not match the one in the look up data of this module. For example,
    # the user may have supplied the sub country "Ag R" (in Turkey) but the
    # ISO standard defines the spelling as "Ag r".

    unless ( defined $code )
    {
        # For every sub country, compare upper cased full name supplied by user
        # to upper cased full name from lookup hash. If they match, return the
        # correctly cased full name from the lookup hash.

        my @all_names = $sub_country->all_full_names;
        my $current_name;
        foreach $current_name ( @all_names )
        {
            if ( uc($full_name) eq uc($current_name) )
            {
                $code = $Locale::SubCountry::subcountry{$sub_country->{_country_code}}{_full_name_keyed}{$current_name};
            }
        }
    }

    if ( defined $code )
    {
        return($code);
    }
    else
    {
        return('unknown');
    }
}

#-------------------------------------------------------------------------------
# Given the alpha-2 ISO 3166-2 code for a sub country, return the full name.
# Parameters are the code and a flag, which if set to true
# will cause the full name to be uppercased

sub full_name
{
    my $sub_country = shift;
    my ($code,$uc_name) = @_;

    unless ( $sub_country->has_sub_countries )
    {
        # this country has no sub countries
        # return;
    }

    $code = _clean($code);
    $code = uc($code);

    my $full_name =
        $Locale::SubCountry::subcountry{$sub_country->{_country_code}}{_code_keyed}{$code};
    if ( $uc_name )
    {
        $full_name = uc($full_name);
    }

    if ( $full_name )
    {
        return($full_name);
    }
    else
    {
        return('unknown');
    }
}

#-------------------------------------------------------------------------------
# Given the alpha-2 ISO 3166-2 code for a sub country, return the level,
# being one of state, province, overseas territory, city, council etc
sub level
{
    my $sub_country = shift;
    my ($code) = @_;

    $code = _clean($code);

    my $level = $Locale::SubCountry::subcountry{$sub_country->{_country_code}}{$code}{_level};

    if ( $level )
    {
        return($level);
    }
    else
    {
        return('unknown');
    }
}
#-------------------------------------------------------------------------------
# Given a sub country object, return a hash of all the levels and their totals 
# Such as Australia: State => 6, Territory => 2

sub levels
{
    my $sub_country = shift;  
 
    return( %{ $Locale::SubCountry::subcountry{$sub_country->{_country_code}}{_levels} });

}

#-------------------------------------------------------------------------------
# Returns 1 if the current country has sub countries. otherwise 0.

sub has_sub_countries
{
    my $sub_country = shift;
    if ( $Locale::SubCountry::subcountry{$sub_country->{_country_code}}{_code_keyed} )
    {
        return(1);
    }
    else
    {
        return(0);
    }
}
#-------------------------------------------------------------------------------
# Returns a hash of code/full name pairs, keyed by sub country code.

sub code_full_name_hash
{
    my $sub_country = shift;
    if ( $sub_country->has_sub_countries )
    {
        return( %{ $Locale::SubCountry::subcountry{$sub_country->{_country_code}}{_code_keyed} } );
    }
    else
    {
        return(undef);
    }
}
#-------------------------------------------------------------------------------
# Returns a hash of name/code pairs, keyed by sub country name.

sub full_name_code_hash
{
    my $sub_country = shift;
    if ( $sub_country->has_sub_countries )
    {
        return( %{ $Locale::SubCountry::subcountry{$sub_country->{_country_code}}{_full_name_keyed} } );
    }
    else
    {
        return(undef);
    }
}
#-------------------------------------------------------------------------------
# Returns sorted array of all sub country full names for the current country

sub all_full_names
{
    my $sub_country = shift;
    if ( $sub_country->full_name_code_hash )
    {
        my %all_full_names = $sub_country->full_name_code_hash;
        if ( %all_full_names )
        {
            return( sort keys %all_full_names );
        }
    }
    else
    {
        return(undef);
    }
}
#-------------------------------------------------------------------------------
# Returns array of all sub country alpha-2  ISO 3166-2 codes for the current country

sub all_codes
{
    my $sub_country = shift;

    if ( $sub_country->code_full_name_hash )
    {
        my %all_codes = $sub_country->code_full_name_hash;
        return( sort keys %all_codes );
    }
    else
    {
        return(undef);
    }
}

#-------------------------------------------------------------------------------
sub _clean
{
    my ($input_string) = @_;

    if ( $input_string =~ /[\. ]/ )
    {
        # remove dots
        $input_string =~ s/\.//go;

        # remove repeating spaces
        $input_string =~ s/  +/ /go;

        # remove any remaining leading or trailing space
        $input_string =~ s/^ //;
        $input_string =~ s/ $//;
    }

    return($input_string);
}

return(1);
