use strict; use warnings; use diagnostics;
my $t; use lib ($t = -e 't' ? 't' : 'test');
use Test::More;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

use Inline C => DATA =>
  TYPEMAPS => File::Spec->catfile(File::Spec->curdir(), $t, 'typemap');

is(int((add_em_up(1.2, 3.4) + 0.001) * 10), 46);

done_testing;

__END__
__C__
float add_em_up(float x, float y) { return x + y; }
