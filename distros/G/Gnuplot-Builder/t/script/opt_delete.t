use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->delete_option("hoge"), $builder, "delete() should return the builder";

    $builder->set(
        a => "A",
        b => "B",
        c => "C"
    );
    $builder->delete_option("b");
    is $builder->to_string(), <<EXP, "deleted option should not exist.";
set a A
set c C
EXP
    is_deeply [$builder->get_option("b")], [], "get_option() should return an empty list for deleted option";
    is scalar($builder->get_option("b")), undef, "get_option() should return undef for deleted option in scalar context";

    $builder->set(b => "B2");
    is $builder->to_string(), <<EXP, "if the deleted option is set again, it's at the bottom.";
set a A
set c C
set b B2
EXP
}

done_testing;
