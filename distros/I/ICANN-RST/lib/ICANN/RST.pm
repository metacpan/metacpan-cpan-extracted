package ICANN::RST;
# ABSTRACT: a module for interacting with the Registry System Testing (RST) test specifications.
use ICANN::RST::Spec;
use common::sense;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST - a module for interacting with the Registry System Testing (RST) test specifications.

=head1 VERSION

version 0.03

=head1 DESCRIPTION

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
example, to generate the L<HTML
representation|https://icann.github.io/rst-test-specs/rst-test-specs.html>.

=head1 USAGE

The example below generates a list of all the test cases that will be executed
for the C<StandardPreDelegationTest> test plan.

    use ICANN::RST;

    my $spec = ICANN::RST::Spec->new;

    my $plan = $spec->plan(q{StandardPreDelegationTest});

    foreach my $case ($plan->cases) {
        say $case->id;
    }

For more information, see L<ICANN::RST::Spec> which is the main entry point to
the test specifications.

=head1 SEE ALSO

=over

=item * L<ICANN::RST::Base>

=item * L<ICANN::RST::Case>

=item * L<ICANN::RST::ChangeLog>

=item * L<ICANN::RST::DataProvider>

=item * L<ICANN::RST::DataProvider::Column>

=item * L<ICANN::RST::Error>

=item * L<ICANN::RST::Graph>

=item * L<ICANN::RST::Input>

=item * L<ICANN::RST::Plan>

=item * L<ICANN::RST::Resource>

=item * L<ICANN::RST::Spec>

=item * L<ICANN::RST::Suite>

=item * L<ICANN::RST::Text>

=back

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
