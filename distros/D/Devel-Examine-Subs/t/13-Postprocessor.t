#!perl
use warnings;
use strict;

use Test::More tests => 27;
use Data::Dumper;

BEGIN {#1-2
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Postprocessor' ) || print "Bail out!\n";
}

my $file = 't/sample.data';

# post_proc config

my $namespace = "Devel::Examine::Subs";
my $post_proc_module = $namespace . "::Postprocessor";
my $compiler = $post_proc_module->new();
my $post_proc = $compiler->{post_procs}{subs}->();

{#3
    my $des = Devel::Examine::Subs->new(post_proc => '', file => $file,);
    my $res = $des->run();
    
    ok ( ref($res) eq 'HASH', "no post_proc, data is sent through untouched" );
    for my $f (keys %$res){
        for my $s (keys %{$res->{$f}{subs}}){
            ok ( ref($res->{$f}{subs}{$s}) eq 'HASH', "\$s->{file}{subs}{sub}: no post_proc, data is sent through untouched" );

        }
    }
}
{#4
    my $des = Devel::Examine::Subs->new(file => $file);

    my $cref = sub {
                my $p = shift;
                my $s = shift; 
                return (keys %$s)[0]; 
            };

    my $res = $des->run({post_proc => $cref});

    is ($res, 't/sample.data', "single custom cref to post_proc does the right thing" );

}
{#5
    my $des = Devel::Examine::Subs->new(file => $file);

    my $cref = sub {
                my $p = shift;
                my $s = shift; 
                return $s->{'t/sample.data'}{subs}; 
            };

    my $cref2 = sub {
                my $p = shift;
                my $s = shift;
                return $s->{four};
            };

    my $res = $des->run({post_proc => [$cref, $cref2]});

    ok (ref $res eq 'HASH', "sending in an aref with two crefs to post_proc returns the expected data" );
    is ($res->{end}, 34, "aref of crefs: good data");
    is ($res->{start}, 29, "aref of crefs: good data");
    is ($res->{num_lines}, 6, "aref of crefs: good data");
    ok (ref $res->{code} eq 'ARRAY', "aref of crefs: good data");
    is ($res->{code}[0], 'sub four {', "aref of crefs: good data");
}

{#6
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({post_proc => 'asdfasdf'});
    };

    ok ( $@, "post_proc module croaks if an invalid internal post_proc name is passed in" );

}
{#7
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({post_proc => ['_test', 'asdfasdf']});
    };

    like ( $@, qr/'asdfasdf'/, "post_proc module croaks if the 2nd entry " .
            "in an aref is not implemented" );
}
{#8
    my $des = Devel::Examine::Subs->new();

    my $cref = sub { print "hello, world!"; };

    eval {
        $des->run({post_proc => [$cref, 'asdfasdf']});
    };

    ok ( $@, "post_proc module croaks with invalid if a \$cref is passed " .
             "in with a string post_proc that is invalid" );
}
{#9
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({post_proc => '_test_bad'});
    };

    like ( $@, qr/dispatch table/, "post_proc module croaks if the dt key is ok, but the value doesn't point to a callback" );
}
{#10
    my $des = Devel::Examine::Subs->new();

    my $cref = sub { "hello, world!"; };

    eval {
        $des->run({post_proc => [$cref, '_test']});
    };

    ok ( ! $@, "post_proc works when sent an array ref with a cref and a " .
             "string" );
}
{#11
    my $des = Devel::Examine::Subs->new(file => 't/sample.data');
    my $ret = $des->run({engine => 'all', post_proc_return => 1});
    is (ref $ret, 'HASH', "post_proc_return returns the struct");
}
{#11
    my $des = Devel::Examine::Subs->new(file => 't/sample.data', search => "hello");
    my $ret = $des->run({
        engine => 'all',
        post_proc => 'subs',
        post_proc_return => 1,
        search => 'four'
    });

    for (@$ret){
        print Dumper $_ if $_->{name} eq 'four';
    }
    #is (ref $ret, 'HASH', "post_proc_return returns the struct");
}
