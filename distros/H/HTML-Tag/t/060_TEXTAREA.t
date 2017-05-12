use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 4 }

# load your module...
use HTML::Tag;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag:TEXTAREA\n";

my $obj = HTML::Tag->new(element=>'TEXTAREA');

ok(defined $obj);

ok($obj->html,'<textarea cols="40" rows="5"></textarea>');

$obj->name('test');

ok($obj->html,'<textarea name="test" cols="40" rows="5"></textarea>');

$obj->value('tv');

ok($obj->html,'<textarea name="test" cols="40" rows="5">tv</textarea>');
