#!/usr/bin/perl
use strict;
use warnings;
use GPS::OID;

=head1 NAME

example.pl - GPS::OID simple example

=cut

my $obj = GPS::OID->new;
foreach ($obj->listprn) {
  print "PRN: $_ => OID: ", $obj->oid_prn($_)||'', "\n";
}
foreach ($obj->listoid) {
  print "OID: $_ => PRN: ", $obj->prn_oid($_)||'', "\n";
}

__END__

=head1 SAMPLE OUTPUT

  PRN: 01 => OID: 22231
  PRN: 02 => OID: 28474
  PRN: 03 => OID: 23833
  PRN: 04 => OID: 22877
  PRN: 05 => OID: 22779
  PRN: 06 => OID: 23027
  PRN: 07 => OID: 22657
  PRN: 08 => OID: 25030
  PRN: 09 => OID: 22700
  PRN: 10 => OID: 23953
  PRN: 11 => OID: 25933
  PRN: 12 => OID: 29601
  PRN: 13 => OID: 24876
  PRN: 14 => OID: 26605
  PRN: 15 => OID: 20830
  PRN: 16 => OID: 27663
  PRN: 17 => OID: 28874
  PRN: 18 => OID: 26690
  PRN: 19 => OID: 28190
  PRN: 20 => OID: 26360
  PRN: 21 => OID: 27704
  PRN: 22 => OID: 28129
  PRN: 23 => OID: 28361
  PRN: 24 => OID: 21552
  PRN: 25 => OID: 21890
  PRN: 26 => OID: 22014
  PRN: 27 => OID: 22108
  PRN: 28 => OID: 26407
  PRN: 29 => OID: 22275
  PRN: 30 => OID: 24320
  PRN: 31 => OID: 29486
  PRN: 120 => OID: 24307
  PRN: 121 => OID: 28899
  PRN: 122 => OID: 24819
  PRN: 124 => OID: 26863
  PRN: 126 => OID: 25153
  PRN: 129 => OID: 28622
  PRN: 134 => OID: 24674
  PRN: 135 => OID: 28884
  PRN: 137 => OID: 28937
  PRN: 138 => OID: 28868
  OID: 20830 => PRN: 15
  OID: 21552 => PRN: 24
  OID: 21890 => PRN: 25
  OID: 22014 => PRN: 26
  OID: 22108 => PRN: 27
  OID: 22231 => PRN: 01
  OID: 22275 => PRN: 29
  OID: 22657 => PRN: 07
  OID: 22700 => PRN: 09
  OID: 22779 => PRN: 05
  OID: 22877 => PRN: 04
  OID: 23027 => PRN: 06
  OID: 23833 => PRN: 03
  OID: 23953 => PRN: 10
  OID: 24307 => PRN: 120
  OID: 24320 => PRN: 30
  OID: 24674 => PRN: 134
  OID: 24819 => PRN: 122
  OID: 24876 => PRN: 13
  OID: 25030 => PRN: 08
  OID: 25153 => PRN: 126
  OID: 25933 => PRN: 11
  OID: 26360 => PRN: 20
  OID: 26407 => PRN: 28
  OID: 26605 => PRN: 14
  OID: 26690 => PRN: 18
  OID: 26863 => PRN: 124
  OID: 27663 => PRN: 16
  OID: 27704 => PRN: 21
  OID: 28129 => PRN: 22
  OID: 28190 => PRN: 19
  OID: 28361 => PRN: 23
  OID: 28474 => PRN: 02
  OID: 28622 => PRN: 129
  OID: 28868 => PRN: 138
  OID: 28874 => PRN: 17
  OID: 28884 => PRN: 135
  OID: 28899 => PRN: 121
  OID: 28937 => PRN: 137
  OID: 29486 => PRN: 31
  OID: 29601 => PRN: 12

=cut
