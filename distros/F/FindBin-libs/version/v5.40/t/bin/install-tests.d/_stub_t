package Testophile;
use v5.40;

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;

    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

use FindBin::Testy;

FindBin::Testy->run;
