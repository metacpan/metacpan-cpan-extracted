use strict;
use warnings;
use Data::Dumper;
use lib './lib';
use Test::More;
use Data::Dumper;
use JavaScript::Duktape;

subtest 'check undefined gets through to sub' => sub {
    my $js = JavaScript::Duktape->new();

    $js->set(
        foo => sub {
            is $_[0], undef;
            is $_[1], 'bar';
        }
    );

    $js->eval(q{
        foo( undefined, 'bar');
    });
};

subtest 'check undefined return gets through from another sub' => sub {
    my $js = JavaScript::Duktape->new();

    $js->set(
        gen_undef => sub {
            return undef;
        }
    );

    $js->set(
        foo => sub {
            is $_[0], undef;
            is $_[1], 'bar';
        }
    );

    $js->eval(q{
        foo( gen_undef(), 'bar');
    });
};

subtest 'set to value to undefined and pass it to sub' => sub {
    my $js = JavaScript::Duktape->new();

    $js->set( myundef => undef );

    $js->set(
        foo => sub {
            is $_[0], undef;
            is $_[1], 'bar';
        }
    );

    $js->eval(q{
        foo( myundef, 'bar');
    });
};

done_testing;
