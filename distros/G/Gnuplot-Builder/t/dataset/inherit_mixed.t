use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;
use Gnuplot::Builder::JoinDict;
use lib "t";
use testlib::DatasetUtil qw(get_data);

{
    my $grand = Gnuplot::Builder::Dataset->new;
    my $using_val = Gnuplot::Builder::JoinDict->new(
        separator => ":", content => [x => 1, y => 2]
    );
    $grand->set_option(
        using => $using_val,
        every => undef,
        axes  => "x1y1",
        title => q{''},
        with  => "lp",
        lt    => 0,
        lw    => 1,
    );
    my $parent = $grand->new_child;
    $parent->set_option(
        pt => 1,
        lt => 3
    );
    $parent->set_file("-");
    $parent->set_data("1 1");
    my $child = $parent->new_child;
    $child->set_option(
        ps => 3,
        axes => undef,
        every => '::1',
    );
    $child->set_source('"-"');

    is $grand->to_string, q{using 1:2 axes x1y1 title '' with lp lt 0 lw 1}, "grand params OK";
    is get_data($grand), "", "grand data ok";
    is $parent->to_string,
        q{'-' using 1:2 axes x1y1 title '' with lp lt 3 lw 1 pt 1},
            "parent params OK: set source, override lt and add pt";
    is get_data($parent), "1 1", "parent data ok";
    is $child->to_string,
        q{"-" using 1:2 every ::1 title '' with lp lt 3 lw 1 pt 1 ps 3},
            "child params OK: set source again, override every, disable axes, add ps";
    is get_data($child), "1 1", "child data ok. It's inherited from parent";

    foreach my $child_case (
        {name => "every", exp => ["::1"]},
        {name => "axes",  exp => [undef]},
        {name => "title", exp => [q{''}]},
        {name => "with",  exp => ["lp"]},
        {name => "lt",    exp => [3]},
        {name => "lw",    exp => [1]},
        {name => "pt",    exp => [1]},
        {name => "lt",    exp => [3]},
        {name => "ps",    exp => [3]},
        {name => "non-existent", exp => []}
    ) {
        is_deeply [$child->get_option($child_case->{name})], $child_case->{exp}, "get_option($child_case->{name}) on child OK";
        is scalar($child->get_option($child_case->{name})), $child_case->{exp}[0], "get_option($child_case->{name}) on child OK in scalar context";
    }
    identical scalar($child->get_option("using")), $using_val, "get_option(using) on child returns the grand-parent's object";
}

done_testing;
