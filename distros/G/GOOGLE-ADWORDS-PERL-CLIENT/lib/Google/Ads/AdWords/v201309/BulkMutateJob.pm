package Google::Ads::AdWords::v201309::BulkMutateJob;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201309' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201309::Job);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(Google::Ads::SOAP::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %failureReason_of :ATTR(:get<failureReason>);
my %stats_of :ATTR(:get<stats>);
my %billingSummary_of :ATTR(:get<billingSummary>);
my %Job__Type_of :ATTR(:get<Job__Type>);
my %id_of :ATTR(:get<id>);
my %policy_of :ATTR(:get<policy>);
my %request_of :ATTR(:get<request>);
my %status_of :ATTR(:get<status>);
my %history_of :ATTR(:get<history>);
my %result_of :ATTR(:get<result>);
my %numRequestParts_of :ATTR(:get<numRequestParts>);
my %numRequestPartsReceived_of :ATTR(:get<numRequestPartsReceived>);

__PACKAGE__->_factory(
    [ qw(        failureReason
        stats
        billingSummary
        Job__Type
        id
        policy
        request
        status
        history
        result
        numRequestParts
        numRequestPartsReceived

    ) ],
    {
        'failureReason' => \%failureReason_of,
        'stats' => \%stats_of,
        'billingSummary' => \%billingSummary_of,
        'Job__Type' => \%Job__Type_of,
        'id' => \%id_of,
        'policy' => \%policy_of,
        'request' => \%request_of,
        'status' => \%status_of,
        'history' => \%history_of,
        'result' => \%result_of,
        'numRequestParts' => \%numRequestParts_of,
        'numRequestPartsReceived' => \%numRequestPartsReceived_of,
    },
    {
        'failureReason' => 'Google::Ads::AdWords::v201309::ApiErrorReason',
        'stats' => 'Google::Ads::AdWords::v201309::JobStats',
        'billingSummary' => 'Google::Ads::AdWords::v201309::BillingSummary',
        'Job__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'policy' => 'Google::Ads::AdWords::v201309::BulkMutateJobPolicy',
        'request' => 'Google::Ads::AdWords::v201309::BulkMutateRequest',
        'status' => 'Google::Ads::AdWords::v201309::BasicJobStatus',
        'history' => 'Google::Ads::AdWords::v201309::BulkMutateJobEvent',
        'result' => 'Google::Ads::AdWords::v201309::BulkMutateResult',
        'numRequestParts' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'numRequestPartsReceived' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
    },
    {

        'failureReason' => 'failureReason',
        'stats' => 'stats',
        'billingSummary' => 'billingSummary',
        'Job__Type' => 'Job.Type',
        'id' => 'id',
        'policy' => 'policy',
        'request' => 'request',
        'status' => 'status',
        'history' => 'history',
        'result' => 'result',
        'numRequestParts' => 'numRequestParts',
        'numRequestPartsReceived' => 'numRequestPartsReceived',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201309::BulkMutateJob

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
BulkMutateJob from the namespace https://adwords.google.com/api/adwords/cm/v201309.

A {@code BulkMutateJob} is essentially a mixed collection of mutate operations from the following AdWords API campaign management services: <ul> <li>{@link CampaignService}</li> <li>{@link CampaignTargetService}</li> <li>{@link CampaignCriterionService}</li> <li>{@link AdGroupService}</li> <li>{@link AdGroupAdService}</li> <li>{@link AdGroupCriterionService}</li> </ul> <p>The mutate operations in a job's request are constructed in exactly the same way as they are for synchronous calls to these services.</p> <p>The mutate operations are grouped by their scoping entity in the AdWords customer tree. Currently, mutate operations can be grouped either by the customer or by their parent campaign. However, they cannot be grouped both ways - some by customer and others by campaigns - in the same job.</p> <p class="note"><b>Note:</b> A job may have no more than 500,000 mutate operations in total, and no more than 10 different scoping campaigns.</p> <p>The mutate operations must be packaged into containers called {@code Operation Streams}, each tagged with the ID of the scoping entity of its operations.</p> <p>To facilitate the building of very large bulk mutate jobs, the operation streams of a job can be submitted using multiple request parts. A job is queued for processing as soon as it can be determined that all of its request parts have been received.</p> <p class="note"><b>Note:</b> A job may have no more than 100 request parts. Each part may have no more than 25 operation streams and no more than 10,000 operations in total.</p> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * id


=item * policy


=item * request


=item * status


=item * history


=item * result


=item * numRequestParts


=item * numRequestPartsReceived




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():






=head1 AUTHOR

Generated by SOAP::WSDL

=cut

