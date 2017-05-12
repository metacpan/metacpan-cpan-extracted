void
cpDampedRotarySpringSetSpringTorqueFunc( constraint, springTorqueFunc )
    cpConstraint *constraint
    SV* springTorqueFunc
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.dampedRotarySpringTorqueFuncs,
        (char*)&constraint,
        sizeof(constraint),
        springTorqueFunc,
        0
    );

    cpDampedRotarySpringSetSpringTorqueFunc(
        constraint,
        (cpDampedRotarySpringTorqueFunc) __perlCpDampedRotarySpringSetSpringTorqueFunc
    );
