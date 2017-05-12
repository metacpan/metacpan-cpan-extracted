/*
 * Extensions for the PCF Command Set
 *
 * $Id: cmqcfce.h,v 33.5 2012/09/26 16:15:24 jettisu Exp $
 *
 * (c) 1999-2012 Morgan Stanley & Co. Incorporated
 * See ..../src/LICENSE for terms of distribution.
 *
 */

#if !defined(MQCFCE_INCLUDED)    /* File not yet included? */
#define MQCFCE_INCLUDED

#if defined(__cplusplus)
extern "C" {
#endif

#define MQCMDE_INQUIRE_AUTHORITY		1000L
#define MQCMDE_CHANGE_AUTHORITY			1001L

#define MQIAE_OBJECT_TYPE			1000L
#define MQIAE_ENTITY_TYPE			1001L

#define MQIAE_AUTH_CONNECT			1011L
#define MQIAE_AUTH_BROWSE			1012L
#define MQIAE_AUTH_INPUT			1013L
#define MQIAE_AUTH_OUTPUT			1014L
#define MQIAE_AUTH_INQUIRE			1015L
#define MQIAE_AUTH_SET				1016L
#define MQIAE_AUTH_PASSID			1017L
#define MQIAE_AUTH_PASSALL			1018L
#define MQIAE_AUTH_SETID			1019L
#define MQIAE_AUTH_SETALL			1020L
#define MQIAE_AUTH_ALTERNATEUSER		1021L
#define MQIAE_AUTH_CREATE			1022L
#define MQIAE_AUTH_DELETE			1023L
#define MQIAE_AUTH_DISPLAY			1024L
#define MQIAE_AUTH_CHANGE			1025L
#define MQIAE_AUTH_CLEAR			1026L
#define MQIAE_AUTH_AUTHORIZE			1027L
#define MQIAE_AUTH_START_STOP			1028L
#define MQIAE_AUTH_DISPLAY_STATUS		1029L
#define MQIAE_AUTH_RESOLVE_RESET		1030L
#define MQIAE_AUTH_PING				1031L

#define MQIAE_AUTH_ALLADMIN			1050L
#define MQIAE_AUTH_ALLMQI			1051L
#define MQIAE_AUTH_ALL				1052L

#define MQCAE_OBJECT_NAME			3000L
#define MQCAE_ENTITY_NAME			3001L

#define MQIA64E_EXPIRES_AT                      4000L
#define MQIAE_EXPIRES_AFTER                     4001L

#define MQAUTH_YES				1L
#define MQAUTH_NO				0L

#define MQETE_PRINCIPAL				1000L
#define MQETE_GROUP				1001L
#define MQETE_AFS_GROUP				1002L

#if defined(__cplusplus)
}
#endif

#endif  /* End of header file */
