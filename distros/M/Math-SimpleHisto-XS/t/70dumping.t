use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Math::SimpleHisto::XS') };

use lib 't/lib', 'lib';
use Test_Functions;

my $h = Math::SimpleHisto::XS->new(nbins => 23, min => 13.1, max => 99.2);
$h->fill(20.11, 12.4);
$h->fill(29.31, 123);
$h->fill(59., 59.);
$h->fill(32.91, 9,);
$h->fill(89.01, -2);
$h->fill(99.01, 1000);
$h->fill(59.01, -5);
$h->set_overflow(12.);
$h->set_underflow(1.);

my $h_var = Math::SimpleHisto::XS->new(bins => [132., 133., 139, 141.1, 150.9, 200.]);
$h_var->fill(133.11, 12.4);
$h_var->fill(199.31, 123);
$h_var->fill(151, 59.);
$h_var->fill(140, 9,);
$h_var->fill(89, -2);
$h_var->fill(100000, 1000);
$h_var->fill(151, -5);
$h_var->set_overflow(12.);
$h_var->set_underflow(1.);

my @test_histos = (
  [$h, 'constant bins'],
  [$h_var, 'variable bins'],
);
# simple dump
test_dump_undump($_->[0], 'simple', $_->[1]) for @test_histos;

# native_pack
test_dump_undump($_->[0], 'native_pack', $_->[1]) for @test_histos;

# Storable
SKIP: {
  if (not eval "require Storable; 1;") {
    diag("Could not load Storable, not testing Storable related features");
    last SKIP;
  }
  foreach my $test_histo (@test_histos) {
    my ($h, $name) = @$test_histo;
    my $cloned = Storable::thaw(Storable::nfreeze($h));
    isa_ok($cloned, 'Math::SimpleHisto::XS');
    histo_eq($h, $cloned, "Storable thaw(nfreeze()) ($name)");
    $cloned = Storable::dclone($h);
    isa_ok($cloned, 'Math::SimpleHisto::XS');
    histo_eq($h, $cloned, "Storable dclone ($name)");
  }
}

# JSON
SKIP: {
  if (not defined $Math::SimpleHisto::XS::JSON) {
    diag("Could not load JSON support module, not testing JSON related features");
    last SKIP;
  }
  diag("Using $Math::SimpleHisto::XS::JSON_Implementation for testing JSON support");
  test_dump_undump($_->[0], 'json', $_->[1]) for @test_histos;
}

# YAML
SKIP: {
  if (not eval "require YAML::Tiny; 1;") {
    diag("Could not load YAML::Tiny, not testing YAML::Tiny related features");
    last SKIP;
  }
  test_dump_undump($_->[0], 'yaml', $_->[1]) for @test_histos;
}

if (grep {/^--print-dumps$/} @ARGV) {
  open my $fh, ">", "dumps.$Math::SimpleHisto::XS::VERSION.txt"
    or die $!;
  binmode $fh;
  foreach my $dump_type (qw(simple native_pack json yaml)) {
    print $fh $dump_type, ':', $h->dump($dump_type), "\n\n";
  }
  close $fh;
}

done_testing();

sub test_dump_undump {
  my $histo = shift;
  my $type = shift;
  my $name = shift;

  my $dump = $histo->dump($type);
  ok(defined($dump), "'$type' dump is defined ($name)");

  my $clone = Math::SimpleHisto::XS->new_from_dump($type, $dump);
  isa_ok($clone, 'Math::SimpleHisto::XS');
  histo_eq($histo, $clone, "'$type' histo dump is same as original ($name)");
}

