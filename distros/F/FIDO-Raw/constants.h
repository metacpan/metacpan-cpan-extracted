#define OPT_OMIT  FIDO_OPT_OMIT
#define OPT_FALSE FIDO_OPT_FALSE
#define OPT_TRUE  FIDO_OPT_TRUE

#define EXT_HMAC_SECRET   FIDO_EXT_HMAC_SECRET
#define EXT_CRED_PROTECT  FIDO_EXT_CRED_PROTECT

#define CRED_PROT_UV_OPTIONAL          FIDO_CRED_PROT_UV_OPTIONAL
#define CRED_PROT_UV_OPTIONAL_WITH_ID  FIDO_CRED_PROT_UV_OPTIONAL_WITH_ID
#define CRED_PROT_UV_REQUIRED          FIDO_CRED_PROT_UV_REQUIRED

#define	ERR_SUCCESS FIDO_ERR_SUCCESS
#define ERR_INVALID_COMMAND FIDO_ERR_INVALID_COMMAND
#define ERR_INVALID_PARAMETER FIDO_ERR_INVALID_PARAMETER
#define ERR_INVALID_LENGTH FIDO_ERR_INVALID_LENGTH
#define ERR_INVALID_SEQ FIDO_ERR_INVALID_SEQ
#define ERR_TIMEOUT FIDO_ERR_TIMEOUT
#define ERR_CHANNEL_BUSY FIDO_ERR_CHANNEL_BUSY
#define ERR_LOCK_REQUIRED FIDO_ERR_LOCK_REQUIRED
#define ERR_INVALID_CHANNEL FIDO_ERR_INVALID_CHANNEL
#define ERR_CBOR_UNEXPECTED_TYPE FIDO_ERR_CBOR_UNEXPECTED_TYPE
#define ERR_INVALID_CBOR FIDO_ERR_INVALID_CBOR
#define ERR_MISSING_PARAMETER FIDO_ERR_MISSING_PARAMETER
#define ERR_LIMIT_EXCEEDED FIDO_ERR_LIMIT_EXCEEDED
#define ERR_UNSUPPORTED_EXTENSION FIDO_ERR_UNSUPPORTED_EXTENSION
#define ERR_CREDENTIAL_EXCLUDED FIDO_ERR_CREDENTIAL_EXCLUDED
#define ERR_PROCESSING FIDO_ERR_PROCESSING
#define ERR_INVALID_CREDENTIAL FIDO_ERR_INVALID_CREDENTIAL
#define ERR_USER_ACTION_PENDING FIDO_ERR_USER_ACTION_PENDING
#define ERR_OPERATION_PENDING FIDO_ERR_OPERATION_PENDING
#define ERR_NO_OPERATIONS FIDO_ERR_NO_OPERATIONS
#define ERR_UNSUPPORTED_ALGORITHM FIDO_ERR_UNSUPPORTED_ALGORITHM
#define ERR_OPERATION_DENIED FIDO_ERR_OPERATION_DENIED
#define ERR_KEY_STORE_FULL FIDO_ERR_KEY_STORE_FULL
#define ERR_NOT_BUSY FIDO_ERR_NOT_BUSY
#define ERR_NO_OPERATION_PENDING FIDO_ERR_NO_OPERATION_PENDING
#define ERR_UNSUPPORTED_OPTION FIDO_ERR_UNSUPPORTED_OPTION
#define ERR_INVALID_OPTION FIDO_ERR_INVALID_OPTION
#define ERR_KEEPALIVE_CANCEL FIDO_ERR_KEEPALIVE_CANCEL
#define ERR_NO_CREDENTIALS FIDO_ERR_NO_CREDENTIALS
#define ERR_USER_ACTION_TIMEOUT FIDO_ERR_USER_ACTION_TIMEOUT
#define ERR_NOT_ALLOWED FIDO_ERR_NOT_ALLOWED
#define ERR_PIN_INVALID FIDO_ERR_PIN_INVALID
#define ERR_PIN_BLOCKED FIDO_ERR_PIN_BLOCKED
#define ERR_PIN_AUTH_INVALID FIDO_ERR_PIN_AUTH_INVALID
#define ERR_PIN_AUTH_BLOCKED FIDO_ERR_PIN_AUTH_BLOCKED
#define ERR_PIN_NOT_SET FIDO_ERR_PIN_NOT_SET
#define ERR_PIN_REQUIRED FIDO_ERR_PIN_REQUIRED
#define ERR_PIN_POLICY_VIOLATION FIDO_ERR_PIN_POLICY_VIOLATION
#define ERR_PIN_TOKEN_EXPIRED FIDO_ERR_PIN_TOKEN_EXPIRED
#define ERR_REQUEST_TOO_LARGE FIDO_ERR_REQUEST_TOO_LARGE
#define ERR_ACTION_TIMEOUT FIDO_ERR_ACTION_TIMEOUT
#define ERR_UP_REQUIRED FIDO_ERR_UP_REQUIRED
#define ERR_UV_BLOCKED FIDO_ERR_UV_BLOCKED
#define ERR_ERR_OTHER FIDO_ERR_ERR_OTHER
#define ERR_SPEC_LAST FIDO_ERR_SPEC_LAST


#define OK FIDO_OK
#define ERR_TX FIDO_ERR_TX
#define ERR_RX FIDO_ERR_RX
#define ERR_RX_NOT_CBOR FIDO_ERR_RX_NOT_CBOR
#define ERR_RX_INVALID_CBOR FIDO_ERR_RX_INVALID_CBOR
#define ERR_INVALID_PARAM FIDO_ERR_INVALID_PARAM
#define ERR_INVALID_SIG FIDO_ERR_INVALID_SIG
#define ERR_INVALID_ARGUMENT FIDO_ERR_INVALID_ARGUMENT
#define ERR_USER_PRESENCE_REQUIRED FIDO_ERR_USER_PRESENCE_REQUIRED
#define ERR_INTERNAL FIDO_ERR_INTERNAL

#include "const-c-constant.inc"

#undef OPT_OMIT
#undef OPT_FALSE
#undef OPT_TRUE

#undef EXT_HMAC_SECRET
#undef EXT_CRED_PROTECT

#undef CRED_PROT_UV_OPTIONAL
#undef CRED_PROT_UV_OPTIONAL_WITH_ID
#undef CRED_PROT_UV_REQUIRED

#undef ERR_SUCCESS
#undef ERR_INVALID_COMMAND
#undef ERR_INVALID_PARAMETER
#undef ERR_INVALID_LENGTH
#undef ERR_INVALID_SEQ
#undef ERR_TIMEOUT
#undef ERR_CHANNEL_BUSY
#undef ERR_LOCK_REQUIRED
#undef ERR_INVALID_CHANNEL
#undef ERR_CBOR_UNEXPECTED_TYPE
#undef ERR_INVALID_CBOR
#undef ERR_MISSING_PARAMETER
#undef ERR_LIMIT_EXCEEDED
#undef ERR_UNSUPPORTED_EXTENSION
#undef ERR_CREDENTIAL_EXCLUDED
#undef ERR_PROCESSING
#undef ERR_INVALID_CREDENTIAL
#undef ERR_USER_ACTION_PENDING
#undef ERR_OPERATION_PENDING
#undef ERR_NO_OPERATIONS
#undef ERR_UNSUPPORTED_ALGORITHM
#undef ERR_OPERATION_DENIED
#undef ERR_KEY_STORE_FULL
#undef ERR_NOT_BUSY
#undef ERR_NO_OPERATION_PENDING
#undef ERR_UNSUPPORTED_OPTION
#undef ERR_INVALID_OPTION
#undef ERR_KEEPALIVE_CANCEL
#undef ERR_NO_CREDENTIALS
#undef ERR_USER_ACTION_TIMEOUT
#undef ERR_NOT_ALLOWED
#undef ERR_PIN_INVALID
#undef ERR_PIN_BLOCKED
#undef ERR_PIN_AUTH_INVALID
#undef ERR_PIN_AUTH_BLOCKED
#undef ERR_PIN_NOT_SET
#undef ERR_PIN_REQUIRED
#undef ERR_PIN_POLICY_VIOLATION
#undef ERR_PIN_TOKEN_EXPIRED
#undef ERR_REQUEST_TOO_LARGE
#undef ERR_ACTION_TIMEOUT
#undef ERR_UP_REQUIRED
#undef ERR_UV_BLOCKED
#undef ERR_ERR_OTHER
#undef ERR_SPEC_LAST

#undef OK
#undef ERR_TX
#undef ERR_RX
#undef ERR_RX_NOT_CBOR
#undef ERR_RX_INVALID_CBOR
#undef ERR_INVALID_PARAM
#undef ERR_INVALID_SIG
#undef ERR_INVALID_ARGUMENT
#undef ERR_USER_PRESENCE_REQUIRED
#undef ERR_INTERNAL

