package Dist::Zilla::Plugin::Prereqs::EnsureVersion;

our $DATE = '2017-07-04'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::InstallTool';

use namespace::autoclean;

use Config::IOD::Reader;
use File::HomeDir;

sub setup_installer {
    my ($self) = @_;

    state $pmversions = do {
        my $path = File::HomeDir->my_home . "/pmversions.ini";
        my $hoh;
        if (-e $path) {
            $hoh = Config::IOD::Reader->new->read_file($path);
        } else {
            $self->log(["File %s does not exist, assuming ".
                            "no minimum versions are specified", $path]);
            $hoh = {};
        }
        $hoh->{GLOBAL} // {};
    };

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;

    for my $phase (sort keys %$prereqs_hash) {
        for my $rel (sort keys %{$prereqs_hash->{$phase}}) {
            my $versions = $prereqs_hash->{$phase}{$rel};
            for my $mod (sort keys %$versions) {
                my $ver = $versions->{$mod};
                my $minver = $pmversions->{$mod};
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

This document describes version 0.02 of Dist::Zilla::Plugin::Prereqs::EnsureVersion (from Perl distribution Dist-Zilla-Plugin-Prereqs-EnsureVersion), released on 2017-07-04.

=head1 SYNOPSIS

In F<~/pmversions.ini>:

 Log::Any::IfLOG=0.07
 File::Write::Rotate=0.28

In F<dist.ini>:

 [Prereqs::EnsureVersion]

=head1 DESCRIPTION

This plugin will check versions specified in prereqs. First you create
F<~/pmversions.ini> containing list of modules and their mininum versions. Then,
the plugin will check all prereqs against this list. If minimum version is not
met (e.g. the prereq says 0 or a smaller version) then the build will be
aborted.

Ideas for future version: ability to blacklist certain versions, specify version
ranges, e.g.:

 Module::Name = 1.00-2.00, != 1.93

=for Pod::Coverage .+

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

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
