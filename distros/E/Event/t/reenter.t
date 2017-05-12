# deep -*- perl -*-
BEGIN {
    if ($^O eq 'MSWin32') {
	print "1..0 # skipped; Win32 supports select() only on sockets\n";
	exit;
    }
}

use Test; plan test => 7;
use Event qw(loop unloop one_event all_running);

#$Event::DebugLevel = 4;

# deep recursion
my $rep;
$rep = Event->io(fd => \*STDOUT, poll => 'w', cb => sub { loop() });
do {
    local $SIG{__WARN__} = sub {};  # COMMENT OUT WHEN DEBUGGING!
    ok !defined loop();
};
ok $rep->is_running, 0;


# simple nested case
my $nest=0;
$rep->cb(sub {
    return if ++$nest > 10;
    one_event();
});
ok one_event();


# a bit more complex nested exception
$nest=0;
$rep->cb(sub {
    die 10 if ++$nest > 10;
    one_event() or die "not recursing";
});
$Event::DIED = sub {
    my $e = shift;
    ok $e->w, $rep;
    ok $e->w, all_running();
    my @all = all_running;
    ok @all, $nest;
    unloop();
};
loop();
ok 1;
