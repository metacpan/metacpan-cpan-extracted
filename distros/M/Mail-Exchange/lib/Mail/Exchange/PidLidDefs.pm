
package Mail::Exchange::PidLidDefs;
use Exporter;
use vars qw(@ISA @EXPORTER);
@ISA=qw(Exporter);
@EXPORT=qw(%PidLidDefs);

our %PidLidDefs=(
0x0001 => { type => 0x0040, name => "PidLidAttendeeCriticalChange", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Specifies the date and time at which the meeting-related object was sent.
0x0002 => { type => 0x001f, name => "PidLidWhere", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # 
0x0003 => { type => 0x0102, name => "PidLidGlobalObjectId", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Contains an ID for an object that represents an exception to a recurring series.
0x0004 => { type => 0x000b, name => "PidLidIsSilent", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates whether the user did not include any text in the body of the Meeting Response object.
0x0005 => { type => 0x000b, name => "PidLidIsRecurring", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Specifies whether the object is associated with a recurring series.
0x0006 => { type => 0x001f, name => "PidLidRequiredAttendees", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Identifies required attendees for the appointment or meeting.
0x0007 => { type => 0x001f, name => "PidLidOptionalAttendees", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Specifies optional attendees.
0x0008 => { type => 0x001f, name => "PidLidResourceAttendees", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Identifies resource attendees for the appointment or meeting.
0x0009 => { type => 0x000b, name => "PidLidDelegateMail", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates whether a delegate responded to the meeting request.
0x000a => { type => 0x000b, name => "PidLidIsException", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates whether the object represents an exception (including an orphan instance).
0x000c => { type => 0x0003, name => "PidLidTimeZone", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Specifies information about the time zone of a recurring meeting.
0x000d => { type => 0x0003, name => "PidLidStartRecurrenceDate", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Identifies the start date of the recurrence pattern.
0x000e => { type => 0x0003, name => "PidLidStartRecurrenceTime", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Identifies the start time of the recurrence pattern.
0x000f => { type => 0x0003, name => "PidLidEndRecurrenceDate", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Identifies the end date of the recurrence range.
0x0010 => { type => 0x0003, name => "PidLidEndRecurrenceTime", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Identifies the end time of the recurrence range.
0x0011 => { type => 0x0002, name => "PidLidDayInterval", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Identifies the day interval for the recurrence pattern.
0x0012 => { type => 0x0002, name => "PidLidWeekInterval", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Identifies the number of weeks that occur between each meeting.
0x0013 => { type => 0x0002, name => "PidLidMonthInterval", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates the monthly interval of the appointment or meeting.
0x0014 => { type => 0x0002, name => "PidLidYearInterval", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates the yearly interval of the appointment or meeting.
0x0015 => { type => 0x0003, name => "PidLidClientIntent", guid => "11000E07-B51B-40D6-AF21-CAA85EDAB1D0" }, # Indicates what actions the user has taken on this Meeting object.
0x0017 => { type => 0x0003, name => "PidLidMonthOfYearMask", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates the calculated month of the year in which the appointment or meeting occurs.
0x0018 => { type => 0x0002, name => "PidLidOldRecurrenceType", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates the recurrence pattern for the appointment or meeting.
0x001a => { type => 0x0040, name => "PidLidOwnerCriticalChange", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Specifies the date and time at which a Meeting Request object was sent by the organizer.
0x001c => { type => 0x0003, name => "PidLidCalendarType", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # 
0x0023 => { type => 0x0102, name => "PidLidCleanGlobalObjectId", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # 
0x0024 => { type => 0x001f, name => "PidLidAppointmentMessageClass", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates the message class of the Meeting object to be generated from the Meeting Request object.
0x0026 => { type => 0x0003, name => "PidLidMeetingType", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # Indicates the type of Meeting Request object or Meeting Update object.
0x0028 => { type => 0x001f, name => "PidLidOldLocation", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # 
0x0029 => { type => 0x0040, name => "PidLidOldWhenStartWhole", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # 
0x002a => { type => 0x0040, name => "PidLidOldWhenEndWhole", guid => "6ED8DA90-450B-101B-98DA-00AA003F1305" }, # 
0x1000 => { type => 0x0003, name => "PidLidDayOfMonth", guid => "00062008-0000-0000-C000-000000000046" }, # Identifies the day of the month for the appointment or meeting.
0x1001 => { type => 0x0003, name => "PidLidICalendarDayOfWeekMask", guid => "00062008-0000-0000-C000-000000000046" }, # Identifies the day of the week for the appointment or meeting.
0x1005 => { type => 0x0003, name => "PidLidOccurrences", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates the number of occurrences in the recurring appointment or meeting.
0x1006 => { type => 0x0003, name => "PidLidMonthOfYear", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates the month of the year in which the appointment or meeting occurs.
0x100b => { type => 0x000b, name => "PidLidNoEndDateFlag", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates whether the recurrence pattern has an end date.
0x100d => { type => 0x0003, name => "PidLidRecurrenceDuration", guid => "00062008-0000-0000-C000-000000000046" }, # Identifies the length, in minutes, of the appointment or meeting.
0x8005 => { type => 0x001f, name => "PidLidFileUnder", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the name under which to file a contact when displaying a list of contacts.
0x8006 => { type => 0x0003, name => "PidLidFileUnderId", guid => "00062004-0000-0000-C000-000000000046" }, # 
0x8007 => { type => 0x1003, name => "PidLidContactItemData", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the visible fields in the application's user interface that are used to help display the contact information.
0x800e => { type => 0x001f, name => "PidLidReferredBy", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the name of the person who referred the contact to the user.
0x8010 => { type => 0x001f, name => "PidLidDepartment", guid => "00062004-0000-0000-C000-000000000046" }, # This property is ignored by the server and is set to an empty string by the client.
0x8015 => { type => 0x000b, name => "PidLidHasPicture", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies whether the attachment has a picture.
0x801a => { type => 0x001f, name => "PidLidHomeAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the complete address of the contact's home address.
0x801b => { type => 0x001f, name => "PidLidWorkAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the complete address of the contact's work address.
0x801c => { type => 0x001f, name => "PidLidOtherAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the complete address of the contact's other address.
0x8022 => { type => 0x0003, name => "PidLidPostalAddressId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies which physical address is the mailing address for this contact.
0x8023 => { type => 0x0003, name => "PidLidContactCharacterSet", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the character set used for a Contact object.
0x8025 => { type => 0x000b, name => "PidLidAutoLog", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies to the application whether to create a Journal object for each action associated with this Contact object.
0x8026 => { type => 0x1003, name => "PidLidFileUnderList", guid => "00062004-0000-0000-C000-000000000046" }, # 
0x8028 => { type => 0x1003, name => "PidLidAddressBookProviderEmailList", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies which electronic address properties are set on the Contact object.
0x8029 => { type => 0x0003, name => "PidLidAddressBookProviderArrayType", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the state of the contact's electronic addresses and represents a set of bit flags.
0x802b => { type => 0x001f, name => "PidLidHtml", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the contact's business webpage URL.
0x802c => { type => 0x001f, name => "PidLidYomiFirstName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the phonetic pronunciation of the contact's given name.
0x802d => { type => 0x001f, name => "PidLidYomiLastName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the phonetic pronunciation of the contact's surname.
0x802e => { type => 0x001f, name => "PidLidYomiCompanyName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the phonetic pronunciation of the contact's company name.
0x8040 => { type => 0x0102, name => "PidLidBusinessCardDisplayDefinition", guid => "00062004-0000-0000-C000-000000000046" }, # Contains user customization details for displaying a contact as a business card.
0x8041 => { type => 0x0102, name => "PidLidBusinessCardCardPicture", guid => "00062004-0000-0000-C000-000000000046" }, # Contains the image to be used on a business card.
0x8045 => { type => 0x000b, name => "PidLidPromptSendUpdate", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates that the Meeting Response object was out-of-date when it was received.
0x8045 => { type => 0x001f, name => "PidLidWorkAddressStreet", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the street portion of the contact's work address.
0x8046 => { type => 0x001f, name => "PidLidWorkAddressCity", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the city or locality portion of the contact's work address.
0x8047 => { type => 0x001f, name => "PidLidWorkAddressState", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the state or province portion of the contact's work address.
0x8048 => { type => 0x001f, name => "PidLidWorkAddressPostalCode", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the postal code (ZIP code) portion of the contact's work address.
0x8049 => { type => 0x001f, name => "PidLidWorkAddressCountry", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the country or region portion of the contact's work address.
0x804a => { type => 0x001f, name => "PidLidWorkAddressPostOfficeBox", guid => "00062004-0000-0000-C00-000000000046" }, # Specifies the post office box portion of the contact's work address.
0x804c => { type => 0x0003, name => "PidLidDistributionListChecksum", guid => "00062004-0000-0000-C000-000000000046" }, # 
0x804d => { type => 0x0102, name => "PidLidBirthdayEventEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the EntryID of an optional Appointment object that represents the contact's birthday.
0x804e => { type => 0x0102, name => "PidLidAnniversaryEventEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the EntryID of the Appointment object that represents a contact's anniversary.
0x804f => { type => 0x001f, name => "PidLidContactUserField1", guid => "00062004-0000-0000-C000-000000000046" }, # Contains text used to add custom text to a business card representation of a Contact object.
0x8050 => { type => 0x001f, name => "PidLidContactUserField2", guid => "00062004-0000-0000-C000-000000000046" }, # Contains text used to add custom text to a business card representation of a Contact object.
0x8051 => { type => 0x001f, name => "PidLidContactUserField3", guid => "00062004-0000-0000-C000-000000000046" }, # Contains text used to add custom text to a business card representation of a Contact object.
0x8052 => { type => 0x001f, name => "PidLidContactUserField4", guid => "00062004-0000-0000-C000-000000000046" }, # Contains text used to add custom text to a business card representation of a Contact object.
0x8053 => { type => 0x001f, name => "PidLidDistributionListName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the name of the personal distribution list.
0x8054 => { type => 0x1102, name => "PidLidDistributionListOneOffMembers", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the list of one-off EntryIDs corresponding to the members of the personal distribution list.
0x8055 => { type => 0x1102, name => "PidLidDistributionListMembers", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the list of EntryIDs of the objects corresponding to the members of the personal distribution list.
0x8062 => { type => 0x001f, name => "PidLidInstantMessagingAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the contact's instant messaging address.
0x8064 => { type => 0x0102, name => "PidLidDistributionListStream", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the list of EntryIDs and one-off EntryIDs corresponding to the members of the personal distribution list.
0x8080 => { type => 0x001f, name => "PidLidEmail1DisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the user-readable display name for the e-mail address.
0x8082 => { type => 0x001f, name => "PidLidEmail1AddressType", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the address type of an electronic address.
0x8083 => { type => 0x001f, name => "PidLidEmail1EmailAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the e-mail address of the contact.
0x8084 => { type => 0x001f, name => "PidLidEmail1OriginalDisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the SMTP e-mail address that corresponds to the e-mail address for the Contact object.
0x8085 => { type => 0x0102, name => "PidLidEmail1OriginalEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the EntryID of the object corresponding to this electronic address.
0x8090 => { type => 0x001f, name => "PidLidEmail2DisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the user-readable display name for the e-mail address.
0x8092 => { type => 0x001f, name => "PidLidEmail2AddressType", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the address type of the electronic address.
0x8093 => { type => 0x001f, name => "PidLidEmail2EmailAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the e-mail address of the contact.
0x8094 => { type => 0x001f, name => "PidLidEmail2OriginalDisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the SMTP e-mail address that corresponds to the e-mail address for the Contact object.
0x8095 => { type => 0x0102, name => "PidLidEmail2OriginalEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the EntryID of the object that corresponds to this electronic address.
0x80a0 => { type => 0x001f, name => "PidLidEmail3DisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the user-readable display name for the e-mail address.
0x80a2 => { type => 0x001f, name => "PidLidEmail3AddressType", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the address type of the electronic address.
0x80a3 => { type => 0x001f, name => "PidLidEmail3EmailAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the e-mail address of the contact.
0x80a4 => { type => 0x001f, name => "PidLidEmail3OriginalDisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the SMTP e-mail address that corresponds to the e-mail address for the Contact object.
0x80a5 => { type => 0x0102, name => "PidLidEmail3OriginalEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the EntryID of the object that corresponds to this electronic address.
0x80b2 => { type => 0x001f, name => "PidLidFax1AddressType", guid => "00062004-0000-0000-C000-000000000046" }, # Contains the string value "FAX".
0x80b3 => { type => 0x001f, name => "PidLidFax1EmailAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Contains a user-readable display name, followed by the "@" character, followed by a fax number.
0x80b4 => { type => 0x001f, name => "PidLidFax1OriginalDisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # 
0x80b5 => { type => 0x0102, name => "PidLidFax1OriginalEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies a one-off EntryID that corresponds to this fax address.
0x80c2 => { type => 0x001f, name => "PidLidFax2AddressType", guid => "00062004-0000-0000-C000-000000000046" }, # Contains the string value "FAX".
0x80c3 => { type => 0x001f, name => "PidLidFax2EmailAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Contains a user-readable display name, followed by the "@" character, followed by a fax number.
0x80c4 => { type => 0x001f, name => "PidLidFax2OriginalDisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # 
0x80c5 => { type => 0x0102, name => "PidLidFax2OriginalEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies a one-off EntryID corresponding to this fax address.
0x80d2 => { type => 0x001f, name => "PidLidFax3AddressType", guid => "00062004-0000-0000-C000-000000000046" }, # Contains the string value "FAX".
0x80d3 => { type => 0x001f, name => "PidLidFax3EmailAddress", guid => "00062004-0000-0000-C000-000000000046" }, # Contains a user-readable display name, followed by the "@" character, followed by a fax number.
0x80d4 => { type => 0x001f, name => "PidLidFax3OriginalDisplayName", guid => "00062004-0000-0000-C000-000000000046" }, # 
0x80d5 => { type => 0x0102, name => "PidLidFax3OriginalEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies a one-off EntryID that corresponds to this fax address.
0x80d8 => { type => 0x001f, name => "PidLidFreeBusyLocation", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies a URL path from which a client can retrieve free/busy status information for the contact.
0x80da => { type => 0x001f, name => "PidLidHomeAddressCountryCode", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the country code portion of the contact's home address.
0x80db => { type => 0x001f, name => "PidLidWorkAddressCountryCode", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the country code portion of the contact's work address.
0x80dc => { type => 0x001f, name => "PidLidOtherAddressCountryCode", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the country code portion of the contact's other address.
0x80dd => { type => 0x001f, name => "PidLidAddressCountryCode", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the country code portion of the contact's mailing address.
0x80de => { type => 0x0040, name => "PidLidBirthdayLocal", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the birthday of a contact.
0x80df => { type => 0x0040, name => "PidLidWeddingAnniversaryLocal", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the wedding anniversary of the contact, at midnight in the client's local time zone, and is saved without any time zone conversions.
0x80e0 => { type => 0x000b, name => "PidLidIsContactLinked", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies whether the contact is linked to other contacts.
0x80e2 => { type => 0x0102, name => "PidLidContactLinkedGlobalAddressListEntryId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the EntryID of the GAL contact to which the duplicate contact is linked.
0x80e3 => { type => 0x101f, name => "PidLidContactLinkSMTPAddressCache", guid => "00062004-0000-0000-C000-000000000046" }, # Contains a list of the SMTP addresses that are used by the contact.
0x80e5 => { type => 0x1102, name => "PidLidContactLinkLinkRejectHistory", guid => "00062004-0000-0000-C000-000000000046" }, # Contains a list of GAL contacts that were previously rejected for linking with the duplicate contact.
0x80e6 => { type => 0x0003, name => "PidLidContactLinkGlobalAddressListLinkState", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the state of the linking between the GAL contact and the duplicate contact.
0x80e8 => { type => 0x0048, name => "PidLidContactLinkGlobalAddressListLinkId", guid => "00062004-0000-0000-C000-000000000046" }, # Specifies the GUID of the GAL contact to which the duplicate contact is linked.
0x8101 => { type => 0x0003, name => "PidLidTaskStatus", guid => "00062003-0000-0000-C000-000000000046" }, # Specifies the status of a task.
0x8102 => { type => 0x0005, name => "PidLidPercentComplete", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates whether a time-flagged Message object is complete.
0x8103 => { type => 0x000b, name => "PidLidTeamTask", guid => "00062003-0000-0000-C000-000000000046" }, # This property is set by the client but is ignored by the server.
0x8104 => { type => 0x0040, name => "PidLidTaskStartDate", guid => "00062003-0000-0000-C000-000000000046" }, # Specifies the date on which the user expects work on the task to begin.
0x8105 => { type => 0x0040, name => "PidLidTaskDueDate", guid => "00062003-0000-0000-C000-000000000046" }, # Specifies the date by which the user expects work on the task to be complete.
0x8107 => { type => 0x000b, name => "PidLidTaskResetReminder", guid => "00062003-0000-0000-C000-000000000046" }, # 
0x8108 => { type => 0x000b, name => "PidLidTaskAccepted", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates whether a task assignee has replied to a task request for this Task object.
0x8109 => { type => 0x000b, name => "PidLidTaskDeadOccurrence", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates whether new occurrences remain to be generated.
0x810f => { type => 0x0040, name => "PidLidTaskDateCompleted", guid => "00062003-0000-0000-C000-000000000046" }, # Specifies the date when the user completed work on the task.
0x8110 => { type => 0x0003, name => "PidLidTaskActualEffort", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates the number of minutes that the user actually spent working on a task.
0x8111 => { type => 0x0003, name => "PidLidTaskEstimatedEffort", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates the number of minutes that the user expects to work on a task.
0x8112 => { type => 0x0003, name => "PidLidTaskVersion", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates which copy is the latest update of a Task object.
0x8113 => { type => 0x0003, name => "PidLidTaskState", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates the current assignment state of the Task object.
0x8115 => { type => 0x0040, name => "PidLidTaskLastUpdate", guid => "00062003-0000-0000-C000-000000000046" }, # Contains the date and time of the most recent change made to the Task object.
0x8116 => { type => 0x0102, name => "PidLidTaskRecurrence", guid => "00062003-0000-0000-C000-000000000046" }, # 
0x8117 => { type => 0x0102, name => "PidLidTaskAssigners", guid => "00062003-0000-0000-C000-000000000046" }, # Contains a stack of entries, each of which represents a task assigner.
0x8119 => { type => 0x000b, name => "PidLidTaskStatusOnComplete", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates whether the task assignee has been requested to send an e-mail message update upon completion of the assigned task.
0x811a => { type => 0x0003, name => "PidLidTaskHistory", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates the type of change that was last made to the Task object.
0x811b => { type => 0x000b, name => "PidLidTaskUpdates", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates whether the task assignee has been requested to send a task update when the assigned Task object changes.
0x811c => { type => 0x000b, name => "PidLidTaskComplete", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates that the task is complete.
0x811e => { type => 0x000b, name => "PidLidTaskFCreator", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates that the Task object was originally created by the action of the current user or user agent instead of by the processing of a task request.
0x811f => { type => 0x001f, name => "PidLidTaskOwner", guid => "00062003-0000-0000-C000-000000000046" }, # Contains the name of the owner of the task.
0x8120 => { type => 0x0003, name => "PidLidTaskMultipleRecipients", guid => "00062003-0000-0000-C000-000000000046" }, # Provides optimization hints about the recipients (2) of a Task object.
0x8121 => { type => 0x001f, name => "PidLidTaskAssigner", guid => "00062003-0000-0000-C000-000000000046" }, # Specifies the name of the user that last assigned the task.
0x8122 => { type => 0x001f, name => "PidLidTaskLastUser", guid => "00062003-0000-0000-C000-000000000046" }, # Contains the name of the most recent user to have been the owner of the task.
0x8123 => { type => 0x0003, name => "PidLidTaskOrdinal", guid => "00062003-0000-0000-C000-000000000046" }, # Provides an aid to custom sorting of Task objects.
0x8124 => { type => 0x000b, name => "PidLidTaskNoCompute", guid => "00062003-0000-0000-C000-000000000046" }, # Not used. The client can set this property, but it has no impact on the Task-Related Objects Protocol and is ignored by the server.
0x8125 => { type => 0x001f, name => "PidLidTaskLastDelegate", guid => "00062003-0000-0000-C000-000000000046" }, # Contains the name of the user who most recently assigned the task, or the user to whom it was most recently assigned.
0x8126 => { type => 0x000b, name => "PidLidTaskFRecurring", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates whether the task includes a recurrence pattern.
0x8127 => { type => 0x001f, name => "PidLidTaskRole", guid => "00062003-0000-0000-C000-000000000046" }, # Not used. The client can set this property, but it has no impact on the Task-Related Objects Protocol and is ignored by the server.
0x8129 => { type => 0x0003, name => "PidLidTaskOwnership", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates the role of the current user relative to the Task object.
0x812a => { type => 0x0003, name => "PidLidTaskAcceptanceState", guid => "00062003-0000-0000-C000-000000000046" }, # Indicates the acceptance state of the task.
0x812c => { type => 0x000b, name => "PidLidTaskFFixOffline", guid => "00062003-0000-0000-C000-000000000046" }, # 
0x8139 => { type => 0x0003, name => "PidLidTaskCustomFlags", guid => "00062003-0000-0000-C000-000000000046" }, # The client can set this property, but it has no impact on the Task-Related Objects Protocol and is ignored by the server.
0x8201 => { type => 0x0003, name => "PidLidAppointmentSequence", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the sequence number of a Meeting object.
0x8202 => { type => 0x0040, name => "PidLidAppointmentSequenceTime", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8203 => { type => 0x0003, name => "PidLidAppointmentLastSequence", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates to the organizer the last sequence number that was sent to any attendee.
0x8204 => { type => 0x0003, name => "PidLidChangeHighlight", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies a bit field that indicates how the Meeting object has changed.
0x8205 => { type => 0x0003, name => "PidLidBusyStatus", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the availability of a user for the event described by the object.
0x8206 => { type => 0x000b, name => "PidLidFExceptionalBody", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates that the Exception Embedded Message object has a body that differs from the Recurring Calendar object.
0x8207 => { type => 0x0003, name => "PidLidAppointmentAuxiliaryFlags", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies a bit field that describes the auxiliary state of the object.
0x8208 => { type => 0x001f, name => "PidLidLocation", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the location of the event.
0x8209 => { type => 0x001f, name => "PidLidMeetingWorkspaceUrl", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the URL of the Meeting Workspace that is associated with a Calendar object.
0x820a => { type => 0x000b, name => "PidLidForwardInstance", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates whether the Meeting Request object represents an exception to a recurring series, and whether it was forwarded (even when forwarded by the organizer) rather than being an invitation sent by the organizer.
0x820c => { type => 0x1102, name => "PidLidLinkedTaskItems", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates whether the user did not include any text in the body of the Meeting Response object.
0x820d => { type => 0x0040, name => "PidLidAppointmentStartWhole", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the start date and time of the appointment.
0x820e => { type => 0x0040, name => "PidLidAppointmentEndWhole", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the end date and time for the event.
0x820f => { type => 0x0040, name => "PidLidAppointmentStartTime", guid => "00062002-0000-0000-C000-000000000046" }, # Identifies the time that the appointment starts.
0x8210 => { type => 0x0040, name => "PidLidAppointmentEndTime", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates the time that the appointment ends.
0x8211 => { type => 0x0040, name => "PidLidAppointmentEndDate", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates the date that the appointment ends.
0x8212 => { type => 0x0040, name => "PidLidAppointmentStartDate", guid => "00062002-0000-0000-C000-000000000046" }, # Identifies the date that the appointment starts.
0x8213 => { type => 0x0003, name => "PidLidAppointmentDuration", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the length of the event, in minutes.
0x8214 => { type => 0x0003, name => "PidLidAppointmentColor", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the color to be used when displaying the Calendar object.
0x8215 => { type => 0x000b, name => "PidLidAppointmentSubType", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies whether the event is an all-day event.
0x8216 => { type => 0x0102, name => "PidLidAppointmentRecur", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the dates and times when a recurring series occurs.
0x8217 => { type => 0x0003, name => "PidLidAppointmentStateFlags", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies a bit field that describes the state of the object.
0x8218 => { type => 0x0003, name => "PidLidResponseStatus", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the response status of an attendee.
0x8220 => { type => 0x0040, name => "PidLidAppointmentReplyTime", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the date and time at which the attendee responded to a received meeting request or Meeting Update object.
0x8223 => { type => 0x000b, name => "PidLidRecurring", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies whether the object represents a recurring series.
0x8224 => { type => 0x0003, name => "PidLidIntendedBusyStatus", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8226 => { type => 0x0040, name => "PidLidAppointmentUpdateTime", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates the time at which the appointment was last updated.
0x8228 => { type => 0x0040, name => "PidLidExceptionReplaceTime", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the date and time, in UTC, within a recurrence pattern that an exception will replace.
0x8229 => { type => 0x000b, name => "PidLidFInvited", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates whether invitations have been sent for the meeting that this Meeting object represents.
0x822b => { type => 0x000b, name => "PidLidFExceptionalAttendees", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x822e => { type => 0x001f, name => "PidLidOwnerName", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates the name of the owner of the mailbox.
0x822f => { type => 0x000b, name => "PidLidFOthersAppointment", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates whether the Calendar folder from which the meeting was opened is another user's calendar.
0x8230 => { type => 0x001f, name => "PidLidAppointmentReplyName", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the user who last replied to the meeting request or meeting update.
0x8231 => { type => 0x0003, name => "PidLidRecurrenceType", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the recurrence type of the recurring series.
0x8232 => { type => 0x001f, name => "PidLidRecurrencePattern", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies a description of the recurrence pattern of the Calendar object.
0x8233 => { type => 0x0102, name => "PidLidTimeZoneStruct", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies time zone information for a recurring meeting.
0x8234 => { type => 0x001f, name => "PidLidTimeZoneDescription", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8235 => { type => 0x0040, name => "PidLidClipStart", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the start date and time of the event in UTC.
0x8236 => { type => 0x0040, name => "PidLidClipEnd", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the end date and time of the event in UTC.
0x8237 => { type => 0x0102, name => "PidLidOriginalStoreEntryId", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the EntryID of the delegator’s store.
0x8238 => { type => 0x001f, name => "PidLidAllAttendeesString", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies a list of all the attendees except for the organizer, including resources and unsendable attendees.
0x823a => { type => 0x000b, name => "PidLidAutoFillLocation", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x823b => { type => 0x001f, name => "PidLidToAttendeesString", guid => "00062002-0000-0000-C000-000000000046" }, # Contains a list of all of the sendable attendees who are also required attendees.
0x823c => { type => 0x001f, name => "PidLidCcAttendeesString", guid => "00062002-0000-0000-C000-000000000046" }, # Contains a list of all the sendable attendees who are also optional attendees.
0x823e => { type => 0x000b, name => "PidLidTrustRecipientHighlights", guid => "00062003-0000-0000-C000-000000000046" }, # 
0x8240 => { type => 0x000b, name => "PidLidConferencingCheck", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8241 => { type => 0x0003, name => "PidLidConferencingType", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the type of the meeting.
0x8242 => { type => 0x001f, name => "PidLidDirectory", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the directory server to be used.
0x8243 => { type => 0x001f, name => "PidLidOrganizerAlias", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the e-mail address of the organizer.
0x8244 => { type => 0x000b, name => "PidLidAutoStartCheck", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies whether to automatically start the conferencing application when a reminder for the start of a meeting is executed.
0x8247 => { type => 0x001f, name => "PidLidCollaborateDoc", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the document to be launched when the user joins the meeting.
0x8248 => { type => 0x001f, name => "PidLidNetShowUrl", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the URL to be launched when the user joins the meeting.
0x8249 => { type => 0x001f, name => "PidLidOnlinePassword", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8250 => { type => 0x0040, name => "PidLidAppointmentProposedStartWhole", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8251 => { type => 0x0040, name => "PidLidAppointmentProposedEndWhole", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8256 => { type => 0x0003, name => "PidLidAppointmentProposedDuration", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8257 => { type => 0x000b, name => "PidLidAppointmentCounterProposal", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates whether a Meeting Response object is a counter proposal.
0x8259 => { type => 0x0003, name => "PidLidAppointmentProposalNumber", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies the number of attendees who have sent counter proposals that have not been accepted or rejected by the organizer.
0x825a => { type => 0x000b, name => "PidLidAppointmentNotAllowPropose", guid => "00062002-0000-0000-C000-000000000046" }, # Indicates whether attendees are not allowed to propose a new date and/or time for the meeting.
0x825d => { type => 0x0102, name => "PidLidAppointmentUnsendableRecipients", guid => "00062002-0000-0000-C000-000000000046" }, # Contains a list of unsendable attendees.
0x825e => { type => 0x0102, name => "PidLidAppointmentTimeZoneDefinitionStartDisplay", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x825f => { type => 0x0102, name => "PidLidAppointmentTimeZoneDefinitionEndDisplay", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8260 => { type => 0x0102, name => "PidLidAppointmentTimeZoneDefinitionRecur", guid => "00062002-0000-0000-C000-000000000046" }, # Specifies time zone information that describes how to convert the meeting date and time on a recurring series to and from UTC.
0x8261 => { type => 0x0102, name => "PidLidForwardNotificationRecipients", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x827a => { type => 0x0102, name => "PidLidInboundICalStream", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x827b => { type => 0x000b, name => "PidLidSingleBodyICal", guid => "00062002-0000-0000-C000-000000000046" }, # 
0x8501 => { type => 0x0003, name => "PidLidReminderDelta", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the interval, in minutes, between the time at which the reminder first becomes overdue and the start time of the Calendar object.
0x8502 => { type => 0x0040, name => "PidLidReminderTime", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the initial signal time for objects that are not Calendar objects.
0x8503 => { type => 0x000b, name => "PidLidReminderSet", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies whether a reminder is set on the object.
0x8504 => { type => 0x0040, name => "PidLidReminderTimeTime", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates the time of the reminder for the appointment or meeting.
0x8505 => { type => 0x0040, name => "PidLidReminderTimeDate", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates the time and date of the reminder for the appointment or meeting.
0x8506 => { type => 0x000b, name => "PidLidPrivate", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates whether the end user wishes for this Message object to be hidden from other users who have access to the Message object.
0x850e => { type => 0x000b, name => "PidLidAgingDontAgeMe", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies whether to automatically archive the message.
0x8510 => { type => 0x0003, name => "PidLidSideEffects", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies how a Message object is handled by the client in relation to certain user interface actions by the user, such as deleting a message.
0x8511 => { type => 0x0003, name => "PidLidRemoteStatus", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates the remote status of the calendar item.
0x8514 => { type => 0x000b, name => "PidLidSmartNoAttach", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates whether the Message object has no end-user visible attachments.
0x8516 => { type => 0x0040, name => "PidLidCommonStart", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates the start time for the Message object.
0x8517 => { type => 0x0040, name => "PidLidCommonEnd", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates the end time for the Message object.
0x8518 => { type => 0x0003, name => "PidLidTaskMode", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the assignment status of the embedded Task object.
0x8519 => { type => 0x0102, name => "PidLidTaskGlobalId", guid => "00062008-0000-0000-C000-000000000046" }, # Contains a unique GUID for this task, which is used to locate an existing task upon receipt of a task response or task update.
0x851a => { type => 0x0003, name => "PidLidAutoProcessState", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the options used in the automatic processing of e-mail messages.
0x851c => { type => 0x000b, name => "PidLidReminderOverride", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x851d => { type => 0x0003, name => "PidLidReminderType", guid => "00062008-0000-0000-C000-000000000046" }, # This property is not set and, if set, is ignored.
0x851e => { type => 0x000b, name => "PidLidReminderPlaySound", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies whether the client is to play a sound when the reminder becomes overdue.
0x851f => { type => 0x001f, name => "PidLidReminderFileParameter", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the filename of the sound that a client is to play when the reminder for that object becomes overdue.
0x8520 => { type => 0x0102, name => "PidLidVerbStream", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies what voting responses the user can make in response to the message.
0x8524 => { type => 0x001f, name => "PidLidVerbResponse", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the voting option that a respondent has selected.
0x8530 => { type => 0x001f, name => "PidLidFlagRequest", guid => "00062008-0000-0000-C000-000000000046" }, # Contains user-specifiable text to be associated with the flag.
0x8535 => { type => 0x001f, name => "PidLidBilling", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies billing information for the contact.
0x8536 => { type => 0x001f, name => "PidLidNonSendableTo", guid => "00062008-0000-0000-C000-000000000046" }, # Contains a list of all of the unsendable attendees who are also required attendees.
0x8537 => { type => 0x001f, name => "PidLidNonSendableCc", guid => "00062008-0000-0000-C000-000000000046" }, # Contains a list of all of the unsendable attendees who are also optional attendees.
0x8538 => { type => 0x001f, name => "PidLidNonSendableBcc", guid => "00062008-0000-0000-C000-000000000046" }, # Contains a list of all of the unsendable attendees who are also resources.
0x8539 => { type => 0x101f, name => "PidLidCompanies", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x853a => { type => 0x101f, name => "PidLidContacts", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x8543 => { type => 0x1003, name => "PidLidNonSendToTrackStatus", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the value from the response table.
0x8544 => { type => 0x1003, name => "PidLidNonSendCcTrackStatus", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the value from the response table.
0x8545 => { type => 0x1003, name => "PidLidNonSendBccTrackStatus", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the value from the response table.
0x8552 => { type => 0x0003, name => "PidLidCurrentVersion", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the build number of the client application that sent the message.
0x8554 => { type => 0x001f, name => "PidLidCurrentVersionName", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the name of the client application that sent the message.
0x8560 => { type => 0x0040, name => "PidLidReminderSignalTime", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the point in time when a reminder transitions from pending to overdue.
0x8580 => { type => 0x001f, name => "PidLidInternetAccountName", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the user-visible e-mail account name through which the e-mail message is sent.
0x8581 => { type => 0x001f, name => "PidLidInternetAccountStamp", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the e-mail account ID through which the e-mail message is sent.
0x8582 => { type => 0x000b, name => "PidLidUseTnef", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies whether Transport Neutral Encapsulation Format (TNEF) is to be included on a message when the message is converted from TNEF to MIME or SMTP format.
0x8584 => { type => 0x0102, name => "PidLidContactLinkSearchKey", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the list of SearchKeys for a Contact object linked to by the Message object.
0x8585 => { type => 0x0102, name => "PidLidContactLinkEntry", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x8586 => { type => 0x001f, name => "PidLidContactLinkName", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x859c => { type => 0x0102, name => "PidLidSpamOriginalFolder", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies which folder a message was in before it was filtered into the Junk E-mail folder.
0x85a0 => { type => 0x0040, name => "PidLidToDoOrdinalDate", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the current time, in UTC, which is used to determine the sort order of objects in a consolidated to-do list.
0x85a1 => { type => 0x001f, name => "PidLidToDoSubOrdinal", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x85a4 => { type => 0x001f, name => "PidLidToDoTitle", guid => "00062008-0000-0000-C000-000000000046" }, # Contains user-specifiable text to identify this Message object in a consolidated to-do list.
0x85b1 => { type => 0x001f, name => "PidLidInfoPathFormName", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the name of the form associated with this message.
0x85b5 => { type => 0x000b, name => "PidLidClassified", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates whether the contents of this message are regarded as classified information.
0x85b6 => { type => 0x001f, name => "PidLidClassification", guid => "00062008-0000-0000-C000-000000000046" }, # Contains a list of the classification categories to which the associated Message object has been assigned.
0x85b7 => { type => 0x001f, name => "PidLidClassificationDescription", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x85b8 => { type => 0x001f, name => "PidLidClassificationGuid", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the GUID that identifies the list of e-mail classification categories used by a Message object.
0x85ba => { type => 0x000b, name => "PidLidClassificationKeep", guid => "00062008-0000-0000-C000-000000000046" }, # Indicates whether the message uses any classification categories.
0x85bd => { type => 0x0102, name => "PidLidReferenceEntryId", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the value of the EntryID of the Contact object unless the Contact object is a copy of an earlier original.
0x85bf => { type => 0x0040, name => "PidLidValidFlagStringProof", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x85c0 => { type => 0x0003, name => "PidLidFlagString", guid => "00062008-0000-0000-C000-000000000046" }, # Contains an index identifying one of a set of pre-defined text strings to be associated with the flag.
0x85c6 => { type => 0x0102, name => "PidLidConversationActionMoveFolderEid", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the EntryID for the destination folder.
0x85c7 => { type => 0x0102, name => "PidLidConversationActionMoveStoreEid", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the EntryID for a move to a folder in a different store.
0x85c8 => { type => 0x0040, name => "PidLidConversationActionMaxDeliveryTime", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x85c9 => { type => 0x0003, name => "PidLidConversationProcessed", guid => "00062008-0000-0000-C000-000000000046" }, # 
0x85ca => { type => 0x0040, name => "PidLidConversationActionLastAppliedTime", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the time, in UTC, that an E-mail object was last received in the conversation, or the last time that the user modified the conversation action, whichever occurs later.
0x85cb => { type => 0x0003, name => "PidLidConversationActionVersion", guid => "00062008-0000-0000-C000-000000000046" }, # Contains the version of the conversation actionFAI message.
0x85cc => { type => 0x000b, name => "PidLidServerProcessed", guid => "11000E07-B51B-40D6-AF21-CAA85EDAB1D0" }, # Indicates whether the Meeting Request object or Meeting Update object has been processed.
0x85cd => { type => 0x0003, name => "PidLidServerProcessingActions", guid => "11000E07-B51B-40D6-AF21-CAA85EDAB1D0" }, # Indicates what processing actions have been taken on this Meeting Request object or Meeting Update object.
0x85e0 => { type => 0x0003, name => "PidLidPendingStateForSiteMailboxDocument", guid => "00062008-0000-0000-C000-000000000046" }, # Specifies the synchronization state of the Document object that is in the Document Libraries folder of the site mailbox.
0x8700 => { type => 0x001f, name => "PidLidLogType", guid => "0006200A-0000-0000-C000-000000000046" }, # Briefly describes the journal activity that is being recorded.
0x8706 => { type => 0x0040, name => "PidLidLogStart", guid => "0006200A-0000-0000-C000-000000000046" }, # Contains the time, in UTC, at which the activity began.
0x8707 => { type => 0x0003, name => "PidLidLogDuration", guid => "0006200A-0000-0000-C000-000000000046" }, # Contains the duration, in minutes, of the activity.
0x8708 => { type => 0x0040, name => "PidLidLogEnd", guid => "0006200A-0000-0000-C000-000000000046" }, # Contains the time, in UTC, at which the activity ended.
0x870c => { type => 0x0003, name => "PidLidLogFlags", guid => "0006200A-0000-0000-C000-000000000046" }, # Contains metadata about the Journal object.
0x870e => { type => 0x000b, name => "PidLidLogDocumentPrinted", guid => "0006200A-0000-0000-C000-000000000046" }, # Indicates whether the document was printed during journaling.
0x870f => { type => 0x000b, name => "PidLidLogDocumentSaved", guid => "0006200A-0000-0000-C000-000000000046" }, # Indicates whether the document was saved during journaling.
0x8710 => { type => 0x000b, name => "PidLidLogDocumentRouted", guid => "0006200A-0000-0000-C000-000000000046" }, # Indicates whether the document was sent to a routing recipient (1) during journaling.
0x8711 => { type => 0x000b, name => "PidLidLogDocumentPosted", guid => "0006200A-0000-0000-C000-000000000046" }, # Indicates whether the document was sent by e-mail or posted to a server folder during journaling.
0x8712 => { type => 0x001f, name => "PidLidLogTypeDesc", guid => "0006200A-0000-0000-C000-000000000046" }, # Contains an expanded description of the journal activity that is being recorded.
0x8900 => { type => 0x001f, name => "PidLidPostRssChannelLink", guid => "00062041-0000-0000-C000-000000000046" }, # Contains the URL of the RSS or Atom feed from which the XML file came.
0x8901 => { type => 0x001f, name => "PidLidPostRssItemLink", guid => "00062041-0000-0000-C000-000000000046" }, # Contains the URL of the link from an RSS or Atom item.
0x8902 => { type => 0x0003, name => "PidLidPostRssItemHash", guid => "00062041-0000-0000-C000-000000000046" }, # Contains a hash of the feed XML computed by using an implementation-dependent algorithm.
0x8903 => { type => 0x001f, name => "PidLidPostRssItemGuid", guid => "00062041-0000-0000-C000-000000000046" }, # Contains a unique identifier for the RSS object.
0x8904 => { type => 0x001f, name => "PidLidPostRssChannel", guid => "00062041-0000-0000-C000-000000000046" }, # Contains the contents of the title field from the XML of the Atom feed or RSS channel.
0x8905 => { type => 0x001f, name => "PidLidPostRssItemXml", guid => "00062041-0000-0000-C000-000000000046" }, # Contains the item element and all of its sub-elements from an RSS feed, or the entry element and all of its sub-elements from an Atom feed.
0x8906 => { type => 0x001f, name => "PidLidPostRssSubscription", guid => "00062041-0000-0000-C000-000000000046" }, # Contains the user's preferred name for the RSS or Atom subscription.
0x8a00 => { type => 0x0003, name => "PidLidSharingStatus", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a01 => { type => 0x0102, name => "PidLidSharingProviderGuid", guid => "00062040-0000-0000-C000-000000000046" }, # Contains the value "%xAE.F0.06.00.00.00.00.00.C0.00.00.00.00.00.00.46".
0x8a02 => { type => 0x001f, name => "PidLidSharingProviderName", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a03 => { type => 0x001f, name => "PidLidSharingProviderUrl", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a04 => { type => 0x001f, name => "PidLidSharingRemotePath", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a05 => { type => 0x001f, name => "PidLidSharingRemoteName", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a06 => { type => 0x001f, name => "PidLidSharingRemoteUid", guid => "00062040-0000-0000-C000-000000000046" }, # Contains the EntryID of the folder being shared.
0x8a07 => { type => 0x001f, name => "PidLidSharingInitiatorName", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a08 => { type => 0x001f, name => "PidLidSharingInitiatorSmtp", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a09 => { type => 0x0102, name => "PidLidSharingInitiatorEntryId", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a0a => { type => 0x0003, name => "PidLidSharingFlags", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a0b => { type => 0x001f, name => "PidLidSharingProviderExtension", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a0c => { type => 0x001f, name => "PidLidSharingRemoteUser", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a0d => { type => 0x001f, name => "PidLidSharingRemotePass", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a0e => { type => 0x001f, name => "PidLidSharingLocalPath", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a0f => { type => 0x001f, name => "PidLidSharingLocalName", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a10 => { type => 0x001f, name => "PidLidSharingLocalUid", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a13 => { type => 0x0102, name => "PidLidSharingFilter", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a14 => { type => 0x001f, name => "PidLidSharingLocalType", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a15 => { type => 0x0102, name => "PidLidSharingFolderEntryId", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a17 => { type => 0x0003, name => "PidLidSharingCapabilities", guid => "00062040-0000-0000-C000-000000000046" }, # Indicates that the Message object relates to a special folder.
0x8a18 => { type => 0x0003, name => "PidLidSharingFlavor", guid => "00062040-0000-0000-C000-000000000046" }, # Indicates the type of Sharing Message object.
0x8a19 => { type => 0x0003, name => "PidLidSharingAnonymity", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a1a => { type => 0x0003, name => "PidLidSharingReciprocation", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a1b => { type => 0x0003, name => "PidLidSharingPermissions", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a1c => { type => 0x0102, name => "PidLidSharingInstanceGuid", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a1d => { type => 0x001f, name => "PidLidSharingRemoteType", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a1e => { type => 0x001f, name => "PidLidSharingParticipants", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a1f => { type => 0x0040, name => "PidLidSharingLastSyncTime", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a21 => { type => 0x001f, name => "PidLidSharingExtensionXml", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a22 => { type => 0x0040, name => "PidLidSharingRemoteLastModificationTime", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a23 => { type => 0x0040, name => "PidLidSharingLocalLastModificationTime", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a24 => { type => 0x001f, name => "PidLidSharingConfigurationUrl", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a zero-length string.
0x8a25 => { type => 0x0040, name => "PidLidSharingStart", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a26 => { type => 0x0040, name => "PidLidSharingStop", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a27 => { type => 0x0003, name => "PidLidSharingResponseType", guid => "00062040-0000-0000-C000-000000000046" }, # Contains the type of response with which the recipient (1) of the sharing request responded.
0x8a28 => { type => 0x0040, name => "PidLidSharingResponseTime", guid => "00062040-0000-0000-C000-000000000046" }, # Contains the time at which the recipient (1) of the sharing request sent a sharing response.
0x8a29 => { type => 0x0102, name => "PidLidSharingOriginalMessageEntryId", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a2a => { type => 0x0003, name => "PidLidSharingSyncInterval", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a2b => { type => 0x0003, name => "PidLidSharingDetail", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a2c => { type => 0x0003, name => "PidLidSharingTimeToLive", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a2d => { type => 0x0102, name => "PidLidSharingBindingEntryId", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a2e => { type => 0x0102, name => "PidLidSharingIndexEntryId", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a2f => { type => 0x001f, name => "PidLidSharingRemoteComment", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a40 => { type => 0x0040, name => "PidLidSharingWorkingHoursStart", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a41 => { type => 0x0040, name => "PidLidSharingWorkingHoursEnd", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a42 => { type => 0x0003, name => "PidLidSharingWorkingHoursDays", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a43 => { type => 0x0000, name => "PidLidSharingWorkingHoursTimeZone", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a44 => { type => 0x0040, name => "PidLidSharingDataRangeStart", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a45 => { type => 0x0040, name => "PidLidSharingDataRangeEnd", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a46 => { type => 0x0003, name => "PidLidSharingRangeStart", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a47 => { type => 0x0003, name => "PidLidSharingRangeEnd", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a48 => { type => 0x001f, name => "PidLidSharingRemoteStoreUid", guid => "00062040-0000-0000-C000-000000000046" }, # 
0x8a49 => { type => 0x001f, name => "PidLidSharingLocalStoreUid", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a4b => { type => 0x0003, name => "PidLidSharingRemoteByteSize", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a4c => { type => 0x0003, name => "PidLidSharingRemoteCrc", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a4d => { type => 0x001f, name => "PidLidSharingLocalComment", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a4e => { type => 0x0003, name => "PidLidSharingRoamLog", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a4f => { type => 0x0003, name => "PidLidSharingRemoteMessageCount", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a51 => { type => 0x001f, name => "PidLidSharingBrowseUrl", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a55 => { type => 0x0040, name => "PidLidSharingLastAutoSyncTime", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a56 => { type => 0x0003, name => "PidLidSharingTimeToLiveAuto", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a5b => { type => 0x001f, name => "PidLidSharingRemoteVersion", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a5c => { type => 0x0102, name => "PidLidSharingParentBindingEntryId", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8a60 => { type => 0x0003, name => "PidLidSharingSyncFlags", guid => "00062040-0000-0000-C000-000000000046" }, # Contains a value that is ignored by the server no matter what value is generated by the client.
0x8b00 => { type => 0x0003, name => "PidLidNoteColor", guid => "0006200E-0000-0000-C000-000000000046" }, # Specifies the suggested background color of the Note object.
0x8b02 => { type => 0x0003, name => "PidLidNoteWidth", guid => "0006200E-0000-0000-C000-000000000046" }, # Specifies the width of the visible message window in pixels.
0x8b03 => { type => 0x0003, name => "PidLidNoteHeight", guid => "0006200E-0000-0000-C000-000000000046" }, # Specifies the height of the visible message window in pixels.
0x8b04 => { type => 0x0003, name => "PidLidNoteX", guid => "0006200E-0000-0000-C000-000000000046" }, # Specifies the distance, in pixels, from the left edge of the screen that a user interface displays a Note object.
0x8b05 => { type => 0x0003, name => "PidLidNoteY", guid => "0006200E-0000-0000-C000-000000000046" }, # Specifies the distance, in pixels, from the top edge of the screen that a user interface displays a Note object.
0x9000 => { type => 0x101f, name => "PidLidCategories", guid => "00020329-0000-0000-C000-000000000046" }, # Contains the array of text labels assigned to this Message object.


);

1;
