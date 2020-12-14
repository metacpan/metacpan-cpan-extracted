package Log::ger::UseJSONForDump;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-06'; # DATE
our $DIST = 'Log-ger-UseJSONForDump'; # DIST
our $VERSION = '0.003'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Log::ger ();

use Data::Clean::ForJSON;
use JSON::MaybeXS;

my @known_configs = qw(pretty);

my %default_configs = (
    pretty => 1,
    clean => 1,
);

my $cleanser = Data::Clean::ForJSON->get_cleanser;
my $json;

sub import {
    my ($pkg, %args) = @_;
    my %configs = %default_configs;
    for my $k (sort keys %args) {
        die unless grep { $k eq $_ } @known_configs;
        $configs{$k} = $args{$k};
    }

    $json = JSON::MaybeXS->new;
    $json->pretty($configs{pretty} ? 1:0);
    $json->binary(1);
    $json->allow_nonref(1);

    $Log::ger::_dumper = sub {
        my $data = $configs{clean} ? $cleanser->clone_and_clean($_[0]) : $_[0];
        $json->encode($data);
    };
}

1;
# ABSTRACT: Use JSON::MaybeXS to dump data structures (as JSON)

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::UseJSONForDump - Use JSON::MaybeXS to dump data structures (as JSON)

=head1 VERSION

This document describes version 0.003 of Log::ger::UseJSONForDump (from Perl distribution Log-ger-UseJSONForDump), released on 2020-06-06.

=head1 SYNOPSIS

 use Log::ger::UseJSONForDump;

To configure:

 use Log::ger::UseJSONForDump (clean=>0, pretty=>0);

=head1 DESCRIPTION

=head1 CONFIGURATION

=head2 pretty

=head2 clean

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-UseJSONForDump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-UseJSONForDump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-UseJSONForDump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<JSON::MaybeXS>

Other modules to set data dumper for Log::ger:

=over

=item * L<Log::ger::UseDataBahe>

=item * L<Log::ger::UseDataDump>

=item * L<Log::ger::UseDataDumpColor>

=item * L<Log::ger::UseDataDumpObjectAsString>

=item * L<Log::ger::UseDataDumpOptions>

=item * L<Log::ger::UseDataDumper>

=item * L<Log::ger::UseDataDumperCompact>

=item * L<Log::ger::UseDataPrinter>

=item * L<Log::ger::UseYAMLForDump>

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
