use Test::More tests => 5;
use Lingua::EN::GeniaTagger;

use strict;
use Data::Dumper;

print STDERR "\nPlease specify the path to geniatagger >> ";
chomp(my $path = <STDIN>);
start_genia($path);
while(<DATA>){
  next unless $_;
  next if /^#/;
  chomp;
  if($_){
    my $result = tag($_);
    ok($result);
#    print $result;
    like($result, qr(CD28\tCD28\tNN\tB-NP));
    my $chunks = chunk($result);
#    print Dumper $chunks;
    is($chunks->[1][0], 'CC');
    is($chunks->[1][1][2], 'CC');
    like(stringify_chunks($result), qr(\Q[NP 5-lipoxygenase/NN NP] [PUNCT ./. PUNCT]\E));
    last;
  }
}

__END__
IL-2 gene expression and NF-kappa B activation through CD28 requires reactive oxygen production by 5-lipoxygenase.
