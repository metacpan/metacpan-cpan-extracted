<?php
//
// +----------------------------------------------------------------------+
// | PHP Version 4                                                        |
// +----------------------------------------------------------------------+
// | Copyright (c) 1997-2003 The PHP Group                                |
// +----------------------------------------------------------------------+
// | This source file is subject to version 2.02 of the PHP license,      |
// | that is bundled with this package in the file LICENSE, and is        |
// | available at through the world-wide-web at                           |
// | http://www.php.net/license/2_02.txt.                                 |
// | If you did not receive a copy of the PHP license and are unable to   |
// | obtain it through the world-wide-web, please send a note to          |
// | license@php.net so we can mail you a copy immediately.               |
// +----------------------------------------------------------------------+
// | Author: Alexios Fakos (alexios@php.net)                              |
// +----------------------------------------------------------------------+
//
//
// $Id: ado_constants.php,v 1.3 2003/01/04 11:54:52 mj Exp $
//


/**
 * Database independent query interface definition for Microsoft's ADODB
 * library using PHP's COM extension
 *
 * @author   Alexios Fakos <alexios@php.net>
 * @version  $Revision: 1.3 $
 * @package  DB_ado
 */


//  CursorTypeEnum Values  //
    define('adOpenForwardOnly', 0);
    define('adOpenKeyset', 1);
    define('adOpenDynamic', 2);
    define('adOpenStatic', 3);

//  CursorOptionEnum Values  //
    define('adHoldRecords', 256);
    define('adMovePrevious', 512);
    define('adAddNew', 16778240);
    define('adDelete', 16779264);
    define('adUpdate', 16809984);
    define('adBookmark', 8192);
    define('adApproxPosition', 16384);
    define('adUpdateBatch', 65536);
    define('adResync', 131072);
    define('adNotify', 262144);
    define('adFind', 524288);
    define('adSeek', 4194304);
    define('adIndex', 8388608);

//  LockTypeEnum Values  //
    define('adLockReadOnly', 1);
    define('adLockPessimistic', 2);
    define('adLockOptimistic', 3);
    define('adLockBatchOptimistic', 4);

//  ExecuteOptionEnum Values  //
    define('adAsyncExecute', 16);
    define('adAsyncFetch', 32);
    define('adAsyncFetchNonBlocking', 64);
    define('adExecuteNoRecords', 128);
    define('adExecuteStream', 1024);

//  ConnectOptionEnum Values  //
    define('adAsyncConnect', 16);

//  ObjectStateEnum Values  //
    define('adStateClosed', 0);
    define('adStateOpen', 1);
    define('adStateConnecting', 2);
    define('adStateExecuting', 4);
    define('adStateFetching', 8);

//  CursorLocationEnum Values  //
    define('adUseServer', 2);
    define('adUseClient', 3);

//  DataTypeEnum Values  //
    define('adEmpty', 0);
    define('adTinyInt', 16);
    define('adSmallInt', 2);
    define('adInteger', 3);
    define('adBigInt', 20);
    define('adUnsignedTinyInt', 17);
    define('adUnsignedSmallInt', 18);
    define('adUnsignedInt', 19);
    define('adUnsignedBigInt', 21);
    define('adSingle', 4);
    define('adDouble', 5);
    define('adCurrency', 6);
    define('adDecimal', 14);
    define('adNumeric', 131);
    define('adBoolean', 11);
    define('adError', 10);
    define('adUserDefined', 132);
    define('adVariant', 12);
    define('adIDispatch', 9);
    define('adIUnknown', 13);
    define('adGUID', 72);
    define('adDate', 7);
    define('adDBDate', 133);
    define('adDBTime', 134);
    define('adDBTimeStamp', 135);
    define('adBSTR', 8);
    define('adChar', 129);
    define('adVarChar', 200);
    define('adLongVarChar', 201);
    define('adWChar', 130);
    define('adVarWChar', 202);
    define('adLongVarWChar', 203);
    define('adBinary', 128);
    define('adVarBinary', 204);
    define('adLongVarBinary', 205);
    define('adChapter', 136);
    define('adFileTime', 64);
    define('adPropVariant', 138);
    define('adVarNumeric', 139);
    define('adArray', 8192);

//  FieldAttributeEnum Values  //
    define('adFldMayDefer', 2);
    define('adFldUpdatable', 4);
    define('adFldUnknownUpdatable', 8);
    define('adFldFixed', 16);
    define('adFldIsNullable', 32);
    define('adFldMayBeNull', 64);
    define('adFldLong', 128);
    define('adFldRowID', 256);
    define('adFldRowVersion', 512);
    define('adFldCacheDeferred', 4096);
    define('adFldIsChapter', 8192);
    define('adFldNegativeScale', 16384);
    define('adFldKeyColumn', 32768);
    define('adFldIsRowURL', 65536);
    define('adFldIsDefaultStream', 131072);
    define('adFldIsCollection', 262144);

//  EditModeEnum Values  //
    define('adEditNone', 0);
    define('adEditInProgress', 1);
    define('adEditAdd', 2);
    define('adEditDelete', 4);

//  RecordStatusEnum Values  //
    define('adRecOK', 0);
    define('adRecNew', 1);
    define('adRecModified', 2);
    define('adRecDeleted', 4);
    define('adRecUnmodified', 8);
    define('adRecInvalid', 16);
    define('adRecMultipleChanges', 64);
    define('adRecPendingChanges', 128);
    define('adRecCanceled', 256);
    define('adRecCantRelease', 1024);
    define('adRecConcurrencyViolation', 2048);
    define('adRecIntegrityViolation', 4096);
    define('adRecMaxChangesExceeded', 8192);
    define('adRecObjectOpen', 16384);
    define('adRecOutOfMemory', 32768);
    define('adRecPermissionDenied', 65536);
    define('adRecSchemaViolation', 131072);
    define('adRecDBDeleted', 262144);

//  GetRowsOptionEnum Values  //
    define('adGetRowsRest', -1);

//  PositionEnum Values  //
    define('adPosUnknown', -1);
    define('adPosBOF', -2);
    define('adPosEOF', -3);

//  BookmarkEnum Values  //
    define('adBookmarkCurrent', 0);
    define('adBookmarkFirst', 1);
    define('adBookmarkLast', 2);

//  MarshalOptionsEnum Values  //
    define('adMarshalAll', 0);
    define('adMarshalModifiedOnly', 1);

//  AffectEnum Values  //
    define('adAffectCurrent', 1);
    define('adAffectGroup', 2);
    define('adAffectAllChapters', 4);

//  ResyncEnum Values  //
    define('adResyncUnderlyingValues', 1);
    define('adResyncAllValues', 2);

//  CompareEnum Values  //
    define('adCompareLessThan', 0);
    define('adCompareEqual', 1);
    define('adCompareGreaterThan', 2);
    define('adCompareNotEqual', 3);
    define('adCompareNotComparable', 4);

//  FilterGroupEnum Values  //
    define('adFilterNone', 0);
    define('adFilterPendingRecords', 1);
    define('adFilterAffectedRecords', 2);
    define('adFilterFetchedRecords', 3);
    define('adFilterConflictingRecords', 5);

//  SearchDirectionEnum Values  //
    define('adSearchForward', 1);
    define('adSearchBackward', -1);

//  PersistFormatEnum Values  //
    define('adPersistADTG', 0);
    define('adPersistXML', 1);

//  StringFormatEnum Values  //
    define('adClipString', 2);

//  ConnectPromptEnum Values  //
    define('adPromptAlways', 1);
    define('adPromptComplete', 2);
    define('adPromptCompleteRequired', 3);
    define('adPromptNever', 4);

//  ConnectModeEnum Values  //
    define('adModeUnknown', 0);
    define('adModeRead', 1);
    define('adModeWrite', 2);
    define('adModeReadWrite', 3);
    define('adModeShareDenyRead', 4);
    define('adModeShareDenyWrite', 8);
    define('adModeShareExclusive', 12);
    define('adModeShareDenyNone', 16);
    define('adModeRecursive', 4194304);

//  RecordCreateOptionsEnum Values  //
    define('adCreateCollection', 8192);
    define('adCreateStructDoc', -2147483648);
    define('adCreateNonCollection', 0);
    define('adOpenIfExists', 33554432);
    define('adCreateOverwrite', 67108864);
    define('adFailIfNotExists', -1);

//  RecordOpenOptionsEnum Values  //
    define('adOpenRecordUnspecified', -1);
    define('adOpenOutput', 8388608);
    define('adOpenAsync', 4096);
    define('adDelayFetchStream', 16384);
    define('adDelayFetchFields', 32768);
    define('adOpenExecuteCommand', 65536);

//  IsolationLevelEnum Values  //
    define('adXactUnspecified', -1);
    define('adXactChaos', 16);
    define('adXactReadUncommitted', 256);
    define('adXactBrowse', 256);
    define('adXactCursorStability', 4096);
    define('adXactReadCommitted', 4096);
    define('adXactRepeatableRead', 65536);
    define('adXactSerializable', 1048576);
    define('adXactIsolated', 1048576);

//  XactAttributeEnum Values  //
    define('adXactCommitRetaining', 131072);
    define('adXactAbortRetaining', 262144);

//  PropertyAttributesEnum Values  //
    define('adPropNotSupported', 0);
    define('adPropRequired', 1);
    define('adPropOptional', 2);
    define('adPropRead', 512);
    define('adPropWrite', 1024);

//  ErrorValueEnum Values  //
    define('adErrProviderFailed', 3000);
    define('adErrInvalidArgument', 3001);
    define('adErrOpeningFile', 3002);
    define('adErrReadFile', 3003);
    define('adErrWriteFile', 3004);
    define('adErrNoCurrentRecord', 3021);
    define('adErrIllegalOperation', 3219);
    define('adErrCantChangeProvider', 3220);
    define('adErrInTransaction', 3246);
    define('adErrFeatureNotAvailable', 3251);
    define('adErrItemNotFound', 3265);
    define('adErrObjectInCollection', 3367);
    define('adErrObjectNotSet', 3420);
    define('adErrDataConversion', 3421);
    define('adErrObjectClosed', 3704);
    define('adErrObjectOpen', 3705);
    define('adErrProviderNotFound', 3706);
    define('adErrBoundToCommand', 3707);
    define('adErrInvalidParamInfo', 3708);
    define('adErrInvalidConnection', 3709);
    define('adErrNotReentrant', 3710);
    define('adErrStillExecuting', 3711);
    define('adErrOperationCancelled', 3712);
    define('adErrStillConnecting', 3713);
    define('adErrInvalidTransaction', 3714);
    define('adErrUnsafeOperation', 3716);
    define('adwrnSecurityDialog', 3717);
    define('adwrnSecurityDialogHeader', 3718);
    define('adErrIntegrityViolation', 3719);
    define('adErrPermissionDenied', 3720);
    define('adErrDataOverflow', 3721);
    define('adErrSchemaViolation', 3722);
    define('adErrSignMismatch', 3723);
    define('adErrCantConvertvalue', 3724);
    define('adErrCantCreate', 3725);
    define('adErrColumnNotOnThisRow', 3726);
    define('adErrURLIntegrViolSetColumns', 3727);
    define('adErrURLDoesNotExist', 3727);
    define('adErrTreePermissionDenied', 3728);
    define('adErrInvalidURL', 3729);
    define('adErrResourceLocked', 3730);
    define('adErrResourceExists', 3731);
    define('adErrCannotComplete', 3732);
    define('adErrVolumeNotFound', 3733);
    define('adErrOutOfSpace', 3734);
    define('adErrResourceOutOfScope', 3735);
    define('adErrUnavailable', 3736);
    define('adErrURLNamedRowDoesNotExist', 3737);
    define('adErrDelResOutOfScope', 3738);
    define('adErrPropInvalidColumn', 3739);
    define('adErrPropInvalidOption', 3740);
    define('adErrPropInvalidValue', 3741);
    define('adErrPropConflicting', 3742);
    define('adErrPropNotAllSettable', 3743);
    define('adErrPropNotSet', 3744);
    define('adErrPropNotSettable', 3745);
    define('adErrPropNotSupported', 3746);
    define('adErrCatalogNotSet', 3747);
    define('adErrCantChangeConnection', 3748);
    define('adErrFieldsUpdateFailed', 3749);
    define('adErrDenyNotSupported', 3750);
    define('adErrDenyTypeNotSupported', 3751);

//  ParameterAttributesEnum Values  //
    define('adParamSigned', 16);
    define('adParamNullable', 64);
    define('adParamLong', 128);

//  ParameterDirectionEnum Values  //
    define('adParamUnknown', 0);
    define('adParamInput', 1);
    define('adParamOutput', 2);
    define('adParamInputOutput', 3);
    define('adParamReturnValue', 4);

//  CommandTypeEnum Values  //
    define('adCmdUnknown', 8);
    define('adCmdText', 1);
    define('adCmdTable', 2);
    define('adCmdStoredProc', 4);
    define('adCmdFile', 256);
    define('adCmdTableDirect', 512);

//  EventStatusEnum Values  //
    define('adStatusOK', 1);
    define('adStatusErrorsOccurred', 2);
    define('adStatusCantDeny', 3);
    define('adStatusCancel', 4);
    define('adStatusUnwantedEvent', 5);

//  EventReasonEnum Values  //
    define('adRsnAddNew', 1);
    define('adRsnDelete', 2);
    define('adRsnUpdate', 3);
    define('adRsnUndoUpdate', 4);
    define('adRsnUndoAddNew', 5);
    define('adRsnUndoDelete', 6);
    define('adRsnRequery', 7);
    define('adRsnResynch', 8);
    define('adRsnClose', 9);
    define('adRsnMove', 10);
    define('adRsnFirstChange', 11);
    define('adRsnMoveFirst', 12);
    define('adRsnMoveNext', 13);
    define('adRsnMovePrevious', 14);
    define('adRsnMoveLast', 15);

//  SchemaEnum Values  //
    define('adSchemaProviderSpecific', -1);
    define('adSchemaAsserts', 0);
    define('adSchemaCatalogs', 1);
    define('adSchemaCharacterSets', 2);
    define('adSchemaCollations', 3);
    define('adSchemaColumns', 4);
    define('adSchemaCheckConstraints', 5);
    define('adSchemaConstraintColumnUsage', 6);
    define('adSchemaConstraintTableUsage', 7);
    define('adSchemaKeyColumnUsage', 8);
    define('adSchemaReferentialConstraints', 9);
    define('adSchemaTableConstraints', 10);
    define('adSchemaColumnsDomainUsage', 11);
    define('adSchemaIndexes', 12);
    define('adSchemaColumnPrivileges', 13);
    define('adSchemaTablePrivileges', 14);
    define('adSchemaUsagePrivileges', 15);
    define('adSchemaProcedures', 16);
    define('adSchemaSchemata', 17);
    define('adSchemaSQLLanguages', 18);
    define('adSchemaStatistics', 19);
    define('adSchemaTables', 20);
    define('adSchemaTranslations', 21);
    define('adSchemaProviderTypes', 22);
    define('adSchemaViews', 23);
    define('adSchemaViewColumnUsage', 24);
    define('adSchemaViewTableUsage', 25);
    define('adSchemaProcedureParameters', 26);
    define('adSchemaForeignKeys', 27);
    define('adSchemaPrimaryKeys', 28);
    define('adSchemaProcedureColumns', 29);
    define('adSchemaDBInfoKeywords', 30);
    define('adSchemaDBInfoLiterals', 31);
    define('adSchemaCubes', 32);
    define('adSchemaDimensions', 33);
    define('adSchemaHierarchies', 34);
    define('adSchemaLevels', 35);
    define('adSchemaMeasures', 36);
    define('adSchemaProperties', 37);
    define('adSchemaMembers', 38);
    define('adSchemaTrustees', 39);
    define('adSchemaFunctions', 40);
    define('adSchemaActions', 41);
    define('adSchemaCommands', 42);
    define('adSchemaSets', 43);

//  FieldStatusEnum Values  //
    define('adFieldOK', 0);
    define('adFieldCantConvertValue', 2);
    define('adFieldIsNull', 3);
    define('adFieldTruncated', 4);
    define('adFieldSignMismatch', 5);
    define('adFieldDataOverflow', 6);
    define('adFieldCantCreate', 7);
    define('adFieldUnavailable', 8);
    define('adFieldPermissionDenied', 9);
    define('adFieldIntegrityViolation', 10);
    define('adFieldSchemaViolation', 11);
    define('adFieldBadStatus', 12);
    define('adFieldDefault', 13);
    define('adFieldIgnore', 15);
    define('adFieldDoesNotExist', 16);
    define('adFieldInvalidURL', 17);
    define('adFieldResourceLocked', 18);
    define('adFieldResourceExists', 19);
    define('adFieldCannotComplete', 20);
    define('adFieldVolumeNotFound', 21);
    define('adFieldOutOfSpace', 22);
    define('adFieldCannotDeleteSource', 23);
    define('adFieldReadOnly', 24);
    define('adFieldResourceOutOfScope', 25);
    define('adFieldAlreadyExists', 26);
    define('adFieldPendingInsert', 65536);
    define('adFieldPendingDelete', 131072);
    define('adFieldPendingChange', 262144);
    define('adFieldPendingUnknown', 524288);
    define('adFieldPendingUnknownDelete', 1048576);

//  SeekEnum Values  //
    define('adSeekFirstEQ', 1);
    define('adSeekLastEQ', 2);
    define('adSeekAfterEQ', 4);
    define('adSeekAfter', 8);
    define('adSeekBeforeEQ', 16);
    define('adSeekBefore', 32);

//  ADCPROP_UPDATECRITERIA_ENUM Values  //
    define('adCriteriaKey', 0);
    define('adCriteriaAllCols', 1);
    define('adCriteriaUpdCols', 2);
    define('adCriteriaTimeStamp', 3);

//  ADCPROP_ASYNCTHREADPRIORITY_ENUM Values  //
    define('adPriorityLowest', 1);
    define('adPriorityBelowNormal', 2);
    define('adPriorityNormal', 3);
    define('adPriorityAboveNormal', 4);
    define('adPriorityHighest', 5);

//  ADCPROP_AUTORECALC_ENUM Values  //
    define('adRecalcUpFront', 0);
    define('adRecalcAlways', 1);

//  ADCPROP_UPDATERESYNC_ENUM Values  //

//  ADCPROP_UPDATERESYNC_ENUM Values  //

//  MoveRecordOptionsEnum Values  //
    define('adMoveUnspecified', -1);
    define('adMoveOverWrite', 1);
    define('adMoveDontUpdateLinks', 2);
    define('adMoveAllowEmulation', 4);

//  CopyRecordOptionsEnum Values  //
    define('adCopyUnspecified', -1);
    define('adCopyOverWrite', 1);
    define('adCopyAllowEmulation', 4);
    define('adCopyNonRecursive', 2);

//  StreamTypeEnum Values  //
    define('adTypeBinary', 1);
    define('adTypeText', 2);

//  LineSeparatorEnum Values  //
    define('adLF', 10);
    define('adCR', 13);
    define('adCRLF', -1);

//  StreamOpenOptionsEnum Values  //
    define('adOpenStreamUnspecified', -1);
    define('adOpenStreamAsync', 1);
    define('adOpenStreamFromRecord', 4);

//  StreamWriteEnum Values  //
    define('adWriteChar', 0);
    define('adWriteLine', 1);

//  SaveOptionsEnum Values  //
    define('adSaveCreateNotExist', 1);
    define('adSaveCreateOverWrite', 2);

//  FieldEnum Values  //
    define('adDefaultStream', -1);
    define('adRecordURL', -2);

//  StreamReadEnum Values  //
    define('adReadAll', -1);
    define('adReadLine', -2);

//  RecordTypeEnum Values  //
    define('adSimpleRecord', 0);
    define('adCollectionRecord', 1);
    define('adStructDoc', 2);
?>