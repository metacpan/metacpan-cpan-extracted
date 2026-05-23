use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

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

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $pid = fork;
defined $pid or die "Cannot fork : $!";

if ($pid == 0) {
    # child

    sleep unless $awake;

    tie my $d, 'IPC::Shareable', 'obj', { destroy => 0 , serializer => 'storable' };
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

    my $s = tie my $d, 'IPC::Shareable', 'obj', { create => 1, destroy => 1 , serializer => 'storable' };

#    my $id = $s->{_shm}->{_id};

    $d = { };
    $d->{_first} = 'foobar';
    $d->{_second} = 'barfoo';

    $d = Dummy->new;
    $d->first('foobar');
    $d->second('barfoo');

    kill ALRM => $pid;
    waitpid($pid, 0);

    is $d->first(), 'kid did', "parent: shared obj first() returns ok";
    is $d->second(), 'this', "parent: shared obj second() returns ok";

    IPC::Shareable->clean_up_all;

    is defined $d, '', "parent: after clean_up_all(), everything's gone";
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();

