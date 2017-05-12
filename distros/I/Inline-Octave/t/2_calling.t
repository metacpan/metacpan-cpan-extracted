use strict;
use Test;
 
BEGIN {
           plan(tests => 2) ;
}
         
use Inline Octave => q{
   function x=jnk1(u); x=u+1; endfunction
   function x=jnk2(u); x=1./u; endfunction
   function x=jnk3(u); x=str2num(u); endfunction
};   

my $v= jnk1(3)->disp();
chomp ($v);
ok( $v, " 4" );

# jnk2 gives warning if u=0
do {
  local $SIG{__WARN__} = sub {
     my $ok = ($_[0] =~ /division by zero/);
     ok( $ok, 1);
  };

  $v= jnk2(0)->disp();
};

do {
  local $SIG{__DIE__} = sub {
     print STDERR "boo $_[0]";
     my $ok = ($_[0] =~ /Invalid call to str2num/);
     ok( $ok, 1);
  };

#  jnk3(1234);
# This often blocks for some bizarre reason, need to look into why. 
# For now, it's now too bad, since these errors will kill the process
};
