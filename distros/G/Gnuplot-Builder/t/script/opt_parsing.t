use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

{
    note("--- example");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<'EOT');
xrange = [-5:10]
output = "foo.png"
grid
-key

## terminal = png size 100,200
terminal = pngcairo size 400,800

tics = mirror in \
       rotate autojustify

arrow = 1 from 0,10 to 10,0
arrow = 2 from 5,5  to 10,10
EOT
    is $builder->to_string, <<EXP;
set xrange [-5:10]
set output "foo.png"
set grid
unset key
set terminal pngcairo size 400,800
set tics mirror in        rotate autojustify
set arrow 1 from 0,10 to 10,0
set arrow 2 from 5,5  to 10,10
EXP
}

{
    note("--- multiple lines with trailing backslash");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<'EOT');
term\
inal =\
png \
size 100,\
200
EOT
    is $builder->to_string, "set terminal png size 100,200\n";
}

{
    note("--- trailing backslash should take effect before commenting out.");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<'EOT');
## due to trailing backslash, the next line is also commented out \
title = "foobar"
EOT
    is $builder->to_string, "";
}

{
    note("--- white speces in keys and values");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<'EOT');
arrow 1 = from 0,0 to 1,1
  arrow 2  =  from   5,5  to 10,10
EOT
    is $builder->to_string, <<'EOT';
set arrow 1 from 0,0 to 1,1
set arrow 2 from   5,5  to 10,10
EOT
}

done_testing;

