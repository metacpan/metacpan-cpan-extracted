#! perl
use Test::More "no_plan";

BEGIN { use_ok(Inline => 'FORCE') }

use Inline Spew => 'DATA';

# require YAML;
diag(join " ", "result is", my $result = spew());

__DATA__
__Spew__
START: qx/date/
