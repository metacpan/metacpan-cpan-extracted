package Markdent::Types::Internal;

use strict;
use warnings;

our $VERSION = '0.37';

use IO::Handle;

use Specio::Declare;
use Specio::Library::Builtins;

use parent 'Specio::Exporter';

declare(
    'HeaderLevel',
    parent => t('Int'),
    inline => sub {"$_[1] >= 1 && $_[1] <= 6"},
    message_generator =>
        sub {"Header level must be a number from 1-6 (not $_)"},
);

object_does_type(
    'BlockParserDialectRole',
    role => 'Markdent::Role::Dialect::BlockParser',
);

declare(
    'BlockParserClass',
    parent => t('ClassName'),
    inline => sub {
        "$_[1]->can('does') && $_[1]->does('Markdent::Role::BlockParser')";
    },
);

object_does_type(
    'SpanParserDialectRole',
    role => 'Markdent::Role::Dialect::SpanParser',
);

declare(
    'SpanParserClass',
    parent => t('ClassName'),
    inline => sub {
        "$_[1]->can('does') && $_[1]->does('Markdent::Role::SpanParser')";
    },
);

object_does_type(
    'EventObject',
    role => 'Markdent::Role::Event',
);

declare(
    'ExistingFile',
    parent => t('Str'),
    inline => sub {"$_[1] eq '-' || -f $_[1]"},
);

object_does_type(
    'HandlerObject',
    role => 'Markdent::Role::Handler',
);

declare(
    'NonEmptyArrayRef',
    parent => t('ArrayRef'),
    inline => sub {"@{$_[1]} >= 1"},
);

declare(
    'OutputStream',
    parent => t('Item'),
    inline => sub {
        sprintf(
            <<'EOF', t('FileHandle')->inline_check( $_[1] ), t('Object')->inline_check( $_[1] ), $_[1] );
( %s || %s ) && %s->can('print')
EOF
    },
    message_generator => sub {
        'The output stream must be a Perl file handle or an object with a print method';
    },
);

enum(
    'TableCellAlignment',
    values => [qw( left right center )],
);

1;
