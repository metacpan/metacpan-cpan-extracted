#!perl

use strict;
use warnings;

use Test::Most;

use IPC::PrettyPipe;

use Safe::Isa;
use Scalar::Util ();

use lib 't';

subtest 'default renderer' => sub {

    my $pipe     = IPC::PrettyPipe->new;
    my $renderer = $pipe->renderer;

    is(
        Scalar::Util::blessed( $renderer ),
        'IPC::PrettyPipe::Render::Template::Tiny',
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

    isnt( $nrenderer, $renderer,
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

    isnt( $nrenderer, $renderer,
        'new renderer is not the same as the old one' );

    is(
        Scalar::Util::blessed( $nrenderer ),
        'IPC::PrettyPipe::Render::Template::Tiny',
        'new renderer is created correctly'
    );

};

done_testing;
