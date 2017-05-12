use strict;
use warnings;

use Test::More;
BEGIN { plan tests => 20 };

use FindBin qw( $Bin );

use Config;
my $perl = $Config{perlpath};

my $out;

sub run {
  $_ = `$perl @_`;
  !$?
}

sub check_deps {
  m[Data/Dumper.pm] && m[overload.pm]
}

sub check_time {
  m[Time spent loading modules]
}

sub check_bias {
  m[\(including the time I spent loading Time::HiRes\)]
}

sub check_origin {
  m[$INC{'Data/Dumper.pm'}]
}

ok run "-I$Bin -I$Bin/lib -MDevel::Dependencies -MFoo -e 0";
ok !$?;
ok !!m[Foo\.pm$]m;
ok !!m[Bar\.pm$]m;

ok run "-I$Bin -I$Bin/lib -MDevel::Dependencies=origin -MFoo -e 0";
ok !$?;
ok !!m[$Bin/Foo\.pm$]m;
ok !!m[$Bin/lib/Foo/Bar\.pm$]m;

ok run "-I$Bin -I$Bin/lib -MDevel::Dependencies=distance -MFoo -e 0";
ok !$?;
ok !!m[Foo\.pm \(1\)$]m;
ok !!m[Bar\.pm \(2\)$]m;

ok run "-I$Bin -I$Bin/lib -MDevel::Dependencies=time -MFoo -e 0";
ok !$?;
ok !!m[Time spent loading modules];
ok !!m[\(including the time I spent loading Time::HiRes\)];

ok run "-I$Bin -I$Bin/lib -MDevel::Dependencies=time -MTime::HiRes -MFoo -e 0";
ok !$?;
ok !!m[Time spent loading modules];
ok !m[\(including the time I spent loading Time::HiRes\)];
