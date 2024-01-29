use strict;
use warnings;

use Test::More;
use Test::Exception;

use GDPR::IAB::TCFv2;

subtest "bitfield" => sub {
    subtest "valid tcf v2 consent string using bitfield" => sub {
        my $consent;

        my $tc_string =
          'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA';
        lives_ok {
            $consent = GDPR::IAB::TCFv2->Parse($tc_string);
        }
        'should not throw exception';

        isa_ok $consent, 'GDPR::IAB::TCFv2', 'gdpr iab tcf v2 consent';

        is $consent->tc_string, $tc_string,
          'should return the original tc string';

        is "${consent}", $tc_string,
          'should return the original tc string in string context';

        is $consent->version, 2, 'should return version 2';

        is $consent->created, 1228644257,
          'should return the creation epoch 07/12/2008';

        {
            my ( $seconds, $nanoseconds ) = $consent->created;
            is $seconds, 1228644257,
              'should return the creation epoch 07/12/2008 on list context';
            is $nanoseconds, 700000000,
              'should return the 700000000 nanoseconds of epoch on list context';
        }

        is $consent->last_updated, 1326215413,
          'should return the last update epoch 10/01/2012';

        {
            my ( $seconds, $nanoseconds ) = $consent->last_updated;
            is $seconds, 1326215413,
              'should return the last updated epoch 07/12/2008 on list context';
            is $nanoseconds, 400000000,
              'should return the 400000000 nanoseconds of epoch on list context';
        }

        is $consent->cmp_id, 21, 'should return the cmp id 21';

        is $consent->cmp_version, 7, 'should return the cmp version 7';

        is $consent->consent_screen, 2, 'should return the consent screen 2';

        is $consent->consent_language, "EN",
          'should return the consent language "EN"';

        is $consent->vendor_list_version, 23,
          'should return the vendor list version 23';

        is $consent->policy_version, 2,
          'should return the policy version 2';

        ok $consent->is_service_specific,
          'should return true for service specific';

        ok !$consent->use_non_standard_stacks,
          'should return false for use non standard stacks';

        ok !$consent->purpose_one_treatment,
          'should return false for use purpose one treatment';

        is $consent->publisher_country_code, "KM",
          'should return the publisher country code "KM"';

        is $consent->max_vendor_id_consent, 115,
          "max vendor id consent is 115";

        is $consent->max_vendor_id_legitimate_interest, 113,
          "max vendor id legitimate interest is 113";

        subtest "check purpose consent ids" => sub {
            plan tests => 24;

            my %allowed_purposes = map { $_ => 1 } ( 1, 3, 9, 10 );

            foreach my $id ( 1 .. 24 ) {
                is !!$consent->is_purpose_consent_allowed($id),
                  !!$allowed_purposes{$id},
                  "checking purpose id $id for consent";
            }
        };

        subtest "check purpose legitimate interest ids" => sub {
            plan tests => 24;

            my %allowed_purposes = map { $_ => 1 } ( 3, 4, 5, 8, 9, 10 );

            foreach my $id ( 1 .. 24 ) {
                is !!$consent->is_purpose_legitimate_interest_allowed($id),
                  !!$allowed_purposes{$id},
                  "checking purpose id $id for legitimate interest";
            }
        };

        subtest "check special feature opt in" => sub {
            plan tests => 12;

            my %special_feature_opt_in = (
                2 => 1,
            );

            foreach my $id ( 1 .. 12 ) {
                is !!$consent->is_special_feature_opt_in($id),
                  !!$special_feature_opt_in{$id},
                  "checking special feature id $id opt in";
            }
        };

        subtest "check vendor consent ids" => sub {
            plan tests => 120;

            my %allowed_vendors =
              map { $_ => 1 } (
                2, 3, 6, 7, 8, 10, 12, 13, 14, 15, 16, 21, 25, 27, 30, 31, 34,
                35,
                37, 38, 39, 42, 43, 49, 52, 54, 55, 56, 57, 59, 60, 63, 64, 65,
                66, 67, 68, 69, 73, 74, 76, 78, 83, 86, 87, 89, 90, 92, 96, 99,
                100, 106, 109, 110, 114, 115
              );

            foreach my $id ( 1 .. 120 ) {
                is !!$consent->vendor_consent($id),
                  !!$allowed_vendors{$id},
                  "checking vendor id $id for consent";
            }
        };

        subtest "check vendor legitimate interest ids" => sub {
            plan tests => 120;

            my %allowed_vendors =
              map { $_ => 1 }
              ( 1, 9, 26, 27, 30, 36, 37, 43, 86, 97, 110, 113 );

            foreach my $id ( 1 .. 120 ) {
                is !!$consent->vendor_legitimate_interest($id),
                  !!$allowed_vendors{$id},
                  "checking vendor id $id for legitimate interest";
            }
        };

        ok !$consent->check_publisher_restriction( 1, 0, 284 ),
          "should have no publisher restriction to vendor 284 regarding purpose id 1 of type 0 'Purpose Flatly Not Allowed by Publisher' when called with positional parameters";

        ok !$consent->check_publisher_restriction(
            purpose_id       => 1,
            restriction_type => 0, vendor_id => 284
          ),
          "should have no publisher restriction to vendor 284 regarding purpose id 1 of type 0 'Purpose Flatly Not Allowed by Publisher' when called with named parameters";

        my $restrictions = $consent->publisher_restrictions(284);
        is_deeply $restrictions, {},
          "should return the restriction purpose id => restriction map type map";

        my $publisher_tc = $consent->publisher_tc;

        ok !defined($publisher_tc), "should not return publisher_tc";

        done_testing;
    };


    subtest
      "valid tcf v2 consent string using bitfield with publisher TC section"
      => sub {

        subtest "without custom purposes" => sub {
            my $consent;

            my $tc_string =
              'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA';
            lives_ok {
                $consent = GDPR::IAB::TCFv2->Parse($tc_string);
            }
            'should not throw exception';

            isa_ok $consent, 'GDPR::IAB::TCFv2', 'gdpr iab tcf v2 consent';

            is $consent->tc_string, $tc_string,
              'should return the original tc string';

            is "${consent}", $tc_string,
              'should return the original tc string in string context';

            is $consent->version, 2, 'should return version 2';

            my $publisher_tc = $consent->publisher_tc;

            ok defined($publisher_tc), "should return publisher_tc";

            is $publisher_tc->num_custom_purposes, 0,
              "should not have any custom purposes";

            subtest "check publisher purpose consent ids" => sub {
                plan tests => 24;

                my %allowed_purposes = map { $_ => 1 } ( 2, 4, 6, 8, 9, 10 );

                foreach my $id ( 1 .. 24 ) {
                    is !!$publisher_tc->is_purpose_consent_allowed($id),
                      !!$allowed_purposes{$id},
                      "checking publisher purpose id $id for consent";
                }
            };

            subtest "check publisher purpose legitimate interest ids" => sub {
                plan tests => 24;

                my %allowed_purposes = map { $_ => 1 } ( 2, 4, 5, 7, 10 );

                foreach my $id ( 1 .. 24 ) {
                    is !!$publisher_tc
                      ->is_purpose_legitimate_interest_allowed($id),
                      !!$allowed_purposes{$id},
                      "checking publisher purpose id $id for legitimate interest";
                }
            };

            done_testing;
        };

        subtest "with custom purposes" => sub {
            my $consent;

            my $tc_string =
              'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.YAAAAAAAAXA';
            lives_ok {
                $consent = GDPR::IAB::TCFv2->Parse($tc_string);
            }
            'should not throw exception';

            isa_ok $consent, 'GDPR::IAB::TCFv2', 'gdpr iab tcf v2 consent';

            is $consent->tc_string, $tc_string,
              'should return the original tc string';

            is "${consent}", $tc_string,
              'should return the original tc string in string context';

            is $consent->version, 2, 'should return version 2';

            my $publisher_tc = $consent->publisher_tc;

            ok defined($publisher_tc), "should return publisher_tc";

            is $publisher_tc->num_custom_purposes, 2,
              "should have 2 custom purposes";

            subtest "check publisher purpose consent ids" => sub {
                plan tests => 24;

                my %allowed_purposes;

                foreach my $id ( 1 .. 24 ) {
                    is !!$publisher_tc->is_purpose_consent_allowed($id),
                      !!$allowed_purposes{$id},
                      "checking publisher purpose id $id for consent";
                }
            };

            subtest "check publisher purpose legitimate interest ids" => sub {
                plan tests => 24;

                my %allowed_purposes;

                foreach my $id ( 1 .. 24 ) {
                    is !!$publisher_tc
                      ->is_purpose_legitimate_interest_allowed($id),
                      !!$allowed_purposes{$id},
                      "checking publisher purpose id $id for legitimate interest";
                }
            };


            subtest "check publisher custom purpose consent ids" => sub {
                plan tests => 2;

                ok $publisher_tc->is_custom_purpose_consent_allowed(1),
                  "should have custom purpose 1 allowed";
                ok $publisher_tc->is_custom_purpose_consent_allowed(2),
                  "should have custom purpose 2 allowed";
            };

            subtest
              "check publisher custom purpose legitimate interest ids" => sub {
                plan tests => 2;

                ok $publisher_tc
                  ->is_custom_purpose_legitimate_interest_allowed(1),
                  "should have custom purpose 1 allowed";
                ok !$publisher_tc
                  ->is_custom_purpose_legitimate_interest_allowed(2),
                  "should not have custom purpose 2 allowed";
              };

            done_testing;
        };

        done_testing;
      };
    done_testing;

};

subtest "range" => sub {
    subtest "valid tcf v2 consent string using range" => sub {
        my $consent;

        my $tc_string =
          'COyfVVoOyfVVoADACHENAwCAAAAAAAAAAAAAE5QBgALgAqgD8AQACSwEygJyAnSAMABgAFkAgQCDASeAmYBOgAA';
        lives_ok {
            $consent = GDPR::IAB::TCFv2->Parse($tc_string);
        }
        'should not throw exception';

        isa_ok $consent, 'GDPR::IAB::TCFv2', 'gdpr iab tcf v2 consent';

        is $consent->tc_string, $tc_string,
          'should return the original tc string';

        is "${consent}", $tc_string,
          'should return the original tc string in string context';

        is $consent->version, 2, 'should return version 2';

        is $consent->created, 1587946020,
          'should return the creation epoch 27/04/2020 on scalar context';

        {
            my ( $seconds, $nanoseconds ) = $consent->created;
            is $seconds, 1587946020,
              'should return the creation epoch 27/04/2020 on list context';
            is $nanoseconds, 0,
              'should return the 0 nanoseconds of epoch on list context';
        }

        is $consent->last_updated, 1587946020,
          'should return the last update epoch 27/04/2020';

        {
            my ( $seconds, $nanoseconds ) = $consent->last_updated;
            is $seconds, 1587946020,
              'should return the last update epoch 27/04/2020 on list context';
            is $nanoseconds, 0,
              'should return the 0 nanoseconds of epoch on list context';
        }

        is $consent->cmp_id, 3, 'should return the cmp id 3';

        is $consent->cmp_version, 2, 'should return the cmp version 2';

        is $consent->consent_screen, 7, 'should return the consent screen 7';

        is $consent->consent_language, "EN",
          'should return the consent language "EN"';

        is $consent->vendor_list_version, 48,
          'should return the vendor list version 23';

        is $consent->policy_version, 2,
          'should return the policy version 2';

        ok !$consent->is_service_specific,
          'should return true for service specific';

        ok !$consent->use_non_standard_stacks,
          'should return false for use non standard stacks';

        ok !$consent->purpose_one_treatment,
          'should return false for use purpose one treatment';

        is $consent->publisher_country_code, "AA",
          'should return the publisher country code "AA"';

        is $consent->max_vendor_id_consent, 626,
          "max vendor id consent is 626";

        is $consent->max_vendor_id_legitimate_interest, 628,
          "max vendor id legitimate interest is 628";

        subtest "check purpose consent ids" => sub {
            plan tests => 24;

            foreach my $id ( 1 .. 24 ) {
                ok !$consent->is_purpose_consent_allowed($id),
                  "checking purpose id $id for consent";
            }
        };

        subtest "check purpose legitimate interest ids" => sub {
            plan tests => 24;

            foreach my $id ( 1 .. 24 ) {
                ok !$consent->is_purpose_legitimate_interest_allowed($id),
                  "checking purpose id $id for legitimate interest";
            }
        };

        subtest "check special feature opt in" => sub {
            plan tests => 12;

            foreach my $id ( 1 .. 12 ) {
                ok !$consent->is_special_feature_opt_in($id),
                  "checking special feature id $id opt in";
            }
        };

        subtest "check vendor consent ids" => sub {
            plan tests => 626;

            my %allowed_vendors =
              map { $_ => 1 } ( 23, 42, 126, 127, 128, 587, 613, 626 );

            foreach my $id ( 1 .. 626 ) {
                is !!$consent->vendor_consent($id),
                  !!$allowed_vendors{$id},
                  "checking vendor id $id for consent";
            }
        };

        subtest "check vendor legitimate interest ids" => sub {
            plan tests => 628;

            my %allowed_vendors =
              map { $_ => 1 } ( 24, 44, 129, 130, 131, 591, 614, 628 );

            foreach my $id ( 1 .. 628 ) {
                is !!$consent->vendor_legitimate_interest($id),
                  !!$allowed_vendors{$id},
                  "checking vendor id $id for legitimate interest";
            }
        };

        ok !$consent->check_publisher_restriction( 1, 0, 284 ),
          "should have no publisher restriction to vendor 284 regarding purpose id 1 of type 0 'Purpose Flatly Not Allowed by Publisher'";

        my $restrictions = $consent->publisher_restrictions(284);
        is_deeply $restrictions, {},
          "should return the restriction purpose id => restriction map type map";

        my $publisher_tc = $consent->publisher_tc;

        ok !defined($publisher_tc), "should not return publisher_tc";

        done_testing;
    };
    subtest
      "valid tcf v2 consent string using range and prefetch some vendor ids"
      => sub {
        my $consent;

        my $tc_string =
          'COyfVVoOyfVVoADACHENAwCAAAAAAAAAAAAAE5QBgALgAqgD8AQACSwEygJyAnSAMABgAFkAgQCDASeAmYBOgAA';
        lives_ok {
            $consent = GDPR::IAB::TCFv2->Parse(
                $tc_string,
                prefetch => [ 1, 20 .. 24, 284, 626, 268 ]
            );
        }
        'should not throw exception';

        isa_ok $consent, 'GDPR::IAB::TCFv2', 'gdpr iab tcf v2 consent';

        is $consent->tc_string, $tc_string,
          'should return the original tc string';

        is "${consent}", $tc_string,
          'should return the original tc string in string context';

        is $consent->version, 2, 'should return version 2';


        subtest "check vendor consent ids" => sub {
            plan tests => 626;

            my %allowed_vendors =
              map { $_ => 1 } ( 23, 42, 126, 127, 128, 587, 613, 626 );

            foreach my $id ( 1 .. 626 ) {
                is !!$consent->vendor_consent($id),
                  !!$allowed_vendors{$id},
                  "checking vendor id $id for consent";
            }
        };

        subtest "check vendor legitimate interest ids" => sub {
            plan tests => 628;

            my %allowed_vendors =
              map { $_ => 1 } ( 24, 44, 129, 130, 131, 591, 614, 628 );

            foreach my $id ( 1 .. 628 ) {
                is !!$consent->vendor_legitimate_interest($id),
                  !!$allowed_vendors{$id},
                  "checking vendor id $id for legitimate interest";
            }
        };

        ok !$consent->check_publisher_restriction( 1, 0, 284 ),
          "should have no publisher restriction to vendor 284 regarding purpose id 1 of type 0 'Purpose Flatly Not Allowed by Publisher'";

        my $restrictions = $consent->publisher_restrictions(284);
        is_deeply $restrictions, {},
          "should return the restriction purpose id => restriction map type map";

        done_testing;
      };
    done_testing;
};
subtest "check publisher restriction" => sub {
    subtest "check publisher restriction #1" => sub {
        my $consent;

        lives_ok {
            $consent = GDPR::IAB::TCFv2->Parse(
                'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA');
        }
        'should not throw exception';

        isa_ok $consent, 'GDPR::IAB::TCFv2', 'gdpr iab tcf v2 consent';

        is $consent->version, 2, 'should return version 2';

        ok !$consent->check_publisher_restriction( 1, 0, 284 ),
          "should have no publisher restriction to vendor 284 regarding purpose id 1 of type 0 'Purpose Flatly Not Allowed by Publisher'";

        ok $consent->check_publisher_restriction( 7, 1, 32 ),
          "must have publisher restriction to vendor 32 regarding purpose id 7 of type 1 'Require Consent'";

        ok !$consent->check_publisher_restriction( 7, 1, 7 ),
          "must have publisher restriction to vendor 7 regarding purpose id 7 of type 1 'Require Consent'";

        ok !$consent->check_publisher_restriction( 5, 1, 32 ),
          "must have publisher restriction to vendor 32 regarding purpose id 5 of type 1 'Require Consent'";

        my $restrictions = $consent->publisher_restrictions(284);
        is_deeply $restrictions, {},
          "should return the restriction purpose id => restriction map type map";

        $restrictions = $consent->publisher_restrictions(32);
        is_deeply $restrictions, { 7 => { 1 => 1 } },
          "should return the restriction purpose id => restriction map type map";

        done_testing;
    };

    subtest "check publisher restriction #2" => sub {
        my $consent;

        lives_ok {
            $consent = GDPR::IAB::TCFv2->Parse(
                'COxPe2TOxPe2TALABAENAPCgAAAAAAAAAAAAAFAAAAoAAA4IACACAIABgACAFA4ADACAAIygAGADwAQBIAIAIB0AEAEBSACACAA'
            );
        }
        'should not throw exception';

        isa_ok $consent, 'GDPR::IAB::TCFv2', 'gdpr iab tcf v2 consent';

        is $consent->version, 2, 'should return version 2';

        ok !$consent->purpose_one_treatment,
          'should have no purpose 1 treatment';

        ok !$consent->is_special_feature_opt_in(3),
          'should have no feature id 3 opt in';

        ok !$consent->check_publisher_restriction( 1, 0, 284 ),
          "should have no publisher restriction to vendor 284 regarding purpose id 1 of type 0 'Purpose Flatly Not Allowed by Publisher'";

        ok $consent->check_publisher_restriction( 1, 0, 32 ),
          "must have publisher restriction to vendor 32 regarding purpose id 1 of type 0 'Purpose Flatly Not Allowed by Publisher'";

        ok !$consent->check_publisher_restriction( 1, 1, 32 ),
          "should have no publisher restriction to vendor 32 regarding purpose id 1 of type 1 'Require Consent'";

        ok $consent->check_publisher_restriction( 2,  0, 32 );
        ok $consent->check_publisher_restriction( 2,  0, 5 );
        ok $consent->check_publisher_restriction( 2,  0, 11 );
        ok !$consent->check_publisher_restriction( 2, 0, 44 );
        ok !$consent->check_publisher_restriction( 2, 0, 500 );
        ok $consent->check_publisher_restriction( 2,  1, 32 );
        ok !$consent->check_publisher_restriction( 2, 1, 42 );

        my $restrictions = $consent->publisher_restrictions(284);
        is_deeply $restrictions, {},
          "should return the restriction purpose id => restriction map type map";

        $restrictions = $consent->publisher_restrictions(32);
        is_deeply $restrictions,
          { 1  => { 0 => 1 }, 2 => { 0 => 1, 1 => 1 }, 7 => { 0 => 1, 1 => 1 },
            10 => { 0 => 1, 1 => 1 }
          },
          "should return the restriction purpose id => restriction map type map";


        done_testing;
    };

    subtest "check publisher restriction #3 " => sub {
        my $consent;

        lives_ok {
            $consent = GDPR::IAB::TCFv2->Parse(
                'COzSDo9OzSDo9B9AAAENAiCAALAAAAAAAAAACOQAQCOAAAAA');
        }
        'should not throw exception';

        isa_ok $consent, 'GDPR::IAB::TCFv2', 'gdpr iab tcf v2 consent';

        is $consent->version, 2, 'should return version 2';

        ok !$consent->check_publisher_restriction( 1, 0, 284 ),
          "should have no publisher restriction to vendor 284 regarding purpose id 1 of type 0 'Purpose Flatly Not Allowed by Publisher'";

        my $restrictions = $consent->publisher_restrictions(284);
        is_deeply $restrictions, {},
          "should return the restriction purpose id => restriction map type map";

        done_testing;
    };

    done_testing;
};

subtest "invalid tcf consent string candidates" => sub {
    throws_ok {
        GDPR::IAB::TCFv2->Parse();
    }
    qr/missing gdpr consent string/,
      'undefined consent string should throw error';

    throws_ok {
        GDPR::IAB::TCFv2->Parse("");
    }
    qr/missing gdpr consent string/, 'empty consent string should throw error';

    lives_ok {
        my $consent = GDPR::IAB::TCFv2->Parse(
            "BOEFEAyOEFEAyAHABDENAI4AAAB9vABAASAAAAAAAAAA");

        is $consent->version, 1, "tcf v1";

    }
    'valid tcf v1 consent string should now throw error without strict flag';

    throws_ok {
        GDPR::IAB::TCFv2->Parse(
            "BOEFEAyOEFEAyAHABDENAI4AAAB9vABAASAAAAAAAAAA", strict => 1 );
    }
    qr/consent string is not tcf version 2/,
      'valid tcf v1 consent string should throw error with strict flag';

    throws_ok {
        GDPR::IAB::TCFv2->Parse("Clc");
    }
    qr/vendor consent strings are at least 29 bytes long/,
      'short (less than 29 bytes) tcf v2 consent string should throw error';

    lives_ok {
        my $consent = GDPR::IAB::TCFv2->Parse(
            "DOEFEAyOEFEAyAHABDENAI4AAAB9vABAASAAAAAAAAAA", strict => 0 );
        is $consent->version, 3, "tcf v3";
    }
    'possible tcf v3 consent string should not throw error without strict flag';

    throws_ok {
        GDPR::IAB::TCFv2->Parse(
            "DOEFEAyOEFEAyAHABDENAI4AAAB9vABAASAAAAAAAAAA", strict => 1 );
    }
    qr/consent string is not tcf version 2/,
      'possible tcf v3 consent string should throw error with strict flag';

    throws_ok {
        GDPR::IAB::TCFv2->Parse(
            "COyfVVoOyfVVoADACHENAwCAAAAAAAAAAAAAE5QBgALgAqgD8AQACSwEygJyAnSAMABgAFkAgQCDASeAmYBOgA!A"
        );
    }
    qr/invalid base64 format/,
      'string is not a base64 url encoded string';

    throws_ok {
        GDPR::IAB::TCFv2->Parse('COvcSpYOvcSpYC9AAAENAPCAAAAAAAAAAAAAAFAAAAA')
    }
    qr/index out of bounds on offset 256/,
      'this test uses a crafted consent uses bit field, declares 10 vendors and legitimate interest without required content';

    throws_ok {
        GDPR::IAB::TCFv2->Parse(
            'COvcSpYOvcSpYC9AAAENAPCAAAAAAAAAAAAAAFQBgAAgABAACAAEAAQAAgAA')
    }
    qr/index out of bounds on offset 360: can't read 1, only has: 360/,
      'this test uses a crafted consent uses range section, declares 10 vendors, 6 exceptions and legitimate interest without require';


    done_testing;
};

subtest "check if looks like tcf v2 consent string" => sub {
    ok GDPR::IAB::TCFv2::looksLikeIsConsentVersion2(
        "COyfVVoOyfVVoADACHENAwCAAAAAAAAAAAAAE5QBgALgAqgD8AQACSwEygJyAnSAMABgAFkAgQCDASeAmYBOgAA"
      ),
      "this valid consent string starts with literal 'C' so it looks like a tcf v2 consent string";

    ok GDPR::IAB::TCFv2::looksLikeIsConsentVersion2(
        "COyfVVoOyfVVoADACHENAwCAAAAAAAAAAAAAE5QBgALgAqgD8AQACSwEygJyAnSAMABgAFkAgQCDASeAmYBOgA!A"
      ),
      "this invalid consent string starts with literal 'C' so it looks like a tcf v2 consent string";

    ok !GDPR::IAB::TCFv2::looksLikeIsConsentVersion2(
        "BOEFEAyOEFEAyAHABDENAI4AAAB9vABAASAAAAAAAAAA"),
      "this tcf v1 consent string starts with literal 'B' so it does not looks like a tcf v2";

    ok !GDPR::IAB::TCFv2::looksLikeIsConsentVersion2(""),
      "empty consent string does not looks like a tcf v2";

    ok !GDPR::IAB::TCFv2::looksLikeIsConsentVersion2(),
      "no consent string does not looks like a tcf v2";

    done_testing;
};

done_testing;
