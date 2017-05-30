# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Games::Chipmunk;

use 5.008000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT =  qw(
	CP_ALLOW_PRIVATE_ACCESS
	CP_BUFFER_BYTES
	CP_VERSION_MAJOR
	CP_VERSION_MINOR
	CP_VERSION_RELEASE
	cpcalloc
	cpfree
	cprealloc
	cpvslerp
	cpvslerpconst
	cpvstr
    $CPV_ZERO
    cpv
    cpveql
    cpvadd
    cpvneg
    cpvsub
    cpvmult
    cpvdot
    cpvcross
    cpvperp
    cpvrperp
    cpvproject
    cpvforangle
    cpvtoangle
    cpvrotate
    cpvunrotate
    cpvlengthsq
    cpvlength
    cpvlerp
    cpvnormalize
    cpvnormalize_safe
    cpvclamp
    cpvlerpconst
    cpvdist
    cpvdistsq
    cpvnear
    cpfmax
    cpfmin
    cpfabs
    cpfclamp
    cpflerp
    cpflerpconst

    cpMessage
    cpMomentForCircle
    cpAreaForCircle
    cpMomentForSegment
    cpAreaForSegment
    cpMomentForPoly
    cpAreaForPoly
    cpCentroidForPoly
    cpMomentForBox
    cpMomentForBox2
    cpConvexHull
    cpArbiterGetRestitution
    cpArbiterSetRestitution
    cpArbiterGetFriction
    cpArbiterSetFriction
    cpArbiterGetSurfaceVelocity
    cpArbiterSetSurfaceVelocity
    cpArbiterGetUserData
    cpArbiterSetUserData
    cpArbiterTotalImpulse
    cpArbiterTotalKE
    cpArbiterIgnore
    cpArbiterGetShapes
    cpArbiterGetBodies
    cpArbiterGetContactPointSet
    cpArbiterSetContactPointSet
    cpArbiterIsFirstContact
    cpArbiterIsRemoval
    cpArbiterGetCount
    cpArbiterGetNormal
    cpArbiterGetPointA
    cpArbiterGetPointB
    cpArbiterGetDepth
    cpArbiterCallWildcardBeginA
    cpArbiterCallWildcardBeginB
    cpArbiterCallWildcardPreSolveA
    cpArbiterCallWildcardPreSolveB
    cpArbiterCallWildcardPostSolveA
    cpArbiterCallWildcardPostSolveB
    cpArbiterCallWildcardSeparateA
    cpArbiterCallWildcardSeparateB
    cpBBNew
    cpBBNewForExtents
    cpBBNewForCircle
    cpBBIntersects
    cpBBContainsBB
    cpBBContainsVect
    cpBBMerge
    cpBBExpand
    cpBBCenter
    cpBBArea
    cpBBMergedArea
    cpBBSegmentQuery
    cpBBIntersectsSegment
    cpBBClampVect
    cpBBWrapVect
    cpBBOffset
    cpBodyAlloc
    cpBodyInit
    cpBodyNew
    cpBodyNewKinematic
    cpBodyNewStatic
    cpBodyDestroy
    cpBodyFree
    cpBodyActivate
    cpBodyActivateStatic
    cpBodySleep
    cpBodySleepWithGroup
    cpBodyIsSleeping
    cpBodyGetType
    cpBodySetType
    cpBodyGetSpace
    cpBodyGetMass
    cpBodySetMass
    cpBodyGetMoment
    cpBodySetMoment
    cpBodyGetPosition
    cpBodySetPosition
    cpBodyGetCenterOfGravity
    cpBodySetCenterOfGravity
    cpBodyGetVelocity
    cpBodySetVelocity
    cpBodyGetForce
    cpBodySetForce
    cpBodyGetAngle
    cpBodySetAngle
    cpBodyGetAngularVelocity
    cpBodySetAngularVelocity
    cpBodyGetTorque
    cpBodySetTorque
    cpBodyGetRotation
    cpBodyGetUserData
    cpBodySetUserData
    cpBodySetVelocityUpdateFunc
    cpBodySetPositionUpdateFunc
    cpBodyUpdateVelocity
    cpBodyUpdatePosition
    cpBodyLocalToWorld
    cpBodyWorldToLocal
    cpBodyApplyForceAtWorldPoint
    cpBodyApplyForceAtLocalPoint
    cpBodyApplyImpulseAtWorldPoint
    cpBodyApplyImpulseAtLocalPoint
    cpBodyGetVelocityAtWorldPoint
    cpBodyGetVelocityAtLocalPoint
    cpBodyKineticEnergy
    cpBodyEachShape
    cpBodyEachConstraint
    cpBodyEachArbiter
    cpConstraintDestroy
    cpConstraintFree
    cpConstraintGetSpace
    cpConstraintGetBodyA
    cpConstraintGetBodyB
    cpConstraintGetMaxForce
    cpConstraintSetMaxForce
    cpConstraintGetErrorBias
    cpConstraintSetErrorBias
    cpConstraintGetMaxBias
    cpConstraintSetMaxBias
    cpConstraintGetCollideBodies
    cpConstraintSetCollideBodies
    cpConstraintGetPreSolveFunc
    cpConstraintSetPreSolveFunc
    cpConstraintGetPostSolveFunc
    cpConstraintSetPostSolveFunc
    cpConstraintGetUserData
    cpConstraintSetUserData
    cpConstraintGetImpulse
    cpConstraintIsDampedRotarySpring
    cpDampedRotarySpringAlloc
    cpDampedRotarySpringInit
    cpDampedRotarySpringNew
    cpDampedRotarySpringGetRestAngle
    cpDampedRotarySpringSetRestAngle
    cpDampedRotarySpringGetStiffness
    cpDampedRotarySpringSetStiffness
    cpDampedRotarySpringGetDamping
    cpDampedRotarySpringSetDamping
    cpDampedRotarySpringGetSpringTorqueFunc
    cpDampedRotarySpringSetSpringTorqueFunc
    cpConstraintIsDampedSpring
    cpDampedSpringAlloc
    cpDampedSpringInit
    cpDampedSpringNew
    cpDampedSpringGetAnchorA
    cpDampedSpringSetAnchorA
    cpDampedSpringGetAnchorB
    cpDampedSpringSetAnchorB
    cpDampedSpringGetRestLength
    cpDampedSpringSetRestLength
    cpDampedSpringGetStiffness
    cpDampedSpringSetStiffness
    cpDampedSpringGetDamping
    cpDampedSpringSetDamping
    cpDampedSpringGetSpringForceFunc
    cpDampedSpringSetSpringForceFunc
    cpConstraintIsGearJoint
    cpGearJointAlloc
    cpGearJointInit
    cpGearJointNew
    cpGearJointGetPhase
    cpGearJointSetPhase
    cpGearJointGetRatio
    cpGearJointSetRatio
    cpConstraintIsGrooveJoint
    cpGrooveJointAlloc
    cpGrooveJointInit
    cpGrooveJointNew
    cpGrooveJointGetGrooveA
    cpGrooveJointSetGrooveA
    cpGrooveJointGetGrooveB
    cpGrooveJointSetGrooveB
    cpGrooveJointGetAnchorB
    cpGrooveJointSetAnchorB
    cpHastySpaceNew
    cpHastySpaceFree
    cpHastySpaceSetThreads
    cpHastySpaceStep
    cpConstraintIsPinJoint
    cpPinJointAlloc
    cpPinJointInit
    cpPinJointNew
    cpPinJointGetAnchorA
    cpPinJointSetAnchorA
    cpPinJointGetAnchorB
    cpPinJointSetAnchorB
    cpPinJointGetDist
    cpPinJointSetDist
    cpConstraintIsPivotJoint
    cpPivotJointAlloc
    cpPivotJointInit
    cpPivotJointNew
    cpPivotJointNew2
    cpPivotJointGetAnchorA
    cpPivotJointSetAnchorA
    cpPivotJointGetAnchorB
    cpPivotJointSetAnchorB
    cpPolylineFree
    cpPolylineIsClosed
    cpPolylineSimplifyCurves
    cpPolylineSimplifyVertexes
    cpPolylineToConvexHull
    cpPolylineSetAlloc
    cpPolylineSetInit
    cpPolylineSetNew
    cpPolylineSetDestroy
    cpPolylineSetCollectSegment
    cpPolylineConvexDecomposition
    cpPolyShapeAlloc
    cpPolyShapeInit
    cpPolyShapeInitRaw
    cpPolyShapeNew
    cpPolyShapeNewRaw
    cpBoxShapeInit
    cpBoxShapeInit2
    cpBoxShapeNew
    cpBoxShapeNew2
    cpPolyShapeGetCount
    cpPolyShapeGetVert
    cpPolyShapeGetRadius
    cpConstraintIsRatchetJoint
    cpRatchetJointAlloc
    cpRatchetJointInit
    cpRatchetJointNew
    cpRatchetJointGetAngle
    cpRatchetJointSetAngle
    cpRatchetJointGetPhase
    cpRatchetJointSetPhase
    cpRatchetJointGetRatchet
    cpRatchetJointSetRatchet
    cpConstraintIsRotaryLimitJoint
    cpRotaryLimitJointAlloc
    cpRotaryLimitJointInit
    cpRotaryLimitJointNew
    cpRotaryLimitJointGetMin
    cpRotaryLimitJointSetMin
    cpRotaryLimitJointGetMax
    cpRotaryLimitJointSetMax
    cpShapeDestroy
    cpShapeFree
    cpShapeCacheBB
    cpShapeUpdate
    cpShapePointQuery
    cpShapeSegmentQuery
    cpShapesCollide
    cpShapeGetSpace
    cpShapeGetBody
    cpShapeSetBody
    cpShapeSetMass
    cpShapeGetDensity
    cpShapeSetDensity
    cpShapeGetMoment
    cpShapeGetArea
    cpShapeGetCenterOfGravity
    cpShapeGetBB
    cpShapeGetSensor
    cpShapeSetSensor
    cpShapeGetElasticity
    cpShapeSetElasticity
    cpShapeGetFriction
    cpShapeSetFriction
    cpShapeGetSurfaceVelocity
    cpShapeSetSurfaceVelocity
    cpShapeGetUserData
    cpShapeSetUserData
    cpShapeGetCollisionType
    cpShapeSetCollisionType
    cpShapeGetFilter
    cpShapeSetFilter
    cpCircleShapeAlloc
    cpCircleShapeInit
    cpCircleShapeNew
    cpCircleShapeGetOffset
    cpCircleShapeGetRadius
    cpSegmentShapeAlloc
    cpSegmentShapeInit
    cpSegmentShapeNew
    cpSegmentShapeSetNeighbors
    cpSegmentShapeGetA
    cpSegmentShapeGetB
    cpSegmentShapeGetNormal
    cpSegmentShapeGetRadius
    cpConstraintIsSimpleMotor
    cpSimpleMotorAlloc
    cpSimpleMotorInit
    cpSimpleMotorNew
    cpSimpleMotorGetRate
    cpSimpleMotorSetRate
    cpConstraintIsSlideJoint
    cpSlideJointAlloc
    cpSlideJointInit
    cpSlideJointNew
    cpSlideJointGetAnchorA
    cpSlideJointSetAnchorA
    cpSlideJointGetAnchorB
    cpSlideJointSetAnchorB
    cpSlideJointGetMin
    cpSlideJointSetMin
    cpSlideJointGetMax
    cpSlideJointSetMax
    cpSpaceAlloc
    cpSpaceInit
    cpSpaceNew
    cpSpaceDestroy
    cpSpaceFree
    cpSpaceGetIterations
    cpSpaceSetIterations
    cpSpaceGetGravity
    cpSpaceSetGravity
    cpSpaceGetDamping
    cpSpaceSetDamping
    cpSpaceGetIdleSpeedThreshold
    cpSpaceSetIdleSpeedThreshold
    cpSpaceGetSleepTimeThreshold
    cpSpaceSetSleepTimeThreshold
    cpSpaceGetCollisionSlop
    cpSpaceSetCollisionSlop
    cpSpaceGetCollisionBias
    cpSpaceSetCollisionBias
    cpSpaceGetCollisionPersistence
    cpSpaceSetCollisionPersistence
    cpSpaceGetUserData
    cpSpaceSetUserData
    cpSpaceGetStaticBody
    cpSpaceGetCurrentTimeStep
    cpSpaceIsLocked
    cpSpaceAddDefaultCollisionHandler
    cpSpaceAddCollisionHandler
    cpSpaceAddWildcardHandler
    cpSpaceAddShape
    cpSpaceAddBody
    cpSpaceAddConstraint
    cpSpaceRemoveShape
    cpSpaceRemoveBody
    cpSpaceRemoveConstraint
    cpSpaceContainsShape
    cpSpaceContainsBody
    cpSpaceContainsConstraint
    cpSpaceAddPostStepCallback
    cpSpacePointQuery
    cpSpacePointQueryNearest
    cpSpaceSegmentQuery
    cpSpaceSegmentQueryFirst
    cpSpaceBBQuery
    cpSpaceShapeQuery
    cpSpaceEachBody
    cpSpaceEachShape
    cpSpaceEachConstraint
    cpSpaceReindexStatic
    cpSpaceReindexShape
    cpSpaceReindexShapesForBody
    cpSpaceUseSpatialHash
    cpSpaceStep
    cpSpaceDebugDraw
    cpSpaceHashAlloc
    cpSpaceHashInit
    cpSpaceHashNew
    cpSpaceHashResize
    cpBBTreeAlloc
    cpBBTreeInit
    cpBBTreeNew
    cpBBTreeOptimize
    cpBBTreeSetVelocityFunc
    cpSweep1DAlloc
    cpSweep1DInit
    cpSweep1DNew
);
our @EXPORT_OK = @EXPORT;


our $VERSION = '0.6';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Games::Chipmunk::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Games::Chipmunk', $VERSION);

our $CPV_ZERO = _CPVZERO();



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Games::Chipmunk - Perl API for the Chipmunk 2D v7 physics library

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Games::Chipmunk;

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
    for(my $time = $timeStep * 5; $time < 2; $time += $timeStep){
        my $pos = cpBodyGetPosition($ballBody);
        my $vel = cpBodyGetVelocity($ballBody);
        $last_y = $pos->y;

        cpSpaceStep($space, $timeStep);
    }

    # Clean up our objects and exit!
    cpShapeFree($ballShape);
    cpBodyFree($ballBody);
    cpShapeFree($ground);
    cpSpaceFree($space);

=head1 DESCRIPTION

Chipmunk 2D is a physics library that supports fast, lightweight rigid body 
physics for games or other simulations.

This Perl module is a pretty straight implementation of the C library, so 
the Chipmunk API docs should give you most of what you need. The complete API 
is exported when you C<use> the module.

A few cavets:

=over 4

=item * The cpvzero global is accessible as C<$CPV_ZERO>

=item * Callback functions in the C<cpSpatialIndex> header are not implemented

=back

Callbacks elsewhere in the library can all take Perl functions. For example:

    cpBodySetVelocityUpdateFunc( $body, sub {
        my ($body, $gravity, $damping, $dt) = @_;
        cpBodyUpdateVelocity( $body, $gravity, 0, $dt );
        return;
    });

=head1 TODO

Write the callback function mappings inside C<cpSpatialIndex>

Convert to Dist::Zilla

=head1 SEE ALSO

Chipmunk 2D Website: L<http://chipmunk-physics.net>

L<Alien::Chipmunk>

=head1 AUTHOR

Timm Murray <tmurray@wumpus-cave.net>

=head1 LICENSE

Copyright (c) 2016,  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of 
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
