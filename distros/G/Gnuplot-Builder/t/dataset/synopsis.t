use strict;
use warnings FATAL => "all";
use Test::More;

#########

use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;
    
my $builder = Gnuplot::Builder::Script->new;

my $func_data = Gnuplot::Builder::Dataset->new('sin(x)');
$func_data->set(title => '"function"', with => "lines");
    
my $unit_scale = 0.001;
my $file_data = Gnuplot::Builder::Dataset->new_file("sampled_data1.dat");
$file_data->set(
    using => sub { "1:(\$2 * $unit_scale)" },
    title => '"sample 1"',
    with  => 'linespoints lw 2'
);
    
my $another_file_data = $file_data->new_child;
$another_file_data->set_file("sampled_data2.dat");  ## override parent's setting
$another_file_data->setq(title => "sample 2");      ## override parent's setting

my $inline_data = Gnuplot::Builder::Dataset->new_data(<<INLINE_DATA);
1.0  3.2
1.4  3.0
1.9  4.3
2.2  3.9
INLINE_DATA
$inline_data->set(using => "1:2", title => '"sample 3"');
    
## $builder->plot($func_data, $file_data, $another_file_data, $inline_data);


#########

my $result = "";
$builder->plot_with(dataset => [$func_data, $file_data, $another_file_data, $inline_data],
                    writer => sub { $result .= shift });

my $exp_plotline =
    q{plot sin(x) title "function" with lines,} .
    q{'sampled_data1.dat' using 1:($2 * 0.001) title "sample 1" with linespoints lw 2,} .
    q{'sampled_data2.dat' using 1:($2 * 0.001) title 'sample 2' with linespoints lw 2,} .
    q{'-' using 1:2 title "sample 3"};

is $result, <<"EXP", "plot result OK";
$exp_plotline
1.0  3.2
1.4  3.0
1.9  4.3
2.2  3.9
e
EXP

done_testing;

