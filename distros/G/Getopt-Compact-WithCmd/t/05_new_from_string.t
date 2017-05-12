use strict;
use warnings;
use Test::More;
use Test::Requires 'Text::ParseWords';

use File::Basename qw/basename/;
use Getopt::Compact::WithCmd;

subtest 'ok' => sub {
    my $go = Getopt::Compact::WithCmd->new_from_string('--foo bar',
        global_struct => {
            foo => { type => '!' },
        },
    );
    is $go->opts->{foo}, 1;
    is_deeply $go->args, [qw/bar/];
};

subtest 'fail' => sub {
    eval { Getopt::Compact::WithCmd->new_from_string() };
    like $@, qr/Usage: Getopt::Compact::WithCmd->new_from_string\(\$str, %options\)/;
};

done_testing;
