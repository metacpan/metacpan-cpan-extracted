void
cpBodySetVelocityUpdateFunc( body, velocityFunc )
    cpBody *body
    SV* velocityFunc
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.bodyVelocityFuncs,
        (char*)&body,
        sizeof(body),
        velocityFunc,
        0
    );

    cpBodySetVelocityUpdateFunc(
        body,
        (cpBodyVelocityFunc) __perlCpBodyVelocityFunc
    );

void
cpBodySetPositionUpdateFunc( body, func )
    cpBody *body
    SV* func
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.bodyPositionFuncs,
        (char*)&body,
        sizeof(body),
        func,
        0
    );

    cpBodySetPositionUpdateFunc(
        body,
        (cpBodyPositionFunc) __perlCpBodyPositionFunc
    );

void
cpBodyEachShape( body, func, data )
    cpBody *body
    SV* func
    SV* data
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.bodyEachShapeFuncs,
        (char*)&body,
        sizeof(body),
        func,
        0
    );

    cpBodyEachShape(
        body,
        (cpBodyShapeIteratorFunc) __perlCpBodyShapeIteratorFunc,
        data
    );

void
cpBodyEachConstraints( body, func, data )
    cpBody *body
    SV* func
    SV* data
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.bodyEachConstraintFuncs,
        (char*)&body,
        sizeof(body),
        func,
        0
    );

    cpBodyEachConstraint(
        body,
        (cpBodyConstraintIteratorFunc) __perlCpBodyConstraintIteratorFunc,
        data
    );

void
cpBodyEachArbiter( body, func, data )
    cpBody *body
    SV* func
    SV* data
  PREINIT:
    dMY_CXT;
  CODE:
    hv_store(
        MY_CXT.bodyArbiterIteratorFuncs,
        (char*)&body,
        sizeof(body),
        func,
        0
    );

    cpBodyEachArbiter(
        body,
        (cpBodyArbiterIteratorFunc) __perlCpBodyArbiterIteratorFunc,
        data
    );
