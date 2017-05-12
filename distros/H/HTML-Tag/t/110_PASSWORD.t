use strict;
use Test;
use warnings;
use diagnostics;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 4 }

# load your module...
use HTML::Tag;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag::PASSWORD\n";

my $obj = HTML::Tag->new(element=>'PASSWORD');

ok(defined $obj);

ok($obj->html,'<input type="password" />');

$obj->name('test');

ok($obj->html,'<input name="test" type="password" />');

$obj->value('tv');

ok($obj->html,'<input name="test" type="password" value="tv" />');
