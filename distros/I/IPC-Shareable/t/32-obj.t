use warnings;
use strict;

use Carp;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
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

tie my $d, 'IPC::Shareable', { destroy => 'yes' , serializer => 'storable' };

$d = Dummy->new or undef $ok;
is ref($d), 'Dummy', "shared var is a Dummy object ok";

is $d->first('first'), 'first', "shared obj first() returns ok";
is $d->second('second'), 'second', "shared obj second() returns ok";

is $d->first('foo'), 'foo', "shared obj first() returns ok, again";
is $d->second('bar'), 'bar', "shared obj second() returns ok, again";

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();

