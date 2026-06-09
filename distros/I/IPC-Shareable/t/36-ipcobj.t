use warnings;
use strict;

use Carp;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(
    assert_clean_process barrier_new barrier_release barrier_wait unique_glue
);


my $t  = 1;
my $ok = 1;

{
    package Dummy;

    sub new {
        my $d = {
            _first  => undef,
            _second => undef,
        };
        return bless $d => shift;
    }

    sub first {
        my $self = shift;
        $self->{_first} = shift if @_;
        return $self->{_first};
    }

    sub second {
        my $self = shift;
        $self->{_second} = shift if @_;
        return $self->{_second};
    }
}

# A pipe barrier (see IPCShareableTest::barrier_new) replaces the old
# SIGALRM/sleep handshake and its lost-wakeup race.

my $ready = barrier_new();   # parent -> child: segment created

my $pid = fork;
defined $pid or die "Cannot fork : $!";

if ($pid == 0) {
    # child

    barrier_wait($ready);

    tie my $d, 'IPC::Shareable', unique_glue('obj'), { destroy => 0 , serializer => 'storable' };
#    is ref($d), 'Dummy', "child: shared var has object ok";

#    is $d->first(), 'foobar', "child: shared obj first() returns ok";
#    is $d->second(), 'barfoo', "child: shared obj second() returns ok";
#    is $d->first('foo'), 'foo', "shared obj first() returns ok, again";
#    is $d->second('bar'), 'bar', "shared obj second() returns ok, again";

    $d->first('kid did');
    $d->second('this');

    exit;

} else {
    # parent

    my $s = tie my $d, 'IPC::Shareable', unique_glue('obj'), { create => 1, destroy => 1 , serializer => 'storable' };

#    my $id = $s->{_shm}->{_id};

    $d = { };
    $d->{_first} = 'foobar';
    $d->{_second} = 'barfoo';

    $d = Dummy->new;
    $d->first('foobar');
    $d->second('barfoo');

    barrier_release($ready);
    waitpid($pid, 0);

    is $d->first(), 'kid did', "parent: shared obj first() returns ok";
    is $d->second(), 'this', "parent: shared obj second() returns ok";

    IPC::Shareable->clean_up_all;

    is defined $d, '', "parent: after clean_up_all(), everything's gone";
}

IPC::Shareable::_end;

assert_clean_process();

done_testing();

