# -------------------------------------------------------------------------
# Name: Geography::USStates.pm
# Auth: Dion Almaer (dion)
# Desc: Get info on US States / Dependant Areas
# Date Created: Sun Nov 15 17:50:29 1998
# Version: 0.12
# $Modified: Wed May 26 02:15:53 1999 by dion $
# -------------------------------------------------------------------------
package Geography::USStates;

use     strict;
require 5.002;
require Exporter;

$Geography::USStates::VERSION = '0.12';
@Geography::USStates::ISA     = qw(Exporter);
@Geography::USStates::EXPORT  = qw(getState getStates getStateNames getStateAbbrevs);
@Geography::USStates::EXPORT_OK   = qw(getArea getAreas getAreaNames getAreaAbbrevs getStateOrArea getStatesAndAreas 
									   getStatesAndAreasNames getStatesAndAreasAbbrevs);
%Geography::USStates::EXPORT_TAGS =(states=> [qw|getState getStates getStateNames getStateAbbrevs|],
                                    areas => [qw|getArea getAreas getAreaNames getAreaAbbrevs|],
                                    both  => [qw|getStateOrArea getStatesAndAreas getStatesAndAreasNames getStatesAndAreasAbbrevs|],
                                    all   => [qw|getStateOrArea getStatesAndAreas getStatesAndAreasNames getStatesAndAreasAbbrevs
											     getState getStates getStateNames getStateAbbrevs
                                                 getArea getAreas getAreaNames getAreaAbbrevs|]);

%Geography::USStates::STATES =
                  (AL => 'Alabama', AK => 'Alaska', AZ => 'Arizona',
                   AR => 'Arkansas', CA => 'California', CO => 'Colorado',
                   CT => 'Connecticut', DE => 'Delaware', FL => 'Florida',
                   GA => 'Georgia', HI => 'Hawaii', ID => 'Idaho',
                   IL => 'Illinois', IN => 'Indiana', IA => 'Iowa',
                   KS => 'Kansas', KY => 'Kentucky',
                   LA => 'Louisiana', ME => 'Maine', MD => 'Maryland',
                   MA => 'Massachusetts', MI => 'Michigan', MN => 'Minnesota',
                   MS => 'Mississippi', MO => 'Missouri', MT => 'Montana',
                  'NE' => 'Nebraska', NJ => 'New Jersey', NH => 'New Hampshire',
                   NV => 'Nevada', NM => 'New Mexico', NY => 'New York',
                   NC => 'North Carolina', ND => 'North Dakota', OH => 'Ohio',
                   OK => 'Oklahoma', OR => 'Oregon', PA => 'Pennsylvania',
                   RI => 'Rhode Island', SC => 'South Carolina',
                   SD => 'South Dakota', TN => 'Tennessee', TX => 'Texas',
                   UT => 'Utah', VT => 'Vermont', VA => 'Virginia',
                   WA => 'Washington', WV => 'West Virginia', WI => 'Wisconsin',
                   WY => 'Wyoming');

%Geography::USStates::AREAS = (AS => 'American Samoa', DC => 'District Of Columbia', GU => 'Guam', 
                               MD => 'Midway Islands', NI => 'Northern Mariana Islands',
							   PR => 'Puerto Rico', VI => 'Virgin Islands');

%Geography::USStates::BOTH = (%Geography::USStates::STATES, %Geography::USStates::AREAS);

# ----------------------------------------------------------------------------
# CORE FUNCTIONS: These functions do the real work
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Subroutine: getKey - Given a hashref and (abbrev get full name, name get abbrev)
# ----------------------------------------------------------------------------
sub getKey {
	my $hashref = shift;
   	my $value = shift;
	if (length $value > 2) {
		my %states = getKeys($hashref, 'case' => 'lower', 'hashkey' => 'name');
        return $states{lc $value};
    } else {
        return $hashref->{uc $value};
    }
}

# ----------------------------------------------------------------------------
# Subroutine: getKeys - return a hash: $hash{'MN'} = 'Minnesota'
# ----------------------------------------------------------------------------
sub getKeys {
	my $hashref = shift;
    my %hash = (ref $_[0] eq 'HASH') ? %{ $_[0] } : @_;

    # -- do something to the states
    $hash{hashkey} ||= ''; # -- for -w
    $hash{case}    ||= ''; # -- for -w

    return %{ $hashref }
          unless @_ || $hash{case} || $hash{hashkey} eq 'name';

    my %states;
    while ( my ($abbrev, $name) = each %{ $hashref } ) {
            if ($hash{case} =~ /^[lu]/i) {
                $name = ($hash{case} =~ /^u/i) ? uc $name : lc $name;
            }
            if ($hash{hashkey} eq 'name') {
                $states{$name}   = $abbrev;
            } else {
                $states{$abbrev} = $name;
            }
    }
    return %states;
}

sub getNames   { return sort values %{ $_[0] }; }
sub getAbbrevs { return sort keys   %{ $_[0] }; }

# ----------------------------------------------------------------------------
# US STATE FUNCTIONS
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Subroutine: getState - given abbrev get full name, given name get abbrev
# ----------------------------------------------------------------------------
sub getState { getKey(\%Geography::USStates::STATES, @_); }

# ----------------------------------------------------------------------------
# Subroutine: getStates - return a states hash: $hash{'MN'} = 'Minnesota'
# ----------------------------------------------------------------------------
sub getStates {	getKeys(\%Geography::USStates::STATES, @_); }

# ----------------------------------------------------------------------------
# Subroutine: getStateNames - return an array of states by name
# ----------------------------------------------------------------------------
sub getStateNames   { getNames(\%Geography::USStates::STATES); }

# ----------------------------------------------------------------------------
# Subroutine: getStateAbbrevs - return an array of states by 2 letter abbrev
# ----------------------------------------------------------------------------
sub getStateAbbrevs { getAbbrevs(\%Geography::USStates::STATES); }

# ----------------------------------------------------------------------------
# DEPENDANT AREAS: These are areas that aren't states, but are part of the US
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Subroutine: getArea - given abbrev get full name, given name get abbrev
# ----------------------------------------------------------------------------
sub getArea { getKey(\%Geography::USStates::AREAS, @_); }

# ----------------------------------------------------------------------------
# Subroutine: getAreas - return an areas hash: $hash{'GU'} = 'Guam'
# ----------------------------------------------------------------------------
sub getAreas { getKeys(\%Geography::USStates::AREAS, @_); }

# ----------------------------------------------------------------------------
# Subroutine: getAreaNames - return an array of areas by name
# ----------------------------------------------------------------------------
sub getAreaNames { getNames(\%Geography::USStates::AREAS); }

# ----------------------------------------------------------------------------
# Subroutine: getAreaAbbrevs - return an array of areas by 2 letter abbrev
# ----------------------------------------------------------------------------
sub getAreaAbbrevs { getAbbrevs(\%Geography::USStates::AREAS); }

# ----------------------------------------------------------------------------
# BOTH: Look up both states and dependant areas
# ----------------------------------------------------------------------------
  
# ----------------------------------------------------------------------------
# Subroutine: getStateOrArea - given abbrev get full name, given name get abbrev
# ----------------------------------------------------------------------------
sub getStateOrArea { getKey(\%Geography::USStates::BOTH, @_); }

# ----------------------------------------------------------------------------
# Subroutine: getStatesAndAreas - return a state or areas hash
# ----------------------------------------------------------------------------
sub getStatesAndAreas { getKeys(\%Geography::USStates::BOTH, @_); }

# ----------------------------------------------------------------------------
# Subroutine: getStatesAndAreasNames - return an array of both by name
# ----------------------------------------------------------------------------
sub getStatesAndAreasNames { getNames(\%Geography::USStates::BOTH); }

# ----------------------------------------------------------------------------
# Subroutine: getStatesAndAreasAbbrevs - return an array of both by 2 letter abbrev
# ----------------------------------------------------------------------------
sub getStatesAndAreasAbbrevs { getAbbrevs(\%Geography::USStates::BOTH); }

# ----------------------------------------------------------------------------
1; # End of Geography::USStates.pm
# ----------------------------------------------------------------------------

__END__

=head1 NAME

Geography::USStates - USA State Data

=head1 SYNOPSIS

use Geography::USStates; # -- just getState* functions
use Geography::USStates qw(:areas); # -- just getArea* functions
use Geography::USStates qw(:both);  # -- just getState*Area* functions
use Geography::USStates qw(:both);  # -- all functions

# ------ US STATES BASED
$state = getState('mn');        # -- get the statename 'Minnesota'

$state = getState('wisconsin'); # -- get the abbreviation 'wi'

@states = getStateNames();      # -- return all state names

@states = getStateAbbrevs();    # -- return all state abbrevations (AL, AK, ..)

%s = getStates();               # -- return hash $states{'MN'} = 'Minnesota'

%s = getStates(case=>'upper');  # -- return hash $states{'MN'} = 'MINNESOTA'

%s = getStates(case=>'lower');  # -- return hash $states{'MN'} = 'minnesota'

%s = getStates(hashkey=>'name');# -- return hash $states{'Minnesota'} = 'MN'

# ------ US AREAS
$area = getArea('gu');          # -- get the area name 'Guam'

$area = getArea('guam');        # -- get the abbreviation 'gu'

@areas = getAreaNames();        # -- return all area names

@areas = getAreaAbbrevs();      # -- return all area abbrevations (DC, GU, ..)

%a = getAreas();                # -- return hash $states{'GU'} = 'Guam'

%a = getAreas(case=>'upper');   # -- return hash $states{'GU'} = 'GUAM'

%a = getAreas(case=>'lower');   # -- return hash $states{'GU'} = 'guam'

%a = getAreas(hashkey=>'name'); # -- return hash $states{'Guam'} = 'GU'

# ------ Lookup both US States and Dependant areas
# -- get the statename 'Minnesota' or 'Guam' respectivily
$state = getStateOrArea('mn' || 'gu');  

# -- get the abbreviation 'wi' or 'gu' respectivily
$state = getStateOrArea('wisconsin' || 'guam'); 

# -- return all states and areas names together
@states = getStatesAndAreasNames();

# -- return all states and areas abbreviations together
@states = getStatesAndAreasAbbrevs();

# -- same as getStates() but it returns the areas in the hash too
%s = getStatesAndAreas();               
%s = getStatesAndAreas(case=>'upper');  
%s = getStatesAndAreas(case=>'lower');  
%s = getStatesAndAreas(hashkey=>'name');

=head1 DESCRIPTION

This module allows you to get information on US State names, their
abbreviations, and couple the two together (in hashes). As well as
states, the US has "Dependant Area's" like Guam, 
and the Virgin Islands. Sometimes you want to offer these areas
in your application so you can get access to those via the
getArea*() functions and the getState*Area*() functions.

=head1 FUNCTIONS

o B<getState>($statename || $stateabbrev)

  Given an abbreviation a statename is returned.
  Given a name an abbreviatin is returned

  e.g. print getState('MN');
       would print 'Minnesota'

       print getState('wisconsin');
       would print 'WI'

 o B<getStateNames>()

    Return all of the states in an array

    e.g. map { print "$_\n" } getStateNames();
         would print "Alabama\nAlaska\n...";
  
  o B<getStateAbbrevs>()
  
    Return all of the abbrevs in an array
  
    e.g. map { print "$_\n" } getStateAbbrevs();
         would print "AL\nAK\n...";
  
  o B<getStates>(%hash | $hashref) [keys: case => upper||lower, hashkey=>name]
  
    A hash is returned with both abbrev and statename. By default it returns
    the state abbrev as the key and the state name as the value
  
    e.g. $hash{MN} = 'Minnesota';
  
    You can also pass params in a hash or hashref. To force the state names
    to be lower case, or upper case you do:
  
    getStates(case => 'upper'); # -- for upper case... lower for lower case
  
    If you want to return a hash where the name is the key you do:
  
    my %s = getStates(hashkey => 'name');
    and then
    $s{'Minnesota'} = 'MN';
  
  =head1 AUTHOR
  
  Dion Almaer (dion@almaer.com)
  
=cut
