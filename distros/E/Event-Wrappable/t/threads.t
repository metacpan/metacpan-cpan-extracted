use strict;
use warnings;
use Scalar::Util;
use Event::Wrappable;
use Test::More ();
BEGIN {
    eval q{ use threads; use threads::shared; };
    if ( $@ ) {
        Test::More->import( skip_all=>"Threads not available" );
    }
    else {
        Test::More->import( tests => 8 );
    }
}

note("Starting up");

my $event_wrapper_counter = 0;

my $wrapped;
Event::Wrappable->wrap_events( sub {
    $wrapped = event { note("Wrapped event triggered"); };
}, sub {
    my( $listener ) = @_;
    return sub { ++ $event_wrapper_counter; $listener->() };
});

my $unwrapped = event { note("Unwrapped event triggered"); };

my $wrapped_id   = $wrapped->object_id;
my $wrapped_addr = refaddr $wrapped;

my $unwrapped_id   = $unwrapped->object_id;
my $unwrapped_addr = refaddr $unwrapped;

my $thr_wrapped_id :shared;
my $thr_wrapped_addr :shared;
my $thr_unwrapped_id :shared;
my $thr_unwrapped_addr :shared;

threads->create(sub {
    $thr_wrapped_addr   = refaddr $wrapped;
    $thr_wrapped_id     = $wrapped->object_id;
    $thr_unwrapped_addr = refaddr $unwrapped;
    $thr_unwrapped_id   = $unwrapped->object_id;

})->join;

isnt( $thr_wrapped_addr, $wrapped_addr, "Threading dups our wrapped object" );
is(   $thr_wrapped_id, $wrapped_id, "Our wrapped object ids survive threading" );

isnt( $thr_unwrapped_addr, $unwrapped_addr, "Threading dups our unwrapped object" );
is(   $thr_unwrapped_id, $unwrapped_id, "Our unwrapped object ids survive threading" );


$wrapped->();
is( $event_wrapper_counter, 1, "Event wrapper triggered" );

$unwrapped->();
is( $event_wrapper_counter, 1, "Removing event wrapper worked" );

$wrapped->();
is( $event_wrapper_counter, 2, "Event wrapper triggered again" );

is( ref($wrapped), "Event::Wrappable", "Returned event sub is blessed");
