package Fey::Meta::Class::Table;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::Exceptions qw( param_error );
use Fey::Hash::ColumnsKey;
use Fey::Object::Policy;
use Fey::Meta::Attribute::FromInflator;
use Fey::Meta::Attribute::FromColumn;
use Fey::Meta::Attribute::FromSelect;
use Fey::Meta::Class::Schema;
use Fey::Meta::HasOne::ViaFK;
use Fey::Meta::HasOne::ViaSelect;
use Fey::Meta::HasMany::ViaFK;
use Fey::Meta::HasMany::ViaSelect;
use Fey::Meta::Method::Constructor;
use Fey::Meta::Method::FromSelect;
use Fey::ORM::Types
    qw( Bool ClassName CodeRef DoesHasMany DoesHasOne HashRef Object );
use List::AllUtils qw( all );
use Try::Tiny ();

use Moose;
use MooseX::ClassAttribute;
use MooseX::SemiAffordanceAccessor;

extends 'Moose::Meta::Class';

class_has '_ClassToTableMap' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef ['Fey::Table'],
    default => sub { {} },
    lazy    => 1,
    handles => {
        TableForClass     => 'get',
        _SetTableForClass => 'set',
        _ClassHasTable    => 'exists',
    },
);

has '_object_cache_is_enabled' => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

has '_object_cache' => (
    is      => 'ro',
    isa     => HashRef [Object],
    lazy    => 1,
    default => sub { {} },
    clearer => '_clear_object_cache',
);

has 'table' => (
    is        => 'rw',
    isa       => 'Fey::Table',
    writer    => '_set_table',
    predicate => '_has_table',
);

has 'inflators' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef [CodeRef],
    default => sub { {} },
    lazy    => 1,
    handles => {
        _add_inflator => 'set',
        has_inflator  => 'exists',
    },
);

has 'deflators' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef [CodeRef],
    default => sub { {} },
    lazy    => 1,
    handles => {
        deflator_for  => 'get',
        _add_deflator => 'set',
        has_deflator  => 'exists',
    },
);

has 'schema_class' => (
    is      => 'ro',
    isa     => ClassName,
    lazy    => 1,
    default => sub {
        Fey::Meta::Class::Schema->ClassForSchema( $_[0]->table()->schema() );
    },
);

has 'policy' => (
    is      => 'rw',
    isa     => 'Fey::Object::Policy',
    default => sub { Fey::Object::Policy->new() },
);

has '_has_ones' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef [DoesHasOne],
    default => sub { {} },
    lazy    => 1,
    handles => {
        _has_one        => 'get',
        _add_has_one    => 'set',
        _has_has_one    => 'exists',
        has_ones        => 'values',
        _remove_has_one => 'delete',
    },
);

has '_has_manies' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef [DoesHasMany],
    default => sub { {} },
    lazy    => 1,
    handles => {
        _has_many        => 'get',
        _add_has_many    => 'set',
        _has_has_many    => 'exists',
        has_manies       => 'values',
        _remove_has_many => 'delete',
    },
);

has '_select_sql_cache' => (
    is      => 'ro',
    isa     => 'Fey::Hash::ColumnsKey',
    lazy    => 1,
    default => sub { Fey::Hash::ColumnsKey->new() },
);

has '_sql_string_cache' => (
    is      => 'ro',
    isa     => HashRef [HashRef],
    lazy    => 1,
    default => sub {
        { {} }
    },
);

has '_select_by_pk_sql' => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    default => sub { return $_[0]->name()->_MakeSelectByPKSQL() },
);

has '_count_sql' => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_build_count_sql',
);

sub ClassForTable {
    my $class = shift;

    return @_ == 1
        ? $class->_ClassForTable(@_)
        : map { $class->_ClassForTable($_) } @_;
}

sub _ClassForTable {
    my $class = shift;
    my $table = shift;

    my $map = $class->_ClassToTableMap();

    for my $class_name ( keys %{$map} ) {
        my $potential_table = $map->{$class_name};

        return $class_name
            if $potential_table->name() eq $table->name()
            && $potential_table->schema()->name() eq $table->schema()->name();
    }

    return;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _search_cache {
    my $self = shift;
    my $p    = shift;

    my $cache = $self->_object_cache();

    for my $key ( @{ $self->table()->candidate_keys() } ) {
        my @names = map { $_->name() } @{$key};
        next unless all { defined $p->{$_} } @names;

        my $cache_key = join "\0", map { ( $_, $p->{$_} ) } sort @names;

        return $cache->{$cache_key}
            if exists $cache->{$cache_key};
    }
}

sub _write_to_cache {
    my $self   = shift;
    my $object = shift;

    my $cache = $self->_object_cache();

    for my $key ( @{ $self->table()->candidate_keys() } ) {
        my @names = map { $_->name() } @{$key};

        my @pieces = map { ( $_, $object->$_() ) } sort @names;

        next unless all {defined} @pieces;

        my $cache_key = join "\0", @pieces;

        $cache->{$cache_key} = $object;
    }
}

sub _associate_table {
    my $self    = shift;
    my $table   = shift;
    my $context = shift;

    my $caller = $self->name();

    param_error 'Cannot call has_table() more than once per class'
        if $self->_has_table();

    param_error 'Cannot associate the same table with multiple classes'
        if $self->ClassForTable($table);

    param_error 'A table object passed to has_table() must have a schema'
        unless $table->has_schema();

    my $class = Fey::Meta::Class::Schema->ClassForSchema( $table->schema() );

    param_error 'You must load your schema class before calling has_table()'
        unless $class
        && $class->can('meta')
        && $class->meta()->_has_schema();

    param_error
        'A table object passed to has_table() must have at least one key'
        unless @{ $table->primary_key() };

    $self->_SetTableForClass( $self->name() => $table );

    $self->_set_table($table);

    $self->_make_column_attributes($context);
}
## use critic;

sub _make_column_attributes {
    my $self    = shift;
    my $context = shift;

    my $table = $self->table();

    for my $column ( $table->columns() ) {
        my $name = $column->name();

        next if $self->has_method($name);

        my %attr_p = (
            metaclass          => 'Fey::Meta::Attribute::FromColumn',
            is                 => 'rw',
            isa                => $self->_type_for_column($column),
            lazy               => 1,
            default            => sub { $_[0]->_get_column_value($name) },
            column             => $column,
            writer             => q{_set_} . $name,
            clearer            => q{_clear_} . $name,
            predicate          => q{has_} . $name,
            definition_context => $context,
        );

        $self->add_attribute( $name, %attr_p );

        if ( my $transform = $self->policy()->transform_for_column($column) )
        {
            $self->_add_transform( $name, {}, %{$transform} );
        }
    }
}

# XXX - can this be overridden or customized? should it account for
# per-column/policy-level transforms?
{
    my %FeyToMoose = (
        text     => 'Str',
        blob     => 'Str',
        integer  => 'Int',
        float    => 'Num',
        datetime => 'Str',
        date     => 'Str',
        time     => 'Str',
        boolean  => 'Bool',
        other    => 'Value',
    );

    sub _type_for_column {
        my $self   = shift;
        my $column = shift;

        my $type = $FeyToMoose{ $column->generic_type() };

        $type .= q{ | Undef}
            if $column->is_nullable();

        return $type;
    }
}

sub _add_transform {
    my $self    = shift;
    my $name    = shift;
    my $context = shift;
    my %p       = @_;

    my $attr = $self->get_attribute($name);

    param_error "The column $name does not exist as an attribute"
        unless $attr;

    $self->_add_inflator_to_attribute(
        $name,
        $context,
        $attr,
        $p{inflate},
        $p{handles}
    ) if $p{inflate};

    if ( $p{deflate} ) {
        param_error
            "Cannot provide more than one deflator for a column ($name)"
            if $self->has_deflator($name);

        $self->_add_deflator( $name => $p{deflate} );
    }
}

## no critic (Subroutines::ProhibitManyArgs)
sub _add_inflator_to_attribute {
    my $self     = shift;
    my $name     = shift;
    my $context  = shift;
    my $attr     = shift;
    my $inflator = shift;
    my $handles  = shift;

    param_error "Cannot provide more than one inflator for a column ($name)"
        if $attr->isa('Fey::Meta::Attribute::FromInflator');

    $self->remove_attribute($name);

    my $raw_name = $name . q{_raw};

    # XXX - should the private writer invoke the deflator?
    my $raw_attr = $attr->clone(
        name               => $raw_name,
        reader             => $raw_name,
        definition_context => $context,
    );

    $self->add_attribute($raw_attr);

    my $inflated_predicate = q{_has_inflated_} . $name;
    my $inflated_clear     = q{_clear_inflated_} . $name;

    my $default = sub {
        my $self = shift;

        return $self->$inflator( $self->$raw_name() );
    };

    my %handles = $handles ? ( handles => $handles ) : ();

    $self->add_attribute(
        $name,
        metaclass          => 'Fey::Meta::Attribute::FromInflator',
        is                 => 'ro',
        lazy               => 1,
        default            => $default,
        predicate          => $inflated_predicate,
        clearer            => $inflated_clear,
        init_arg           => undef,
        raw_attribute      => $raw_attr,
        inflator           => $inflator,
        definition_context => $context,
        %handles,
    );

    my $clear_inflated = sub {
        my $self = shift;

        $self->$inflated_clear();
    };

    $self->add_after_method_modifier( $raw_attr->clearer(), $clear_inflated );
    $self->add_after_method_modifier( $raw_attr->writer(),  $clear_inflated );

    $self->_add_inflator( $name => $inflator );
}
## use critic

sub add_has_one {
    my $self = shift;
    my %p    = @_;

    param_error 'You must call has_table() before calling has_one().'
        unless $self->_has_table();

    param_error
        'You cannot pass both a select and fk parameter when creating a has-one relationship'
        if $p{select} && $p{fk};

    my $class
        = $p{select}
        ? 'Fey::Meta::HasOne::ViaSelect'
        : 'Fey::Meta::HasOne::ViaFK';

    $p{foreign_table} = delete $p{table};

    $p{is_cached} = delete $p{cache}
        if exists $p{cache};
    $p{allows_undef} = delete $p{undef}
        if exists $p{undef};

    my $has_one = $class->new(
        table => $self->table(),
        namer => $self->policy()->has_one_namer(),
        %p,
    );

    $has_one->attach_to_class($self);

    $self->_add_has_one( $has_one->name() => $has_one );
}

sub remove_has_one {
    my $self = shift;
    my $name = shift;

    return unless $self->_has_has_one($name);

    my $has_one = $self->_has_one($name);

    $has_one->detach_from_class();

    $self->_remove_has_one( $has_one->name() );
}

sub add_has_many {
    my $self = shift;
    my %p    = @_;

    param_error 'You must call has_table() before calling has_many().'
        unless $self->_has_table();

    param_error
        'You cannot pass both a select and fk parameter when creating a has-many relationship'
        if $p{select} && $p{fk};

    my $class
        = $p{select}
        ? 'Fey::Meta::HasMany::ViaSelect'
        : 'Fey::Meta::HasMany::ViaFK';

    $p{foreign_table} = delete $p{table};

    $p{is_cached} = delete $p{cache}
        if exists $p{cache};

    my $has_many = $class->new(
        table => $self->table(),
        namer => $self->policy()->has_many_namer(),
        %p,
    );

    $has_many->attach_to_class($self);

    $self->_add_has_many( $has_many->name() => $has_many );
}

sub remove_has_many {
    my $self = shift;
    my $name = shift;

    return unless $self->_has_has_many($name);

    my $has_many = $self->_has_many($name);

    $has_many->detach_from_class();

    $self->_remove_has_many( $has_many->name() );
}

sub _build_count_sql {
    my $self = shift;

    my $table = $self->table();

    my $select = $self->schema_class()->SQLFactoryClass()->new_select();

    $select->select( Fey::Literal::Function->new( 'COUNT', '*' ) )
        ->from($table);

    return $select;
}

sub add_query_method {
    my $self = shift;

    my $method = Fey::Meta::Method::FromSelect->new(
        package_name => $self->name(),
        @_,
    );

    $self->add_method( $method->name() => $method );

    return;
}

sub make_immutable {
    shift->SUPER::make_immutable(
        @_,
        constructor_class => 'Fey::Meta::Method::Constructor',
    );
}

if ( $Moose::VERSION >= 1.9900 ) {

    # XXX - can we refactor Moose/CMOP core to make overriding (and copying)
    # all of this unnecessary?
    override _inline_new_object => sub {
        my $self = shift;

        #<<<
        return (
            'my $class = shift;',
            '$class = Scalar::Util::blessed($class) || $class;',
            $self->_inline_fallback_constructor('$class'),
            $self->_inline_params( '$params', '$class' ),
            $self->_inline_search_cache(),
            'my $instance;',
            '$class->_ClearConstructorError();',
            'my @args = @_;',
            'Try::Tiny::try {',
                '@_ = @args;',
                $self->_inline_generate_instance( '$instance', '$class' ),
                $self->_inline_slot_initializers,
                $self->_inline_preserve_weak_metaclasses,
                $self->_inline_extra_init,
            '}',
            'Try::Tiny::catch {',
                'die $_ unless Scalar::Util::blessed($_) && $_->isa(q{Fey::Exception::NoSuchRow});',
                '$class->_SetConstructorError($_);',
                'undef $instance;',
            '};',
            'return unless $instance;',
            $self->_inline_write_to_cache(),
            'return $instance',
        );
        #>>>
    };

    # The default version of this sticks a "my" in front of the declaration,
    # but we want to declare the $instance var earlier.
    override _inline_generate_instance => sub {
        my $self = shift;
        my ( $inst, $class ) = @_;
        return (
            $inst . ' = ' . $self->_inline_create_instance($class) . ';',
        );
    };
}

sub _inline_search_cache {
    my $self = shift;

    #<<<
    return
        ( 'if ( $metaclass->_object_cache_is_enabled() ) {',
              'my $cached = $metaclass->_search_cache($params);',
              'return $cached if $cached;',
          '}'
        );
    #>>>
}

sub _inline_write_to_cache {
    my $self = shift;

    return
        '$metaclass->_write_to_cache($instance) if $metaclass->_object_cache_is_enabled();';
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A metaclass for table classes

__END__

=pod

=head1 NAME

Fey::Meta::Class::Table - A metaclass for table classes

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::User;

  use Fey::ORM::Table;

  print __PACKAGE__->meta()->ClassForTable($table);

=head1 DESCRIPTION

This is the metaclass for table classes. When you use
L<Fey::ORM::Table> in your class, it uses this class to do all the
heavy lifting.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Meta::Class::Table->ClassForTable( $table1, $table2 )

Given one or more L<Fey::Table> objects, this method returns the name
of the class which "has" that table, if any.

=head2 Fey::Meta::Class::Table->TableForClass($class)

Given a class, this method returns the L<Fey::Table> object associated
with that class, if any.

=head2 $meta->table()

Returns the L<Fey::Table> for the metaclass's class.

=head2 $meta->add_has_one(%options)

Creates a new L<Fey::Meta::HasOne::ViaFK> or
L<Fey::Meta::HasOne::ViaSelect> object and adds it to the
metaclass. Internally, this will call C<attach_to_class()> on the
C<HasOne> meta-object.

=head2 $meta->has_ones()

Returns a list of the C<HasOne> objects added to this metaclass.

=head2 $meta->remove_has_one($name)

Removes the named C<HasOne> meta-object. Internally, this will call
C<detach_from_class()> on the C<HasOne> meta-object.

=head2 $meta->add_has_many(%options)

Creates a new L<Fey::Meta::HasMany::ViaFK> or
L<Fey::Meta::HasMany::ViaSelect> object and adds it to the
metaclass. Internally, this will call C<attach_to_class()> on the
C<HasMany> meta-object.

=head2 $meta->has_manies()

Returns a list of the C<HasMany> objects added to this metaclass.

=head2 $meta->remove_has_many($name)

Removes the named C<HasMany> meta-object. Internally, this will call
C<detach_from_class()> on the C<HasMany> meta-object.

=head2 $meta->has_inflator($name)

Returns a boolean indicating whether or not there is an inflator
defined for the named column.

=head2 $meta->has_deflator($name)

Returns a boolean indicating whether or not there is an inflator
defined for the named column.

=head2 $meta->add_query_method(%options)

Adds a new L<Fey::Meta::Method::FromSelect> method to the class. The
C<%options> passed to this method will be passed to the
L<Fey::Meta::Method::FromSelect> constructor.

=head2 $meta->make_immutable()

This class overrides C<< Moose::Meta::Class->make_immutable() >> in
order to do its own optimizations for immutability.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
