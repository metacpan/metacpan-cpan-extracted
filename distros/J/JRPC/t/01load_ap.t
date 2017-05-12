# Test the JRPC::Apache2 independently here because of the deep chain of
# non-mandated dependencies to Apache2 / mod_perl.
# Skip all if Apache2::* modules not found.
use Test::More;
use lib ('..');

eval("use Apache2::RequestRec;");
if ($@) {
   plan('skip_all', "No Apache2::* modules found (and not required), skipping ...");
}

plan('tests', 1);
use_ok('JRPC::Apache2');

