#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( "Unable to load HTML::Object::DOM" );
    use_ok( 'HTML::Object::DOM::Node' ) || BAIL_OUT( "Unable to load HTML::Object::DOM::Node" );
    use_ok( 'HTML::Object::Event', ':phase' ) || BAIL_OUT( "Unable to load HTML::Object::Event" );
};

use strict;
use warnings;

my $parser = HTML::Object::DOM->new;
my $html = <<EOT;
<div id="div1">
    <div id="div2"></div>
</div>
EOT
my $doc = $parser->parse_data( $html ) || BAIL_OUT( "Error parsing data: " . $parser->error );

my $div1 = $doc->getElementById( 'div1' );
my $div2 = $doc->getElementById( 'div2' );
# $div1->debug( $DEBUG );
# $div2->debug( $DEBUG );
isa_ok( $div1, 'HTML::Object::DOM::Node' );
isa_ok( $div2, 'HTML::Object::DOM::Node' );
SKIP:
{
    if( !defined( $div1 ) || !defined( $div2 ) )
    {
        skip( 'cannot get div1 or div2 element object', 7 );
    }
    my @elems = ();
    my( $eh1, $eh2 );
    $eh1 = $div1->addEventListener('click', sub
    {
        my $e = shift( @_ );
        push( @elems, $div1->id );
        isa_ok( $e => 'HTML::Object::Event' );
        is( $e->currentTarget, $div1, 'current target is div1' );
    }, { capture => 1 });
    $eh2 = $div2->addEventListener('click', sub
    {
        my $e = shift( @_ );
        push( @elems, $div2->id );
        isa_ok( $e => 'HTML::Object::Event' );
        is( $e->currentTarget, $div2, 'current target is div2' );
    }, { capture => 0 });
    isa_ok( $eh1, 'HTML::Object::EventListener' );
    isa_ok( $eh2, 'HTML::Object::EventListener' );

    my $elem = $div2->trigger('click');
    isa_ok( $elem, 'HTML::Object::DOM::Node' );
    is( $elem, $div2, 'trigger return element' );
    is( "@elems", "div1 div2", 'capture sequence' );

    if( !defined( $eh1 ) || !defined( $eh2 ) )
    {
        skip( 'unable to create an event listener for div1 or div2', 2 );
    }
    # same as $elem->removeEventListener( $type, $handler, $options_hashref ), but simpler
    # $eh1->debug( $DEBUG );
    $eh1->remove || diag( "Error trying to remove event listener for div1: ", $eh1->error );
    $eh2->remove || diag( "Error trying to remove event listener for div2: ", $eh2->error );
    @elems = ();

    is( $div1->hasEventListener, 0, 'remove for div1' );
    is( $div2->hasEventListener, 0, 'remove for div2' );
    
    # Test with all events in bubbling phase only
    $eh1 = $div1->addEventListener('click', sub
    {
        my $e = shift( @_ );
        push( @elems, $div1->id );
        isa_ok( $e => 'HTML::Object::Event' );
        is( $e->currentTarget, $div1, 'current target is div1' );
    }, { capture => 0 });
    $eh2 = $div2->addEventListener('click', sub
    {
        my $e = shift( @_ );
        push( @elems, $div2->id );
        isa_ok( $e => 'HTML::Object::Event' );
        is( $e->currentTarget, $div2, 'current target is div2' );
    }, { capture => 0 });
    $elem = $div2->trigger('click');
    is( "@elems", "div2 div1", 'bubbling sequence' );
};

my $event = HTML::Object::Event->new( 'click' );
SKIP:
{
    if( !defined( $event ) )
    {
        skip( 'unable to create an event', 19 );
    }
    # $event->debug( $DEBUG );
    ok( $event->bubbles, 'bubbles' );
    ok( $event->cancelable, 'cancelable' );
    ok( !$event->cancelled, 'cancelled' );
    ok( !$event->composed, 'composed' );
    is( $event->currentTarget, undef, 'currentTarget' );
    ok( !$event->defaultPrevented, 'defaultPrevented' );
    is( $event->eventPhase, 0, 'eventPhase' );
    ok( $event->isTrusted, 'isTrusted' );
    is( $event->target, undef, 'target' );
    my $ts = $event->timeStamp;
    like( $ts, qr/^(\d+)\.(\d+)$/, 'timeStamp' );
    is( $event->type, 'click', 'type' );
    is( $event->composedPath, undef, 'composedPath' );
    $event->preventDefault;
    is( $event->defaultPrevented, 1, 'preventDefault' );
    $event->stopImmediatePropagation;
    is( $event->cancelled, 2 );
    $event->stopPropagation;
    is( $event->cancelled, 1 );
    ok( defined( &NONE ), 'constant NONE' );
    ok( defined( &CAPTURING_PHASE ), 'constant CAPTURING_PHASE' );
    ok( defined( &AT_TARGET ), 'constant AT_TARGET' );
    ok( defined( &BUBBLING_PHASE ), 'constant BUBBLING_PHASE' );
};

done_testing();

__END__

