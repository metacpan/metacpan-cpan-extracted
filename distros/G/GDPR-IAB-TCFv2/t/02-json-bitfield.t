use strict;
use warnings;

use Test::More;

use GDPR::IAB::TCFv2;

# use JSON;
# use DateTime;
# use DateTimeX::TO_JSON formatter => 'DateTime::Format::RFC3339';

subtest "bitfield" => sub {
    subtest
      "should convert data to json using compact flag and 0/1 as booleans" =>
      sub {
        subtest "should convert data to json using yyyymmdd as date format" =>
          sub {
            my $consent = GDPR::IAB::TCFv2->Parse(
                'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA',
                json => {
                    verbose        => 0,
                    compact        => 1,
                    use_epoch      => 0,
                    boolean_values => [ 0, 1 ],
                    date_format    => '%Y%m%d',    # yyymmdd
                },
            );


            my $got      = $consent->TO_JSON();
            my $expected = _fixture_bitfield_compact(
                created      => 20081207,
                last_updated => 20120110,
            );
            is_deeply $got, $expected, "must return the json hashref";

            done_testing;
          };

        subtest "should convert data to json using epoch date format" => sub {
            my $consent = GDPR::IAB::TCFv2->Parse(
                'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA',
                json => {
                    verbose        => 0,
                    compact        => 1,
                    use_epoch      => 1,
                    boolean_values => [ 0, 1 ],
                },
            );


            my $got      = $consent->TO_JSON();
            my $expected = _fixture_bitfield_compact(
                created      => 1228644257,
                last_updated => 1326215413,
            );

            is_deeply $got, $expected, "must return the json hashref";

            done_testing;
        };

        done_testing;
      };

    subtest
      "should convert data to json using default (non-compact) and 0/1 as booleans"
      => sub {

        subtest "default non verbose, date as iso 8601" => sub {
            my $consent = GDPR::IAB::TCFv2->Parse(
                'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA',
                json => {
                    verbose        => 0,
                    compact        => 0,
                    use_epoch      => 0,
                    boolean_values => [ 0, 1 ],
                },
            );

            ok $consent->vendor_consent(27);

            my $got      = $consent->TO_JSON();
            my $expected = _fixture_bitfield_default();
            is_deeply $got, $expected, "must return the json hashref";

            done_testing;
        };

        subtest "default verbose, date as iso 8601" => sub {
            my $consent = GDPR::IAB::TCFv2->Parse(
                'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA',
                json => {
                    verbose        => 1,
                    compact        => 0,
                    use_epoch      => 0,
                    boolean_values => [ 0, 1 ],
                },
            );

            ok $consent->vendor_consent(27);

            my $got      = $consent->TO_JSON();
            my $expected = _fixture_bitfield_verbose();
            is_deeply $got, $expected, "must return the json hashref";

            done_testing;
        };

        done_testing;
      };

    subtest "publisher section" => sub {
        subtest "publisher section without publisher_tc" => sub {
            my $consent = GDPR::IAB::TCFv2->Parse(
                'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA',
                json => {
                    verbose        => 0,
                    compact        => 1,
                    use_epoch      => 0,
                    boolean_values => [ 0, 1 ],
                },
            );

            my $got = $consent->TO_JSON;
            my $expected =
              { "publisher" => { "restrictions" => { "7" => { "32" => 1 } } }
              };

            is_deeply $got->{publisher}, $expected->{publisher},
              "must return the same publisher restriction section";

            done_testing;
        };
        subtest "publisher section with publisher_tc" => sub {
            subtest "without custom purposes" => sub {
                my $consent = GDPR::IAB::TCFv2->Parse(
                    'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA.argAC0gAAAAAAAAAAAA',
                    json => {
                        verbose        => 0,
                        compact        => 1,
                        use_epoch      => 0,
                        boolean_values => [ 0, 1 ],
                    },
                );

                my $got      = $consent->TO_JSON;
                my $expected = {
                    "publisher" => {
                        "consents"             => [ 2, 4, 6, 8, 9, 10 ],
                        "legitimate_interests" => [ 2, 4, 5, 7, 10 ],
                        "custom_purposes"      => {
                            "consents"             => [],
                            "legitimate_interests" => [],
                        },
                        "restrictions" => { "7" => { "32" => 1 } }
                    }
                };

                is_deeply $got->{publisher}, $expected->{publisher},
                  "must return the same publisher restriction section";

                done_testing;
            };

            subtest "with custom purposes" => sub {
                my $consent = GDPR::IAB::TCFv2->Parse(
                    'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA.YAAAAAAAAXA',
                    json => {
                        verbose        => 0,
                        compact        => 1,
                        use_epoch      => 0,
                        boolean_values => [ 0, 1 ],
                    },
                );

                my $got      = $consent->TO_JSON;
                my $expected = {
                    "publisher" => {
                        "consents"             => [],
                        "legitimate_interests" => [],
                        "custom_purposes"      => {
                            "consents"             => [ 1, 2 ],
                            "legitimate_interests" => [1],
                        },
                        "restrictions" => { "7" => { "32" => 1 } }
                    }
                };

                is_deeply $got->{publisher}, $expected->{publisher},
                  "must return the same publisher restriction section";

                done_testing;
            };

            done_testing;
        };

        done_testing;
    };

    subtest "TO_JSON method should return the same hashref " => sub {
        my $consent = GDPR::IAB::TCFv2->Parse(
            'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA',
            json => {
                verbose        => 0,
                compact        => 1,
                use_epoch      => 0,
                boolean_values => [ 0, 1 ],
            },
        );


        my $got1 = $consent->TO_JSON();
        my $got2 = $consent->TO_JSON();

        is_deeply $got1, $got2, "must return the same hashref";

        done_testing;
    };

    done_testing;

};

done_testing;

sub _fixture_bitfield_compact {
    my (%extra) = @_;

    return {
        'special_features_opt_in' => [2],
        'use_non_standard_stacks' => 0,
        'last_updated'            => '2012-01-10T17:10:13Z',
        'policy_version'          => 2,
        'tc_string'               =>
          'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA',
        'version'             => 2,
        'consent_language'    => 'EN',
        'is_service_specific' => 1,
        'vendor'              => {
            'consents' => [
                2,
                3,
                6,
                7,
                8,
                10,
                12,
                13,
                14,
                15,
                16,
                21,
                25,
                27,
                30,
                31,
                34,
                35,
                37,
                38,
                39,
                42,
                43,
                49,
                52,
                54,
                55,
                56,
                57,
                59,
                60,
                63,
                64,
                65,
                66,
                67,
                68,
                69,
                73,
                74,
                76,
                78,
                83,
                86,
                87,
                89,
                90,
                92,
                96,
                99,
                100,
                106,
                109,
                110,
                114,
                115
            ],
            'legitimate_interests' => [
                1,
                9,
                26,
                27,
                30,
                36,
                37,
                43,
                86,
                97,
                110,
                113
            ],
        },
        'purpose' => {
            'consents' => [
                1,
                3,
                9,
                10
            ],
            'legitimate_interests' => [
                3,
                4,
                5,
                8,
                9,
                10
            ],
        },
        'cmp_id'                 => 21,
        'created'                => '2008-12-07T10:04:17Z',
        'purpose_one_treatment'  => 0,
        'consent_screen'         => 2,
        'vendor_list_version'    => 23,
        'cmp_version'            => 7,
        'publisher_country_code' => 'KM',
        'publisher'              => {
            'restrictions' => {},
        },

        %extra
    };
}

sub _fixture_bitfield_default {
    my (%extra) = @_;

    return {
        'tc_string' =>
          'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA',
        'consent_language' => 'EN',
        'purpose'          => {
            'consents' => {
                '1'  => 1,
                '3'  => 1,
                '9'  => 1,
                '10' => 1,
            },
            'legitimate_interests' => {
                '3'  => 1,
                '4'  => 1,
                '5'  => 1,
                '8'  => 1,
                '9'  => 1,
                '10' => 1,
            },
        },
        'vendor' => {
            'legitimate_interests' => {
                '1'   => 1,
                '9'   => 1,
                '26'  => 1,
                '27'  => 1,
                '30'  => 1,
                '36'  => 1,
                '37'  => 1,
                '43'  => 1,
                '86'  => 1,
                '97'  => 1,
                '110' => 1,
                '113' => 1,
            },
            'consents' => {
                '2'   => 1,
                '3'   => 1,
                '6'   => 1,
                '7'   => 1,
                '8'   => 1,
                '10'  => 1,
                '12'  => 1,
                '13'  => 1,
                '14'  => 1,
                '15'  => 1,
                '16'  => 1,
                '21'  => 1,
                '25'  => 1,
                '27'  => 1,
                '30'  => 1,
                '31'  => 1,
                '34'  => 1,
                '35'  => 1,
                '37'  => 1,
                '38'  => 1,
                '39'  => 1,
                '42'  => 1,
                '43'  => 1,
                '49'  => 1,
                '52'  => 1,
                '54'  => 1,
                '55'  => 1,
                '56'  => 1,
                '57'  => 1,
                '59'  => 1,
                '60'  => 1,
                '63'  => 1,
                '64'  => 1,
                '65'  => 1,
                '66'  => 1,
                '67'  => 1,
                '68'  => 1,
                '69'  => 1,
                '73'  => 1,
                '74'  => 1,
                '76'  => 1,
                '78'  => 1,
                '83'  => 1,
                '86'  => 1,
                '87'  => 1,
                '89'  => 1,
                '90'  => 1,
                '92'  => 1,
                '96'  => 1,
                '99'  => 1,
                '100' => 1,
                '106' => 1,
                '109' => 1,
                '110' => 1,
                '114' => 1,
                '115' => 1,
            },
        },
        'cmp_id'                  => 21,
        'purpose_one_treatment'   => 0,
        'special_features_opt_in' => { '2' => 1 },
        'last_updated'            => '2012-01-10T17:10:13Z',
        'use_non_standard_stacks' => 0,
        'policy_version'          => 2,
        'version'                 => 2,
        'is_service_specific'     => 1,
        'created'                 => '2008-12-07T10:04:17Z',
        'consent_screen'          => 2,
        'vendor_list_version'     => 23,
        'cmp_version'             => 7,
        'publisher_country_code'  => 'KM',
        'publisher'               => {
            'restrictions' => {},
        },

        %extra
    };
}

sub _fixture_bitfield_verbose {
    my (%extra) = @_;

    return {
        'tc_string' =>
          'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA',
        'consent_language' => 'EN',
        'purpose'          => {
            'consents' => {
                '11' => 0,
                '21' => 0,
                '7'  => 0,
                '17' => 0,
                '2'  => 0,
                '22' => 0,
                '1'  => 1,
                '18' => 0,
                '23' => 0,
                '16' => 0,
                '13' => 0,
                '6'  => 0,
                '3'  => 1,
                '9'  => 1,
                '12' => 0,
                '20' => 0,
                '14' => 0,
                '15' => 0,
                '8'  => 0,
                '4'  => 0,
                '24' => 0,
                '19' => 0,
                '10' => 1,
                '5'  => 0
            },
            'legitimate_interests' => {
                '11' => 0,
                '21' => 0,
                '7'  => 0,
                '17' => 0,
                '2'  => 0,
                '22' => 0,
                '1'  => 0,
                '18' => 0,
                '23' => 0,
                '16' => 0,
                '13' => 0,
                '6'  => 0,
                '3'  => 1,
                '9'  => 1,
                '12' => 0,
                '20' => 0,
                '14' => 0,
                '15' => 0,
                '8'  => 1,
                '4'  => 1,
                '24' => 0,
                '19' => 0,
                '10' => 1,
                '5'  => 1
            },
        },
        'vendor' => {
            'legitimate_interests' => {
                '33'  => 0,
                '32'  => 0,
                '90'  => 0,
                '63'  => 0,
                '21'  => 0,
                '71'  => 0,
                '102' => 0,
                '7'   => 0,
                '80'  => 0,
                '26'  => 1,
                '99'  => 0,
                '18'  => 0,
                '72'  => 0,
                '16'  => 0,
                '44'  => 0,
                '55'  => 0,
                '84'  => 0,
                '74'  => 0,
                '27'  => 1,
                '95'  => 0,
                '57'  => 0,
                '61'  => 0,
                '108' => 0,
                '20'  => 0,
                '109' => 0,
                '92'  => 0,
                '103' => 0,
                '89'  => 0,
                '10'  => 0,
                '31'  => 0,
                '113' => 1,
                '35'  => 0,
                '11'  => 0,
                '91'  => 0,
                '78'  => 0,
                '107' => 0,
                '48'  => 0,
                '87'  => 0,
                '93'  => 0,
                '77'  => 0,
                '106' => 0,
                '65'  => 0,
                '29'  => 0,
                '50'  => 0,
                '39'  => 0,
                '64'  => 0,
                '97'  => 1,
                '58'  => 0,
                '41'  => 0,
                '12'  => 0,
                '15'  => 0,
                '81'  => 0,
                '52'  => 0,
                '60'  => 0,
                '56'  => 0,
                '101' => 0,
                '73'  => 0,
                '66'  => 0,
                '45'  => 0,
                '86'  => 1,
                '76'  => 0,
                '19'  => 0,
                '62'  => 0,
                '54'  => 0,
                '67'  => 0,
                '70'  => 0,
                '68'  => 0,
                '2'   => 0,
                '17'  => 0,
                '1'   => 1,
                '88'  => 0,
                '30'  => 1,
                '100' => 0,
                '110' => 1,
                '82'  => 0,
                '25'  => 0,
                '28'  => 0,
                '83'  => 0,
                '75'  => 0,
                '40'  => 0,
                '14'  => 0,
                '112' => 0,
                '69'  => 0,
                '59'  => 0,
                '49'  => 0,
                '24'  => 0,
                '104' => 0,
                '53'  => 0,
                '79'  => 0,
                '22'  => 0,
                '42'  => 0,
                '46'  => 0,
                '23'  => 0,
                '13'  => 0,
                '105' => 0,
                '96'  => 0,
                '6'   => 0,
                '85'  => 0,
                '3'   => 0,
                '36'  => 1,
                '94'  => 0,
                '111' => 0,
                '9'   => 1,
                '51'  => 0,
                '47'  => 0,
                '8'   => 0,
                '38'  => 0,
                '98'  => 0,
                '4'   => 0,
                '34'  => 0,
                '37'  => 1,
                '43'  => 1,
                '5'   => 0
            },
            'consents' => {
                '33'  => 0,
                '32'  => 0,
                '90'  => 1,
                '63'  => 1,
                '21'  => 1,
                '71'  => 0,
                '102' => 0,
                '7'   => 1,
                '80'  => 0,
                '26'  => 0,
                '99'  => 1,
                '18'  => 0,
                '72'  => 0,
                '16'  => 1,
                '44'  => 0,
                '55'  => 1,
                '84'  => 0,
                '74'  => 1,
                '27'  => 1,
                '95'  => 0,
                '57'  => 1,
                '61'  => 0,
                '108' => 0,
                '115' => 1,
                '20'  => 0,
                '109' => 1,
                '92'  => 1,
                '103' => 0,
                '89'  => 1,
                '10'  => 1,
                '31'  => 1,
                '113' => 0,
                '35'  => 1,
                '11'  => 0,
                '91'  => 0,
                '78'  => 1,
                '107' => 0,
                '48'  => 0,
                '87'  => 1,
                '93'  => 0,
                '77'  => 0,
                '106' => 1,
                '65'  => 1,
                '29'  => 0,
                '50'  => 0,
                '39'  => 1,
                '64'  => 1,
                '97'  => 0,
                '114' => 1,
                '58'  => 0,
                '41'  => 0,
                '12'  => 1,
                '15'  => 1,
                '81'  => 0,
                '52'  => 1,
                '60'  => 1,
                '56'  => 1,
                '101' => 0,
                '73'  => 1,
                '66'  => 1,
                '45'  => 0,
                '86'  => 1,
                '76'  => 1,
                '19'  => 0,
                '62'  => 0,
                '54'  => 1,
                '67'  => 1,
                '70'  => 0,
                '68'  => 1,
                '2'   => 1,
                '17'  => 0,
                '1'   => 0,
                '88'  => 0,
                '30'  => 1,
                '100' => 1,
                '110' => 1,
                '82'  => 0,
                '25'  => 1,
                '28'  => 0,
                '83'  => 1,
                '75'  => 0,
                '40'  => 0,
                '14'  => 1,
                '112' => 0,
                '69'  => 1,
                '59'  => 1,
                '49'  => 1,
                '24'  => 0,
                '104' => 0,
                '53'  => 0,
                '79'  => 0,
                '22'  => 0,
                '42'  => 1,
                '46'  => 0,
                '23'  => 0,
                '13'  => 1,
                '105' => 0,
                '96'  => 1,
                '6'   => 1,
                '85'  => 0,
                '3'   => 1,
                '36'  => 0,
                '94'  => 0,
                '111' => 0,
                '9'   => 0,
                '51'  => 0,
                '47'  => 0,
                '8'   => 1,
                '38'  => 1,
                '98'  => 0,
                '4'   => 0,
                '34'  => 1,
                '37'  => 1,
                '43'  => 1,
                '5'   => 0
            },
        },
        'cmp_id'                  => 21,
        'purpose_one_treatment'   => 0,
        'special_features_opt_in' => {
            '6'  => 0,
            '11' => 0,
            '3'  => 0,
            '7'  => 0,
            '9'  => 0,
            '12' => 0,
            '2'  => 1,
            '8'  => 0,
            '1'  => 0,
            '4'  => 0,
            '10' => 0,
            '5'  => 0
        },
        'last_updated'            => '2012-01-10T17:10:13Z',
        'use_non_standard_stacks' => 0,
        'policy_version'          => 2,
        'version'                 => 2,
        'is_service_specific'     => 1,
        'created'                 => '2008-12-07T10:04:17Z',
        'consent_screen'          => 2,
        'vendor_list_version'     => 23,
        'cmp_version'             => 7,
        'publisher_country_code'  => 'KM',
        'publisher'               => {
            'restrictions' => {},
        },

        %extra
    };
}
