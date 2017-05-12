use strict;
use warnings;

my @tests = (
  [  1,  5,   200000],
  [  1, 10,   200000],
  [  2,  5,   200000],
  [ 20,  5,   200000],
  [  2, 10,   200000],
  [ 20, 10,   200000],
  [  2, 50,   100000],
  [ 20, 50,   100000],
  [  5, 20,  1000000],
  [500, 10,   200000],
 );


foreach my $t (@tests) {
  printf "\n%6d records with %2d keys of %2d chars\n", reverse @$t; 
  system "perl benchmark_HT.pl all " . join(" ", @$t);
}

__END__
RESULTS:


200000 records with  5 keys of  1 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  3.323   2.231   1.684   0.156   0.047  132.5MB (perl core hashes)
  4.259   3.760   1.575   0.141   0.078  180.0MB (Hash::Type v2.00)
  2.293   3.151   1.342   5.272   0.110  524.0MB (Hash::Ordered v0.010)
  3.479   3.681   1.451   5.850   0.125  539.8MB (Tie::IxHash v1.23)
  1.779   2.231   1.279   4.914   0.156  508.2MB (Tie::Hash::Indexed v0.05)

200000 records with 10 keys of  1 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  4.181   2.246   0.812   0.062   0.016  132.5MB (perl core hashes)
  2.683   5.366   1.357   0.110   0.078  227.4MB (Hash::Type v2.00)
  3.386   5.740   1.358   5.194   0.110  524.0MB (Hash::Ordered v0.010)
  5.756   7.005   1.451   5.818   0.109  539.8MB (Tie::IxHash v1.23)
  3.167   4.196   1.279   5.258   0.171  508.2MB (Tie::Hash::Indexed v0.05)

200000 records with  5 keys of  2 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  1.451   1.170   0.827   0.078   0.032  132.5MB (perl core hashes)
  2.464   2.902   1.342   0.124   0.047  178.0MB (Hash::Type v2.00)
  2.199   3.120   1.357   5.148   0.109  524.0MB (Hash::Ordered v0.010)
  3.510   3.759   1.467   5.741   0.140  539.8MB (Tie::IxHash v1.23)
  1.794   2.231   1.279   4.976   0.172  508.2MB (Tie::Hash::Indexed v0.05)

200000 records with  5 keys of 20 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  1.482   1.201   0.811   0.078   0.031  132.5MB (perl core hashes)
  1.669   2.933   1.326   0.125   0.063  180.0MB (Hash::Type v2.00)
  2.200   3.120   1.341   5.148   0.109  524.0MB (Hash::Ordered v0.010)
  3.541   3.744   1.498   5.257   0.141  539.8MB (Tie::IxHash v1.23)
  1.826   2.215   1.279   5.164   0.172  506.2MB (Tie::Hash::Indexed v0.05)

200000 records with  5 keys of  2 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  6.193   2.262   1.233   0.125   0.063  164.2MB (perl core hashes)
  2.075   2.948   1.342   0.109   0.047  211.6MB (Hash::Type v2.00)
  2.527   3.182   1.342   6.302   0.187  650.5MB (Hash::Ordered v0.010)
  3.838   3.744   1.466   5.741   0.436  698.0MB (Tie::IxHash v1.23)
  4.695   3.386   1.450   5.757   0.874  698.0MB (Tie::Hash::Indexed v0.05)

200000 records with  5 keys of 20 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  1.435   1.201   0.827   0.094   0.047  164.2MB (perl core hashes)
  1.654   4.508   1.326   0.140   0.062  211.6MB (Hash::Type v2.00)
  2.652   4.805   1.373   8.096   0.375  682.2MB (Hash::Ordered v0.010)
  6.381   9.016   2.793   7.581   0.265  713.8MB (Tie::IxHash v1.23)
  2.402   2.762   1.513   5.195   0.312  713.8MB (Tie::Hash::Indexed v0.05)

200000 records with 10 keys of  2 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  3.853   2.418   0.842   0.078   0.078  225.4MB (perl core hashes)
  2.684   5.756   1.373   0.171   0.078  274.9MB (Hash::Type v2.00)
  4.305   5.991   1.357   5.865   0.608  840.3MB (Hash::Ordered v0.010)
 15.132   8.486   1.576   5.397   0.359  917.3MB (Tie::IxHash v1.23)
  3.713   4.305   1.389   6.131   1.217  966.8MB (Tie::Hash::Indexed v0.05)

200000 records with 10 keys of 20 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  3.963   2.340   0.811   0.109   0.093  227.4MB (perl core hashes)
  2.746   5.694   1.341   0.125   0.078  274.9MB (Hash::Type v2.00)
  4.539   6.131   1.373   5.366   0.312  887.7MB (Hash::Ordered v0.010)
  7.114   9.344   1.560   7.317   1.092  966.8MB (Tie::IxHash v1.23)
  5.740   6.474   1.342   5.039   0.546  998.4MB (Tie::Hash::Indexed v0.05)

100000 records with 50 keys of  2 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  6.349   5.382   0.406   0.062   0.171  384.5MB (perl core hashes)
  5.429  13.384   0.702   0.063   0.110  432.0MB (Hash::Type v2.00)
  9.048  14.211   0.687   1.232   0.577 1180.7MB (Hash::Ordered v0.010)
 14.508  17.113   0.765   1.513   0.702 1354.6MB (Tie::IxHash v1.23)
  7.893  11.997   0.670   1.358   1.107 1542.4MB (Tie::Hash::Indexed v0.05)

100000 records with 50 keys of 20 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  6.677   5.553   0.421   0.078   0.172  384.5MB (perl core hashes)
  5.429  13.291   0.702   0.047   0.093  432.0MB (Hash::Type v2.00)
  9.532  14.523   0.702   1.404   0.624 1259.8MB (Hash::Ordered v0.010)
 14.914  17.846   0.796   1.466   0.873 1433.7MB (Tie::IxHash v1.23)
  8.066  10.405   0.671   1.450   1.108 1623.5MB (Tie::Hash::Indexed v0.05)

1000000 records with 20 keys of  5 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
 26.271  21.871   4.306   0.671   0.749 1388.7MB (perl core hashes)
 23.540  58.812  11.404   1.264   0.827 1671.4MB (Hash::Type v2.00)
 48.859  77.564  18.486 168.621  11.357 5997.5MB (Hash::Ordered v0.010)
 62.478  70.575   7.940 170.353  11.669 6756.5MB (Tie::IxHash v1.23)
 37.705  41.559   6.864 161.040  28.844 7309.9MB (Tie::Hash::Indexed v0.05)

  200000 records with 10 keys of 500 chars
 create  update  access    sort  delete   memory
======= ======= ======= ======= ======= ========
  5.913   3.869   1.201   0.109   0.109  132.5MB (perl core hashes)
  6.193   6.396   1.373   0.125   0.063  209.6MB (Hash::Type v2.00)
  3.447   5.788   1.357   7.847   0.171  524.0MB (Hash::Ordered v0.010)
  7.941   7.581   1.514   5.772   0.109  539.8MB (Tie::IxHash v1.23)
  3.073   4.243   1.279   4.961   0.156  508.2MB (Tie::Hash::Indexed v0.05)
