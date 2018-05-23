
use Test::More;

package M1;

BEGIN { $INC{'M1.pm'} = __FILE__ }

BEGIN { our @EXPORT_OK = qw(f1 f2 f3); }

sub f1 { }
sub f2 { }
sub f3 { }

sub f4 { }

package main;

UNITCHECK {
    ok( !__PACKAGE__->can('f1'), 'f1 is gone (by UNITCHECK time)' );
    ok( !__PACKAGE__->can('f2'), 'f2 is gone (by UNITCHECK time)' );
}

use Importer::Zim::Unit 'M1' => qw(f1 f2);

ok( defined &f1, 'f1 was imported' );
is( \&f1, \&M1::f1, 'f1 comes from M1' );

ok( defined &f2, 'f2 was imported' );
is( \&f2, \&M1::f2, 'f2 comes from M1' );

done_testing;
