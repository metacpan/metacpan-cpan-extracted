use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::JoinDict qw(joind);

{
    my $dict = joind();
    isa_ok $dict, "Gnuplot::Builder::JoinDict";
    is "$dict", "";
}

{
    my $dict = joind(":", x => 10, y => 20);
    is "$dict", "10:20";
    my $new_dict = $dict->set(x => 15);
    is "$new_dict", "15:20";
}

done_testing;
