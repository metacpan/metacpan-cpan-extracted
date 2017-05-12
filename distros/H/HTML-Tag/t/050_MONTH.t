use strict;
use Test;
use Tie::IxHash;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 6 }

# load your module...
use HTML::Tag;
use HTML::Tag::Lang::it;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag::MONTH\n";

my $obj = HTML::Tag->new(element=>'MONTH', name=>'test');

ok(defined $obj);

ok($obj->html,qr/<option\svalue="05">05\s-\sMaggio<\/option>/);

$obj->selected('05');

ok($obj->html,qr/<option\svalue="05"\sselected>05\s-\sMaggio<\/option>/);

$obj->maybenull(1);

ok($obj->html,qr/^<select\sname="test"><option\svalue=""><\/option>/);

$obj->permitted([1,5,8]);
ok($obj->html !~ /<option\svalue="02">/);

$obj->permitted(['09']);
ok($obj->html, qr/<option\svalue="09">/);
