#// clang-format off

MODULE = Dyn::Callback   PACKAGE = Dyn::Callback::Args

# Actually defined in dyncallback/dyncall_args.h

void
DESTROY(SV * me)
CODE:
// clang-format on
{
    DCArgs *value;
    if (sv_derived_from(me, "Dyn::Callback::Args")) {
        IV tmp = SvIV(MUTABLE_SV(SvRV(me)));
        value = INT2PTR(DCArgs *, tmp);
    }
    else
        croak("value is not of type Dyn::Callback::Args");
    if (value) { // No double free!
        value = NULL;
        safefree(value);
    }
}
// clang-format off

MODULE = Dyn::Callback   PACKAGE = Dyn::Callback

SV *
_fetch(SV * me)
ALIAS:
    dcbArgBool      = DC_SIGCHAR_BOOL
    dcbArgChar      = DC_SIGCHAR_CHAR
    dcbArgUChar     = DC_SIGCHAR_UCHAR
    dcbArgShort     = DC_SIGCHAR_SHORT
    dcbArgUShort    = DC_SIGCHAR_USHORT
    dcbArgInt       = DC_SIGCHAR_INT
    dcbArgUInt      = DC_SIGCHAR_UINT
    dcbArgLong      = DC_SIGCHAR_LONG
    dcbArgULong     = DC_SIGCHAR_ULONG
    dcbArgLongLong  = DC_SIGCHAR_LONGLONG
    dcbArgULongLong = DC_SIGCHAR_ULONGLONG
    dcbArgFloat     = DC_SIGCHAR_FLOAT
    dcbArgDouble    = DC_SIGCHAR_DOUBLE
    dcbArgPointer   = DC_SIGCHAR_POINTER
CODE:
// clang-format on
{
    DCArgs *args;
    if (sv_derived_from(ST(0), "Dyn::Callback::Args")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        args = INT2PTR(DCArgs *, tmp);
    }
    else
        croak("value is not of type Dyn::Callback::Value");
    switch (ix) {
    case DC_SIGCHAR_BOOL:
        RETVAL = boolSV((bool)dcbArgBool(args));
        break;
    case DC_SIGCHAR_CHAR:
        RETVAL = newSViv((char)dcbArgChar(args));
        break;
    case DC_SIGCHAR_UCHAR:
        RETVAL = newSVuv((char)dcbArgUChar(args));
        break;
    case DC_SIGCHAR_SHORT:
        RETVAL = newSViv((short)dcbArgShort(args));
        break;
    case DC_SIGCHAR_USHORT:
        RETVAL = newSVuv((unsigned short)dcbArgUShort(args));
        break;
    case DC_SIGCHAR_INT:
        RETVAL = newSViv((int)dcbArgInt(args));
        break;
    case DC_SIGCHAR_UINT:
        RETVAL = newSVuv((unsigned int)dcbArgUInt(args));
        break;
    case DC_SIGCHAR_LONG:
        RETVAL = newSViv((long)dcbArgLong(args));
        break;
    case DC_SIGCHAR_ULONG:
        RETVAL = newSVuv((unsigned long)dcbArgULong(args));
        break;
    case DC_SIGCHAR_LONGLONG:
        RETVAL = newSViv((long)dcbArgLongLong(args));
        break;
    case DC_SIGCHAR_ULONGLONG:
        RETVAL = newSVuv((unsigned long long)dcbArgULongLong(args));
        break;
    case DC_SIGCHAR_FLOAT:
        RETVAL = newSVnv((float)dcbArgFloat(args));
        break;
    case DC_SIGCHAR_DOUBLE:
        RETVAL = newSVnv((double)dcbArgDouble(args));
        break;
    case DC_SIGCHAR_POINTER:
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV((DCpointer)dcbArgPointer(args)))),
                          gv_stashpv("Dyn::Call::Pointer", GV_ADD));
        break;
    default:
        croak("Dyn::Callback::Args has no field %c", ix);
        break;
    }
}
// clang-format off
OUTPUT:
    RETVAL

DCpointer
dcbArgAggr(DCArgs *args, DCpointer target)
OUTPUT:
    RETVAL

const char *
dcbArgString(DCArgs *args)
CODE:
    // clang-format on
    RETVAL = (const char *)dcbArgPointer(args);
// clang-format off
OUTPUT:
    RETVAL

void
dcbReturnAggr(DCArgs * args, DCValue * result, DCpointer ret)

BOOT:
// clang-format on
{
    export_function("Dyn::Callback", "dcbArgInt", "args");
    export_function("Dyn::Callback", "dcbArgBool", "args");
    export_function("Dyn::Callback", "dcbArgChar", "args");
    export_function("Dyn::Callback", "dcbArgUChar", "args");
    export_function("Dyn::Callback", "dcbArgShort", "args");
    export_function("Dyn::Callback", "dcbArgUShort", "args");
    export_function("Dyn::Callback", "dcbArgInt", "args");
    export_function("Dyn::Callback", "dcbArgUInt", "args");
    export_function("Dyn::Callback", "dcbArgLong", "args");
    export_function("Dyn::Callback", "dcbArgULong", "args");
    export_function("Dyn::Callback", "dcbArgLongLong", "args");
    export_function("Dyn::Callback", "dcbArgULongLong", "args");
    export_function("Dyn::Callback", "dcbArgFloat", "args");
    export_function("Dyn::Callback", "dcbArgDouble", "args");
    export_function("Dyn::Callback", "dcbArgPointer", "args");
    export_function("Dyn::Callback", "dcbArgAggr", "args");
    export_function("Dyn::Callback", "dcbArgString", "args"); // Not in upstream lib
    export_function("Dyn::Callback", "dcbReturnAggr", "args");
}
// clang-format off
