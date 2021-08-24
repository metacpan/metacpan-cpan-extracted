package Markdown::Compiler::Target::Tree;
use Moo;
use Storable qw( dclone );

has tree => (
    is => 'ro',
);

has tree => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_html',
);

has functions => (
    is  => 'ro',
    lazy => 1,
    default => sub {
        return +{
            'Markdown::Compiler::Parser::Node::Header'                 => 'header', 
            'Markdown::Compiler::Parser::Node::HR'                     => 'hr',
            'Markdown::Compiler::Parser::Node::Paragraph'              => 'paragraph',
            'Markdown::Compiler::Parser::Node::Paragraph::BoldItalic'  => 'paragraph_bolditalic',
            'Markdown::Compiler::Parser::Node::Paragraph::Bold'        => 'paragraph_bold',
            'Markdown::Compiler::Parser::Node::Paragraph::Italic'      => 'paragraph_italic',
            'Markdown::Compiler::Parser::Node::Paragraph::String'      => 'paragraph_string',
            'Markdown::Compiler::Parser::Node::Paragraph::Link'        => 'paragraph_link',
            'Markdown::Compiler::Parser::Node::Paragraph::Image'       => 'paragraph_image',
            'Markdown::Compiler::Parser::Node::Table'                  => 'table',
            'Markdown::Compiler::Parser::Node::Blockquote'             => 'blockquote',
            'Markdown::Compiler::Parser::Node::Codeblock'              => 'codeblock',
            'Markdown::Compiler::Parser::Node::List'                   => 'list',
        }
    }
);

sub _build_tree {
    my ( $self ) = @_;

    return $self->_compile( dclone $self->tree );
}

sub _compile { 
    my ( $self, $tree ) = @_;

    my $str;

    while ( defined ( my $node = shift @{ $tree } ) ) {
        # Children should be compiled first.
        if ( $node->children and @{$node->children} >= 1 ) {

            # If this node can be compiled, then we will compile it, giving it the content
            if ( my $code = $self->can($self->functions->{ref($node)}) ) {
                $str .= $code->($self, $node, $self->_compile($node->children));
                next;
            }
            warn "This is an odd place to be.... children but the parent can't be compiled?";
        }

        # This node has no children to compile.
        else {
            if ( my $code = $self->can($self->functions->{ref($node)}) ) {
                $str .= $code->($self, $node);
                next;
            }

        }
    }
    return $str;
}

sub header {
    my ( $self, $node, $content ) = @_;

    return sprintf( "header( size => ) )

    "header()

    my $header = "h" . $node->size;

    return "<$header>$content</$header>\n\n";

}

sub hr {

}

sub paragraph {
    my ( $self, $node, $content ) = @_;

    return "<p>$content</p>\n\n";

}

sub paragraph_bolditalic {
    my ( $self, $node, $content ) = @_;

    return "<strong><em>$content</em></strong>";

}

sub paragraph_bold {
    my ( $self, $node, $content ) = @_;

    return "<strong>$content</strong>";

}

sub paragraph_italic {
    my ( $self, $node, $content ) = @_;

    return "<em>$content</em>";
}

sub paragraph_string {
    my ( $self, $node ) = @_;

    return $node->content;

}

sub paragraph_link {
    my ( $self, $node ) = @_;

    return sprintf( '<a href="%s" title="%s">%s</a>', 
        $node->href, 
        $node->text  ? $node->text  : "",
        $node->title ? $node->title : "",
    );
}

sub paragraph_image {
    my ( $self, $node ) = @_;

    return sprintf( '<img src="%s" title="%s" alt="%s">', 
        $node->href, 
        $node->text  ? $node->text  : "",
        $node->title ? $node->title : "",
    );
}

sub table {

}

sub blockquote {

}

sub codeblock {

}

sub list {

}





        # package Markdown::Compiler::Parser::Node;
        # package Markdown::Compiler::Parser::Node::Header;
        # package Markdown::Compiler::Parser::Node::HR;
        # package Markdown::Compiler::Parser::Node::Paragraph;
        # package Markdown::Compiler::Parser::Node::Paragraph::BoldItalic;
        # package Markdown::Compiler::Parser::Node::Paragraph::Bold;
        # package Markdown::Compiler::Parser::Node::Paragraph::Italic;
        # package Markdown::Compiler::Parser::Node::Paragraph::String;
        # package Markdown::Compiler::Parser::Node::Paragraph::Link;
        # package Markdown::Compiler::Parser::Node::Paragraph::Image;
        # package Markdown::Compiler::Parser::Node::Table;
        # package Markdown::Compiler::Parser::Node::Blockquote;
        # package Markdown::Compiler::Parser::Node::Codeblock;
        # package Markdown::Compiler::Parser::Node::List;



1;

