#_ Exports_____________________________________________________________
# Test exports    
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

package Math::Zap::Zzz;
$VERSION=1.07;

sub aaa {'hello from aaa'};
sub bbb {'hello from bbb'};

use Math::Zap::Exports qw(
  aaa ()
  bbb ()
);

1;

package Math::Zap::Main;
$VERSION=1.07;

Math::Zap::Zzz::import(qw(zzz aaa -a bbb -b));
use Test::Simple tests=>2;

ok(a() eq 'hello from aaa');
ok(b() eq 'hello from bbb');

