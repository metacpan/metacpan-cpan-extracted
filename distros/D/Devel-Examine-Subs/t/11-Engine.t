#!perl
use warnings;
use strict;

use Test::More tests => 11;

use Data::Dumper;

BEGIN {#1-2
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
}

# engine config
my $namespace = "Devel::Examine::Subs";
my $engine_module = $namespace . "::Engine";
my $compiler = $engine_module->new();
my $engine = $compiler->{engines}{_test}->();

{#3
    ok ( ref($engine) eq 'CODE', "a returned \$engine is a CODE ref" );
}
{#4
    my $res = $engine->();
    is ( ref($res), 'HASH', "_test engine returns a hashref" );
}
{#5
    my $res = $engine->();
    is ( ref($res), 'HASH', "_test engine returns a hashref properly" );
}
{#6
    my $des = _des({engine => '_test'});
    my $engine = $des->_engine();
    is ( ref($engine), 'CODE', "_load_engine() returns a cref properly" );
    is ( ref($engine->()), 'HASH', "the _test engine returns a hashref" );
}
{#8
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({engine => '_test_bad'});
    };

    like ( $@, qr/dispatch table/, "engine module croaks if the dt key is ok, but the value doesn't point to a callback" );
}
{#9
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({engine => 'asdfasdf'});
    };

    like ( $@, qr/'asdfasdf'/, "engine module croaks if an invalid internal engine is called" );
}
{
    my $des = Devel::Examine::Subs->new;

    my $cref = sub { return 55; };
    my $p = {
        engine => $cref,
    };

    my $ret = $des->_engine($p, {a => 1});

    is (ref $ret, 'CODE', "_engine() returns a cref properly");
    is ($ret->(), 55, "...and the cref does the right thing");

}
sub _engine { 
    my $p = shift; 
    return \&{$compiler->{engines}{$p}}; 
};

sub _des {  
    my $p = shift; 
    my $des =  Devel::Examine::Subs->new(engine => $p->{engine}); 
    return $des;
};
