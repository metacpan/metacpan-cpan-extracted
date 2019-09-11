use strict;
use warnings;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
use Test::More;

my $cli;

{
    package CLI_Opts::Test;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [
                'foo|f=s' => doc => "Foo!", required => 1, default => "abc",
            ],
            [
                'bar|b=s' => doc => "bar!", required => 1,
            ],
        ],
    ;
    sub cmd_default {
        my ( $c, @args ) = @_;
        $cli = $c;
    }
}

eval { CLI_Opts::Test->run([qw//]) };
like($@, qr/bar is required./, 'bar is required');

CLI_Opts::Test->run([qw/--bar hoge/]);
is_deeply( $cli, default_state(foo => 'abc', bar => 'hoge') );

CLI_Opts::Test->run([qw/-b huga/]);
is_deeply( $cli, default_state(foo => 'abc', bar => 'huga') );

eval { CLI_Opts::Test->run([qw/--bar baz --foo/]) };
like($@, qr/foo is required./, 'foo is required');

eval { CLI_Opts::Test->run([qw/--bar baz -f/]) };
like($@, qr/foo is required./, 'foo is required');


done_testing;

sub default_state {
    my (%args) = @_;
    return {
        %args,
        '_cmd' => ($cli->{_cmd} // 'default'),
    };
}
