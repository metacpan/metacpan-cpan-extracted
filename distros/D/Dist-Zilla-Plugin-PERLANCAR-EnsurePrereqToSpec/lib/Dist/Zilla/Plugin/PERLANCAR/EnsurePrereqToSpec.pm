package Dist::Zilla::Plugin::PERLANCAR::EnsurePrereqToSpec;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-09'; # DATE
our $DIST = 'Dist-Zilla-Plugin-PERLANCAR-EnsurePrereqToSpec'; # DIST
our $VERSION = '0.061'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::Rinci::CheckDefinesMeta',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

sub _prereq_check {
    my ($self, $prereqs_hash, $mod, $wanted_phase, $wanted_rel) = @_;

    #use DD; dd $prereqs_hash;

    my $num_any = 0;
    my $num_wanted = 0;
    for my $phase (keys %$prereqs_hash) {
        for my $rel (keys %{ $prereqs_hash->{$phase} }) {
            if (exists $prereqs_hash->{$phase}{$rel}{$mod}) {
                $num_any++;
                $num_wanted++ if $phase eq $wanted_phase && $rel eq $wanted_rel;
            }
        }
    }
    ($num_any, $num_wanted);
}

sub _prereq_only_in {
    my ($self, $prereqs_hash, $mod, $wanted_phase, $wanted_rel) = @_;

    my ($num_any, $num_wanted) = $self->_prereq_check(
        $prereqs_hash, $mod, $wanted_phase, $wanted_rel,
    );
    $num_wanted == 1 && $num_any == 1;
}

sub _has_prereq {
    my ($self, $prereqs_hash, $mod, $wanted_phase, $wanted_rel) = @_;

    my ($num_any, $num_wanted) = $self->_prereq_check(
        $prereqs_hash, $mod, $wanted_phase, $wanted_rel,
    );
    $num_wanted == 1;
}

sub _prereq_none {
    my ($self, $prereqs_hash, $mod) = @_;

    my ($num_any, $num_wanted) = $self->_prereq_check(
        $prereqs_hash, $mod, 'whatever', 'whatever',
    );
    $num_any == 0;
}

sub after_build {
    my $self = shift;

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;

    # Rinci
    if ($self->check_dist_defines_rinci_meta || -f ".tag-implements-Rinci") {
        $self->log_fatal(["Dist defines Rinci metadata or implements Rinci, but there is no prereq phase=develop rel=x_spec to Rinci"])
            unless $self->_prereq_only_in($prereqs_hash, "Rinci", "develop", "x_spec");
    } else {
        $self->log_fatal(["Dist does not define Rinci metadata, but there is a phase=develop rel=xpec prereq to Rinci"])
            if $self->_has_prereq($prereqs_hash, "Rinci", "develop", "x_spec");
    }

    # ColorTheme
    if (grep { $_->name =~ m!(?:\A|/)ColorTheme/.+\.pm! } @{ $self->found_files }) {
        $self->log_fatal(["Dist has ColorThemes/* .pm file but there is no prereq phase=develop, rel=x_spec to ColorTheme"])
            unless $self->_prereq_only_in($prereqs_hash, "ColorTheme", "develop", "x_spec");
    }

}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Ensure prereq to spec modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PERLANCAR::EnsurePrereqToSpec - Ensure prereq to spec modules

=head1 VERSION

This document describes version 0.061 of Dist::Zilla::Plugin::PERLANCAR::EnsurePrereqToSpec (from Perl distribution Dist-Zilla-Plugin-PERLANCAR-EnsurePrereqToSpec), released on 2020-06-09.

=head1 SYNOPSIS

In C<dist.ini>:

 [PERLANCAR::EnsurePrereqToSpec]

=head1 DESCRIPTION

I like to specify prerequisite to spec modules such as L<Rinci>, L<Riap>,
L<Sah>, L<Setup>, etc as (phase=develop, rel=x_spec) dependency, to express that
a distribution conforms to such specification(s).

Currently only these spec is checked:

=over

=item * L<Rinci>

When a package contains Rinci metadata (C<%SPEC>).

=item * L<ColorTheme>

When there is a ColorTheme/* source files.

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-PERLANCAR-EnsurePrereqToSpec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-PERLANCAR-EnsurePrereqToSpec>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PERLANCAR-EnsurePrereqToSpec>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
