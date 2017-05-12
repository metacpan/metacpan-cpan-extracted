use strict; use warnings; use diagnostics;
use lib -e 't' ? 't' : 'test';
use Test::More;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

use Inline 'C';

$main::myvar = $main::myvar = "myvalue";
is(lookup('main::myvar'), "myvalue");
done_testing;

__END__
__C__
SV* lookup(char* var) { return perl_get_sv(var, 0); }
