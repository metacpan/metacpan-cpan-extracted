
use strict;
use warnings;
use Test::More tests => 2;

use Method::Signatures::Simple;

func empty ($x) {}

is scalar empty(1), undef, "empty func returns nothing (scalar context)";
is_deeply [empty(1,2)], [], "empty func returns nothing (list context)";

__END__
