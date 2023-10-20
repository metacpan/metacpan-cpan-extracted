use strict;
use warnings;
use Math::Int113;
use Test::More;

eval {require Math::GMPz;};

if($@) {
  warn "$@";
  plan skip_all => "No Math::GMPz";
  done_testing();
  exit 0;
}

for(1..100) {
  my $add = 1 + int(rand(2000));
  my $mul = 2 + int(rand(2 ** 32));

  my $div = (~0) + $add;
  my $num = (~0) * $mul;
  my $zmod = (Math::GMPz->new(~0) * $mul) % (Math::GMPz->new(~0) + $add);

  my $mod = $num % $div;
  my $msg = sprintf("%.36g %% %.36g == %.36g", $num, $div, $mod);
  cmp_ok($mod, '==', $zmod, "1: $msg");

  my $mdiv = Math::Int113->new($div);
  $mod = $num % $mdiv;
  $msg = sprintf("%.36g %% %s == %s", $num, $mdiv, $mod);
  cmp_ok("$mod", 'eq', "$zmod", "2: $msg");

  my $mnum = Math::Int113->new($num);
  $mod = $mnum % $div;
  $msg = sprintf("%s %% %.36g == %s", $num, $mdiv, $mod);
  cmp_ok("$mod", 'eq', "$zmod", "3: $msg");

  $mod = $mnum % $mdiv;
  $msg = sprintf("%s %% %s == %s", $num, $mdiv, $mod);
  cmp_ok("$mod", 'eq', "$zmod", "4: $msg");
}

done_testing();
