# -*-perl-*-

use Test; plan tests => 6;
use Event qw(loop);

sub step1 {
    my ($e) = @_;
    ok $e->got, 't';
    $e->w->timeout_cb(undef);
}

sub step2 {
    my ($e) = @_;
    ok $e->got, 't';
    $e->w->cancel;
}

Event->io(timeout => .1, timeout_cb => \&step1, cb => \&step2);

sub method {
    step1($_[1]);
}

Event->io(timeout => .1, timeout_cb => ['main','method'],
	  cb => \&step2);

Event->io(timeout => .1, timeout_cb => [bless([],'main'),'method'],
	  cb => \&step2);

loop;
