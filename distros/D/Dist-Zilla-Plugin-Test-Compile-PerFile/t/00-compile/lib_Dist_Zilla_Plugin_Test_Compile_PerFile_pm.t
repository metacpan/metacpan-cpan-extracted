# This test was generated for <lib/Dist/Zilla/Plugin/Test/Compile/PerFile.pm>
# using by Dist::Zilla::Plugin::Test::Compile::PerFile ( @Author::KENTNL/Test::Compile::PerFile ) version 0.003903
# with template 02-raw-require.t.tpl
my $file = "Dist/Zilla/Plugin/Test/Compile/PerFile.pm";
my $err;
{
  local $@;
  eval { require $file; 1 } or $err = $@;
};

if( not defined $err ) {
  print "1..1\nok 1 - require ${file}\n";
  exit 0;
}
print "1..1\nnot ok 1 - require ${file}\n";
print STDERR "# ${_}\n" for split /\n/, $err;
exit 1;
