# DESCRIPTION

Registry System Testing (RST) ensures that a Registry Operator (RO) is able to
operate a generic Top-Level Domain in a stable and secure manner.

Every RO must demonstrate that it has established operations in accordance with
the applicable technical and operational criteria prior to (a) delegation into
the root zone of the Internet, (b) transition of the TLD between Registry
Service Providers (RSPs), and (c) introduction of certain registry services.

Version 2.0 of the RST system introduced a machine-readable representation of
the test specifications, allowing automated construction and execution of test
plans.

This module provides a way to interact with the RST test specs. It is used, for
example, to generate the [HTML
representation](https://icann.github.io/rst-test-specs/rst-test-specs.html).

# USAGE

The example below generates a list of all the test cases that will be executed
for the `StandardPreDelegationTest` test plan.

    use ICANN::RST;

    my $spec = ICANN::RST::Spec->new;

    my $plan = $spec->plan(q{StandardPreDelegationTest});

    foreach my $case ($plan->cases) {
        say $case->id;
    }

For more information, see [ICANN::RST::Spec](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3ASpec) which is the main entry point to
the test specifications.

# SEE ALSO

- [ICANN::RST::Base](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3ABase)
- [ICANN::RST::Case](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3ACase)
- [ICANN::RST::ChangeLog](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3AChangeLog)
- [ICANN::RST::DataProvider](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3ADataProvider)
- [ICANN::RST::DataProvider::Column](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3ADataProvider%3A%3AColumn)
- [ICANN::RST::Error](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3AError)
- [ICANN::RST::Graph](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3AGraph)
- [ICANN::RST::Input](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3AInput)
- [ICANN::RST::Plan](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3APlan)
- [ICANN::RST::Resource](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3AResource)
- [ICANN::RST::Spec](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3ASpec)
- [ICANN::RST::Suite](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3ASuite)
- [ICANN::RST::Text](https://metacpan.org/pod/ICANN%3A%3ARST%3A%3AText)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
