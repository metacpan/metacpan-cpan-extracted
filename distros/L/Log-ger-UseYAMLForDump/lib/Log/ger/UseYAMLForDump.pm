package Log::ger::UseYAMLForDump;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-14'; # DATE
our $DIST = 'Log-ger-UseYAMLForDump'; # DIST
our $VERSION = '0.002'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Log::ger ();

use YAML::PP;

my @known_configs = qw();

my %default_configs = (
);

sub import {
    my ($pkg, %args) = @_;
    my %configs = %default_configs;
    for my $k (sort keys %args) {
        die unless grep { $k eq $_ } @known_configs;
        $configs{$k} = $args{$k};
    }

    $Log::ger::_dumper = \&YAML::PP::Dump;
}

1;
# ABSTRACT: Use YAML::PP to dump data structures (as YAML)

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::UseYAMLForDump - Use YAML::PP to dump data structures (as YAML)

=head1 VERSION

This document describes version 0.002 of Log::ger::UseYAMLForDump (from Perl distribution Log-ger-UseYAMLForDump), released on 2020-12-14.

=head1 SYNOPSIS

 use Log::ger::UseYAMLForDump;

=head1 DESCRIPTION

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-UseYAMLForDump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-UseYAMLForDump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Log-ger-UseYAMLForDump/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<YAML::PP>

Other modules to set data dumper for Log::ger:

=over

=item * L<Log::ger::UseBaheForDump>

=item * L<Log::ger::UseDataDump>

=item * L<Log::ger::UseDataDumpColor>

=item * L<Log::ger::UseDataDumpObjectAsString>

=item * L<Log::ger::UseDataDumpOptions>

=item * L<Log::ger::UseDataDumper>

=item * L<Log::ger::UseDataDumperCompact>

=item * L<Log::ger::UseDataPrinter>

=item * L<Log::ger::UseJSONForDump>

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
