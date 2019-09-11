use strict;
use warnings;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
use Test::More;

my $cli;
my $result = {};


{
    package CLI_Opts::Test;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [
                'foo|f' => doc => "foo flag!",
            ],
            [
                'bar|b' => doc => "bar flag!",
            ],
            [
                'int|i=i' => doc => "integer!",
            ],
            [
                'str|s=s' => doc => "string!",
            ],
            [
                'config|c=s@' => doc => "config files",
            ],
            [
                'nums|n=i@' => doc => "numbers",
            ],
        ],
    ;

    sub cmd_default {
        my ( $c ) = @_;
        $cli = $c;
        $result->{default} = 'default';
    }

    sub cmd_hello {
        my ( $c, @args ) = @_;
        $cli = $c;
        $result->{hello} = [@args];
    }

}


{
    package CLI_Opts::Test2;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [
                'foo|f=s' => doc => "foo!", required => 1,
            ],
            [
                'bar|b=s' => doc => "bar!", required => 1, default => 'a',
            ],
            [
                'baz|z=i' => doc => "baz!", default => 123,
            ],
        ],
    ;
    sub cmd_default {
        my ( $c ) = @_;
        $cli = $c;
    }
}


CLI_Opts::Test->run([qw/-fb/]);
is_deeply( $cli, default_state(foo => 1, bar => 1) );

CLI_Opts::Test->run([qw/--int 123/]);
is_deeply( $cli, default_state('int' => 123) );

eval { CLI_Opts::Test->run([qw/--int abc/]) };
like($@, qr/option `int` takes integer/);

eval { CLI_Opts::Test->run([qw/-i abc/]) };
like($@, qr/option `int` takes integer/);

CLI_Opts::Test->run([qw/--str abc/]);
is_deeply( $cli, default_state('str' => "abc") );

CLI_Opts::Test->run([qw/-c abc -c def/]);
is_deeply( $cli, default_state(config => [qw/abc def/]) );

CLI_Opts::Test->run([qw/-n 123 -n 456/]);
is_deeply( $cli, default_state(nums => [qw/123 456/]) );

eval { CLI_Opts::Test->run([qw/--nums 123 --nums abc/]) };
like($@, qr/option `nums` takes integer/);

eval { CLI_Opts::Test2->run([qw//]) };
like($@, qr/foo is required./);

CLI_Opts::Test2->run([qw/--foo hoge/]);
is_deeply( $cli, default_state(foo => 'hoge', bar => 'a', baz => 123) );


done_testing;


sub default_state {
    my (%args) = @_;
    $result = {};
    return {
        %args,
        '_cmd' => ($cli->{_cmd} // 'default'),
    };
}


