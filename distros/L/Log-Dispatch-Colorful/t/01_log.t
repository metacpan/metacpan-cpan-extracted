use strict;
use warnings;

use Test::More tests => 4;

use Log::Dispatch;
use Log::Dispatch::Colorful;
use Term::ANSIColor;
use IO::Scalar;

my $dispatcher = Log::Dispatch->new;

my $err;
tie *STDERR, 'IO::Scalar', \$err;
my $colorful = Log::Dispatch::Colorful->new(
    name      => 'screen',
    min_level => 'debug',
    stderr    => 1,
    color     => {
        info  => { text => 'green', },
        debug => {
            text       => 'red',
            background => 'white',
        },
        error => {
            text       => 'yellow',
            background => 'red',
        },
    }
);

$dispatcher->add($colorful);

$dispatcher->error('eeeeeeerrrrrrrrrrroooooooorrrrrrrr');

ok $err =~ m{eeeeeeerrrrrrrrrrroooooooorrrrrrrr}xms, 'colorful error';

my $data = { foo => 'bar' };
is ref $data, 'HASH';

$dispatcher->debug($data);

ok $err =~ m!'foo' \s+ => \s+ 'bar'!xms, 'no debug';
is ref $data, 'HASH';

