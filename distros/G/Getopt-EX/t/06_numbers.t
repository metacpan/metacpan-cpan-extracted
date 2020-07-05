use strict;
use warnings;
use Test::More;
use Data::Dumper;

use Getopt::EX::Numbers;

my $obj;
sub call {
    my($method, $spec, $expected, $comment) = @_;
    my $result = [ $obj->parse($spec)->$method ];
    is_deeply($result, $expected, $comment // "$method $spec");
}
sub spec { call 'range', @_ }
sub seq  { call 'sequence', @_ }

$obj = new Getopt::EX::Numbers max => 10;
spec '1' => [ [1,1] ];
spec '1:2' => [ [1,2] ];
spec ':10' => [ [0,10] ];
spec ':20' => [ [0,10] ];
spec ':10:3' => [ [0,0], [3,3], [6,6], [9,9] ];
spec ':10:3:2' => [ [0,1], [3,4], [6,7], [9,10] ];
seq  ':10:3:2' => [  0,1 ,  3,4 ,  6,7 ,  9,10  ];
seq  ':10::2'  => [  0..10 ];

seq  '::' => [0..10];
seq  '::2' => [0,2,4,6,8,10];
seq  '1::2' => [1,3,5,7,9];

$obj = new Getopt::EX::Numbers min => 1, max => 10;
spec '1'   => [ [1,1] ];
spec '1:2' => [ [1,2] ];
spec ':10' => [ [1,10] ];
spec ':20' => [ [1,10] ];
spec ':10:3'    => [ [1,1], [4,4], [7,7], [10,10] ];
spec ':10:3:2'  => [ [1,2], [4,5], [7,8], [10,10] ];
seq  ':10:3:2'  => [  1,2 ,  4,5 ,  7,8 ,  10     ];
spec '1:10:3'   => [ [1,1], [4,4], [7,7], [10,10] ];
spec '1:10:3:2' => [ [1,2], [4,5], [7,8], [10,10] ];
seq  '1:10:3:2' => [  1,2 ,  4,5 ,  7,8 ,  10     ];

seq  '::' => [1..10];
seq  '::2' => [1,3,5,7,9];
seq  '2::2' => [2,4,6,8,10];

seq  '-5:' => [5..10];
seq  ':-5' => [1..5];
seq  '-8:-2' => [2..8];
seq  ':+5' => [1..6];

is_deeply( [ Getopt::EX::Numbers->new->parse("1:10:3:2")->sequence ],
	   [  1,2 ,  4,5 ,  7,8 ,  10,11 ],
	   "direct" );

is_deeply( [ Getopt::EX::Numbers->new(
		start => 1, end => 10, step=> 3, length => 2
	     )->sequence ],
	   [  1,2 ,  4,5 ,  7,8 ,  10,11 ],
	   "skip parse" );

is_deeply( [ Getopt::EX::Numbers->new(
		 min => 1, max => 10, start => 1, end => 1
	     )->parse("1")->range ],
	   [  [1,1] ],
	   "skip parse -> range" );

is_deeply( [ Getopt::EX::Numbers->new(
		 min => 1, max => 10, start => 1, end => 1
	     )->parse("1:10:3:2")->sequence ],
	   [  1,2 ,  4,5 ,  7,8 ,  10 ],
	   "skip parse -> sequence" );

done_testing;

1;
