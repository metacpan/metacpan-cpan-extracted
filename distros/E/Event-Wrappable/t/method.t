use strict;
use warnings;
use Test::More tests => 7;
use Event::Wrappable;

my $event_wrapper_counter = 0;

{
    package EXAMPLE;
    use Test::More;
    sub new {
        my $class = shift;
        my $self = bless {}, $class;
        $self->{'event1'} = 0;
        $self->{'event2'} = 0;
        return $self;
    }
    sub test1 {
        my $self = shift;
        note("Wrapped event triggered");
        $self->{'event1'} ++;
    }
    sub test2 {
        my $self = shift;
        note("Unwrapped event triggered");
        $self->{'event2'} ++;
    }
}

my $obj = EXAMPLE->new;

my $wrapped;

Event::Wrappable->wrap_events( sub {
    $wrapped = event_method $obj=>"test1";
}, sub {
    my( $listener ) = @_;
    return sub { ++ $event_wrapper_counter; $listener->() };
});

my $unwrapped = event_method $obj=>"test2";

$wrapped->();
is( $event_wrapper_counter, 1, "Event wrapper triggered" );
is( $obj->{'event1'}, 1, "First event triggered" );

$unwrapped->();
is( $event_wrapper_counter, 1, "Removing event wrapper worked" );
is( $obj->{'event2'}, 1, "Second event triggered" );

$wrapped->();
is( $event_wrapper_counter, 2, "Event wrapper triggered again" );
is( $obj->{'event1'}, 2, "First event triggered again" );

is( ref($wrapped), "Event::Wrappable", "Returned event sub is blessed");
