use strict;
use Test::More (tests => 16);
use Test::MockObject;

BEGIN
{
    use_ok("Event::Notify");
}

my $notify = Event::Notify->new;
ok( $notify );
isa_ok( $notify, "Event::Notify");

{ # Normal case, using notify()
    my $observer = Test::MockObject->new();
    $observer->mock('register', sub {
        my ($self, $subject) = @_;
        $subject->register_event($_, $self) for qw(foo bar baz);
    } );
    $observer->mock('notify', sub {
        my ($self, $event) = @_;
        like($event, qr/^foo|bar|baz$/);
    } );

    eval {
        $notify->register( $observer );
    };
    ok( !$@, "register() seems to work" );
    
    $notify->notify('foo');
    $notify->notify('bar');
    $notify->notify('baz');
    $notify->notify('quux'); # should not cause ok()

    $notify->clear_observers();
}

{ # Normal case, each using their own method. No notify() is provided
    my $observer = Test::MockObject->new();
    $observer->mock('register', sub {
        my ($self, $subject) = @_;
        $subject->register_event($_, $self, { method => $_ }) for qw(foo bar baz);
    } );

    foreach my $e (qw(foo bar baz)) {
        $observer->mock($e, sub {
            my ($self, $event) = @_;
            is($e, $event, "method $e was called for the appropriate event");
        } );
    }

    eval {
        $notify->register( $observer );
    };
    ok( !$@, "register() seems to work" );
    
    $notify->notify('foo');
    $notify->notify('bar');
    $notify->notify('baz');
    $notify->notify('quux'); # should not cause ok()
    $notify->clear_observers();
}

{ # Normal case. We're passing a coderef
    my $observer = sub { 
        my($event) = @_;
        like($event, qr/^foo|bar|baz$/, "proper event $event notified");
    };
    $notify->register_event( $_, $observer ) for qw(foo bar baz);

    $notify->notify('foo');
    $notify->notify('bar');
    $notify->notify('baz');
    $notify->notify('quux'); # should not cause ok()
    $notify->clear_observers();
}

{ # Bad cases. The object does not implement the specified method
    my $observer = Test::MockObject->new;
    eval {
        $notify->register_event('foo', $observer );
    };
    like( $@, qr/does not implement a notify\(\) method/, "properly croaks without notify()" );

    $observer->mock('notify', sub {});
    eval {
        $notify->register_event('foo', $observer, { method => 'foo' });
    };
    like( $@, qr/does not implement a foo\(\) method/, "properly croaks without foo()" );
    $notify->clear_observers();
}


