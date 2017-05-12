use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Sequences;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Backend::PgSQL::Sequences - FusqlFS PostgreSQL database sequences interface

=head1 SYNOPSIS

    use FusqlFS::Backend::PgSQL::Sequences;

    my $seqs = FusqlFS::Backend::PgSQL::Sequences->new();

=head1 DESCRIPTION

This is FusqlFS an interface to PostgreSQL database sequences. This class is
not to be used by itself.

See L<FusqlFS::Artifact> for description of interface methods,
L<FusqlFS::Backend> to learn more on backend initialization and
L<FusqlFS::Backend::Base> for more info on database backends writing.

=head1 EXPOSED STRUCTURE

=over

=item F<./struct>

Additional sequence info. To learn more about these fields see PostgreSQL
documentation about C<CREATE SEQUENCE>.

=item F<./owner>

Symlink to sequence's owner in F<../../roles>.

=item F<./acl>

Sequence's ACL with permissions given to different roles. See
L<FusqlFS::Backend::PgSQL::Role::Acl> for details.

=back

=cut

use FusqlFS::Backend::PgSQL::Role::Owner;
use FusqlFS::Backend::PgSQL::Role::Acl;
use DBI qw(:sql_types);

sub init
{
    my $self = shift;

    $self->{list_expr} = $self->expr("SELECT relname FROM pg_catalog.pg_class WHERE relkind = 'S'");
    $self->{exists_expr} = $self->expr("SELECT 1 FROM pg_catalog.pg_class WHERE relkind = 'S' AND relname = ?");
    $self->{get_expr} = 'SELECT * FROM "%s"';
    $self->{rename_expr} = 'ALTER SEQUENCE "%s" RENAME TO "%s"';
    $self->{create_expr} = 'CREATE SEQUENCE "%s"';
    $self->{drop_expr} = 'DROP SEQUENCE "%s"';

    $self->{owner} = FusqlFS::Backend::PgSQL::Role::Owner->new('S');
    $self->{acl}   = FusqlFS::Backend::PgSQL::Role::Acl->new('S');
}

=begin testing get

is $_tobj->get('unknown'), undef;

=end testing
=cut
sub get
{
    my $self = shift;
    my ($name) = @_;
    my $result = $self->all_col($self->{exists_expr}, $name);
    return unless @$result;
    return {
        struct => $self->dump($self->one_row($self->{get_expr}, [$name])),
        owner  => $self->{owner},
        acl    => $self->{acl},
    };
}

=begin testing list

cmp_set $_tobj->list(), [];

=end testing
=cut
sub list
{
    my $self = shift;
    return $self->all_col($self->{list_expr}) || [];
}

=begin testing store after create

isnt $_tobj->store('fusqlfs_sequence', $new_sequence), undef;
is_deeply $_tobj->get('fusqlfs_sequence'), $new_sequence;

=end testing
=cut
sub store
{
    my $self = shift;
    my ($name, $data) = @_;
	return unless $data;

    my $struct = $self->validate($data, {
		struct => {
			is_cycled    => '',
			increment_by => qr/^-?\d+$/,
			cache_value  => qr/^-?\d+$/,
			last_value   => qr/^-?\d+$/,
			max_value    => qr/^-?\d+$/,
			min_value    => qr/^-?\d+$/,,
		}
	}) or return;
	$data = $struct->{struct};

    my $sql = "ALTER SEQUENCE \"$name\" ";
    $sql .= $data->{is_cycled}? 'CYCLE ': 'NO CYCLE ' if $data->{is_cycled};

    my $sth = $self->build($sql, sub{
            my ($a, $b) = @_;
            return unless exists $data->{$a};
            if (!defined $data->{$a})
            {
                return "NO $b->[0] " if $b->[2];
                return;
            }
            return "$b->[0] ? ", $data->{$a}, $b->[1];
    }, increment_by => ['INCREMENT BY', SQL_INTEGER, 0],
       cache_value  => ['CACHE', SQL_INTEGER, 0]       ,
       last_value   => ['RESTART WITH', SQL_INTEGER, 0],
       max_value    => ['MAXVALUE', SQL_INTEGER, 1]    ,
       min_value    => ['MINVALUE', SQL_INTEGER, 1]    );

    $sth->execute();
}

=begin testing rename after store

isnt $_tobj->rename('fusqlfs_sequence', 'new_fusqlfs_sequence'), undef;
is $_tobj->get('fusqlfs_sequence'), undef;
is_deeply $_tobj->get('new_fusqlfs_sequence'), $new_sequence;
is_deeply $_tobj->list(), [ 'new_fusqlfs_sequence' ];

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($name, $newname) = @_;
    $self->do($self->{rename_expr}, [$name, $newname]);
}

=begin testing drop after rename

isnt $_tobj->drop('new_fusqlfs_sequence'), undef;
is $_tobj->get('new_fusqlfs_sequence'), undef;
is_deeply $_tobj->list(), [];

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{drop_expr}, [$name]);
}

=begin testing create after get list

isnt $_tobj->create('fusqlfs_sequence'), undef;
is_deeply $_tobj->get('fusqlfs_sequence'), { struct => {
    cache_value => 1,
    increment_by => 1,
    is_called => 0,
    is_cycled => 0,
    last_value => 1,
    log_cnt => 0,
    max_value => 9223372036854775807,
    min_value => 1,
    sequence_name => 'fusqlfs_sequence',
    start_value => 1,
}, owner => $_tobj->{owner}, acl => $_tobj->{acl} };
is_deeply $_tobj->list(), [ 'fusqlfs_sequence' ];

=end testing
=cut
sub create
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{create_expr}, [$name]);
}

1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Test

my $new_sequence = { struct => {
    cache_value => 4,
    increment_by => 2,
    is_called => 0,
    is_cycled => 1,
    last_value => 6,
    log_cnt => 0,
    max_value => 1000,
    min_value => '-10',
    sequence_name => 'fusqlfs_sequence',
    start_value => 1,
}, owner => $_tobj->{owner}, acl => $_tobj->{acl} };

=end testing
=cut
