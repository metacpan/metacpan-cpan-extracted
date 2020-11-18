package Log::ger::Output::Test::Counter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-17'; # DATE
our $DIST = 'Log-ger-Output-Test-Counter'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    if (defined $plugin_conf{counter_get_hooks}) {
        ${ $plugin_conf{counter_get_hooks} }++;
    }

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    if (defined $plugin_conf{counter_outputter}) {
                        ${ $plugin_conf{counter_outputter} }++;
                    }
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Increase internal counter

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Test::Counter - Increase internal counter

=head1 VERSION

This document describes version 0.001 of Log::ger::Output::Test::Counter (from Perl distribution Log-ger-Output-Test-Counter), released on 2020-11-17.

=head1 SYNOPSIS

 BEGIN { our $counter_get_hooks; our $counter_outputter }
 use Log::ger::Output "Test::Counter" => (
     counter_get_hooks => \$counter_get_hooks,
     counter_outputter => \$counter_outputter,
 );

=head1 DESCRIPTION

This output is for testing only. Instead of actually outputting something, it
increases counters.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 counter_get_hooks

Reference to scalar. Will be increased whenever C<get_hooks> is called.

=head2 counter_outputter

Reference to scalar. Will be increased whenever outputter is called.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Output-Test-Counter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Output-Test-Counter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Output-Test-Counter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
