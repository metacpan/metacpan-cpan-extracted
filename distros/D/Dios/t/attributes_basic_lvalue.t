use Test::More;
BEGIN {
    eval { require Want; 1 }
        or plan skip_all => "lvalue accessors require the Want module (which could not be loaded)";
}

use Dios { accessors => 'lval' };

plan tests => 25;

my $NAME  = 'Damian';
my @NUMS  = (1,2,3);
my %COUNT = ( a=>1.1, b=>-2 );

my $NEWNAME  = 'Conway';
my @NEWNUMS  = (4,5,6);
my %NEWCOUNT = ( a=>0, c=>99 );

class Base1 {
    method basic { return 'basic' }
}

class Base2 {
    method more_basic { return 'more basic' }
}

class Demo is Base1 is Base2 {
    has Str $.name  is req;
    has Int @.nums  is req;
    has Num %.count is req;

    method change_name ($this: Str $newname, Int|Undef :$other) {
        ::is $name, $NAME => 'Name correct';

        $name = $NEWNAME;
        ::is $this->name, $NEWNAME => 'Assignment to name correct';

        return 1;
    }

    method change_others () {
        ::is_deeply \@nums, \@NUMS => 'Nums correct';

        @nums = @NEWNUMS;
        ::is_deeply $self->nums, \@NEWNUMS => 'Assignment to nums correct';


        ::is_deeply \%count, \%COUNT => 'Nums correct';

        %count = %NEWCOUNT;
        ::is_deeply $self->count, \%NEWCOUNT => 'Assignment to nums correct';

        return 1;
    }
}

::ok !eval { Demo->new({ count => \%COUNT, nums => \@NUMS   }); } => 'Missing required name';
::like $@, qr/mandatory/ => '...with correct error message';
::ok !eval { Demo->new({ name => $NAME,    nums => \@NUMS   }); } => 'Missing required count';
::like $@, qr/mandatory/ => '...with correct error message';
::ok !eval { Demo->new({ name => $NAME,    count => \%COUNT }); } => 'Missing required nums';
::like $@, qr/mandatory/ => '...with correct error message';

my $obj = Demo->new({ name => $NAME, count => \%COUNT, nums => \@NUMS });

::is $obj->basic, 'basic' => 'Inherited Base1 correctly';
::is $obj->more_basic, 'more basic' => 'Inherited Base2 correctly';

::is        $obj->change_name('me'), 1 => 'Called foo() correctly';
::is        $obj->name,  $NEWNAME  => 'Retained updated name correctly';
::is_deeply $obj->nums,  \@NUMS    => 'Retained original nums correctly';
::is_deeply $obj->count, \%COUNT   => 'Retained original count correctly';

::is        $obj->change_others(), 1    => 'Called foo() correctly';
::is        $obj->name,  $NEWNAME   => 'Retained updated name correctly';
::is_deeply $obj->nums,  \@NEWNUMS  => 'Retained original nums correctly';
::is_deeply $obj->count, \%NEWCOUNT => 'Retained original count correctly';

::ok !defined eval{ $obj->name('etc'); 1 }, => 'Name setter failed, as expected';
::ok !defined eval{ $obj->nums(['a']); 1 }, => 'Nums setter failed, as expected';
::ok !defined eval{ $obj->count({}); 1 },   => 'Count setter failed, as expected';

done_testing;

