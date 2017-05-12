#!perl
use warnings;
use strict;

use Test::More tests => 17;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

{#2
    my $res = $des->missing( file =>  't/sample.data', search => 'this' );
    ok ( $res->[0] =~ '\w+', "legacy missing() returns an array if file exists and text available" );
}
{#3
    my $res = $des->missing( file => 't/sample.data', search => '' );
    ok ( ! $res->[0], "legacy missing() returns an empty array if file exists and text is empty string" );
}
{#4
    my $res = $des->missing( file => 't/sample.data', search => 'asdfasdf' );
    ok ( $res->[0], "obj->missing() returns an array if file exists and search text not found" );
}
{#5-7
    my %params = (
                    file => 't/sample.data', 
                    engine => 'missing', 
                  );

    my $des = Devel::Examine::Subs->new(%params);
    
    my $missing = $des->run(\%params);

    ok ( ref($missing) eq 'ARRAY', "calling the 'missing' engine through run() returns an aref" );
    is ( @$missing, 0, "'missing' engine returns the proper count of subs through run()" );
    ok ( ref($missing) eq 'ARRAY', "missing engine does the right thing through run() with no search" );
}
{#8
    my %params = (
                    file => 't/sample.data', 
                    engine => 'missing', 
                    search => 'this',  
                );

    my $des = Devel::Examine::Subs->new(%params);

    my $missing = $des->run(\%params);

    is ( @$missing, 6, "'missing' engine returns the proper count of subs through run() with 'this'" );
}
{#9
     my %params = (
                    file => 't/sample.data', 
                    engine => 'missing', 
                    search => 'return',
                );

    my $des = Devel::Examine::Subs->new(%params);

    my $missing = $des->run(\%params);

    is ( @$missing, 8, "'missing' engine returns the proper count of subs through run() with 'return'" );
}
{#10
    my %params = (
                    file => 't/sample.data', 
                    engine => 'missing', 
                    search => 'asdf',
                );

    my $des = Devel::Examine::Subs->new(%params);
    my $missing = $des->run();
    
    is ( @$missing, 11, "'missing' engine returns the proper count of subs through run() with 'asdf'" );
}

{
    my %params = ( file => 't/test/files', search => 'this' );

    my $des = Devel::Examine::Subs->new(%params);

    my $ret = $des->missing();

    is (keys %$ret, 3, "missing() directory has the correct number of keys" );

    delete $ret->{'t/test/files/module.pm'};;

    for (keys %$ret){
        ok (ref $ret->{$_} eq 'ARRAY', "missing() directory keys contain arefs" );
        is (@{$ret->{$_}}, 6, "missing() directory keys have the correct number of elements" );
    }
}
{#4
    my $res = $des->missing( file => 't/sample.data', search => 'my?', regex => 0 );
    is (@$res, 11, "without regex, search doesn't act like a regex");

    $res = $des->missing( file => 't/sample.data', search => 'm.', regex => 1);
    is (@$res, 4, "with regex, search acts like a regex");
}
