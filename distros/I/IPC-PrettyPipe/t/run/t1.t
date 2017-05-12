#!perl

use strict;
use warnings;

use Cwd;
use Test::Most;
use Test::File;
use Test::Trap qw[ :output(systemsafe) ];
use IO::File;
use File::pushd;

use Test::Builder;

use Devel::FindPerl 'find_perl_interpreter';

use File::Spec::Functions qw[ catfile ];

use IPC::PrettyPipe::DSL ':all';

use t::run::utils;


my $testcmd = catfile( getcwd, 't', 'run', 'testprog.pl' );
my @testcmd = ( find_perl_interpreter, $testcmd );


sub setup_prog {

    my $name = shift;
    my %fds  = @_;


    my %files;

    while ( my ( $fd, $mode ) = each %fds ) {

        my $file = $name . '.' . $fd;

        $fds{$fd} = {
            mode => $mode,
            file => $file,
        };

        next if $mode eq 'w';

        IO::File->new( $file, '>' )->say( "$name $fd" );

    }

    return %fds;
}



subtest 'single command; default executor, pipe stderr/out' => sub {

    my $dir = tempd();

    my @r = trap {

        my $pipe = ppipe [
            @testcmd,
            '--name'   => 'test1',
            '--logdir' => '.',
            1, 2,
        ];
#        $pipe->executor( 'IPC::Run' );
        $pipe->run;

    };

    test_run( $trap,
	expect_files => [ 'test1.log' ],
        stdout  => qr/test1 1/,
        stderr  => qr/test1 2/,
        logfile => [ 'test1.log',
		     {
		      name   => 'test1',
		      logdir => '.'
		     },
		   ],
    );



};

subtest 'single command; accessor executor, pipe stderr/out' => sub {

    my $dir = tempd();

    my @r = trap {

        my $pipe = ppipe [
            @testcmd,
            '--name'   => 'test1',
            '--logdir' => '.',
            1, 2,
        ];
        $pipe->executor( 'IPC::Run' );
        $pipe->run;

    };

    test_run( $trap,
	expect_files => [ 'test1.log' ],
        stdout  => qr/test1 1/,
        stderr  => qr/test1 2/,
        logfile => [ 'test1.log',
		     {
		      name   => 'test1',
		      logdir => '.'
		     },
		   ],
    );



};

subtest 'single command; 2>&1 ' => sub {

    my $dir = tempd();

    my @r = trap {

        my $pipe = ppipe [
            @testcmd,
            '--name'   => 'test1',
            '--logdir' => '.',
            '2>&1',
            1, 2,
        ];
        $pipe->executor( 'IPC::Run' );
        $pipe->run;

    };

    test_run( $trap,
	expect_files => [ 'test1.log' ],
        stdout  => [ qr/test1 1/, qr/test1 2/ ],
        logfile => [ 'test1.log',
		     {
		      name   => 'test1',
		      logdir => '.'
		     },
		   ],
    );



};

subtest 'single command; fd < ; fd >; pipe stderr/out capture' => sub {

    plan skip_all => 'redirecting FD>2 not possible on Win32'
	if $^O =~ /Win32/i;

    my $dir = tempd();

    my %fds = setup_prog( 'test1', 3 => 'r', 4 => 'w' );

    # IPC::Run (v 0.92) has a bug which affects sequential fd's see
    # https://rt.cpan.org/Ticket/Display.html?id=81851.
    #
    # ordering of 4> before 3< is necessary to circumvent bug.
    my @r = trap {

        my $pipe = ppipe
	  [
            @testcmd,
            '--name'   => 'test1',
            '--logdir' => '.',
            3,    'r',
            4,    'w',
            1,    2,
            '4>', $fds{4}{file},
            '3<', $fds{3}{file}
          ],
          '>',  'stdout',
          '2>', 'stderr';
        $pipe->executor( 'IPC::Run' );
        $pipe->run;

    };

    test_run( $trap,
        expect_files => [ 'test1.log',
			  'stdout', 'stderr', map { $_->{file} } values %fds ],
        logfile      => [ 'test1.log',
			  {
			   3      => ["test1 3\n"],
			   name   => 'test1',
			   logdir => '.'
			  },
			],
        file_contains_like => [
            $fds{4}{file} => qr/test1 4/,
            stdout        => qr/test1 1/,
            stderr        => qr/test1 2/
        ],
    );



};

subtest 'two commands; fd < ; fd >; pipe stderr/out capture' => sub {

    plan skip_all => 'redirecting FD>2 not possible on Win32'
	if $^O =~ /Win32/i;

    my $dir = tempd();

    my $name = 'test1';

    my %fds = ( test1 => { setup_prog(
				    'test1',
				    3 => 'r',
				    4 => 'w' ) },
		test2 => { setup_prog(
				    'test2',
				    3 => 'r',
				    4 => 'w' ) },
	      );

    # IPC::Run (v 0.92) has a bug which affects sequential fd's see
    # https://rt.cpan.org/Ticket/Display.html?id=81851.
    #
    # ordering of 4> before 3< is necessary to circumvent bug.
    my @r = trap {

        my $pipe = ppipe 
	  [
            @testcmd,
            '--name'   => 'test1',
            '--logdir' => '.',
            3,    'r',
            4,    'w',
            1,    2,
            '4>', $fds{test1}{4}{file},
            '3<', $fds{test1}{3}{file}
          ],
	  [
            @testcmd,
            '--name'   => 'test2',
            '--logdir' => '.',
            3,    'r',
            4,    'w',
            0, 1,
            '4>', $fds{test2}{4}{file},
            '3<', $fds{test2}{3}{file}
          ],
          '>',  'stdout',
          '2>', 'stderr';
        $pipe->executor( 'IPC::Run' );
        $pipe->run;

    };

    test_run( $trap,

        expect_files => [ 'test1.log', 'test2.log',
			  'stdout', 'stderr', map { $_->{file} } map { values %{$_} } values %fds ],
        logfile      => [ 'test1.log', {
					3      => ["test1 3\n"],
					name   => 'test1',
					logdir => '.'
				       },
			],
        logfile      => [ 'test2.log', {
					3      => ["test2 3\n"],
					0      => ["test1 1\n"],
					name   => 'test2',
					logdir => '.'
				       },
			],
        file_contains_like => [
            $fds{test1}{4}{file} => qr/test1 4/,
            $fds{test2}{4}{file} => qr/test2 4/,
            stdout        => qr/test1 1\ntest2 1\n/,
            stderr        => qr/test1 2/
        ],
    );



};


done_testing;
