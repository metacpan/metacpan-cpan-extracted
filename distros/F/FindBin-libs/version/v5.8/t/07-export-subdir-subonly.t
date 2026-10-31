package Testophile;

use v5.8;

$\ = "\n";
$, = "\n\t";

BEGIN   { mkdir './lib/foo', 0555   }
END     { rmdir './lib/foo'         }

use FindBin::libs qw( export subdir=foo subonly );

use Test::More tests => 1;

ok @lib == 1, 'Found only foo subdir';

__END__
