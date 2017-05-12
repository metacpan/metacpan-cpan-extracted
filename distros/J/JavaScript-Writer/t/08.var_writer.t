#!/usr/bin/env perl

use strict;
use warnings;
use JavaScript::Writer;
use Test::More;

plan tests => 6;

{
    # var a;
    my $js = JavaScript::Writer->new();

    $js->var('a');

    is "$js", "var a;", "variable declarition";
}

{
    # var a = 1;
    my $js = JavaScript::Writer->new();

    $js->var(a => 1);

    is "$js", "var a = 1;", "Scalar assignment";
}

{
    # var a = [ ... ]
    my $js = JavaScript::Writer->new();

    $js->var(a => [ 1, 3, 5, 7, 9 ]);

    is "$js", 'var a = [1,3,5,7,9];', "Array assignment";
}

{
    # var a = { ... }
    my $js = JavaScript::Writer->new();
    $js->var(a => { Lorem => 'Ipsum', 'Foo' => 0 });
    is "$js", 'var a = {"Foo":0,"Lorem":"Ipsum"};', "Hash assignment";
}

{
    # var a = function(){ ... }
    my $js = JavaScript::Writer->new();
    $js->var(salut => sub { $_[0]->alert("Nihao") });
    is "$js", 'var salut = function(){alert("Nihao");};', "function assigned to a var";
}

{
    # var a = function(foo,bar,baz){ ... }
    my $jsf = JavaScript::Writer::Function->new;
    $jsf->arguments(qw[foo bar baz]);
    $jsf->body( sub { $_[0]->alert("Nihao") } );

    my $js = JavaScript::Writer->new();
    $js->var(salut => $jsf);
    is "$js", 'var salut = function(foo,bar,baz){alert("Nihao");};', "anonymous function with arguments assigned to a var";
}
