#!./perl -w

use Test; plan test => 10;
use Event;
require Event::generic;

my $src = Event::generic::Source->new;
ok $src;

my $w0 = Event->generic(parked => 1);
ok $w0;
eval { $w0->source(undef); };
ok $@, "";
eval { $w0->source($src); };
ok $@, "";
eval { $w0->source(123); };
ok $@, qr/not a reference/;
eval { $w0->source(\123); };
ok $@, qr/not a thing/;
eval { $w0->source($w0); };
ok $@, qr/Can't find event magic/;

sub second_cb($) {
	my($e) = @_;
	ok $e->data, 456;
	$e->w->stop;
}
$w0->cb(sub($) {
	my($e) = @_;
	ok $e->data, 123;
	Event->generic(source => $src, cb => \&second_cb);
	$e->w->cb(\&second_cb);
	$src->event(456);
});
$w0->start;
$src->event(123);
Event::loop;

