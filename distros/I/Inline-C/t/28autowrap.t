use strict; use warnings; use diagnostics;
my $t; use lib ($t = -e 't' ? 't' : 'test');
use TestInlineSetup;
use Inline config => directory => $TestInlineSetup::DIR;
use Test::More;

use Inline C => sub { q{ double sin(double); } } => enable => "autowrap";
like &sin(1), qr/^0\.8/, "sin(1) returned 0.8-ish";

done_testing;
