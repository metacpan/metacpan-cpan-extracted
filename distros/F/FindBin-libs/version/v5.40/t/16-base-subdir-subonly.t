package Testophile;

use v5.8;

use FindBin::Bin qw( $Bin );

use File::Spec::Functions  qw( catpath );

use FindBin::libs qw( base=lib subdir=FindBin subonly );

use Test::More;

my $expect  = catpath '' => qw( lib FindBin );

ok $INC[0] =~ /\Q$expect\E $/x, "$INC[0] ($expect)";

done_testing;
__END__
