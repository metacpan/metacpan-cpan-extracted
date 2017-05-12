use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->set_option(xrange => '[10:20]'), $builder, "set_option() should return the object";
    $builder->set_option(<<EOD);
key
-grid
term = png
EOD
    is $builder->to_string, "set xrange [10:20]\nset key\nunset grid\nset term png\n",
        'set_option() is alias for set()';
}

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->unset("foo", "bar", "buzz"), $builder, "unset() should return the object";
    is $builder->to_string, "unset foo\nunset bar\nunset buzz\n",
        "unset() is alias for set(name => undef)";
}

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->setq_option(title => "This is A's result"), $builder, "setq_option() returns the object.";
    is $builder->to_string, qq{set title 'This is A''s result'\n}, "setq_option() is alias for setq()";
}

done_testing;
