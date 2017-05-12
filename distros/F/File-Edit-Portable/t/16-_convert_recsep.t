#!perl
use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";
}

my $rw = File::Edit::Portable->new;

my ($hex, $type);

$hex = $rw->_convert_recsep("\n", 'hex');
is ($hex, '\0a', 'converts nix to hex ok');
$type = $rw->_convert_recsep("\n", 'type');
is ($type, 'nix', 'converts nix to type ok');

$hex = $rw->_convert_recsep("\r\n", 'hex');
is ($hex, '\0d\0a', 'converts win to hex ok');
$type = $rw->_convert_recsep("\r\n", 'type');
is ($type, 'win', 'converts win to type ok');

$hex = $rw->_convert_recsep("\r", 'hex');
is ($hex, '\0d', 'converts mac to hex ok');
$type = $rw->_convert_recsep("\r", 'type');
is ($type, 'mac', 'converts mac to type ok');

$hex = $rw->_convert_recsep("xxx", 'hex');
is ($hex, '787878', 'converts unknown to hex ok');
$type = $rw->_convert_recsep("xxx", 'type');
is ($type, 'unknown', 'converts unknown to type ok');

done_testing();
