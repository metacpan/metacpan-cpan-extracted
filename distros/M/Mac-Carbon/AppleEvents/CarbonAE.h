/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/AppleEvents/CarbonAE.h,v 1.1 2002/12/10 03:06:23 pudge Exp $
 *
 *    Copyright (c) 2002 Matthias Neeracher, Chris Nandor
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: CarbonAE.h,v $
 * Revision 1.1  2002/12/10 03:06:23  pudge
 * Big update for Carbon support
 *
 * Revision 1.2  2002/11/14 12:47:58  pudge
 * Cast errno to short
 *
 * Revision 1.1  2002/11/13 02:04:50  pudge
 * Aieeeeee!  Big ol' Carbon update.
 *
 *
 */

// these aren't even used, but here's replacement macros just in case
#define CallOSACreateAppleEventProc(userRoutine, theAEEventClass, theAEEventID, target, returnID, transactionID, result, refCon) InvokeOSACreateAppleEventUPP(theAEEventClass, theAEEventID, target, returnID, transactionID, result, refCon, userRoutine)
#define CallOSASendProc(userRoutine, theAppleEvent, reply, sendMode, sendPriority, timeOutInTicks, idleProc, filterProc, refCon) InvokeOSASendUPP(theAppleEvent, reply, sendMode, sendPriority, timeOutInTicks, idleProc, filterProc, refCon, userRoutine)

/*  Carbon adds a new paramter for additional error information (see
 *  AEBuildError), but it is optional and we just pass in NULL for now.
 *  if we can find a way to return the error information (maybe in $@?),
 *  then it could be useful.
 */
AEBuildError gBuildError;
#define vAEBuild(theAppleEvent, format, args) \
	vAEBuildDesc(theAppleEvent, &gBuildError, format, args)
#define vAEBuildParameters(theAppleEvent, format, args) \
	vAEBuildParameters(theAppleEvent, &gBuildError, format, args)

// we don't use AESubDesc at all
#define AESubDesc char

/*  The current code uses AEStream, which no longer exists in Carbon.
 *  AEStreamRef exists in the old headers, and the new, and is a
 *  pointer to the AEStream structure.  Apple changed the names of
 *  all the functions, too.  So kill two birds with one set of macros.
 */
#define AEStream AEStreamRef
#define AEStream_Close(stream, desc) \
	AEStreamClose(*stream, desc)
#define AEStream_CloseDesc(stream) \
	AEStreamCloseDesc(*stream)
#define AEStream_CloseList(stream) \
	AEStreamCloseList(*stream)
#define AEStream_CloseRecord(stream) \
	AEStreamCloseRecord(*stream)
#define AEStream_Open \
	AEStreamOpen
#define AEStream_OpenDesc(stream, type) \
	AEStreamOpenDesc(*stream, type)
#define AEStream_OpenEvent	\
	AEStreamOpenEvent
#define AEStream_OpenKeyDesc(stream, key, type) \
	AEStreamOpenKeyDesc(*stream, key, type)
#define AEStream_OpenList(stream) \
	AEStreamOpenList(*stream)
#define AEStream_OpenRecord(stream, type) \
	AEStreamOpenRecord(*stream, type)
#define AEStream_OptionalParam(stream, key) \
	AEStreamOptionalParam(*stream, key)
#define AEStream_SetRecordType(stream, type) \
	AEStreamSetRecordType(*stream, type)
#define AEStream_WriteAEDesc(stream, desc) \
	AEStreamWriteAEDesc(*stream, desc)
#define AEStream_WriteData(stream, ptr, length) \
	AEStreamWriteData(*stream, ptr, length)
#define AEStream_WriteDesc(stream, type, ptr, length) \
	AEStreamWriteDesc(*stream, type, ptr, length)
#define AEStream_WriteKey(stream, key) \
	AEStreamWriteKey(*stream, key)
#define AEStream_WriteKeyDesc(stream, key, type, ptr, length) \
	AEStreamWriteKeyDesc(*stream, key, type, ptr, length)

static void pAEBuildError()
{
	sv_setpvn(ERRSV, "", 0);
	if (gBuildError.fError) {
		char * errorString;
		char * errorString2 = NewPtr(128);

		switch (gBuildError.fError) {
			case aeBuildSyntaxBadToken:
				errorString = "Illegal character";
				break;
			case aeBuildSyntaxBadEOF:
				errorString = "Unexpected end of format string";
				break;
			case aeBuildSyntaxNoEOF:
				errorString = "Unexpected extra stuff past end";
				break;
			case aeBuildSyntaxBadNegative:
				errorString = "\"-\" not followed by digits";
				break;
			case aeBuildSyntaxMissingQuote:
				errorString = "Missing close \"'\"";
				break;
			case aeBuildSyntaxBadHex:
				errorString = "Non-digit in hex string";
				break;
			case aeBuildSyntaxOddHex:
				errorString = "Odd # of hex digits";
				break;
			case aeBuildSyntaxNoCloseHex:
				errorString = "Missing \"È\"";
				break;
			case aeBuildSyntaxUncoercedHex:
				errorString = "Hex string must be coerced to a type";
				break;
			case aeBuildSyntaxNoCloseString:
				errorString = "Missing \"Ó\"";
				break;
			case aeBuildSyntaxBadDesc:
				errorString = "Illegal descriptor";
				break;
			case aeBuildSyntaxBadData:
				errorString = "Bad data value inside (É)";
				break;
			case aeBuildSyntaxNoCloseParen:
				errorString = "Missing \")\" after data value";
				break;
			case aeBuildSyntaxNoCloseBracket:
				errorString = "Expected \",\" or \"]\"";
				break;
			case aeBuildSyntaxNoCloseBrace:
				errorString = "Expected \",\" or \"}\"";
				break;
			case aeBuildSyntaxNoKey:
				errorString = "Missing keyword in record";
				break;
			case aeBuildSyntaxNoColon:
				errorString = "Missing \":\" after keyword in record";
				break;
			case aeBuildSyntaxCoercedList:
				errorString = "Cannot coerce a list";
				break;
			case aeBuildSyntaxUncoercedDoubleAt:
				errorString = "\"@@\" substitution must be coerced";
				break;
			default:
				errorString = "Unknown error";
				break;
		}

		sprintf(errorString2, "%s at character %d",
			errorString, gBuildError.fErrorPos);
		sv_setpvn(ERRSV, errorString2, strlen(errorString2));
		DisposePtr(errorString2);
	}
}
