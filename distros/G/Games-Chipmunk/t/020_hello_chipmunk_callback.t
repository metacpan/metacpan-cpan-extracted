# Perl implementation of the Hello Chipmunk example from the Chipmunk docs,
# using a callback func to update velocity
use Test::More;
use strict;
use warnings;
use Games::Chipmunk;

use constant DEBUG => 0;

# cpVect is a 2D vector and cpv() is a shortcut for initializing them.
my $gravity = cpv(0, -100);

# Create an empty space.
my $space = cpSpaceNew();

# Add a static line segment shape for the ground.
# We'll make it slightly tilted so the ball will roll off.
# We attach it to space->staticBody to tell Chipmunk it shouldn't be movable.
my $ground = cpSegmentShapeNew(
    cpSpaceGetStaticBody( $space ), cpv(-20, 5), cpv(20, -5), 0 );
cpShapeSetFriction($ground, 1);
cpSpaceAddShape($space, $ground);

# Now let's make a ball that falls onto the line and rolls off.
# First we need to make a cpBody to hold the physical properties of the object.
# These include the mass, position, velocity, angle, etc. of the object.
# Then we attach collision shapes to the cpBody to give it a size and shape.

my $radius = 5;
my $mass = 1;

# The moment of inertia is like mass for rotation
# Use the cpMomentFor*() functions to help you approximate it.
my $moment = cpMomentForCircle($mass, 0, $radius, $CPV_ZERO);

# The cpSpaceAdd*() functions return the thing that you are adding.
# It's convenient to create and add an object in one line.
my $ballBody = cpSpaceAddBody($space, cpBodyNew($mass, $moment));
cpBodySetPosition($ballBody, cpv(0, 15));

# Now we create the collision shape for the ball.
# You can create multiple collision shapes that point to the same body.
# They will all be attached to the body and move around to follow it.
my $ballShape = cpSpaceAddShape($space, cpCircleShapeNew($ballBody, $radius, $CPV_ZERO));
cpShapeSetFriction($ballShape, 0.7);

# Now that it's all set up, we simulate all the objects in the space by
# stepping forward through time in small increments called steps.
# It is *highly* recommended to use a fixed size time step.
my $timeStep = 1.0/60.0;
my $last_y = 0;

my $dt = 0;
my $vel_callback_count = 0;
my $vel_callback = sub {
    my ($body) = @_;
    diag( "Velocity update function called" ) if DEBUG;
    diag( "Body is: $body" ) if DEBUG;
    $vel_callback_count++;
    cpBodyUpdateVelocity( $body, $gravity, 0, $dt );
    return;
};
cpBodySetVelocityUpdateFunc( $ballBody, $vel_callback );
diag( "Set velocity update func" ) if DEBUG;

my $time = $timeStep * 5;
my $prev_time = $time;
diag( "Beginning time iterations" ) if DEBUG;
for(; $time < 2; $time += $timeStep){
    diag( "Time $time, dt $dt, prev time $prev_time" ) if DEBUG;
    my $pos = cpBodyGetPosition($ballBody);
    diag( "Got body position" ) if DEBUG;
    my $vel = cpBodyGetVelocity($ballBody);
    diag( "Got body velocity" ) if DEBUG;
    cpSpaceStep($space, $timeStep);
    diag( "Stepped" ) if DEBUG;
    $dt = $time - $prev_time;
    $prev_time = $time;
}

diag( "Completed time iterations" ) if DEBUG;
cmp_ok( $vel_callback_count, '>', 2,
    "Velocity update callback has been called at least twice" );

# Clean up our objects and exit!
cpShapeFree($ballShape);
cpBodyFree($ballBody);
cpShapeFree($ground);
cpSpaceFree($space);

done_testing();
