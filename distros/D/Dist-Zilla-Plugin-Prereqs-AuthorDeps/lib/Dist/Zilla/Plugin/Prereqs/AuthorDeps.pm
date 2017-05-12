use v5.10;
use strict;
use warnings;

package Dist::Zilla::Plugin::Prereqs::AuthorDeps;
# ABSTRACT: Add Dist::Zilla authordeps to META files as develop prereqs
our $VERSION = '0.006';

use Moose;
use MooseX::Types::Moose qw( HashRef ArrayRef Str );
use List::Util qw/min/;

use Dist::Zilla::Util::AuthorDeps 5.021;
use Dist::Zilla 4;

use constant MAX_DZIL_VERSION => 5;

with 'Dist::Zilla::Role::PrereqSource';

#pod =attr phase
#pod
#pod Phase for prereqs. Defaults to 'develop'.
#pod
#pod =cut

has phase => (
    is      => ro  =>,
    isa     => Str,
    lazy    => 1,
    default => sub { 'develop' },
);

#pod =attr relation
#pod
#pod Relation type.  Defaults to 'requires'.
#pod
#pod =cut

has relation => (
    is      => ro  =>,
    isa     => Str,
    lazy    => 1,
    default => sub { 'requires' },
);

#pod =attr exclude
#pod
#pod Module to exclude from prereqs.  May be specified multiple times.
#pod
#pod =cut

has exclude => (
    is => ro =>,
    isa => ArrayRef [Str],
    lazy    => 1,
    default => sub { [] }
);

has _exclude_hash => (
    is => ro =>,
    isa => HashRef [Str],
    lazy    => 1,
    builder => '_build__exclude_hash'
);

sub _build__exclude_hash {
    my ( $self, ) = @_;
    return { map { ; $_ => 1 } @{ $self->exclude } };
}

sub mvp_multivalue_args { return qw(exclude) }

sub register_prereqs {
    my ($self)   = @_;
    my $zilla    = $self->zilla;
    my $phase    = $self->phase;
    my $relation = $self->relation;

    my $authordeps = Dist::Zilla::Util::AuthorDeps::extract_author_deps('.');

    for my $req (@$authordeps) {
        my ( $mod, $version ) = each %$req;
        next if $self->_exclude_hash->{$mod};
        $zilla->register_prereqs( { phase => $phase, type => $relation }, $mod, $version );
    }

    $zilla->register_prereqs(
        { phase => $phase, type => $relation },
        "Dist::Zilla", min( MAX_DZIL_VERSION, int( Dist::Zilla->VERSION ) ),
    );

    return;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::AuthorDeps - Add Dist::Zilla authordeps to META files as develop prereqs

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    # in dist.ini:

    [Prereqs::AuthorDeps]

=head1 DESCRIPTION

This adds L<Dist::Zilla> itself and the result of the C<dzil authordeps>
command to the 'develop' phase prerequisite list.

=head1 ATTRIBUTES

=head2 phase

Phase for prereqs. Defaults to 'develop'.

=head2 relation

Relation type.  Defaults to 'requires'.

=head2 exclude

Module to exclude from prereqs.  May be specified multiple times.

=for Pod::Coverage mvp_multivalue_args register_prereqs MAX_DZIL_VERSION

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Prereqs::Plugins> is similar but puts all plugins after
expanding any bundles into prerequisites, which is a much longer list that you
would get from C<dzil authordeps>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dist-Zilla-Plugin-Prereqs-AuthorDeps/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dist-Zilla-Plugin-Prereqs-AuthorDeps>

  git clone https://github.com/dagolden/Dist-Zilla-Plugin-Prereqs-AuthorDeps.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords David Golden Karen Etheridge

=over 4

=item *

David Golden <xdg@xdg.me>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
