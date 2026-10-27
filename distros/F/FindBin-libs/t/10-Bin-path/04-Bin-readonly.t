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
use FindBin::Bin    qw( $Bin $Bin_c );

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

ok length( $Bin_c ),
    "\$Bin_c is non-empty: '$Bin_c'";

eval { $Bin_c = 'foobar'; 1 }
and fail   "\$Bin_c was modified to 'foobar'"
or  pass   "\$Bin_c is not modifiable: string value";

eval { $Bin_c = ''; 1 }
and fail   "\$Bin_c was modified to empty string"
or  pass   "\$Bin_c is not modifiable: empty string";

eval { $Bin_c = undef; 1 }
and fail   "\$Bin_c was modified to undef"
or  pass   "\$Bin_c is not modifiable: undef";

done_testing;
