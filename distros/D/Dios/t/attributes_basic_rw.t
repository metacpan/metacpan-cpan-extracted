use Dios;
use Test::More;

plan tests => 22;

my $NAME  = 'Damian';
my @NUMS  = (1,2,3);
my %COUNT = ( a=>1.1, b=>-2 );

my $NEWNAME  = 'Conway';
my @NEWNUMS  = (4,5,6);
my %NEWCOUNT = ( a=>0, c=>99 );

my $NEWNAME2  = 'MUDD';
my @NEWNUMS2  = (7);
my %NEWCOUNT2 = ();

class Base1 {
    method basic { return 'basic' }
}

class Base2 {
    method more_basic { return 'more basic' }
}

class Demo is Base1 is Base2 {
    has Str $.name  is rw is req;
    has Int @.nums  is rw is req;
    has Num %.count is rw is req;

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
}

my $obj = Demo->new({ name => $NAME, count => \%COUNT, nums => \@NUMS });

::is $obj->basic, 'basic' => 'Inherited Base1 correctly';
::is $obj->more_basic, 'more basic' => 'Inherited Base2 correctly';

::is        $obj->change_name('me'), 1 => 'Called foo() correctly';
::is        $obj->get_name,  $NEWNAME  => 'Retained updated name correctly';
::is_deeply $obj->get_nums,  \@NUMS    => 'Retained original nums correctly';
::is_deeply $obj->get_count, \%COUNT   => 'Retained original count correctly';

::is        $obj->change_others(), 1    => 'Called foo() correctly';
::is        $obj->get_name,  $NEWNAME   => 'Retained updated name correctly';
::is_deeply $obj->get_nums,  \@NEWNUMS  => 'Retained original nums correctly';
::is_deeply $obj->get_count, \%NEWCOUNT => 'Retained original count correctly';

::ok $obj->set_name($NEWNAME2),   => 'Name setter succeeded';
::ok $obj->set_nums(\@NEWNUMS2), => 'Nums setter succeeded';
::ok $obj->set_count(\%NEWCOUNT2),     => 'Count setter succeeded';

::is        $obj->get_name,  $NEWNAME2   => 'Retained updated name correctly';
::is_deeply $obj->get_nums,  \@NEWNUMS2  => 'Retained original nums correctly';
::is_deeply $obj->get_count, \%NEWCOUNT2 => 'Retained original count correctly';

done_testing;
