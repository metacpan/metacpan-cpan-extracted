use Dios;
use Test::More;

plan tests => 17;

my $NAME  = 'Damian';
my @NUMS  = (1,2,3);
my %COUNT = ( a=>1.1, b=>-2 );

my $NEWNAME  = 'Conway';
my @NEWNUMS  = (4,5,6);
my %NEWCOUNT = ( a=>0, c=>99 );

my $BADNAME  = '';
my @BADNUMS  = (44,55,66);
my %BADCOUNT = ( a=>[], c=>'cat' );

lex Str $name where { length > 0 } = $NAME;
lex Int @nums where { $_ < 10 }    = @NUMS;
lex Num %count                     = %COUNT;

is         $name,   $NAME,  'Initialization of $name';
is_deeply \@nums,  \@NUMS,  'Initialization of @nums';
is_deeply \%count, \%COUNT, 'Initialization of %count';

ok eval { $name  = $NEWNAME;  1 }, 'Assignment to $name';
ok eval { @nums  = @NEWNUMS;  1 }, 'Assignment to @nums';
ok eval { %count = %NEWCOUNT; 1 }, 'Assignment to %count';

is         $name,   $NEWNAME,  'Correct values assigned to $name';
is_deeply \@nums,  \@NEWNUMS,  'Correct values assigned to @nums';
is_deeply \%count, \%NEWCOUNT, 'Correct values assigned to %count';

ok eval { $nums[3]  = $NEWNUMS[0];  1 }, 'Assignment to @nums elem';
is $nums[3],  $NEWNUMS[0],  'Correct value assigned to @nums elem';

ok eval { $count{z} = $NEWCOUNT{c}; 1 }, 'Assignment to %count entry';
is $count{z}, $NEWCOUNT{c}, 'Correct value assigned to %count entry';

eval{ ok !eval { $name  = $BADNAME;  1 }, 'Invalid assignment to $name'; };
eval{ ok !eval { @nums  = @BADNUMS;  1 }, 'Invalid assignment to @nums'; };
eval{ ok !eval { $nums[0]  = 9; $nums[0]++; 1 }, 'Invalid increment to $nums[0]'; };
eval{ ok !eval { %count = %BADCOUNT; 1 }, 'Invalid assignment to %count'; };

done_testing();
