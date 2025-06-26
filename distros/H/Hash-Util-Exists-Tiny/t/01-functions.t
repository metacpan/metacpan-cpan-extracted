use strict;
use warnings;

use Test::More;

use Hash::Util::Exists::Tiny qw(:all);

my %h = (foo => undef, bar => 1, baz => 1);


{
  note("Testing exists_one_of ...");
  ok(exists_one_of(\%h, qw(foo bar baz)),
            "Three elements");
  ok(exists_one_of(\%h, qw(foo bar)),
            "Two elements");
  ok(exists_one_of(\%h, qw(foo)),
            "One element");
  ok(exists_one_of(\%h, qw(foo bar non-existing)),
            "Two elements, one non existing");
  ok(exists_one_of(\%h, qw(foo bar non-existing bar foo)),
            "Repeated elements, one non existing");
  ok(!exists_one_of(\%h, qw(non-existing1 non-existing2)),
           "Non-existing elements");
  ok(!exists_one_of(\%h),
            "Empty list");
}


{
  note("Testing list_exists ...");
  is_deeply([list_exists(\%h, qw(foo bar baz))],
            [qw(foo bar baz)],
            "Three elements");
  is_deeply([list_exists(\%h, qw(foo bar))],
            [qw(foo bar)],
            "Two elements");
  is_deeply([list_exists(\%h, qw(foo bar non-existing))],
            [qw(foo bar)],
            "Two elements, one non existing");
  is_deeply([list_exists(\%h, qw(foo bar non-existing bar foo))],
            [qw(foo bar bar foo)],
            "Repeated elements, one non existing");
  is_deeply([list_exists(\%h, qw(non-existing))],
            [],
           "Non-existing element");
  is_deeply([list_exists(\%h)],
            [],
            "Empty list");
}


{
  note("Testing list_exists_unique ...");
  is_deeply([list_exists_unique(\%h, qw(foo bar baz))],
            [qw(foo bar baz)],
            "Three elements");
  is_deeply([list_exists_unique(\%h, qw(foo bar))],
            [qw(foo bar)],
            "Two elements");
  is_deeply([list_exists_unique(\%h, qw(foo bar non-existing))],
            [qw(foo bar)],
            "Two elements, one non existing");
  is_deeply([list_exists_unique(\%h, qw(foo bar non-existing bar foo foo bar))],
            [qw(foo bar)],
            "Repeated elements, one non existing");
  is_deeply([list_exists_unique(\%h, qw(non-existing))],
            [],
           "Non-existing element");
  is_deeply([list_exists_unique(\%h)],
            [],
            "Empty list");
}


{
  note("Testing num_exists");
  is(num_exists(\%h, qw(foo bar baz)),
     3,
     "Three elements");
  is(num_exists(\%h, qw(foo bar)),
     2,
     "Two elements");
  is(num_exists(\%h, qw(foo bar non-existing)),
     2,
     "Two elements, one non existing");
  is(num_exists(\%h, qw(foo bar non-existing bar foo)),
     4,
     "Repeated elements, one non existing");
  is(num_exists(\%h, qw(non-existing)),
     0,
     "Non-existing element");
  is(num_exists(\%h),
     0,
     "Empty list");
}


{
  note("Testing num_exists_unique");
  is(num_exists_unique(\%h, qw(foo bar baz)),
     3,
     "Three elements");
  is(num_exists_unique(\%h, qw(foo bar)),
     2,
     "Two elements");
  is(num_exists_unique(\%h, qw(foo bar non-existing)),
     2,
     "Two elements, one non existing");
  is(num_exists_unique(\%h, qw(foo bar non-existing bar foo foo bar bar foo)),
     2,
     "Repeated elements, one non existing");
  is(num_exists_unique(\%h, qw(non-existing)),
     0,
     "Non-existing element");
  is(num_exists_unique(\%h),
     0,
     "Empty list");
}

# -----

{
  note("Testing defined_one_of ...");
  ok(defined_one_of(\%h, qw(foo bar baz)),
            "Three elements");
  ok(defined_one_of(\%h, qw(foo bar)),
            "Two elements");
  ok(!defined_one_of(\%h, qw(foo)),
            "One element (value undef)");
  ok(defined_one_of(\%h, qw(foo bar non-existing)),
            "Two elements, one non existing, one undef");
  ok(defined_one_of(\%h, qw(bar non-existing bar)),
            "Repeated elements, one non existing, one undef");
  ok(!defined_one_of(\%h, qw(non-existing1 non-existing2)),
           "Non-existing elements");
  ok(!defined_one_of(\%h),
            "Empty list");
}


{
  note("Testing list_defined ...");
  is_deeply([list_defined(\%h, qw(foo bar baz))],
            [qw(bar baz)],
            "Three elements, one undef");
  is_deeply([list_defined(\%h, qw(foo bar))],
            [qw(bar)],
            "Two elements, one undef");
  is_deeply([list_defined(\%h, qw(foo bar non-existing))],
            [qw(bar)],
            "Two elements, one non existing, one undef");
  is_deeply([list_defined(\%h, qw(foo bar non-existing bar foo))],
            [qw(bar bar)],
            "Repeated elements, one non existing, one undef");
  is_deeply([list_defined(\%h, qw(non-existing))],
            [],
           "Non-existing element");
  is_deeply([list_defined(\%h)],
            [],
            "Empty list");
}


{
  note("Testing list_defined_unique ...");
  is_deeply([list_defined_unique(\%h, qw(foo bar baz))],
            [qw(bar baz)],
            "Three elements, one undef");
  is_deeply([list_defined_unique(\%h, qw(foo bar))],
            [qw(bar)],
            "Two elements, one undef");
  is_deeply([list_defined_unique(\%h, qw(foo bar non-existing))],
            [qw(bar)],
            "Two elements, one non existing, one undef");
  is_deeply([list_defined_unique(\%h, qw(foo bar non-existing bar foo))],
            [qw(bar)],
            "Repeated elements, one non existing, one undef");
  is_deeply([list_defined_unique(\%h, qw(non-existing))],
            [],
           "Non-existing element");
  is_deeply([list_defined_unique(\%h)],
            [],
            "Empty list");
}


{
  note("Testing num_defined");
  is(num_defined(\%h, qw(foo bar baz)),
     2,
     "Three elements, one undef");
  is(num_defined(\%h, qw(foo bar)),
     1,
     "Two elements, one undef");
  is(num_defined(\%h, qw(foo bar non-existing)),
     1,
     "Two elements, one undef, one non existing");
  is(num_defined(\%h, qw(foo bar non-existing bar foo)),
     2,
     "Repeated elements, one non existing, one undef");
  is(num_defined(\%h, qw(non-existing)),
     0,
     "Non-existing element");
  is(num_defined(\%h),
     0,
     "Empty list");
}



{
  note("Testing num_defined_unique");
  is(num_defined_unique(\%h, qw(foo bar baz)),
     2,
     "Three elements, one undef");
  is(num_defined_unique(\%h, qw(foo bar)),
     1,
     "Two elements, one undef");
  is(num_defined_unique(\%h, qw(foo bar non-existing)),
     1,
     "Two elements, one undef, one non existing");
  is(num_defined_unique(\%h, qw(foo bar non-existing bar foo)),
     1,
     "Repeated elements, one non existing, one undef");
  is(num_defined_unique(\%h, qw(non-existing)),
     0,
     "Non-existing element");
  is(num_defined_unique(\%h),
     0,
     "Empty list");
}

#==================================================================================================
done_testing();

