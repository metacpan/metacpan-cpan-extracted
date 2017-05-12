use strict;
use 5.010;

=head1 NAME

FusqlFS::Backend::PgSQL::Table::Triggers

=head1 SYNOPSIS

    use FusqlFS::Backend::PgSQL::Table::Triggers

    my $triggers = FusqlFS::Backend::PgSQL::Table::Triggers->new();

=head1 DESCRIPTION

=head1 EXPOSED STRUCTURE

=over

=item F<./handler>

Symlink to function in F<../../../../functions>, which executes on trigger event(s).

=item F<./create.sql>

C<CREATE TRIGGER> clause to create this trigger.

=item F<./struct>

Additional trigger info with following fields:

=over

=item C<for_each>

I<one of row or statement> defines if trigger will be triggered for each touched row or once for whole statement.

=item C<when>

I<one of before or after> defines if trigger is triggered before or after event(s).

=item C<events>

I<set of insert, update, delete, truncate> list of events trigger will be triggered on.

=back

=back

=head1 METHODS

=over

=cut

package FusqlFS::Backend::PgSQL::Table::Triggers;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact::Table::Lazy';

=item new

Class constructor.

Output: $triggers_instance.

=begin testing new

my $triggers = {_tpkg}->new();
isa_ok $triggers, $_tcls;

=end testing
=cut
sub init
{
    my $self = shift;

    # tgtype:
    # 0  1 = for each row
    # 1  2 = before
    # 2  4 = insert
    # 3  8 = delete
    # 4 16 = update
    # 5 32 = truncate (?)
    $self->{get_expr} = $self->expr('SELECT pg_catalog.pg_get_triggerdef(t.oid) AS "create.sql",
            p.proname||\'(\'||pg_catalog.pg_get_function_arguments(p.oid)||\')\' AS handler,
            CASE WHEN (t.tgtype & 1) != 0 THEN \'row\' ELSE \'statement\' END AS for_each,
            CASE WHEN (t.tgtype & 2) != 0 THEN \'before\' ELSE \'after\' END AS when,
            ARRAY[
                CASE WHEN (t.tgtype &  4) != 0 THEN \'insert\' END,
                CASE WHEN (t.tgtype &  8) != 0 THEN \'delete\' END,
                CASE WHEN (t.tgtype & 16) != 0 THEN \'update\' END,
                CASE WHEN (t.tgtype & 32) != 0 THEN \'truncate\' END
                ] AS events
        FROM pg_catalog.pg_trigger AS t
            LEFT JOIN pg_catalog.pg_class AS r ON (t.tgrelid = r.oid)
            LEFT JOIN pg_catalog.pg_proc AS p ON (t.tgfoid = p.oid)
        WHERE r.relname = ? AND t.tgname = ? AND t.tgconstraint = 0');
    $self->{list_expr} = $self->expr('SELECT t.tgname FROM pg_catalog.pg_trigger AS t
        LEFT JOIN pg_catalog.pg_class AS r ON (t.tgrelid = r.oid) WHERE r.relname = ?');

    $self->{rename_expr} = 'ALTER TRIGGER %s ON %s RENAME TO %s';
    $self->{drop_expr} = 'DROP TRIGGER %s ON %s';
    $self->{store_expr} = 'CREATE TRIGGER %s %s %s ON %s FOR EACH %s EXECUTE PROCEDURE %s';

    $self->{template} = {
        'struct' => $self->dump({
            events => [
                'insert',
                'update',
                'delete',
            ],
            for_each => 'row',
            when => 'before',
        }),
    };
}

=item get

=begin testing get

is $_tobj->get('fusqlfs_table', 'xxxxx'), undef;
is $_tobj->get('xxxxx', 'xxxxx'), undef;

=end testing
=cut
sub get
{
    my $self = shift;
    my ($table, $name) = @_;

    unless ($self->SUPER::get($table, $name))
    {
        my $data = $self->one_row($self->{get_expr}, $table, $name);
        return unless $data;

        my $result = {};

        $data->{events} = [ grep $_, @{$data->{events}} ];

        $result->{handler} = \"functions/$data->{handler}";
        delete $data->{handler};

        $result->{'create.sql'} = delete($data->{'create.sql'});
        $result->{struct} = $self->dump($data);

        return $result;
    }
}

=item list

=begin testing list

cmp_set $_tobj->list('fusqlfs_table'), [];

=end testing
=cut
sub list
{
    my $self = shift;
    my ($table) = @_;
    return [ @{$self->all_col($self->{list_expr}, $table)}, @{$self->SUPER::list($table)} ];
}

=item drop

=begin testing drop after rename

is $_tobj->drop('fusqlfs_table', 'fusqlfs_trigger'), undef;
isnt $_tobj->drop('fusqlfs_table', 'new_fusqlfs_trigger'), undef;
cmp_set $_tobj->list('fusqlfs_table'), [];
is $_tobj->get('fusqlfs_table', 'fusqlfs_trigger'), undef;

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->SUPER::drop($table, $name) or $self->do($self->{drop_expr}, [$name, $table]);
}

=item store

=begin testing store after get list

isnt $_tobj->create('fusqlfs_table', 'fusqlfs_trigger'), undef;
cmp_set $_tobj->list('fusqlfs_table'), [ 'fusqlfs_trigger' ];
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_trigger'), $_tobj->{template};

isnt $_tobj->store('fusqlfs_table', 'fusqlfs_trigger', $new_trigger), undef;
cmp_set $_tobj->list('fusqlfs_table'), [ 'fusqlfs_trigger' ];
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_trigger'), $new_trigger;

=end testing
=cut
sub store
{
    my $self = shift;
    my ($table, $name, $data) = @_;
    return unless $data;

    my $struct = $self->validate($data, {
        struct => {
            when     => qr/^(before|after)$/i,
            for_each => qr/^(row|statement)$/i,
            events   => $self->set_of(qw(insert update delete truncate)),
        },
        handler => ['SCALAR', sub{ $$_ =~ /^functions\/(\S+\(.*\))$/ && $1 }]
    }) or return;

    my $when     = uc($struct->{struct}->{when});
    my $for_each = uc($struct->{struct}->{for_each});
    my $events   = join ' OR ', map { uc $_ } @{$struct->{struct}->{events}};
    my $handler  = $struct->{handler};

    $self->drop($table, $name) and $self->do($self->{store_expr}, [$name, $when, $events, $table, $for_each, $handler]);
}

=item rename

=begin testing rename after store

isnt $_tobj->rename('fusqlfs_table', 'fusqlfs_trigger', 'new_fusqlfs_trigger'), undef;
is $_tobj->get('fusqlfs_table', 'fusqlfs_trigger'), undef;
$new_trigger->{'create.sql'} =~ s/TRIGGER fusqlfs_trigger/TRIGGER new_fusqlfs_trigger/;
is_deeply $_tobj->get('fusqlfs_table', 'new_fusqlfs_trigger'), $new_trigger;
cmp_set $_tobj->list('fusqlfs_table'), [ 'new_fusqlfs_trigger' ];

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($table, $name, $newname) = @_;
    $self->SUPER::rename($table, $name, $newname)
        or $self->do($self->{rename_expr}, [$name, $table, $newname]);
}

1;

__END__

=back

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Table::Test

my $new_trigger = {
    'create.sql' => 'CREATE TRIGGER fusqlfs_trigger BEFORE INSERT OR UPDATE ON fusqlfs_table FOR EACH ROW EXECUTE PROCEDURE fusqlfs_function()',
    handler => \'functions/fusqlfs_function()',
    struct => {
        events => [ 'insert', 'update' ],
        for_each => 'row',
        when => 'before',
    },
};

=end testing

