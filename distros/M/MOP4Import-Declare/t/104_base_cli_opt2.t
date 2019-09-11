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

eval { CLI_Opts::Test->run([qw//]) };
like($@, qr/bar is required./, 'bar is required');

stdout_is( sub { CLI_Opts::Test->run([qw/--bar 123/]); }, 'default', 'default' );
is_deeply( $cli, default_state(bar => 123) );

stdout_is( sub { CLI_Opts::Test->run([qw/--bar 123 hello/]); }, 'Hello ' );
is_deeply( $cli, default_state(bar => 123, baz => 123) );

stdout_is( sub { CLI_Opts::Test->run([qw/--bar 123 hello --baz 456/]); }, 'Hello ' );
is_deeply( $cli, default_state(bar => 123, baz => 456) );

stdout_is( sub { CLI_Opts::Test->run([qw/--bar 123 hello -h blah/]); }, 'Hello blah' );
is_deeply( $cli, default_state(bar => 123, huga => 1, baz => 123) );

stdout_is( sub { CLI_Opts::Test->run([qw/--bar 321 hello -z 456 "--foo"/]); }, 'Hello "--foo"' );
is_deeply( $cli, default_state(bar => 321, baz => 456) );

stdout_is( sub { CLI_Opts::Test->run([qw/--bar 123 eat -p 456 banana/]); }, 'Eat banana' );
is_deeply( $cli, default_state( bar => 123, poo => 456) );

stdout_is( sub { CLI_Opts::Test->run([qw/--bar 123 eat -h apple/]); }, 'Eat apple' );
is_deeply( $cli, default_state( bar => 123, huga => 1) );

eval { CLI_Opts::Test->run([qw/--bar 123 eat -z 456 banana/]) };
like($@, qr/Invalid option format/, 'z is not for subcmd');

eval { CLI_Opts::Test->run([qw/--bar 123 fly/]) };
like($@, qr/pee is required/, 'pee is required');

stdout_is( sub { CLI_Opts::Test->run([qw/--bar 123 fly -P foo/]); }, 'Fly ' );
is_deeply( $cli, default_state( bar => 123, pee => 'foo') );


done_testing;

sub default_state {
    my (%args) = @_;
    return {
        'foo' => 'abc',
        '_cmd' => ($cli->{_cmd} // 'default'),
        %args,
    };
}
