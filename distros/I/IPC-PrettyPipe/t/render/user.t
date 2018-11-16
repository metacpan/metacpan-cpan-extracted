#! perl

use Test2::V0;

use IPC::PrettyPipe;

{
    package ExtendRenderer;
    use Moo;
    extends 'IPC::PrettyPipe::Render::Template::Tiny';
}

ok(
    lives {
        my $p = IPC::PrettyPipe->new( renderer => 'ExtendRenderer' );
        $p->renderer;
    },
    "extend existing renderer"
);

{
    package NewRenderer;
    use Moo;

    sub render { }
    with 'IPC::PrettyPipe::Renderer';
}

ok(
    lives {
        my $p = IPC::PrettyPipe->new( renderer => 'NewRenderer' );
        $p->renderer;
    },
    "extend existing renderer"
);

ok(
    lives {
        my $p = IPC::PrettyPipe->new( renderer => NewRenderer->new );
        $p->renderer;
    },
    "object"
);



done_testing;
