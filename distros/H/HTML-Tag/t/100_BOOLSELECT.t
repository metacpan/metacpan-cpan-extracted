use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 3 }

# load your module...
use HTML::Tag;
use HTML::Tag::Lang::it;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag::BOOLSELECT\n";

my $obj = HTML::Tag->new(element=>'BOOLSELECT', name=>'test');

ok(defined $obj);

ok($obj->html,qq|<select name="test"><option value="1">Si</option>\n<option value="0">No</option>\n</select>|);

$obj->maybenull(1);

ok($obj->html,qr/^<select\sname="test"><option\svalue=""><\/option>/);
