package Testophile;

use v5.8;

use FindBin qw( $Bin );

use File::Spec::Functions  qw( catpath );

use FindBin::libs qw( base=lib subdir=FindBin subonly );

use Test::More tests => 1;

my $expect  = catpath '' => qw( lib FindBin );

ok $INC[0] =~ /\Q$expect\E $/x, "$INC[0] ($expect)";

__END__
