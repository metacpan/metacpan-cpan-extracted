package Markdown::Compiler::Test;
use warnings;
use strict;
use Test::More;
use Test::Deep;
use Test::Differences;
use Import::Into;
use Exporter;
use Markdown::Compiler;
use Markdown::Compiler::Lexer;
use Markdown::Compiler::Parser;
use Markdown::Compiler::Target::HTML;
use Data::Dumper::Concise;

push our @ISA, qw( Exporter );
push our @EXPORT, qw( build_and_test _test_dump_lexer _test_dump_parser _test_dump_html );

sub import {
    shift->export_to_level(1);
    
    my $target = caller;

    warnings->import::into($target);
    strict->import::into($target);
    Test::More->import::into($target);
    Test::Deep->import::into($target);
}

# build_and_test
#
# source can be:
#       1. string ->
#       2. hash   ->
#       3. code   ->
#
# expect can be:
#       code_name => arguments ( &_test_run_$code_name($compiler,$arguments) )
sub build_and_test {
    my ( $name, $source, $expects ) = @_;
    my ( undef, $file, $line ) = caller;

    if ( ref($source) and ( ref($source) ne 'CODE' or ref($source) ne 'HASH' ) ) {
        die "Error: Invalid type for \$source @ $file:$line. Must be HASH, CODE or plain string.\n";
    }

    my $compiler = ref($source) eq 'HASH'
        ? Markdown::Compiler->new( %{$source} )
        : ref($source) eq 'CODE'
            ? $source->()
            : Markdown::Compiler->new( source => $source );

    foreach my $expect ( @{$expects} ) {
        my $method_name = shift @{$expect};

        my $test = __PACKAGE__->can( "_test_run_$method_name" )
            or die "Invalid test function: $method_name @ $file:$line\n";

        $test->($compiler, $name, $file, $line, @{$expect});
    }

    return $compiler;
}

sub _test_run_dump_lexer {
    my ( $compiler, $name, $file, $line, @args ) = @_;

    foreach my $token ( @{$compiler->lexer->tokens} ) {
        ( my $content = $token->content  ) =~ s/\n//g;
        printf( "%20s | %s\n", $content, $token->type );
    }
}

sub _test_run_dump_parser {
    my ( $compiler, $name, $file, $line, @args ) = @_;

    my $tree = $compiler->parser->tree;

    print Dumper($tree);
}

sub _test_run_dump_result {
    my ( $compiler, $name, $file, $line, @args ) = @_;

    print "=== HTML ===\n" . $compiler->result . "\n=== END ===\n\n";
}

# Paragraph
# String
# String
# String => [ content => 'foo', children => '' ],
#
# 
# 
# 
#
#
sub _test_run_assert_parse_tree {
    my ( $compiler, $name, $file, $line, @args ) = @_;

    my $tree = $compiler->parser->tree;

    print Dumper($tree);
}

sub _test_run_assert_parser {
    my ( $compiler, $name, $file, $line, $match ) = @_;

    my $tree = $compiler->parser->tree;

    cmp_deeply( $tree, $match, sprintf( "%s:%d: %s", $file, $line, $name ) );
}

sub _test_run_assert_lexer {
    my ( $compiler, $name, $file, $line, $match ) = @_;

    my @stream = map { ref($_) } @{$compiler->parser->stream};

    cmp_deeply( \@stream, $match, sprintf( "%s:%d: %s", $file, $line, $name ) );
}


# This one I need to think through!
sub _test_run_result_is {
    my ( $compiler, $name, $file, $line, $match ) = @_;

    if ( ref($match) eq 'REGEXP' ) {
        ok( $compiler->result =~ $match, sprintf( "%s:%d: %s", $file, $line, $name ) );
    } else {
        eq_or_diff ( $compiler->result, $match, sprintf( "%s:%d: %s", $file, $line, $name ) );
    }
}

sub _test_run_metadata_is {
    my ( $compiler, $name, $file, $line, $match ) = @_;

    cmp_deeply( $compiler->parser->metadata, $match, sprintf( "%s:%d: %s", $file, $line, $name ) );
}


1;
