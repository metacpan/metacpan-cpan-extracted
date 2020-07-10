#! perl

use Test2::V0;

use IPC::PrettyPipe::DSL ':all';

subtest '|=' => sub {

    subtest 'pipe |= pipe' => sub {

        my $pipe = ppipe ppcmd 'foo';
        $pipe |= ppipe( ppcmd( 'goo' ) );

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
                            call cmd     => 'goo';
                        };
                    };
                };
            },
        );
    };

    subtest 'pipe |= cmd' => sub {

        my $pipe = ppipe ppcmd 'foo';
        $pipe |= ppcmd( 'goo' );

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
                            call cmd     => 'goo';
                        };
                    };
                };
            },
        );
    };
};

subtest '|' => sub {

    subtest 'pipe | pipe' => sub {

        my $pipe = ppipe( ppcmd 'foo' ) | ppipe( ppcmd 'goo' );

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

        my $pipe = ppcmd( 'foo' ) | ppipe( ppcmd 'goo' );

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
};

done_testing;
