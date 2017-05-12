# stop -*-perl-*- ?

use Carp;# 'verbose';
use Test; plan tests => 7;
use Event qw(all_running loop unloop sweep);
# $Event::DebugLevel = 3;

my $die = Event->idle(cb => sub { die "died\n" }, desc => 'killer');

my $status = 'ok';
$Event::DIED = sub {
    my ($e,$why) = @_;

    ok $e->w->desc, 'killer';
    chop $why;
    ok $why, 'died';

    if ($Event::Eval == 0) {
	$Event::Eval = 1;
	$die->again
    } elsif ($Event::Eval == 1) {
	unloop $status;
	$Event::Eval = 0;
    }
};

ok loop(), $status;

#-----------------------------

{
    local $Event::DIED = sub { die };
    local $SIG{__WARN__} = sub {
	ok $_[0], '/Event::DIED died/';
    };
    $die->now;
    sweep();
}
{
    local $Event::DIED = \&Event::verbose_exception_handler;
    local $SIG{__WARN__} = sub {
	ok $_[0], '/died/';
    };
    $die->now;
    sweep();
}
