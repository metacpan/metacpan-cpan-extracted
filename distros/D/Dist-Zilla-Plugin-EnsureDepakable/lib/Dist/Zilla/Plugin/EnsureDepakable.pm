package Dist::Zilla::Plugin::EnsureDepakable;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::AfterBuild';

use Module::Depakable;
use namespace::autoclean;

sub after_build {
    my ($self) = @_;

    if ($ENV{DZIL_ENSUREDEPAKABLE_SKIP}) {
        $self->log(["Skipping checking depakable because ".
                        "environment DZIL_ENSUREDEPAKABLE_SKIP is set to true"]);
        return;
    }

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;
    my $rr_prereqs = $prereqs_hash->{runtime}{requires} // {};

    return unless keys %$rr_prereqs;

    my $prereqs = [grep { $_ ne 'perl' } keys %$rr_prereqs];
    $self->log_debug(["Checking whether prereqs are depakable: %s", $prereqs]);
    my $res = Module::Depakable::prereq_depakable(prereqs => $prereqs);
    if ($res->[0] != 200) {
        $self->log_fatal(["Distribution not depakable: %s", $res->[1]]);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Make sure that distribution is "depakable"

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::EnsureDepakable - Make sure that distribution is "depakable"

=head1 VERSION

This document describes version 0.004 of Dist::Zilla::Plugin::EnsureDepakable (from Perl distribution Dist-Zilla-Plugin-EnsureDepakable), released on 2017-07-10.

=head1 SYNOPSIS

In F<dist.ini>:

 [EnsureDepakable]

=head1 DESCRIPTION

This plugin helps make sure that you do not add a (direct, or indirect)
dependency to a non-core XS module, so that all your distribution's modules can
be use-d by a script that wants to be packed so it can be run with only
requiring core perl modules.

See L<Module::Depakable> for more details on the meaning of "depakable".

=for Pod::Coverage .+

=head1 ENVIRONMENT

=head2 DZIL_ENSUREDEPAKABLE_SKIP => bool

Can be set to 1 to skip checking depakable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-EnsureDepakable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-EnsureDepakable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-EnsureDepakable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::depak>

L<Module::Depakable>, L<depakable>

L<Dist::Zilla::Plugin::Depak>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
