package testlib::LensUtil;
use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Exporter qw(import);
use Gnuplot::Builder::JoinDict qw(joind);
use Test::Requires { "Data::Focus" => "0.03" };
use Data::Focus qw(focus);

our @EXPORT_OK = qw(test_lens_options);

sub test_lens_options {
    my ($label, $new) = @_;
    note("--- test_lens_options: $label");
    {
        my $o = $new->();
        my $got_s = focus($o)->get("hoge");
        is $got_s, undef;
        my @got_l = focus($o)->list("hoge");
        is_deeply \@got_l, [undef], "one empty focal point at first";
    }
    {
        my $o = $new->();
        my $got_o = focus($o)->set(hoge => "foobar");
        identical $got_o, $o, "the lens should be destructive.";
        is scalar(focus($o)->get("hoge")), "foobar", "simple scalar: get";
        is_deeply [focus($o)->list("hoge")], ["foobar"], "simple scalar: list";
        is_deeply [$o->get_option("hoge")], ["foobar"], "simple scalar: get_option list";
    }
    {
        my $o = $new->();
        identical focus($o)->set(hoge => ["foo", "bar"]), $o;
        is scalar(focus($o)->get("hoge")), "foo", "array-ref: get";
        is_deeply [focus($o)->list("hoge")], ["foo"], "array-ref: list. single focal point always.";
        is_deeply [$o->get_option("hoge")], ["foo", "bar"], "array-ref: get_option list. actually it's a two-elem list.";
        identical focus($o)->over(hoge => sub { uc(shift) }), $o;
        is_deeply [focus($o)->list("hoge")], ["FOO"], "array-ref: list: after over";
        is_deeply [$o->get_option("hoge")], ["FOO"],
            "array-ref: get option_list after over. it becomes a single elem because over() routine returns a simple scalar.";
        identical focus($o)->over(hoge => sub { [$_[0], $_[0]] }), $o;
        is_deeply [$o->get_option("hoge")], ["FOO", "FOO"], "array-ref over() returning array-ref. now it's actually a two-elem list";
    }
    {
        my $o = $new->();
        identical focus($o)->set(hoge => []), $o;
        is scalar(focus($o)->get("hoge")), undef, "empty array-ref: get";
        is_deeply [focus($o)->list("hoge")], [undef], "empty array-ref: list: returns undef because it's evaled in scalar context";
        is_deeply [$o->get_option("hoge")], [], "empty array-ref: get_option list: but it's actually an empty list";
        identical focus($o)->set(hoge => "HOGE"), $o;
        is scalar(focus($o)->get("hoge")), "HOGE", "set after empty array-ref: get";
        is_deeply [focus($o)->list("hoge")], ["HOGE"], "set after empty array-ref: list";
        is_deeply [$o->get_option("hoge")], ["HOGE"], "set after empty array-ref: single elem";
    }
    {
        my $o = $new->();
        my $val = "val";
        identical focus($o)->set(hoge => sub { $val }), $o;
        is scalar(focus($o)->get("hoge")), "val", "code-ref: get";
        is_deeply [focus($o)->list("hoge")], ["val"], "code-ref: list";
        is_deeply [$o->get_option("hoge")], ["val"], "code-ref: get_option list";
        $val = "FOOBAR";
        is scalar(focus($o)->get("hoge")), "FOOBAR", "code-ref: get dynamic";
        is_deeply [focus($o)->list("hoge")], ["FOOBAR"], "code-ref: list dynamic";
        is_deeply [$o->get_option("hoge")], ["FOOBAR"], "code-ref: get_option list";
    }
    {
        my $o = $new->();
        identical focus($o)->set(hoge => undef), $o;
        is scalar(focus($o)->get("hoge")), undef, "undef: get";
        is_deeply [focus($o)->list("hoge")], [undef], "undef: list";
        is_deeply [$o->get_option("hoge")], [undef], "undef: get_option list";
    }
    {
        my $o = $new->();
        my $j = joind(":", x => 1, y => 2);
        identical focus($o)->set(using => $j), $o;
        identical scalar(focus($o)->get("using")), $j, "object: get";
        my @got_list = focus($o)->list("using");
        is scalar(@got_list), 1, "object: list elems";
        identical $got_list[0], $j, "object: list";
        my @got_opts = $o->get_option("using");
        is scalar(@got_opts), 1, "object: get_option list elems";
        identical $got_list[0], $j, "object: get_option list";
    }
}

1;
