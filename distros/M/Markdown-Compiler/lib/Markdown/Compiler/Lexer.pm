package Markdown::Compiler::Lexer;
BEGIN {
    {
        package Markdown::Compiler::Lexer::Token;
        use Moo;

        has source => (
            is       => 'ro',
            required => 1,
        );

        has start => (
            is       => 'ro',
            required => 1,
        );
        
        has end => (
            is       => 'ro',
            required => 1,
        );

        has line => (
            is       => 'ro',
            lazy    => 1,
            builder => sub {
                my $self = shift;

                my $lines = grep { $_ eq "\n" } (split(//, substr(${$self->source}, 0, $self->start)));
                return $lines;
            },
        );

        has content => (
            is      => 'ro',
            lazy    => 1,
            builder => sub { 
                my $self = shift;  
                return substr( ${$self->source}, $self->start, ( $self->end - $self->start ) );
            },
        );

        # Allow to overide, for example to return multiple tokens.
        sub tokens {
            return shift;
        }

        1;
    }
    {
        package Markdown::Compiler::Lexer::Token::EscapedChar;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'EscapedChar' }
        sub match { [ qr/\G(\\\\|\\\`|\\\*|\\\_|\\\{|\\\}|\\\[|\\\]|\\\(|\\\)|\\\#|\\\+|\\\-|\\\.|\\\!)/ ] }

        # Delete the first \
        around content => sub {
            my $orig = shift;
            my $value = $orig->(@_);

            return substr($value,1);
        };

        1;
    }
    {
        package Markdown::Compiler::Lexer::Token::CodeBlock;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'CodeBlock' }
        sub match {[
            qr|\G\`\`\`(?:\n\|$)|,
            qr|\G\`\`\`[ ]*\S+[ ]*\n|,
        ]}



        has language => (
            is      => 'ro',
            lazy    => 1,
            builder => sub {
                my $content = shift->content;

                if ( $content =~ m|\`\`\`[ ]*(\S+)[ ]*\n| ) {
                    return $1;
                }
                return undef;
            }
        );

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::HR;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'HR' }
        sub match { [ qr/\G(?:(?<=^)|(?<=\n))((?:(\*\s*\*\s*\*)|(-\s*-\s*-)|(_\s*_\s*_))[-_*\s]*)\n/ ] }
        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::Image;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';
        use Regexp::Common qw( URI );

        # Regexp::Common::URI doesn't support fragments, I should make a patch for it.
        my $url_match = qr/$RE{URI}{HTTP}{ -scheme => 'https?' }(?:\#[A-z0-9-_]+)?/;

        sub type  { 'Image' }
#        sub match {[
#            qr/\G\!\[(.*)\]\(($url_match)\s+"([^"]+)"\s*\)/,
#            qr/\G\!\[(.*)\]\(($url_match\s*)\)/,
#            qr/\G\!($url_match)/,
#        ]}
        sub match {[
            qr/\G\!\[(.*)\]\(([^ ]+)\s+"([^"]+)"\s*\)/,
            qr/\G\!\[(.*)\]\(([^ ]+\s*)\)/,
            qr/\G\!($url_match)/,
        ]}

        has text => (
            is      => 'ro',
            lazy    => 1,
            builder => sub { shift->data->{text} },
        );

        has href => (
            is      => 'ro',
            lazy    => 1,
            builder => sub { shift->data->{href} },
        );

        has title => (
            is      => 'ro',
            lazy    => 1,
            builder => sub { shift->data->{title} },
        );

        has data => (
            is      => 'ro',
            lazy    => 1,
            builder => sub {
                my $content = shift->content;

                if ( $content =~ /!\[(.*)\]\(([^ ]+)\s+"([^"]+)"\s*\)/ ) {
                    return {
                        text  => $1,
                        href  => $2,
                        title => $3,
                    }
                } elsif ( $content =~ /!\[(.*)\]\(([^ ]+\s*)\)/ ) {
                    return {
                        text  => $1,
                        href  => $2,
                        title => undef,
                    }
                } elsif ( $content =~ /!($url_match)/ ) {
                    return {
                        text  => undef,
                        href  => $1,
                        title => undef,
                    };
                }
            }
        );

        1;
    }
    {
        package Markdown::Compiler::Lexer::Token::Link;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';
        use Regexp::Common qw( URI );

        # Regexp::Common::URI doesn't support fragments, I should make a patch for it.
        my $url_match = qr/$RE{URI}{HTTP}{ -scheme => 'https?' }(?:#[A-z0-9-_]+)?(?=[ )])/;

        sub type  { 'Link' }
            # qr/\G\[.*\]\($url_match\s+"([^"]+)"\s*\)/,
            # qr/\G\[.*\]\($url_match\)/,
            # qr/\G$url_match/,
        sub match {[ 
            qr/\G\[.*?\]\($url_match\s+"([^"]+)"\s*\)/,
            qr/\G\[.*?\]\($url_match\)/,
            qr/\G$url_match/,
            qr/\G$RE{URI}{HTTP}{ -scheme => 'https?' }/,
        ]}

        has text => (
            is      => 'ro',
            lazy    => 1,
            builder => sub { shift->data->{text} },
        );

        has title => (
            is      => 'ro',
            lazy    => 1,
            builder => sub { shift->data->{title} },
        );

        has href => (
            is      => 'ro',
            lazy    => 1,
            builder => sub { shift->data->{href} },
        );

        has data => (
            is      => 'ro',
            lazy    => 1,
            builder => sub {
                my $content = shift->content;

                if ( $content =~ /\[(.*)\]\(($url_match)\s+"([^"]+)"\s*\)/ ) {
                    return {
                        text  => $1,
                        href  => $2,
                        title => $3,
                    };
                } elsif ( $content =~ /\[(.*)\]\(($url_match\s*)\)/ ) {
                    return {
                        text  => $1,
                        href  => $2,
                        title => undef,
                    };
                } elsif ( $content =~ /($url_match)/ ) {
                    return {
                        text  => undef,
                        href  => $1,
                        title => undef,
                    };
                } elsif ( $content =~ /($RE{URI}{HTTP}{ -scheme => 'https?' })/ ) {
                    return {
                        text  => undef,
                        href  => $1,
                        title => undef,
                    };
                }
            },
        );

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::Item;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'Item' }
        sub match { [
            # Unordered / Beginning of line, then * + or -
            qr/\G(?:(?<=^)|(?<=\n))(?:\*|\+|\-) /,

            # Numbered / Beginning of line, [number].[space]
            qr/\G(?:(?<=^)|(?<=\n))\d+\.\s+/,
        ]}

        # Note: I have the following version of this I should solve why I did this:
        # $str =~ /\G(?:(?=^)|(?=\n))(?:\*|\+|\-) /gc or ( exists $tokens[-1] and $tokens[-1]->{type} eq 'line_break' and $str =~ /\G(?:\*|\+|\-) /gc

        1;
    }
    
    {
        package Markdown::Compiler::Lexer::Token::TableStart;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'TableStart' }
        sub match { [ qr/\G(?:(?<=^)|(?<=\n))\| / ] }

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::TableHeaderSep;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'TableHeaderSep' }
        # sub match { [ qr/\G(?:(?<=^)|(?<=\n))\| / ] }

        sub match { return [
                qr/\G:---:/,
                qr/\G:--/,
                qr/\G--:/,
            ];
        }

        1;
    }
    
    {
        package Markdown::Compiler::Lexer::Token::BlockQuote;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'BlockQuote' }
        sub match { [ qr/\G(?:(?=^)|(?=\n)|(?=>\s))> / ] }

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::Header;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'Header' }
        sub match { [ qr/\G([\#]+) (.+?)(?=\n|$)/ ] }

        has size => (
            is      => 'ro',
            lazy    => 1,
            default => sub { length(shift->data->{header}) },
        );

        has title => (
            is      => 'ro',
            lazy    => 1,
            default => sub { shift->data->{title} },
        );

        has data => (
            is      => 'ro',
            lazy    => 1,
            builder => sub {
                my $content = shift->content;

                if ( $content =~ /^([\#]+)\s+(.+?)$/ ) {
                    return {
                        header => $1,
                        title  => $2,
                    };
                }
            },
        );


        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::InlineCode;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'InlineCode' }
        sub match { [ qr/\G`/ ] }

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::Bold;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'Bold' }

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::Italic;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'Italic' }

        1;
    }
    
    {
        package Markdown::Compiler::Lexer::Token::BoldItalic;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'BoldItalic' }

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::BoldItalicMaker;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'ShortAttribute' }
        sub match { 
            return [ 
                qr/\G\*\*\*/,
                qr/\G___/,
                qr/\G\*\*/,
                qr/\G(?:(?<=^)|(?<=[\s]))\*(?=\S|$)/,
                qr/\G(?<=[\S])\*/,
                qr/\G__/,
                qr/\G_/,
            ] 
        }

        sub tokens {
            my ( $self ) = @_;
            my $content  = $self->content;
            
            if ( $content =~ /^___/  ) {
                return Markdown::Compiler::Lexer::Token::BoldItalic->new( 
                    start  => $self->start, 
                    end    => $self->end, 
                    source => $self->source 
                );
            } elsif ( $content =~ /^\*\*\*/  ) {
                return Markdown::Compiler::Lexer::Token::BoldItalic->new( 
                    start  => $self->start, 
                    end    => $self->end, 
                    source => $self->source 
                );
            } elsif ( $content =~ /^\*\*/ ) { 
                return Markdown::Compiler::Lexer::Token::Bold->new( 
                    start  => $self->start, 
                    end    => $self->end, 
                    source => $self->source 
                );
            } elsif ( $content =~ /^__/  ) {
                return Markdown::Compiler::Lexer::Token::Bold->new( 
                    start  => $self->start, 
                    end    => $self->end, 
                    source => $self->source 
                );
            } elsif ( $content =~ /^_/ ) {
                return Markdown::Compiler::Lexer::Token::Italic->new( 
                    start  => $self->start, 
                    end    => $self->end, 
                    source => $self->source 
                );
            } elsif ( $content =~ /^\*/ ) {
                return Markdown::Compiler::Lexer::Token::Italic->new( 
                    start  => $self->start, 
                    end    => $self->end, 
                    source => $self->source 
                );

            }
        };

        

        1;
    }
    
    {
        package Markdown::Compiler::Lexer::Token::LineBreak;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'LineBreak' }
        sub match { [ qr/\G\n/ ] }

        1;
    }
    
    {
        package Markdown::Compiler::Lexer::Token::Space;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'Space' }
        sub match { [ qr/\G\s+/ ] }

        has length => (
            is => 'ro',
            lazy => 1,
            builder => sub { length(shift->content) },
        );

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::Word;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        # We'll match words to avoid making too many objects, such
        # that "Hello World" becomes 11 objects. 
        sub type  { 'Word' }
        sub match { [ qr|\G[a-zA-Z]+|, qr|\G\d+\.\d+|, qr|\G\d+|  ] }

        1;
    }

    {
        package Markdown::Compiler::Lexer::Token::Char;
        use Moo;
        extends 'Markdown::Compiler::Lexer::Token';

        sub type  { 'Char' }
        sub match { [ qr/\G./s ] }

        1;
    }
}
use Moo;
use v5.10;

has source => (
    is       => 'ro',
    required => 1,

);

has tokens => (
    is       => 'ro',
    builder  => '_build_tokens',
    init_arg => undef,

);

has token_table => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ( $self ) = @_;

        my $str;

        foreach my $token ( @{$self->tokens} ) {
            ( my $content = $token->content  ) =~ s/\n//g;
            $str .= sprintf( "%20s | %s\n", $content, $token->type );
        }

        return $str;
    }
);

has hooks => (
    is      => 'ro',
    default => sub { [] },
);

has lexer_tokens => (
    is => 'ro',
    default => sub {
        return [qw(
            Markdown::Compiler::Lexer::Token::EscapedChar
            Markdown::Compiler::Lexer::Token::CodeBlock
            Markdown::Compiler::Lexer::Token::HR
            Markdown::Compiler::Lexer::Token::Image
            Markdown::Compiler::Lexer::Token::Link
            Markdown::Compiler::Lexer::Token::Item
            Markdown::Compiler::Lexer::Token::TableStart
            Markdown::Compiler::Lexer::Token::TableHeaderSep
            Markdown::Compiler::Lexer::Token::InlineCode
            Markdown::Compiler::Lexer::Token::BlockQuote
            Markdown::Compiler::Lexer::Token::Header
            Markdown::Compiler::Lexer::Token::BoldItalicMaker
            Markdown::Compiler::Lexer::Token::LineBreak
            Markdown::Compiler::Lexer::Token::Space
            Markdown::Compiler::Lexer::Token::Word
            Markdown::Compiler::Lexer::Token::Char
        )];
    # Removed from betweenb Space and Char, might have been
    # more trouble than it's worth.
    # Markdown::Compiler::Lexer::Token::Word
    }
);

sub _build_tokens {
    my ( $self ) = @_;

    my $str = $self->source;

    pos($str) = 0;
    my @tokens;

    PARSE: while ( length($str) != pos($str) ) {
        my $start_pos = pos($str);

        TOKEN: foreach my $token_class ( @{$self->lexer_tokens} ) {
            my $matches = $token_class->match;

            foreach my $match ( @{$matches} ) {
                if ( $str =~ m|$match|gc ) {
                    push @tokens, $token_class->new( 
                        source => \$self->source,
                        start  => $start_pos,
                        end    => pos($str),
                    )->tokens;
                    next PARSE;
                }
            }
        }
        # We were not able to match the content, so we're blowing up now.
        die "Error at offset $start_pos of document: next 10 chars" . substr($self->source, $start_pos, 10 );
    }

    return [ @tokens ];
}

1;
