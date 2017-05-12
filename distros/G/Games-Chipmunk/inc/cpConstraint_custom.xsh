void
cpConstraintSetPreSolveFunc( constraint, func )
    cpConstraint *constraint
    SV * func
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.constraintPreSolveFuncs,
        (char*)&constraint,
        sizeof(constraint),
        func,
        0
    );

    cpConstraintSetPreSolveFunc(
        constraint,
        (cpConstraintPreSolveFunc) __perlCpConstraintPreSolveFunc
    );


void
cpConstraintSetPostSolveFunc( constraint, func )
    cpConstraint *constraint
    SV * func
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.constraintPostSolveFuncs,
        (char*)&constraint,
        sizeof(constraint),
        func,
        0
    );

    cpConstraintSetPostSolveFunc(
        constraint,
        (cpConstraintPostSolveFunc) __perlCpConstraintPostSolveFunc
    );
