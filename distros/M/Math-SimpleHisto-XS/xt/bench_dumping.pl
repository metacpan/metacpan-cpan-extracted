use strict;
use warnings;
use Test::More tests => 1;
pass(); # Just in case somebody wants to run this through some TAP thingy

use Math::SimpleHisto::XS;
use Benchmark qw(:hireswallclock timethis cmpthese);

my @histos;

my $data = [map 123+rand(890-123), 0..19999];
my $weight = [map 123+rand(890-123), 0..19999];

my $hist_small = Math::SimpleHisto::XS->new(min => 123, max => 890, nbins => 10);
$hist_small->fill($data, $weight);

my $hist_med = Math::SimpleHisto::XS->new(min => 123, max => 890, nbins => 100);
$hist_med->fill($data, $weight);

my $hist_large = Math::SimpleHisto::XS->new(min => 123, max => 890, nbins => 10000);
$hist_large->fill($data, $weight);

if (defined $Math::SimpleHisto::XS::JSON_Implementation
    and eval "require YAML::Tiny; 1;")
{
  diag($Math::SimpleHisto::XS::JSON_Implementation);

  foreach my $hist_test (
    ['small', $hist_small],
    ['med', $hist_med],
    ['large', $hist_large],
  ) {
    my ($name, $hist) = @$hist_test;

    my $dump_simple      = $hist->dump('simple');
    my $dump_json        = $hist->dump('json');
    my $dump_yaml        = $hist->dump('yaml');
    my $dump_native_pack = $hist->dump('native_pack');
    printf(
      "Dump sizes:\n" . ("  %11s: %20u\n" x 4),
      'simple', length($dump_simple),
      'JSON', length($dump_json),
      'YAML', length($dump_yaml),
      'native_pack', length($dump_native_pack)
    );

    my %dump_tests;
    my %undump_tests;
    my %dumpundump_tests;
    foreach my $type (qw(simple json yaml native_pack)) {
      my $dumpcode = qq{my \$dump_$type = \$hist->dump('$type');};
      my $dumpsub  = eval "sub {$dumpcode}";
      
      my $undumpcode = qq{my \$obj = Math::SimpleHisto::XS->new_from_dump('$type', \$dump_$type);};
      my $undumpsub  = eval "sub {$undumpcode}";
      my $dump_undumpsub  = eval "sub {$dumpcode; $undumpcode}";

      $dump_tests{"dump_${name}_$type"} = $dumpsub;
      $undump_tests{"undump_${name}_$type"} = $undumpsub;
      $dumpundump_tests{"dump_undump_${name}_$type"} = $dump_undumpsub;
    }
    cmpthese(-1, \%dump_tests);
    print "\n";
    cmpthese(-1, \%undump_tests);
    print "\n";
    cmpthese(-1, \%dumpundump_tests);
    print "\n";
  } # foreach hist_test
} # if have JSON and YAML


