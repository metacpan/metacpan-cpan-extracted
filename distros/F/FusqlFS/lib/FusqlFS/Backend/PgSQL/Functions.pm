use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Functions;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Backend::PgSQL::Functions - FusqlFS PostgreSQL database functions
(a.k.a. stored procedures) interface

=head1 SYNOPSIS

    use FusqlFS::Backend::PgSQL::Functions;

    my $funcs = FusqlFS::Backend::PgSQL::Functions->new();

=head1 DESCRIPTION

This is FusqlFS an interface to PostgreSQL database functions (or stored
procedures as they are called in "big DBMS world"). This class is not to be
used by itself.

See L<FusqlFS::Artifact> for description of interface methods,
L<FusqlFS::Backend> to learn more on backend initialization and
L<FusqlFS::Backend::Base> for more info on database backends writing.

=head1 EXPOSED STRUCTURE

=over

=item F<./language>

Symlink to language used to write this function in F<../../languages>.
See L<FusqlFS::Backend::PgSQL::Languages> for details.

=item F<./content.*>

This file have suffix equal to language name used to write this function and
contains this function's body. You can edit it in order to change function's
definition.

=item F<./owner>

Symlink to sequence's owner in F<../../roles>.

=item F<./acl>

Functions's ACL with permissions given to different roles. See
L<FusqlFS::Backend::PgSQL::Role::Acl> for details.

=back

=cut

use FusqlFS::Backend::PgSQL::Role::Owner;
use FusqlFS::Backend::PgSQL::Role::Acl;

sub init
{
    my $self = shift;

    my $pgver = $self->dbh->{pg_server_version};
    my $get_func_args = 'pg_catalog.pg_get_function_arguments(p.oid)';
    my $get_func_res  = 'pg_catalog.pg_get_function_result(p.oid)';

    if ($pgver < 80400)
    {
        $get_func_args = q{CASE WHEN p.proallargtypes IS NOT NULL THEN
    pg_catalog.array_to_string(ARRAY(
      SELECT
        CASE
          WHEN p.proargmodes[s.i] = 'i' THEN ''
          WHEN p.proargmodes[s.i] = 'o' THEN 'OUT '
          WHEN p.proargmodes[s.i] = 'b' THEN 'INOUT '
          WHEN p.proargmodes[s.i] = 'v' THEN 'VARIADIC '
        END ||
        CASE
          WHEN COALESCE(p.proargnames[s.i], '') = '' THEN ''
          ELSE p.proargnames[s.i] || ' '
        END ||
        pg_catalog.format_type(p.proallargtypes[s.i], NULL)
      FROM
        pg_catalog.generate_series(1, pg_catalog.array_upper(p.proallargtypes, 1)) AS s(i)
    ), ', ')
  ELSE
    pg_catalog.array_to_string(ARRAY(
      SELECT
        CASE
          WHEN COALESCE(p.proargnames[s.i+1], '') = '' THEN ''
          ELSE p.proargnames[s.i+1] || ' '
          END ||
        pg_catalog.format_type(p.proargtypes[s.i], NULL)
      FROM
        pg_catalog.generate_series(0, pg_catalog.array_upper(p.proargtypes, 1)) AS s(i)
    ), ', ')
  END};
        $get_func_res = 'pg_catalog.format_type(p.prorettype, NULL)';
    }

    $self->{list_expr} = $self->expr("SELECT DISTINCT p.proname||'('||$get_func_args||')' FROM pg_catalog.pg_proc AS p
                LEFT JOIN pg_catalog.pg_namespace AS ns ON ns.oid = p.pronamespace
            WHERE ns.nspname = 'public'");

    #CASE WHEN p.proisagg THEN NULL ELSE pg_catalog.pg_get_functiondef(p.oid) END AS struct
    $self->{get_expr} = $self->expr("SELECT $get_func_res AS result,
                trim(both from p.prosrc) AS content, l.lanname AS lang,
                CASE p.provolatile WHEN 'i' THEN 'immutable' WHEN 's' THEN 'stable' WHEN 'v' THEN 'volatile' END AS volatility,
                CASE WHEN p.proisagg THEN 'aggregate' WHEN p.proiswindow THEN 'window' WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger' ELSE 'normal' END AS type
            FROM pg_catalog.pg_proc AS p
                LEFT JOIN pg_catalog.pg_language AS l ON l.oid = p.prolang
            WHERE p.proname = ? AND $get_func_args = ?");

    $self->{create_expr} = 'CREATE OR REPLACE FUNCTION %s RETURNS integer LANGUAGE sql AS $function$ SELECT 1; $function$';
    $self->{rename_expr} = 'ALTER FUNCTION %s RENAME TO %s';
    $self->{drop_expr} = 'DROP FUNCTION %s';
    $self->{store_expr} = 'CREATE OR REPLACE FUNCTION %s RETURNS %s LANGUAGE %s AS $function$ %s $function$ %s';

    $self->{owner} = FusqlFS::Backend::PgSQL::Role::Owner->new('_F');
    $self->{acl}   = FusqlFS::Backend::PgSQL::Role::Acl->new('_F');
}

=begin testing get

my $row = $_tobj->get('xxxxx');
is $row, undef, '->get() result is sane';

=end testing
=cut
sub get
{
    my $self = shift;
    my ($name, $args) = split(/\(/, $_[0], 2);
    return unless $args;
    $args =~ s/\)$//;
    my $data = $self->one_row($self->{get_expr}, $name, $args);
    return unless $data;

    my $result = {};
    $result->{language} = \"languages/$data->{lang}";
    $result->{'content.'.delete($data->{lang})} = delete($data->{content});
    $result->{struct} = $self->dump($data);

    $result->{owner} = $self->{owner};
    $result->{acl}   = $self->{acl};

    return $result;
}

=begin testing list

my $list = $_tobj->list();
isa_ok $list, 'ARRAY', '->list() result is an array';
cmp_ok scalar(@$list), '==', 0, '->list() result is empty';

=end testing
=cut
sub list
{
    my $self = shift;
    return $self->all_col($self->{list_expr});
}

=begin testing drop after store

is $_tobj->drop('fusqlfs_func(integer)'), undef;
isnt $_tobj->drop('fusqlfs_func(integer, integer)'), undef;
is_deeply $_tobj->list(), [];
is $_tobj->get('fusqlfs_func(integer, integer)'), undef;

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{drop_expr}, [$name]);
}

=begin testing store after rename

isnt $_tobj->store('fusqlfs_func(integer, integer)', $new_func), undef;
is_deeply $_tobj->get('fusqlfs_func(integer, integer)'), $new_func;

=end testing
=cut
sub store
{
    my $self = shift;
    my ($name, $data) = @_;
    return unless $data;

    my $struct = $self->validate($data, {
        struct => {
            volatility => qr/^(volatile|immutable|stable)$/i,
            type       => qr/^(window|trigger|normal)$/i,
            result     => '',
        },
        language => ['SCALAR', sub{ $$_ =~ /^languages\/(.+)$/ && $1 }],
    }, sub{ $_->{content} = $_[0]->{'content.'.$_->{language}}||undef })
        or return;

    my $opts = ' ';
    $opts .= 'WINDOW ' if $struct->{struct}->{type} eq 'window';
    $opts .= uc $struct->{struct}->{volatility};

    $self->do($self->{store_expr}, [$name, $struct->{struct}->{result}, $struct->{language}, $struct->{content}, $opts]);
}

=begin testing rename after create

isnt $_tobj->rename('fusqlfs_func(integer)', 'fusqlfs_func(integer, integer)'), undef;
is_deeply $_tobj->get('fusqlfs_func(integer, integer)', $created_func), $created_func;
is $_tobj->get('fusqlfs_func(integer)'), undef;
is_deeply $_tobj->list(), [ 'fusqlfs_func(integer, integer)' ];

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($name, $newname) = @_;
    return if $name eq $newname;

    my ($fname, $fargs) = split /\(/, $newname, 2;
    my ($aname, $aargs) = split /\(/, $name, 2;
    if ($fargs eq $aargs)
    {
        $self->do($self->{rename_expr}, [$name, $fname]);
    }
    else
    {
        my $data = $self->get($name);
        $self->drop($name);
        $self->store($newname, $data);
    }
}

=begin testing create after get list

isnt $_tobj->create('fusqlfs_func(integer)'), undef;
is_deeply $_tobj->list(), [ 'fusqlfs_func(integer)' ];
is_deeply $_tobj->get('fusqlfs_func(integer)'), $created_func;

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

my $created_func = {
    'content.sql' => 'SELECT 1;',
    'language' => \'languages/sql',
    'struct' => {
        result => 'integer',
        type => 'normal',
        volatility => 'volatile',
    },
    'owner' => $_tobj->{owner},
    'acl' => $_tobj->{acl},
};

my $new_func = {
    'content.sql' => 'SELECT $1 | $2;',
    'language' => \'languages/sql',
    'struct' => {
        result => 'integer',
        type => 'normal',
        volatility => 'immutable',
    },
    'owner' => $_tobj->{owner},
    'acl' => $_tobj->{acl},
};

=end testing
=cut
