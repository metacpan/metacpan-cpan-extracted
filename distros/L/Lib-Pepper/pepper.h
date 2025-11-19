#ifndef __pepper_h__
#define __pepper_h__

#include "peppertypes.h"
#include "pepperenums.h"
#include "peppererrors.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/* define NULL if needed */
#ifndef NULL
#define NULL ( 0 )
#endif /* NULL */

/* empty definitions to mark function parameter direction */
#define _IN____
#define ___OUT_

/* this defines the signature of the call back function that will be called from PEPPERerface to the POS */
#define PEPCallbackSignature                                                                                           \
    void ( *pepCallback )( PEPCallbackEvent /* eEvent */, PEPCallbackOption /* eOption */, PEPHandle /* hInstance */,  \
                           PEPHandle /* hOutputOptions */, PEPHandle /* hInputOptions */, void* /* pUserData */ )

/**
* @brief Function to initialize the library before usage. Use this as first call before anything else
* @param pConfigurationStructure A ptr to the null terminated character buffer that represents the configuration file XML structure. If NULL, the configuration is read from file
* @param pLicenseStructure A ptr to the null terminated character buffer that represents the license file XML structure. If NULL, the license is read from file
* @param pRfu1 An input parameter reserved for future use. Set this to NULL
* @param pRfu2 An input parameter reserved for future use. Set this to NULL
* @param pTerminalTypeOptionList [out] A list of output options containing the available terminal types
* @return A function result to check for success or possible failures
*
* Remark 1: This call is blocking
* Remark 2: The output options contain the full list of all terminal type implementations that have been compiled in on this platform.
*           The usable terminal types may be further restricted by the license information
*/
PEPFunctionResult PEPPERC_API pepInitialize( _IN____ const char* pPepcoreLibraryPath,
                                             _IN____ const char* pConfigurationStructure,
                                             _IN____ const char* pLicenseStructure, _IN____ const void* pRfu1,
                                             _IN____ const void* pRfu2, ___OUT_ PEPHandle* pTerminalTypeOptionList );

/**
* @brief Function to retrieve the version number of the library
* @param pVersionMajor [out] The major version number (Is incremented when new implementation types are added)
* @param pVersionMinor [out] The minor version number (Is incremented when protocol versions are updated)
* @param pVersionService [out] The service version number (Is incremented on bug fixes)
* @param pVersionRevision [out] The revision (Is an internal counter that reflects the revision in our source control subsystem)
* @param pApiMajor [out] The api major version (Is updated when the library API has breaking changes)
*
* Remark: This call is blocking
*/
PEPFunctionResult PEPPERC_API pepVersion( ___OUT_ int64_t* pVersionMajor, ___OUT_ int64_t* pVersionMinor,
                                          ___OUT_ int64_t* pVersionService, ___OUT_ int64_t* pVersionRevision,

                                          ___OUT_ int64_t* pApi,

                                          ___OUT_ int64_t* pOsArchitecture, ___OUT_ int64_t* pReleaseType,
                                          ___OUT_ int64_t* pConfigurationType );

/**
* @brief Function to create a new work instance
* @param iTerminalType The numerical value of the terminal type as returend in the available terminal types list
* @param iInstanceId A numeric identifier that represents this specific instance. For the same instance this must be the same value on any initialization
* @param pInstance The instance handle to use in further calls
* @return A function result to check for success or possible failures
*
* Remark: This call is blocking
*/
PEPFunctionResult PEPPERC_API pepCreateInstance( _IN____ int64_t iTerminalType, _IN____ int64_t iInstanceId,
                                                 ___OUT_ PEPHandle* pInstance );

/**
* @brief Function to configure the work instance for further operation
* @param hInstance [in] The instance handle of the instance that the desired operation is related to
* @param PEPCallbackSignature [in] Ptr to the callback function that informs about occured processing events
* @param pCallbackUserData [in] User specific data that is forwarded into the callback function for your use
* @param hInputOptions [in] A list of input options for the operation processing
* @param pOutputOptions [out] A list of output options (aka results) for the operation processing.
* @return twResult_Success in case of success, one of the failure values in case of error.
*
* Remark: This call is blocking
* Important: In case of failures there may not even be a pOutputOptions set. Check pOutputOptions against pepInvalidHandle (-1) first before you try to access it
*/
PEPFunctionResult PEPPERC_API pepConfigure( _IN____ PEPHandle hInstance, _IN____ PEPCallbackSignature,
                                            _IN____ void* pCallbackUserData, _IN____ PEPHandle hInputOptions,
                                            ___OUT_ PEPHandle* pOutputOptions );

/**
* @brief Function to retrieve the current status of another pending operation
* @param hInstance [in] The instance handle of the instance that the desired operation is related to
* @param hOperation [in] The operation handle of the operation that is to be monitored
* @param bWaitForCompletion [in] In case of pepFalse, the call returns immediately with the status, in case of pepTrue
* this call blocks until the operation is completed
* @param pStatus [out] The status of the operation.
* - pepFalse in case the operation is pending,
* - pepTrue in case the operation is done.
* @return A result code for the call of this function
*
* Remark: Whether this call is blocking or not depends on the bWaitForCompletion parameter
*/
PEPFunctionResult PEPPERC_API pepOperationStatus( _IN____ PEPHandle hInstance, _IN____ PEPHandle hOperation,
                                                  _IN____ PEPBool bWaitForCompletion, ___OUT_ PEPBool* pStatus );

/**
* @brief Function to prepare an operation. This is the first of four steps in processing the operation
* @param hInstance [in] The instance handle of the instance that the desired operation is related to
* @param eOperation [in] The operation enum type to define the desired operation
* @param hInputOptions [in] A list of input options for the operation processing
* @param pOperation [out] The operation handle
* @param pOutputOptions [out] A list of output options (aka results) for the operation processing.
*        In case of not successful processing (return == pepInvalidHandle) this option list may or may not be set.
*        Check the return value of pOutputOptions against pepInvalidHandle before processing this
*        Do not access this parameter before the call is done!
* @return A result code for the call of this function
*
* Remark: This call returns immediately. In case of successful processing (return != pepInvalidHandle) you will be informed over the completion via
* pepOperationStatus and callback event.
*/
PEPFunctionResult PEPPERC_API pepPrepareOperation( _IN____ PEPHandle hInstance, _IN____ PEPOperation eOperation,
                                                   _IN____ PEPHandle hInputOptions, ___OUT_ PEPHandle* pOperation,
                                                   ___OUT_ PEPHandle* pOutputOptions );

/**
* @brief Function to start an operation. This is the second of four steps in processing the operation
* @param hInstance [in] The instance handle of the instance that the desired operation is related to
* @param eOperation [in] The operation enum type to define the desired operation
* @param hInputOptions [in] A list of input options for the operation processing
* @param pOperation [out] The operation handle
* @param pOutputOptions [out] A list of output options (aka results) for the operation processing.
*        In case of not successful processing (return == pepInvalidHandle) this option list may or may not be set.
*        Check the return value of pOutputOptions against pepInvalidHandle before processing this
*        Do not access this parameter before the call is done!
* @return A result code for the call of this function
*
* Remark: This call returns immediately. In case of successful processing (return != pepInvalidHandle) you will be informed over the completion via
* pepOperationStatus and callback event.
*/
PEPFunctionResult PEPPERC_API pepStartOperation( _IN____ PEPHandle hInstance, _IN____ PEPOperation eOperation,
                                                 _IN____ PEPHandle hInputOptions, ___OUT_ PEPHandle* pOperation,
                                                 ___OUT_ PEPHandle* pOutputOptions );

/**
* @brief Function to execute an operation. This is the third of four steps in processing the operation
* @param hInstance [in] The instance handle of the instance that the desired operation is related to
* @param eOperation [in] The operation enum type to define the desired operation
* @param hInputOptions [in] A list of input options for the operation processing
* @param pOperation [out] The operation handle
* @param pOutputOptions [out] A list of output options (aka results) for the operation processing.
*        In case of not successful processing (return == pepInvalidHandle) this option list may or may not be set.
*        Check the return value of pOutputOptions against pepInvalidHandle before processing this
*        Do not access this parameter before the call is done!
* @return A result code for the call of this function
*
* Remark: This call returns immediately. In case of successful processing (return != pepInvalidHandle) you will be informed over the completion via
* pepOperationStatus and callback event.
*/
PEPFunctionResult PEPPERC_API pepExecuteOperation( _IN____ PEPHandle hInstance, _IN____ PEPOperation eOperation,
                                                   _IN____ PEPHandle hInputOptions, ___OUT_ PEPHandle* pOperation,
                                                   ___OUT_ PEPHandle* pOutputOptions );

/**
* @brief Function to finalize an operation. This is the fourth of four steps in processing the operation
* @param hInstance [in] The instance handle of the instance that the desired operation is related to
* @param eOperation [in] The operation enum type to define the desired operation
* @param hInputOptions [in] A list of input options for the operation processing
* @param pOperation [out] The operation handle
* @param pOutputOptions [out] A list of output options (aka results) for the operation processing.
*        In case of not successful processing (return == pepInvalidHandle) this option list may or may not be set.
*        Check the return value of pOutputOptions against pepInvalidHandle before processing this
*        Do not access this parameter before the call is done!
* @return A result code for the call of this function
*
* Remark: This call returns immediately. In case of successful processing (return != pepInvalidHandle) you will be informed over the completion via
* pepOperationStatus and callback event.
*/
PEPFunctionResult PEPPERC_API pepFinalizeOperation( _IN____ PEPHandle hInstance, _IN____ PEPOperation eOperation,
                                                    _IN____ PEPHandle hInputOptions, ___OUT_ PEPHandle* pOperation,
                                                    ___OUT_ PEPHandle* pOutputOptions );

/**
* @brief Function to cleanup and free a created instance
* @param hInstance [in] The instance handle of the instance that the desired operation is related to
* @return A result code for the call of this function
*
* Remark: This call is blocking
*/
PEPFunctionResult PEPPERC_API pepFreeInstance( _IN____ PEPHandle hInstance );

/**
* @brief Function to cleanup and free all acquired ressources. Do this call as very last before unloading the library.
* @return A result code for the call of this function
*
* Remark: This call is blocking
*/
PEPFunctionResult PEPPERC_API pepFinalize();

/**
 * Multipurpose method to perform different tasks that read and modify the internal state of pepper operation. 
 * Please check PEPUtilityCode for possible actions.
 * @param           hInstance       Instance
 * @param           hInputOptions   Input options
 * @param [out]     hOutputOptions  Output options
 * @return  A PEPFunctionResult.
 */
PEPFunctionResult PEPPERC_API pepUtility( _IN____ PEPHandle hInstance, _IN____ PEPHandle hInputOptions,
                                          ___OUT_ PEPHandle* hOutputOptions );

/**
 * Multipurpose method to perform different non-financial operations on an EFT/POS device.
 * Please check PEPAuxiliaryCode for possible actions.
 * @param           hInstance       Instance
 * @param           hInputOptions   Input options
* @param            pOperation [out] The operation handle
 * @param [out]     hOutputOptions  Output options
 * @return  A PEPFunctionResult.
 */
PEPFunctionResult PEPPERC_API pepAuxiliary( _IN____ PEPHandle hInstance, _IN____ PEPHandle hInputOptions,
                                            ___OUT_ PEPHandle* pOperation, ___OUT_ PEPHandle* hOutputOptions );

/**
 * @brief Function to download any Pepper license
 * @param           hInputOptions   Input options
 * @param           pOutputOptions  Output options
 * @return  A PEPFunctionResult.
 */
PEPFunctionResult PEPPERC_API pepDownloadLicense( _IN____ PEPHandle hInputOptions, ___OUT_ PEPHandle* pOutputOptions );

/**
* @brief This function initializes a new empty option list
* @param pList [out] The list handle
* @return A result code for the call of this function
*/
PEPFunctionResult PEPPERC_API pepOptionListCreate( ___OUT_ PEPHandle* pList );

/**
* @brief This function returns the value of a specified string option in the list
* @param [in] hList Handle of the option list to retrieve from
* @param [in] chName The textual name of the option to retrieve (e.g. something like "sResultText")
* @param [out] pValue a ptr to a const char* that will point the the 0-terminated result text
* @return The result code of the operation. Usually to expect result codes are:
* - pepFunctionResult_Success Succesful operation. Only in this case the pointed to value of pValue is valid!
* - pepFunctionResult_Failure_Unknown_Option in case you provided a chName that is not recognized as known option
* - pepFunctionResult_Failure_Invalid_Option_Value in case you used the wrong function for retrieval
*   (e.g. you used the string function for retrieving an int option)
*/
PEPFunctionResult PEPPERC_API pepOptionListGetStringElement( _IN____ PEPHandle hList, _IN____ const char* chName,
                                                             ___OUT_ const char** pValue );

/**
* @brief This function returns the value of a specified int option in the list
* @param [in] hList Handle of the option list to retrieve from
* @param [in] chName The textual name of the option to retrieve (e.g. something like "iFunctionResult")
* @param [out] pValue a ptr to an int64_t that will hold the result value
* @return The result code of the operation. Usually to expect result codes are:
* - pepFunctionResult_Success Succesful operation. Only in this case the pointed to value of pValue is valid!
* - pepFunctionResult_Failure_Unknown_Option in case you provided a chName that is not recognized as known option
* - pepFunctionResult_Failure_Invalid_Option_Value in case you used the wrong function for retrieval
*   (e.g. you used the int function for retrieving a string option)
*/
PEPFunctionResult PEPPERC_API pepOptionListGetIntElement( _IN____ PEPHandle hList, _IN____ const char* chName,
                                                          ___OUT_ int64_t* pValue );

/**
* @brief This function returns the handle of a specified child option list in the list
* @param [in] hList Handle of the option list to retrieve from
* @param [in] chName The textual name of the option to retrieve (e.g. something like "hLine")
* @param [out] pValue a ptr to a PEPHandle that will hold the result handle value
* @return The result code of the operation. Usually to expect result codes are:
* - pepFunctionResult_Success Succesful operation. Only in this case the pointed to value of pValue is valid!
* - pepFunctionResult_Failure_Unknown_Option in case you provided a chName that is not recognized as known option
* - pepFunctionResult_Failure_Invalid_Option_Value in case you used the wrong function for retrieval
*   (e.g. you used the function for retrieving a string option)
*/
PEPFunctionResult PEPPERC_API pepOptionListGetChildOptionListElement( _IN____ PEPHandle hList,
                                                                      _IN____ const char* chName,
                                                                      ___OUT_ PEPHandle* pChildList );

/**
* @brief This function returns a ptr to a const char* that will point the the 0-terminated text of a
* comma seperated list of all existing options in the list.
* @param [in] hList Handle of the option list to retrieve from
* @param [out] pValue a ptr to a const char* that will hold the result value
* @return The result code of the operation. Usually to expect result codes are:
* - pepFunctionResult_Success Succesful operation. Only in this case the pointed to value of pValue is valid!
* - pepFunctionResult_Failure_Unknown_Option in case you provided a chName that is not recognized as known option
* - pepFunctionResult_Failure_Invalid_Option_Value in case you used the wrong function for retrieval
*   (e.g. you used the function for retrieving a string option)
*
* Example Output inpHandle after successful call:
* "iFunctionResult,sResultText,iAmount"
*/
PEPFunctionResult PEPPERC_API pepOptionListGetElementList( _IN____ PEPHandle hList, ___OUT_ const char** pValue );

/**
* @brief This function adds a string option to an existing option list
* @param [in] hList Handle of the option list to write into
* @param [in] chName The textual name of the option to set (e.g. something like "sPosNumber")
* @param [in] chValue The textual value of the option to set (e.g. something like "ecr42")
* @return The result code of the operation
*/
PEPFunctionResult PEPPERC_API pepOptionListAddStringElement( _IN____ PEPHandle hList, _IN____ const char* chName,
                                                             _IN____ const char* chValue );

/**
* @brief This function adds an int option to an existing option list
* @param [in] hList Handle of the option list to write into
* @param [in] chName The textual name of the option to set (e.g. something like "iAmount")
* @param [in] iValue The numeric value of the option to set (e.g. something like 10095)
* @return The result code of the operation
*/
PEPFunctionResult PEPPERC_API pepOptionListAddIntElement( _IN____ PEPHandle hList, _IN____ const char* chName,
                                                          _IN____ int64_t iValue );

/**
* @brief This function adds an existing option list as child to another existing option list
* @param [in] hList Handle of the parent option list to write into
* @param [in] chName The textual name of the option to set (e.g. something like "hLine")
* @param [in] hChildList The handle value of the child option list to add
* @return The result code of the operation
*
* @todo: Sicherstellen dass hList != hChildList!
*/
PEPFunctionResult PEPPERC_API pepOptionListAddChildOptionListElement( _IN____ PEPHandle hList,
                                                                      _IN____ const char* chName,
                                                                      _IN____ PEPHandle hChildList );

/* function type declarations for dynamic loading of the library */
/* -- PEPPER functions -- */
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepInitialize )( _IN____ const char*, _IN____ const char*,
                                                                      _IN____ const char*, _IN____ const void*,
                                                                      _IN____ const void*, ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepVersion )( ___OUT_ int64_t*, ___OUT_ int64_t*, ___OUT_ int64_t*,
                                                                   ___OUT_ int64_t*, ___OUT_ int64_t*, ___OUT_ int64_t*,
                                                                   ___OUT_ int64_t*, ___OUT_ int64_t* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepCreateInstance )( _IN____ int64_t, _IN____ int64_t,
                                                                          ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepConfigure )( _IN____ PEPHandle, _IN____ PEPCallbackSignature,
                                                                     _IN____ void*, _IN____ PEPHandle,
                                                                     ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOperationStatus )( _IN____ PEPHandle, _IN____ PEPHandle,
                                                                           _IN____ PEPBool, ___OUT_ PEPBool* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepPrepareOperation )( _IN____ PEPHandle, _IN____ PEPOperation,
                                                                            _IN____ PEPHandle, ___OUT_ PEPHandle*,
                                                                            ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepStartOperation )( _IN____ PEPHandle, _IN____ PEPOperation,
                                                                          _IN____ PEPHandle, ___OUT_ PEPHandle*,
                                                                          ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepExecuteOperation )( _IN____ PEPHandle, _IN____ PEPOperation,
                                                                            _IN____ PEPHandle, ___OUT_ PEPHandle*,
                                                                            ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepFinalizeOperation )( _IN____ PEPHandle, _IN____ PEPOperation,
                                                                             _IN____ PEPHandle, ___OUT_ PEPHandle*,
                                                                             ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepFreeInstance )( _IN____ PEPHandle );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepFinalize )();
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepUtility )( _IN____ PEPHandle, _IN____ PEPHandle,
                                                                   ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepAuxiliary )( _IN____ PEPHandle, _IN____ PEPHandle,
                                                                     ___OUT_ PEPHandle*, ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepDownloadLicense )( _IN____ PEPHandle, ___OUT_ PEPHandle* );

/* -- Linked lists handler functions -- */
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOptionListCreate )( ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOptionListGetStringElement )( _IN____ PEPHandle,
                                                                                      _IN____ const char*,
                                                                                      ___OUT_ const char** );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOptionListGetIntElement )( _IN____ PEPHandle,
                                                                                   _IN____ const char*,
                                                                                   ___OUT_ int64_t* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOptionListGetChildOptionListElement )( _IN____ PEPHandle,
                                                                                               _IN____ const char*,
                                                                                               ___OUT_ PEPHandle* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOptionListGetElementList )( _IN____ PEPHandle,
                                                                                    ___OUT_ const char** );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOptionListAddStringElement )( _IN____ PEPHandle,
                                                                                      _IN____ const char*,
                                                                                      _IN____ const char* );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOptionListAddIntElement )( _IN____ PEPHandle,
                                                                                   _IN____ const char*,
                                                                                   _IN____ int64_t iValue );
typedef PEPFunctionResult( CALLING_CONVENTION* FnPtr_pepOptionListAddChildOptionListElement )( _IN____ PEPHandle,
                                                                                               _IN____ const char*,
                                                                                               _IN____ PEPHandle );

#ifdef __cplusplus
};     /* extern "C" */
#endif /* __cplusplus */

#endif /* __pepper_h__ */
