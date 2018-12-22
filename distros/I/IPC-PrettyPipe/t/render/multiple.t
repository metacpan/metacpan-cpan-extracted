#!perl

use Test2::V0;
use Test::Lib;

use IPC::PrettyPipe;


subtest 'default renderer' => sub {

    my $pipe     = IPC::PrettyPipe->new;
    my $renderer = $pipe->renderer;

    isa_ok(
        $renderer,
        ['IPC::PrettyPipe::Render::Template::Tiny'],
        'created correctly'
    );

};


subtest 'dynamic change to renderer' => sub {

    my $pipe = IPC::PrettyPipe->new;

    # force generation of default
    my $renderer = $pipe->renderer;

    # specify a new backend
    $pipe->renderer( 'Test' );
    my $nrenderer = $pipe->renderer;

    ref_is_not( $nrenderer, $renderer,
        'new renderer is not the same as the old one' );

    is(
        Scalar::Util::blessed( $nrenderer ),
        'IPC::PrettyPipe::Render::Test',
        'new renderer is created correctly'
    );

};

subtest 'clear renderer to get default again' => sub {

    my $pipe = IPC::PrettyPipe->new;

    # force generation of default
    my $renderer = $pipe->renderer;

    # clear out the current one.
    $pipe->_clear_renderer;

    # force generation of new one, based on defaulta
    my $nrenderer = $pipe->renderer;

    ref_is_not( $nrenderer, $renderer,
        'new renderer is not the same as the old one' );

    is(
        Scalar::Util::blessed( $nrenderer ),
        'IPC::PrettyPipe::Render::Template::Tiny',
        'new renderer is created correctly'
    );

};

done_testing;
