#!env perl

use strict;use warnings;

use lib '../lib';
use Test::More;

use_ok('Message::Router', 'mroute', 'mroute_config');

$main::returns = {};

sub main::h1 {
    my %args = @_;
    #expects
    # $args{message}
    # $args{route}
    # $args{routes}
    # $args{forward}
    $main::returns = \%args;
}
my $config = {
    routes => [
        {   match => {
                a => 'b',
            },
            forwards => [
                {   handler => 'main::h1',
                    x => 'y',
                },
            ],
            transform => {
                this => 'that',
            },
        }
    ],
};

ok ((not scalar keys %$main::returns), 'make sure returns starts blank');
eval {
    mroute_config();
};
ok $@, 'argumentless mroute_config failed';
ok $@ =~ /single argument must be a HASH reference/, 'argumentless mroute_config failed correctly';

eval {
    mroute_config('smurf');
};
ok $@, 'scalar argument to mroute_config failed';
ok $@ =~ /single argument must be a HASH reference/, 'scalar argument to mroute_config failed correctly';


eval {
    mroute_config('one','two');
};
ok $@, 'two arguments to mroute_config failed';
ok $@ =~ /single argument must be a HASH reference/, 'two arguments to mroute_config failed correctly';


eval {
    mroute();
};
ok $@, 'no arguments to mroute failed';
ok $@ =~ /single argument must be a HASH reference/, 'no arguments to mroute failed correctly';


eval {
    mroute('one', 'two');
};
ok $@, 'two arguments to mroute failed';
ok $@ =~ /single argument must be a HASH reference/, 'two arguments to mroute failed correctly';


eval {
    mroute_config({});
};
ok $@, 'blank config mroute_config failed';
ok $@ =~ /passed config must have an ARRAY or HASH 'routes' key/, 'blank config to mroute_config failed correctly';

eval {
    mroute_config({ routes => 'smurf' });
};
ok $@, 'config mroute_config with non-ARRAY-ref argument failed';
ok $@ =~ /passed config must have an ARRAY or HASH 'routes' key/, 'config mroute_config with non-ARRAY-ref argument failed correctly';


eval {
    mroute_config({ routes => [ {} ] });
};
ok $@, 'config mroute_config with route without match key failed';
ok $@ =~ /each route has to have a HASH reference 'match' key/, 'config mroute_config with route without match key failed correctly';

eval {
    mroute_config({ routes => [''] });
};
ok $@, 'config mroute_config with "false" route';
ok $@ =~ /each route must be a HASH reference/, 'config mroute_config with "false" route';

eval {
    mroute_config({ routes => ['wrong'] });
};
ok $@, 'config mroute_config with non-HASH-reference route failed';
ok $@ =~ /each route must be a HASH reference/, 'config mroute_config with non-HASH-reference route failed correctly';


eval {
    mroute_config({ routes => [ { match => {}, transform => 'wrong' } ] });
};
ok $@, 'config mroute_config with non-HASH-reference transform failed';
ok $@ =~ /the optional 'transform' key must be a HASH reference/, 'config mroute_config with non-HASH-reference transform failed correctly';


eval {
    mroute_config({ routes => [ { match => {}, forwards => 'wrong' } ] });
};
ok $@, 'config mroute_config with scalar optional forwards failed';
ok $@ =~ /the optional 'forwards' key must be an ARRAY reference/, 'config mroute_config with scalar optional forwards failed correctly';


eval {
    mroute_config({ routes => [ { match => {}, forwards => ['wrong'] } ] });
};
ok $@, 'forward not being a HASH reference failed';
ok $@ =~ /each forward must be a HASH reference/, 'forward not being a HASH reference failed correctly';


eval {
    mroute_config({ routes => [ { match => {}, forwards => [{}] } ] });
};
ok $@, 'forward must hash not having a defined "handler" key failed';
ok $@ =~ /each forward must have a scalar 'handler' key/, 'forward must hash not having a defined "handler" key failed correctly';

eval {
    mroute_config({ routes => [ { match => {}, forwards => [{ handler => {} }] } ] });
};
ok $@, 'forward must hash not having a defined scalar "handler" key failed';
ok $@ =~ /each forward must have a scalar 'handler' key/, 'forward must hash not having a defined scalar "handler" key failed correctly';

eval {
    ok mroute_config({ routes => [ { match => { a => ' specialhuhFOO'}, forwards => [{ handler => 'huh' }] } ] });
    mroute({a => 'b'});
};
ok $@, 'bad match syntax failed';
ok $@ =~ /Message::Router::mroute:/, 'bad match syntax failed correctly';





done_testing();

