package Markdent::Types::Internal;

use strict;
use warnings;

our $VERSION = '0.26';

use IO::Handle;

use MooseX::Types 0.20 -declare => [
    qw(
        BlockParserClass
        BlockParserDialectRole
        EventObject
        ExistingFile
        HandlerObject
        HeaderLevel
        NonEmptyArrayRef
        OutputStream
        PosInt
        SpanParserClass
        SpanParserDialectRole
        TableCellAlignment
        )
];

use MooseX::Types::Moose qw(
    ArrayRef
    ClassName
    FileHandle
    Int
    Item
    Object
    Str
);

#<<<
subtype HeaderLevel,
    as Int,
    where { $_ >= 1 && $_ <= 6 },
    message { "Header level must be a number from 1-6 (not $_)" };

role_type BlockParserDialectRole, { role => 'Markdent::Role::Dialect::BlockParser' };

subtype BlockParserClass,
    as ClassName,
    where { $_->can('does') && $_->does('Markdent::Role::BlockParser') };

role_type SpanParserDialectRole, { role => 'Markdent::Role::Dialect::SpanParser' };

subtype SpanParserClass,
    as ClassName,
    where { $_->can('does') && $_->does('Markdent::Role::SpanParser') };

subtype EventObject,
    as Object,
    where { $_->can('does') && $_->does('Markdent::Role::Event') };

subtype ExistingFile,
    as Str,
    where { -f $_ };

subtype HandlerObject,
    as Object,
    where { $_->can('does') && $_->does('Markdent::Role::Handler') };

subtype NonEmptyArrayRef,
    as ArrayRef,
    where { @{$_} >= 1 };

subtype OutputStream,
    as Item,
    where {
        FileHandle()->check($_)
            || ( Object()->check($_) && $_->can('print') );
    },
    message { 'The output stream must be a Perl file handle or an object with a print method' };

enum TableCellAlignment, [qw( left right center )];

subtype PosInt,
    as Int,
    where { $_ >= 1 },
    message { "The number provided ($_) is not a positive integer" };
#>>>

1;
