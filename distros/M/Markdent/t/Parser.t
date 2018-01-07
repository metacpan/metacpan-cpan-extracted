use strict;
use warnings;

use Test2::V0;

use Markdent::Dialect::Theory::BlockParser;
use Markdent::Handler::MinimalTree;
use Markdent::Parser;

use lib 't/lib';

my $handler = Markdent::Handler::MinimalTree->new();

{
    my $parser = Markdent::Parser->new(
        dialects => 'Theory',
        handler  => $handler,
    );

    ok(
        $parser->_block_parser()->meta()
            ->does_role('Markdent::Dialect::Theory::BlockParser'),
        '$parser->_block_parser() with dialects = Theory'
    );

    ok(
        $parser->_span_parser()->meta()
            ->does_role('Markdent::Dialect::Theory::SpanParser'),
        '$parser->_span_parser() with dialects = Theory'
    );
}

{
    my $parser = Markdent::Parser->new(
        dialects => ['Theory'],
        handler  => $handler,
    );

    ok(
        $parser->_block_parser()->meta()
            ->does_role('Markdent::Dialect::Theory::BlockParser'),
        '$parser->_block_parser() with dialects = [Theory]'
    );

    ok(
        $parser->_span_parser()->meta()
            ->does_role('Markdent::Dialect::Theory::SpanParser'),
        '$parser->_span_parser() with dialects = [Theory]'
    );
}

{
    is(
        dies {
            my $parser = Markdent::Parser->new(
                dialects           => 'Theory',
                block_parser_class => 'Markdent::Parser::BlockParser',
                handler            => $handler,
            );
        },
        undef,
        'Can combine an explicit block_parser_class with a dialect'
    );
}

{
    my $parser = Markdent::Parser->new(
        dialects => ['Example::Dialect'],
        handler  => $handler,
    );

    ok(
        $parser->_block_parser()->meta()
            ->does_role('Example::Dialect::BlockParser'),
        '$parser->_block_parser() with dialects = Example::Dialect'
    );

    ok(
        $parser->_span_parser()->meta()
            ->does_role('Example::Dialect::SpanParser'),
        '$parser->_span_parser() with dialects = Example::Dialect'
    );
}

{
    my $parser = Markdent::Parser->new(
        dialects => ['Example::Dialect2'],
        handler  => $handler,
    );

    ok(
        $parser->_span_parser()->meta()
            ->does_role('Example::Dialect2::SpanParser'),
        '$parser->_span_parser() with dialects = Example::Dialect2 - only provides a SpanParser class'
    );
}

{
    my $parser = Markdent::Parser->new(
        dialect => 'Theory',
        handler => $handler,
    );

    ok(
        $parser->_block_parser()->meta()
            ->does_role('Markdent::Dialect::Theory::BlockParser'),
        '$parser->_block_parser() with dialect = Theory (dialect as synonym for dialects)'
    );

    ok(
        $parser->_span_parser()->meta()
            ->does_role('Markdent::Dialect::Theory::SpanParser'),
        '$parser->_span_parser() with dialect = Theory (dialect as synonym for dialects)'
    );
}

done_testing();
