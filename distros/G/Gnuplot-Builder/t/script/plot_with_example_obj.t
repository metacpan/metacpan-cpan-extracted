package My::Data;
use strict;
use warnings FATAL => "all";

sub new {
    my ($class, $x_data, $y_data) = @_;
    return bless { x => $x_data, y => $y_data }, $class;
}

sub params_string { q{"-" using 1:2 title "My Data" with lp} }

sub write_data_to {
    my ($self, $writer) = @_;
    foreach my $i (0 .. $#{$self->{x}}) {
        my ($x, $y) = ($self->{x}[$i], $self->{y}[$i]);
        $writer->("$x $y\n");
    }
}

package main;
use strict;
use warnings FATAL => "all";
use Test::More;
use lib "t";
use testlib::ScriptUtil qw(plot_str);
use Gnuplot::Builder::Script;

my $builder = Gnuplot::Builder::Script->new;
is plot_str($builder, "plot_with", dataset => My::Data->new([1,2,3], [1,4,9])), <<EXP, "example OK";
plot "-" using 1:2 title "My Data" with lp
1 1
2 4
3 9
e
EXP


done_testing;

