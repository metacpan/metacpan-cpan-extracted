#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Include Pepper library headers */
#include "peppertypes.h"
#include "pepperenums.h"
#include "peppererrors.h"
#include "pepper.h"

/* Callback support structure */
typedef struct {
    SV* callback_cv;     /* Perl callback coderef */
    SV* userdata;        /* Perl user data */
} PepperCallbackData;

/* Callback wrapper function that gets called by C library */
void CALLING_CONVENTION
pepper_callback_wrapper(
    PEPCallbackEvent eEvent,
    PEPCallbackOption eOption,
    PEPHandle hInstance,
    PEPHandle hOutputOptions,
    PEPHandle hInputOptions,
    void* pUserData
) {
    dTHX;  /* Get thread context */
    dSP;   /* Stack pointer declaration */

    PepperCallbackData* callbackData = (PepperCallbackData*)pUserData;
    if(!callbackData || !callbackData->callback_cv) {
        return;
    }

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    /* Push arguments onto Perl stack */
    mXPUSHi(eEvent);
    mXPUSHi(eOption);

    /* Convert handles to Perl SVs */
    if(hInstance != pepInvalidHandle) {
        SV* handle_sv = sv_2mortal(newSViv(PTR2IV(hInstance)));
        XPUSHs(handle_sv);
    } else {
        XPUSHs(&PL_sv_undef);
    }

    if(hOutputOptions != pepInvalidHandle) {
        SV* handle_sv = sv_2mortal(newSViv(PTR2IV(hOutputOptions)));
        XPUSHs(handle_sv);
    } else {
        XPUSHs(&PL_sv_undef);
    }

    if(hInputOptions != pepInvalidHandle) {
        SV* handle_sv = sv_2mortal(newSViv(PTR2IV(hInputOptions)));
        XPUSHs(handle_sv);
    } else {
        XPUSHs(&PL_sv_undef);
    }

    /* Push user data */
    if(callbackData->userdata) {
        XPUSHs(callbackData->userdata);
    } else {
        XPUSHs(&PL_sv_undef);
    }

    PUTBACK;

    /* Call the Perl callback */
    call_sv(callbackData->callback_cv, G_DISCARD | G_EVAL);

    FREETMPS;
    LEAVE;
}

MODULE = Lib::Pepper		PACKAGE = Lib::Pepper

PROTOTYPES: ENABLE

###############################################################################
# LIBRARY MANAGEMENT
###############################################################################

void
pepInitialize(pepcoreLibraryPath, configStructure, licenseStructure)
    const char* pepcoreLibraryPath
    SV* configStructure
    SV* licenseStructure
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle terminalTypeOptionList = pepInvalidHandle;
        const char* configStr = (SvOK(configStructure) && SvPOK(configStructure)) ? SvPV_nolen(configStructure) : NULL;
        const char* licenseStr = (SvOK(licenseStructure) && SvPOK(licenseStructure)) ? SvPV_nolen(licenseStructure) : NULL;

        result = pepInitialize(pepcoreLibraryPath, configStr, licenseStr, NULL, NULL, &terminalTypeOptionList);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(terminalTypeOptionList != pepInvalidHandle) {
            mPUSHi(PTR2IV(terminalTypeOptionList));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

PEPFunctionResult
pepFinalize()

void
pepVersion()
    PPCODE:
    {
        PEPFunctionResult result;
        int64_t major = 0, minor = 0, service = 0, revision = 0, api = 0;
        int64_t osArch = 0, releaseType = 0, configType = 0;

        result = pepVersion(&major, &minor, &service, &revision, &api, &osArch, &releaseType, &configType);

        EXTEND(SP, 9);
        mPUSHi(result);
        mPUSHi(major);
        mPUSHi(minor);
        mPUSHi(service);
        mPUSHi(revision);
        mPUSHi(api);
        mPUSHi(osArch);
        mPUSHi(releaseType);
        mPUSHi(configType);
    }

###############################################################################
# INSTANCE MANAGEMENT
###############################################################################

void
pepCreateInstance(terminalType, instanceId)
    int64_t terminalType
    int64_t instanceId
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle instance = pepInvalidHandle;

        result = pepCreateInstance(terminalType, instanceId, &instance);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(instance != pepInvalidHandle) {
            mPUSHi(PTR2IV(instance));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

PEPFunctionResult
pepFreeInstance(hInstance)
    PEPHandle hInstance

###############################################################################
# CONFIGURATION
###############################################################################

void
pepConfigureWithCallback(hInstance, hInputOptions, callback_cv, userdata_sv)
    PEPHandle hInstance
    PEPHandle hInputOptions
    SV* callback_cv
    SV* userdata_sv
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle outputOptions = pepInvalidHandle;
        PepperCallbackData* callbackData = NULL;

        /* Validate callback */
        if(!SvROK(callback_cv) || SvTYPE(SvRV(callback_cv)) != SVt_PVCV) {
            croak("pepConfigureWithCallback: callback must be a code reference");
        }

        /* Allocate callback data structure */
        callbackData = (PepperCallbackData*)malloc(sizeof(PepperCallbackData));
        if(!callbackData) {
            croak("pepConfigureWithCallback: out of memory");
        }

        /* Store callback and user data with reference counting */
        callbackData->callback_cv = SvREFCNT_inc(callback_cv);
        callbackData->userdata = SvOK(userdata_sv) ? SvREFCNT_inc(userdata_sv) : NULL;

        /* Call pepConfigure with our wrapper */
        result = pepConfigure(hInstance, pepper_callback_wrapper, callbackData, hInputOptions, &outputOptions);

        /* Note: callbackData memory management needs improvement - currently leaking */

        EXTEND(SP, 2);
        mPUSHi(result);
        if(outputOptions != pepInvalidHandle) {
            mPUSHi(PTR2IV(outputOptions));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

###############################################################################
# OPERATION WORKFLOW (4-step process)
###############################################################################

void
pepPrepareOperation(hInstance, eOperation, hInputOptions)
    PEPHandle hInstance
    PEPOperation eOperation
    PEPHandle hInputOptions
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle operation = pepInvalidHandle;
        PEPHandle outputOptions = pepInvalidHandle;

        result = pepPrepareOperation(hInstance, eOperation, hInputOptions, &operation, &outputOptions);

        EXTEND(SP, 3);
        mPUSHi(result);
        if(operation != pepInvalidHandle) {
            mPUSHi(PTR2IV(operation));
        } else {
            PUSHs(&PL_sv_undef);
        }
        if(outputOptions != pepInvalidHandle) {
            mPUSHi(PTR2IV(outputOptions));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

void
pepStartOperation(hInstance, eOperation, hInputOptions)
    PEPHandle hInstance
    PEPOperation eOperation
    PEPHandle hInputOptions
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle operation = pepInvalidHandle;
        PEPHandle outputOptions = pepInvalidHandle;

        result = pepStartOperation(hInstance, eOperation, hInputOptions, &operation, &outputOptions);

        EXTEND(SP, 3);
        mPUSHi(result);
        if(operation != pepInvalidHandle) {
            mPUSHi(PTR2IV(operation));
        } else {
            PUSHs(&PL_sv_undef);
        }
        if(outputOptions != pepInvalidHandle) {
            mPUSHi(PTR2IV(outputOptions));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

void
pepExecuteOperation(hInstance, eOperation, hInputOptions)
    PEPHandle hInstance
    PEPOperation eOperation
    PEPHandle hInputOptions
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle operation = pepInvalidHandle;
        PEPHandle outputOptions = pepInvalidHandle;

        result = pepExecuteOperation(hInstance, eOperation, hInputOptions, &operation, &outputOptions);

        EXTEND(SP, 3);
        mPUSHi(result);
        if(operation != pepInvalidHandle) {
            mPUSHi(PTR2IV(operation));
        } else {
            PUSHs(&PL_sv_undef);
        }
        if(outputOptions != pepInvalidHandle) {
            mPUSHi(PTR2IV(outputOptions));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

void
pepFinalizeOperation(hInstance, eOperation, hInputOptions)
    PEPHandle hInstance
    PEPOperation eOperation
    PEPHandle hInputOptions
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle operation = pepInvalidHandle;
        PEPHandle outputOptions = pepInvalidHandle;

        result = pepFinalizeOperation(hInstance, eOperation, hInputOptions, &operation, &outputOptions);

        EXTEND(SP, 3);
        mPUSHi(result);
        if(operation != pepInvalidHandle) {
            mPUSHi(PTR2IV(operation));
        } else {
            PUSHs(&PL_sv_undef);
        }
        if(outputOptions != pepInvalidHandle) {
            mPUSHi(PTR2IV(outputOptions));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

###############################################################################
# OPERATION STATUS
###############################################################################

void
pepOperationStatus(hInstance, hOperation, bWaitForCompletion)
    PEPHandle hInstance
    PEPHandle hOperation
    PEPBool bWaitForCompletion
    PPCODE:
    {
        PEPFunctionResult result;
        PEPBool status = pepFalse;

        result = pepOperationStatus(hInstance, hOperation, bWaitForCompletion, &status);

        EXTEND(SP, 2);
        mPUSHi(result);
        mPUSHi(status);
    }

###############################################################################
# UTILITY AND AUXILIARY
###############################################################################

void
pepUtility(hInstance, hInputOptions)
    PEPHandle hInstance
    PEPHandle hInputOptions
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle outputOptions = pepInvalidHandle;

        result = pepUtility(hInstance, hInputOptions, &outputOptions);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(outputOptions != pepInvalidHandle) {
            mPUSHi(PTR2IV(outputOptions));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

void
pepAuxiliary(hInstance, hInputOptions)
    PEPHandle hInstance
    PEPHandle hInputOptions
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle operation = pepInvalidHandle;
        PEPHandle outputOptions = pepInvalidHandle;

        result = pepAuxiliary(hInstance, hInputOptions, &operation, &outputOptions);

        EXTEND(SP, 3);
        mPUSHi(result);
        if(operation != pepInvalidHandle) {
            mPUSHi(PTR2IV(operation));
        } else {
            PUSHs(&PL_sv_undef);
        }
        if(outputOptions != pepInvalidHandle) {
            mPUSHi(PTR2IV(outputOptions));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

###############################################################################
# LICENSE
###############################################################################

void
pepDownloadLicense(hInputOptions)
    PEPHandle hInputOptions
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle outputOptions = pepInvalidHandle;

        result = pepDownloadLicense(hInputOptions, &outputOptions);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(outputOptions != pepInvalidHandle) {
            mPUSHi(PTR2IV(outputOptions));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

###############################################################################
# OPTION LIST MANAGEMENT
###############################################################################

void
pepOptionListCreate()
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle list = pepInvalidHandle;

        result = pepOptionListCreate(&list);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(list != pepInvalidHandle) {
            mPUSHi(PTR2IV(list));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

void
pepOptionListGetStringElement(hOptionList, pKey)
    PEPHandle hOptionList
    const char* pKey
    PPCODE:
    {
        PEPFunctionResult result;
        const char* value = NULL;

        result = pepOptionListGetStringElement(hOptionList, pKey, &value);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(result >= pepFunctionResult_Success && value) {
            mPUSHp(value, strlen(value));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

void
pepOptionListGetIntElement(hOptionList, pKey)
    PEPHandle hOptionList
    const char* pKey
    PPCODE:
    {
        PEPFunctionResult result;
        int64_t value = 0;

        result = pepOptionListGetIntElement(hOptionList, pKey, &value);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(result >= pepFunctionResult_Success) {
            mPUSHi(value);
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

void
pepOptionListGetChildOptionListElement(hOptionList, pKey)
    PEPHandle hOptionList
    const char* pKey
    PPCODE:
    {
        PEPFunctionResult result;
        PEPHandle childHandle = pepInvalidHandle;

        result = pepOptionListGetChildOptionListElement(hOptionList, pKey, &childHandle);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(result >= pepFunctionResult_Success && childHandle != pepInvalidHandle) {
            mPUSHi(PTR2IV(childHandle));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

PEPFunctionResult
pepOptionListAddStringElement(hOptionList, pKey, pValue)
    PEPHandle hOptionList
    const char* pKey
    const char* pValue

PEPFunctionResult
pepOptionListAddIntElement(hOptionList, pKey, value)
    PEPHandle hOptionList
    const char* pKey
    int64_t value

PEPFunctionResult
pepOptionListAddChildOptionListElement(hOptionList, pKey, hChildOptionList)
    PEPHandle hOptionList
    const char* pKey
    PEPHandle hChildOptionList

void
pepOptionListGetElementList(hOptionList)
    PEPHandle hOptionList
    PPCODE:
    {
        PEPFunctionResult result;
        const char* elementList = NULL;

        result = pepOptionListGetElementList(hOptionList, &elementList);

        EXTEND(SP, 2);
        mPUSHi(result);
        if(result >= pepFunctionResult_Success && elementList) {
            mPUSHp(elementList, strlen(elementList));
        } else {
            PUSHs(&PL_sv_undef);
        }
    }

###############################################################################
# HELPER FUNCTIONS
###############################################################################

int
isValidHandle(handle)
    PEPHandle handle
    CODE:
        RETVAL = (handle != pepInvalidHandle);
    OUTPUT:
        RETVAL

int
isSuccess(result)
    PEPFunctionResult result
    CODE:
        RETVAL = (result >= pepFunctionResult_Success);
    OUTPUT:
        RETVAL

int
isFailure(result)
    PEPFunctionResult result
    CODE:
        RETVAL = (result < pepFunctionResult_Success);
    OUTPUT:
        RETVAL

