package My::Test::Render;

use strict;
use warnings;

use Carp;
use Test2::V0;

use IPC::PrettyPipe::DSL ':all';

use Exporter 'import';

our @EXPORT = qw( test_renderer );

our %TESTS = (

    T1 => {
        label    => 'One command',
        input    => sub { ppipe ['cmd1'] },
    },
    T2 => {
        label    => 'One command w/ one arg',
        input    => sub { ppipe [ 'cmd1', 'a' ] },
    },
    T3 => {
        label    => 'One command w/ one arg + value, no sep',
        input    => sub { ppipe [ 'cmd1', [ 'a', 3 ] ] },
    },
    T4 => {
        label    => 'One command w/ one arg + blank value, no sep',
        input    => sub { ppipe [ 'cmd1', [ 'a', '' ] ] },
    },
    T5 => {
        label    => 'One command w/ one arg + value, sep',
        input    => sub { ppipe [ 'cmd1', argsep '=', [ 'a', 3 ] ] },
    },
    T6 => {
        label    => 'One command w/ one arg + value, pfx, no sep',
        input    => sub { ppipe [ 'cmd1', argpfx '-', [ 'a', 3 ] ] },
    },
    T7 => {
        label => 'One command w/ one arg + value, pfx, sep',
        input => sub {
            ppipe [
                'cmd1',
                argpfx '--',
                argsep '=',
                [ 'a', 3 ],
                [ 'b', 'is after a' ] ];
        },
    },
    T8 => {
        label    => 'One command w/ two args',
        input    => sub { ppipe [ 'cmd1', 'a', 'b' ] },
    },
    T9 => {
        label    => 'One command w/ one stream',
        input    => sub { ppipe [ 'cmd1', '>', 'file' ] },
    },
    T10 => {
        label => 'One command w/ one stream, one arg',
        input => sub {
            ppipe [ 'cmd1', '>', 'file', '-a' ];
        },
    },
    T11 => {
        label => 'One command w/ two streams',
        input => sub {
            ppipe [ 'cmd1', '>', 'stdout', '2>', 'stderr' ];
        },
    },
    T12 => {
        label => 'One command w/ two streams, one arg',
        input => sub {
            ppipe [ 'cmd1', '>', 'stdout', '2>', 'stderr', '-a' ];
        },
    },
    T13 => {
        label => 'Two commands',
        input => sub {
            ppipe ['cmd1'], ['cmd2'];
        },
    },
    T14 => {
        label => 'Two commands w/ args',
        input => sub {
            ppipe [ 'cmd1', '-a' ], [ 'cmd2', '-b' ];
        },
    },
    T15 => {
        label => 'Two commands w/ args and one stream apiece',
        input => sub {
            ppipe [ 'cmd1', '-a', '2>', 'stderr' ],
              [ 'cmd2', '-b', '>', 'stdout' ];
        },
    },
    T16 => {
        label => 'Two commands w/ args and two streams apiece',
        input => sub {
            ppipe [ 'cmd1', '-a', '2>', 'stderr', '3>', 'out put' ],
              [ 'cmd2', '-b', '>', 0, '2>', 'std err' ];
        },
    },
    T17 => {
        label => 'Two commands + pipe streams',
        input => sub {
            ppipe ['cmd1'], ['cmd2'], '>', 'stdout';
        },
    },
    T18 => {
        label => 'Two commands w/ args and one stream apiece + pipe streams',
        input => sub {
            ppipe [ 'cmd 1', '-a', '2>', 'std err' ],
              [ 'cmd 2', '-b', '>', 'std out' ],
              '>',
              0;
        },
    },
    T19 => {
        label => 'nested pipes, outer pipe streams, not merged',
        input => sub {
            IPC::PrettyPipe->new(
                cmds => [
                    [ 'cmd 1', '-a', '2>', 'std err' ],
                    ppipe [ 'cmd 2', '-b', '>', 'std out' ],
                ],
                streams     => [ ppstream '>', 0 ],
                merge_pipes => 0,
            );
        },
    },
    T20 => {
        label => 'nested pipes, outer pipe streams, merged',
        input => sub {
            ppipe [ 'cmd 1', '-a', '2>', 'std err' ],
              ppipe( [ 'cmd 2', '-b', '>', 'std out' ] ),
              '>',
              0;
        },
    },
    T21 => {
        label => 'nested pipes, inner pipe streams',
        input => sub {
            ppipe   [ 'cmd 1', '-a', '2>', 'std err' ],
              ppipe [ 'cmd 2', '-b', '>',  'std out' ],
              '>',
              0;
        },
    },
);

sub test_renderer {

    my ( $renderer, $expected ) = @_;

    while ( my ( $id, $test ) = each %TESTS ) {

        defined ( my $exp = $expected->{$id} )
          or
          croak( "missing expected values for test $id\n" );

        my $pipe = $test->{input}->();

        subtest $test->{label} => sub {

                ok(
                    lives {
                        $pipe->renderer( $renderer )
                    },
                    "attach renderer"
                ) or diag $@;

                my $got = $pipe->render;
                is( $got, $exp, 'expected output' );
            };
        }
}

1;
