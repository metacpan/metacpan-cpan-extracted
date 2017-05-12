use Test::More;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use In::Korean::Numbers::SinoKorean;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Source: http://stackoverflow.com/questions/492838/why-do-my-perl-tests-fail-with-use-encoding-utf8
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my %tests = (
  0 => '영',
  1 => '일' ,
  2 => '이' ,
  3 => '삼' ,
  4 => '사' ,
  5 => '오' ,
  6 => '육' ,
  7 => '칠' ,
  8 => '팔' ,
  9 => '구' ,
  10 => '십' ,
  11 => '십일' ,
  12 => '십이' ,
  13 => '십삼' ,
  14 => '십사' ,
  15 => '십오' ,
  16 => '십육' ,
  17 => '십칠' ,
  18 => '십팔' ,
  19 => '십구' ,
  20 => '이십' ,
  21 => '이십일' ,
  22 => '이십이' ,
  23 => '이십삼' ,
  24 => '이십사' ,
  25 => '이십오' ,
  26 => '이십육' ,
  27 => '이십칠' ,
  28 => '이십팔' ,
  29 => '이십구' ,
  30 => '삼십' ,
  31 => '삼십일' ,
  40 => '사십' ,
  41 => '사십일' ,
  50 => '오십' ,
  51 => '오십일' ,
  60 => '육십' ,
  61 => '육십일' ,
  70 => '칠십' ,
  71 => '칠십일' ,
  80 => '팔십' ,
  81 => '팔십일' ,
  90 => '구십' ,
  91 => '구십일' ,
  100 => '백' ,
  1000 => '천' ,
  1111=>'천백십일',
  5231 => '오천이백삼십일',
  11000=>'만천',
  100000=>'십만',
  500000=>'오십만',
  692824=>'육십구만이천팔백이십사',
);

my $test_count = 4 + 4 * scalar keys %tests;
plan tests => $test_count;

my $sk = In::Korean::Numbers::SinoKorean->new;

for my $int ( keys %tests ) {
  
  my $hangul = $tests{ $int };

  is( $sk->getHangul( $int ), $hangul, 'Testing object-oriented: ' . $int . ' => ' . $hangul );

  is( In::Korean::Numbers::SinoKorean::getHangul( $int ), $hangul, 'Testing procedural: ' . $int . ' => ' . $hangul );

  is( $sk->getInt( $hangul ), $int, 'Testing object-oriented: ' . $hangul . ' => ' . $int );

  is( In::Korean::Numbers::SinoKorean::getInt( $hangul ), $int, 'Testing procedural: ' . $hangul . ' => ' . $int );
}

# Silently ignore too many args
is( $sk->getHangul( 1, 2 ), '일', 'Should ignore exessive arguments.' );

# Undef if no args
is( $sk->getHangul(), undef, 'Should be undefined if no arguments.' );

# Undef if not positive integer
is( $sk->getHangul( -1), undef, 'Should be undefined if negative argument.' );
is( $sk->getHangul( 1.5), undef, 'Should be undefined if not an integer.' );

done_testing();
