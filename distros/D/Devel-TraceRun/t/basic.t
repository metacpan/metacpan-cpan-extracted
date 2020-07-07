use Test::More;
use File::Spec::Functions;

my $tdir = catdir qw(t lib);
my $tfile = catfile qw(t scr.pl);
my $first_ret = $] < 5.016000 ? 'undef' : '';
my $initial = $] < 5.028000 ? '' : <<EOF;
main::($tfile:0)(Devel::Tra)
return()
EOF
my $first_block = $] < 5.028000 ? '' : <<EOF;
  main::($tfile:1)(Thing)
  return($first_ret)
EOF

my $expected = <<EOF;
${initial}main::($tfile:1)()
${first_block}return($first_ret)
Thing::func(ARRAY)
  Thing::func2()
  return()
return()
Thing::func(ARRAY)
  Thing::func2()
  return(2nd retval)
return(2nd retval)
main entry(very long ,2,Thing)
  Thing::func()
    Thing::func2()
    return(2nd retval)
  return(2nd retval)
return(2nd retval)
EOF

is scalar qx{"$^X" -d -d:TraceRun -I$tdir $tfile}, $expected;

done_testing;
