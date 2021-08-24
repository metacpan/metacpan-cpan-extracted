package Markdown::Compiler::Parser;
BEGIN {
    {
        package Markdown::Compiler::Parser::Node;
        use Moo;

        has tokens => (
            is       => 'ro',
            required => 1,
        );
        
        has children => (
            is       => 'ro',
        );

        has content => (
            is => 'ro',
        );

        1;
    }

    {
        package Markdown::Compiler::Parser::Node::Metadata;
        use Moo;
        extends 'Markdown::Compiler::Parser::Node';

        has data => (
            is => 'ro',
        );

        # content => $content,
        # tokens  => [ @tree ],
        # data    => $struct,
        1;
    }

    {
        package Markdown::Compiler::Parser::Node::Metadata::Key;
        use Moo;
        extends 'Markdown::Compiler::Parser::Node';

        1;
    }

    {
        package Markdown::Compiler::Parser::Node::Metadata::Value;
        use Moo;
        extends 'Markdown::Compiler::Parser::Node';

        1;
    }
}
use Moo;

has stream => (
    is       => 'ro',
    required => 1,
);

has tree => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_tree',
);

has htree => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_htree',
);

has metadata => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_metadata',
);


sub _build_tree {
    my ( $self ) = @_;

    my @tokens = @{$self->stream};

    return $self->make_hash($self->_parse(\@tokens));
}

sub make_hash {
    my ( $self, $tokens ) = @_;

    my @stream;

    foreach my $token ( @{$tokens} ) {

        if ( ref($token) eq 'HASH' ) {
            if ( $token->{children} && @{$token->{children}} >= 1 ) {
                $token->{children} = [ $self->make_hash( $token->{children} ) ];
            }
            push @stream, $token;
        } else {
            push @stream, {
                class   => ref($token),
                tokens  => [ $token->tokens ],
                ( $token->can('data')     && $token->data     ? ( data     => $token->data                           ) : () ),
                ( $token->can('href')     && $token->href     ? ( href     => $token->href                           ) : () ),
                ( $token->can('title')    && $token->title    ? ( title    => $token->title                          ) : () ),
                ( $token->can('size')     && $token->size     ? ( size     => $token->size                           ) : () ),
                ( $token->can('text')     && $token->text     ? ( text     => $token->text                           ) : () ),
                ( $token->can('language') && $token->language ? ( language => $token->language                       ) : () ),
                ( $token->can('content')  && $token->content  ? ( content  => $token->content                        ) : () ),
                ( $token->can('children') && $token->children ? ( children => [ $self->make_hash($token->children) ] ) : () ),
            };
        }
    }

    return [ @stream ];
}

sub _build_metadata {
    my ( $self ) = @_;

    if ( $self->tree->[0] and $self->tree->[0]->{class} eq 'Markdown::Compiler::Parser::Node::Metadata' ) {
        return $self->tree->[0]->{data};
    }
    return undef;
}

sub _parse {
    my ( $self, $tokens ) = @_;
    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Header
        if ( $token->type eq 'Header' ) {
            push @tree, {
                class => 'Markdown::Compiler::Parser::Node::Header',
                size     => $token->size,
                title    => $token->title,
#                tokens   => [ $token ],
                content  => $token->content,
                children => [ $self->_parse_paragraph(Markdown::Compiler->new( source => $token->title )->lexer->tokens)  ],
            };
            next;
        }

        # Paragraphs
        elsif ( grep { $token->type eq $_ } ( qw( EscapedChar Image Link Word Char Bold Italic BoldItalic InlineCode ) ) ) {
            unshift @{$tokens}, $token; # Put the token back and go to paragraph context.
            push @tree, {
                class => 'Markdown::Compiler::Parser::Node::Paragraph',
                children => [ $self->_parse_paragraph( $tokens ) ],
            };

            next;
        }
        
        # HR
        elsif ( $token->type eq 'HR' ) {
            # When is an HR not an HR? -- When it's actually the beginning
            # of metadata.  If this is the first token, then we are dealing
            # with metadata, not an HR.
            if ( $token->start == 0 ) {
                push @tree, Markdown::Compiler::Parser::Node::Metadata->new(
                    %{ $self->_parse_metadata($tokens) },
                );
                    # language => $token->language,
                    # tokens   => [ $token ],
                    # children => [ $self->_parse_metadata( $tokens ) ],
                next;
            }

            # Otherwise, we just have a simple HR token.
            push @tree, {
                class => 'Markdown::Compiler::Parser::Node::HR',
#                tokens   => [ $token ],
            };
            next;
        }

        # Tables
        elsif ( $token->type eq 'TableStart' ) {
            unshift @{$tokens}, $token; # Put the token back and go to table context.
            push @tree, {
                class    => 'Markdown::Compiler::Parser::Node::Table',
#                tokens   => [ $token ],
                children => [ $self->_parse_table( $tokens ) ],
            };
            next;
        }
        
        # Blockquotes
        elsif ( $token->type eq 'BlockQuote' ) {
            push @tree, { 
                class    => 'Markdown::Compiler::Parser::Node::BlockQuote',
#                tokens   => [ $token ],
                children => [ $self->_parse_blockquote( $tokens ) ],
            };
            next;
        }
        
        # Code Blocks
        elsif ( $token->type eq 'CodeBlock' ) {
            push @tree, {
                class    => 'Markdown::Compiler::Parser::Node::CodeBlock',
                language => $token->language,
#                tokens   => [ $token ],
                children => [ $self->_parse_codeblock( $tokens ) ],
            };
            next;
        }
        
        # Lists
        elsif ( $token->type eq 'Item' ) {
            # Put the item token back so that _parse_list knows what kind it is.
            unshift @{$tokens}, $token;
            push @tree, $self->_parse_list( $tokens );
            next;
        }

        # Tokens To Ignore
        elsif ( grep { $token->type eq $_ } ( qw( LineBreak ) ) ) {
            # Do Nothing.
            next;
        }

        # Unknown Token?
        else {
            use Data::Dumper::Concise;
            die "Parser::_parse() could not handle token " . $token->type . " on line " . $token->line;
        }
    }
    return [ @tree ];
}

sub _parse_paragraph {
    my ( $self, $tokens ) = @_;

    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions:
        #
        #   - No more tokens (after while loop)
        #   - Two new line tokens in a rwo (first one is eaten)
        if ( $token->type eq 'LineBreak' ) {
            if ( exists $tokens->[0] and $tokens->[0]->type eq 'LineBreak' ) {
                # Double Line Break, Bail Out
                return @tree;
            }
            # Single Line Break - Ignore
            next;
        }
        # Exit Conditions Continued:
        #
        #    - Tokens which are invalid in this context, put the token back and return our @ree
        if ( grep { $token->type eq $_ } (qw(TableStart CodeBlock BlockQuote List HR Header)) ) {
            unshift @$tokens, $token;
            return @tree;
        }


        # Parsing
        if ( grep { $token->type eq $_ } (qw(EscapedChar Space Word Char)) ) {
            push @tree, {
                class   => 'Markdown::Compiler::Parser::Node::Paragraph::String',
                content => $token->content,
#                tokens  => [ $token ],
            };
            next;
        }

        if ( grep { $token->type eq $_ } (qw(Link)) ) {
            push @tree, {
                class   => 'Markdown::Compiler::Parser::Node::Paragraph::Link',
                text    => $token->text,
                title   => $token->title,
                href    => $token->href,
#                tokens  => [ $token ],
            };
            next;
        }
        
        if ( $token->type eq 'Image' ) {
            push @tree, {
                class   => 'Markdown::Compiler::Parser::Node::Paragraph::Image',
                text    => $token->text,
                title   => $token->title,
                href    => $token->href,
#                tokens  => [ $token ],
            };
            next;
        }

        if ( $token->type eq 'InlineCode' ) {
            my @todo;

            # Eat tokens until the next Bold block, these tokens will be recursively processed.
            while ( defined ( my $todo_token = shift @{ $tokens } ) ) {
                last if $todo_token->type eq 'InlineCode';

                # Don't cross linebreak boundries
                if ( $todo_token->type eq 'LineBreak' ) {
                    unshift @{$tokens}, $todo_token;
                    last;
                }

                push @todo, $todo_token;
            }

            # Handle the children as plain strings.
            push @tree, {
                class   => 'Markdown::Compiler::Parser::Node::Paragraph::InlineCode',
                content => $token->content,
#                tokens  => [ $token ],
                children => [ 
                    map { +{
                        class   => 'Markdown::Compiler::Parser::Node::Paragraph::String',
                        content => $_->content,
                        tokens  => [ $_ ],
                    } } @todo
                ],
            };
            next;
        }
        
        if ( $token->type eq 'BoldItalic' ) {
            my @todo;

            # Eat tokens until the next BoldItalic block, these tokens will be recursively processed.
            while ( defined ( my $todo_token = shift @{ $tokens } ) ) {
                last if $todo_token->type eq 'BoldItalic';

                # Don't cross linebreak boundries
                if ( $todo_token->type eq 'LineBreak' ) {
                    unshift @{$tokens}, $todo_token;
                    last;
                }

                push @todo, $todo_token;
            }

            # Process the children with _parse_paragraph.
            push @tree, {
                class    => 'Markdown::Compiler::Parser::Node::Paragraph::BoldItalic',
                content  => $token->content,
#                tokens   => [ $token ],
                children => [ $self->_parse_paragraph( \@todo ) ],
            };
            next;
        }
        
        if ( $token->type eq 'Bold' ) {
            my @todo;

            # Eat tokens until the next Bold block, these tokens will be recursively processed.
            while ( defined ( my $todo_token = shift @{ $tokens } ) ) {
                last if $todo_token->type eq 'Bold';

                # Don't cross linebreak boundries
                if ( $todo_token->type eq 'LineBreak' ) {
                    unshift @{$tokens}, $todo_token;
                    last;
                }

                push @todo, $todo_token;
            }

            # Process the children with _parse_paragraph.
            push @tree, {
                class    => 'Markdown::Compiler::Parser::Node::Paragraph::Bold',
                content  => $token->content,
#                tokens   => [ $token ],
                children => [ $self->_parse_paragraph( \@todo ) ],
            };
            next;
        }

        if ( $token->type eq 'Italic' ) {
            my @todo;

            # Eat tokens until the next Italic block, these tokens will be recursively processed.
            while ( defined ( my $todo_token = shift @{ $tokens } ) ) {
                last if $todo_token->type eq 'Italic';

                # Don't cross linebreak boundries
                if ( $todo_token->type eq 'LineBreak' ) {
                    unshift @{$tokens}, $todo_token;
                    last;
                }

                push @todo, $todo_token;
            }

            # Process the children with _parse_paragraph.
            push @tree, {
                class    => 'Markdown::Compiler::Parser::Node::Paragraph::Italic',
                content  => $token->content,
#                tokens   => [ $token ],
                children => [ $self->_parse_paragraph( \@todo ) ],
            };
            next;
        }
        
        # Unknown Token?
        else {
            die "Parser::_parse_paragraph() could not handle token " . $token->{type};
        }
    }
    return @tree;
}

sub _parse_table_row {
    my ( $self, $tokens ) = @_;
    
    my @tree;

    # We must eat from here to 
    while ( my $token = shift @{ $tokens } ) {
        last if $token->type eq 'LineBreak';

        my @todo;
        # Eat all of the tokens from here until the next |
        while ( defined ( my $todo_token = shift @{ $tokens } ) ) {
            last if $todo_token->type eq 'Char' and $todo_token->content eq '|';
            last if $todo_token->type eq 'LineBreak';
            push @todo, $todo_token;
        }
        push @tree, {
            class    => 'Markdown::Compiler::Parser::Node::Table::Cell',
            content  => $token->content,
#            tokens   => [ $token ],
            children => [ $self->_parse_paragraph( \@todo ) ],
        };
        next;
    }

    return @tree;
}

sub _parse_table_header_row {
    my ( $self, $tokens ) = @_;
    
    my @tree;

    # We must eat from here to 
    while ( my $token = shift @{ $tokens } ) {
        last if $token->type eq 'LineBreak';

        my @todo;
        # Eat all of the tokens from here until the next |
        while ( defined ( my $todo_token = shift @{ $tokens } ) ) {
            last if $todo_token->type eq 'Char' and $todo_token->content eq '|';
            last if $todo_token->type eq 'LineBreak';
            push @todo, $todo_token;
        }
        push @tree, {
            class    => 'Markdown::Compiler::Parser::Node::Table::HeaderCell',
            content  => $token->content,
#            tokens   => [ $token ],
            children => [ $self->_parse_paragraph( \@todo ) ],
        };
        next;
    }

    return @tree;
}

sub _parse_table {
    my ( $self, $tokens ) = @_;
    
    my @tree;

    my $is_first_row = 1;
    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions:
        #
        #   - Line break and no more tokens (after while loop)
        #   - Line break, and another line break.
        if ( $token->type eq 'LineBreak' ) {
            return @tree unless @$tokens;
            return @tree if $tokens->[0]->type eq 'LineBreak';
        }

        if ( $token->type eq 'TableStart' ) {
            my @todo;

            # Eat tokens until the next Italic block, these tokens will be recursively processed.
            while ( defined ( my $todo_token = shift @{ $tokens } ) ) {
                last if $todo_token->type eq 'TableStart';

                # Don't cross linebreak boundries
                if ( $todo_token->type eq 'LineBreak' ) {
                    unshift @{$tokens}, $todo_token;
                    last;
                }

                push @todo, $todo_token;
            }

            # Process the children with _parse_paragraph.
            if ( $is_first_row ) {
                push @tree, {
                    class    => 'Markdown::Compiler::Parser::Node::Table::Row',
                    content  => $token->content,
    #                tokens   => [ $token ],
                    children => [ $self->_parse_table_header_row( \@todo ) ],
                };
                $is_first_row = 0;
            } else {
                push @tree, {
                    class    => 'Markdown::Compiler::Parser::Node::Table::Row',
                    content  => $token->content,
    #                tokens   => [ $token ],
                    children => [ $self->_parse_table_row( \@todo ) ],
                };
            }
            next;
        }
    }
    return @tree;
}

sub _parse_table_2 {
    my ( $self, $tokens ) = @_;
        # Token Types:
        # package Markdown::Compiler::Lexer;
        # package Markdown::Compiler::Lexer::Token;
        # package Markdown::Compiler::Lexer::Token::EscapedChar;
        # package Markdown::Compiler::Lexer::Token::CodeBlock;
        # package Markdown::Compiler::Lexer::Token::HR;
        # package Markdown::Compiler::Lexer::Token::Image;
        # package Markdown::Compiler::Lexer::Token::Link;
        # package Markdown::Compiler::Lexer::Token::Item;
        # package Markdown::Compiler::Lexer::Token::TableStart;
        # package Markdown::Compiler::Lexer::Token::TableHeaderSep;
        # package Markdown::Compiler::Lexer::Token::BlockQuote;
        # package Markdown::Compiler::Lexer::Token::Header;
        # package Markdown::Compiler::Lexer::Token::Bold;
        # package Markdown::Compiler::Lexer::Token::Italic;
        # package Markdown::Compiler::Lexer::Token::BoldItalic;
        # package Markdown::Compiler::Lexer::Token::BoldItalicMaker;
        # package Markdown::Compiler::Lexer::Token::LineBreak;
        # package Markdown::Compiler::Lexer::Token::Space;
        # package Markdown::Compiler::Lexer::Token::Word;
        # package Markdown::Compiler::Lexer::Token::Char;

}

sub _parse_blockquote {
    my ( $self, $tokens ) = @_;

    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions:
        #
        #   - Line break and no more tokens (after while loop)
        #   - Line break, and another line break.
        if ( $token->type eq 'LineBreak' ) {
            return @tree unless @$tokens;
            return @tree if $tokens->[0]->type eq 'LineBreak';
        }

        next if $token->type eq 'BlockQuote';

        push @tree, {
            class   => 'Markdown::Compiler::Parser::Node::BlockQuote::String',
            content => $token->content,
#            tokens  => [ $token ],
        };
    }
    return @tree;
}

sub _parse_codeblock {
    my ( $self, $tokens ) = @_;

    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions:
        #
        #   - No more tokens (after while loop)
        #   - Run into the next CodeBlock token.
        if ( $token->type eq 'CodeBlock' ) {
            return @tree;
        }
        
        push @tree, {
            class   => 'Markdown::Compiler::Parser::Node::CodeBlock::String',
            content => $token->content,
#            tokens  => [ $token ],
        };
    }
    return @tree;
}

# Lists are:
#
# Ordered ( Numbered )
#       List Item (Paragraph-like Processing)
#       New Line terminates (We'll ignore that space-carry-on bullshit for now)
#       Match Order Preceeding (Spaces before Item), and go to next List Item OR return tree
#
# Unordered ( Bulleted)
# 
#
# Functions:
# 
# _parse_list_unordered( $offset_for_next_match, $tokens )
# _parse_list_ordered( $offset_for_next_match, $tokens  )
# _parse_list_item( $tokens )
#
#
#

sub _parse_list_item {
    my ( $self, $tokens ) = @_;

    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions:
        #
        #   - No more tokens (after while loop)
        #   - Run into the next CodeBlock token.
        if ( $token->type eq 'LineBreak' ) {
            return @tree;
        }

        # Handle links in list
        if ( $token->type eq 'Link' ) {
            push @tree, { 
                class   => 'Markdown::Compiler::Parser::Node::Paragraph::Link',
                text    => $token->text,
                title   => $token->title,
                href    => $token->href,
#                tokens  => [ $token ],
            };
            next;
        }

        push @tree, {
            class   => 'Markdown::Compiler::Parser::Node::List::Item::String',
            content => $token->content,
#            tokens  => [ $token ],
        };
    }

    return @tree;
}

sub _parse_list_ordered {
    my ( $self, $lvl, $tokens ) = @_;

    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions.
        #
        # If we hit any linebreak we go back to _parse_list to handle it.
        if ( $token->type eq 'LineBreak' ) {
            unshift @{$tokens}, $token;
            return @tree;

        }

        # Handle the next item ( root level )
        elsif ( $lvl == 0 and $token->type eq 'Item' ) {
            push @tree, {
                class    => 'Markdown::Compiler::Parser::Node::List::Ordered::Item',
#                tokens   => [ $token ],
                children => [ $self->_parse_list_item( $tokens ) ],
            };
            next;
        }

        # Transitioning from level 1 to 0 doesn't use the space method below,
        # it uses this one here.
        elsif ( $token->type eq 'Item' ) {
            # Put the space/item token back, return our tree.
            unshift @{$tokens}, $token;
            return @tree;
        }

        # Handle Space
        elsif ( $token->type eq 'Space' ) {
            # warn "After this space token is a " . $tokens->[0]->type . " with " . $tokens->[0]->content . " content\n";
            # Case: This is the ordering level for this invocation, stay in this list.
            if ( $token->length == $lvl ) {
                $token = shift @{$tokens};
                if ( $token->type eq 'Word' ) { # Golden, correct stay-in-list level
                    $token = shift @{$tokens}
                        if $tokens->[0]->{type} eq 'Space'; # The space before the Item
                    push @tree, {
                        class    => 'Markdown::Compiler::Parser::Node::List::Ordered::Item',
#                        tokens   => [ $token ],
                        children => [ $self->_parse_list_item( $tokens ) ],
                    };
                    next;
                }
                die "Error: It shouldn't have gotten here, we're fucked";
            }

            # Case: This list is now complete, the next request was for the next parent item.
            elsif ( $token->length < $lvl or $token->type eq 'Item' ) {
                # Put the space/item token back, return our tree.
                unshift @{$tokens}, $token;
                return @tree;
            }


            # Case: This is a new list, existing under the last Item
            elsif ( $token->length > $lvl ) {
                if ( $token->content =~ /^\d+\.\s+$/ ) {
                    unshift @{$tokens}, $token;
                    push @tree, {
                        class    => 'Markdown::Compiler::Parser::Node::List::Ordered',
#                        tokens   => [ ],
                        children => [ $self->_parse_list_ordered( $token->length, $tokens ) ]
                    };
                    next;
                } else {
                    unshift @{$tokens}, $token;
                    push @tree, {
                        class    => 'Markdown::Compiler::Parser::Node::List::Unordered',
#                        tokens   => [ ],
                        children => [ $self->_parse_list_unordered( $token->{length}, $tokens ) ]
                    };
                    next;
                }
            }

            else {
                die "Parser::_parse_list_unordered() could not handle token " . $token->type;
            }

        }
    }
    return @tree;
}

sub _parse_list_unordered {
    my ( $self, $lvl, $tokens ) = @_;

    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions.
        #
        # If we hit any linebreak we go back to _parse_list to handle it.
        if ( $token->type eq 'LineBreak' ) {
            unshift @{$tokens}, $token;
            return @tree;

        }

        # Handle the next item ( root level )
        elsif ( $lvl == 0 and $token->type eq 'Item' ) {
            push @tree, { 
                class    => 'Markdown::Compiler::Parser::Node::List::Unordered::Item',
#                tokens   => [ $token ],
                children => [ $self->_parse_list_item( $tokens ) ],
            };
            next;
        }

        # Transitioning from level 1 to 0 doesn't use the space method below,
        # it uses this one here.
        elsif ( $token->type eq 'Item' ) {
            # Put the space/item token back, return our tree.
            unshift @{$tokens}, $token;
            return @tree;
        }

        # Handle Space
        elsif ( $token->type eq 'Space' ) {
            # warn "After this space token is a " . $tokens->[0]->type . " with " . $tokens->[0]->content . " content\n";
            # Case: This is the ordering level for this invocation, stay in this list.
            if ( $token->length == $lvl ) {
                $token = shift @{$tokens};
                if ( $token->type eq 'Char' ) { # Golden, correct stay-in-list level
                    $token = shift @{$tokens}
                        if $tokens->[0]->type eq 'Space'; # The space before the Item
                    push @tree, {
                        class    => 'Markdown::Compiler::Parser::Node::List::Unordered::Item',
#                        tokens   => [ $token ],
                        children => [ $self->_parse_list_item( $tokens ) ],
                    };
                    next;
                }
                die "Error: It shouldn't have gotten here, we're fucked";
            }

            # Case: This list is now complete, the next request was for the next parent item.
            elsif ( $token->length < $lvl or $token->type eq 'Item' ) {
                # Put the space/item token back, return our tree.
                unshift @{$tokens}, $token;
                return @tree;
            }

            # Case: This is a new list, existing under the last Item
            elsif ( $token->length > $lvl ) {
                if ( $token->content =~ /^\d+\.\s+$/ ) {
                    unshift @{$tokens}, $token;
                    push @tree, {
                        class    => 'Markdown::Compiler::Parser::Node::List::Ordered',
#                        tokens   => [ ],
                        children => [ $self->_parse_list_ordered( $token->length, $tokens ) ]
                    };
                    next;
                } else {
                    unshift @{$tokens}, $token;
                    push @tree, {
                        class    => 'Markdown::Compiler::Parser::Node::List::Unordered',
#                        tokens   => [ ],
                        children => [ $self->_parse_list_unordered( $token->length, $tokens ) ]
                    };
                    next;
                }
            }


            else {
                die "Parser::_parse_list_unordered() could not handle token " . $token->type;
            }

        }
    }
    return @tree;
}

sub _parse_list {
    my ( $self, $tokens ) = @_;

    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions:
        #
        #   - No more tokens (after while loop)
        #   - Two new line tokens in a rwo (first one is eaten)
        if ( $token->type eq 'LineBreak' ) {
            if ( exists $tokens->[0] and $tokens->[0]->type eq 'LineBreak' ) {
                # Double Line Break, Bail Out
                warn "See the bail out condition.... in _parse_list\n";
                return @tree;
            }
            # Single Line Break - Ignore
            next;
        }
        # Exit Conditions Continued:
        #
        #    - Tokens which are invalid in this context, put the token back and return our @ree
        if ( grep { $token->type eq $_ } (qw(Char Word TableStart CodeBlock BlockQuote List HR Header)) ) {
            unshift @$tokens, $token;
            return @tree;
        }
        
        if ( $token->type eq 'Item' ) {
            if ( $token->content =~ /^\d+\.\s+$/ ) {
                unshift @{$tokens}, $token;
                push @tree, {
                    class    => 'Markdown::Compiler::Parser::Node::List::Ordered',
#                    tokens   => [ ],
                    children => [ $self->_parse_list_ordered( 0, $tokens ) ]
                };
                next;
            } else {
                unshift @{$tokens}, $token;
                push @tree, {
                    class    => 'Markdown::Compiler::Parser::Node::List::Unordered',
#                    tokens   => [ ],
                    children => [ $self->_parse_list_unordered( 0, $tokens ) ]
                };
                next;
            }
        }
        
        die "Parser::_parse_list() could not handle token " . $token->type;

    }
    return @tree;

        # Token Types:
        # package Markdown::Compiler::Lexer;
        # package Markdown::Compiler::Lexer::Token;
        # package Markdown::Compiler::Lexer::Token::EscapedChar;
        # package Markdown::Compiler::Lexer::Token::CodeBlock;
        # package Markdown::Compiler::Lexer::Token::HR;
        # package Markdown::Compiler::Lexer::Token::Image;
        # package Markdown::Compiler::Lexer::Token::Link;
        # package Markdown::Compiler::Lexer::Token::Item;
        # package Markdown::Compiler::Lexer::Token::TableStart;
        # package Markdown::Compiler::Lexer::Token::TableHeaderSep;
        # package Markdown::Compiler::Lexer::Token::BlockQuote;
        # package Markdown::Compiler::Lexer::Token::Header;
        # package Markdown::Compiler::Lexer::Token::Bold;
        # package Markdown::Compiler::Lexer::Token::Italic;
        # package Markdown::Compiler::Lexer::Token::BoldItalic;
        # package Markdown::Compiler::Lexer::Token::BoldItalicMaker;
        # package Markdown::Compiler::Lexer::Token::LineBreak;
        # package Markdown::Compiler::Lexer::Token::Space;
        # package Markdown::Compiler::Lexer::Token::Word;
        # package Markdown::Compiler::Lexer::Token::Char;
}

sub _parse_metadata {
    my ( $self, $tokens ) = @_;

    my @tree;

    while ( defined ( my $token = shift @{ $tokens } ) ) {
        # Exit Conditions:
        #
        #     - We run into the HR block.
        if ( $token->type eq 'HR' ) {
            last;
        }

        if ( grep { $token->type eq $_ } ( qw( EscapedChar Space Word Char LineBreak  ) ) ) {
            push @tree, $token;
            next;
        }

        die "Parser::_parse_metadata() could not handle token " . $token->type;
    }


    my $content = join "", map { $_->content } @tree;

    require YAML::XS;
    my $struct = YAML::XS::Load( $content );


    return {
        content => $content,
        tokens  => [ @tree ],
        data    => $struct,
    };
}

sub show_tree {
    my ( $self ) = @_;

    print $self->_pretty_print(0, $self->tree);
}

sub _pretty_print {
    my ( $self, $index, $tokens ) = @_;

    $index ||= 0;
    my $str;

    foreach my $token ( @{$tokens} ) {

        my $tab = " " x ( $index x 2 );

        my $class = ref($token);
        $class =~ s|Markdown::Compiler::Parser::Node::||;

        my $content = join "", map { $_->content } (@{$token->tokens});
        $content =~ s/\n/\\n/g;
        $content =~ s/\r/\\n/g;

        $str .= 
            " " x ( $index * 2 ) .
            sprintf( '%-' . (35 - ($index * 2)) . 's', $class ) .
            "| $content\n";

        $str .= $self->_pretty_print( $index + 1, $token->children )
            if $token->children;
    }
    return $str;
}




1;
