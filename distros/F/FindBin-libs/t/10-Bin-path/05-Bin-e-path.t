package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin to pwd() when $0 is '-e', '-', or
# 'interactive' (eval / one-liner / interactive shell invocation).

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

BEGIN { $0 = '-e' }

use File::Spec::Functions qw( file_name_is_absolute );
use Test::More;

use FindBin::Bin qw( $Bin );

ok file_name_is_absolute( $Bin ), "\$Bin is absolute for '-e' invocation";
ok -d $Bin,                       "\$Bin names an existing directory for '-e'";

is $Bin, FindBin::Bin::pwd(),     "\$Bin eq pwd() for '-e' invocation";

done_testing;
__END__
