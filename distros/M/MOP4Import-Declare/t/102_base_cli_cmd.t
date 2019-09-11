use strict;
use warnings;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
use Test::More;
use Test::Output;

my $cli;

{
    package CLI_Opts::TestA;
    use MOP4Import::Base::CLI_Opts -as_base;
    sub cmd_help {
        my ( $c, @args ) = @_;
        print "Usage";
    }
}


{
    package CLI_Opts::TestB;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [ 'help|z' => doc => "help!", command => 'help' ],
        ],
    ;
    sub cmd_help {
        my ( $c, @args ) = @_;
        print "Usage";
    }
}


{
    package CLI_Opts::TestC;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [
                'hello|h=s' => doc => "Hello!", command => 'hello',
            ],
        ],
    ;
    sub cmd_help {
        my ( $c, @args ) = @_;
        print "Usage";
    }
    sub cmd_hello {
        my ( $c, @args ) = @_;
        print "Hello ", @args;
    }
}


{
    package CLI_Opts::TestD;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [
                'h=s' => doc => "Hello!", command => 'foo',
            ],
        ],
    ;
    sub cmd_help {
        my ( $c, @args ) = @_;
        print "Usage";
    }
    sub cmd_foo {
        my ( $c, @args ) = @_;
        $cli = $c;
        print "Hello ", @args;
    }
}


{
    package CLI_Opts::TestE;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [
                'foo|f' => doc => "Foo!", command => 'foo',
            ],
        ],
    ;
    sub cmd_help {
        my ( $c, @args ) = @_;
        print "Usage";
    }
    sub cmd_foo {
        my ( $c, @args ) = @_;
        $cli = $c;
        print "foo";
    }
}

stdout_is( sub { CLI_Opts::TestA->run([qw//]); }, '' );
stdout_is( sub { CLI_Opts::TestB->run([qw//]); }, '' );
stdout_is( sub { CLI_Opts::TestC->run([qw//]); }, '' );

stdout_is( sub { CLI_Opts::TestA->run([qw/--help/]); }, 'Usage' );
stdout_is( sub { CLI_Opts::TestA->run([qw/-h/]); }, 'Usage' );

stdout_is( sub { CLI_Opts::TestB->run([qw/--help/]); }, 'Usage' );
stdout_is( sub { CLI_Opts::TestB->run([qw/-z/]); }, 'Usage' );
eval { CLI_Opts::TestB->run([qw/-h/]) };
like($@, qr/Invalid option format/, 'delete -h');

stdout_is( sub { CLI_Opts::TestC->run([qw/--help/]); }, 'Usage' );
stdout_is( sub { CLI_Opts::TestC->run([qw/--hello 123/]); }, 'Hello 123' );
stdout_is( sub { CLI_Opts::TestC->run([qw/-h abc/]); }, 'Hello abc' );

stdout_is( sub { CLI_Opts::TestD->run([qw/--help/]); }, 'Usage' );
stdout_is( sub { CLI_Opts::TestD->run([qw/-h abc/]); }, 'Hello abc' );
is_deeply( $cli->{__cmd}, [qw/foo abc/] );

eval { CLI_Opts::TestD->run([qw/-h abc -h def/]) };
like($@, qr/command invoking option was already called/, 'duplicated call');

stdout_is( sub { CLI_Opts::TestE->run([qw/--help/]); }, 'Usage' );
stdout_is( sub { CLI_Opts::TestE->run([qw/-h/]); }, 'Usage' );
stdout_is( sub { CLI_Opts::TestE->run([qw/--foo/]); }, 'foo' );


done_testing;

