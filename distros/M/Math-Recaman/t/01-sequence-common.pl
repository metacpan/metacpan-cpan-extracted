#!perl

my @sequence = @Math::Recaman::checks;
my $size = scalar(@sequence);

plan tests => $size+2;

Math::Recaman::recaman($size, sub {
  my $got      = shift;
  my $count    = shift;
  my $expected = shift @sequence;
  is($got, $expected, "Number $count of the sequence is $expected");
});

is(scalar(@sequence), 0, "We exhausted our list");