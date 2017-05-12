use strict;
use Test;
use Tie::IxHash;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 5 }

# load your module...
use HTML::Tag;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag::YEAR\n";

my $year = (localtime())[5]+1900;
my $obj = HTML::Tag->new(element=>'YEAR', name=>'test',from => $year);
use Tie::IxHash;

ok(defined $obj);

ok($obj->html,qr/<option\svalue="$year"\sselected>$year<\/option>/);

$year++;

$obj->selected($year);

ok($obj->html,qr/<option\svalue="$year"\sselected>$year<\/option>/);

$obj->maybenull(1);

ok($obj->html,qr/^<select\sname="test"><option\svalue=""><\/option>/);

$obj->permitted([2003,2004,2005]);

ok($obj->html !~ /<option\svalue="$year"\sselected>$year<\/option>/);
