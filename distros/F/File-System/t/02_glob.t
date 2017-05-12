use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
	use_ok('File::System::Object');
}

my $obj = 'File::System::Object';

my @files = qw/
	a ab abc abcd
	b bc bcd
	c cd
	d
	.a .ab .abc .abcd
	.b .bc .bcd
	.c .cd
	.d
/;

is_deeply([ $obj->match_glob('a', @files) ],           [ qw/ a / ]);
is_deeply([ $obj->match_glob('[abc]', @files) ],       [ qw/ a b c / ]);
is_deeply([ $obj->match_glob('[a-d]', @files) ],       [ qw/ a b c d / ]);
is_deeply([ $obj->match_glob('?', @files) ],           [ qw/ a b c d / ]);
is_deeply([ $obj->match_glob('*', @files) ],           [ qw/ a ab abc abcd b bc bcd c cd d / ]);
is_deeply([ $obj->match_glob('{a,bcd,cd}', @files) ],  [ qw/ a bcd cd / ]);
is_deeply([ $obj->match_glob('.a', @files) ],          [ qw/ .a / ]);
is_deeply([ $obj->match_glob('.[abc]', @files) ],      [ qw/ .a .b .c / ]);
is_deeply([ $obj->match_glob('.[a-d]', @files) ],      [ qw/ .a .b .c .d / ]);
is_deeply([ $obj->match_glob('.?', @files) ],          [ qw/ .a .b .c .d / ]);
is_deeply([ $obj->match_glob('.*', @files) ],          [ qw/ .a .ab .abc .abcd .b .bc .bcd .c .cd .d / ]);
is_deeply([ $obj->match_glob('.{a,bcd,cd}', @files) ], [ qw/ .a .bcd .cd / ]);
is_deeply([ $obj->match_glob('*b*', @files) ],         [ qw/ ab abc abcd b bc bcd / ]);
