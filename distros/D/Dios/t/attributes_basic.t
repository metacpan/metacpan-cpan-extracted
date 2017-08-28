use Dios;
use Test::More;

plan tests => 26;

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

    has Str $.name  is req = rand(100);
    has Int @.nums  is req;
    has Num %.count is req;

    method change_name ($this: Str $newname, Int|Undef :$other) {
        ::is $name, $NAME => 'Name correct';

        $name = $NEWNAME;
        ::is $this->get_name, $NEWNAME => 'Assignment to name correct';

        return 1;
    }

    method change_others () {
        ::is_deeply \@nums, \@NUMS => 'Nums correct';

        @nums = @NEWNUMS;
        ::is_deeply $self->get_nums, \@NEWNUMS => 'Assignment to nums correct';


        ::is_deeply \%count, \%COUNT => 'Nums correct';

        %count = %NEWCOUNT;
        ::is_deeply $self->get_count, \%NEWCOUNT => 'Assignment to nums correct';

        return 1;
    }

    method check_all () {

        ::is $name, $NEWNAME => 'Name correct in check_all method';

        ::is_deeply \@nums, \@NEWNUMS => 'Nums correct in check_all method';

        ::is_deeply \%count, \%NEWCOUNT => 'Nums correct in check_all method';

        return 1;
    }
}

my $obj = Demo->new({ name => $NAME, count => \%COUNT, nums => \@NUMS });

::is $obj->basic, 'basic' => 'Inherited Base1 correctly';
::is $obj->more_basic, 'more basic' => 'Inherited Base2 correctly';

::is        $obj->change_name('me'), 1 => 'Called change_name() correctly';
::is        $obj->get_name,  $NEWNAME  => 'Retained updated name correctly';
::is_deeply $obj->get_nums,  \@NUMS    => 'Retained original nums correctly';
::is_deeply $obj->get_count, \%COUNT   => 'Retained original count correctly';

::is        $obj->change_others(), 1    => 'Called change_others() correctly';
::is        $obj->get_name,  $NEWNAME   => 'Retained updated name correctly';
::is_deeply $obj->get_nums,  \@NEWNUMS  => 'Retained original nums correctly';
::is_deeply $obj->get_count, \%NEWCOUNT => 'Retained original count correctly';

::is        $obj->check_all(), 1        => 'Called check_all() correctly';
::is        $obj->get_name,  $NEWNAME   => 'Retained updated name correctly';
::is_deeply $obj->get_nums,  \@NEWNUMS  => 'Retained original nums correctly';
::is_deeply $obj->get_count, \%NEWCOUNT => 'Retained original count correctly';

::ok !defined eval{ $obj->set_name('etc'); 1 }, => 'Name setter failed, as expected';
::ok !defined eval{ $obj->set_nums(['a']); 1 }, => 'Nums setter failed, as expected';
::ok !defined eval{ $obj->set_count({}); 1 },   => 'Count setter failed, as expected';

done_testing;
