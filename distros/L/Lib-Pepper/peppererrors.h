// clang-format off
#ifndef __peppererrors_h__
#define __peppererrors_h__

/* Function Result Codes */
/* EXTREMLY IMPORTANT: These result codes tell you if a function call was successful or not.
 * They do NOT tell you if the payment has been authorized or not. See PEPTransactionResult below for this information! */
typedef enum
{
    /* successful function call */
    pepFunctionResult_Success                                                = 0,

    /* generic/unknown failure situation (check log file) */
    pepFunctionResult_Failure_Generic                                        = -1,
    pepFunctionResult_Failure_Generic_Invalid_Value                          = -2,
    pepFunctionResult_Failure_Generic_Operation_Already_Done                 = -3,
    pepFunctionResult_Failure_Generic_Functionality_Not_Licensed             = -4,
    pepFunctionResult_Failure_Generic_Invalid_Callback_Response              = -5,

    /* ---- initialization failures ---- */
    pepFunctionResult_Failure_Library_Initialization_Generic                 = -100,
    pepFunctionResult_Failure_Library_Reused_InstanceId                      = -101,
    pepFunctionResult_Failure_Library_Loading_Error                          = -102,
    pepFunctionResult_Failure_Library_Method_Not_Found                       = -103,
    pepFunctionResult_Failure_Library_Version_Mismatch                       = -104,
    pepFunctionResult_Failure_Library_Missing_Function_Opcode                = -105,

    /* ---- config file failures ---- */
    pepFunctionResult_Failure_Configuration_Generic                          = -200,
    pepFunctionResult_Failure_Missing_Environment_variable                   = -201,
    pepFunctionResult_Failure_Missing_Configuration_File                     = -202,
    pepFunctionResult_Failure_Invalid_Xml_Structure                          = -203,
    pepFunctionResult_Failure_Configuration_Inexisting_Path                  = -204,

    /* ---- logging failures ---- */
    pepFunctionResult_Failure_Logging_Generic                                = -300,
    pepFunctionResult_Failure_Logging_Inexisting_Path                        = -301,
    pepFunctionResult_Failure_Logging_Archive_Creation                       = -302,

    /* ---- persistence failures ---- */
    pepFunctionResult_Failure_Persistence_Generic                            = -400,
    pepFunctionResult_Failure_Persistence_Initialization_Failed              = -401,
    pepFunctionResult_Failure_Persistence_Metadata_Mismatch                  = -402,
    pepFunctionResult_Failure_Persistence_Wrong_Statement                    = -403,
    pepFunctionResult_Failure_Persistence_Database_Failure                   = -404,
    pepFunctionResult_Failure_Object_Not_Found                               = -405,

    /* ---- core library failures ---- */
    pepFunctionResult_Failure_Core_Generic                                   = -500,
    pepFunctionResult_Failure_Core_Icu_Initialization_Failed                 = -501,
    pepFunctionResult_Failure_Core_Index_Out_Of_Bounds                       = -502,
    pepFunctionResult_Failure_Core_Codepage_Not_Found                        = -503,
    pepFunctionResult_Failure_Core_String_Conversion_Failed                  = -504,
    pepFunctionResult_Failure_Core_Invalid_Regex                             = -505,
    pepFunctionResult_Failure_Core_Invalid_Hexdump                           = -510,
    pepFunctionResult_Failure_Core_Stream_Too_Short                          = -511,
    pepFunctionResult_Failure_Core_Too_Few_Elements                          = -512,
    pepFunctionResult_Failure_Core_Xerces_Initialization_Failed              = -520,
    pepFunctionResult_Failure_Core_Invalid_Xml_Tag                           = -521,
    pepFunctionResult_Failure_Core_Writing_Xml_Failed                        = -522,
    pepFunctionResult_Failure_Core_Reading_Xml_Failed                        = -523,
    pepFunctionResult_Failure_Core_Parsing_Xml_Path_Failed                   = -524,
    pepFunctionResult_Failure_Core_Inexisting_Xml_Tag                        = -525,
    pepFunctionResult_Failure_Core_Path_Is_Special_File                      = -530,
    pepFunctionResult_Failure_Core_File_Operation_Failed                     = -531,
    pepFunctionResult_Failure_Core_Invalid_Path                              = -532,
    pepFunctionResult_Failure_Core_Invalid_Time                              = -540,
    pepFunctionResult_Failure_Core_Invalid_Time_String                       = -541,
    pepFunctionResult_Failure_Core_Invalid_Ip_Address                        = -550,
    pepFunctionResult_Failure_Core_Invalid_Hostname                          = -551,
    pepFunctionResult_Failure_Core_Invalid_Url                               = -552,
    pepFunctionResult_Failure_Core_Invalid_Uuid                              = -553,
    pepFunctionResult_Failure_Core_Invalid_Context                           = -554,
    pepFunctionResult_Failure_Core_Invalid_Translation_Table_Entry           = -555,
    pepFunctionResult_Failure_Core_Invalid_Time_Zone                         = -556,
	pepFunctionResult_Failure_Core_Invalid_Json_Node                         = -557,
    pepFunctionResult_Failure_Core_Invalid_Json_Node_Name                    = -558,
    pepFunctionResult_Failure_Core_Invalid_Json_Node_Value                   = -559,
    pepFunctionResult_Failure_Core_Wrong_Value_Type                          = -560,
    pepFunctionResult_Failure_Core_Json_Structure_Reading                    = -561,
    pepFunctionResult_Failure_Core_Json_Structure_Writing                    = -562,
    pepFunctionResult_Failure_Core_Json_Node_Not_Found                       = -563,
    pepFunctionResult_Failure_Core_Json_Path_Parsing                         = -564,
    pepFunctionResult_Failure_Core_Invalid_Json_Tree                         = -565,
    pepFunctionResult_Failure_Core_Invalid_Json_File_Name                    = -566,

    /* ---- domain library failures ---- */
    pepFunctionResult_Failure_Domain_Generic                                 = -600,
    pepFunctionResult_Failure_Domain_Invalid_Card_Number                     = -601,  
    pepFunctionResult_Failure_Domain_Invalid_Card_Expiration_Date            = -602,  
    pepFunctionResult_Failure_Domain_Ticket_Creation_Failed                  = -610,  
    pepFunctionResult_Failure_Domain_Invalid_Tlv_Tag                         = -620,  
    pepFunctionResult_Failure_Domain_Invalid_Tlv_Tag_Length                  = -621,  
    pepFunctionResult_Failure_Domain_Invalid_Tlv_Node                        = -622,  
    pepFunctionResult_Failure_Domain_Invalid_Country_Code                    = -630,  
    pepFunctionResult_Failure_Domain_Invalid_Iban_Format                     = -631,  
    pepFunctionResult_Failure_Domain_Invalid_Ticket_Template                 = -640,
    pepFunctionResult_Failure_Domain_Invalid_Currency                        = -650,

    /* ---- encryption library failures ---- */                                      
    pepFunctionResult_Failure_Encryption_Generic                             = -700,  
    pepFunctionResult_Failure_Encryption_Processing_Failed                   = -701,  
                                                                                     
    /* ---- license library failures ---- */                                         
    pepFunctionResult_Failure_License_Generic                                = -800,  
    pepFunctionResult_Failure_License_Invalid_Data                           = -801,  
    pepFunctionResult_Failure_License_Invalid_Key                            = -802,  
    pepFunctionResult_Failure_License_Invalid_Byte_Stream                    = -803,  
    pepFunctionResult_Failure_License_Invalid_Amount_Identifier              = -804,  
    pepFunctionResult_Failure_License_Invalid_Macro                          = -805,
    pepFunctionResult_Failure_License_Invalid_Licensee_Code                  = -850,  
    pepFunctionResult_Failure_License_Invalid_License_Keycode                = -851,  
                                                                                     
    /* ---- netlib library failures ---- */                                          
    pepFunctionResult_Failure_Netlib_Generic                                 = -900,  
    pepFunctionResult_Failure_Netlib_Unexpected_Peer_Close                   = -901,  
    pepFunctionResult_Failure_Netlib_Socket_Ressource_Error                  = -902,  
    pepFunctionResult_Failure_Netlib_Invalid_Service                         = -903,  
    pepFunctionResult_Failure_Netlib_Peer_side_Exception                     = -904,  
    pepFunctionResult_Failure_Netlib_Unexpected_End_Of_Data                  = -905,  
    pepFunctionResult_Failure_Netlib_Data_Sink_Error                         = -906,  

    /* ---- handle failures ---- */
    pepFunctionResult_Failure_Handle_Generic                                 = -1000,
    pepFunctionResult_Failure_Invalid_Handle_Value                           = -1001,
    pepFunctionResult_Failure_Wrong_Handle_For_Operation                     = -1002,

    /* ---- option failures ---- */
    pepFunctionResult_Failure_Option_Generic                                 = -1100,
    pepFunctionResult_Failure_Unknown_Option                                 = -1101,
    pepFunctionResult_Failure_Invalid_Option_Value                           = -1102,
    pepFunctionResult_Failure_Expected_Option_Unset                          = -1103,
    pepFunctionResult_Failure_Invalid_Option_Type                            = -1104,

    /* ---- instance failures ---- */
    pepFunctionResult_Failure_Instance_Generic                               = -1200,
    pepFunctionResult_Failure_Instance_Type_Invalid                          = -1201,
    pepFunctionResult_Failure_Instance_Inexisting_Context                    = -1202,
    pepFunctionResult_Failure_Instance_Unconfigured                          = -1203,

    /* ---- state machine failures ---- */
    pepFunctionResult_Failure_StateMachine_Generic                           = -1300,
    pepFunctionResult_Failure_Wrong_State                                    = -1301,

    /* ---- business check failures ---- */
    pepFunctionResult_Failure_Check_Generic                                  = -1400,
    pepFunctionResult_Failure_Check_Mandatory_Element_Unset                  = -1401,
    pepFunctionResult_Failure_Check_Invalid_Value_In_Context                 = -1402,
    pepFunctionResult_Failure_Check_Operation_Not_Supported                  = -1403,

    /* ---- card type failures ---- */
    pepFunctionResult_Failure_Cardtype_Generic                               = -1500,
    pepFunctionResult_Failure_Missing_Cardtype_File                          = -1501,
    pepFunctionResult_Failure_Invalid_Cardtype_File                          = -1502,

    /* ----high level initialization failures ---- */
    pepFunctionResult_Failure_Initialization_Generic                         = -2000,

    /* ---- communication failures ---- */
    pepFunctionResult_Failure_Communication_Generic                          = -2100,
    pepFunctionResult_Failure_Communication_Timeout                          = -2101,
    pepFunctionResult_Failure_Communication_Protocol_Error                   = -2102,
    pepFunctionResult_Failure_Communication_Unexpected_Channel_Close         = -2103,
    pepFunctionResult_Failure_Communication_Channel_Error                    = -2104,
    pepFunctionResult_Failure_Communication_Ressource_Initialization_Error   = -2105,
    pepFunctionResult_Failure_Communication_Invalid_Channel_Descriptor       = -2106,
    pepFunctionResult_Failure_Communication_Decoding_Failure                 = -2107,

    /* ==== protocol specific error codes ==== */

    /* ---- paylife specific error codes ---- */
    pepFunctionResult_PaylifeAustria_Attendant_Intervention                  = -3001,
    pepFunctionResult_PaylifeAustria_LaterDemandedCardData                   = -3002,
    pepFunctionResult_PaylifeAustria_LaterDemandedCardDataNegative           = -3003,

    /* workaround for clang */
    pepFunctionResult_ClangWorkaround                        = 100000
}
PEPFunctionResult;


/* Payment Result Codes */
typedef enum
{
    /* successful transaction
     * check output option iAmount against your input option iAmount to verify for full or partial authorization
     *
     * Remark:
     * In case of a void transaction or a reversal, the value pepTransactionResult_Authorized is returned
     * if the current void operation was successful and the flow of money has been successfully stopped.
    */
    pepTransactionResult_Authorized                              = 0,

    /* unsuccessful transaction */
    pepTransactionResult_Not_Authorized                          = -1,

    /* uncertain result */
    pepTransactionResult_Uncertain                               = -2
}
PEPTransactionResult;


#endif /* __peppererrors_h__ */
// clang-format on
