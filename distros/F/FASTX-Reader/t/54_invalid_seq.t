use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;


use_ok 'FASTX::Seq';

## EMPTY SEQUENCE WITH NAME
my $empty = FASTX::Seq->new("", "seq1", undef);
ok(length($empty->{seq})==0, "[OBJ] Empty sequence is fine: no sequence");
ok(length($empty->{name})>0, "[OBJ] Empty sequence is fine: has name");

## SEQUENCE WITH NO ATTRIBUTES: NOT VALID
eval {
    my $badseq = FASTX::Seq->new();
};

ok($@, "[OBJ/FAIL] Got error on sequence without any attribute:\n" . format_error($@));

eval {
    my $badseq = FASTX::Seq->new("", undef, undef, "I");
};

ok($@, "[OBJ/FAIL] Empty sequence cannot have a quality that is not empty:\n"  . format_error($@));
done_testing();

sub format_error {
  my $result = '';
  my $prefix = '>  ';
  for my $string (@_) {
    $string =~s/\n/\n$prefix/s;
    $result .= $prefix . $string;
  }
  return $result;
}