use strict;
use warnings;
use Gnuplot::Builder::Script;
use utf8;

sub main {
    my $s = Gnuplot::Builder::Script->new();
    $s->set(title => qq{"タイトル sin(x)"});
    print $s->plot("sin(x)");
}

main;



