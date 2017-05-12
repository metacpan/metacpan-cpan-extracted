use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Role::Acl;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Backend::PgSQL::Role::Base';

=head1 NAME

FusqlFS::Backend::PgSQL::Role::Acl - FusqlFS class to expose PostgreSQL
artifact's permissions

=head1 SYNOPSIS

    package FusqlFS::Backend::PgSQL::Tables;
    use parent 'FusqlFS::Artifact';

    use FusqlFS::Backend::PgSQL::Role::Acl;

    sub init
    {
        my $self = shift;

        # initialize class

        $self->{acl} = FusqlFS::Backend::PgSQL::Role::Acl->new('r');
    }

    sub get
    {
        my $self = shift;
        my ($name) = @_;
        my $result = {};

        # load structures into $result

        $result->{acl} = $self->{acl};
        return $result;
    }

=head1 DESCRIPTION

This class exposes PostgreSQL artifact's permissions (a.k.a. ACL) as a
directory with subdirectories named after roles with marker files named after
permissions. It is best used with plugged in L<FusqlFS::Backend::PgSQL::Roles>
module (see L<FusqlFS::Backend::Base> for more info on plugging in different
modules).

The class's C<new> constructor accepts single char argument designating
type of artifact the owner of which is to be exposed. Possible values can
be seen in L<FusqlFS::Backend::PgSQL::Role::Base> module.

=head1 EXPOSED STRUCTURE

First level of exposed files are subdirectories named after roles, e.g. if a
table has perms granted to roles C<user1> and C<user2> this module will expose
subdirectories F<./user1> and F<./user2>.

Removing such subdirectory revokes all permissions from the role, creating
subdirectory with some role's name grants all permission to the role.

Every such subdirectory has following structure:

=over

=item F<./granter>

Symlink to role in F<../../../../roles> which granted current role its permissions.

=item F<./role>

Symlink to current role in F<../../../../roles> (i.e. the role with the name
equal to current subdirectory's name).

=item F<./insert>, F<./update>, F<./delete>, F<./references>, F<./trigger>, F<./usage>

Plain files to designated correspondent permission is granted. Remove some of
the files to revoke the permission or create new file with one of the names
(e.g. with C<touch ./insert>) to grant such permission.

=back

=cut

our %relperms = (
    r  => [ qw(select insert update delete truncate references trigger) ],
    S  => [ qw(usage select update) ],
    _F => [ qw(execute) ],
    _L => [ qw(usage) ],
);

our %aclmap = qw(
    select     r
    insert     a
    update     w
    delete     d
    truncate   D
    references x
    trigger    t
    execute    X
    usage      U
    create     C
    connect    c
    temporary  T
);

sub init
{
    my $self = shift;
    my $relkind = shift;

    my @kind = $self->kind($relkind);

    $self->{perms} = $relperms{$relkind};
    $self->{get_expr} = $self->expr('SELECT %2$sacl FROM pg_catalog.%3$s WHERE %4$s = ? %5$s', @kind);
    $self->{grant_expr}  = sprintf('GRANT %%s ON %1$s %%s TO %%s', @kind);
    $self->{revoke_expr} = sprintf('REVOKE %%s ON %1$s %%s FROM %%s', @kind);
    $self->{create_expr} = sprintf('GRANT ALL PRIVILEGES ON %1$s %%s TO %%s', @kind);
    $self->{drop_expr}   = sprintf('REVOKE ALL PRIVILEGES ON %1$s %%s FROM %%s', @kind);
}

sub get
{
    my $self = shift;
    my ($role, $name) = reverse @_;
    my $acl = $self->all_col($self->{get_expr}, $name);
    return unless $acl && @$acl;

    my $rolep = $role eq 'public'? '': $role;
    my @acl = split /[=\/]/, (grep /^$rolep=/, @{$acl->[0]})[0];
    return unless @acl;

    return { granter => \"roles/$acl[2]", role => \"roles/$acl[0]", map { $_ => 1 } grep $acl[1] =~ /$aclmap{$_}/, @{$self->{perms}} };
}

sub list
{
    my $self = shift;
    my $name = pop;
    my $acl = $self->all_col($self->{get_expr}, $name);
    return unless $acl && @$acl;
    return [ map { (split(/=/, $_))[0]||'public' } @{$acl->[0]} ];
}

sub store
{
    my $self = shift;
    my $perms = $self->validate(pop, { map { '-'.$_ => '' } @{$self->{perms}} }) or return;
    my @newacl = keys %$perms;
    my ($role, $name) = reverse @_;

    my $acl = $self->all_col($self->{get_expr}, $name);
    return unless $acl && @$acl;

    my $rolep = $role eq 'public'? '': $role;
    my $oldacl = (split /[=\/]/, (grep /^$rolep=/, @{$acl->[0]})[0])[1];
    return unless $oldacl;
    my @oldacl = grep $oldacl =~ /$aclmap{$_}/, @{$self->{perms}};

    my ($grant, $revoke) = $self->adiff(\@oldacl, \@newacl);
    $self->do($self->{revoke_expr}, [$_, $name, $role]) foreach @$revoke;
    $self->do($self->{grant_expr},  [$_, $name, $role]) foreach @$grant;
}

sub create
{
    my $self = shift;
    my ($role, $name) = reverse @_;
    $self->do($self->{create_expr}, [$name, $role]);
}

sub drop
{
    my $self = shift;
    my ($role, $name) = reverse @_;
    $self->do($self->{drop_expr}, [$name, $role]);
}

sub rename
{
    my $self = shift;
    my ($newrole, $role, $name) = reverse @_;
    my $acl = $self->get($name, $role);
    $self->drop($name, $role) and $self->store($name, $newrole, $acl);
}

1;

