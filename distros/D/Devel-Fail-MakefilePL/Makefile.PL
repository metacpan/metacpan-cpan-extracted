
use strict;
use warnings;

use lib '.';

use inc::Module::Install;

my
$VERSION = 1.82;

BEGIN {
  name('Devel-Fail-MakefilePL');
  all_from('lib/Devel/Fail/MakefilePL.pm');
  license('perl');
  WriteAll;
  } # end of BEGIN block

Deliberate_compile_error!

foo

bar baz

exit 88;

__END__
