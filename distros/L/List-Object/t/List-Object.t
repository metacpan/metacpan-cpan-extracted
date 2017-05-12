# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl List-Object.t'
# vim:set filetype=perl:
#########################
use strict;
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 65;
#use Test::More qw(no_plan);
use Data::Dumper;
use List::Object;
BEGIN { use_ok('List::Object') };
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $class = 'List::Object';
my $test_type = "List::Object::Test";
my $lo = $class->new();

is ref $lo, $class, "new() returns $class object";
is $lo->type(), '%', 'default type is HASH';

eval {
    $lo->push([]);
};
my $e = $@;
#print STDERR "#[$e]\n";
like $e, qr/not valid ref type/, "correctly disallowed pushing or wrong type";
$List::Object::Loose = 1;
eval {
    $lo->push([]);
};
#
$e = $@;

ok ! $e, "Able to globally turn off strict data chekcing";
$List::Object::Loose = 0;
#print STDERR "[$e]\n";
use Cwd;
require 't/data/Person.pm';
require 't/data/BadPerson.pm';

my @data = (
    {
        first_name  => 'Bob',
        last_name   => 'Smith',
        age         => 10,
        gender      => 'm',
    },
    {
        first_name  => 'John',
        last_name   => 'Jones',
        age         => 70,
        gender      => 'm',
    },
    {
        first_name  => 'Tom',
        last_name   => 'Hilton',
        age         => 5,
        gender      => 'm',
    },
    {
        first_name  => 'Paul',
        last_name   => 'Murphy',
        age         => 65,
        gender      => 'm',
    },
    {
        first_name  => 'Ringo',
        last_name   => 'Anders',
        age         => 20,
        gender      => 'm',
    },
    {
        first_name  => 'Jen',
        last_name   => 'Davis',
        age         => 60,
        gender      => 'f',
    },
    {
        first_name  => 'Tara',
        last_name   => 'Oneal',
        age         => 55,
        gender      => 'f',
    },
    {
        first_name  => 'Amber',
        last_name   => 'South',
        age         => 25,
        gender      => 'f',
    },
    {
        first_name  => 'Carrie',
        last_name   => 'Brown',
        age         => 45,
        gender      => 'f',
    },
    {
        first_name  => 'Zoe',
        last_name   => 'Zohn',
        age         => 30,
        gender      => 'f',
    },

);


# Testing an object list;

# array functions
my $test_type = 'Test::Person';
my $bad_type = 'Test::BadPerson';
my $po = $class->new(type => $test_type);
is $po->type(), $test_type, "list type is reported correctly";
foreach my $p_data (@data)
{
    my $p = $test_type->new(%$p_data);
    $po->add($p);
}

is $po->count(), 10, "Count reported correctly.";

is $po->first()->first_name(), 'Bob', "First element correct";
is $po->last()->first_name(), 'Zoe', "Last element correct";

$po->rewind();

ok $po->has_next(), "has next reports true state";

$po->next(); $po->next(); $po->next();

my $paused_at = 3;
is $po->{_index}, $paused_at, "calling 'next()' iterating through the array";

my $first_name = $po->peek()->first_name();

is $po->peek()->first_name(), $first_name,  "peek() looks ahead w/o nexting";
is  $po->{_index}, $paused_at, "index unchanged after peeking";

$po->next();$po->next();$po->next();$po->next();$po->next();

ok $po->has_next(), "has_next() report true correctly.";
$po->next();
ok ! $po->has_next(), "has_next reports false correctly.";
eval
{
    $po->next(); 
};

like $@, qr/index out of range/, "Correctly cannot call next() at end of list.";

$po->rewind();

is $po->{_index}, 0, "rewind successful.";

$po->sort_by('age');

is $po->first()->age(), 5, "sort_by check 1 success"; 
is $po->last()->age(), 70, "sort_by check 2 success"; 

$po->sort_by('first_name');
is $po->first()->first_name(), 'Amber', "sort_by check 3 success"; 
is $po->last()->first_name(), 'Zoe', "sort_by check 4 success"; 

$po->reverse();
is $po->first()->first_name(), 'Zoe', "reverse check 1 success"; 
is $po->last()->first_name(), 'Amber', "reverse check 2 success"; 

# randome data
my $p_add = $test_type->new(first_name  => 'Arthur', 
                            last_name   => 'Read',
                            age         => '8');

$po->set(5, $p_add);

my $p_get = $po->get(5);

is $p_get->last_name(), 'Read', "Set and get report correct results";

my $rm_item = $po->remove(5);

is $po->count(), 9, "post remove count() correct";
is $rm_item->last_name(), $p_add->last_name(), "correct item removed, returned";

my $p2_get = $po->get(5);

ok $p2_get->last_name() ne $p_add->last_name(), "getting same index is different after remove";

$po->clear();

is $po->count(), 0, "count is zero after clear";
is $po->{_index}, 0, "index is zero after clear";
is $po->type(), $test_type, "type still correct after clear";

eval {
$po->push($bad_type->new());
};

like $@, qr/not valid ref type/, "type still enforced after clear";

my @push_people;
for (0..2)
{
    push @push_people, Test::Person->new(%{$data[$_]});
}

$po->push(@push_people);

is $po->count(), 3, "pushed multiple items in";

my @unshift_people;
for (7..9)
{
    push @unshift_people, Test::Person->new(%{$data[$_]});
}

$po->unshift(@unshift_people), 6, "unshifted multiple items in";

is $po->count(), 6, "unshifted multiple items in";

my @middle_people;
for (3..6)
{
    push @middle_people, Test::Person->new(%{$data[$_]});
}
$po->push(@middle_people);

#eval {
#$po->sort();
#};

#like $@, qr/scalar/, "can't sort on non-scalars";


$po->sort_by('first_name');

is $po->count(), 10, "count is still good";

my $shift_item = $po->shift();

is $po->count(), 9, "shifting reduces count";
is $shift_item->first_name(), 'Amber', "shifted the right item";

my $pop_item = $po->pop();
is $po->count(), 8, "popping reduces count";
is $pop_item->first_name(), "Zoe", "popped the right item";

my @out_array = $po->array();

is scalar @out_array, 8, "returned array() has correct count";

is $out_array[1]->first_name(), 'Carrie', "first element looks correct";


is $po->allow_undef(), 0, "allow undef returns zero";

$po->{_allow_undef} = 1;

is $po->allow_undef(), 1, "allow undef returns true";

eval {
$po->push(undef);
};

ok ! $@,  "undef allowed to go in with option turned on";

$po->{_allow_undef} = 0;


eval {
$po->push(undef);
};

like $@, qr/undef/,  "undef disallowed with option turned off";


# testing spice last, resting data;
$po = $class->new(type => $test_type);
is $po->type(), $test_type, "list type is reported correctly";
foreach my $p_data (@data)
{
    my $p = $test_type->new(%$p_data);
    $po->add($p);
}
is $po->count(), 10, 'resetting test data set';

my ($i1, $i2)  = $po->splice(3,2);

is $po->count(), 8, 'splice removed 2';

is $i1->first_name(), 'Paul', "splice check 1";
is $i2->first_name(), 'Ringo', "splice check 2";

$po->splice(0, 1, $i1, $i2);

is $po->count(), 9, 'splice added  2, removed 1';

is $po->get(0)->first_name(), "Paul", "splice check 3";
is $po->get(1)->first_name(), "Ringo", "splice check 3";
is $po->get(2)->first_name(), "John", "splice check 5";

my $po_join;
eval
{
    $po_join =  $po->join(',');
};

is $po_join, '', "join returns empty string on non-scalar or non-scalar refs & carps!";

my $spo;
eval
{
$spo = List::Object->new(type => '',
                         list => [qw( z b a c )]);
};
                         
my $join = $spo->join(',');
is $join, "z,b,a,c", "join work correctly on lists of scalars";

eval {
$spo->add(Test::Person->new());
};

like $@, qr/valid/ , "checking scalar type enforcement";

eval {
$spo->unshift(undef);
};

like $@, qr/undef/, "checking scalar undef enforement";


eval {
    $spo->push('');
};

ok ! $@, 'making sure scalar vals can be empty string without issue';

$spo->pop();


$spo->sort();

is $spo->first(), 'a', "sort check 1";
is $spo->last(), 'z', "sort check 2";

# test sort of scalar refs..

my $a = 'a'; my $b = 'b'; my $c = 'c', my $z = 'z';

my @sc_ary = (\$z, \$b, \$a, \$c);

my $srlo = List::Object->new( type  => '$',
                              list  => \@sc_ary);

$srlo->sort();

my $sr_a = $srlo->first(); 
my $sr_z = $srlo->last(); 

is $$sr_a, 'a', "scalarref sort check 1";
is $$sr_z, 'z', "scalarref sort check 2";

my $sr_join = $srlo->join(',');

is $sr_join, "a,b,c,z", "join of scalarref list successful";


# test lish of HASHREFS;

my $hol = List::Object->new(type => '%',
                            list => \@data); 

$hol->sort_by('last_name');

is $hol->last()->{'last_name'} , 'Zohn' , 'hash sort check 1';
is $hol->first()->{'last_name'} , 'Anders' , 'hash sort check 2';



