package Fey::Types::Internal;

use strict;
use warnings;

our $VERSION = '0.44';

use List::AllUtils qw( all );
use overload ();
use Scalar::Util qw( blessed );

use MooseX::Types -declare => [
    qw(
        ArrayRefOfColumns
        ArrayRefOfFunctionArgs
        CanQuote
        Column
        ColumnLikeOrName
        ColumnOrName
        ColumnWithTable
        DefaultValue
        FunctionArg
        FK
        GenericTypeName
        GroupByElement
        IntoElement
        LiteralTermArg
        Named
        NamedObjectSet
        NonNullableInsertValue
        NonNullableUpdateValue
        NullableInsertValue
        NullableUpdateValue
        OrderByElement
        OuterJoinType
        PosInteger
        PosOrZeroInteger
        SelectElement
        SetOperationArg
        Schema
        Table
        TableLikeOrName
        TableOrName
        WhereBoolean
        WhereClause
        WhereClauseSide
        )
];

use MooseX::Types::Moose
    qw( ArrayRef Defined Int Item Object Str Undef Value );

subtype GenericTypeName, as Str, where {
    /^(?:text|blob|integer|float|date|datetime|time|boolean|other)$/xism
};

subtype PosInteger, as Int, where { $_ > 0 };

subtype PosOrZeroInteger, as Int, where { $_ >= 0 };

role_type DefaultValue, { role => 'Fey::Role::IsLiteral' };

coerce DefaultValue,
    from Undef, via { Fey::Literal::Null->new() },
    from Value, via { Fey::Literal->new_from_scalar($_) };

class_type NamedObjectSet, { class => 'Fey::NamedObjectSet' };

class_type Column, { class => 'Fey::Column' };

subtype ArrayRefOfColumns, as ArrayRef [Column], where {
    @{$_} >= 1
};

coerce ArrayRefOfColumns, from Column, via { [$_] };

role_type Named, { role => 'Fey::Role::Named' };

subtype FunctionArg, as Object,
    where { $_->can('does') && $_->does('Fey::Role::Selectable') };

coerce FunctionArg,
    from Undef, via { Fey::Literal::Null->new() },
    from Value, via { Fey::Literal->new_from_scalar($_) };

subtype ArrayRefOfFunctionArgs, as ArrayRef [FunctionArg];

coerce ArrayRefOfFunctionArgs, from ArrayRef, via {
    [ map { FunctionArg->coerce($_) } @{$_} ];
};

subtype LiteralTermArg, as ArrayRef, where {
    return unless $_ and @{$_};
    all {
        blessed($_)
            ? $_->can('sql_or_alias') || overload::Overloaded($_)
            : defined && !ref;
    }
    @{$_};
};

coerce LiteralTermArg, from Value, via { [$_] };

for my $thing (
    [ 'Table',  'Fey::Table',  TableOrName,  TableLikeOrName ],
    [ 'Column', 'Fey::Column', ColumnOrName, ColumnLikeOrName ]
    ) {
    my ( $thing, $class, $name_type, $like_type ) = @$thing;

    subtype $name_type, as Item, where {
        return   unless defined $_;
        return 1 unless blessed $_;
        return $_->isa($class);
    };

    subtype $like_type, as Item, where {
        return   unless defined $_;
        return 1 unless blessed $_;
        return   unless $_->can('does');
        return $_->can('does') && $_->does( 'Fey::Role::' . $thing . 'Like' );
    };
}

role_type SetOperationArg, { role => 'Fey::Role::SQL::ReturnsData' };

subtype SelectElement, as Item, where {
    !blessed $_[0]
        || $_[0]->isa('Fey::Table')
        || $_[0]->isa('Fey::Table::Alias')
        || ( $_[0]->can('is_selectable')
        && $_[0]->is_selectable() );
};

subtype ColumnWithTable, as Column, where {
    $_[0]->has_table();
};

subtype IntoElement, as Object, where {
    return $_->isa('Fey::Table')
        || ( $_->isa('Fey::Column')
        && $_->table()
        && !$_->table()->is_alias() );
};

subtype NullableInsertValue, as Item, where {
    !blessed $_
        || (
        $_->can('does')
        && (   $_->does('Fey::Role::IsLiteral')
            || $_->does('Fey::Role::SQL::ReturnsData') )
        )
        || $_->isa('Fey::Placeholder')
        || overload::Overloaded($_);
};

subtype NonNullableInsertValue, as Defined, where {
    !blessed $_
        || (
        $_->can('does')
        && (   $_->does('Fey::Role::IsLiteral')
            || $_->does('Fey::Role::SQL::ReturnsData') )
        && !$_->isa('Fey::Literal::Null')
        )
        || $_->isa('Fey::Placeholder')
        || overload::Overloaded($_);
};

subtype NullableUpdateValue, as Item, where {
    !blessed $_
        || $_->isa('Fey::Column')
        || (
        $_->can('does')
        && (   $_->does('Fey::Role::IsLiteral')
            || $_->does('Fey::Role::SQL::ReturnsData') )
        )
        || $_->isa('Fey::Placeholder')
        || overload::Overloaded($_);
};

subtype NonNullableUpdateValue, as Defined, where {
    !blessed $_
        || $_->isa('Fey::Column')
        || (
        $_->can('does')
        && (   $_->does('Fey::Role::IsLiteral')
            || $_->does('Fey::Role::SQL::ReturnsData') )
        && !$_->isa('Fey::Literal::Null')
        )
        || $_->isa('Fey::Placeholder')
        || overload::Overloaded($_);
};

subtype OrderByElement, as Item, where {
    if ( !blessed $_ ) {
        return $_ =~ /^(?:asc|desc)(?: nulls (?:last|first))?$/i;
    }

    return 1
        if $_->can('is_orderable')
        && $_->is_orderable();
};

subtype GroupByElement, as Object, where {
    return 1
        if $_->can('is_groupable')
        && $_->is_groupable();
};

subtype OuterJoinType, as Str, where { return $_ =~ /^(?:full|left|right)$/ };

subtype CanQuote, as Item,
    where { return $_->isa('DBI::db') || $_->can('quote') };

subtype WhereBoolean, as Str, where { return $_ =~ /^(?:AND|OR)$/ };

subtype WhereClauseSide, as Item, where {
    return 1 if !defined $_;
    return 0 if ref $_ && !blessed $_;
    return 1 unless blessed $_;
    return 1 if overload::Overloaded($_);

    return 1
        if $_->can('is_comparable')
        && $_->is_comparable();
};

class_type WhereClause, { class => 'Fey::SQL::Where' };

class_type Table, { class => 'Fey::Table' };

class_type Schema, { class => 'Fey::Schema' };

class_type FK, { class => 'Fey::FK' };

1;

# ABSTRACT: Types for use in Fey

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Types::Internal - Types for use in Fey

=head1 VERSION

version 0.44

=head1 DESCRIPTION

This module defines a whole bunch of types used by the Fey core
classes. None of these types are documented for external use at the
present, though that could change in the future.

=head1 BUGS

See L<Fey> for details on how to report bugs.

Bugs may be submitted at L<https://github.com/ap/Fey/issues>.

=head1 SOURCE

The source code repository for Fey can be found at L<https://github.com/ap/Fey>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2025 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
