use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 3 }

# load your module...
use HTML::Tag;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag::SPAN\n";

my $obj = HTML::Tag->new(name => '');

ok(defined $obj);

ok($obj->html,'<span></span>');

$obj->name('test');

ok($obj->html,'<span name="test"></span>');
