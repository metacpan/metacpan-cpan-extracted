#
# This file is part of Dist-Zilla-Role-EnsureStash
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Role::EnsureStash;
{
  $Dist::Zilla::Role::EnsureStash::VERSION = '0.002';
}

# ABSTRACT: Ensure your plugin has access to a certain stash

# XXX this is probably a good candidate for MX::Role::Parameterized
use Moose::Role;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

with 'Dist::Zilla::Role::RegisterStash';


# XXX this is probably a good candidate for MX::RelatedClasses
requires 'our_stash_name';
requires 'our_stash_class';

has our_stash => (
    is       => 'lazy',
    isa_role => 'Dist::Zilla::Role::Stash',
);

sub _build_our_stash {
    my $self = shift @_;

    my $stash   = $self->zilla->stash_named($self->our_stash_name);
    return $stash if defined $stash;

    Class::MOP::load_class($self->our_stash_class);
    $stash = $self->our_stash_class->new;
    $self->_register_stash($self->our_stash_name, $stash);

    return $stash;
}

!!42;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl

=head1 NAME

Dist::Zilla::Role::EnsureStash - Ensure your plugin has access to a certain stash

=head1 VERSION

This document describes version 0.002 of Dist::Zilla::Role::EnsureStash - released December 30, 2012 as part of Dist-Zilla-Role-EnsureStash.

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::Something;

    use Moose;
    use namespace::autoclean;

    with
        'Dist::Zilla::Plugin::BeforeRelease',
        'Dizt::Zilla::Role::EnsureStash',
        ;

    sub our_stash_name  { '%ThatStash'                    }
    sub our_stash_class { 'Dist::Zilla::Stash::ThatStash' }

    sub before_release {
        my $self = shift @_;

        # returns '%ThatStash' if it exists, otherwise creates, registers,
        # then returns it
        my $stash = $self->our_stash;

        # profit!
    }

=head1 DESCRIPTION

This is a L<Dist::Zilla> role designed to ensure that if a plugin needs access
to a stash, and that stash does not already exist, then it is automatically
created and returned.

This is more intended for helping plugins that need to share common data do so
via stashes, rather than specific information (e.g. PAUSE credentials and the
like).  As such, the stash instances created here are expected to largely be
able to do their thing without much (preferably any) external input.

=head1 REQUIRED METHODS

=head2 our_stash_name

Just as it sounds; should return something Dist::Zilla will recognize as a
stash name (e.g. C<%SomeStash>).

=head2 our_stash_class

This is expected to return the class name of the class to be created and
registered as C<our_stash_name()> if a stash by that name does not exist.

It is expected to have consumed the L<Dist::Zilla::Role::Stash> role.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Role::RegisterStash>

=back

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
