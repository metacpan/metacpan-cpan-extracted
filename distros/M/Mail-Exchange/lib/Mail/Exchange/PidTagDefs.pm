
package Mail::Exchange::PidTagDefs;
use Exporter;
use vars qw(@ISA @EXPORTER);
@ISA=qw(Exporter);
@EXPORT=qw(%PidTagDefs);

our %PidTagDefs=(
0x0001 => { type => 0x0102, name => "PidTagTemplateData" }, # Describes the controls used in the template that is used to retrieve address book information.
0x0002 => { type => 0x000b, name => "PidTagAlternateRecipientAllowed" }, # Specifies whether the sender permits the message to be auto-forwarded.
0x0004 => { type => 0x001f, name => "PidTagAutoForwardComment" }, # Contains text included in an automatically-generated message.
0x0004 => { type => 0x0102, name => "PidTagScriptData" }, # Contains a series of instructions that can be executed to format an address and the data that is needed to execute those instructions.
0x0005 => { type => 0x000b, name => "PidTagAutoForwarded" }, # 
0x000f => { type => 0x0040, name => "PidTagDeferredDeliveryTime" }, # Contains the date and time, in UTC, at which the sender prefers that the message be delivered.
0x0015 => { type => 0x0040, name => "PidTagExpiryTime" }, # Contains the time, in UTC, after which a client wants to receive an expiry event if the message arrives late.
0x0017 => { type => 0x0003, name => "PidTagImportance" }, # Indicates the level of importance assigned by the end user to the Message object.
0x001a => { type => 0x001f, name => "PidTagMessageClass" }, # Denotes the specific type of the Message object.
0x0023 => { type => 0x000b, name => "PidTagOriginatorDeliveryReportRequested" }, # Indicates whether an e-mail sender requests an e-mail delivery receipt from the messaging system.
0x0025 => { type => 0x0102, name => "PidTagParentKey" }, # Contains the search key that is used to correlate the original message and the reports about the original message.
0x0026 => { type => 0x0003, name => "PidTagPriority" }, # Indicates the client's request for the priority with which the message is to be sent by the messaging system.
0x0029 => { type => 0x000b, name => "PidTagReadReceiptRequested" }, # Specifies whether the e-mail sender requests a read receipt from all recipients (1) when this e-mail message is read or opened.
0x002b => { type => 0x000b, name => "PidTagRecipientReassignmentProhibited" }, # Specifies whether adding additional or different recipients (1) is prohibited for the e-mail message when forwarding the e-mail message.
0x002e => { type => 0x0003, name => "PidTagOriginalSensitivity" }, # Contains the sensitivity value of the original e-mail message.
0x0030 => { type => 0x0040, name => "PidTagReplyTime" }, # Specifies the time, in UTC, that the sender has designated for an associated work item to be due.
0x0031 => { type => 0x0102, name => "PidTagReportTag" }, # Contains the data that is used to correlate the report and the original message.
0x0032 => { type => 0x0040, name => "PidTagReportTime" }, # 
0x0036 => { type => 0x0003, name => "PidTagSensitivity" }, # Indicates the sender's assessment of the sensitivity of the Message object.
0x0037 => { type => 0x001f, name => "PidTagSubject" }, # Contains the subject of the e-mail message.
0x0039 => { type => 0x0040, name => "PidTagClientSubmitTime" }, # Contains the current time, in UTC, when the e-mail message is submitted.
0x003a => { type => 0x001f, name => "PidTagReportName" }, # Contains the display name for the entity (usually a server agent) that generated the report message.
0x003b => { type => 0x0102, name => "PidTagSentRepresentingSearchKey" }, # Contains a binary-comparable key that represents the end user who is represented by the sending mailbox owner.
0x003d => { type => 0x001f, name => "PidTagSubjectPrefix" }, # Contains the prefix for the subject of the message.
0x003f => { type => 0x0102, name => "PidTagReceivedByEntryId" }, # Contains the address book EntryID of the mailbox receiving the E-mail object.
0x0040 => { type => 0x001f, name => "PidTagReceivedByName" }, # Contains the e-mail message receiver's display name.
0x0041 => { type => 0x0102, name => "PidTagSentRepresentingEntryId" }, # Contains the identifier of the end user who is represented by the sending mailbox owner.
0x0042 => { type => 0x001f, name => "PidTagSentRepresentingName" }, # Contains the display name for the end user who is represented by the sending mailbox owner.
0x0043 => { type => 0x0102, name => "PidTagReceivedRepresentingEntryId" }, # Contains an address book EntryID that identifies the end user represented by the receiving mailbox owner.
0x0044 => { type => 0x001f, name => "PidTagReceivedRepresentingName" }, # Contains the display name for the end user represented by the receiving mailbox owner.
0x0045 => { type => 0x0102, name => "PidTagReportEntryId" }, # Specifies whether a reply to the e-mail message is requested by the e-mail message's sender.
0x0046 => { type => 0x0102, name => "PidTagReadReceiptEntryId" }, # Contains an address book EntryID.
0x0047 => { type => 0x0102, name => "PidTagMessageSubmissionId" }, # Contains a message identifier assigned by a message transfer agent.
0x0048 => { type => 0x0040, name => "PidTagProviderSubmitTime" }, # 
0x0049 => { type => 0x001f, name => "PidTagOriginalSubject" }, # Specifies the subject of the original message.
0x004b => { type => 0x001f, name => "PidTagOriginalMessageClass" }, # 
0x004c => { type => 0x0102, name => "PidTagOriginalAuthorEntryId" }, # Contains an address book EntryID structure ([MS-OXCDATA] section 2.2.5.2) and is defined in report messages to identify the user who sent the original message.
0x004d => { type => 0x001f, name => "PidTagOriginalAuthorName" }, # Contains the display name of the sender of the original message referenced by a report message.
0x004e => { type => 0x0040, name => "PidTagOriginalSubmitTime" }, # Specifies the original e-mail message's submission date and time, in UTC.
0x004f => { type => 0x0102, name => "PidTagReplyRecipientEntries" }, # 
0x0050 => { type => 0x001f, name => "PidTagReplyRecipientNames" }, # Contains a list of display names for recipients (1) that are to receive a reply.
0x0051 => { type => 0x0102, name => "PidTagReceivedBySearchKey" }, # Identifies an address book search key that contains a binary-comparable key that is used to identify correlated objects for a search.
0x0052 => { type => 0x0102, name => "PidTagReceivedRepresentingSearchKey" }, # Identifies an address book search key that contains a binary-comparable key of the end user represented by the receiving mailbox owner.
0x0053 => { type => 0x0102, name => "PidTagReadReceiptSearchKey" }, # Contains an address book search key.
0x0054 => { type => 0x0102, name => "PidTagReportSearchKey" }, # Contains an address book search key representing the entity (usually a server agent) that generated the report message.
0x0055 => { type => 0x0040, name => "PidTagOriginalDeliveryTime" }, # Contains the delivery time, in UTC, from the original message.
0x0057 => { type => 0x000b, name => "PidTagMessageToMe" }, # Indicates that the receiving mailbox owner is one of the primary recipients of this e-mail message.
0x0058 => { type => 0x000b, name => "PidTagMessageCcMe" }, # 
0x0059 => { type => 0x000b, name => "PidTagMessageRecipientMe" }, # Indicates that the receiving mailbox owner is a primary or a carbon copy (Cc) recipient of this e-mail message.
0x005a => { type => 0x001f, name => "PidTagOriginalSenderName" }, # 
0x005b => { type => 0x0102, name => "PidTagOriginalSenderEntryId" }, # Contains an address book EntryID that is set on delivery report messages.
0x005c => { type => 0x0102, name => "PidTagOriginalSenderSearchKey" }, # Contains an address book search key set on the original e-mail message.
0x005d => { type => 0x001f, name => "PidTagOriginalSentRepresentingName" }, # Contains the display name of the end user who is represented by the original e-mail message sender.
0x005e => { type => 0x0102, name => "PidTagOriginalSentRepresentingEntryId" }, # Identifies an address book EntryID that contains the entry identifier of the end user who is represented by the original message sender.
0x005f => { type => 0x0102, name => "PidTagOriginalSentRepresentingSearchKey" }, # Identifies an address book search key that contains the SearchKey of the end user who is represented by the original message sender.
0x0060 => { type => 0x0040, name => "PidTagStartDate" }, # 
0x0061 => { type => 0x0040, name => "PidTagEndDate" }, # 
0x0062 => { type => 0x0003, name => "PidTagOwnerAppointmentId" }, # Specifies a quasi-unique value among all of the Calendar objects in a user's mailbox.
0x0063 => { type => 0x000b, name => "PidTagResponseRequested" }, # Indicates whether a response is requested to a Message object.
0x0064 => { type => 0x001f, name => "PidTagSentRepresentingAddressType" }, # Contains an e-mail address type.
0x0065 => { type => 0x001f, name => "PidTagSentRepresentingEmailAddress" }, # Contains an e-mail address for the end user who is represented by the sending mailbox owner.
0x0066 => { type => 0x001f, name => "PidTagOriginalSenderAddressType" }, # 
0x0067 => { type => 0x001f, name => "PidTagOriginalSenderEmailAddress" }, # 
0x0068 => { type => 0x001f, name => "PidTagOriginalSentRepresentingAddressType" }, # Contains the address type of the end user who is represented by the original e-mail message sender.
0x0069 => { type => 0x001f, name => "PidTagOriginalSentRepresentingEmailAddress" }, # Contains the e-mail address of the end user who is represented by the original e-mail message sender.
0x0070 => { type => 0x001f, name => "PidTagConversationTopic" }, # Contains an unchanging copy of the original subject.
0x0071 => { type => 0x0102, name => "PidTagConversationIndex" }, # Indicates the relative position of this message within a conversation thread.
0x0072 => { type => 0x001f, name => "PidTagOriginalDisplayBcc" }, # 
0x0073 => { type => 0x001f, name => "PidTagOriginalDisplayCc" }, # 
0x0074 => { type => 0x001f, name => "PidTagOriginalDisplayTo" }, # 
0x0075 => { type => 0x001f, name => "PidTagReceivedByAddressType" }, # Contains the e-mail message receiver's e-mail address type.
0x0076 => { type => 0x001f, name => "PidTagReceivedByEmailAddress" }, # Contains the e-mail message receiver's e-mail address.
0x0077 => { type => 0x001f, name => "PidTagReceivedRepresentingAddressType" }, # Contains the e-mail address type for the end user represented by the receiving mailbox owner.
0x0078 => { type => 0x001f, name => "PidTagReceivedRepresentingEmailAddress" }, # Contains the e-mail address for the end user represented by the receiving mailbox owner.
0x007d => { type => 0x001f, name => "PidTagTransportMessageHeaders" }, # Contains transport-specific message envelope information for e-mail.
0x007f => { type => 0x0102, name => "PidTagTnefCorrelationKey" }, # Contains a value that correlates a Transport Neutral Encapsulation Format (TNEF) attachment with a message.
0x0080 => { type => 0x001f, name => "PidTagReportDisposition" }, # Contains a string indicating whether the original message was displayed to the user or deleted (report messages only).
0x0081 => { type => 0x001f, name => "PidTagReportDispositionMode" }, # Contains a description of the action that a client has performed on behalf of a user (report messages only).
0x0807 => { type => 0x0003, name => "PidTagAddressBookRoomCapacity" }, # Contains the maximum occupancy of the room.
0x0809 => { type => 0x001f, name => "PidTagAddressBookRoomDescription" }, # Contains a description of the Resource object.
0x0c06 => { type => 0x000b, name => "PidTagNonReceiptNotificationRequested" }, # Specifies whether the client sends a non-read receipt.
0x0c08 => { type => 0x000b, name => "PidTagOriginatorNonDeliveryReportRequested" }, # Specifies whether an e-mail sender requests suppression of nondelivery receipts.
0x0c15 => { type => 0x0003, name => "PidTagRecipientType" }, # Represents the recipient (1) type of a recipient (1) on the message.
0x0c17 => { type => 0x000b, name => "PidTagReplyRequested" }, # Indicates whether a reply is requested to a Message object.
0x0c19 => { type => 0x0102, name => "PidTagSenderEntryId" }, # Identifies an address book EntryID that contains the address book EntryID of the sending mailbox owner.
0x0c1a => { type => 0x001f, name => "PidTagSenderName" }, # Contains the display name of the sending mailbox owner.
0x0c1d => { type => 0x0102, name => "PidTagSenderSearchKey" }, # Identifies an address book search key.
0x0c1e => { type => 0x001f, name => "PidTagSenderAddressType" }, # Contains the e-mail address type of the sending mailbox owner.
0x0c1f => { type => 0x001f, name => "PidTagSenderEmailAddress" }, # Contains the e-mail address of the sending mailbox owner.
0x0e01 => { type => 0x000b, name => "PidTagDeleteAfterSubmit" }, # Indicates that the original message is to be deleted after it is sent.
0x0e02 => { type => 0x001f, name => "PidTagDisplayBcc" }, # Contains a list of blind carbon copy (Bcc) recipientdisplay names.
0x0e03 => { type => 0x001f, name => "PidTagDisplayCc" }, # Contains a list of carbon copy (Cc) recipientdisplay names.
0x0e04 => { type => 0x001f, name => "PidTagDisplayTo" }, # Contains a list of the primary recipientdisplay names, separated by semicolons, when an e-mail message has primary recipients (1).
0x0e06 => { type => 0x0040, name => "PidTagMessageDeliveryTime" }, # Contains the posting date of the item or entry.
0x0e07 => { type => 0x0003, name => "PidTagMessageFlags" }, # Specifies the status of the Message object.
0x0e08 => { type => 0x0003, name => "PidTagMessageSize" }, # Contains the size, in bytes, consumed by the Message object on the server.
0x0e08 => { type => 0x0014, name => "PidTagMessageSizeExtended" }, # 
0x0e09 => { type => 0x0102, name => "PidTagParentEntryId" }, # Contains the EntryID of the folder where messages reside.
0x0e0f => { type => 0x000b, name => "PidTagResponsibility" }, # Specifies whether another mail agent has ensured that the message will be delivered.
0x0e12 => { type => 0x000d, name => "PidTagMessageRecipients" }, # Identifies all of the recipients (1) of the current message.
0x0e13 => { type => 0x000d, name => "PidTagMessageAttachments" }, # Identifies all attachments to the current message.
0x0e17 => { type => 0x0003, name => "PidTagMessageStatus" }, # Specifies the status of a message in a contents table.
0x0e1b => { type => 0x000b, name => "PidTagHasAttachments" }, # Indicates whether the Message object contains at least one attachment.
0x0e1d => { type => 0x001f, name => "PidTagNormalizedSubject" }, # Contains the normalized subject of the message.
0x0e1f => { type => 0x000b, name => "PidTagRtfInSync" }, # 
0x0e20 => { type => 0x0003, name => "PidTagAttachSize" }, # Contains the size, in bytes, consumed by the Attachment object on the server.
0x0e21 => { type => 0x0003, name => "PidTagAttachNumber" }, # Identifies the Attachment object within its Message object.
0x0e23 => { type => 0x0003, name => "PidTagInternetArticleNumber" }, # 
0x0e28 => { type => 0x001f, name => "PidTagPrimarySendAccount" }, # Specifies the first server that a client is to use to send the e-mail with.
0x0e29 => { type => 0x001f, name => "PidTagNextSendAcct" }, # Specifies the server that a client is currently attempting to use to send e-mail.
0x0e2b => { type => 0x0003, name => "PidTagToDoItemFlags" }, # Contains flags associated with objects.
0x0e2c => { type => 0x0102, name => "PidTagSwappedToDoStore" }, # 
0x0e2d => { type => 0x0102, name => "PidTagSwappedToDoData" }, # Contains a secondary storage location for flags when sender flags or sender reminders are supported.
0x0e69 => { type => 0x000b, name => "PidTagRead" }, # Indicates whether a message has been read.
0x0e6a => { type => 0x001f, name => "PidTagSecurityDescriptorAsXml" }, # Contains security attributes in XML.
0x0e79 => { type => 0x0003, name => "PidTagTrustSender" }, # 
0x0e84 => { type => 0x0102, name => "PidTagExchangeNTSecurityDescriptor" }, # Contains the calculated security descriptor for the item.
0x0e99 => { type => 0x0102, name => "PidTagExtendedRuleMessageActions" }, # Contains action information about named properties used in the rule.
0x0e9a => { type => 0x0102, name => "PidTagExtendedRuleMessageCondition" }, # Contains condition information about named properties used in the rule.
0x0e9b => { type => 0x0003, name => "PidTagExtendedRuleSizeLimit" }, # Contains the maximum size, in bytes, that the user is allowed to accumulate for a single extended rule.
0x0ff4 => { type => 0x0003, name => "PidTagAccess" }, # Indicates the operations available to the client for the object.
0x0ff5 => { type => 0x0003, name => "PidTagRowType" }, # Identifies the type of the row.
0x0ff6 => { type => 0x0102, name => "PidTagInstanceKey" }, # Contains an object on an NSPI server.
0x0ff7 => { type => 0x0003, name => "PidTagAccessLevel" }, # Indicates the client's access level to the object.
0x0ff8 => { type => 0x0102, name => "PidTagMappingSignature" }, # A 16-byte constant that is present on all Address Book objects, but is not present on objects in an offline address book.
0x0ff9 => { type => 0x0102, name => "PidTagRecordKey" }, # Contains a unique binary-comparable identifier for a specific object.
0x0ffb => { type => 0x0102, name => "PidTagStoreEntryId" }, # Contains the unique EntryID of the message store where an object resides.
0x0ffe => { type => 0x0003, name => "PidTagObjectType" }, # Indicates the type of Server object.
0x0fff => { type => 0x0102, name => "PidTagEntryId" }, # Contains the information to identify many different types of messaging objects.
0x1000 => { type => 0x001f, name => "PidTagBody" }, # Contains message body (2) text in plain text format.
0x1001 => { type => 0x001f, name => "PidTagReportText" }, # Contains the optional text for a report message.
0x1009 => { type => 0x0102, name => "PidTagRtfCompressed" }, # Contains message body (2) text in compressed RTF format.
0x1013 => { type => 0x001f, name => "PidTagBodyHtml" }, # 
0x1013 => { type => 0x0102, name => "PidTagHtml" }, # Contains message body (2) text in HTML format.
0x1014 => { type => 0x001f, name => "PidTagBodyContentLocation" }, # Contains a globally unique Uniform Resource Identifier (URI) that serves as a label for the current message body (2).
0x1015 => { type => 0x001f, name => "PidTagBodyContentId" }, # Contains a GUID that corresponds to the current message body (2).
0x1016 => { type => 0x0003, name => "PidTagNativeBody" }, # Indicates the best available format for storing the message body (2).
0x1035 => { type => 0x001f, name => "PidTagInternetMessageId" }, # 
0x1039 => { type => 0x001f, name => "PidTagInternetReferences" }, # Contains a list of message IDs that specify the messages to which this reply is related.
0x1042 => { type => 0x001f, name => "PidTagInReplyToId" }, # 
0x1043 => { type => 0x001f, name => "PidTagListHelp" }, # Contains a URI that provides detailed help information for the mailing list from which an e-mail message was sent.
0x1044 => { type => 0x001f, name => "PidTagListSubscribe" }, # Contains the URI that subscribes a recipient (2) to a  message’s associated mailing list.
0x1045 => { type => 0x001f, name => "PidTagListUnsubscribe" }, # Contains the URI that unsubscribes a recipient (2) from a message’s associated mailing list.
0x1046 => { type => 0x001f, name => "PidTagOriginalMessageId" }, # 
0x1080 => { type => 0x0003, name => "PidTagIconIndex" }, # Specifies which icon is to be used by a user interface when displaying a group of Message objects.
0x1081 => { type => 0x0003, name => "PidTagLastVerbExecuted" }, # Specifies the last verb executed for the message item to which it is related.
0x1082 => { type => 0x0040, name => "PidTagLastVerbExecutionTime" }, # 
0x1090 => { type => 0x0003, name => "PidTagFlagStatus" }, # Specifies the flag state of the Message object.
0x1091 => { type => 0x0040, name => "PidTagFlagCompleteTime" }, # Specifies the date and time, in UTC, that the Message object was flagged as complete.
0x1095 => { type => 0x0003, name => "PidTagFollowupIcon" }, # Specifies the flag color of the Message object.
0x1096 => { type => 0x0003, name => "PidTagBlockStatus" }, # Indicates the user's preference for viewing external content (such as links to images on an HTTP server) in the message body (2).
0x10c3 => { type => 0x0040, name => "PidTagICalendarStartTime" }, # Contains the date and time, in UTC, when the appointment or meeting starts.
0x10c4 => { type => 0x0040, name => "PidTagICalendarEndTime" }, # Contains the date and time, in UTC, when an appointment or meeting ends.
0x10c5 => { type => 0x0040, name => "PidTagCdoRecurrenceid" }, # 
0x10ca => { type => 0x0040, name => "PidTagICalendarReminderNextTime" }, # Contains the date and time, in UTC, for the activation of the next reminder.
0x10f3 => { type => 0x001f, name => "PidTagUrlCompName" }, # Contains the composite URL name.
0x10f4 => { type => 0x000b, name => "PidTagAttributeHidden" }, # Specifies the hide or show status of a folder.
0x10f6 => { type => 0x000b, name => "PidTagAttributeReadOnly" }, # 
0x3000 => { type => 0x0003, name => "PidTagRowid" }, # Contains a unique identifier for a recipient (2) in a message's recipient table.
0x3001 => { type => 0x001f, name => "PidTagDisplayName" }, # Contains the display name of the folder.
0x3002 => { type => 0x001f, name => "PidTagAddressType" }, # Contains the e-mail address type of a Message object.
0x3003 => { type => 0x001f, name => "PidTagEmailAddress" }, # Contains the e-mail address of a Message object.
0x3004 => { type => 0x001f, name => "PidTagComment" }, # Contains a comment about the purpose or content of the Address Book object.
0x3005 => { type => 0x0003, name => "PidTagDepth" }, # Specifies the number of nested categories in which a given row is contained.
0x3007 => { type => 0x0040, name => "PidTagCreationTime" }, # Contains the time, in UTC, that the object was created.
0x3008 => { type => 0x0040, name => "PidTagLastModificationTime" }, # Contains the time, in UTC, of the last modification to the object.
0x300b => { type => 0x0102, name => "PidTagSearchKey" }, # Contains a unique binary-comparable key that identifies an object for a search.
0x3010 => { type => 0x0102, name => "PidTagTargetEntryId" }, # Contains the message ID of a Message object being submitted for optimization ([MS-OXOMSG] section 3.2.4.4).
0x3013 => { type => 0x0102, name => "PidTagConversationId" }, # Contains a computed value derived from other conversation-related properties.
0x3016 => { type => 0x000b, name => "PidTagConversationIndexTracking" }, # 
0x3018 => { type => 0x0102, name => "PidTagArchiveTag" }, # 
0x3019 => { type => 0x0102, name => "PidTagPolicyTag" }, # Specifies the GUID of a retention tag.
0x301a => { type => 0x0003, name => "PidTagRetentionPeriod" }, # Specifies the number of days that a Message object can remain unarchived.
0x301b => { type => 0x0102, name => "PidTagStartDateEtc" }, # Contains the default retention period, and the start date from which the age of a Message object is calculated.
0x301c => { type => 0x0040, name => "PidTagRetentionDate" }, # Specifies the date, in UTC, after which a Message object is expired by the server.
0x301d => { type => 0x0003, name => "PidTagRetentionFlags" }, # Contains flags that specify the status or nature of an item's retention tag or archive tag.
0x301e => { type => 0x0003, name => "PidTagArchivePeriod" }, # 
0x301f => { type => 0x0040, name => "PidTagArchiveDate" }, # 
0x340d => { type => 0x0003, name => "PidTagStoreSupportMask" }, # Indicates whether string properties within the .msg file are Unicode-encoded.
0x340e => { type => 0x0003, name => "PidTagStoreState" }, # Indicates whether a mailbox has any active Search folders.
0x3600 => { type => 0x0003, name => "PidTagContainerFlags" }, # Contains a bitmask of flags that describe capabilities of an address book container.
0x3601 => { type => 0x0003, name => "PidTagFolderType" }, # Specifies the type of a folder that includes the Root folder, Generic folder, and Search folder.
0x3602 => { type => 0x0003, name => "PidTagContentCount" }, # Specifies the number of rows under the header row.
0x3603 => { type => 0x0003, name => "PidTagContentUnreadCount" }, # 
0x3609 => { type => 0x000b, name => "PidTagSelectable" }, # This property is not set and, if set, is ignored.
0x360a => { type => 0x000b, name => "PidTagSubfolders" }, # Specifies whether a folder has subfolders.
0x360c => { type => 0x001f, name => "PidTagAnr" }, # Contains a filter value used in ambiguous name resolution.
0x360e => { type => 0x000d, name => "PidTagContainerHierarchy" }, # Identifies all of the subfolders of the current folder.
0x360f => { type => 0x000d, name => "PidTagContainerContents" }, # Always empty. An NSPI server defines this value for distribution lists and it is not present for other objects.
0x3610 => { type => 0x000d, name => "PidTagFolderAssociatedContents" }, # Identifies all FAI messages in the current folder.
0x3613 => { type => 0x001f, name => "PidTagContainerClass" }, # Contains a string value that describes the type of Message object that a folder contains.
0x36d0 => { type => 0x0102, name => "PidTagIpmAppointmentEntryId" }, # Contains the EntryID of the Calendar folder.
0x36d1 => { type => 0x0102, name => "PidTagIpmContactEntryId" }, # Contains the EntryID of the Contacts folder.
0x36d2 => { type => 0x0102, name => "PidTagIpmJournalEntryId" }, # Contains the EntryID of the Journal folder.
0x36d3 => { type => 0x0102, name => "PidTagIpmNoteEntryId" }, # Contains the EntryID of the Notes folder.
0x36d4 => { type => 0x0102, name => "PidTagIpmTaskEntryId" }, # Contains the EntryID of the Tasks folder.
0x36d5 => { type => 0x0102, name => "PidTagRemindersOnlineEntryId" }, # Contains an EntryID for the Reminders folder.
0x36d7 => { type => 0x0102, name => "PidTagIpmDraftsEntryId" }, # Contains the EntryID of the Drafts folder.
0x36d8 => { type => 0x1102, name => "PidTagAdditionalRenEntryIds" }, # Contains the indexed entry IDs for several special folders related to conflicts, sync issues, local failures, server failures, junk e-mail and spam.
0x36d9 => { type => 0x0102, name => "PidTagAdditionalRenEntryIdsEx" }, # Contains an array of blocks that contain the EntryIDs for folders related to RSS feed folders, and the Tracked Mail Processing folder, To-Do Search folder, and Conversation Action Settings folder.
0x36da => { type => 0x0102, name => "PidTagExtendedFolderFlags" }, # Contains encoded sub-properties for a folder.
0x36e2 => { type => 0x0003, name => "PidTagOrdinalMost" }, # 
0x36e4 => { type => 0x1102, name => "PidTagFreeBusyEntryIds" }, # 
0x36e5 => { type => 0x001f, name => "PidTagDefaultPostMessageClass" }, # Contains the message class of the object.
0x3701 => { type => 0x000d, name => "PidTagAttachDataObject" }, # Contains the binary representation of the Attachment object in an application-specific format.
0x3701 => { type => 0x0102, name => "PidTagAttachDataBinary" }, # Contains the contents of the file to be attached.
0x3702 => { type => 0x0102, name => "PidTagAttachEncoding" }, # Contains encoding information about the Attachment object.
0x3703 => { type => 0x001f, name => "PidTagAttachExtension" }, # Contains a file name extension that indicates the document type of an attachment.
0x3704 => { type => 0x001f, name => "PidTagAttachFilename" }, # 
0x3705 => { type => 0x0003, name => "PidTagAttachMethod" }, # Represents the way the contents of an attachment are accessed.
0x3707 => { type => 0x001f, name => "PidTagAttachLongFilename" }, # Contains the full filename and extension of the Attachment object.
0x3708 => { type => 0x001f, name => "PidTagAttachPathname" }, # 
0x3709 => { type => 0x0102, name => "PidTagAttachRendering" }, # Contains a Windows Metafile, as specified in [MS-WMF], for the Attachment object.
0x370a => { type => 0x0102, name => "PidTagAttachTag" }, # Contains the identifier information for the application that supplied the Attachment object data.
0x370b => { type => 0x0003, name => "PidTagRenderingPosition" }, # Represents an offset, in rendered characters, to use when rendering an attachment  within the main message text.
0x370c => { type => 0x001f, name => "PidTagAttachTransportName" }, # Contains the name of an attachment file, modified so that it can be correlated with TNEF messages.
0x370d => { type => 0x001f, name => "PidTagAttachLongPathname" }, # Contains the fully-qualified path and file name with extension.
0x370e => { type => 0x001f, name => "PidTagAttachMimeTag" }, # Contains a content-type MIME header.
0x370f => { type => 0x0102, name => "PidTagAttachAdditionalInformation" }, # Contains attachment encoding information.
0x3711 => { type => 0x001f, name => "PidTagAttachContentBase" }, # Contains the base of a relative URI.
0x3712 => { type => 0x001f, name => "PidTagAttachContentId" }, # Contains a content identifier unique to the Message object that matches a corresponding "cid:" URI schema reference in the HTML body of the Message object.
0x3713 => { type => 0x001f, name => "PidTagAttachContentLocation" }, # Contains a relative or full URI that matches a corresponding reference in the HTML body of a Message object.
0x3714 => { type => 0x0003, name => "PidTagAttachFlags" }, # Indicates which body formats might reference this attachment when rendering data.
0x3719 => { type => 0x001f, name => "PidTagAttachPayloadProviderGuidString" }, # Contains the GUID of the software component that can display the contents of the message.
0x371a => { type => 0x001f, name => "PidTagAttachPayloadClass" }, # Contains the class name of an object that can display the contents of the message.
0x371b => { type => 0x001f, name => "PidTagTextAttachmentCharset" }, # Specifies the character set of an attachment received via MIME with the content-type of text.
0x3900 => { type => 0x0003, name => "PidTagDisplayType" }, # Contains an integer value that indicates how to display an Address Book object in a table or as an addressee on a message.
0x3902 => { type => 0x0102, name => "PidTagTemplateid" }, # 
0x3905 => { type => 0x0003, name => "PidTagDisplayTypeEx" }, # Contains an integer value that indicates how to display an Address Book object in a table or as a recipient (1) on a message.
0x39fe => { type => 0x001f, name => "PidTagSmtpAddress" }, # Contains the SMTP address of the Message object.
0x39ff => { type => 0x001f, name => "PidTagAddressBookDisplayNamePrintable" }, # Contains the printable string version of the display name.
0x3a00 => { type => 0x001f, name => "PidTagAccount" }, # Contains the alias of an Address Book object, which is an alternative name by which the object can be identified.
0x3a02 => { type => 0x001f, name => "PidTagCallbackTelephoneNumber" }, # Contains a telephone number to reach the mail user.
0x3a05 => { type => 0x001f, name => "PidTagGeneration" }, # Contains a generational abbreviation that follows the full name of the mail user.
0x3a06 => { type => 0x001f, name => "PidTagGivenName" }, # Contains the mail user's given name.
0x3a07 => { type => 0x001f, name => "PidTagGovernmentIdNumber" }, # Contains a government identifier for the mail user.
0x3a08 => { type => 0x001f, name => "PidTagBusinessTelephoneNumber" }, # Contains the primary telephone number of the mail user's place of business.
0x3a09 => { type => 0x001f, name => "PidTagHomeTelephoneNumber" }, # Contains the primary telephone number of the mail user's home.
0x3a0a => { type => 0x001f, name => "PidTagInitials" }, # Contains the initials for parts of the full name of the mail user.
0x3a0b => { type => 0x001f, name => "PidTagKeyword" }, # Contains a keyword that identifies the mail user to the mail user's system administrator.
0x3a0c => { type => 0x001f, name => "PidTagLanguage" }, # Contains a value that indicates the language in which the messaging user is writing messages.
0x3a0d => { type => 0x001f, name => "PidTagLocation" }, # Contains the location of the mail user.
0x3a0f => { type => 0x001f, name => "PidTagMessageHandlingSystemCommonName" }, # Contains the common name of a messaging user for use in a message header.
0x3a10 => { type => 0x001f, name => "PidTagOrganizationalIdNumber" }, # Contains an identifier for the mail user used within the mail user's organization.
0x3a11 => { type => 0x001f, name => "PidTagSurname" }, # Contains the mail user's family name.
0x3a12 => { type => 0x0102, name => "PidTagOriginalEntryId" }, # Contains the original EntryID of an object.
0x3a15 => { type => 0x001f, name => "PidTagPostalAddress" }, # Contains the mail user's postal address.
0x3a16 => { type => 0x0000, name => "PidTagCompanyName" }, # Contains the mail user's company name.
0x3a17 => { type => 0x001f, name => "PidTagTitle" }, # Contains the mail user's job title.
0x3a18 => { type => 0x001f, name => "PidTagDepartmentName" }, # Contains a name for the department in which the mail user works.
0x3a19 => { type => 0x001f, name => "PidTagOfficeLocation" }, # Contains the mail user's office location.
0x3a1a => { type => 0x001f, name => "PidTagPrimaryTelephoneNumber" }, # Contains the mail user's primary telephone number.
0x3a1b => { type => 0x001f, name => "PidTagBusiness2TelephoneNumber" }, # Contains a secondary telephone number at the mail user's place of business.
0x3a1b => { type => 0x101f, name => "PidTagBusiness2TelephoneNumbers" }, # Contains secondary telephone numbers at the mail user's place of business.
0x3a1c => { type => 0x001f, name => "PidTagMobileTelephoneNumber" }, # Contains the mail user's cellular telephone number.
0x3a1d => { type => 0x001f, name => "PidTagRadioTelephoneNumber" }, # Contains the mail user's radio telephone number.
0x3a1e => { type => 0x001f, name => "PidTagCarTelephoneNumber" }, # Contains the mail user's car telephone number.
0x3a1f => { type => 0x001f, name => "PidTagOtherTelephoneNumber" }, # Contains an alternate telephone number for the mail user.
0x3a20 => { type => 0x001f, name => "PidTagTransmittableDisplayName" }, # Contains an Address Book object'sdisplay name that is transmitted with the message.
0x3a21 => { type => 0x001f, name => "PidTagPagerTelephoneNumber" }, # Contains the mail user's pager telephone number.
0x3a22 => { type => 0x0102, name => "PidTagUserCertificate" }, # Contains an ASN.1 authentication certificate for a messaging user.
0x3a23 => { type => 0x001f, name => "PidTagPrimaryFaxNumber" }, # Contains the telephone number of the mail user's primary fax machine.
0x3a24 => { type => 0x001f, name => "PidTagBusinessFaxNumber" }, # Contains the telephone number of the mail user's business fax machine.
0x3a25 => { type => 0x001f, name => "PidTagHomeFaxNumber" }, # Contains the telephone number of the mail user's home fax machine.
0x3a26 => { type => 0x001f, name => "PidTagCountry" }, # Contains the name of the mail user's country/region.
0x3a27 => { type => 0x001f, name => "PidTagLocality" }, # Contains the name of the mail user's locality, such as the town or city.
0x3a28 => { type => 0x001f, name => "PidTagStateOrProvince" }, # Contains the name of the mail user's state or province.
0x3a29 => { type => 0x001f, name => "PidTagStreetAddress" }, # Contains the mail user's street address.
0x3a2a => { type => 0x001f, name => "PidTagPostalCode" }, # Contains the postal code for the mail user's postal address.
0x3a2b => { type => 0x001f, name => "PidTagPostOfficeBox" }, # Contains the number or identifier of the mail user's post office box.
0x3a2c => { type => 0x001f, name => "PidTagTelexNumber" }, # Contains the mail user's telex number.
0x3a2d => { type => 0x001f, name => "PidTagIsdnNumber" }, # Contains the Integrated Services Digital Network (ISDN) telephone number of the mail user.
0x3a2e => { type => 0x001f, name => "PidTagAssistantTelephoneNumber" }, # Contains the telephone number of the mail user's administrative assistant.
0x3a2f => { type => 0x001f, name => "PidTagHome2TelephoneNumber" }, # Contains a secondary telephone number at the mail user's home.
0x3a2f => { type => 0x101f, name => "PidTagHome2TelephoneNumbers" }, # Contains secondary telephone numbers at the mail user's home.
0x3a30 => { type => 0x001f, name => "PidTagAssistant" }, # Contains the name of the mail user's administrative assistant.
0x3a40 => { type => 0x000b, name => "PidTagSendRichInfo" }, # Indicates whether the e-mail-enabled entity represented by the Address Book object can receive all message content, including Rich Text Format (RTF) and other embedded objects.
0x3a41 => { type => 0x0040, name => "PidTagWeddingAnniversary" }, # Contains the date of the mail user's wedding anniversary.
0x3a42 => { type => 0x0040, name => "PidTagBirthday" }, # Contains the date of the mail user's birthday at midnight.
0x3a43 => { type => 0x001f, name => "PidTagHobbies" }, # Contains the names of the mail user's hobbies.
0x3a44 => { type => 0x001f, name => "PidTagMiddleName" }, # Specifies the middle name(s) of the contact.
0x3a45 => { type => 0x001f, name => "PidTagDisplayNamePrefix" }, # Contains the mail user's honorific title.
0x3a46 => { type => 0x001f, name => "PidTagProfession" }, # Contains the name of the mail user's line of business.
0x3a47 => { type => 0x001f, name => "PidTagReferredByName" }, # Contains the name of the mail user's referral.
0x3a48 => { type => 0x001f, name => "PidTagSpouseName" }, # Contains the name of the mail user's spouse/partner.
0x3a49 => { type => 0x001f, name => "PidTagComputerNetworkName" }, # Contains the name of the mail user's computer network.
0x3a4a => { type => 0x001f, name => "PidTagCustomerId" }, # Contains the mail user's customer identification number.
0x3a4b => { type => 0x001f, name => "PidTagTelecommunicationsDeviceForDeafTelephoneNumber" }, # Contains the mail user's telecommunication device for the deaf (TTY/TDD) telephone number.
0x3a4c => { type => 0x001f, name => "PidTagFtpSite" }, # Contains the File Transfer Protocol (FTP) site address of the mail user.
0x3a4d => { type => 0x0002, name => "PidTagGender" }, # Contains a value that represents the mail user's gender.
0x3a4e => { type => 0x001f, name => "PidTagManagerName" }, # Contains the name of the mail user's manager.
0x3a4f => { type => 0x001f, name => "PidTagNickname" }, # Contains the mail user's nickname.
0x3a50 => { type => 0x001f, name => "PidTagPersonalHomePage" }, # Contains the URL of the mail user's personal home page.
0x3a51 => { type => 0x001f, name => "PidTagBusinessHomePage" }, # Contains the URL of the mail user's business home page.
0x3a57 => { type => 0x001f, name => "PidTagCompanyMainTelephoneNumber" }, # Contains the main telephone number of the mail user's company.
0x3a58 => { type => 0x101f, name => "PidTagChildrensNames" }, # 
0x3a59 => { type => 0x001f, name => "PidTagHomeAddressCity" }, # Contains the name of the mail user's home locality, such as the town or city.
0x3a5a => { type => 0x001f, name => "PidTagHomeAddressCountry" }, # Contains the name of the mail user's home country/region.
0x3a5b => { type => 0x001f, name => "PidTagHomeAddressPostalCode" }, # Contains the postal code for the mail user's home postal address.
0x3a5c => { type => 0x001f, name => "PidTagHomeAddressStateOrProvince" }, # Contains the name of the mail user's home state or province.
0x3a5d => { type => 0x001f, name => "PidTagHomeAddressStreet" }, # Contains the mail user's home street address.
0x3a5e => { type => 0x001f, name => "PidTagHomeAddressPostOfficeBox" }, # Contains the number or identifier of the mail user's home post office box.
0x3a5f => { type => 0x001f, name => "PidTagOtherAddressCity" }, # Contains the name of the mail user's other locality, such as the town or city.
0x3a60 => { type => 0x001f, name => "PidTagOtherAddressCountry" }, # Contains the name of the mail user's other country/region.
0x3a61 => { type => 0x001f, name => "PidTagOtherAddressPostalCode" }, # Contains the postal code for the mail user's other postal address.
0x3a62 => { type => 0x001f, name => "PidTagOtherAddressStateOrProvince" }, # Contains the name of the mail user's other state or province.
0x3a63 => { type => 0x001f, name => "PidTagOtherAddressStreet" }, # Contains the mail user's other street address.
0x3a64 => { type => 0x001f, name => "PidTagOtherAddressPostOfficeBox" }, # Contains the number or identifier of the mail user's other post office box.
0x3a70 => { type => 0x1102, name => "PidTagUserX509Certificate" }, # Contains a list of certificates for the mail user.
0x3a71 => { type => 0x0003, name => "PidTagSendInternetEncoding" }, # Contains a bitmask of message encoding preferences for e-mail sent to an e-mail-enabled entity that is represented by this Address Book object.
0x3f08 => { type => 0x0003, name => "PidTagInitialDetailsPane" }, # Indicates which page of a display template to display first.
0x3f20 => { type => 0x001f, name => "PidTagTemporaryDefaultDocument" }, # Indicates the relative URI of the default document contained in the structured document.
0x3fde => { type => 0x0003, name => "PidTagInternetCodepage" }, # 
0x3fdf => { type => 0x0003, name => "PidTagAutoResponseSuppress" }, # 
0x3fe0 => { type => 0x0102, name => "PidTagAccessControlListData" }, # Contains a permissions list for a folder.
0x3fe3 => { type => 0x000b, name => "PidTagDelegatedByRule" }, # 
0x3fe7 => { type => 0x0003, name => "PidTagResolveMethod" }, # Specifies how to resolve any conflicts with the message.
0x3fea => { type => 0x000b, name => "PidTagHasDeferredActionMessages" }, # Indicates whether a Message object has a deferred action message associated with it.
0x3feb => { type => 0x0003, name => "PidTagDeferredSendNumber" }, # Contains a number used in the calculation of how long to defer sending a message.
0x3fec => { type => 0x0003, name => "PidTagDeferredSendUnits" }, # 
0x3fed => { type => 0x0003, name => "PidTagExpiryNumber" }, # 
0x3fee => { type => 0x0003, name => "PidTagExpiryUnits" }, # 
0x3fef => { type => 0x0040, name => "PidTagDeferredSendTime" }, # Contains the amount of time after which a client would like to defer sending the message.
0x3ff0 => { type => 0x0102, name => "PidTagConflictEntryId" }, # Contains the EntryID of the conflict resolve message.
0x3ff1 => { type => 0x0003, name => "PidTagMessageLocaleId" }, # Contains the Windows Locale ID of the end-user who created this message.
0x3ff8 => { type => 0x001f, name => "PidTagCreatorName" }, # Contains the name of a Message object.
0x3ff9 => { type => 0x0102, name => "PidTagCreatorEntryId" }, # Specifies the original author of the message according to their Address Book EntryID.
0x3ffa => { type => 0x001f, name => "PidTagLastModifierName" }, # Contains the name of the last mail user to change the Message object.
0x3ffb => { type => 0x0102, name => "PidTagLastModifierEntryId" }, # Specifies the Address Book EntryID of the last user to modify the contents of the message.
0x3ffd => { type => 0x0003, name => "PidTagMessageCodepage" }, # Specifies the code page used to encode the non-Unicode string properties on this Message object.
0x401a => { type => 0x0003, name => "PidTagSentRepresentingFlags" }, # 
0x4029 => { type => 0x001f, name => "PidTagReadReceiptAddressType" }, # Contains the address type of the end user to whom a read receipt is directed.
0x402a => { type => 0x001f, name => "PidTagReadReceiptEmailAddress" }, # Contains the e-mail address of the end user to whom a read receipt is directed.
0x402b => { type => 0x001f, name => "PidTagReadReceiptName" }, # Contains the display name for the end user to whom a read receipt is directed.
0x4076 => { type => 0x0003, name => "PidTagContentFilterSpamConfidenceLevel" }, # Indicates a confidence level that the message is spam.
0x4079 => { type => 0x0003, name => "PidTagSenderIdStatus" }, # Reports the results of a Sender-ID check.
0x4083 => { type => 0x001f, name => "PidTagPurportedSenderDomain" }, # Contains the domain responsible for transmitting the current message.
0x5902 => { type => 0x0003, name => "PidTagInternetMailOverrideFormat" }, # Indicates the encoding method and HTML inclusion for attachments.
0x5909 => { type => 0x0003, name => "PidTagMessageEditorFormat" }, # Specifies the format that an e-mail editor can use for editing the message body (2).
0x5d01 => { type => 0x001f, name => "PidTagSenderSmtpAddress" }, # Contains the SMTP e-mail address format of the e–mail address of the sending mailbox owner.
0x5fde => { type => 0x0003, name => "PidTagRecipientResourceState" }, # 
0x5fdf => { type => 0x0003, name => "PidTagRecipientOrder" }, # Specifies the location of the current recipient (1) in the recipient table.
0x5fe1 => { type => 0x000b, name => "PidTagRecipientProposed" }, # Indicates that the attendee proposed a new date and/or time.
0x5fe3 => { type => 0x0040, name => "PidTagRecipientProposedStartTime" }, # Indicates the meeting start time requested by the attendee in a counter proposal.
0x5fe4 => { type => 0x0040, name => "PidTagRecipientProposedEndTime" }, # Indicates the meeting end time requested by the attendee in a counter proposal.
0x5ff6 => { type => 0x001f, name => "PidTagRecipientDisplayName" }, # 
0x5ff7 => { type => 0x0102, name => "PidTagRecipientEntryId" }, # 
0x5ffb => { type => 0x0040, name => "PidTagRecipientTrackStatusTime" }, # Indicates the date and time at which the attendee responded.
0x5ffd => { type => 0x0003, name => "PidTagRecipientFlags" }, # Specifies a bit field that describes the recipient (1) status.
0x5fff => { type => 0x0003, name => "PidTagRecipientTrackStatus" }, # Indicates the response status that is returned by the attendee.
0x6100 => { type => 0x0003, name => "PidTagJunkIncludeContacts" }, # Indicates whether e-mail addresses of the contacts in the Contacts folder are treated in a special way with respect to the spam filter.
0x6101 => { type => 0x0003, name => "PidTagJunkThreshold" }, # Indicates how aggressively incoming e-mail is to be sent to the Junk E-mail folder.
0x6102 => { type => 0x0003, name => "PidTagJunkPermanentlyDelete" }, # Indicates whether messages identified as spam can be permanently deleted.
0x6103 => { type => 0x0003, name => "PidTagJunkAddRecipientsToSafeSendersList" }, # Indicates whether e-mail recipients (1) are to be added to the safe senders list.
0x6107 => { type => 0x000b, name => "PidTagJunkPhishingEnableLinks" }, # Indicated whether the phishing stamp on a message is to be ignored.
0x64f0 => { type => 0x0102, name => "PidTagMimeSkeleton" }, # Contains the top-level MIME message headers, all MIME message body part headers, and body part content that is not already converted to Message object properties, including attachments.
0x65c2 => { type => 0x0102, name => "PidTagReplyTemplateId" }, # Contains the value of the GUID that points to a Reply template.
0x65e0 => { type => 0x0102, name => "PidTagSourceKey" }, # Contains a value that contains an internal global identifier (GID) for this folder or message.
0x65e1 => { type => 0x0102, name => "PidTagParentSourceKey" }, # 
0x65e2 => { type => 0x0102, name => "PidTagChangeKey" }, # Contains a structure that identifies the last change to the object.
0x65e3 => { type => 0x0102, name => "PidTagPredecessorChangeList" }, # 
0x65e9 => { type => 0x0003, name => "PidTagRuleMessageState" }, # Contains flags that specify the state of the rule. Set on the FAI message.
0x65ea => { type => 0x0003, name => "PidTagRuleMessageUserFlags" }, # Contains an opaque property that the client sets for the exclusive use of the client. Set on the FIA message.
0x65eb => { type => 0x001f, name => "PidTagRuleMessageProvider" }, # Identifies the client application that owns the rule. Set on the FAI message.
0x65ec => { type => 0x001f, name => "PidTagRuleMessageName" }, # Specifies the name of the rule. Set on the FAI message.
0x65ed => { type => 0x0003, name => "PidTagRuleMessageLevel" }, # Contains 0x00000000. Set on the FAI message.
0x65ee => { type => 0x0102, name => "PidTagRuleMessageProviderData" }, # Contains opaque data set by the client for the exclusive use of the client. Set on the FAI message.
0x65f3 => { type => 0x0003, name => "PidTagRuleMessageSequence" }, # Contains a value used to determine the order in which rules are evaluated and executed. Set on the FAI message.
0x6619 => { type => 0x0102, name => "PidTagUserEntryId" }, # Address book EntryID of the user logged on to the public folders.
0x661b => { type => 0x0102, name => "PidTagMailboxOwnerEntryId" }, # Contains the EntryID in the Global Address List (GAL) of the owner of the mailbox.
0x661c => { type => 0x001f, name => "PidTagMailboxOwnerName" }, # Contains the display name of the owner of the mailbox.
0x661d => { type => 0x000b, name => "PidTagOutOfOfficeState" }, # Indicates whether the user is OOF.
0x6622 => { type => 0x0102, name => "PidTagSchedulePlusFreeBusyEntryId" }, # Contains the EntryID of the folder named "SCHEDULE+ FREE BUSY" under the non-IPM subtree of the public folderstore.
0x6639 => { type => 0x0003, name => "PidTagRights" }, # Specifies a user's folder permissions.
0x663a => { type => 0x000b, name => "PidTagHasRules" }, # Indicates whether a Folder object has rules.
0x663b => { type => 0x0102, name => "PidTagAddressBookEntryId" }, # Contains the name-service EntryID of a directory object that refers to a public folder.
0x663e => { type => 0x0003, name => "PidTagHierarchyChangeNumber" }, # Contains a number that monotonically increases every time a subfolder is added to, or deleted from, this folder.
0x6645 => { type => 0x0102, name => "PidTagClientActions" }, # 
0x6646 => { type => 0x0102, name => "PidTagDamOriginalEntryId" }, # Contains the EntryID of the delivered message that the client has to process.
0x6647 => { type => 0x000b, name => "PidTagDamBackPatched" }, # Indicates whether the Deferred Action Message (DAM) was updated by the server.
0x6648 => { type => 0x0003, name => "PidTagRuleError" }, # Contains the error code that indicates the cause of an error encountered during the execution of the rule.
0x6649 => { type => 0x0003, name => "PidTagRuleActionType" }, # 
0x664a => { type => 0x000b, name => "PidTagHasNamedProperties" }, # Indicates whether the Message object has a named property.
0x6650 => { type => 0x0003, name => "PidTagRuleActionNumber" }, # Contains the index of a rule action that failed.
0x6651 => { type => 0x0102, name => "PidTagRuleFolderEntryId" }, # Contains the EntryID of the folder where the rule that triggered the generation of a DAM is stored.
0x666a => { type => 0x0003, name => "PidTagProhibitReceiveQuota" }, # Maximum size, in kilobytes, that a user is allowed to accumulate in their mailbox before no further e-mail will be delivered to their mailbox.
0x666c => { type => 0x000b, name => "PidTagInConflict" }, # Specifies whether the attachment represents an alternate replica.
0x666d => { type => 0x0003, name => "PidTagMaximumSubmitMessageSize" }, # Maximum size, in kilobytes, of a message that a user is allowed to submit for transmission to another user.
0x666e => { type => 0x0003, name => "PidTagProhibitSendQuota" }, # Maximum size, in kilobytes, that a user is allowed to accumulate in their mailbox before the user can no longer send any more e-mail.
0x6671 => { type => 0x0014, name => "PidTagMemberId" }, # Contains a unique identifier that the messaging server generates for each user.
0x6672 => { type => 0x001f, name => "PidTagMemberName" }, # Contains the user-readable name of the user.
0x6673 => { type => 0x0003, name => "PidTagMemberRights" }, # Contains the permissions for the specified user.
0x6674 => { type => 0x0014, name => "PidTagRuleId" }, # Specifies a unique identifier that is generated by the messaging server for each rule when the rule is first created.
0x6675 => { type => 0x0102, name => "PidTagRuleIds" }, # 
0x6676 => { type => 0x0003, name => "PidTagRuleSequence" }, # Contains a value used to determine the order in which rules are evaluated and executed.
0x6677 => { type => 0x0003, name => "PidTagRuleState" }, # Contains flags that specify the state of the rule.
0x6678 => { type => 0x0003, name => "PidTagRuleUserFlags" }, # Contains an opaque property that the client sets for the exclusive use of the client.
0x6679 => { type => 0x00fd, name => "PidTagRuleCondition" }, # Defines the conditions under which a rule’s action is to be executed.
0x6680 => { type => 0x00fe, name => "PidTagRuleActions" }, # Contains the set of actions associated with the rule.
0x6681 => { type => 0x001f, name => "PidTagRuleProvider" }, # Contains opaque data set by the client for the exclusive use of the client.
0x6682 => { type => 0x001f, name => "PidTagRuleName" }, # Specifies the name of the rule.
0x6683 => { type => 0x0003, name => "PidTagRuleLevel" }, # Contains 0x00000000. This property is not used.
0x6684 => { type => 0x0102, name => "PidTagRuleProviderData" }, # Contains opaque data set by the client for the exclusive use of the client.
0x668f => { type => 0x0040, name => "PidTagDeletedOn" }, # Specifies the time, in UTC, when the item or folder was soft deleted.
0x66a1 => { type => 0x0003, name => "PidTagLocaleId" }, # Contains the Logon object LocaleID.
0x66b3 => { type => 0x0003, name => "PidTagNormalMessageSize" }, # Contains the aggregate size of Message objects in a folder.
0x66c3 => { type => 0x0003, name => "PidTagCodePageId" }, # Contains the identifier for the client code page used for Unicode to double-byte character set (DBCS) string conversion.
0x6704 => { type => 0x000d, name => "PidTagAddressBookManageDistributionList" }, # Contains information for use in display templates for distribution lists.
0x6705 => { type => 0x0003, name => "PidTagSortLocaleId" }, # Contains the locale identifier.
0x6707 => { type => 0x001f, name => "PidTagUrlName" }, # Contains the URL of an object.
0x6708 => { type => 0x000b, name => "PidTagSubfolder" }, # Indicates whether the resource is a folder as displayed to end users.
0x6709 => { type => 0x0040, name => "PidTagLocalCommitTime" }, # Specifies the time, in UTC, that a Message object or Folder object was last changed.
0x670a => { type => 0x0040, name => "PidTagLocalCommitTimeMax" }, # Contains the time of the most recent message change within the folder container, excluding messages changed within subfolders.
0x670b => { type => 0x0003, name => "PidTagDeletedCountTotal" }, # Contains the total count of messages that have been deleted from a folder, excluding messages deleted within subfolders.
0x670e => { type => 0x001f, name => "PidTagFlatUrlName" }, # Contains a unique identifier for an item across the store.
0x671c => { type => 0x001f, name => "PidTagPublicFolderAdministrativeDescription" }, # Contains a text description of a public folder.
0x671d => { type => 0x0102, name => "PidTagPublicFolderProxy" }, # Contains the base64 encoding of the Object GUID for a mail-enabled public folder.
0x6740 => { type => 0x00fb, name => "PidTagSentMailSvrEID" }, # Contains an EntryID that represents the Sent Items folder for the message.
0x6741 => { type => 0x00fb, name => "PidTagDeferredActionMessageOriginalEntryId" }, # Contains the server EntryID for the DAM.
0x6748 => { type => 0x0014, name => "PidTagFolderId" }, # Contains the Folder ID (FID) ([MS-OXCDATA] section 2.2.1.1) of the folder.
0x6749 => { type => 0x0014, name => "PidTagParentFolderId" }, # Contains a value that contains the Folder ID (FID), as specified in [MS-OXCDATA] section 2.2.1.1, that identifies the parent folder of the messaging object being synchronized.
0x674a => { type => 0x0014, name => "PidTagMid" }, # Contains a value that contains the MID of the message currently being synchronized.
0x674d => { type => 0x0014, name => "PidTagInstID" }, # Contains an identifier for all instances of a row in the table.
0x674e => { type => 0x0003, name => "PidTagInstanceNum" }, # Contains an identifier for a single instance of a row in the table.
0x674f => { type => 0x0014, name => "PidTagAddressBookMessageId" }, # Contains the Short-term Message ID (MID) ([MS-OXCDATA] section 2.2.1.2) of the first message in the local site's offline address bookpublic folder.
0x67a4 => { type => 0x0014, name => "PidTagChangeNumber" }, # Contains a structure that identifies the last change to the message or folder that is currently being synchronized.
0x67aa => { type => 0x000b, name => "PidTagAssociated" }, # Specifies whether the message being synchronized is an FAI message.
0x6800 => { type => 0x001f, name => "PidTagOfflineAddressBookName" }, # Contains the display name of the address list.
0x6801 => { type => 0x0003, name => "PidTagOfflineAddressBookSequence" }, # Contains the sequence number of the OAB.
0x6801 => { type => 0x0003, name => "PidTagVoiceMessageDuration" }, # Specifies the length of the attached audio message, in seconds.
0x6802 => { type => 0x001e, name => "PidTagOfflineAddressBookContainerGuid" }, # A string formatted GUID that represents the address list container object.
0x6802 => { type => 0x001f, name => "PidTagSenderTelephoneNumber" }, # Contains the telephone number of the caller associated with a voice mail message.
0x6802 => { type => 0x0102, name => "PidTagRwRulesStream" }, # Contains additional rule data that is opaque to the server.
0x6803 => { type => 0x0003, name => "PidTagOfflineAddressBookMessageClass" }, # Contains the message class for full OAB messages.
0x6803 => { type => 0x001f, name => "PidTagVoiceMessageSenderName" }, # Specifies the name of the caller who left the attached voice message, as provided by the voice network's caller ID system.
0x6804 => { type => 0x0003, name => "PidTagFaxNumberOfPages" }, # Contains the number of pages in a Fax object.
0x6804 => { type => 0x001e, name => "PidTagOfflineAddressBookDistinguishedName" }, # Contains the distinguished name (DN) (1) of the address list that is contained in the OAB message.
0x6805 => { type => 0x001f, name => "PidTagVoiceMessageAttachmentOrder" }, # Contains a list of file names for the audio file attachments that are to be played as part of a message.
0x6805 => { type => 0x1003, name => "PidTagOfflineAddressBookTruncatedProperties" }, # Contains a list of the property tags that have been truncated or limited by the server.
0x6806 => { type => 0x001f, name => "PidTagCallId" }, # Contains a unique identifier associated with the phone call.
0x6834 => { type => 0x0003, name => "PidTagSearchFolderLastUsed" }, # Contains the last time, in UTC, that the folder was accessed.
0x683a => { type => 0x0003, name => "PidTagSearchFolderExpiration" }, # Contains the time, in UTC, at which the search folder container will be stale and has to be updated or recreated.
0x6841 => { type => 0x0003, name => "PidTagScheduleInfoResourceType" }, # Set to 0x00000000 when sending and is ignored on receipt.
0x6841 => { type => 0x0003, name => "PidTagSearchFolderTemplateId" }, # Contains the ID of the template that is being used for the search.
0x6842 => { type => 0x000b, name => "PidTagScheduleInfoDelegatorWantsCopy" }, # Indicates whether the delegator wants to receive copies of the meeting-related objects that are sent to the delegate.
0x6842 => { type => 0x0102, name => "PidTagSearchFolderId" }, # Contains a GUID that identifies the search folder.
0x6842 => { type => 0x0102, name => "PidTagWlinkGroupHeaderID" }, # Specifies the ID of the navigation shortcut that groups other navigation shortcuts.
0x6843 => { type => 0x000b, name => "PidTagScheduleInfoDontMailDelegates" }, # 
0x6844 => { type => 0x0102, name => "PidTagSearchFolderRecreateInfo" }, # This property is not to be used.
0x6844 => { type => 0x101f, name => "PidTagScheduleInfoDelegateNames" }, # Specifies the names of the delegates.
0x6845 => { type => 0x0102, name => "PidTagSearchFolderDefinition" }, # Specifies the search criteria and search options.
0x6845 => { type => 0x1102, name => "PidTagScheduleInfoDelegateEntryIds" }, # Specifies the EntryIDs of the delegates.
0x6846 => { type => 0x0003, name => "PidTagSearchFolderStorageType" }, # 
0x6846 => { type => 0x000b, name => "PidTagGatewayNeedsToRefresh" }, # This property is deprecated and SHOULD NOT be used.
0x6847 => { type => 0x0003, name => "PidTagFreeBusyPublishStart" }, # Specifies the start time, in UTC, of the publishing range.
0x6847 => { type => 0x0003, name => "PidTagSearchFolderTag" }, # 
0x6847 => { type => 0x0003, name => "PidTagWlinkSaveStamp" }, # Specifies an integer that allows a client to identify with a high probability whether the navigation shortcut was saved by the current client session.
0x6848 => { type => 0x0003, name => "PidTagFreeBusyPublishEnd" }, # Specifies the end time, in UTC, of the publishing range.
0x6848 => { type => 0x0003, name => "PidTagSearchFolderEfpFlags" }, # Specifies flags that control how a folder is displayed.
0x6849 => { type => 0x0003, name => "PidTagWlinkType" }, # Specifies the type of navigation shortcut.
0x6849 => { type => 0x001f, name => "PidTagFreeBusyMessageEmailAddress" }, # Specifies the e-mail address of the user to whom this free/busy message applies.
0x684a => { type => 0x0003, name => "PidTagWlinkFlags" }, # Specifies conditions associated with the shortcut.
0x684a => { type => 0x101f, name => "PidTagScheduleInfoDelegateNamesW" }, # Specifies the names of the delegates in Unicode.
0x684b => { type => 0x000b, name => "PidTagScheduleInfoDelegatorWantsInfo" }, # Indicates whether the delegator wants to receive informational updates.
0x684b => { type => 0x0102, name => "PidTagWlinkOrdinal" }, # Specifies a variable-length binary property to be used to sort shortcuts lexicographically.
0x684c => { type => 0x0102, name => "PidTagWlinkEntryId" }, # Specifies the EntryID of the folder pointed to by the shortcut.
0x684d => { type => 0x0102, name => "PidTagWlinkRecordKey" }, # 
0x684e => { type => 0x0102, name => "PidTagWlinkStoreEntryId" }, # 
0x684f => { type => 0x0102, name => "PidTagWlinkFolderType" }, # Specifies the type of folder pointed to by the shortcut.
0x684f => { type => 0x1003, name => "PidTagScheduleInfoMonthsMerged" }, # 
0x6850 => { type => 0x0102, name => "PidTagWlinkGroupClsid" }, # 
0x6850 => { type => 0x1102, name => "PidTagScheduleInfoFreeBusyMerged" }, # 
0x6851 => { type => 0x001f, name => "PidTagWlinkGroupName" }, # 
0x6851 => { type => 0x1003, name => "PidTagScheduleInfoMonthsTentative" }, # 
0x6852 => { type => 0x0003, name => "PidTagWlinkSection" }, # Specifies the section where the shortcut should be grouped.
0x6852 => { type => 0x1102, name => "PidTagScheduleInfoFreeBusyTentative" }, # 
0x6853 => { type => 0x0003, name => "PidTagWlinkCalendarColor" }, # Specifies the background color of the calendar.
0x6853 => { type => 0x1003, name => "PidTagScheduleInfoMonthsBusy" }, # 
0x6854 => { type => 0x0102, name => "PidTagWlinkAddressBookEID" }, # 
0x6854 => { type => 0x1102, name => "PidTagScheduleInfoFreeBusyBusy" }, # 
0x6855 => { type => 0x1003, name => "PidTagScheduleInfoMonthsAway" }, # Specifies the months for which free/busy data of type OOF is present in the free/busy message.
0x6856 => { type => 0x1102, name => "PidTagScheduleInfoFreeBusyAway" }, # Specifies the times for which the free/busy status is set a value of OOF.
0x6868 => { type => 0x0040, name => "PidTagFreeBusyRangeTimestamp" }, # Specifies the time, in UTC, that the data was published.
0x6869 => { type => 0x0003, name => "PidTagFreeBusyCountMonths" }, # Contains an integer value used to calculate the start and end dates of the range of free/busy data to be published to the public folders.
0x686a => { type => 0x0102, name => "PidTagScheduleInfoAppointmentTombstone" }, # Contains a list of tombstones, where each tombstone represents a Meeting object that has been declined.
0x686b => { type => 0x1003, name => "PidTagDelegateFlags" }, # 
0x686c => { type => 0x0102, name => "PidTagScheduleInfoFreeBusy" }, # This property is deprecated and is not to be used.
0x686d => { type => 0x000b, name => "PidTagScheduleInfoAutoAcceptAppointments" }, # Indicates whether a client or server is to automatically respond to all meeting requests for the attendee or resource.
0x686f => { type => 0x000b, name => "PidTagScheduleInfoDisallowOverlappingAppts" }, # Indicates whether a client or server, when automatically responding to meeting requests, is to decline Meeting Request objects that overlap with previously scheduled events.
0x6890 => { type => 0x0102, name => "PidTagWlinkClientID" }, # Specifies the Client ID that allows the client to determine whether the shortcut was created on the current machine/user via an equality test.
0x6891 => { type => 0x0102, name => "PidTagWlinkAddressBookStoreEID" }, # 
0x6892 => { type => 0x0003, name => "PidTagWlinkROGroupType" }, # Specifies the type of group header.
0x7001 => { type => 0x0102, name => "PidTagViewDescriptorBinary" }, # Contains view definitions.
0x7002 => { type => 0x001f, name => "PidTagViewDescriptorStrings" }, # Contains view definitions in string format.
0x7006 => { type => 0x001f, name => "PidTagViewDescriptorName" }, # 
0x7007 => { type => 0x0003, name => "PidTagViewDescriptorVersion" }, # Contains the View Descriptor version.
0x7c06 => { type => 0x0003, name => "PidTagRoamingDatatypes" }, # Contains a bitmask that indicates which stream properties exist on the message.
0x7c07 => { type => 0x0102, name => "PidTagRoamingDictionary" }, # Contains a dictionary stream, as specified in [MS-OXOCFG] section 2.2.5.1.
0x7c08 => { type => 0x0102, name => "PidTagRoamingXmlStream" }, # Contains an XML stream, as specified in [MS-OXOCFG] section 2.2.5.2.
0x7c24 => { type => 0x000b, name => "PidTagOscSyncEnabled" }, # Specifies whether contact synchronization with an external source is handled by the server.
0x7d01 => { type => 0x000b, name => "PidTagProcessed" }, # Indicates whether a client has already processed a received task communication.
0x7ff9 => { type => 0x0040, name => "PidTagExceptionReplaceTime" }, # Indicates the original date and time, in UTC, at which the instance in the recurrence pattern would have occurred if it were not an exception.
0x7ffa => { type => 0x0003, name => "PidTagAttachmentLinkId" }, # Contains the type of Message object to which an attachment is linked.
0x7ffb => { type => 0x0040, name => "PidTagExceptionStartTime" }, # Contains the end date and time of the exception in the local time zone of the computer when the exception is created.
0x7ffc => { type => 0x0040, name => "PidTagExceptionEndTime" }, # Contains the start date and time of the exception in the local time zone of the computer when the exception is created.
0x7ffd => { type => 0x0003, name => "PidTagAttachmentFlags" }, # Indicates special handling for an Attachment object.
0x7ffe => { type => 0x000b, name => "PidTagAttachmentHidden" }, # Indicates whether an Attachment object is hidden from the end user.
0x7fff => { type => 0x000b, name => "PidTagAttachmentContactPhoto" }, # Indicates that a contact photo attachment is attached to a Contact object.
0x8004 => { type => 0x001f, name => "PidTagAddressBookFolderPathname" }, # This property is deprecated and is to be ignored.
0x8005 => { type => 0x000d, name => "PidTagAddressBookManager" }, # Contains one row that references the mail user's manager.
0x8005 => { type => 0x001f, name => "PidTagAddressBookManagerDistinguishedName" }, # Contains the distinguished name (DN) (1) of the mail user's manager.
0x8006 => { type => 0x001e, name => "PidTagAddressBookHomeMessageDatabase" }, # Contains the DN expressed in the X500 DN format.
0x8008 => { type => 0x001e, name => "PidTagAddressBookIsMemberOfDistributionList" }, # List all the distribution lists for which this object is a member.
0x8009 => { type => 0x000d, name => "PidTagAddressBookMember" }, # Contains the members of the distribution list.
0x800c => { type => 0x000d, name => "PidTagAddressBookOwner" }, # Contains one row that references the distribution list's owner.
0x800e => { type => 0x000d, name => "PidTagAddressBookReports" }, # Lists all the people who report to a mail user.
0x800f => { type => 0x101f, name => "PidTagAddressBookProxyAddresses" }, # Contains alternate e-mail addresses for the Address Book object.
0x8011 => { type => 0x001f, name => "PidTagAddressBookTargetAddress" }, # Contains the foreign system e-mail address of an Address Book object.
0x8015 => { type => 0x000d, name => "PidTagAddressBookPublicDelegates" }, # Contains a list of mail users who are allowed to send e-mail on behalf of the mailbox owner.
0x8024 => { type => 0x000d, name => "PidTagAddressBookOwnerBackLink" }, # Contains a list of the distribution lists owned by a mail user.
0x802d => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute1" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x802e => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute2" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x802f => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute3" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8030 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute4" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8031 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute5" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8032 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute6" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8033 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute7" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8034 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute8" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8035 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute9" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8036 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute10" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x803c => { type => 0x001f, name => "PidTagAddressBookObjectDistinguishedName" }, # Contains the distinguished name (DN) (1) of the Address Book object.
0x806a => { type => 0x0003, name => "PidTagAddressBookDeliveryContentLength" }, # Specifies the maximum size, in bytes, of a message that a recipient (1) can receive.
0x8073 => { type => 0x000d, name => "PidTagAddressBookDistributionListMemberSubmitAccepted" }, # Indicates that delivery restrictions exist for a recipient (1).
0x8170 => { type => 0x101f, name => "PidTagAddressBookNetworkAddress" }, # Contains a list of names by which a server is known to the various transports in use by the network.
0x8c57 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute11" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8c58 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute12" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8c59 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute13" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8c60 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute14" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8c61 => { type => 0x001f, name => "PidTagAddressBookExtensionAttribute15" }, # Contains custom values defined and populated by the organization that modified the display templates.
0x8c6a => { type => 0x1102, name => "PidTagAddressBookX509Certificate" }, # Contains the ASN_1 DER encoded X.509 certificates for the mail user.
0x8c6d => { type => 0x0102, name => "PidTagAddressBookObjectGuid" }, # Contains a GUID that identifies an Address Book object.
0x8c8e => { type => 0x001f, name => "PidTagAddressBookPhoneticGivenName" }, # 
0x8c8f => { type => 0x001f, name => "PidTagAddressBookPhoneticSurname" }, # 
0x8c90 => { type => 0x001f, name => "PidTagAddressBookPhoneticDepartmentName" }, # 
0x8c91 => { type => 0x001f, name => "PidTagAddressBookPhoneticCompanyName" }, # 
0x8c92 => { type => 0x001f, name => "PidTagAddressBookPhoneticDisplayName" }, # 
0x8c93 => { type => 0x0003, name => "PidTagAddressBookDisplayTypeExtended" }, # Contains a value that indicates how to display an Address Book object in a table or as a recipient (1) on a message.
0x8c94 => { type => 0x000d, name => "PidTagAddressBookHierarchicalShowInDepartments" }, # Lists all Department objects of which the mail user is a member.
0x8c96 => { type => 0x101f, name => "PidTagAddressBookRoomContainers" }, # Contains a list of DNs that represent the address book containers that hold Resource objects, such as conference rooms and equipment.
0x8c97 => { type => 0x000d, name => "PidTagAddressBookHierarchicalDepartmentMembers" }, # Contains all of the mail users that belong to this department.
0x8c98 => { type => 0x001e, name => "PidTagAddressBookHierarchicalRootDepartment" }, # Contains the DN of the root departmental group in the department hierarchy for the organization.
0x8c99 => { type => 0x000d, name => "PidTagAddressBookHierarchicalParentDepartment" }, # Contains all of the departments to which this department is a child.
0x8c9a => { type => 0x000d, name => "PidTagAddressBookHierarchicalChildDepartments" }, # Contains the child departments in a hierarchy of departments.
0x8c9e => { type => 0x0102, name => "PidTagThumbnailPhoto" }, # Contains the mail user's photo in .jpg format.
0x8ca0 => { type => 0x0003, name => "PidTagAddressBookSeniorityIndex" }, # Contains a signed integer that specifies the seniority order of Address Book objects that represent members of a department and are referenced by a Department object or departmental group, with larger values specifying members that are more senior.
0x8ca8 => { type => 0x001f, name => "PidTagAddressBookOrganizationalUnitRootDistinguishedName" }, # Contains the distinguished name (DN) (1) of the Organization object of the mail user's organization.
0x8cac => { type => 0x101f, name => "PidTagAddressBookSenderHintTranslations" }, # Contains the locale ID and translations of the default mail tip.
0x8cb5 => { type => 0x000b, name => "PidTagAddressBookModerationEnabled" }, # Indicates whether moderation is enabled for the mail user of the distribution list.
0x8cc2 => { type => 0x0102, name => "PidTagSpokenName" }, # Contains a recording of the mail user's name pronunciation.
0x8cd8 => { type => 0x000d, name => "PidTagAddressBookAuthorizedSenders" }, # Indicates whether delivery restrictions exist for a recipient (1).
0x8cd9 => { type => 0x000d, name => "PidTagAddressBookUnauthorizedSenders" }, # Indicates whether delivery restrictions exist for a recipient (1).
0x8cda => { type => 0x000d, name => "PidTagAddressBookDistributionListMemberSubmitRejected" }, # Indicates that delivery restrictions exist for a recipient (1).
0x8cdb => { type => 0x000d, name => "PidTagAddressBookDistributionListRejectMessagesFromDLMembers" }, # Indicates that delivery restrictions exist for a recipient (1).
0x8cdd => { type => 0x000b, name => "PidTagAddressBookHierarchicalIsHierarchicalGroup" }, # Indicates whether the distribution list represents a departmental group.
0x8ce2 => { type => 0x0003, name => "PidTagAddressBookDistributionListMemberCount" }, # Contains the total number of recipients (1) in the distribution list.
0x8ce3 => { type => 0x0003, name => "PidTagAddressBookDistributionListExternalMemberCount" }, # Contains the number of external recipients (1) in the distribution list.
0xfffb => { type => 0x000b, name => "PidTagAddressBookIsMaster" }, # Contains a Boolean value of TRUE if it is possible to create Address Book objects in that container, and FALSE otherwise.
0xfffc => { type => 0x0102, name => "PidTagAddressBookParentEntryId" }, # Contains the EntryID of the parent container in a hierarchy of address book containers.
0xfffd => { type => 0x0003, name => "PidTagAddressBookContainerId" }, # Contains the ID of a container on an NSPI server.


);

1;
