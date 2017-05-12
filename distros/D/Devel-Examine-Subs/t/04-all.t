#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 38;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

{#2
    my $res = $des->all( file => 't/sample.data', search => '' );
    ok ( ref($res) eq 'ARRAY', "obj->all() returns an array ref if file exists and text is empty string" );
}
{#3
    my $res = $des->all( file => 't/sample.data', search => 'asdfasdf' );
    ok ( @$res, "obj->all() returns an array ref if file exists and search text not found" );
}
{#4
    my $res = $des->all( file => 't/sample.data' );
    ok ( ref($res) eq 'ARRAY', "obj->all() returns an aref when called in scalar context" );
}
{#5
    my $res = $des->all( file => 't/sample.data', search => 'thifs' );
    is ( @$res, 11, "obj->all() returns the proper count of names when data is found" );
}
{#6
    my $res = $des->all( file => 't/sample.data' );
    is ( @$res, 11, "obj->all() does the right thing with no search param" );
}
{#7
    my %params = (
                    file => 't/sample.data', 
                    engine => 'all', 
                  );

    my $des = Devel::Examine::Subs->new(%params);
    
    my $all = $des->run(\%params);

    ok ( ref($all) eq 'ARRAY', "calling the 'all' engine through run() returns an aref" );
    is ( @$all, 11, "'all' engine returns the proper count of subs through run()" );
    ok ( ref($all) eq 'ARRAY', "all engine does the right thing through run() with no search" );
}
{#8

    my $des = Devel::Examine::Subs->new();

    my $all = $des->all(
                file => 't/sample.data', 
                engine => 'all',
            );

    ok ( ref($all) eq 'ARRAY', "legacy all() does the right thing sending {engine=>'all'}" );
}
{#9

    my $des = Devel::Examine::Subs->new();

    my $all = $des->all(file => 't/sample.data');

    ok ( ref($all) eq 'ARRAY', "legacy all() sets the engine param properly" );
}


{
    my $des = Devel::Examine::Subs->new( file => 't/test/files' );
    my $struct = $des->all();

    is (keys %$struct, 3, "all() directory has the correct number of keys");

    delete $struct->{'t/test/files/module.pm'};

    for (keys %$struct){
        ok (ref $struct->{$_} eq 'ARRAY', "all() directory files contain arefs" );
        is (@{$struct->{$_}}, 11, "all() directory contains the correct number of elements" );
    }
}
{
     my $des = Devel::Examine::Subs->new();

     my $all = $des->all(file => 't/sample.data');

     my @manual_order = qw(
                one one_inner one_inner_two
                two three four function
                five six seven eight
              );

     my @order = $des->order;

     my $i = 0;

     for (@manual_order){
         is ($_, $order[$i], "order() seems to do the right thing");
         $i++;
     }

     $i = 0;

     for (@$all){
         is ($_, $order[$i], "all() sorts the subs in proper order");
         $i++;
     }
}
