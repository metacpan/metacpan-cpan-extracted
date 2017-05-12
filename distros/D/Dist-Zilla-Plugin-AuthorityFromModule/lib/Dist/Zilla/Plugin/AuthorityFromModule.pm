use strict;
use warnings;
package Dist::Zilla::Plugin::AuthorityFromModule; # git description: v0.006-15-gdad604f
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: (DEPRECATED) Add metadata to your distribution indicating what module to copy PAUSE permissions from
# KEYWORDS: distribution metadata authority permissions PAUSE users

our $VERSION = '0.007';

use Moose;
with 'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::ModuleMetadata';
use List::Util 1.33 qw(first any);
use namespace::autoclean;

has module => (
    is => 'ro', isa => 'Str',
);

has _module_name => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;

        if (my $module = $self->module)
        {
            if (my $file = first {
                    $_->name =~ m{^lib/} and $_->name =~ m{\.pm$}
                    and any { $module eq $_ } $self->_packages_from_file($_) }
                @{ $self->zilla->files })
            {
                $self->log_debug([ 'found \'%s\' in %s', $module, $file->name ]);
                return $module;
            }

            $self->log_fatal([ 'the module \'%s\' cannot be found in the distribution', $module ]);
        }

        $self->log_debug('no module provided; defaulting to the main module');

        my $file = $self->zilla->main_module;
        my ($module) = $self->_packages_from_file($file);
        $self->log_debug([ 'extracted package \'%s\' from %s', $module, $file->name ]);
        $module;
    },
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        module => $self->_module_name,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub metadata
{
    my $self = shift;

    my $module = $self->_module_name;

    +{
        # TODO: figure out which field is preferred
        x_authority_from_module => $module,
        x_permissions_from_module => $module,
    };
}

sub _packages_from_file
{
    my ($self, $file) = @_;

    my $mmd = $self->module_metadata_for_file($file);
    grep { $_ ne 'main' } $mmd->packages_inside;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AuthorityFromModule - (DEPRECATED) Add metadata to your distribution indicating what module to copy PAUSE permissions from

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your F<dist.ini>:

    [AuthorityFromModule]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that adds the C<x_authority_from_module> and
C<x_permissions_from_module> keys to your distribution metadata, indicating
from which module to copy L<PAUSE|http://pause.perl.org> permissions when a
module in your distribution enters the L<PAUSE|http://pause.perl.org> index
that has not ever previously been indexed.

As of May 2016, L<PAUSE|http://pause.perl.org> now copies the permissions from the "main module" to any new modules
entering the index for the first time, which renders this module obsolete, with all its goals met in full. There is
no longer any need to use this module.

=for stopwords Colin Newell QA Hackathon

For more information, see the L<pull request that made the change|https://github.com/andk/pause/pull/222>, written
by Colin Newell at the Perl QA Hackathon, in Rugby UK, April 2016.

=head1 MOTIVATION

NOTE: The remainder of this documentation reflects how PAUSE used to work, and is retained purely for historical reasons.

The idea is (was) that this is a more useful piece of data for
L<PAUSE|http://pause.perl.org> than C<x_authority>.  Here is how the release
process works with C<x_authority>, using L<Moose> as an example:

=for stopwords STEVAN maint

=over 4

=item *

I (ETHER) release a new version of L<Moose> with a new module added, C<Moose::Foo>

=item *

normally, L<PAUSE|http://pause.perl.org> would give me "first-come" permissions on this module, but since L<PAUSE|http://pause.perl.org> sees the C<< x_authority => 'cpan:STEVAN' >> metadata, it instead gives "first-come" to STEVAN, and "co-maint" to me

=item *

but now none of the other members of the Moose cabal can do the next Moose release and get the new version of C<Moose::Foo> indexed - they need to contact STEVAN and ask him to give them co-maint at L<http://pause.perl.org>

=back

So, we can see the only gain is that STEVAN automatically gets permission on
the new module, but still, no one else does.  Now, let's look at how
C<x_authority_from_module> would work:

=over 4

=item *

I (ETHER) release a new version of L<Moose> with a new module added, C<Moose::Foo>

=item *

L<PAUSE|http://pause.perl.org> sees the C<< x_authority_from_module => 'Moose' >> metadata and looks up the permissions for the L<Moose> module, and, L<finding many authors|https://pause.perl.org/pause/authenquery?pause99_peek_perms_by=me&pause99_peek_perms_query=Moose&pause99_peek_perms_sub=Submit>, copies all those permissions to L<Moose::Foo>: STEVAN gets first-come, and everyone else (ETHER included) gets co-maint.

=item *

now any of the other members of the Moose cabal can do the next Moose release and everything will be properly indexed, with no manual intervention required.

=back

=head1 CONFIGURATION OPTIONS

=head2 C<module>

The module name to copy permissions from. It must exist in the distribution,
and exist in the L<PAUSE|http://pause.perl.org> permissions table (see
L<peek at PAUSE permissions|https://pause.perl.org/pause/authenquery?ACTION=peek_perms>).

This config is optional; it defaults to the L<main module|Dist::Zilla/main_module> in the distribution.

=for Pod::Coverage metadata

=head1 SEE ALSO

=over 4

=item *

L<https://github.com/andk/pause/pull/222>

=item *

L<Dist::Zilla::Plugin::Authority>

=item *

L<peek at PAUSE permissions|https://pause.perl.org/pause/authenquery?ACTION=peek_perms>

=item *

L<What is x_authority?|http://jawnsy.wordpress.com/2011/02/20/what-is-x_authority>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-AuthorityFromModule>
(or L<bug-Dist-Zilla-Plugin-AuthorityFromModule@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-AuthorityFromModule@rt.cpan.org>).

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
