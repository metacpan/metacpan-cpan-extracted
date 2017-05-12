use Inline 'SLang' => <<'EOS';
variable runtime = time();
typedef struct { x, time } xTime_Struct;
define ret1(x) {
  variable y = struct { x, time };
  y.x    = x;
  y.time = runtime;
  return y;
}
define ret2(x) {
  variable y = @xTime_Struct;
  y.x    = x;
  y.time = runtime;
  return y;
}
EOS

# first with a normal structure
my $s1 = ret1( "struct example" );
print  "ret1() returned a $s1\n";
printf "Is it a structure? [%d]\n", $s1->is_struct_type;
printf "With keys/fields [ %s ]\n",
  join( ", ", keys(%$s1) );
print  " s.x    = $$s1{x}\n";
print  " s.time = $$s1{time}\n";

# and then with a "named" structure
my $s2 = ret2( "named struct example" );
print  "ret2() returned a $s2\n";
printf "Is it a structure? [%d]\n", $s2->is_struct_type;
  printf "With keys/fields [ %s ]\n",
  join( ", ", keys(%$s2) );
print  " s.x    = $$s2{x}\n";
print  " s.time = $$s2{time}\n";

