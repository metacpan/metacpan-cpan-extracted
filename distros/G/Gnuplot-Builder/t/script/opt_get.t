use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    note("--- get non-existent");
    my $builder = Gnuplot::Builder::Script->new;
    is_deeply [$builder->get_option("hoge")], [], "non-existent value returns an empty list";
}

{
    note("--- get plain data");
    foreach my $case (
        {label => 'undef', set => undef, exp => [undef], exp_s => undef},
        {label => "string", set => "foo", exp => ["foo"], exp_s => "foo"},
        {label => "empty array", set => [], exp => [], exp_s => undef},
        {label => "array", set => ["foo", "bar"], exp => ["foo", "bar"], exp_s => "foo"},
    ) {
        my $builder = Gnuplot::Builder::Script->new;
        $builder->set(hoge => $case->{set});
        is_deeply [$builder->get_option("hoge")], $case->{exp}, "$case->{label}: get_option() OK";
        is scalar($builder->get_option("hoge")), $case->{exp_s}, "$case->{label}: get_option() scalar OK";
    }
}

{
    note("--- get lazy values from code-ref");
    foreach my $case (
        {label => "code-ref -> string", set => sub { "foo" }, exp => ["foo"], exp_s => "foo"},
        {label => "code-ref -> empty", set => sub { () }, exp => [], exp_s => undef},
        {label => "code-ref -> list", set => sub { ("foo", "bar") }, exp => ["foo", "bar"], exp_s => "foo"},
        {label => "code-ref -> undef", set => sub { undef }, exp => [undef], exp_s => undef},
    ) {
        my $builder = Gnuplot::Builder::Script->new;
        my $called = 0;
        $builder->set(hoge => sub {
            $called++;
            return $case->{set}->();
        });
        is_deeply [$builder->get_option("hoge")], $case->{exp}, "$case->{label}: get_option() for code-ref OK";
        is $called, 1, "$case->{label}: value code-ref is called once";
        is scalar($builder->get_option("hoge")), $case->{exp_s}, "$case->{label}: get_option() for code-ref in scalar context OK";
        is $called, 2, "$case->{label}: value code-ref called again";
    }
}

{
    note("--- get values set by setq()");
    foreach my $case (
        {label => "string", set => "hoge", exp => [q{'hoge'}], exp_s => q{'hoge'}},
        {label => "array", set => ["foo", "bar"], exp => [q{'foo'}, q{'bar'}], exp_s => q{'foo'}},
        {label => "code-ref", set => sub { ("foo", "bar" ) }, exp => [q{'foo'}, q{'bar'}], exp_s => q{'foo'}}
    ) {
        my $builder = Gnuplot::Builder::Script->new;
        $builder->setq(hoge => $case->{set});
        is_deeply [$builder->get_option("hoge")], $case->{exp}, "$case->{label}: get_option() with setq() OK";
        is scalar($builder->get_option("hoge")), $case->{exp_s}, "$case->{label}: get_option() with setq() scalar OK";
    }
}

done_testing;
