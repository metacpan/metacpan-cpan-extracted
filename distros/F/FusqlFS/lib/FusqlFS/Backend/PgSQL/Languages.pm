use strict;
use 5.010;

=head1 NAME

FusqlFS::Backend::PgSQL::Languages - FusqlFS class to interface with PostgreSQL languages

=head1 SYNOPSIS

    use FusqlFS::Backend::PgSQL::Languages;

    my $languages = FusqlFS::Backend::PgSQL::Languages->new();
    $languages->create('plperl');
    my $data = $languages->get('plperl');
    $data->{struct} =~ s/^trusted: 0$/trusted: 1/m;
    $languages->store('plperl', $data);

=head1 DESCRIPTION

This class is used by L<FusqlFS::Backend::PgSQL> to represent F<languages> subtree and not to be used by itself.

=head1 EXPOSED STRUCTURE

=over

=item F<./handler>, F<./validator>

Symlinks to functions in F<../../functions> set as handler and validator for the language.

=item F<./struct>

Formatted info about language:

=over

=item C<ispl>

I<boolean> true is it's a procedural language (true for all languages except for special internal handlers).

=item C<trusted>

I<boolean> true for trusted languages, i.e. languages usable by non-superusers.

=back

=item F<./owner>

Synlink to language owner role in F<../../roles>.

=back

=head1 METHODS

=over

=cut

package FusqlFS::Backend::PgSQL::Languages;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

use FusqlFS::Backend::PgSQL::Role::Owner;

=item new

Class constructor.

Output: $languages_instance.

=begin testing new

my $instance = {_tpkg}->new();
isa_ok $instance, $_tcls;

=end testing
=cut
sub init
{
    my $self = shift;

    $self->{get_expr} = $self->expr('SELECT l.lanispl AS ispl, l.lanpltrusted AS trusted,
            hp.proname||\'(\'||pg_catalog.pg_get_function_arguments(hp.oid)||\')\' AS handler,
            vp.proname||\'(\'||pg_catalog.pg_get_function_arguments(vp.oid)||\')\' AS validator
        FROM pg_catalog.pg_language AS l
            LEFT JOIN pg_catalog.pg_proc AS hp ON (l.lanplcallfoid = hp.oid)
            LEFT JOIN pg_catalog.pg_proc AS vp ON (l.lanvalidator = vp.oid)
        WHERE lanname = ?');
    $self->{list_expr} = $self->expr('SELECT lanname FROM pg_catalog.pg_language');

    $self->{create_expr} = 'CREATE LANGUAGE %s';
    $self->{drop_expr} = 'DROP LANGUAGE %s';
    $self->{rename_expr} = 'ALTER LANGUAGE %s RENAME TO %s';

    $self->{owner} = FusqlFS::Backend::PgSQL::Role::Owner->new('_L');
}

=item get

=begin testing get

is $_tobj->get('xxxxxx'), undef;
my $data = $_tobj->get('internal');
is_deeply $data, {
    owner => $_tobj->{owner},
    validator => \"functions/fmgr_internal_validator(oid)",
    struct => { ispl => 0, trusted => 0, },
};

=end testing
=cut
sub get
{
    my $self = shift;
    my ($name) = @_;
    my $data = $self->one_row($self->{get_expr}, $name);
    return unless $data;

    my $result = {};
    $result->{handler}   = \"functions/$data->{handler}"   if $data->{handler};
    $result->{validator} = \"functions/$data->{validator}" if $data->{validator};
    delete $data->{handler};
    delete $data->{validator};

    $result->{struct} = $self->dump($data);
    $result->{owner}  = $self->{owner};

    return $result;
}

=item list

=begin testing list

my $list = $_tobj->list();
isa_ok $list, 'ARRAY';
cmp_set $list, [ qw(c internal sql plpgsql) ];

=end testing
=cut
sub list
{
    my $self = shift;
    return $self->all_col($self->{list_expr});
}

=item drop

=begin testing drop after rename

isnt $_tobj->drop('plperl1'), undef;
cmp_set $_tobj->list(), [ qw(c internal sql plpgsql) ];
is $_tobj->get('plperl1'), undef;

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{drop_expr}, [$name]);
}

=item create

=begin testing create after get list

isnt $_tobj->create('plperl'), undef;
is_deeply $_tobj->get('plperl'), $new_lang;
cmp_set $_tobj->list(), [ qw(c internal sql plpgsql plperl) ];

=end testing
=cut
sub create
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{create_expr}, [$name]);
}

=item rename

=begin testing rename after store

isnt $_tobj->rename('plperl', 'plperl1'), undef;
cmp_set $_tobj->list(), [ qw(c internal sql plpgsql plperl1) ];
is $_tobj->get('plperl'), undef;
is_deeply $_tobj->get('plperl1'), $new_lang;

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($name, $newname) = @_;
    $self->do($self->{rename_expr}, [$name, $newname]);
}

=item store

=begin testing store after create

isnt $_tobj->store('plperl', $new_lang), undef;
is_deeply $_tobj->get('plperl'), $new_lang;

=end testing
=cut
sub store
{
    my $self = shift;
    my ($name, $data) = @_;
	return unless $data;

    my $struct = $self->validate($data, {
		-validator => ['SCALAR', sub { $$_ =~ /^functions\/(\S+)\(.*\)$/ && $1 }],
		-handler   => ['SCALAR', sub { $$_ =~ /^functions\/(\S+)\(.*\)$/ && $1 }],
		struct    => {
			trusted => '',
			ispl    => '',
		}
	}, sub{ exists $_->{validator} || exists $_->{handler} })
        or return;

    my $trusted = $struct->{struct}->{trusted}? 'TRUSTED ': '';
    my $sql = "CREATE ${trusted}LANGUAGE $name";
    $sql .= ' '.uc($_).' '.$struct->{$_} foreach (qw(handler validator));

    $self->drop($name) and $self->do($sql);
}

1;

__END__

=back

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Test

my $new_lang = {
    owner     => $_tobj->{owner},
    handler   => \"functions/plperl_call_handler()",
    validator => \"functions/plperl_validator(oid)",
    struct    => { ispl => 1, trusted => 1 },
};

=end testing
=cut
