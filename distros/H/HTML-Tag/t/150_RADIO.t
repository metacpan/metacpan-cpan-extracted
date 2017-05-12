use strict;
use Test;
use warnings;
use diagnostics;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 3 }

# load your module...
use HTML::Tag;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag::RADIO\n";

my $obj = HTML::Tag->new(element=>'RADIO', name => 'test');

ok(defined $obj);

$obj->value({1 => 1});

ok($obj->html,qq|<input name="test" type="radio" value="1" />1\n|);

$obj->value({1 => 1, 2 => 2});

ok($obj->html,qq|<input name="test" type="radio" value="1" />1\n<input name="test" type="radio" value="2" />2\n|);

