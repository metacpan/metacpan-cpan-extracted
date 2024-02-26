package Dist::Zilla::Plugin::PERLANCAR::BeforeBuild;

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Module::Version 'get_version';

with (
    'Dist::Zilla::Role::BeforeBuild',
);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-16'; # DATE
our $DIST = 'Dist-Zilla-PluginBundle-Author-PERLANCAR'; # DIST
our $VERSION = '0.610'; # VERSION

sub before_build {
    my $self = shift;

    my %min_versions = (
        "CPAN::Meta::Prereqs" => "2.150006", # preserves x_* phases/rels
    );
    for (sort keys %min_versions) {
        my $min_v = $min_versions{$_};
        my $installed_v = get_version($_);
        if (version->parse($installed_v) < version->parse($min_v)) {
            die "$_ version must be >= $min_v";
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Do stuffs before building

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PERLANCAR::BeforeBuild - Do stuffs before building

=head1 VERSION

This document describes version 0.610 of Dist::Zilla::Plugin::PERLANCAR::BeforeBuild (from Perl distribution Dist-Zilla-PluginBundle-Author-PERLANCAR), released on 2023-11-16.

=head1 SYNOPSIS

In F<dist.ini>:

 [PERLANCAR::BeforeBuild]

=head1 DESCRIPTION

Currently what this does:

=over

=item * Ensure that the versions of some required modules are recent enough

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-PluginBundle-Author-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-PluginBundle-Author-PERLANCAR>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
