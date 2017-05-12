# -*- perl -*-

# t/01.use.t - check object creation

use FindBin qw($Bin);
use Test::More tests => 4;

use Filesys::MakeISO;

use lib $Bin;

BEGIN {
    use_ok('Filesys::MakeISO::Driver::Test');
}


my $iso = Filesys::MakeISO->new;
ok($iso, 'new() successfull');

isa_ok($iso, 'Filesys::MakeISO');

can_ok($iso, qw(rock_ridge joliet dir image make_iso));
