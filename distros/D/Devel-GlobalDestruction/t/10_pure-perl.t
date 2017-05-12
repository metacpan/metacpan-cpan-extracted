use strict;
use warnings;
use FindBin qw($Bin);
use Config;
use IPC::Open2;

# rerun the tests under the assumption of pure-perl

# for the $^X-es
$ENV{PERL5LIB} = join ($Config{path_sep}, @INC);
$ENV{DEVEL_GLOBALDESTRUCTION_PP_TEST} = 1;

my $this_file = quotemeta(__FILE__);

opendir(my $dh, $Bin);
my @tests = grep { $_ !~ /${this_file}$/ } map { "$Bin/$_" } grep { /\.t$/ } readdir $dh;
print "1..@{[ scalar @tests ]}\n";

my $had_error = 0;
END { $? = $had_error }
sub ok ($$) {
  $had_error++, print "not " if !$_[0];
  print "ok";
  print " - $_[1]" if defined $_[1];
  print "\n";
}

for my $fn (@tests) {
  # this is cheating, and may even hang here and there (testing on windows passed fine)
  # if it does - will have to fix it somehow (really *REALLY* don't want to pull
  # in IPC::Cmd just for a fucking test)
  # the alternative would be to have an ENV check in each test to force a subtest
  open2(my $out, my $in, $^X, $fn );
  while (my $ln = <$out>) {
    print "   $ln";
  }

  wait;
  ok (! $?, "Exit $? from: $^X $fn");
}
