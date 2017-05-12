use strict;
use Test;
use warnings;
use diagnostics;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 6 }

# load your module...
use HTML::Tag;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag::TEXTFIELD\n";

my $obj = HTML::Tag->new(element=>'TEXTFIELD',name => '');

ok(defined $obj);

ok($obj->html,'<input type="text" />');

$obj->name('test');

ok($obj->html,'<input name="test" type="text" />');

$obj->value('tv');

ok($obj->html,'<input name="test" type="text" value="tv" />');

$obj->size(6);

ok($obj->html,'<input name="test" type="text" value="tv" size="6" />');

$obj->maxlength(6);

ok($obj->html,'<input name="test" type="text" value="tv" size="6" maxlength="6" />');
