#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IPC::PrettyPipe;

{
    package ExtendRenderer;
    use Moo;
    extends 'IPC::PrettyPipe::Render::Template::Tiny';
}

is(
    exception {
        my $p = IPC::PrettyPipe->new( renderer => 'ExtendRenderer' );
        $p->renderer;
    },
    undef,
    "extend existing renderer"
);

{
    package NewRenderer;
    use Moo;

    sub render { }
    with 'IPC::PrettyPipe::Renderer';
}

is(
    exception {
        my $p = IPC::PrettyPipe->new( renderer => 'NewRenderer' );
        $p->renderer;
    },
    undef,
    "extend existing renderer"
);

is(
    exception {
        my $p = IPC::PrettyPipe->new( renderer => NewRenderer->new );
        $p->renderer;
    },
    undef,
    "object"
);



done_testing;
