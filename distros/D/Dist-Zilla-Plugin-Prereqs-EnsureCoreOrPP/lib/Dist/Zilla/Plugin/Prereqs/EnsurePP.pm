package Dist::Zilla::Plugin::Prereqs::EnsurePP;

our $DATE = '2016-02-19'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::InstallTool';

use App::lcpan::Call qw(call_lcpan_script);
use Module::Path::More qw(module_path);
use Module::XSOrPP qw(is_pp);
use namespace::autoclean;

sub setup_installer {
    my ($self) = @_;

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;
    my $rr_prereqs = $prereqs_hash->{runtime}{requires} // {};

    $self->log(["Listing prereqs ..."]);
    my $res = call_lcpan_script(argv=>[
        "deps", "-R",
        grep {$_ ne 'perl'} keys %$rr_prereqs]);
    my $has_err;
    for my $entry (@$res) {
        my $mod = $entry->{module};
        $mod =~ s/^\s+//;
        next if $mod eq 'perl';
        if (!module_path(module=>$mod)) {
            $self->log_fatal(["Prerequisite %s is not installed", $mod]);
        }
        if (!is_pp($mod)) {
            $has_err++;
            $self->log(["Prerequisite %s is not PP", $mod]);
        }
    }

    if ($has_err) {
        $self->log_fatal(["There are some errors in prerequisites"]);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Make sure that prereqs (and their deps) are all PP modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::EnsurePP - Make sure that prereqs (and their deps) are all PP modules

=head1 VERSION

This document describes version 0.09 of Dist::Zilla::Plugin::Prereqs::EnsurePP (from Perl distribution Dist-Zilla-Plugin-Prereqs-EnsureCoreOrPP), released on 2016-02-19.

=head1 SYNOPSIS

In dist.ini:

 [Prereqs::EnsurePP]

=head1 DESCRIPTION

This plugin will check that all RuntimeRequires prereqs (and all their recursive
RuntimeRequires deps) are all PP modules. To do this checking, all prereqs must
be installed during build time and they all must be indexed by CPAN. Also, a
reasonably fresh local CPAN mirror indexed (produced by L<App::lcpan>) is
required.

I need this when building a dist that needs to be included in a fatpacked
script.

Note: I put this plugin in setup_installer phase instead of before_release
because I don't always use "dzil release" (i.e. during offline deployment, I
"dzil build" and "pause upload" separately.)

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Prereqs-EnsureCoreOrPP>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Prereqs-EnsureCoreOrPP>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Prereqs-EnsureCoreOrPP>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::FatPacker>, L<App::depak>

L<Dist::Zilla::Plugin::Prereqs::EnsureCoreOrPP>

Related plugins: L<Dist::Zilla::Plugin::CheckPrereqsIndexed>,
L<Dist::Zilla::Plugin::EnsurePrereqsInstalled>,
L<Dist::Zilla::Plugin::OnlyCorePrereqs>

L<App::lcpan>, L<lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
