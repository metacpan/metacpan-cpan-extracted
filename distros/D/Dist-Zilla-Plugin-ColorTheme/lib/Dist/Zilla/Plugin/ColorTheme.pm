package Dist::Zilla::Plugin::ColorTheme;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-08'; # DATE
our $DIST = 'Dist-Zilla-Plugin-ColorTheme'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Moose;

#use PMVersions::Util qw(version_from_pmversions);
use Require::Hook::DzilBuild;

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

sub _load_colortheme_modules {
    my $self = shift;

    return $self->{_our_colortheme_modules} if $self->{_loaded_colortheme_modules}++;

    local @INC = (Require::Hook::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

    my %res;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!^lib/((?:.*/)?ColorTheme/.+\.pm)$!;

        my $pkg_pm = $1;
        (my $pkg = $pkg_pm) =~ s/\.pm$//; $pkg =~ s!/!::!g;

        if ($self->exclude_module && grep { $pkg eq $_ } @{ $self->exclude_module }) {
            $self->log_debug(["ColorTheme module %s excluded", $pkg]);
            next;
        }

        $self->log_debug(["Loading color theme module %s ...", $pkg_pm]);
        delete $INC{$pkg_pm};
        require $pkg_pm;
        $res{$pkg} = $file;
    }

    $self->{_our_colortheme_modules} = \%res;
}

sub _load_colorthemes_modules {
    my $self = shift;

    return $self->{_our_colorthemes_modules} if $self->{_loaded_colorthemes_modules}++;

    local @INC = (Require::Hook::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

    my %res;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!^lib/((?:.*/)?ColorThemes/.+\.pm)$!;
        my $pkg_pm = $1;
        (my $pkg = $pkg_pm) =~ s/\.pm$//; $pkg =~ s!/!::!g;
        require $pkg_pm;
        $res{$pkg} = $file;
    }

    $self->{_our_colorthemes_modules} = \%res;
}

sub munge_files {
    no strict 'refs';

    my $self = shift;

    $self->{_used_colortheme_modules} //= {};

    $self->_load_colortheme_modules;
    $self->_load_colorthemes_modules;

  COLORTHEMES_MODULE:
    for my $pkg (sort keys %{ $self->{_our_colorthemes_modules} }) {
        # ...
    }

  COLORTHEME_MODULE:
    for my $pkg (sort keys %{ $self->{_our_colortheme_modules} }) {
        my $file = $self->{_our_colortheme_modules}{$pkg};

        my $file_content = $file->content;

        my $theme = \%{"$pkg\::THEME"}; keys %$theme or do {
            $self->log_fatal(["No color theme structure defined in \$THEME in %s", $file->name]);
        };

        # set ABSTRACT from color theme structure's summary
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

    } # ColorTheme::*
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building distribution that has ColorTheme modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ColorTheme - Plugin to use when building distribution that has ColorTheme modules

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::ColorTheme (from Perl distribution Dist-Zilla-Plugin-ColorTheme), released on 2020-06-08.

=head1 SYNOPSIS

In F<dist.ini>:

 [ColorTheme]

=head1 DESCRIPTION

This plugin is to be used when building distribution that has L<ColorTheme>
modules.

It does the following to every C<ColorThemes/*> .pm file:

=over

=item *

=back

It does the following to every C<ColorTheme/*> .pm file:

=over

=item * Set module abstract from the color theme structure (%THEME)'s summary

=back

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 exclude_module

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-ColorTheme>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-ColorTheme>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-ColorTheme>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Plugin::ColorTheme>

L<ColorTheme>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
