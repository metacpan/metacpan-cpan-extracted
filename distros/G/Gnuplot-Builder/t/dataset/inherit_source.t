use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    note("--- basic inheritance about source");
    my $parent = Gnuplot::Builder::Dataset->new;
    my $child = $parent->new_child;

    is $child->get_source, undef, "no ancestor have source";
    is $child->to_string, "", "... to_string() ok";
    $parent->set_source("sin(x)");
    is $child->get_source, "sin(x)", "child's source is same as parent's";
    is $child->to_string, "sin(x)", "... to_string() ok";
    $child->set_source("cos(x)");
    is $child->get_source, "cos(x)", "child's source overrides the parent's";
    is $child->to_string, "cos(x)", "... to_string() ok";
    $child->set_source(undef);
    is $child->get_source, undef, "setting child's source to undef overrides the parent's";
    is $child->to_string, "", "... to_string() ok";
    $child->delete_source();
    is $child->get_source, "sin(x)", "child's source deleted. parent's source is now visible.";
    is $child->to_string, "sin(x)", "... to_string() ok";
}

{
    note("--- code-ref source");
    my $parent = Gnuplot::Builder::Dataset->new;
    my $child = $parent->new_child;

    my @inners = ();
    $parent->set_source(sub {
        my ($inner_dataset) = @_;
        push @inners, $inner_dataset;
        return "sin(x)";
    });
    is $parent->get_source, "sin(x)", "parent source OK";
    is $child->get_source, "sin(x)", "child source OK";
    is scalar(@inners), 2, "code is called twice";
    identical $inners[0], $parent, "the first call is with parent";
    identical $inners[1], $child, "the second call is with child";
}

done_testing;
