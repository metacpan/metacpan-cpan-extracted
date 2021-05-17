# -*- perl -*-
use Test::More tests => 11;

use strict;
use warnings;

use JSON::JQ;
use JSON qw/to_json/;

my $jq001 = JSON::JQ->new({ script => '.a + 1' });
my $input001 = { a => 7 };
my $input001_expected = 8;
is_deeply($jq001->process({ data => $input001 }), $input001_expected);

my $jq002 = JSON::JQ->new({ script => '.a + .b' });
my $input002 = { a => [ 1, 2 ], b => [ 3, 4 ] };
my $input002_expected = [ 1, 2, 3, 4 ];
is_deeply($jq002->process({ data => $input002 }), $input002_expected);

my $jq003 = JSON::JQ->new({ script => '.a + null' });
my $input003 = { a => 1 };
my $input003_expected = 1;
is_deeply($jq003->process({ data => $input003 }), $input003_expected);

my $jq004 = JSON::JQ->new({ script => '.a + 1' });
my $input004 = {};
my $input004_expected = 1;
is_deeply($jq004->process({ data => $input004 }), $input004_expected);

my $jq005 = JSON::JQ->new({ script => '{a: 1} + {b: 2} + {c: 3} + {a: 42}' });
my $input005 = undef;
my $input005_expected = { a => 42, b => 2, c => 3 };
is_deeply($jq005->process({ data => $input005 }), $input005_expected);

my $jq006 = JSON::JQ->new({ script => '4 - .a' });
my $input006 = { a => 3 };
my $input006_expected = 1;
is_deeply($jq006->process({ data => $input006 }), $input006_expected);

my $jq007 = JSON::JQ->new({ script => '. - ["xml", "yaml"]' });
my $input007 = [ "xml", "yaml", "json" ];
my $input007_expected = [ "json" ];
is_deeply($jq007->process({ data => $input007 }), $input007_expected);

my $jq008 = JSON::JQ->new({ script => '10 / . * 3' });
my $input008 = 5;
my $input008_expected = 6;
is_deeply($jq008->process({ data => $input008 }), $input008_expected);

my $jq009 = JSON::JQ->new({ script => '. / ", "' });
my $input009 = "a, b,c,d, e";
my $input009_expected = [ "a", "b,c,d", "e" ];
is_deeply($jq009->process({ data => $input009 }), $input009_expected);

my $jq010 = JSON::JQ->new({ script => '{"k": {"a": 1, "b": 2}} * {"k": {"a": 0,"c": 3}}' });
my $input010 = undef;
my $input010_expected = { k => { a => 0, b => 2, c => 3 }};
is_deeply($jq010->process({ data => $input010 }), $input010_expected);

my $jq011 = JSON::JQ->new({ script => '.[] | (1 / .)?' });
my $input011 = [ 1, 0, -1 ];
my $input011_expected = [ 1, -1 ];
is_deeply(scalar($jq011->process({ data => $input011 })), $input011_expected);