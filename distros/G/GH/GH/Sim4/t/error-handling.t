# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use Data::Dumper;

my $result;
my $cDNA;
my $genomic;
my $got_warning;

BEGIN { plan(tests => 5);
	$SIG{'__WARN__'} = sub {$got_warning = $_[0]};
      };
use GH::Sim4 qw/sim4/;
print "# check that the library loads correctly.\n";
ok(1); # If we made it this far, we're ok.


#########################
#
# third pass test, see if error handling works.
#
print "#################\n# Error handling\n#\n";

$cDNA = "wxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyz";
$genomic = <<EOG;
pdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdq
rpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqr
EOG
$genomic =~ s/\n//g;

print "# test that RaiseError throws an exception\n";
undef $result;
eval {$result = sim4($genomic, $cDNA, {"RaiseError" => 1})};
ok(defined($@));
ok($@ =~ m|^The genomic sequence is not a DNA sequence.|);

# This test depends on the SIG{'__WARNING__') handler installed in BEGIN
print "#\n";
print "# test that PrintError calls a warn\n";
undef $result;
$got_warning = undef;
$result = sim4($genomic, $cDNA, {"PrintError" => 1});
ok(defined($got_warning));
ok($got_warning =~ m|^The genomic sequence is not a DNA sequence.|);

#########################
#
# Done.
#

exit(0);

sub slurp {
  my($filename) = @_;
  my($oldSlash);
  my($name);
  my($sequence);

  open SLURP, "<$filename" || die "Unable to open $filename.";

  $name = <SLURP>;
  $oldSlash = $/;
  undef $/;
  $seq = <SLURP>;
  $seq =~ s/\n//g;

  $/ = $oldSlash;
  close SLURP;

  return($seq);
}
