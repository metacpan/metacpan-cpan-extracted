package t::lib::CompareFile;

use strict;
use warnings;

use Test::More;
use JSON ();
use Carp 'croak';

sub compare {
  my ($type, $file, $data, $counts) = @_;

  my $obj = Finance::AMEX::Transaction->new(file_type => $type);

  my $tests = JSON->new->utf8->decode($data);

  open my $fh, '<', $file or croak "cannot open test file: $!";

  while (my $line = $obj->getline($fh)) {

    my $line_type = $line->type;
    if (exists $counts->{$line_type}) {

      my $have    = $counts->{$line_type}->{have};
      my $answers = $tests->{$line_type}->[$have];

      my $map = $line->field_map;

      if (ref($map) eq 'HASH') {
        foreach my $k (keys %{$map}) {
          is($line->$k, $answers->{$k}, sprintf('%s %s: %s', $line_type, $have, $k));
        }
      } elsif (ref($map) eq 'ARRAY') {
        foreach my $column (@{$map}) {
          my ($k) = keys %{$column};
          if ($line->can($k)) {
            is($line->$k, $answers->{$k}, sprintf('%s %s: %s', $line_type, $have, $k));
          }
        }
      } else {
        fail "field_map returned an unknown type for file_type => $line_type";
      }

      $counts->{$line->type}->{have}++;

    } else {
      fail("unknown line type: $line_type");
    }
  }

  close $fh or croak "unable to close: $!";

  foreach my $line_type (keys %{$counts}) {
    is(
      $counts->{$line_type}->{have},
      $counts->{$line_type}->{want},
      sprintf('We saw the expected amount of %s records', $line_type),
    );
  }

  return $obj;
}

sub slurp {
  my ($file) = @_;

  open my $fh, '<', $file or croak "cannot open test file: $!";
  local $/ = undef;
  my $data = <$fh>;
  close $fh or croak "unable to close: $!";

  return $data;
}

1;
