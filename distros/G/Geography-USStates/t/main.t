#!/usr/local/bin/perl5.004 

use Geography::USStates qw(:all);
BEGIN { print "1..12\n"; }

my ($state, @states, %states);

print "1. Getting Statename from abbreviation\n";
$state = getState('mn');
print 'not ' unless $state eq 'Minnesota';
print "ok 1\n";

print "2. Getting State abbreviation from name\n";
$state = getState('wisconsin');
print 'not ' unless $state eq 'WI';
print "ok 2\n";

print "3. Getting All State Names\n";
@states = getStateNames();
print 'not ' unless scalar @states == 50;
print "ok 3\n";

print "4. Getting All States in a hash\n";
%states = getStates();
print 'not ' unless $states{'MN'} eq 'Minnesota';
print "ok 4\n";

print "5. Getting All Uppercase States in a hash\n";
%states = getStates(case => 'upper');
print 'not ' unless $states{'MN'} eq 'MINNESOTA';
print "ok 5\n";

print "6. Getting All lowercase States in a hash with the name as key\n";
%states = getStates(case => 'lower', hashkey => 'name');
print 'not ' unless $states{'minnesota'} eq 'MN';
print "ok 6\n";

print "7. Getting dependant area from abbreviation\n";
$state = getArea('gu');
print 'not ' unless $state eq 'Guam';
print "ok 7\n";

print "8. Getting dependant area abbreviation from name\n";
$state = getArea('guam');
print 'not ' unless $state eq 'GU';
print "ok 8\n";

print "9. Getting All Area Names\n";
@states = getAreaNames();
print 'not ' unless scalar @states == 7;
print "ok 9\n";

print "10. Getting All Areas in a hash\n";
%states = getAreas();
print 'not ' unless $states{'GU'} eq 'Guam';
print "ok 10\n";

print "11. Getting All Uppercase Areas in a hash\n";
%states = getAreas(case => 'upper');
print 'not ' unless $states{'GU'} eq 'GUAM';
print "ok 11\n";

print "12. Getting All lowercase Areas in a hash with the name as key\n";
%states = getAreas(case => 'lower', hashkey => 'name');
print 'not ' unless $states{'guam'} eq 'GU';
print "ok 12\n";

# ----------------------------------------------------------------------------
#      End of Program
# ----------------------------------------------------------------------------
