package Markdown::Compiler::Target::Plogitty;
use Moo;
extends 'Markdown::Compiler::Target::HTML';

sub codeblock {
    my ( $self, $node, $content ) = @_;

    return "<div class=\"mermaid\">\n$content\n</div>\n\n"
        if $node->{language} and $node->{language} eq 'mermaid';

    return $node->{language}
        ? "<pre><code class=\"" . $node->{language} . "\">\n$content\n</code></pre>\n\n"
        : "<pre><code class=\"plaintext\">\n$content\n</code></pre>\n\n";
}

sub paragraph_image {
    my ( $self, $node ) = @_;

    if ( $node->{title} ) {
        return sprintf( '<img class="img-fluid" src="%s" title="%s" alt="%s">',
            $node->{href},
            $node->{title},
            $node->{text}
        );
    } else {
        return sprintf( '<img class="img-fluid" src="%s" alt="%s">',
            $node->{href},
            $node->{text} ? $node->{text} : $node->{href},
        );
    }
}

## 
#sub table_cell {
#    my ( $self, $node, $content ) = @_;
#    
#    return sprintf( "<td>%s%s</td>\n", $node->{content}, $content );
#
#}
#
#sub table_row {
#    my ( $self, $node, $content ) = @_;
#    
#    return "<tr>\n$content</tr>\n";
#}

sub table {
    my ( $self, $node, $content ) = @_;

    return "<table class='table'>\n$content</table>\n\n";
}

sub ordered_list {
    my ( $self, $node, $content ) = @_;

    return qq|<ol>\n$content\n</ol>\n|;

}

sub unordered_list {
    my ( $self, $node, $content ) = @_;

    return qq|<li>\n$content\n</li>\n|;

}

sub list_item {
    my ( $self, $node, $content ) = @_;

    return qq|<li>$content</li>\n|;

}

sub list_item_string {
    my ( $self, $node ) = @_;

    return $node->{content};
}

1;
