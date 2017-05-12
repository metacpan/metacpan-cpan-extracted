use Test;
BEGIN { plan tests => 9 };
use File::FnMatch ':fnmatch';
ok(1); # If we made it this far, we are ok.

ok(defined &fnmatch, 1, "fnmatch imported");
my @const = grep { /^FNM_/ } keys %{__PACKAGE__ . '::'};
ok(@const > 0, 1, "FNM_* constants imported");

ok(fnmatch("*log", "/var/log"));
unless (defined &FNM_PATHNAME) {
  skip("No FNM_PATHNAME", !fnmatch("*log", "/var/log", FNM_PATHNAME));
  skip("No FNM_PATHNAME", fnmatch("/*/*log", "/var/log", FNM_PATHNAME));
} else {
  ok(!fnmatch("*log", "/var/log", FNM_PATHNAME));
  ok(fnmatch("/*/*log", "/var/log", FNM_PATHNAME));
}

unless (defined &FNM_PATHNAME and defined &FNM_PERIOD) {
  skip("No FNM_PATHNAME|FNM_PERIOD", fnmatch("/a/*", "/a/bc", $flags));
  skip("No FNM_PATHNAME|FNM_PERIOD", !fnmatch("/a/*", "/a/.bc", $flags));
  skip("No FNM_PATHNAME|FNM_PERIOD", !fnmatch("/a/*", "/a/b/c", $flags));
} else {
  my $flags = FNM_PATHNAME|FNM_PERIOD;
  ok(fnmatch("/a/*", "/a/bc", $flags));
  ok(!fnmatch("/a/*", "/a/.bc", $flags));
  ok(!fnmatch("/a/*", "/a/b/c", $flags));
}
