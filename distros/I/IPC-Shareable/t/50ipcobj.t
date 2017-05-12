BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..6\n";
}

use strict;
use Carp;
use IPC::Shareable;

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
    # --- Child
    sleep unless $awake;
    my $d;

    ++$t;
    tie($d, 'IPC::Shareable', 'obj', { destroy => 0 })
	or undef $ok;
    $ok = (ref $d eq 'Dummy');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($d->first eq 'foobar');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($d->second eq 'barfoo');
    print $ok ? "ok $t\n" : "not ok $t\n";

    $d->first('kid did');
    $d->second('this');

    exit;
} else {
    # --- Parent
    my $d;
    my $s = tie($d, 'IPC::Shareable', 'obj', { create => 'yes', destroy => 'yes' })
	or undef $ok;
    my $id = $s->{_shm}->{_id};
    print $ok ? "ok $t\n" : "not ok $t\n";

    $d = { };
    $d->{_first} = 'foobar';
    $d->{_second} = 'barfoo';

    $d = Dummy->new;
    $d->first('foobar');
    $d->second('barfoo');

    kill ALRM => $pid;
    waitpid($pid, 0);

    $t += 3; # - Child did 3 test

    ++$t;
    $ok = ($d->first eq 'kid did');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($d->second eq 'this');
    print $ok ? "ok $t\n" : "not ok $t\n";

    IPC::Shareable->clean_up_all;
}

# --- Done!
exit;

