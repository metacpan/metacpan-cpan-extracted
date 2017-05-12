use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Role::Owned;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use base 'FusqlFS::Backend::PgSQL::Role::Base';

=head1 NAME

FusqlFS::Backend::PgSQL::Role::Owned - FusqlFS module to aggregate all
PostgreSQL artifacts owned by a role into single place

=head1 SYNOPSIS

    package FusqlFS::Backend::PgSQL::Roles;
    use base 'FusqlFS::Artifact';

    use FusqlFS::Backend::PgSQL::Role::Owned;

    sub init
    {
        my $self = shift;

        # initialize instance and class

        $self->{owned} = FusqlFS::Backend::PgSQL::Role::Owned->new();
    }

    sub get
    {
        my $class = shift;
        my ($role) = @_;
        my $result = {};

        # get data about $role into $result

        $result->{owned} = $self->{owned};

        return $result;
    }

=head1 DESCRIPTION

This module gathers all database artifacts owned by single role into one single
place. It does it by providing symlinks to artifacts sorted by type (`tables',
`functions' etc., see L</EXPOSED STRUCTURE> for details).

This module is not to be plugged in any place of tree, it is actually to be
used in L</FusqlFS::Backend::PgSQL::Roles> module.

=head1 EXPOSED STRUCTURE

=over

=item F<./tables>, F<./functions>, F<./indices>, F<./sequences>, F<./languages>

This is the first level of hierarchy to sort owned artifacts by type and
provide separate namespaces for different objects in database.

There are symlinks to artifacts of correspondent type in each of these
subdirectories, e.g. if a role owns table C<sometable> and stored procedure
C<someproc> there will be symlinks in F<./tables/sometable> and
F<./functions/someproc> pointing to F</tables/sometable> and
F</functions/someproc>.

=back

=cut

our %kinds = qw(
    tables    r
    sequences S
    functions _F
    languages _L
);

sub init
{
    my $self = shift;

    while (my ($kind, $rel) = each %kinds)
    {
        my @kind = $self->kind($rel);
        $self->{$kind} = [
            $self->expr('SELECT %4$s FROM pg_catalog.%3$s WHERE pg_catalog.pg_get_userbyid(%2$sowner) = ? %5$s', @kind),
            sprintf('ALTER %1$s "%%s" OWNER TO "%%s"', @kind),
        ];
    }
}

sub get
{
    my $self = shift;
    my ($role, $kind) = @_;
    return unless exists $self->{$kind};
    my $data = $self->all_col($self->{$kind}->[0], $role);
    return unless $data;
    return { map { $_ => \"$kind/$_" } @$data };
}

sub list
{
    my $self = shift;
    my ($role) = @_;
    return [ keys %kinds ];
}

sub store
{
    my $self = shift;
    my ($role, $kind, $data) = @_;
    my $list = $self->validate($data, ['HASH', sub{ [ keys %$_ ] }]) or return;
    $self->do($self->{$kind}->[1], $_, $role) foreach @$list;
}

1;
