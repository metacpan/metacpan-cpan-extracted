#! perl

use strict;
use warnings;

use IPC::PrettyPipe;

use Test::More;
use Scalar::Util;

use Test::Lib;
use My::Tests;

sub new { IPC::PrettyPipe->new( @_ ); }

subtest 'default' => sub {

    my $pipe = new();

    is( Scalar::Util::blessed( $pipe->executor ),
        'IPC::PrettyPipe::Execute::IPC::Run', 'executor' );

    is( Scalar::Util::blessed( $pipe->renderer ),
        'IPC::PrettyPipe::Render::Template::Tiny', 'renderer' );
};

subtest 'class' => sub {

    my $pipe = new(
        executor => 'IPC::Run',
        renderer => 'Template::Tiny'
    );

    is( Scalar::Util::blessed( $pipe->executor ),
        'IPC::PrettyPipe::Execute::IPC::Run', 'executor' );

    is( Scalar::Util::blessed( $pipe->renderer ),
        'IPC::PrettyPipe::Render::Template::Tiny', 'renderer' );

};




done_testing;
