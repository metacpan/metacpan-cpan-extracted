use warnings;
use strict;

use Carp;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;
use Test::SharedFork;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(
    assert_clean barrier_new barrier_release barrier_wait unique_glue
);

# serializer: storable
{
    my $ready = barrier_new();   # parent -> child: segment created

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # child

        barrier_wait($ready);

        tie my %h, 'IPC::Shareable', { key => unique_glue('testing25'), destroy => 0 , serializer => 'storable' };
        $h{a} = 'foo';
        exit;
    } else {
        # parent

        tie my %h, 'IPC::Shareable', {
            key     => unique_glue('testing25'),
            create  => 1,
            destroy => 1,
                    serializer => 'storable',
        };

        $h{a} = 'bar';
        is $h{a}, 'bar', "storable: in parent: parent set HV to 'bar' ok";

        barrier_release($ready);
        waitpid($pid, 0);

        is $h{a}, 'foo', "storable: in parent: child set HV to 'foo' ok";

        IPC::Shareable->clean_up_all;
    }
}

# serializer: json
{
    my $ready = barrier_new();   # parent -> child: segment created

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # child

        barrier_wait($ready);

        tie my %h, 'IPC::Shareable', { key => unique_glue('testing25j'), destroy => 0, serializer => 'json' };
        $h{a} = 'foo';
        exit;
    } else {
        # parent

        tie my %h, 'IPC::Shareable', {
            key        => unique_glue('testing25j'),
            create     => 1,
            destroy    => 1,
            serializer => 'json',
        };

        $h{a} = 'bar';
        is $h{a}, 'bar', "json: in parent: parent set HV to 'bar' ok";

        barrier_release($ready);
        waitpid($pid, 0);

        is $h{a}, 'foo', "json: in parent: child set HV to 'foo' ok";

        IPC::Shareable->clean_up_all;
    }
}

IPC::Shareable::_end;

assert_clean(unique_glue('testing25'), unique_glue('testing25j'));

done_testing();
