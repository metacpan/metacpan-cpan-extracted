package DesktopWorkspaceRole::Source::DefHash;

use strict;
use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'DesktopWorkspaceRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-03-29'; # DATE
our $DIST = 'DesktopWorkspaceRoles-Standard'; # DIST
our $VERSION = '0.001'; # VERSION

sub new {
    my ($class, %args) = @_;

    my $defhash = delete $args{defhash};
    unless ($defhash) {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
        $defhash = ${"$class\::SPEC"};
    }

    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        defhash => $defhash,
    }, $class;
}

sub items {
    my $self = shift;
    if (@_) {
        $self->{defhash}{items} = $_[0];
    } else {
        $self->{defhash}{items};
    }
}

sub kde_activity {
    my $self = shift;
    if (@_) {
        $self->{defhash}{kde_activity} = $_[0];
    } else {
        $self->{defhash}{kde_activity};
    }
}

sub new_browser_window {
    my $self = shift;
    if (@_) {
        $self->{defhash}{new_browser_window} = $_[0];
    } else {
        $self->{defhash}{new_browser_window};
    }
}

1;
# ABSTRACT: Get specification from a DefHash

__END__

=pod

=encoding UTF-8

=head1 NAME

DesktopWorkspaceRole::Source::DefHash - Get specification from a DefHash

=head1 VERSION

This document describes version 0.001 of DesktopWorkspaceRole::Source::DefHash (from Perl distribution DesktopWorkspaceRoles-Standard), released on 2026-03-29.

=head1 SYNOPSIS

 my $dw = DesktopWorkspace::Foo->new(defhash => { ... });

=head1 DESCRIPTION

This role retrieves the whole DesktopWorkspace specification from a Perl hash
(that follows L<DefHash> specification).

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

None.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DesktopWorkspaceRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DesktopWorkspaceRoles-Standard>.

=head1 SEE ALSO

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DesktopWorkspaceRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
