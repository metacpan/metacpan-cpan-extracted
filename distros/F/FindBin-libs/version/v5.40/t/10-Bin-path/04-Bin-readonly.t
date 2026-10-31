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
use FindBin::Bin    qw( $Bin $Bin_l );

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

ok length( $Bin_l ),
    "\$Bin_l is non-empty: '$Bin_l'";

eval { $Bin_l = 'foobar'; 1 }
and fail   "\$Bin_l was modified to 'foobar'"
or  pass   "\$Bin_l is not modifiable: string value";

eval { $Bin_l = ''; 1 }
and fail   "\$Bin_l was modified to empty string"
or  pass   "\$Bin_l is not modifiable: empty string";

eval { $Bin_l = undef; 1 }
and fail   "\$Bin_l was modified to undef"
or  pass   "\$Bin_l is not modifiable: undef";

done_testing;
