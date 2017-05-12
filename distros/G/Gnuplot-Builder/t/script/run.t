use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;

my @test_cases = (
    {
        label => "example: enclose 'do for' block",
        args => {
            do => [
                "set multiplot layout 2,2",
                "do for [name in  'A B C D'] {",
                sub {
                    my $another_builder = Gnuplot::Builder::Script->new;
                    $another_builder->define(filename => "name . '.dat'");
                    $another_builder->plot('filename u 1:2');
                },
                "}",
                "unset multiplot"
            ]
        },
        exp => <<'EXP'
set multiplot layout 2,2
do for [name in  'A B C D'] {
filename = name . '.dat'
plot filename u 1:2
}
unset multiplot
EXP
    },
    {
        label => "single code",
        args => { do => sub { $_[0]->("plot sin(x)\n") } },
        exp => <<'EXP'
plot sin(x)
EXP
    },
    {
        label => "single sentence",
        args => { do => "plot sin(x)" },
        exp => <<'EXP'
plot sin(x)
EXP
    },
    {
        label => "empty sentence",
        args => { do => "" },
        exp => "\n",
    },
    {
        label => "empty sentences",
        args => { do => ["", "\n", ""] },
        exp => "\n\n\n",
    },
    {
        label => "code not calling writer",
        args => { do => sub { } },
        exp => ""
    },
    {
        label => "code calling writer with empty data",
        args => { do => sub { $_[0]->(""); } },
        exp => ""
    },
    {
        label => "no do at all",
        args => {},
        exp => "",
    },
    {
        label => "sentences with/without trailing newlines",
        args => {
            do => ["hoge", "foo\n", "bar\n"],
        },
        exp => <<'EXP'
hoge
foo
bar
EXP
    },
    {
        label => "codes with/without trailing newline",
        args => {
            do => [
                sub { $_[0]->("set "); $_[0]->("term"); $_[0]->(" png") },
                sub { $_[0]->(" size 100,"); $_[0]->("100\n") },
                sub { $_[0]->("set grid\n") },
                sub { $_[0]->("") },
                sub { $_[0]->("reread") },
            ]
        },
        exp => q{set term png size 100,100
set grid
reread}
    },
    {
        label => "mixed code and sentences without trailing newlines",
        args => {
            do => [
                "aaa",
                sub { $_[0]->("bbb") },
                "ccc",
                sub { $_[0]->("ddd") },
            ]
        },
        exp => q{aaa
bbbccc
ddd}
    },
    {
        label => "async has no effect",
        args => {
            async => 1,
            do => [
                "hoge",
                sub { $_[0]->("foo\n") }
            ]
        },
        exp => <<'EXP'
hoge
foo
EXP
    },
    {
        label => "output option with a simple do",
        args => {
            output => "foobar.png",
            do => 'plot sin(x)'
        },
        exp => <<'EXP'
set output 'foobar.png'
plot sin(x)
set output
EXP
    },
    {
        label => "output option with no do",
        args => {
            output => "hoge.png",
        },
        exp => <<'EXP'
set output 'hoge.png'
set output
EXP
    }
);



foreach my $case (@test_cases) {
    my $builder = Gnuplot::Builder::Script->new;
    my $script = "";
    my $result = $builder->run_with(
        %{$case->{args}},
        writer => sub { $script .= $_[0] },
    );
    is $script, $case->{exp}, "$case->{label}: script OK";
    is $result, "", "$case->{label}: run_with() should return an empty string if writer is present";
}


{
    note("--- example: run_with() with non-empty Script.");
    my $builder = Gnuplot::Builder::Script->new(<<SET);
term = gif size 500,500 animate
output = "waves.gif"
SET
    my $FRAME_NUM = 10;
    
    my $script_direct = "";
    my $result_direct = $builder->run_with(
        writer => sub { $script_direct .= $_[0] },
        do => sub {
            my $writer = shift;
            foreach my $phase_index (0 .. ($FRAME_NUM-1)) {
                my $phase_deg = 360.0 * $phase_index / $FRAME_NUM;
                $writer->("plot sin(x + $phase_deg / 180.0 * pi)\n");
            }
        }
    );
    is $result_direct, "", "run_with() should return '' when writer is present";
    
    my $script_builder = "";
    my $result_builder = $builder->run_with(
        writer => sub { $script_builder .= $_[0] },
        do => sub {
            my $another_builder = Gnuplot::Builder::Script->new;
            foreach my $phase_index (0 .. ($FRAME_NUM-1)) {
                my $phase_deg = 360.0 * $phase_index / $FRAME_NUM;
                $another_builder->plot("sin(x + $phase_deg / 180.0 * pi)");
            }
        }
    );
    is $result_builder, "", "run_with() should return '' when writer is present";

    my $exp = <<'EXP';
set term gif size 500,500 animate
set output "waves.gif"
plot sin(x + 0 / 180.0 * pi)
plot sin(x + 36 / 180.0 * pi)
plot sin(x + 72 / 180.0 * pi)
plot sin(x + 108 / 180.0 * pi)
plot sin(x + 144 / 180.0 * pi)
plot sin(x + 180 / 180.0 * pi)
plot sin(x + 216 / 180.0 * pi)
plot sin(x + 252 / 180.0 * pi)
plot sin(x + 288 / 180.0 * pi)
plot sin(x + 324 / 180.0 * pi)
EXP
    is $script_direct, $exp, "script ok (direct call to writer)";
    is $script_builder, $exp, "script ok (write though builder)";
}


{
    note("--- example: use the builder in its own run() block");
    my $builder = Gnuplot::Builder::Script->new;
    my $script = "";
    
    $builder->run_with(
        writer => sub { $script .= $_[0] },
        do => [
            "cd 'subdir1'",
            sub {
                foreach my $name (qw(a b c d)) {
                    $builder->plot("'$name.dat' u 1:2 title '$name'");
                }
            }
        ]
    );
    
    is $script, <<'EXP', "result OK";
cd 'subdir1'
plot 'a.dat' u 1:2 title 'a'
plot 'b.dat' u 1:2 title 'b'
plot 'c.dat' u 1:2 title 'c'
plot 'd.dat' u 1:2 title 'd'
EXP
}

{
    note("--- jump out of run() due to exception");
    my $builder = Gnuplot::Builder::Script->new;
    my $result = "";
    local $@;
    eval {
        $builder->run_with(
            writer => sub { $result .= $_[0] },
            do => [
                "print 'hogehoge'",
                sub { $builder->plot("sin(x) title 'sin'") },
                sub {
                    $builder->plot("cos(x) title 'cos'");
                    die "BOOM!";
                    $builder->plot("tan(x) title 'tan'");
                },
                "print 'foobar'"
            ]
        );
        fail("this should not be executed");
    };
    like $@, qr{^BOOM!}, "exception thrown";
    is $result, <<'EXP', "it should write script until it dies";
print 'hogehoge'
plot sin(x) title 'sin'
plot cos(x) title 'cos'
EXP
}

done_testing;
