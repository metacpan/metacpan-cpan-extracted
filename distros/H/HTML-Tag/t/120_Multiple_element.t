use strict;
use Test;
use warnings;
use diagnostics;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 2 }

# load your module...
use HTML::Tag;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing two elements\n";

my @arr;

my $obj = HTML::Tag->new(element=>'PASSWORD');

$obj->name('test');
$obj->value('tv');


push @arr,$obj;

my $obj1 = HTML::Tag->new(element=>'TEXTFIELD');

$obj1->name('test');
$obj1->value('tv');

push @arr,$obj1;

ok($arr[0]->html,'<input name="test" type="password" value="tv" />');

ok($arr[1]->html,'<input name="test" type="text" value="tv" />');

