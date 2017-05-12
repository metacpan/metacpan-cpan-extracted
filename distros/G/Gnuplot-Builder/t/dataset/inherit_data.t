use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;
use lib "t";
use testlib::DatasetUtil qw(get_data);

{
    note("--- basics");
    my $parent = Gnuplot::Builder::Dataset->new;
    my $child = $parent->new_child;

    is get_data($child), "", "no one has inline data";
    $parent->set_data("1 10");
    is get_data($child), "1 10", "child now provides the parent's data";
    $child->set_data(undef);
    is get_data($child), "", "child overrides the parent with undef";
    $child->set_data(sub { $_[1]->("100 200") });
    is get_data($child), "100 200", "child overrides the parent with code";
}

{
    note("--- code-ref data");
    my $parent = Gnuplot::Builder::Dataset->new;
    my $child = $parent->new_child;

    my @inners = ();
    $parent->set_data(sub {
        my ($inner_dataset, $writer) = @_;
        push @inners, $inner_dataset;
        $writer->("15 30");
    });
    is get_data($parent), "15 30", "parent data ok";
    is get_data($child), "15 30", "child data ok";
    is scalar(@inners), 2, "code called twice";
    identical $inners[0], $parent, "the first call is with parent";
    identical $inners[1], $child, "the second call is with child";
}

done_testing;
