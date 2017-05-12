use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

foreach my $case (
    {label => "normal", input => 'hoge.png', exp => qq{set output 'hoge.png'\n}},
    {label => "including apos", input => "hoge's values", exp => qq{set output 'hoge''s values'\n}},
    {label => "undef", input => undef, exp => qq{unset output\n}},
    {label => "empty array-ref", input => [], exp => qq{}},
    {label => "array-ref", input => ["foo", "bar"], exp => qq{set output 'foo'\nset output 'bar'\n}},
    {label => "code-ref -> string", input => sub { "hoge" }, exp => qq{set output 'hoge'\n}},
    {label => "code-ref -> list", input => sub { ("foo", "bar") }, exp => qq{set output 'foo'\nset output 'bar'\n}},
    
) {
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->setq(output => $case->{input}), $builder, "$case->{label}: setq() returns the builder";
    is $builder->to_string, $case->{exp}, "$case->{label}: quoted OK";
}

{
    note("--- setq() code-ref");
    my $builder = Gnuplot::Builder::Script->new;
    my $called = 0;
    $builder->setq(arrow => sub {
        my ($inner_builder, $opt_name) = @_;
        $called++;
        identical $inner_builder, $builder, "first arg for code-ref OK";
        is $opt_name, "arrow", "second arg for code-ref OK";
        ok wantarray, "code-ref in list context OK";
        return ("1", "2", "3");
    });
    is $called, 0, "not called yet";
    is $builder->to_string, "set arrow '1'\nset arrow '2'\nset arrow '3'\n", "script OK";
    is $called, 1, "called once";
}

done_testing;
