# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-CTPP2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('HTML::CTPP2') };

use strict;
use MIME::Base64;

my $T = new HTML::CTPP2(source_charset => 'CP1251', destination_charset => 'utf-8');
ok( ref $T eq "HTML::CTPP2", "Create object.");

my $Bytecode = $T -> parse_template("charset_recoder.tmpl");
ok( ref $Bytecode eq "HTML::CTPP2::Bytecode", "Create object.");

my %H = ("a" => 'Òåñò êîäèðîâêè CP-1251');
ok( $T -> param(\%H) == 0);

my $Result = encode_base64($T -> output($Bytecode));
ok( $Result eq "0KLQtdGB0YI6INCi0LXRgdGCINC60L7QtNC40YDQvtCy0LrQuCBDUC0xMjUxCg==\n");

$T -> reset();

%H = ("a" => 'ðÒÏ×ÅÒËÁ ËÏÄÉÒÏ×ËÉ KOI8-R');
ok( $T -> param(\%H) == 0);
$Result = encode_base64($T -> output($Bytecode, 'koi8-r', 'utf-8'));
ok( $Result eq "0YDQldCv0KA6INCf0YDQvtCy0LXRgNC60LAg0LrQvtC00LjRgNC+0LLQutC4IEtPSTgtUgo=\n");

%H = ("a" => "incorrect encoding ìóñîð test");
ok( $T -> param(\%H) == 0);
$Result = encode_base64($T -> output($Bytecode, 'utf-8', 'utf-8'));
ok( $Result eq "OiBpbmNvcnJlY3QgZW5jb2RpbmcgIHRlc3QK\n");
