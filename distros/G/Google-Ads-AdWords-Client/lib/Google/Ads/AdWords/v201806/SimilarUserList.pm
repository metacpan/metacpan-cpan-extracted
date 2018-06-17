package Google::Ads::AdWords::v201806::SimilarUserList;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/rm/v201806' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201806::UserList);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %isReadOnly_of :ATTR(:get<isReadOnly>);
my %name_of :ATTR(:get<name>);
my %description_of :ATTR(:get<description>);
my %status_of :ATTR(:get<status>);
my %integrationCode_of :ATTR(:get<integrationCode>);
my %accessReason_of :ATTR(:get<accessReason>);
my %accountUserListStatus_of :ATTR(:get<accountUserListStatus>);
my %membershipLifeSpan_of :ATTR(:get<membershipLifeSpan>);
my %size_of :ATTR(:get<size>);
my %sizeRange_of :ATTR(:get<sizeRange>);
my %sizeForSearch_of :ATTR(:get<sizeForSearch>);
my %sizeRangeForSearch_of :ATTR(:get<sizeRangeForSearch>);
my %listType_of :ATTR(:get<listType>);
my %isEligibleForSearch_of :ATTR(:get<isEligibleForSearch>);
my %isEligibleForDisplay_of :ATTR(:get<isEligibleForDisplay>);
my %closingReason_of :ATTR(:get<closingReason>);
my %UserList__Type_of :ATTR(:get<UserList__Type>);
my %seedUserListId_of :ATTR(:get<seedUserListId>);
my %seedUserListName_of :ATTR(:get<seedUserListName>);
my %seedUserListDescription_of :ATTR(:get<seedUserListDescription>);
my %seedUserListStatus_of :ATTR(:get<seedUserListStatus>);
my %seedListSize_of :ATTR(:get<seedListSize>);

__PACKAGE__->_factory(
    [ qw(        id
        isReadOnly
        name
        description
        status
        integrationCode
        accessReason
        accountUserListStatus
        membershipLifeSpan
        size
        sizeRange
        sizeForSearch
        sizeRangeForSearch
        listType
        isEligibleForSearch
        isEligibleForDisplay
        closingReason
        UserList__Type
        seedUserListId
        seedUserListName
        seedUserListDescription
        seedUserListStatus
        seedListSize

    ) ],
    {
        'id' => \%id_of,
        'isReadOnly' => \%isReadOnly_of,
        'name' => \%name_of,
        'description' => \%description_of,
        'status' => \%status_of,
        'integrationCode' => \%integrationCode_of,
        'accessReason' => \%accessReason_of,
        'accountUserListStatus' => \%accountUserListStatus_of,
        'membershipLifeSpan' => \%membershipLifeSpan_of,
        'size' => \%size_of,
        'sizeRange' => \%sizeRange_of,
        'sizeForSearch' => \%sizeForSearch_of,
        'sizeRangeForSearch' => \%sizeRangeForSearch_of,
        'listType' => \%listType_of,
        'isEligibleForSearch' => \%isEligibleForSearch_of,
        'isEligibleForDisplay' => \%isEligibleForDisplay_of,
        'closingReason' => \%closingReason_of,
        'UserList__Type' => \%UserList__Type_of,
        'seedUserListId' => \%seedUserListId_of,
        'seedUserListName' => \%seedUserListName_of,
        'seedUserListDescription' => \%seedUserListDescription_of,
        'seedUserListStatus' => \%seedUserListStatus_of,
        'seedListSize' => \%seedListSize_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'isReadOnly' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'description' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'status' => 'Google::Ads::AdWords::v201806::UserListMembershipStatus',
        'integrationCode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'accessReason' => 'Google::Ads::AdWords::v201806::AccessReason',
        'accountUserListStatus' => 'Google::Ads::AdWords::v201806::AccountUserListStatus',
        'membershipLifeSpan' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'size' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'sizeRange' => 'Google::Ads::AdWords::v201806::SizeRange',
        'sizeForSearch' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'sizeRangeForSearch' => 'Google::Ads::AdWords::v201806::SizeRange',
        'listType' => 'Google::Ads::AdWords::v201806::UserListType',
        'isEligibleForSearch' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'isEligibleForDisplay' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'closingReason' => 'Google::Ads::AdWords::v201806::UserListClosingReason',
        'UserList__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'seedUserListId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'seedUserListName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'seedUserListDescription' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'seedUserListStatus' => 'Google::Ads::AdWords::v201806::UserListMembershipStatus',
        'seedListSize' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
    },
    {

        'id' => 'id',
        'isReadOnly' => 'isReadOnly',
        'name' => 'name',
        'description' => 'description',
        'status' => 'status',
        'integrationCode' => 'integrationCode',
        'accessReason' => 'accessReason',
        'accountUserListStatus' => 'accountUserListStatus',
        'membershipLifeSpan' => 'membershipLifeSpan',
        'size' => 'size',
        'sizeRange' => 'sizeRange',
        'sizeForSearch' => 'sizeForSearch',
        'sizeRangeForSearch' => 'sizeRangeForSearch',
        'listType' => 'listType',
        'isEligibleForSearch' => 'isEligibleForSearch',
        'isEligibleForDisplay' => 'isEligibleForDisplay',
        'closingReason' => 'closingReason',
        'UserList__Type' => 'UserList.Type',
        'seedUserListId' => 'seedUserListId',
        'seedUserListName' => 'seedUserListName',
        'seedUserListDescription' => 'seedUserListDescription',
        'seedUserListStatus' => 'seedUserListStatus',
        'seedListSize' => 'seedListSize',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201806::SimilarUserList

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
SimilarUserList from the namespace https://adwords.google.com/api/adwords/rm/v201806.

SimilarUserList is a list of users which are similar to users from another UserList. These lists are readonly and automatically created by google. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * seedUserListId


=item * seedUserListName


=item * seedUserListDescription


=item * seedUserListStatus


=item * seedListSize




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

