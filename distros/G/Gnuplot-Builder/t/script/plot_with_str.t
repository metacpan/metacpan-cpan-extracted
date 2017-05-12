use strict;
use warnings FATAL => "all";
use lib "t";
use testlib::ScriptUtil qw(plot_str);
use Test::More;
use Gnuplot::Builder::Script;

sub create_builder {
    my $builder = Gnuplot::Builder::Script->new;
    $builder->add("hoge");
    $builder->set(foo => "bar");
    return $builder;
}

{
    my $builder = create_builder;
    foreach my $command (qw(plot splot)) {
        my $method = "${command}_with";
        foreach my $case (
            {label => "single dataset", args => {dataset => "sin(x)"},
             exp => "hoge\nset foo bar\n$command sin(x)\n"},
            {label => "multiple datasets", args => {dataset => ["sin(x)", "cos(x)"]},
             exp => "hoge\nset foo bar\n$command sin(x),cos(x)\n"},
            {label => "with output", args => {dataset => "cos(x)", output => "cos.png"},
             exp => "hoge\nset foo bar\nset output 'cos.png'\n$command cos(x)\nset output\n"}
        ) {
            is plot_str($builder, $method, %{$case->{args}}), $case->{exp}, "$case->{label}: $command OK";
        }
    }
}

{
    note("--- example");
    my $builder = Gnuplot::Builder::Script->new;
    my $script = "";
    $builder->plot_with(
        dataset => ['sin(x)', 'cos(x)'],
        output  => "hoge.eps",
        writer  => sub {
            my ($script_part) = @_;
            $script .= $script_part;
        }
    );
    is $script, <<'EXP', "example OK";
set output 'hoge.eps'
plot sin(x),cos(x)
set output
EXP
        
}

done_testing;
