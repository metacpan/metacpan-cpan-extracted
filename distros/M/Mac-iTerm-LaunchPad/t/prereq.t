# $Id: prereq.t 2056 2007-01-20 00:37:44Z comdog $
use Test::More;
eval "use Test::Prereq";
plan skip_all => "Test::Prereq required to test dependencies" if $@;
prereq_ok();
