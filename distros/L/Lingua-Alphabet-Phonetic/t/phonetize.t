# Emacs, please use -*- cperl -*- mode when editing this file

use File::Spec::Functions;
use ExtUtils::testlib;
use Test::More qw(no_plan);
# use Test::More tests => 13;

use strict;

my $sProg = catfile('blib', 'script', 'phonetize');
my $iWIN32 = ($^O =~ m!win32!i);

ok(-s $sProg, "$sProg exists");
ok(-f $sProg, "$sProg is a plain file");
SKIP:
  {
  skip 'Can not check "executable" file flag on Win32', 1 if $iWIN32;
  ok(-x $sProg, "$sProg is executable");
  } # end of SKIP block
# Now actually try running it:
my $sExpect = <<EXPECT1;
Mike Alpha Romeo
Tango India November
EXPECT1
my $sActual = `$sProg Martin`;
$sActual =~ s![\r\n]+!\n!g;
$sExpect =~ s![\r\n]+!\n!g;
is($sActual, $sExpect, 'output of `phonetize Martin`');

exit 0;

__END__

