use Test::More;

use Error ':try';
use Mail::SPF;
use Net::DNS::Resolver::Programmable;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

$Error::Debug = TRUE;

sub run_spf_test_suite_file {
    my ($file_name, $test_case_overrides) = @_;
    $test_case_overrides ||= {};

    #### Load Test Suite Data and Plan Tests ####

    my $test_suite = Mail::SPF::Test->new_from_yaml_file($file_name);

    defined($test_suite)
        or BAIL_OUT("Unable to load test-suite data from file '$file_name'");

    my $total_test_cases_count  = 0;
    $total_test_cases_count += scalar($_->test_cases) foreach $test_suite->scenarios;

    plan(tests => $total_test_cases_count * 2);

    #### Perform Tests ####

    foreach my $scenario ($test_suite->scenarios) {
        my $server = Mail::SPF::Server->new(
            dns_resolver            => Net::DNS::Resolver::Programmable->new(
                resolver_code           => sub {
                    my ($domain, $rr_type) = @_;
                    my $rcode = 'NOERROR';
                    my @rrs;
                    push(@rrs, $scenario->records_for_domain($domain, $rr_type));
                    push(@rrs, $scenario->records_for_domain($domain, 'CNAME'))
                        if not @rrs and $rr_type ne 'CNAME';
                    if (@rrs == 0) {
                        $rcode = 'NXDOMAIN';
                    }
                    elsif ($rrs[0] eq 'TIMEOUT') {
                        return 'query timed out';
                    }
                    return ($rcode, undef, @rrs);
                }
            ),
            default_authority_explanation
                                    => 'DEFAULT',
            max_void_dns_lookups    => undef  # Be RFC 4408 compliant during testing!
        );

        foreach my $test_case ($scenario->test_cases) { SKIP: {
            my $test_base_name = sprintf("Test case '%s'", $test_case->name);

            if (defined(my $test_case_override = $test_case_overrides->{$test_case->name})) {
                if ($test_case_override =~ /^SKIP(?:: (.*))/) {
                    skip(
                        "Skipping test '" . $test_case->name . "' due to override" .
                        (defined($1) ? " ($1)" : ""),
                        2
                    );
                }
            }

            my $request = Mail::SPF::Request->new(
                scope           => $test_case->scope,
                identity        => $test_case->identity,
                ip_address      => $test_case->ip_address,
                helo_identity   => $test_case->helo_identity
            );
            my $result;
            try {
                $result = $server->process($request);
            }
            catch Error with {
                BAIL_OUT("Uncaught error: " . shift->stacktrace);
            };

            my $overall_ok = TRUE;

            # Test result code:
            my $result_is_ok = $test_case->is_expected_result($result->code);
            diag(
                "$test_base_name result:\n" .
                "Expected: " . join(' or ', map("'$_'", $test_case->expected_results)) . "\n" .
                "     Got: " . "'" . $result->code . "'"
            )
                if not $result_is_ok;
            $overall_ok &&= ok($result_is_ok, "$test_base_name result");

            # Test explanation:
            if (not $result->is_code('fail')) {
                pass("$test_base_name explanation not applicable");
            }
            elsif (not defined($test_case->expected_explanation)) {
                pass("$test_base_name explanation not relevant");
            }
            else {
                $overall_ok &&= is(
                    lc($result->authority_explanation),
                    lc($test_case->expected_explanation),
                    "$test_base_name explanation"
                );
            }

            diag("Test case description: " . $test_case->description)
                if not $overall_ok and defined($test_case->description);
        } }
    }

    return;
}

TRUE;
