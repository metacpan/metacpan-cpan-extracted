package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_c correctly when $0 is '-'
# (stdin / pipe invocation: perl - < script.pl).
#
# $Bin_c = pwd()             -- absolute, symlinks and '..' preserved as-is
# $Bin   = rel2abs( pwd() )  -- canonpath of pwd (same for clean paths)

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

BEGIN { $0 = '-' }

use File::Spec::Functions qw( file_name_is_absolute rel2abs );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_c );

my $pwd = FindBin::Bin::pwd();

ok  file_name_is_absolute( $Bin ),   "\$Bin is absolute for '-' (stdin) invocation";
ok  file_name_is_absolute( $Bin_c ), "\$Bin_c is absolute for '-' (stdin) invocation";

ok  -d $Bin,                          "\$Bin names an existing directory for '-'";
ok  -d $Bin_c,                        "\$Bin_c names an existing directory for '-'";

is  $Bin_c, $pwd,                     "\$Bin_c eq pwd() for '-' invocation";
is  $Bin,   rel2abs( $pwd ),          "\$Bin eq rel2abs(pwd()) for '-' invocation";

done_testing;
__END__
