#! perl

use Test2::V0;

use IPC::PrettyPipe::DSL ':all';

subtest '|' => sub {

    subtest 'cmd | cmd' => sub {

        my $pipe = ppcmd( 'foo' ) | ppcmd( 'goo' );

        is(
            $pipe,
            object {
                prop blessed => 'IPC::PrettyPipe';
                call cmds    => object {
                    call elements => array {
                        item object {
                            prop blessed => 'IPC::PrettyPipe::Cmd';
                            call cmd     => 'foo'
                        };
                        item object {
                            prop blessed => 'IPC::PrettyPipe::Cmd';
                            call cmd     => 'goo'
                        };
                    };
                };
            },
        );
    };


    subtest 'pipe | cmd' => sub {

        my $pipe = ppipe( ppcmd 'foo' ) | ppcmd 'goo';

        is(
            $pipe,
            object {
                prop blessed => 'IPC::PrettyPipe';
                call cmds    => object {
                    call elements => array {
                        item object {
                            prop blessed => 'IPC::PrettyPipe::Cmd';
                            call cmd     => 'foo'
                        };
                        item object {
                            prop blessed => 'IPC::PrettyPipe::Cmd';
                            call cmd     => 'goo'
                        };
                    };
                };
            },
        );
    };

    subtest 'cmd | pipe' => sub {

        my $pipe = ppcmd( 'goo' ) | ppipe( ppcmd 'foo' );

        is(
            $pipe,
            object {
                prop blessed => 'IPC::PrettyPipe';
                call cmds    => object {
                    call elements => array {
                        item object {
                            prop blessed => 'IPC::PrettyPipe::Cmd';
                            call cmd     => 'goo';
                        };
                        item object {
                            prop blessed => 'IPC::PrettyPipe::Cmd';
                            call cmd     => 'foo';
                        };
                    };
                };
            },
        );
    };
};

done_testing;
