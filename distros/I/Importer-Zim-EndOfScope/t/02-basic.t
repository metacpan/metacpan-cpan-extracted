
use Test::More;

package M1;

BEGIN { $INC{'M1.pm'} = __FILE__ }

BEGIN { our @EXPORT_OK = qw(f1 f2 f3); }

sub f1 { }
sub f2 { }
sub f3 { }

sub f4 { }

package main;

{
    {
        use Importer::Zim::EndOfScope 'M1' => qw(f1 f2);

        ok( defined &f1, 'f1 was imported' );
        is( \&f1, \&M1::f1, 'f1 comes from M1' );

        ok( defined &f2, 'f2 was imported' );
        is( \&f2, \&M1::f2, 'f2 comes from M1' );
    }

    ok( !defined &f1, 'f1 is gone' );
    ok( !defined &f2, 'f2 is gone' );
}

{
    {
        use Importer::Zim::EndOfScope 'M1' =>
          ( 'f1' => { -as => 'g1' }, 'f2', 'f3' => { -as => 'h3' } );

        ok( defined &g1, 'g1 was imported' );
        is( \&g1, \&M1::f1, 'g1 comes from M1::f1' );

        ok( defined &f2, 'f2 was imported' );
        is( \&f2, \&M1::f2, 'f2 comes from M1::f2' );

        ok( defined &h3, 'h3 was imported' );
        is( \&h3, \&M1::f3, 'h3 comes from M1::f3' );
    }

    ok( !defined &g1, 'g1 is gone' );
    ok( !defined &f2, 'f2 is gone' );
    ok( !defined &h3, 'h3 is gone' );
}

{
    {
        use Importer::Zim::EndOfScope 'M1' => { -strict => 0 } => qw(f1 f4);

        ok( defined &f1, 'f1 was imported' );
        is( \&f1, \&M1::f1, 'f1 comes from M1::f1' );

        ok( defined &f4, 'f4 was imported (though not exportable)' );
        is( \&f4, \&M1::f4, 'f4 comes from M1::f4' );
    }

    ok( !defined &f1, 'f1 is gone' );
    ok( !defined &f4, 'f4 is gone' );
}

done_testing;
