package Mail::BIMI::Role::Constants;
# ABSTRACT: Class to model defined constants
our $VERSION = '1.20200226'; # VERSION
use 5.20.0;
use Moo::Role;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;

sub BIMI_INVALID      { return 'Invalid BIMI Record' };
sub BIMI_NOT_ENABLED  { return 'Domain is not BIMI enabled' };
sub DNS_ERROR         { return 'DNS query error' };
sub DUPLICATE_KEY     { return 'Duplicate key in record' };
sub EMPTY_L_TAG       { return 'Empty l tag' };
sub EMPTY_V_TAG       { return 'Empty v tag' };
sub INVALID_TRANSPORT { return 'Invalid transport in locations' };
sub INVALID_V_TAG     { return 'Invalid v tag' };
sub MISSING_L_TAG     { return 'Missing l tag' };
sub MULTI_BIMI_RECORD { return 'multiple BIMI records found' };
sub NO_BIMI_RECORD    { return 'no BIMI records found' };
sub NO_DMARC          { return 'No DMARC' };
sub SPF_PLUS_ALL      { return 'SPF +all detected' };

1;
