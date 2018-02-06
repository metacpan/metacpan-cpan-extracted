use strict;
use warnings;
package Dist::Zilla::Plugin::RewriteVersion::Transitional; # git description: v0.008-7-g50b6f0b
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Ease the transition to [RewriteVersion] in your distribution
# KEYWORDS: plugin version rewrite munge module

our $VERSION = '0.009';

use Moose;
extends 'Dist::Zilla::Plugin::RewriteVersion';
with 'Dist::Zilla::Role::InsertVersion';

use Moose::Util::TypeConstraints 'role_type';
use Dist::Zilla::Util;
use Module::Runtime 'use_module';
use Term::ANSIColor 'colored';
use namespace::autoclean;

has fallback_version_provider => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub {
        shift->log('tried to provide a version, but fallback_version_provider configuration is missing');
        return '';
    },
);

has _fallback_version_provider_args => (
    is => 'ro', isa => 'HashRef[Str]',
);

has _fallback_version_provider_obj => (
    is => 'ro',
    isa => role_type('Dist::Zilla::Role::VersionProvider'),
    lazy => 1,
    default => sub {
        my $self = shift;
        use_module(Dist::Zilla::Util->expand_config_package_name($self->fallback_version_provider))->new(
            zilla => $self->zilla,
            plugin_name => 'fallback version provider, via [RewriteVersion::Transitional]',
            %{ $self->_fallback_version_provider_args },
        );
    },
    predicate => '_using_fallback_version_provider',
);

around BUILDARGS => sub
{
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig(@_);

    my %extra_args = %$args;
    delete @extra_args{ map { $_->name } $self->meta->get_all_attributes };

    return +{ %$args, _fallback_version_provider_args => \%extra_args };
};

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        $self->_using_fallback_version_provider
            ? ( map { $_ => $self->$_ } qw(fallback_version_provider _fallback_version_provider_args) )
            : (),
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    $config->{ $self->fallback_version_provider } = $self->_fallback_version_provider_obj->dump_config
        if $self->_using_fallback_version_provider;

    return $config;
};

around provide_version => sub
{
    my $orig = shift;
    my $self = shift;

    return if $self->can('skip_version_provider') and $self->skip_version_provider;

    my $version = $self->$orig(@_);
    return $version if defined $version;

    # if we have no fallback_version_provider, ether they forgot to set it (probably in a bundle that uses us), or
    # the version is already being provided some other way (hardcoded in dist.ini?) and we shouldn't even be here.
    # Bail out gracefully and give something else the chance to provide the version and then we can use our
    # transitional logic to add a $VERSION after release!
    if (my $fallback_version_provider = $self->fallback_version_provider)
    {
        $self->log([ 'no version found in environment or file; falling back to %s', $fallback_version_provider ]);
        return $self->_fallback_version_provider_obj->provide_version;
    }

    return;
};

my $warned_underscore;
around rewrite_version => sub
{
    my $orig = shift;
    my $self = shift;
    my ($file, $version) = @_;

    $self->log([
        colored('%s is a dangerous $VERSION to use without stripping the underscore on a subsequent line!', 'yellow'),
        $version,
    ]) if $version =~ /_/ and not $warned_underscore++;

    # update existing our $VERSION = '...'; entry
    return 1 if $self->$orig($file, $version);

    return $self->insert_version($file, $version, $self->zilla->is_trial);
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::RewriteVersion::Transitional - Ease the transition to [RewriteVersion] in your distribution

=head1 VERSION

version 0.009

=head1 SYNOPSIS

In your F<dist.ini>:

    [RewriteVersion::Transitional]
    fallback_version_provider = Git::NextVersion

=head1 DESCRIPTION

=for stopwords BumpVersionAfterRelease OurPkgVersion PkgVersion

This is a L<Dist::Zilla> plugin that subclasses
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>, to allow plugin
bundles to transition from L<[PkgVersion]|Dist::Zilla::Plugin::PkgVersion> or
L<[OurPkgVersion]|Dist::Zilla::Plugin::OurPkgVersion> to
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>
and L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>
without having to manually edit the F<dist.ini> or any F<.pm> files.

=head2 Determining the distribution version

As with L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>, the version
can be overridden with the C<V> environment variable, or provided through some
other means by setting C<skip_version_provider = 1>.  Then, the main module (see
L<Dist::Zilla/main module>) in the distribution is checked for a C<$VERSION>
assignment.  If one is not found, then the plugin named by the
C<fallback_version_provider> is instantiated (with any extra configuration
options provided) and called to determine the version.

=head2 Munging the modules

When used in a distribution where the F<.pm> file(s) does not contain a
C<$VERSION> declaration, this plugin will add one. If one is already present,
it leaves it alone, acting just as
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion> would.

You would then use L<[BumpVersionAfterRelease::Transitional]|Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional>
to increment the C<$VERSION> in the F<.pm> files in the repository.

B<Note:> If there is more than one package in a single file, if there was
I<any> C<$VERSION> declaration in the file, no additional declarations are
added for the other packages, even if you are using the C<global> option.

=head1 CONFIGURATION OPTIONS

Configuration is the same as in
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>, with the addition of:

=head2 fallback_version_provider

Specify the name (in abbreviated form) of the plugin to use as a version
provider if the version was not already set with the C<V> environment
variable.  Not used if
L<Dist::Zilla::Plugin::RewriteVersion/skip_version_provider> is true.

Don't forget to add this plugin as a runtime-requires prerequisite in your
plugin bundle!

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::PkgVersion>

=item *

L<Dist::Zilla::Plugin::RewriteVersion>

=item *

L<Dist::Zilla::Plugin::BumpVersionAfterRelease>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-RewriteVersion-Transitional>
(or L<bug-Dist-Zilla-Plugin-RewriteVersion-Transitional@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-RewriteVersion-Transitional@rt.cpan.org>).

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
