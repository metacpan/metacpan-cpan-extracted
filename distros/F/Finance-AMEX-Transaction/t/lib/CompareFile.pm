package t::lib::CompareFile;

use strict;
use warnings;

use Test::More;
use JSON ();


sub compare {
  my ($type, $file, $data, $counts) = @_;

  my $obj = Finance::AMEX::Transaction->new(file_type => $type);

  open my $fh, '<', $file or die "cannot open test file: $!";

  my $tests = JSON->new->utf8->decode($data);

  while (my $line = $obj->getline($fh)) {

    my $type = $line->type;
    if (exists $counts->{$type}) {

      my $have = $counts->{$type}->{have};
      my $answers = $tests->{$type}->[$have];

      foreach my $k (keys %{$line->field_map}) {
        is ($line->$k, $answers->{$k}, $type .' '. $have .': '. $k);
      }

      $counts->{$line->type}->{have}++;

    } else {
      fail("unknown line type: $type");
    }
  }

  foreach my $type (keys %{$counts}) {
    is ($counts->{$type}->{have}, $counts->{$type}->{want}, 'We saw the expected amount of '. $type .' records');
  }

  close $fh;

}






1;
