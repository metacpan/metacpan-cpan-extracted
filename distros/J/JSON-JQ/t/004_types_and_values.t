# -*- perl -*-
use Test::More tests => 4;

use strict;
use warnings;

use JSON::JQ;
use JSON qw/to_json/;

my $jq001 = JSON::JQ->new({ script => '[ .[] | . * 2]' });
my $input001 = [ 1, 2, 3 ];
my $input001_expected = [ 2, 4, 6 ];
is_deeply($jq001->process({ data => $input001 }), $input001_expected);

my $jq002 = JSON::JQ->new({ script => '{ user, title: .titles[] }' });
my $input002 = { user => "stedolan", titles => [ "JQ Primer", "More JQ" ] };
my $input002_expected = [ { user => "stedolan", title => "JQ Primer" }, { user => "stedolan", title => "More JQ" } ];
is_deeply(scalar($jq002->process({ data => $input002 })), $input002_expected);

my $jq003 = JSON::JQ->new({ script => '{ (.user): .titles }' });
my $input003 = { user => "stedolan", titles => [ "JQ Primer", "More JQ" ] };
my $input003_expected = { stedolan => [ "JQ Primer", "More JQ" ] };
is_deeply($jq003->process({ data => $input003 }), $input003_expected);

my $jq004 = JSON::JQ->new({ script => '..|.a?' });
my $input004 = [ [ { a => 1 } ] ];
my $input004_expected = 1;
is_deeply($jq004->process({ data => $input004 }), $input004_expected);