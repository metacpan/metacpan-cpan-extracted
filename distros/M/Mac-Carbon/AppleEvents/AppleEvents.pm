=head1 NAME

Mac::AppleEvents - Macintosh Toolbox Interface to the Apple Event Manager

=head1 SYNOPSIS

	use Mac::AppleEvents;


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::AppleEvents;
use vars '$VERSION';
$VERSION = '1.32';

=head2 Constants: Apple event Descriptor Types

=over 4

=item  typeBoolean 

A boolean.

=item  typeTrue 

A boolean True value.

=item  typeFalse 

A boolean False value.

=item  typeChar 

A string.

=item  typeShortInteger 

A 16 bit integer.

=item  typeInteger 

=item  typeLongInteger 

A 32 bit integer.

=item  typeMagnitude 

An unsigned 32 bit integer.

=item  typeShortFloat 

A single precision floating point number.

=item  typeFloat 

=item  typeLongFloat 

A double precision floating point number.

=item  typeExtended 

An extended double precision floating point number.

=item  typeComp 

A 64 bit number.

=item  typeAEList 

An Apple event list.

=item  typeAERecord 

An Apple event record.

=item  typeAppleEvent 

An Apple event.

=item  typeFSS 

A file specification record.

=item  typeAlias 

A file alias record.

=item  typeEnumerated 

An enumeration literal (4 byte character).

=item  typeType 

An Apple event type (4 byte character).

=item  typeAppParameters 

An application launch parameter record.

=item  typeProperty 

A property keyword (4 byte character).

=item  typeKeyword 

A keyword (4 byte character).

=item  typeSectionH 

An Edition Manager section handle.

=item  typeWildCard 

An arbitrary value.

=item  typeApplSignature 

An application signature (4 byte character).

=item  typeQDRectangle 

A QuickDraw rectangle.

=item  typeFixed 

A fixed point value.

=item  typeSessionID 

A PPC Toolbox session ID.

=item  typeTargetID 

A target ID record.

=item  typeProcessSerialNumber 

A process serial number.

=item  typeNull 

No data.

=back

=cut

BEGIN {
sub typeBoolean					() { 'bool' }
sub typeChar					() { 'TEXT' }
sub typeSMInt					() { 'shor' }
sub typeInteger					() { 'long' }
sub typeSMFloat					() { 'sing' }
sub typeFloat					() { 'doub' }
sub typeLongInteger				() { 'long' }
sub typeShortInteger				() { 'shor' }
sub typeLongFloat				() { 'doub' }
sub typeShortFloat				() { 'sing' }
sub typeExtended				() { 'exte' }
sub typeComp					() { 'comp' }
sub typeMagnitude				() { 'magn' }
sub typeAEList					() { 'list' }
sub typeAERecord				() { 'reco' }
sub typeAppleEvent				() { 'aevt' }
sub typeTrue					() { 'true' }
sub typeFalse					() { 'fals' }
sub typeAlias					() { 'alis' }
sub typeEnumerated				() { 'enum' }
sub typeType					() { 'type' }
sub typeAppParameters				() { 'appa' }
sub typeProperty				() { 'prop' }
sub typeFSS					() { 'fss ' }
sub typeKeyword					() { 'keyw' }
sub typeSectionH				() { 'sect' }
sub typeWildCard				() { '****' }
sub typeApplSignature				() { 'sign' }
sub typeQDRectangle				() { 'qdrt' }
sub typeFixed					() { 'fixd' }
sub typeSessionID				() { 'ssid' }
sub typeTargetID				() { 'targ' }
sub typeProcessSerialNumber			() { 'psn ' }
sub typeNull					() { 'null' }

# registry
sub typeAEText					() { 'tTXT' }
sub typeArc					() { 'carc' }
sub typeBest					() { 'best' }
sub typeCell					() { 'ccel' }
sub typeClassInfo				() { 'gcli' }
sub typeColorTable				() { 'clrt' }
sub typeColumn					() { 'ccol' }
sub typeDashStyle				() { 'tdas' }
sub typeData					() { 'tdta' }
sub typeDrawingArea				() { 'cdrw' }
sub typeElemInfo				() { 'elin' }
sub typeEnumeration				() { 'enum' }
sub typeEPS					() { 'EPS ' }
sub typeEventInfo				() { 'evin' }
sub typeFinderWindow				() { 'fwin' }
sub typeFixedPoint				() { 'fpnt' }
sub typeFixedRectangle				() { 'frct' }
sub typeGraphicLine				() { 'glin' }
sub typeGraphicText				() { 'cgtx' }
sub typeGroupedGraphic				() { 'cpic' }
sub typeInsertionLoc				() { 'insl' }
sub typeIntlText				() { 'itxt' }
sub typeIntlWritingCode				() { 'intl' }
sub typeLongDateTime				() { 'ldt ' }
sub typeISO8601DateTime				() { 'isot' }
sub typeLongFixed				() { 'lfxd' }
sub typeLongFixedPoint				() { 'lfpt' }
sub typeLongFixedRectangle			() { 'lfrc' }
sub typeLongPoint				() { 'lpnt' }
sub typeLongRectangle				() { 'lrct' }
sub typeMachineLoc				() { 'mLoc' }
sub typeOval					() { 'covl' }
sub typeParamInfo				() { 'pmin' }
sub typePict					() { 'PICT' }
sub typePixelMap				() { 'cpix' }
sub typePixMapMinus				() { 'tpmm' }
sub typePolygon					() { 'cpgn' }
sub typePropInfo				() { 'pinf' }
sub typePtr					() { 'ptr ' }
sub typeQDPoint					() { 'QDpt' }
sub typeQDRegion				() { 'Qrgn' }
sub typeRectangle				() { 'crec' }
sub typeRGB16					() { 'tr16' }
sub typeRGB96					() { 'tr96' }
sub typeRGBColor				() { 'cRGB' }
sub typeRotation				() { 'trot' }
sub typeRoundedRectangle			() { 'crrc' }
sub typeRow					() { 'crow' }
sub typeScrapStyles				() { 'styl' }
sub typeScript					() { 'scpt' }
sub typeStyledText				() { 'STXT' }
sub typeSuiteInfo				() { 'suin' }
sub typeTable					() { 'ctbl' }
sub typeTextStyles				() { 'tsty' }
sub typeTIFF					() { 'TIFF' }
sub typeVersion					() { 'vers' }
sub typeUnicodeText				() { 'utxt' }
sub typeStyledUnicodeText			() { 'sutx' }
sub typeUTF8Text				() { 'utf8' }
sub typeEncodedString				() { 'encs' }
sub typeCString					() { 'cstr' }
sub typePString					() { 'pstr' }
sub typeMeters					() { 'metr' }
sub typeInches					() { 'inch' }
sub typeFeet					() { 'feet' }
sub typeYards					() { 'yard' }
sub typeMiles					() { 'mile' }
sub typeKilometers				() { 'kmtr' }
sub typeCentimeters				() { 'cmtr' }
sub typeSquareMeters				() { 'sqrm' }
sub typeSquareFeet				() { 'sqft' }
sub typeSquareYards				() { 'sqyd' }
sub typeSquareMiles				() { 'sqmi' }
sub typeSquareKilometers			() { 'sqkm' }
sub typeLiters					() { 'litr' }
sub typeQuarts					() { 'qrts' }
sub typeGallons					() { 'galn' }
sub typeCubicMeters				() { 'cmet' }
sub typeCubicFeet				() { 'cfet' }
sub typeCubicInches				() { 'cuin' }
sub typeCubicCentimeter				() { 'ccmt' }
sub typeCubicYards				() { 'cyrd' }
sub typeKilograms				() { 'kgrm' }
sub typeGrams					() { 'gram' }
sub typeOunces					() { 'ozs ' }
sub typePounds					() { 'lbs ' }
sub typeDegreesC				() { 'degc' }
sub typeDegreesF				() { 'degf' }
sub typeDegreesK				() { 'degk' }


# new ... document and arrange later
# there's more, incl. stuff for SOAP, that we may include later
sub typeSInt16					() { 'shor' }
sub typeSInt32					() { 'long' }
sub typeUInt32					() { 'magn' }
sub typeSInt64					() { 'comp' }
sub typeIEEE32BitFloatingPoint			() { 'sing' }
sub typeIEEE64BitFloatingPoint			() { 'doub' }
sub type128BitFloatingPoint			() { 'ldbl' }
sub typeDecimalStruct				() { 'decm' }

sub typeFSRef					() { 'fsrf' }
sub typeFileURL					() { 'furl' }

sub kAEShowPreferences				() { 'pref' }

sub typeApplicationURL				() { 'aprl' }
sub typeKernelProcessID				() { 'kpid' }
sub typeMachPort				() { 'port' }
sub typeApplicationBundleID			() { 'bund' }

sub keyAcceptTimeoutAttr			() { 'actm' }




=head2 Constants: Parameter and Attribute Keywords

=over 4

=item  keyDirectObject 

The direct object parameter.

=item  keyErrorNumber 

Error number.

=item  keyErrorString 

Error string.

=item  keyProcessSerialNumber 

Process serial number.

=item  keyTransactionIDAttr 

Transaction ID.

=item  keyReturnIDAttr 

Return ID.

=item  keyEventClassAttr 

Event class.

=item  keyEventIDAttr 

Event ID.

=item  keyAddressAttr 

Destination address.

=item  keyOptionalKeywordAttr 

List of optional keywords.

=item  keyTimeoutAttr 

Timeout limit.

=item  keyInteractLevelAttr 

Interaction level.

=item  keyEventSourceAttr 

Event source address.

=item  keyMissedKeywordAttr 

List of mandatory keywords not used.

=item  keyOriginalAddressAttr 

Original source address.

=item  keyPreDispatch 

Install handler before dispatching.

=item  keySelectProc 

Enable/Disable OSL.

=item  keyAERecorderCount 

Number of processes recording AppleEvents.

=item  keyAEVersion 

Apple Event Manager version.

=back

=cut
sub keyDirectObject				() { '----' }
sub keyErrorNumber				() { 'errn' }
sub keyErrorString				() { 'errs' }
sub keyProcessSerialNumber			() { 'psn ' }
sub keyTransactionIDAttr			() { 'tran' }
sub keyReturnIDAttr				() { 'rtid' }
sub keyEventClassAttr				() { 'evcl' }
sub keyEventIDAttr				() { 'evid' }
sub keyAddressAttr				() { 'addr' }
sub keyOptionalKeywordAttr			() { 'optk' }
sub keyTimeoutAttr				() { 'timo' }
sub keyInteractLevelAttr			() { 'inte' }
sub keyEventSourceAttr				() { 'esrc' }
sub keyMissedKeywordAttr			() { 'miss' }
sub keyOriginalAddressAttr			() { 'from' }
sub keyPreDispatch				() { 'phac' }
sub keySelectProc				() { 'selh' }
sub keyAERecorderCount				() { 'recr' }
sub keyAEVersion				() { 'vers' }

=head2 Constants: Core Apple event Suite

=over 4

=item  kCoreEventClass 

Core Suite Event class.

=item  kAEOpenApplication 

Open application without documents.

=item  kAEOpenDocuments 

Open documents.

=item  kAEPrintDocuments 

Print documents.

=item  kAEQuitApplication 

Quit application.

=item  kAEAnswer 

Apple event answer event.

=item  kAEApplicationDied 

Launched application has ended.

=back

=cut
sub kCoreEventClass				() { 'aevt' }
sub kAEOpenApplication				() { 'oapp' }
sub kAEOpenDocuments				() { 'odoc' }
sub kAEPrintDocuments				() { 'pdoc' }
sub kAEQuitApplication				() { 'quit' }
sub kAEAnswer					() { 'ansr' }
sub kAEApplicationDied				() { 'obit' }

=head2 Constants: Miscellaneous

=over 4

=item  kAENoReply 

=item  kAEQueueReply 

=item  kAEWaitReply 

=item  kAENeverInteract 

=item  kAECanInteract 

=item  kAEAlwaysInteract 

=item  kAECanSwitchLayer 

=item  kAEDontReconnect 

=item  kAEWantReceipt 

=item  kAEDontRecord 

=item  kAEDontExecute 

=item  kAEInteractWithSelf 

=item  kAEInteractWithLocal 

=item  kAEInteractWithAll 

Apple event sendMode flags.

=cut
sub kAENoReply					() { 0x00000001 }
sub kAEQueueReply				() { 0x00000002 }
sub kAEWaitReply				() { 0x00000003 }
sub kAENeverInteract				() { 0x00000010 }
sub kAECanInteract				() { 0x00000020 }
sub kAEAlwaysInteract				() { 0x00000030 }
sub kAECanSwitchLayer				() { 0x00000040 }
sub kAEDontReconnect				() { 0x00000080 }
sub kAEWantReceipt				() { 0x00000200 }
sub kAEDontRecord				() { 0x00001000 }
sub kAEDontExecute				() { 0x00002000 }
sub kAEInteractWithSelf				() { 0 }
sub kAEInteractWithLocal			() { 1 }
sub kAEInteractWithAll				() { 2 }

=item  kAENormalPriority 

=item  kAEHighPriority 

Apple event priority values.

=cut
sub kAENormalPriority				() { 0x00000000 }
sub kAEHighPriority				() { 0x00000001 }

=item  kAEStartRecording 

=item  kAEStopRecording 

=item  kAENotifyStartRecording 

=item  kAENotifyStopRecording 

=item  kAENotifyRecording 

Recording events.

=cut
sub kAEStartRecording				() { 'reca' }
sub kAEStopRecording				() { 'recc' }
sub kAENotifyStartRecording			() { 'rec1' }
sub kAENotifyStopRecording			() { 'rec0' }
sub kAENotifyRecording				() { 'recr' }

=item  kAutoGenerateReturnID 

=item  kAnyTransactionID 

=item  kAEDefaultTimeout 

=item  kNoTimeOut 

Special values for return ID, transaction ID, and timeout.

=cut
sub kAutoGenerateReturnID			() { -1 }
sub kAnyTransactionID				() {  0 }
sub kAEDefaultTimeout				() { -1 }
sub kNoTimeOut					() { -2 }

=item  kAENoDispatch 

=item  kAEUseStandardDispatch 

=item  kAEDoNotIgnoreHandler 

=item  kAEIgnoreAppPhacHandler 

=item  kAEIgnoreAppEventHandler 

=item  kAEIgnoreSysPhacHandler 

=item  kAEIgnoreSysEventHandler 

=item  kAEIngoreBuiltInEventHandler 

=item  kAEDontDisposeOnResume 

Options for C<AEResumeTheCurrentEvent()>.

=back

=cut
sub kAENoDispatch				() { 0 }
sub kAEUseStandardDispatch			() { 0xFFFFFFFF }
sub kAEDoNotIgnoreHandler			() { 0x00000000 }
sub kAEIgnoreAppPhacHandler			() { 0x00000001 }
sub kAEIgnoreAppEventHandler			() { 0x00000002 }
sub kAEIgnoreSysPhacHandler			() { 0x00000004 }
sub kAEIgnoreSysEventHandler			() { 0x00000008 }
sub kAEIngoreBuiltInEventHandler		() { 0x00000010 }
sub kAEDontDisposeOnResume			() { 0x80000000 }

sub kAEUnknownSource				() { 0 }
sub kAEDirectCall				() { 1 }
sub kAESameProcess				() { 2 }
sub kAELocalProcess				() { 3 }
sub kAERemoteProcess				() { 4 }
sub kAEDataArray				() { 0 }
sub kAEPackedArray				() { 1 }
sub kAEHandleArray				() { 2 }
sub kAEDescArray				() { 3 }
sub kAEKeyDescArray				() { 4 }


# more more more!

sub kAEAND					() { 'AND ' }
sub kAEOR					() { 'OR  ' }
sub kAENOT					() { 'NOT ' }

sub kAEFirst					() { 'firs' }
sub kAEMiddle					() { 'midd' }
sub kAELast					() { 'last' }
sub kAEAny					() { 'any ' }
sub kAEAll					() { 'all ' }

sub kAENext					() { 'next' }
sub kAEPrevious					() { 'prev' }

sub keyAEDesiredClass				() { 'want' }
sub keyAEContainer				() { 'from' }
sub keyAEForm					() { 'form' }
sub keyAEKeyData				() { 'seld' }

sub keyAERangeStart				() { 'star' }
sub keyAERangeStop				() { 'stop' }

sub keyAEObject                 		() { 'kobj' }
sub keyAEPosition               		() { 'kpos' }
sub kAEBefore                   		() { 'befo' }
sub kAEAfter                    		() { 'afte' }
sub kAEBeginning                		() { 'bgng' }
sub kAEEnd                      		() { 'end ' }

sub formAbsolutePosition			() { 'indx' }
sub formRelativePosition			() { 'rele' }
sub formTest					() { 'test' }
sub formRange					() { 'rang' }
sub formPropertyID				() { 'prop' }
sub formName					() { 'name' }
sub formUniqueID				() { 'ID  ' }

sub typeObjectSpecifier				() { 'obj ' }
sub typeObjectBeingExamined			() { 'exmn' }
sub typeCurrentContainer			() { 'ccnt' }
sub typeToken					() { 'toke' }
sub typeAbsoluteOrdinal				() { 'abso' }
sub typeRangeDescriptor				() { 'rang' }
sub typeLogicalDescriptor			() { 'logi' }
sub typeCompDescriptor				() { 'cmpd' }

sub keyAECompOperator				() { 'relo' }
sub keyAELogicalTerms				() { 'term' }
sub keyAELogicalOperator			() { 'logc' }
sub keyAEObject1    				() { 'obj1' }
sub keyAEObject2    				() { 'obj2' }

sub kAEGreaterThan              		() { '>   ' }
sub kAEGreaterThanEquals        		() { '>=  ' }
sub kAEEquals                   		() { '=   ' }
sub kAELessThan                 		() { '<   ' }
sub kAELessThanEquals           		() { '<=  ' }
sub kAEBeginsWith               		() { 'bgwt' }
sub kAEEndsWith                 		() { 'ends' }
sub kAEContains                 		() { 'cont' }

}

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	use Mac::Memory;
	
	use vars qw(@ISA @EXPORT %AppleEvent %SysAppleEvent);
	
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		AECreateDesc
		AECoerce
		AECoerceDesc
		AEDisposeDesc
		AEDuplicateDesc
		AECreateList
		AECountItems
		AEPut
		AEPutDesc
		AEGetNthDesc
		AEDeleteItem
		AEPutParam
		AEPutParamDesc
		AEGetParamDesc
		AEDeleteParam
		AEGetAttributeDesc
		AEPutAttribute
		AEPutAttributeDesc
		AECreateAppleEvent
		AESend
		AEResetTimer
		AESuspendTheCurrentEvent
		AEResumeTheCurrentEvent
		AEGetTheCurrentEvent
		AESetTheCurrentEvent
		AEGetInteractionAllowed
		AESetInteractionAllowed
		AEInstallEventHandler
		AERemoveEventHandler
		AEGetEventHandler
		AEManagerInfo
		AEBuild
		AEBuildParameters
		AEBuildAppleEvent
		AEPrint
		AEDescToSubDesc
		AEGetSubDescType
		AEGetSubDescBasicType
		AESubDescIsListOrRecord
		AEGetSubDescData
		AESubDescToDesc
		AECountSubDescItems
		AEGetNthSubDesc
		AEGetKeySubDesc
		
		%AppleEvent
		%SysAppleEvent
		typeBoolean
		typeChar
		typeInteger
		typeFloat
		typeLongInteger
		typeShortInteger
		typeLongFloat
		typeShortFloat
		typeExtended
		typeComp
		typeMagnitude
		typeAEList
		typeAERecord
		typeAppleEvent
		typeTrue
		typeFalse
		typeAlias
		typeEnumerated
		typeType
		typeAppParameters
		typeProperty
		typeFSS
		typeKeyword
		typeSectionH
		typeWildCard
		typeApplSignature
		typeQDRectangle
		typeFixed
		typeSessionID
		typeTargetID
		typeProcessSerialNumber
		typeNull

		typeAEText
		typeArc
		typeBest
		typeCell
		typeClassInfo
		typeColorTable
		typeColumn
		typeDashStyle
		typeData
		typeDrawingArea
		typeElemInfo
		typeEnumeration
		typeEPS
		typeEventInfo
		typeFinderWindow
		typeFixedPoint
		typeFixedRectangle
		typeGraphicLine
		typeGraphicText
		typeGroupedGraphic
		typeInsertionLoc
		typeIntlText
		typeIntlWritingCode
		typeLongDateTime
		typeISO8601DateTime
		typeLongFixed
		typeLongFixedPoint
		typeLongFixedRectangle
		typeLongPoint
		typeLongRectangle
		typeMachineLoc
		typeOval
		typeParamInfo
		typePict
		typePixelMap
		typePixMapMinus
		typePolygon
		typePropInfo
		typePtr
		typeQDPoint
		typeQDRegion
		typeRectangle
		typeRGB16
		typeRGB96
		typeRGBColor
		typeRotation
		typeRoundedRectangle
		typeRow
		typeScrapStyles
		typeScript
		typeStyledText
		typeSuiteInfo
		typeTable
		typeTextStyles
		typeTIFF
		typeVersion
		typeUnicodeText
		typeStyledUnicodeText
		typeUTF8Text
		typeEncodedString
		typeCString
		typePString
		typeMeters
		typeInches
		typeFeet
		typeYards
		typeMiles
		typeKilometers
		typeCentimeters
		typeSquareMeters
		typeSquareFeet
		typeSquareYards
		typeSquareMiles
		typeSquareKilometers
		typeLiters
		typeQuarts
		typeGallons
		typeCubicMeters
		typeCubicFeet
		typeCubicInches
		typeCubicCentimeter
		typeCubicYards
		typeKilograms
		typeGrams
		typeOunces
		typePounds
		typeDegreesC
		typeDegreesF
		typeDegreesK

		typeSInt16
		typeSInt32
		typeUInt32
		typeSInt64
		typeIEEE32BitFloatingPoint
		typeIEEE64BitFloatingPoint
		type128BitFloatingPoint
		typeDecimalStruct

		typeFSRef
		typeFileURL

		kAEShowPreferences

		typeApplicationURL
		typeKernelProcessID
		typeMachPort
		typeApplicationBundleID

		keyAcceptTimeoutAttr


		keyDirectObject
		keyErrorNumber
		keyErrorString
		keyProcessSerialNumber
		keyTransactionIDAttr
		keyReturnIDAttr
		keyEventClassAttr
		keyEventIDAttr
		keyAddressAttr
		keyOptionalKeywordAttr
		keyTimeoutAttr
		keyInteractLevelAttr
		keyEventSourceAttr
		keyMissedKeywordAttr
		keyOriginalAddressAttr
		keyPreDispatch
		keySelectProc
		keyAERecorderCount
		keyAEVersion
		kCoreEventClass
		kAEOpenApplication
		kAEOpenDocuments
		kAEPrintDocuments
		kAEQuitApplication
		kAEAnswer
		kAEApplicationDied
		kAENoReply
		kAEQueueReply
		kAEWaitReply
		kAENeverInteract
		kAECanInteract
		kAEAlwaysInteract
		kAECanSwitchLayer
		kAEDontReconnect
		kAEWantReceipt
		kAEDontRecord
		kAEDontExecute
		kAENormalPriority
		kAEHighPriority
		kAEStartRecording
		kAEStopRecording
		kAENotifyStartRecording
		kAENotifyStopRecording
		kAENotifyRecording
		kAutoGenerateReturnID
		kAnyTransactionID
		kAEDefaultTimeout
		kNoTimeOut
		kAENoDispatch
		kAEUseStandardDispatch
		kAEDoNotIgnoreHandler
		kAEIgnoreAppPhacHandler
		kAEIgnoreAppEventHandler
		kAEIgnoreSysPhacHandler
		kAEIgnoreSysEventHandler
		kAEIngoreBuiltInEventHandler
		kAEDontDisposeOnResume
		kAEInteractWithSelf
		kAEInteractWithLocal
		kAEInteractWithAll
		kAEUnknownSource
		kAEDirectCall
		kAESameProcess
		kAELocalProcess
		kAERemoteProcess
		kAEDataArray
		kAEPackedArray
		kAEHandleArray
		kAEDescArray
		kAEKeyDescArray

		AEPutKey
		AEPutKeyDesc
		AEGetKeyDesc

		kAEAND
		kAEOR
		kAENOT

		kAEFirst
		kAEMiddle
		kAELast
		kAEAny
		kAEAll

		kAENext
		kAEPrevious

		keyAEDesiredClass
		keyAEContainer
		keyAEForm
		keyAEKeyData

		keyAERangeStart
		keyAERangeStop

		keyAEObject
		keyAEPosition
		kAEBefore
		kAEAfter
		kAEBeginning
		kAEEnd
		kAEReplace

		formAbsolutePosition
		formRelativePosition
		formTest
		formRange
		formPropertyID
		formName
		formUniqueID

		typeObjectSpecifier
		typeObjectBeingExamined
		typeCurrentContainer
		typeToken
		typeAbsoluteOrdinal
		typeRangeDescriptor
		typeLogicalDescriptor
		typeCompDescriptor

		keyAECompOperator
		keyAELogicalTerms
		keyAELogicalOperator
		keyAEObject1
		keyAEObject2

		kAEGreaterThan
		kAEGreaterThanEquals
		kAEEquals
		kAELessThan
		kAELessThanEquals
		kAEBeginsWith
		kAEEndsWith
		kAEContains
	);
}

bootstrap Mac::AppleEvents;

package Mac::AppleEvents::EventHandler;

BEGIN {
	import Mac::AppleEvents;

	use Carp;
}

sub TIEHASH
{
	my ($package,$sys) = @_;
	my($me) = bless {SYS => $sys};
	
	return $me;
}

sub ParseKey 
{
	my($key) = @_;
	
	return (substr($key, 0, 4), substr($key, -4));
}

sub FETCH 
{
	my($sys,$key)  = @_;
	my(@keys) = ParseKey $key;

	my ($handler, $refcon) = AEGetEventHandler(@keys, $sys->{SYS});
	
	return wantarray ? ($handler,$refcon) : $handler;
}


sub STORE 
{
	my($sys,$key,$handler,$refcon) = @_;
	my(@keys) = ParseKey $key;
	
	$refcon = $key unless defined $refcon;
	
	AEInstallEventHandler(@keys, $handler, $refcon, $sys->{SYS}) || die;
}

sub DELETE 
{
	my($sys,$key)  = @_;
	my(@keys) = ParseKey $key;
	
	AERemoveEventHandler(@keys, $sys->{SYS});
}

sub DESTROY 
{
	my($sys)  = @_;
	
	undef %{$sys};
}

sub FIRSTKEY { croak "Mac::AppleEvents::EventHandler::FIRSTKEY is not implemented" }
sub NEXTKEY { croak "Mac::AppleEvents::EventHandler::NEXTKEY is not implemented" }
sub EXISTS { croak "Mac::AppleEvents::EventHandler::EXISTS is not implemented" }
sub CLEAR { croak "Mac::AppleEvents::EventHandler::CLEAR is not implemented" }

package Mac::AppleEvents;

=head2 Variables

=over 4

=item %AppleEvent

An array of application-wide event handlers.

   $AppleEvent{"aevt", "odoc"} = \&OpenDocument;

=item %SysAppleEvent

An arrary of system-wide event handlers.

=back

=cut
tie %AppleEvent, 	q(Mac::AppleEvents::EventHandler), 0;
tie %SysAppleEvent,	q(Mac::AppleEvents::EventHandler), 1;

my(%constant) = (
	"true" => 1,
	"fals" => 0,
	"null" => "",
);

package AEDesc;

=head2 AEDesc

AEDesc is a Perl package that encapsulates an Apple Event Descriptor.
It uses the OO methods of Perl5 to make building and parsing data structures
easier.

=over 4

=item new TYPE, HANDLE

=item new TYPE, DATA

=item new TYPE

=item new

Create a new Apple event descriptor.
Sets the type and data to TYPE (default is 'null'), and HANDLE or DATA 
(default is empty).

	$desc = new AEDesc("aevt", $event);

=item type TYPE

=item type

Return the type from the AEDesc structure.  
If TYPE is present, make it the new type.

=item data HANDLE

=item data

Return the data from the AEDesc structure. If HANDLE is present, make
it the new data.

B<Warning>: If using Mac OS X, you must dispose of the result on your own.
This is because in Mac OS, we returned the handle from the AEDesc itself,
but now we must return a copy.  So in Mac OS we could do:

	print $desc->data->get;

Now we must do:

	my $handle = $desc->data;
	print $handle->get;
	$handle->dispose;

Normally, you don't want to call C<data> directly anyway, and you would
use C<get> instead.

=item get

Return the data of the AEDesc structure in a smartly unpacked way.

=item dispose

Dispose the AEDesc.

=back

=cut

BEGIN {
	use Mac::Types;
}

sub new {
	my($package, $type, $data) = @_;
	
	$data = "" unless defined($data);
	my $return;
	if (ref($data) ne "Handle") {
		$return = _new($package, $type, new Handle($data));
	} else {
		$return = _new(@_);
	}

	return $return;
}

sub get () {
	my($desc) = @_;
	my($type) = $desc->type;
	
	if (exists($constant{$type})) {
		return $constant{$type};
	} else {
		my $handle = $desc->data;
		my $return = $handle->get;
		$handle->dispose unless $^O eq 'MacOS';
		if (defined($return) && exists($MacUnpack{$type})) {
			return MacUnpack($type, $return);
		}
		return $return;
	}
}

sub dispose {
	Mac::AppleEvents::AEDisposeDesc($_[0]);
}

package AESubDesc;

BEGIN {
	use Mac::Types;
	import Mac::AppleEvents;
}

sub get () {
	my($desc) = @_;
	my($type) = AEGetSubDescType($desc);
	
	if (exists($constant{$type})) {
		return $constant{$type};
	} elsif (exists($MacUnpack{$type})) {
		return MacUnpack($type, AEGetSubDescData($desc));
	} else {
		my($aedesc, $res) = AESubDescToDesc($desc);
		$res = AEPrint($aedesc);
		AEDisposeDesc($aedesc);
		
		return $res;
	}
}

package AEKeyDesc;

=head2 AEKeyDesc

AEKeyDesc is a Perl package that encapsulates an Apple event keyword.
It uses the OO methods of Perl5 to make building and parsing data structures
easier.

=over 4

=item new KEY, TYPE, HANDLE

=item new KEY, TYPE, DATA

=item new KEY, TYPE

=item new KEY

=item new

Creates a new Apple event keyword descriptor.
Sets the keyword, type and data to KEY (default is zero),
TYPE (default is 'null'), and HANDLE or DATA (default is empty).

=item key KEY

=item key

Return the keyword of the AEKeyDesc structure.
If KEY is present, make it the new keyword.

=item type TYPE

=item type

Return the type from the AEKeyDesc structure.  If TYPE is present, make it the new type.

=item data HANDLE

=item data

Return the data from the AEKeyDesc structure. If HANDLE is present, make
it the new data.

=item get

Return the contents in a smartly unpacked way.

=item dispose

Dispose the underlying AEDesc.

=back

=cut

sub new {
	my($package, $key, $type, $data) = @_;

	$data = "" unless defined($data);
	my $return;
	if (ref($data) ne "Handle") {
		$return = _new($package, $key, $type, new Handle($data));
	} else {
		$return = _new(@_);
	}
	return $return;
}

sub dispose {
	Mac::AppleEvents::AEDisposeDesc($_[0]->desc);
}

*AEKeyDesc::get = *AEDesc::get{CODE};

package AEStream;

sub new {
	my($package) = shift @_;
	
	if (!scalar(@_)) {
		Open();
	} elsif (scalar(@_) == 1) {
		OpenEvent(@_);
	} else {
		CreateEvent(@_);
	}
}

=include AppleEvents.xs

=head1 AUTHOR

Written by Matthias Ulrich Neeracher E<lt>neeracher@mac.comE<gt>,
documentation by Bob Dalgleish E<lt>bob.dalgleish@sasknet.sk.caE<gt>.
Currently maintained by Chris Nandor E<lt>pudge@pobox.comE<gt>.

=cut
1;

__END__
