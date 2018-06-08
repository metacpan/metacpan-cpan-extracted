package Dist::Zilla::Plugin::Prereqs::EnsureVersion;

our $DATE = '2018-06-07'; # DATE
our $VERSION = '0.050'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::AfterBuild';

use namespace::autoclean;

use Config::IOD::Reader;
use File::HomeDir;
use PMVersions::Util qw(version_from_pmversions);

sub after_build {
    my ($self) = @_;

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;

    for my $phase (sort keys %$prereqs_hash) {
        next if $phase =~ /^x_/;
        for my $rel (sort keys %{$prereqs_hash->{$phase}}) {
            next if $rel =~ /^x_/;
            my $versions = $prereqs_hash->{$phase}{$rel};
            for my $mod (sort keys %$versions) {
                my $ver = $versions->{$mod};
                my $minver = version_from_pmversions($mod);
                next unless defined $minver;
                if (version->parse($minver) > version->parse($ver)) {
                    $self->log_fatal([
                        "Prerequisite %s is below minimum version (%s vs %s)",
                        $mod, $ver, $minver]);
                }
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Make sure that prereqs have minimum versions

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::EnsureVersion - Make sure that prereqs have minimum versions

=head1 VERSION

This document describes version 0.050 of Dist::Zilla::Plugin::Prereqs::EnsureVersion (from Perl distribution Dist-Zilla-Plugin-Prereqs-EnsureVersion), released on 2018-06-07.

=head1 SYNOPSIS

In F<~/pmversions.ini>:

 Log::ger=0.019
 File::Write::Rotate=0.28

In F<dist.ini>:

 [Prereqs::EnsureVersion]

=head1 DESCRIPTION

This plugin will check versions specified in prereqs. First you create
F<~/pmversions.ini> containing list of modules and their mininum versions. Then,
the plugin will check all prereqs against this list. If minimum version is not
met (e.g. the prereq says 0 or a smaller version) then the build will be
aborted.

Currently, prereqs with custom (/^x_/) phase or relationship are ignored.

Ideas for future version: ability to blacklist certain versions, specify version
ranges, e.g.:

 Module::Name = 1.00-2.00, != 1.93

=for Pod::Coverage .+

=head1 ENVIRONMENT

=head2 PMVERSIONS_PATH

String. Set location of F<pmversions.ini> instead of the default
C<~/pmversions.ini>. Example: C</etc/minver.conf>. Note that this is actually
observed by in L<PMVersions::Util>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Prereqs-EnsureVersion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Prereqs-EnsureVersion>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Prereqs-EnsureVersion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::MinimumPrereqs>

There are some plugins on CPAN related to specifying/detecting Perl's minimum
version, e.g.: L<Dist::Zilla::Plugin::MinimumPerl>,
L<Dist::Zilla::Plugin::Test::MinimumVersion>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
