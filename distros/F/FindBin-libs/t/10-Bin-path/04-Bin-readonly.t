package Testophile;
use v5.40;

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

use Test::More;
use FindBin::Bin    qw( $Bin );

ok length( $Bin ),
    "\$Bin is non-empty: '$Bin'";

eval { $Bin = 'foobar'; 1 }
and fail   "\$Bin was modified to 'foobar'"
or  pass   "\$Bin is not modifiable: string value";

eval { $Bin = ''; 1 }
and fail   "\$Bin was modified to empty string"
or  pass   "\$Bin is not modifiable: empty string";

eval { $Bin = undef; 1 }
and fail   "\$Bin was modified to undef"
or  pass   "\$Bin is not modifiable: undef";

done_testing;
