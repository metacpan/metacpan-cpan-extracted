# This test was generated for <{{$file}}>
# using by {{ $plugin_module }} ( {{ $plugin_name }} ) version {{ $plugin_version }}
# with template 02-raw-require.t.tpl
my $file = {{ quoted($relpath) }};
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
