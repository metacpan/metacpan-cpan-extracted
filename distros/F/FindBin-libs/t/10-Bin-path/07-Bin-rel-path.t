package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin to an absolute directory when $0 is
# a relative path: expected = catpath( $v, catdir( pwd, $d ), '' ).
# Uses FindBin::Bin::pwd() to match Bin.pm's pwd-L semantics rather
# than abs_path, which resolves symlinks.

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

BEGIN { $0 = 'this/is/relative/path.pl' }

use File::Spec::Functions qw( canonpath catdir catpath file_name_is_absolute splitpath );
use Test::More;

use FindBin::Bin qw( $Bin );

my ( $v, $d ) = splitpath 'this/is/relative/path.pl';
my $expect    = canonpath catpath $v, catdir( FindBin::Bin::pwd(), $d ), '';

ok  file_name_is_absolute( $Bin ),   "\$Bin is absolute for relative \$0";
is  $Bin, $expect,                    "\$Bin is directory of relative \$0";

done_testing;
__END__
