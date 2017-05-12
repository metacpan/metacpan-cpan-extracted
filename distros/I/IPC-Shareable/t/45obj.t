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

my $d;
tie $d, 'IPC::Shareable', { destroy => 'yes' } or
    undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

++$t;
$d = Dummy->new or undef $ok;
$ok = (ref $d eq 'Dummy');
print $ok ? "ok $t\n" : "not ok $t\n";

++$t;
$d->first('first');
$ok = ($d->first eq 'first');
print $ok ? "ok $t\n" : "not ok $t\n";

++$t;
$d->second('second');
$ok = ($d->second eq 'second');
print $ok ? "ok $t\n" : "not ok $t\n";

$d->first('foo');
$d->second('bar');

++$t;
$ok = ($d->first eq 'foo');
print $ok ? "ok $t\n" : "not ok $t\n";

++$t;
$ok = ($d->second eq 'bar');
print $ok ? "ok $t\n" : "not ok $t\n";

# --- Done!
exit;

