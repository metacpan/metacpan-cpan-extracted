use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

my @warnings = ();
$SIG{__WARN__} = sub {
    push @warnings, $_[0]
};

{
    note("--- inherit and delete");
    my $parent = Gnuplot::Builder::Dataset->new;
    my $child = $parent->new_child;

    $parent->set_join(p_only => ":", both => "!");
    $child->set_join(c_only => "-", both => "=");
    $child->set_option(
        map { $_ => [1,2,3] } qw(p_only c_only both neither)
    );
    is $child->to_string, q{p_only 1:2:3 c_only 1-2-3 both 1=2=3 neither 1 2 3}, "inheritance OK";

    identical $child->delete_join("both"), $child, "delete_join() returns the invocant";
    is $child->to_string, q{p_only 1:2:3 c_only 1-2-3 both 1!2!3 neither 1 2 3}, "parent's 'both' is visible after child->delete_join()";

    identical $parent->delete_join("both"), $parent, "delete_join() returns the invocant";
    is $child->to_string, q{p_only 1:2:3 c_only 1-2-3 both 1 2 3 neither 1 2 3}, "now join for 'both' is back to default after parent->delete_join()";
}

{
    note("--- override with undef");
    my $parent = Gnuplot::Builder::Dataset->new;
    my $child = $parent->new_child;
    $parent->set_join(foo => ":");
    $parent->set_option(foo => [1,2,3]);
    $child->set_join(foo => undef);
    $child->set_option(foo => [4,5,6]);

    is $parent->to_string, 'foo 1:2:3';
    is $child->to_string, 'foo 4 5 6', "child overrides parent's join by undef";
}

cmp_ok scalar(@warnings), ">", 0, "at least 1 warning should be emitted";
is scalar(grep { /join/i && /deprecated/i } @warnings), scalar(@warnings), "... they are all related to deprecation of join";

done_testing;
