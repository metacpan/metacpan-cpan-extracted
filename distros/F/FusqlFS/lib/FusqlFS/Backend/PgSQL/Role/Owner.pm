use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Role::Owner;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Backend::PgSQL::Role::Base';

=head1 NAME

FusqlFS::Backend::PgSQL::Role::Owner - FusqlFS class to expose PostgreSQL
artifact's owner

=head1 SYNOPSIS

    package FusqlFS::Backend::PgSQL::Tables;
    use parent 'FusqlFS::Artifact';

    use FusqlFS::Backend::PgSQL::Role::Owner;

    sub init
    {
        my $self = shift;

        # initialize class

        $self->{owner} = FusqlFS::Backend::PgSQL::Role::Owner->new('r');
    }

    sub get
    {
        my $self = shift;
        my ($name) = @_;
        my $result = {};

        # load structures into $result

        $result->{owner} = $self->{owner};
        return $result;
    }

=head1 DESCRIPTION

This class exposes PostgreSQL artifact's owner as a symlink to role in
F</roles> directory. It is best used with plugged in
L<FusqlFS::Backend::PgSQL::Roles> module (see L<FusqlFS::Backend::Base> for
more info on plugging in different modules).

The class's C<new> constructor accepts single char argument designating type of
artifact the owner of which is to be exposed. Possible values of this argument
can be seen in L<FusqlFS::Backend::PgSQL::Role::Base> module.

=cut

sub init
{
    my $self = shift;
    my $relkind = shift;

    my @kind = $self->kind($relkind);

    $self->{get_expr} = $self->expr('SELECT pg_catalog.pg_get_userbyid(%2$sowner) FROM pg_catalog.%3$s WHERE %4$s = ? %5$s', @kind);
    $self->{store_expr} = sprintf('ALTER %1$s "%%s" OWNER TO "%%s"', @kind);
}

sub get
{
    my $self = shift;
    my $name = pop;
    my $owner = $self->all_col($self->{get_expr}, $name);
    return \"roles/$owner->[0]" if $owner;
}

sub store
{
    my $self = shift;
    my $data = pop;
    my $name = pop;
    $data = $$data if ref $data eq 'SCALAR';
    return if ref $data || $data !~ m#^roles/([^/]+)$#;
    $self->do($self->{store_expr}, [$name, $1]);
}

1;
