# Perl implementation of the Hello Chipmunk example from the Chipmunk docs
use Test::More;
use strict;
use warnings;
use Games::Chipmunk;

use constant DEBUG => 0;

# cpVect is a 2D vector and cpv() is a shortcut for initializing them.
my $gravity = cpv(0, -100);

# Create an empty space.
my $space = cpSpaceNew();
cpSpaceSetGravity($space, $gravity);

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

# For our tests, we want to check that there was some kind of movement.
# Problem is, there might not be enough acceleration at the start to actually 
# move anything.  We'll just do a few runs to prime the system.
cpSpaceStep($space, $timeStep) for 1 .. 5;
my $iterations = 0;
for(my $time = $timeStep * 5; $time < 2; $time += $timeStep){
    my $pos = cpBodyGetPosition($ballBody);
    my $vel = cpBodyGetVelocity($ballBody);
    diag( sprintf(
        'Time is %5.2f. ballBody is at (%5.2f, %5.2f). Its velocity is (%5.2f, %5.2f)',
        $time, $pos->x, $pos->y, $vel->x, $vel->y
    ) ) if DEBUG;

    cmp_ok( $pos->y, '!=', $last_y, "Y has moved" );
    $last_y = $pos->y;

    cpSpaceStep($space, $timeStep);
    $iterations++;
}

cmp_ok( $iterations, '>', 0, "Iterated over code" );

# Clean up our objects and exit!
cpShapeFree($ballShape);
cpBodyFree($ballBody);
cpShapeFree($ground);
cpSpaceFree($space);

done_testing();
