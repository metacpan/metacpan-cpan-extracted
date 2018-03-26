package Dist::Zilla::Plugin::Regexp::Pattern;

our $DATE = '2018-03-24'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;
#use Module::Load;

with (
    'Dist::Zilla::Role::AfterBuild',
);

sub after_build {
    my $self = shift;

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;

    # check that Regexp::Pattern is mentioned as DevelopRecommends
    unless (exists $prereqs_hash->{develop}{x_spec}{'Regexp::Pattern'}) {
        unless (-f "lib/Regexp/Pattern.pm") { # exception for Regexp-Pattern dist
            $self->log_fatal(["Regexp::Pattern not specified as prerequisite (phase=develop, rel=x_spec)"]);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building Regexp::Pattern::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Regexp::Pattern - Plugin to use when building Regexp::Pattern::* distribution

=head1 VERSION

This document describes version 0.003 of Dist::Zilla::Plugin::Regexp::Pattern (from Perl distribution Dist-Zilla-Plugin-Regexp-Pattern), released on 2018-03-24.

=head1 SYNOPSIS

In F<dist.ini>:

 [Regexp::Pattern]

=head1 DESCRIPTION

This plugin is to be used when building C<Regexp::Pattern::*> distribution. It
currently does the following:

=over

=item * Make sure that L<Regexp::Pattern> is added as a (phase=develop, rel=x_spec) prerequisite

This is a way to express that the module I<follows the specification> specified
in L<Regexp::Pattern>.

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Regexp-Pattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Regexp-Pattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Regexp-Pattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

L<Pod::Weaver::Plugin::Regexp::Pattern>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
