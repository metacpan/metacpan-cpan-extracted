use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;

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

    tie my $d, 'IPC::Shareable', 'obj', { destroy => 0 };
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

    my $s = tie my $d, 'IPC::Shareable', 'obj', { create => 'yes', destroy => 'yes' };

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

done_testing();

