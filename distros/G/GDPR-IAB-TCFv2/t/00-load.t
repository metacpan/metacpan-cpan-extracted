use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('GDPR::IAB::TCFv2::Constants::Purpose');
    use_ok('GDPR::IAB::TCFv2::Constants::SpecialFeature');
    use_ok('GDPR::IAB::TCFv2::Constants::RestrictionType');
    use_ok('GDPR::IAB::TCFv2::BitUtils');
    use_ok('GDPR::IAB::TCFv2::BitField');
    use_ok('GDPR::IAB::TCFv2::Publisher');
    use_ok('GDPR::IAB::TCFv2::PublisherRestrictions');
    use_ok('GDPR::IAB::TCFv2::PublisherTC');
    use_ok('GDPR::IAB::TCFv2::RangeSection');
    use_ok('GDPR::IAB::TCFv2');
}

require_ok('GDPR::IAB::TCFv2::Constants::Purpose');
require_ok('GDPR::IAB::TCFv2::Constants::SpecialFeature');
require_ok('GDPR::IAB::TCFv2::Constants::RestrictionType');
require_ok 'GDPR::IAB::TCFv2::BitUtils';
require_ok 'GDPR::IAB::TCFv2::BitField';
require_ok('GDPR::IAB::TCFv2::Publisher');
require_ok('GDPR::IAB::TCFv2::PublisherRestrictions');
require_ok('GDPR::IAB::TCFv2::PublisherTC');
require_ok 'GDPR::IAB::TCFv2::RangeSection';
require_ok 'GDPR::IAB::TCFv2';

subtest "check interfaces" => sub {
    isa_ok 'GDPR::IAB::TCFv2::BitUtils',                   'Exporter';
    isa_ok 'GDPR::IAB::TCFv2::Constants::Purpose',         'Exporter';
    isa_ok 'GDPR::IAB::TCFv2::Constants::SpecialFeature',  'Exporter';
    isa_ok 'GDPR::IAB::TCFv2::Constants::RestrictionType', 'Exporter';

    my @role_base_methods    = qw<Parse TO_JSON>;
    my @role_decoder_methods = qw<contains>;


    can_ok 'GDPR::IAB::TCFv2::BitField', @role_base_methods,
      @role_decoder_methods;
    can_ok 'GDPR::IAB::TCFv2::RangeSection', @role_base_methods,
      @role_decoder_methods, qw<all>;

    can_ok 'GDPR::IAB::TCFv2::PublisherRestrictions', @role_base_methods,
      qw<check_restriction restrictions>;
    can_ok 'GDPR::IAB::TCFv2::Publisher', @role_base_methods,
      qw<check_restriction restrictions>;
    can_ok 'GDPR::IAB::TCFv2::PublisherTC', @role_base_methods,
      qw<num_custom_purposes
      is_purpose_consent_allowed
      is_purpose_legitimate_interest_allowed
      is_custom_purpose_consent_allowed
      is_custom_purpose_legitimate_interest_allowed>;

    done_testing;
};

diag("GDPR::IAB::TCFv2/$GDPR::IAB::TCFv2::VERSION");

done_testing;
