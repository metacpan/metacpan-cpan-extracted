package Geography::States;

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2015072102';

sub init_data;

my %states;

sub _c_length ($) {
    lc $_ [0] eq "australia" ? 3 : 2
}

sub _norm ($$) {
    my ($str, $country) = @_;
    if (_c_length ($country) >= length $str) {
        $str =  uc $str;
    }
    else {
        $str =  join " " => map {ucfirst lc} split /\s+/ => $str;
        $str =~ s/\bOf\b/of/         if $country eq lc 'USA';
        $str =~ s/\bD([eo])\b/d$1/   if $country eq lc 'Brazil';
    }

    $str;
}

{
    my $data = init_data;

    while (my ($country, $country_data) = each %$data) {
        while (my ($code, $state_data) = each %$country_data) {
            my ($strict, $name) = @$state_data;
            my $info     = [$code, $name, !$strict];
            my $_code    = _norm ($code, $country);
            my $_name    = _norm ($name, $country);
            my $_country = lc $country;
            $states {$_country} -> {$_code} = $info;
            $states {$_country} -> {$_name} = $info;
        }
    }
}


sub new {
    die "Not enough arguments for Geography::States -> new ()\n" unless @_ > 1;

    my $proto   =  shift;
    my $class   =  ref $proto || $proto;

    my $country =  lc shift;
       $country =~ s/\s+/ /g;

    die "No such country $country\n" unless $states {$country};

    my $strict  =  shift;

    my $self;
    my ($cs, $info);
    while (($cs, $info) = each %{$states {$country}}) {
        next unless $cs eq $info -> [0];
        next if $strict && $info -> [2];
        my $inf = [@$info [0, 1]];
        foreach my $i (0 .. 1) {
            #
            # Hardcoded exception.
            #
            next if $country  eq 'canada' &&
                    $$inf [0] eq 'PQ'     &&
                    $i == 1;
            $self -> {cs} -> {$info -> [$i]} = $inf unless
                       exists $self -> {cs} -> {$info -> [$i]};
        }
    }
    $self -> {country} = $country;

    bless $self => $class;
}


sub state {
    my $self = shift;
    unless (@_) {
        my %h;
        return grep {!$h {$_} ++} values %{$self -> {cs}};
    }
    my $query  =  _norm shift, $self -> {country};
    my $answer =  $self -> {cs} -> {$query} or return;
    return @$answer if wantarray;
    $answer -> [$answer -> [0] eq $query ? 1 : 0];
}


1;
    
=pod

=head1 NAME

Geography::States - Map states and provinces to their codes, and vica versa.

=head1 SYNOPSIS

 use Geography::States;

 my $obj = Geography::States -> new (COUNTRY [, STRICT]);


=head1 EXAMPLES

 my $canada = Geography::States -> new ('Canada');

 my  $name          =  $canada -> state ('NF');      # Newfoundland.
 my  $code          =  $canada -> state ('Ontario'); # ON.
 my ($code, $name)  =  $canada -> state ('BC');      # BC, British Columbia.
 my  @all_states    =  $canada -> state;             # List code/name pairs.


=head1 DESCRIPTION

This module lets you map states and provinces to their codes, and codes 
to names of provinces and states.

The C<< Geography::States -> new () >> call takes 1 or 2 arguments. The
first, required, argument is the country we are interested in. Current
supported countries are I<USA>, I<Brazil>, I<Canada>, I<The Netherlands>,
and I<Australia>. If a second non-false argument is given, we use I<strict
mode>. In non-strict mode, we will map territories and alternative codes
as well, while we do not do that in strict mode. For example, if the
country is B<USA>, in non-strict mode, we will map B<GU> to B<Guam>,
while in strict mode, neither B<GU> and B<Guam> will be found.

=head2 The state() method

All queries are done by calling the C<state> method in the object. This method
takes an optional argument. If an argument is given, then in scalar context,
it will return the name of the state if a code of a state is given, and the
code of a state, if the argument of the method is a name of a state. In list
context, both the code and the state will be returned.

If no argument is given, then the C<state> method in list context will return
a list of all code/name pairs for that country. In scalar context, it will
return the number of code/name pairs. Each code/name pair is a 2 element
anonymous array.

Arguments can be given in a case insensitive way; if a name consists of 
multiple parts, the number of spaces does not matter, as long as there is
some whitespace. (That is "NewYork" is wrong, but S<"new    YORK"> is fine.)

=head1 ODDITIES AND OPEN QUESTIONS

I found conflicting abbreviations for the US I<Northern Mariana Islands>,
listed as I<NI> and I<MP>. I picked I<MP> from the USPS site. 

One site listed I<Midway Islands> as having code I<MD>. It is not listed by
the USPS site, and because it conflicts with I<Maryland>, it is not put in
this listing.

The USPS also has so-called I<Military "States">, with non-unique codes.
Those are not listed here.

Canada's I<Quebec> has two codes, the older I<PQ> and the modern I<QC>. Both
I<PQ> and I<QC> will map to I<Quebec>, but I<Quebec> will only map to I<QC>.
With strict mode, I<PQ> will not be listed. Similary, Newfoundland has an
old code I<NF>, and a new code I<NL> (the province is now called
I<Newfoundland and Labrador>).

=head1 DEVELOPMENT
    
The current sources of this module are found on github,
L<< git://github.com/Abigail/geography--states.git >>.

=head1 AUTHOR

Abigail L<< mailto:geography-states@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 1999 - 2001, 2009 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut


sub init_data {
    my $data;

    $$data {'USA'} {AK} = [1 => "Alaska"];
    $$data {'USA'} {AL} = [1 => "Alabama"];
    $$data {'USA'} {AR} = [1 => "Arkansas"];
    $$data {'USA'} {AS} = [0 => "American Samoa"];
    $$data {'USA'} {AZ} = [1 => "Arizona"];
    $$data {'USA'} {CA} = [1 => "California"];
    $$data {'USA'} {CO} = [1 => "Colorado"];
    $$data {'USA'} {CT} = [1 => "Connecticut"];
    $$data {'USA'} {DC} = [0 => "District of Columbia"];
    $$data {'USA'} {DE} = [1 => "Delaware"];
    $$data {'USA'} {FL} = [1 => "Florida"];
    $$data {'USA'} {FM} = [0 => "Federated States of Micronesia"];
    $$data {'USA'} {GA} = [1 => "Georgia"];
    $$data {'USA'} {GU} = [0 => "Guam"];
    $$data {'USA'} {HI} = [1 => "Hawaii"];
    $$data {'USA'} {IA} = [1 => "Iowa"];
    $$data {'USA'} {ID} = [1 => "Idaho"];
    $$data {'USA'} {IL} = [1 => "Illinois"];
    $$data {'USA'} {IN} = [1 => "Indiana"];
    $$data {'USA'} {KS} = [1 => "Kansas"];
    $$data {'USA'} {KY} = [1 => "Kentucky"];
    $$data {'USA'} {LA} = [1 => "Louisiana"];
    $$data {'USA'} {MA} = [1 => "Massachusetts"];
    $$data {'USA'} {MD} = [1 => "Maryland"];
    $$data {'USA'} {ME} = [1 => "Maine"];
    $$data {'USA'} {MH} = [0 => "Marshall Islands"];
    $$data {'USA'} {MI} = [1 => "Michigan"];
    $$data {'USA'} {MN} = [1 => "Minnesota"];
    $$data {'USA'} {MO} = [1 => "Missouri"];
    $$data {'USA'} {MP} = [0 => "Northern Mariana Islands"];
    $$data {'USA'} {MS} = [1 => "Mississippi"];
    $$data {'USA'} {MT} = [1 => "Montana"];
    $$data {'USA'} {NC} = [1 => "North Carolina"];
    $$data {'USA'} {ND} = [1 => "North Dakota"];
    $$data {'USA'} {NE} = [1 => "Nebraska"];
    $$data {'USA'} {NH} = [1 => "New Hampshire"];
    $$data {'USA'} {NJ} = [1 => "New Jersey"];
    $$data {'USA'} {NM} = [1 => "New Mexico"];
    $$data {'USA'} {NV} = [1 => "Nevada"];
    $$data {'USA'} {NY} = [1 => "New York"];
    $$data {'USA'} {OH} = [1 => "Ohio"];
    $$data {'USA'} {OK} = [1 => "Oklahoma"];
    $$data {'USA'} {OR} = [1 => "Oregon"];
    $$data {'USA'} {PA} = [1 => "Pennsylvania"];
    $$data {'USA'} {PR} = [0 => "Puerto Rico"];
    $$data {'USA'} {PW} = [0 => "Palau"];
    $$data {'USA'} {RI} = [1 => "Rhode Island"];
    $$data {'USA'} {SC} = [1 => "South Carolina"];
    $$data {'USA'} {SD} = [1 => "South Dakota"];
    $$data {'USA'} {TN} = [1 => "Tennessee"];
    $$data {'USA'} {TX} = [1 => "Texas"];
    $$data {'USA'} {UT} = [1 => "Utah"];
    $$data {'USA'} {VA} = [1 => "Virginia"];
    $$data {'USA'} {VI} = [0 => "Virgin Islands"];
    $$data {'USA'} {VT} = [1 => "Vermont"];
    $$data {'USA'} {WA} = [1 => "Washington"];
    $$data {'USA'} {WI} = [1 => "Wisconsin"];
    $$data {'USA'} {WV} = [1 => "West Virginia"];
    $$data {'USA'} {WY} = [1 => "Wyoming"];

    $$data {'Brazil'} {AC} = [1 => "Acre"];
    $$data {'Brazil'} {AL} = [1 => "Alagoas"];
    $$data {'Brazil'} {AM} = [1 => "Amazonas"];
    $$data {'Brazil'} {AP} = [1 => "Amap\x{e1}"];
    $$data {'Brazil'} {BA} = [1 => "Bahia"];
    $$data {'Brazil'} {CE} = [1 => "Cear\x{e1}"];
    $$data {'Brazil'} {DF} = [1 => "Distrito Federal"];
    $$data {'Brazil'} {ES} = [1 => "Espir\x{ed}to Santo"];
    $$data {'Brazil'} {FN} = [1 => "Fernando de Noronha"];
    $$data {'Brazil'} {GO} = [1 => "Goi\x{e1}s"];
    $$data {'Brazil'} {MA} = [1 => "Maranh\x{e3}o"];
    $$data {'Brazil'} {MG} = [1 => "Minas Gerais"];
    $$data {'Brazil'} {MS} = [1 => "Mato Grosso do Sul"];
    $$data {'Brazil'} {MT} = [1 => "Mato Grosso"];
    $$data {'Brazil'} {PA} = [1 => "Par\x{e1}"];
    $$data {'Brazil'} {PB} = [1 => "Para\x{ed}ba"];
    $$data {'Brazil'} {PE} = [1 => "Pernambuco"];
    $$data {'Brazil'} {PI} = [1 => "Piau\x{ed}"];
    $$data {'Brazil'} {PR} = [1 => "Paran\x{e1}"];
    $$data {'Brazil'} {RJ} = [1 => "Rio de Janeiro"];
    $$data {'Brazil'} {RN} = [1 => "Rio Grande do Norte"];
    $$data {'Brazil'} {RO} = [1 => "Rond\x{f4}nia"];
    $$data {'Brazil'} {RR} = [1 => "Roraima"];
    $$data {'Brazil'} {RS} = [1 => "Rio Grande do Sul"];
    $$data {'Brazil'} {SC} = [1 => "Santa Catarina"];
    $$data {'Brazil'} {SE} = [1 => "Sergipe"];
    $$data {'Brazil'} {SP} = [1 => "S\x{e3}o Paulo"];
    $$data {'Brazil'} {TO} = [1 => "Tocantins"];

    $$data {'Canada'} {AB} = [1 => "Alberta"];
    $$data {'Canada'} {BC} = [1 => "British Columbia"];
    $$data {'Canada'} {MB} = [1 => "Manitoba"];
    $$data {'Canada'} {NB} = [1 => "New Brunswick"];
    $$data {'Canada'} {NF} = [0 => "Newfoundland"];
    $$data {'Canada'} {NL} = [1 => "Newfoundland and Labrador"];
    $$data {'Canada'} {NS} = [1 => "Nova Scotia"];
    $$data {'Canada'} {NT} = [1 => "Northwest Territories"];
    $$data {'Canada'} {NU} = [1 => "Nunavut"];
    $$data {'Canada'} {ON} = [1 => "Ontario"];
    $$data {'Canada'} {PE} = [1 => "Prince Edward Island"];
    $$data {'Canada'} {PQ} = [0 => "Quebec"];
    $$data {'Canada'} {QC} = [1 => "Quebec"];
    $$data {'Canada'} {SK} = [1 => "Saskatchewan"];
    $$data {'Canada'} {YT} = [1 => "Yukon Territory"];

    $$data {'The Netherlands'} {DR} = [1 => "Drente"];
    $$data {'The Netherlands'} {FL} = [1 => "Flevoland"];
    $$data {'The Netherlands'} {FR} = [1 => "Friesland"];
    $$data {'The Netherlands'} {GL} = [1 => "Gelderland"];
    $$data {'The Netherlands'} {GR} = [1 => "Groningen"];
    $$data {'The Netherlands'} {LB} = [1 => "Limburg"];
    $$data {'The Netherlands'} {NB} = [1 => "Noord Brabant"];
    $$data {'The Netherlands'} {NH} = [1 => "Noord Holland"];
    $$data {'The Netherlands'} {OV} = [1 => "Overijssel"];
    $$data {'The Netherlands'} {UT} = [1 => "Utrecht"];
    $$data {'The Netherlands'} {ZH} = [1 => "Zuid Holland"];
    $$data {'The Netherlands'} {ZL} = [1 => "Zeeland"];

    $$data {'Australia'} {ACT} = [1 => "Australian Capital Territory"];
    $$data {'Australia'} {NSW} = [1 => "New South Wales"];
    $$data {'Australia'} {QLD} = [1 => "Queensland"];
    $$data {'Australia'} {SA}  = [1 => "South Australia"];
    $$data {'Australia'} {TAS} = [1 => "Tasmania"];
    $$data {'Australia'} {VIC} = [1 => "Victoria"];
    $$data {'Australia'} {WA}  = [1 => "Western Australia"];

    $data;
}
