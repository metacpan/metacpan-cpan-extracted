package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_c to the directory component
# of $0 when $0 is an absolute path with no '..' segments.
# Both rel2abs and canon_dir agree on a clean absolute path.

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

BEGIN { $0 = '/this/is/absolute/path.pl' }

use File::Spec::Functions qw( file_name_is_absolute );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_c );

ok  file_name_is_absolute( $Bin ),   "\$Bin is absolute for absolute \$0";
ok  file_name_is_absolute( $Bin_c ), "\$Bin_c is absolute for absolute \$0";

is  $Bin,   '/this/is/absolute',     "\$Bin is directory of absolute \$0";
is  $Bin_c, '/this/is/absolute',     "\$Bin_c is directory of absolute \$0";

done_testing;
__END__
