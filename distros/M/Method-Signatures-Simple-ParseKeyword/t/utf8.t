
use strict;
use warnings;
use utf8;
use Test::More tests => 2;

use Method::Signatures::Simple::ParseKeyword;

func empty ($x) {}

is scalar empty(1), undef, "empty func returns nothing (scalar context)";
is_deeply [empty(1,2)], [], "empty func returns nothing (list context)";

done_testing;

__END__
