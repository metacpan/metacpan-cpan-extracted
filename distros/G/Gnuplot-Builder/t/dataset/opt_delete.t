use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    my $dataset = Gnuplot::Builder::Dataset->new;
    is_deeply [$dataset->get_option("foo")], [], "get non-existent option";
    is scalar($dataset->get_option("foo")), undef, "get non-existent option in scalar context";
    identical $dataset->delete_option("foo"), $dataset, "delete non-existent option is OK";
    
    $dataset->set_option(foo => "bar");
    is_deeply [$dataset->get_option("foo")], ["bar"], "set foo";
    is scalar($dataset->get_option("foo")), "bar", "get foo in scalar context";
    identical $dataset->delete_option("foo"), $dataset, "delete foo";
    is_deeply [$dataset->get_option("foo")], [], "foo is deleted";
    is scalar($dataset->get_option("foo")), undef, ".. in scalar context";
}

done_testing;

