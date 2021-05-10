package Dist::Zilla::Plugin::BorderStyle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-23'; # DATE
our $DIST = 'Dist-Zilla-Plugin-BorderStyle'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Moose;

#use PMVersions::Util qw(version_from_pmversions);
use Require::Hook::Source::DzilBuild;

with (
    'Dist::Zilla::Role::CheckPackageDeclared',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
    #'Dist::Zilla::Role::RequireFromBuild',
);

has exclude_module => (is => 'rw');

use namespace::autoclean;

sub mvp_multivalue_args { qw(exclude_module) }

sub _load_borderstyle_modules {
    my $self = shift;

    return $self->{_our_borderstyle_modules} if $self->{_loaded_borderstyle_modules}++;

    local @INC = (Require::Hook::Source::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

    my %res;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!^lib/((?:.*/)?BorderStyle/.+\.pm)$!;

        my $pkg_pm = $1;
        (my $pkg = $pkg_pm) =~ s/\.pm$//; $pkg =~ s!/!::!g;

        if ($self->exclude_module && grep { $pkg eq $_ } @{ $self->exclude_module }) {
            $self->log_debug(["BorderStyle module %s excluded", $pkg]);
            next;
        }

        $self->log_debug(["Loading border style module %s ...", $pkg_pm]);
        delete $INC{$pkg_pm};
        require $pkg_pm;
        $res{$pkg} = $file;
    }

    $self->{_our_borderstyle_modules} = \%res;
}

sub _load_borderstyles_modules {
    my $self = shift;

    return $self->{_our_borderstyles_modules} if $self->{_loaded_borderstyle_modules}++;

    local @INC = (Require::Hook::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

    my %res;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!^lib/((?:.*/)?BorderStyle/.+\.pm)$!;
        my $pkg_pm = $1;
        (my $pkg = $pkg_pm) =~ s/\.pm$//; $pkg =~ s!/!::!g;
        require $pkg_pm;
        $res{$pkg} = $file;
    }

    $self->{_our_borderstyles_modules} = \%res;
}

sub munge_files {
    no strict 'refs';

    my $self = shift;

    $self->{_used_borderstyle_modules} //= {};

    $self->_load_borderstyle_modules;
    $self->_load_borderstyles_modules;

  BORDERSTYLES_MODULE:
    for my $pkg (sort keys %{ $self->{_our_borderstyles_modules} }) {
        # ...
    }

  BORDERSTYLE_MODULE:
    for my $pkg (sort keys %{ $self->{_our_borderstyle_modules} }) {
        my $file = $self->{_our_borderstyle_modules}{$pkg};

        my $file_content = $file->content;

        my $theme = \%{"$pkg\::BORDER"}; keys %$theme or do {
            $self->log_fatal(["No border style structure defined in \$BORDER in %s", $file->name]);
        };

        # set ABSTRACT from border style structure's summary
        {
            unless ($file_content =~ m{^#[ \t]*ABSTRACT:[ \t]*([^\n]*)[ \t]*$}m) {
                $self->log_debug(["Skipping setting ABSTRACT %s: no # ABSTRACT", $file->name]);
                last;
            }
            my $abstract = $1;
            if ($abstract =~ /\S/) {
                $self->log_debug(["Skipping setting ABSTRACT %s: already filled (%s)", $file->name, $abstract]);
                last;
            }

            $file_content =~ s{^#\s*ABSTRACT:.*}{# ABSTRACT: $theme->{summary}}m
                or die "Can't set abstract for " . $file->name;
            $self->log(["setting abstract for %s (%s)", $file->name, $theme->{summary}]);
            $file->content($file_content);
        }

    } # BorderStyle::*
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building distribution that has BorderStyle modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::BorderStyle - Plugin to use when building distribution that has BorderStyle modules

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::BorderStyle (from Perl distribution Dist-Zilla-Plugin-BorderStyle), released on 2021-01-23.

=head1 SYNOPSIS

In F<dist.ini>:

 [BorderStyle]

=head1 DESCRIPTION

This plugin is to be used when building distribution that has L<BorderStyle>
modules.

It does the following to every C<BorderStyles/*> .pm file:

=over

=item *

=back

It does the following to every C<BorderStyle/*> .pm file:

=over

=item * Set module abstract from the border style structure (%BORDER)'s summary

=back

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 exclude_module

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-BorderStyle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-BorderStyle/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Plugin::BorderStyle>

L<BorderStyle>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
