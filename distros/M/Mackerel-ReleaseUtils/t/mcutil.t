use strict;
use warnings;
use utf8;
use Test::More;

use Mackerel::ReleaseUtils;

my $version = '0.1.2';
my ($major, $minor, $patch) = Mackerel::ReleaseUtils::parse_version $version;
is $major, 0;
is $minor, 1;
is $patch, 2;
is Mackerel::ReleaseUtils::suggest_next_version($version), '0.2.0';

done_testing;
