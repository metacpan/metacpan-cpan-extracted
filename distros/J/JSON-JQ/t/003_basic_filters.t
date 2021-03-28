# -*- perl -*-
use Test::More tests => 27;

use strict;
use warnings;

use JSON::JQ;
use JSON qw/to_json/;

my $jq001 = JSON::JQ->new({ script => '.' });
my $input001 = "Hello, world!";
my $input001_expected = $input001;
is_deeply($jq001->process({ data => $input001 }), $input001_expected);

my $jq002 = JSON::JQ->new({ script => '. | tojson ' });
my $input002 = 123456789;
my $input002_expected = '"'. "$input002". '"';
is_deeply($jq002->process({ data => "$input002" }), $input002_expected);

my $jq003 = JSON::JQ->new({ script => 'map([., . == 1]) | tojson' });
my $input003 = [ 1, 1.000, 1.01, 100e-2 ];
my $input003_expected = '[[1,true],[1,true],[1.01,false],[1,true]]';
is_deeply($jq003->process({ data => $input003 }), $input003_expected);

my $jq004 = JSON::JQ->new({ script => '. as $big | [$big, $big + 1] | map(. > 1000000000) ' });
my $input004 = 1000000000;
my $input004_expected = [ $JSON::false, $JSON::true ];
is_deeply($jq004->process({ data => $input004 }), $input004_expected);

my $jq005 = JSON::JQ->new({ script => '.foo' });
my $input005 = { foo => 42, bar => "less interesting data" };
my $input005_expected = 42;
is_deeply($jq005->process({ data => $input005 }), $input005_expected);

my $jq006 = JSON::JQ->new({ script => '.foo' });
my $input006 = { notfoo => $JSON::true, alsonotfoo => $JSON::false };
my $input006_expected = undef;
is_deeply($jq006->process({ data => $input006 }), $input006_expected);

my $jq007 = JSON::JQ->new({ script => '.["foo"]' });
my $input007 = { foo => 42 };
my $input007_expected = 42;
is_deeply($jq007->process({ data => $input007 }), $input007_expected);

my $jq008 = JSON::JQ->new({ script => '.foo?' });
my $input008 = { foo => 42, bar => "less interesting data" };
my $input008_expected = 42;
is_deeply($jq008->process({ data => $input008 }), $input008_expected);

my $jq009 = JSON::JQ->new({ script => '.foo?' });
my $input009 = { notfoo => $JSON::true, alsonotfoo => $JSON::false };
my $input009_expected = undef;
is_deeply($jq009->process({ data => $input009 }), $input009_expected);

my $jq010 = JSON::JQ->new({ script => '.["foo"]?' });
my $input010 = { foo => 42 };
my $input010_expected = 42;
is_deeply($jq010->process({ data => $input010 }), $input010_expected);

my $jq011 = JSON::JQ->new({ script => '[.foo?]' });
my $input011 = [ 1, 2 ];
my $input011_expected = [];
is_deeply($jq011->process({ data => $input011 }), $input011_expected);

my $jq012 = JSON::JQ->new({ script => '.[0]' });
my $input012 = [ {name => "JSON", good => $JSON::true }, { name => "XML", good => $JSON::false } ];
my $input012_expected = { name => "JSON", good => $JSON::true };
is_deeply($jq012->process({ data => $input012 }), $input012_expected);

my $jq013 = JSON::JQ->new({ script => '.[2]' });
my $input013 = [ {name => "JSON", good => $JSON::true }, { name => "XML", good => $JSON::false } ];
my $input013_expected = undef;
is_deeply($jq013->process({ data => $input013 }), $input013_expected);

my $jq014 = JSON::JQ->new({ script => '.[-2]' });
my $input014 = [ 1, 2, 3 ];
my $input014_expected = 2;
is_deeply($jq014->process({ data => $input014 }), $input014_expected);

my $jq015 = JSON::JQ->new({ script => '.[2:4]' });
my $input015 = [ "a", "b", "c", "d", "e" ];
my $input015_expteced = [ "c", "d" ];
is_deeply($jq015->process({ data => $input015 }), $input015_expteced);

my $jq016 = JSON::JQ->new({ script => '.[2:4]' });
my $input016 = "abcdefghi";
my $input016_expected = "cd";
is_deeply($jq016->process({ data => $input016}), $input016_expected);

my $jq017 = JSON::JQ->new({ script => '.[:3]' });
my $input017 = [ "a", "b", "c", "d", "e" ];
my $input017_expteced = [ "a", "b", "c" ];
is_deeply($jq017->process({ data => $input017 }), $input017_expteced);

my $jq018 = JSON::JQ->new({ script => '.[-2:]' });
my $input018 = [ "a", "b", "c", "d", "e" ];
my $input018_expteced = [ "d", "e" ];
is_deeply($jq018->process({ data => $input018 }), $input018_expteced);

my $jq019 = JSON::JQ->new({ script => '.[]' });
my $input019 = [ {name => "JSON", good => $JSON::true }, { name => "XML", good => $JSON::false } ];
my $input019_expected = $input019;
is_deeply([ $jq019->process({ data => $input019 }) ], $input019_expected);

my $jq020 = JSON::JQ->new({ script => '.[]' });
my $input020 = [];
my $input020_expected = undef;
is_deeply($jq020->process({ data => $input020 }), $input020_expected);

my $jq021 = JSON::JQ->new({ script => '.[]' });
my $input021 = { a => 1, b => 1 };
my $input021_expected = [ 1, 1 ];
is_deeply(scalar($jq021->process({ data => $input021 })), $input021_expected);

my $jq022 = JSON::JQ->new({ script => '.[]?' });
my $input022 = 1;
my $input022_expected = undef;
is_deeply($jq022->process({ data => $input022 }), $input022_expected);

my $jq023 = JSON::JQ->new({ script => '.foo, .bar' });
my $input023 = { foo => 42, bar => "something else", baz => $JSON::true };
my $input023_expected = [ 42, "something else" ];
is_deeply(scalar($jq023->process({ data => $input023 })), $input023_expected);

my $jq024 = JSON::JQ->new({ script => '.user, .projects[]' });
my $input024 = { user => "stedolan", projects => [ "jq", "wikiflow" ] };
my $input024_expected = [ "stedolan", "jq", "wikiflow" ];
is_deeply(scalar($jq024->process({ data => $input024 })), $input024_expected);

my $jq025 = JSON::JQ->new({ script => '.[4,2]' });
my $input025 = [ "a", "b", "c", "d", "e" ];
my $input025_expected = [ "e", "c" ];
is_deeply(scalar($jq025->process({ data => $input025 })), $input025_expected);

my $jq026 = JSON::JQ->new({ script => '.[] | .name' });
my $input026 = [ {name => "JSON", good => $JSON::true }, { name => "XML", good => $JSON::false } ];
my $input026_expected = [ "JSON", "XML" ];
is_deeply(scalar($jq026->process({ data => $input026 })), $input026_expected);

my $jq027 = JSON::JQ->new({ script => '(. + 2) * 5' });
my $input027 = 1;
my $input027_expected = 15;
is_deeply($jq027->process({ data => $input027 }), $input027_expected);