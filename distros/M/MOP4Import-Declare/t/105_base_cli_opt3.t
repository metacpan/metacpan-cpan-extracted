use strict;
use warnings;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
use Test::More;
use Test::Output;

my $cli;

{
    package CLI_Opts::Test;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [
                'foo|f=s' => doc => "Foo!", required => 1, default => "abc",
            ],
            [
                'bar|b=i' => doc => "bar!", required => 1,
            ],
            [
                'baz|z=i' => doc => "baz!", required => 1, default => 123, for_subcmd => 'hello',
            ],
            [
                'huga|h' => doc => "huga!", for_subcmd => 1,
            ],
            [
                'hoge|H=i' => doc => "huga!", for_subcmd => ['hello'],
            ],
            [
                'poo|p=s' => doc => "for hello or eat", for_subcmd => ['hello', 'eat'],
            ],
            [
                'pee|P=s' => doc => "pee!", required => 1, for_subcmd => 'fly',
            ],
        ],
    ;
    sub cmd_default {
        my ( $c, @args ) = @_;
        $cli = $c;
        print "default", @args;
    }
    sub cmd_hello {
        my ( $c, @args ) = @_;
        $cli = $c;
        print "Hello ", @args;
    }
    sub cmd_eat {
        my ( $c, @args ) = @_;
        $cli = $c;
        print "Eat ", @args;
    }
    sub cmd_fly {
        my ( $c, @args ) = @_;
        $cli = $c;
        print "Fly ", @args;
    }
}

eval { CLI_Opts::Test->new() };
like($@, qr/bar is required./, 'bar is required');

eval { CLI_Opts::Test->new(bar => 'hoge') };
like($@, qr/`bar` takes integer/, 'bar takes integer');

$cli = CLI_Opts::Test->new(bar => 456);
is_deeply( $cli, default_state(bar => 456) );


stdout_is( sub { $cli->invoke('hello') }, 'Hello ' );
is_deeply( $cli, default_state(_cmd => 'hello', baz => 123, bar => 456) );

stdout_is( sub { $cli->invoke('fly', pee => 'pee') }, 'Fly peepee' ); # TODO: この動作は変更したい
is_deeply( $cli, default_state(_cmd => 'fly', pee => 'pee', baz => 123, bar => 456) );


done_testing;

sub default_state {
    my (%args) = @_;
    return {
        'foo' => 'abc',
        %args,
    };
}
