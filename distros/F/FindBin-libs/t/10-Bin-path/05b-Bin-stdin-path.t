package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_l correctly when $0 is '-'
# (stdin / pipe invocation: perl - < script.pl).
#
# $Bin_l = pwd()   -- logical CWD (symlinks preserved, like pwd -L)
# $Bin   = $Bin_l  -- defaults to logical path

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

use FindBin::Bin qw( $Bin $Bin_l );

my $pwd = FindBin::Bin::pwd();

ok  file_name_is_absolute( $Bin ),   "\$Bin is absolute for '-' (stdin) invocation";
ok  file_name_is_absolute( $Bin_l ), "\$Bin_l is absolute for '-' (stdin) invocation";

ok  -d $Bin,                          "\$Bin names an existing directory for '-'";
ok  -d $Bin_l,                        "\$Bin_l names an existing directory for '-'";

is  $Bin_l, $pwd,    "\$Bin_l eq pwd() for '-' invocation";
is  $Bin,   $Bin_l,  "\$Bin eq \$Bin_l for '-' invocation";

done_testing;
__END__
