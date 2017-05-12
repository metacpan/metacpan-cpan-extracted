use strict;
use warnings;
package Dist::Zilla::Plugin::Breaks; # git description: v0.003-23-gd774732
# ABSTRACT: Add metadata about potential breakages caused by your distribution
# KEYWORDS: distribution metadata prerequisites upstream dependencies modules conflicts breaks breakages
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.004';

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use CPAN::Meta::Requirements;
use Carp 'confess';
use namespace::autoclean;

sub mvp_multivalue_args { qw(breaks) }

has breaks => (
    is => 'ro', isa => 'HashRef[Str]',
    required => 1,
);

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);
    my ($zilla, $plugin_name) = delete @{$args}{qw(zilla plugin_name)};

    confess 'Missing modules in [Breaks]' if not keys %$args;

    return {
        zilla => $zilla,
        plugin_name => $plugin_name,
        breaks => $args,
    };
};

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    my $data = {
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    $config->{+__PACKAGE__} = $data if keys %$data;

    return $config;
};

sub metadata
{
    my $self = shift;

    my $reqs = CPAN::Meta::Requirements->new;
    my $breaks_data = $self->breaks;
    foreach my $package (keys %$breaks_data)
    {
        # this validates input data, and canonicalizes formatting
        $reqs->add_string_requirement($package, $breaks_data->{$package});
    }

    $breaks_data = $reqs->as_string_hash;
    return keys %$breaks_data ? { x_breaks => $breaks_data } : {};
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Breaks - Add metadata about potential breakages caused by your distribution

=head1 VERSION

version 0.004

=head1 SYNOPSIS

In your F<dist.ini>:

    [Breaks]
    Foo::Bar = <= 1.0       ; anything at this version or below is out of date
    Foo::Baz = == 2.35      ; just this one exact version is problematic

=head1 DESCRIPTION

This plugin adds distribution metadata regarding other modules and version
that are not compatible with your distribution's release.  It is not quite the
same as the C<conflicts> field in prerequisite metadata (see
L<CPAN::Meta::Spec/Relationships>), but rather
indicates what modules will likely not work once your distribution is
installed.

=for stopwords darkPAN

This is a not-uncommon problem when modifying a module's API - there are other
existing modules out on the CPAN (or a darkPAN) which use the old API, and will
need to be updated when the new API is removed.  These modules are not
prerequisites -- our distribution does not use those modules, but rather those
modules use B<us>. So, it's not valid to list those modules in our
prerequisites -- besides, it would likely (almost certainly) be a circular dependency!

The data is added to metadata in the form of the C<x_breaks> field, as set out
by the L<Lancaster consensus|http://www.dagolden.com/index.php/2098/the-annotated-lancaster-consensus/>.
The exact syntax and use may continue to change until it is accepted as an
official part of the meta specification.

Version ranges can and normally should be specified; see
L<CPAN::Meta::Spec/Version Ranges>. They are
interpreted as for C<conflicts> -- version(s) specified indicate the B<bad>
versions of modules, not version(s) that must be present for normal operation.
That is, packages should be specified with the version(s) that will B<not>
work when your distribution is installed; for example, if all version of
C<Foo::Bar> up to and including 1.2 will break, but a release of 1.3 will
work, then specify the breakage as:

    [Breaks]
    Foo::Bar = <= 1.2

or more accurately:

    [Breaks]
    Foo::Bar = < 1.3

A bare version with no operator is interpreted as C<< >= >> -- all versions at
or above the one specified are considered bad -- which is generally not what
you want to say!

=for stopwords CheckBreaks

The L<[Test::CheckBreaks]|Dist::Zilla::Plugin::Test::CheckBreaks> plugin can
generate a test for your distribution that will check this field and provide
diagnostic information to the user should any problems be identified.

Additionally, the L<[Conflicts]|Dist::Zilla::Plugin::Conflicts> plugin can
generate C<x_breaks> data, as well as a (non-standard) mechanism for checking for conflicts
from within F<Makefile.PL>/F<Build.PL>.

=for Pod::Coverage mvp_multivalue_args metadata

=head1 SEE ALSO

=over 4

=item *

L<Annotated Lancaster consensus|http://www.dagolden.com/index.php/2098/the-annotated-lancaster-consensus/>.

=item *

L<CPAN::Meta::Spec/Relationships>

=item *

L<Dist::Zilla::Plugin::Test::CheckBreaks>

=item *

L<Dist::Zilla::Plugin::Conflicts>

=item *

L<Dist::CheckConflicts>

=item *

L<Module::Install::CheckConflicts>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Breaks>
(or L<bug-Dist-Zilla-Plugin-Breaks@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Breaks@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
