package Testophile;
use v5.40;

# Test that FindBin::Bin sets $Bin and $Bin_p correctly when $0 is
# 'interactive' (perl -d or debugger interactive session).
#
# $Bin_l = pwd()            -- logical CWD (symlinks preserved, like pwd -L)
# $Bin_p = abs_path(pwd())  -- physical CWD (symlinks resolved, like pwd -P)
# $Bin   = $Bin_p           -- defaults to physical path (abspath)

BEGIN
{
    use File::Basename        qw( dirname    );
    use File::Spec::Functions qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', '..', 'lib' );
}

BEGIN { $0 = 'interactive' }

use File::Spec::Functions qw( file_name_is_absolute rel2abs );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_l $Bin_p );

my $pwd = FindBin::Bin::pwd();

ok  file_name_is_absolute( $Bin ),   "\$Bin is absolute for 'interactive' invocation";
ok  file_name_is_absolute( $Bin_l ), "\$Bin_l is absolute for 'interactive' invocation";
ok  file_name_is_absolute( $Bin_p ), "\$Bin_p is absolute for 'interactive' invocation";

ok  -d $Bin,                          "\$Bin names an existing directory for 'interactive'";
ok  -d $Bin_l,                        "\$Bin_l names an existing directory for 'interactive'";

is  $Bin_l, $pwd,    "\$Bin_l eq pwd() for 'interactive' invocation";
is  $Bin,   $Bin_p,  "\$Bin eq \$Bin_p for 'interactive' invocation (abspath default)";

done_testing;
__END__
