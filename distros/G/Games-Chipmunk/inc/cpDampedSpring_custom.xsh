void
cpDampedSpringSetSpringForceFunc( constraint, func )
    cpConstraint *constraint
    SV * func
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.dampedSpringForceFuncs,
        (char*)&constraint,
        sizeof(constraint),
        func,
        0
    );

    cpDampedSpringSetSpringForceFunc(
        constraint,
        (cpDampedSpringForceFunc) __perlCpDampedSpringSetSpringForceFunc
    );

