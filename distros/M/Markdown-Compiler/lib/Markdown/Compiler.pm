# ABSTRACT: Perl Markdown Compiler
package Markdown::Compiler;
use Moo;
use Markdown::Compiler::Lexer;
use Markdown::Compiler::Parser;
use Markdown::Compiler::Target::HTML;
use Module::Runtime qw( use_module );

has source => (
    is       => 'ro',
    required => 1,
);

has lexer => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        Markdown::Compiler::Lexer->new( source => shift->source );
    },
);

has parser => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        Markdown::Compiler::Parser->new( stream => shift->stream );
    },
);

has stream => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        shift->lexer->tokens;
    },
);

has tree => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        shift->parser->tree;
    },
);

has compiler => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        Markdown::Compiler::Target::HTML->new( tree => shift->tree );
    },
);

sub compiler_for {
    my ( $self, $target ) = @_;

    $target = substr($target,0,1) eq '+'
        ? substr($target,1)
        : 'Markdown::Compiler::Target::' . $target;

    return use_module("$target")->new( tree => $self->tree );
}

has result => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        shift->compiler->result;
    }
);

has metadata => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        shift->compiler->metadata;
    }
);

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Compiler - A Markdown Compiler

=head1 DESCRIPTION

Markdown::Compiler makes it easy to customize the rendering of a Markdown document.

Markdown::Compiler parses Markdown documents with a hand-rolled lexer and parser.  A compiler then turns the parse tree into the target document.

The stream of tokens from the lexer and the parse tree itself as easily dumped.

=head1 SYNOPSIS

=head1 CONSTRUCTOR

=head2 source

=head2 lexer

=head2 parser

=head2 compiler

=head1 METHODS

=head2 lexer

=head2 parser

=head2 stream

=head2 tree

=head2 compiler

=head2 result

=head2 metadata

=head1 AUTHOR

Kaitlyn Parkhurst (SymKat) I<E<lt>symkat@symkat.comE<gt>> ( Blog: L<http://symkat.com/> )

=head1 CONTRIBUTORS

=head1 COPYRIGHT

Copyright (c) 2021 the Markdown::Compiler L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=head1 AVAILABILITY

The most current version of Markdown::Compiler can be found at L<https://github.com/symkat/Markdown-Compiler>

