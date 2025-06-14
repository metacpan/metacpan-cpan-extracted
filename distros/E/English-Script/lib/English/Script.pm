package English::Script {
    # ABSTRACT: Parse English subset and convert to data or code

    use 5.014;
    use exact;

    use Parse::RecDescent;
    use YAML::XS 'Dump';

    our $VERSION = '1.07'; # VERSION

    sub new {
        my $self = shift;
        $self = ( ref $self ) ? bless( { %$self, @_ }, ref $self ) : bless( {@_}, $self );

        $self->{grammar} //= q#
            content :
                ( comment | sentence )(s) /^\Z/
                { +{ $item[0] => $item[1] } }
                | <error>

            comment :
                /\([^\(\)]*\)/
                {
                    $item[1] =~ /\(([^\)]+)\)/;
                    +{ $item[0] => ( $1 || '' ) };
                }
                | <error>

            sentence :
                command /[\.;]\s/
                { pop @item; +{@item} }
                | <error>

            command :
                (
                    say | set | append | add | subtract | multiply | divide |
                    otherwise_if | if | otherwise | for
                )
                { +{@item} }
                | <error>

            say : /\bsay\b/ ( list | expression )
                { +{ $item[0] => $item[2] } }
                | <error>

            set : /\bset\b/ object '=' ( list | expression )
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            append : /\bappend\b/ ( list | expression ) '=' object
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            add : /\badd\b/ expression '=' object
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            subtract : /\bsubtract\b/ expression '`' object
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            multiply : /\bmultiply\b/ object '~' expression
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            divide : /\bdivide\b/ object '~' expression
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            otherwise_if : /\botherwise,\s*if\b/ expression '::' ( block | command )
                { +{ $item[0] => { %{ $item[2] }, %{ $item[4] } } } }
                | <error>

            if : /\bif\b/ expression '::' ( block | command )
                { +{ $item[0] => { %{ $item[2] }, %{ $item[4] } } } }
                | <error>

            otherwise : /\botherwise\b,?/ ( block | command )
                { +{ $item[0] => $item[2] } }
                | <error>

            for : /\bfor(?:\s+each)?\b/ object '=^' object block
                {
                    +{
                        $item[0] => {
                            item => $item[2],
                            list => $item[4],
                            %{ $item[5] },
                        }
                    };
                }
                | <error>

            block : '{{{' ( comment | sentence )(s?) '}}}'
                { +{ $item[0] => $item[2] } }
                | <error>

            list :
                object ( list_item_seperator object )(s)
                { +{ shift @item => [ shift @item, @{ $item[0] } ] } }
                | <error>

            list_item_seperator : /,\s*(&&\s+)?/
                | <error>

            expression:
                object sub_expression(s?)
                { +{ $item[0] => [ $item[1], map { @$_ } @{ $item[2] } ] } }
                | <error>

            sub_expression:
                operator object
                { [ $item[1], $item[2] ] }
                | <error>

            operator :
                (
                    '+' | '-' | '/' | '*' |
                    '>=' | '>' | '<=' | '<' | '!@=' | '@=' | '!=' | '==' | '!^=' | '^=' |
                    '&&' | '||'
                )
                {
                    $item[1] =
                        ( $item[1] eq '!@=' ) ? 'not in'     :
                        ( $item[1] eq '@='  ) ? 'in'         :
                        ( $item[1] eq '!^=' ) ? 'not begins' :
                        ( $item[1] eq '^='  ) ? 'begins'     : $item[1];
                    +{@item};
                }
                | <error>

            object : call(s?) ( string | number | word | '=+' | '=-' )(s)
                {
                    pop @{ $item[2] } while (
                        @{ $item[2] } > 1 and
                        $item[2][-1]{word} =~ /^(?:value|string|text|number|list|array)$/
                    );

                    for ( @{ $item[2] } ) {
                        if ( $_ eq '=+' ) {
                           $_ = { boolean => 'true' };
                        }
                        elsif ( $_ eq '=-' ) {
                           $_ = { boolean => 'false' };
                        }
                    }

                    my $data            = {};
                    $data->{calls}      = $item[1] if ( @{$item[1]} );
                    $data->{components} = $item[2] if ( @{$item[2]} );

                    +{ $item[0] => $data };
                }
                | <error>

            call :
                ( '~=' | '$=' | /\[\d+\]/ )
                {
                    $item[1] =
                        ( $item[1] =~ /\[(\d+)\]/ ) ? { 'item' => $1 } :
                        ( $item[1] eq '~='        ) ? 'length'         :
                        ( $item[1] eq '$='        ) ? 'shift'          : $item[1];
                    +{@item};
                }
                | <error>

            string :
                /"[^"]*"/
                {
                    $item[1] =~ /"([^"]*)"/;
                    +{ $item[0] => $1 };
                }
                | <error>

            number :
                /\-?(?:\d+,)*(?:\d+\.)*\d+\b/
                {
                    $item[1] =~ s/[^\d\.\-]//g;
                    +{@item};
                }
                | <error>

            word :
                /\w+(?:'s)?\b/
                { +{@item} }
                | <error>
        #;

        $self->renderer( $self->{renderer} // 'JavaScript', $self->{render_args} );

        return $self;
    }

    sub grammar {
        my ( $self, $grammar ) = @_;
        $self->{grammar} = $grammar if ($grammar);
        return $self->{grammar};
    }

    sub append_grammar {
        my ( $self, $grammar ) = @_;
        $self->{grammar} .= "\n" . $grammar if ($grammar);
        return $self;
    }

    sub _instantiate_renderer {
        my ( $self, $renderer, $render_args ) = @_;

        my $class = __PACKAGE__ . "::$renderer";
        eval "require $class";

        return $class->new( $render_args || {} );
    }

    sub renderer {
        my ( $self, $renderer, $render_args ) = @_;
        $self->{render_args} = $render_args;

        if (
            $renderer and (
                not $self->{renderer_obj} or
                $self->{renderer} and $renderer ne $self->{renderer}
            )
        ) {
            my $class = __PACKAGE__ . "::$renderer";
            eval "require $class";

            $self->{renderer}     = $renderer;
            $self->{renderer_obj} = $self->_instantiate_renderer( $self->{renderer}, $self->{render_args} );
        }

        return $self->{renderer};
    }

    sub _prepare_input {
        my ( $self, $input ) = @_;

        my $bits;

        $input =~ s/\(([^\)]+)\)/
            push( @{ $bits->{comments} }, $1 );
            '(' . scalar @{ $bits->{comments} } - 1 . ')';
        /ge;

        $input =~ s/"([^"]+)"/
            push( @{ $bits->{strings} }, $1 );
            '"' . scalar @{ $bits->{strings} } - 1 . '"';
        /ge;

        $input = lc $input;
        $input =~ s/\b(?:a|an|the|value\s+of|list\s+of|there\s+are|there\s+is)\b//g;

        for (
            # call
            [ 'length of'         => '~=' ],
            [ 'removed item from' => '$=' ],

            # operator
            [ 'plus'                        => '+'   ],
            [ 'minus'                       => '-'   ],
            [ 'divided by'                  => '/'   ],
            [ 'times'                       => '*'   ],
            [ 'is greater than or equal to' => '>='  ],
            [ 'is greater than'             => '>'   ],
            [ 'is less than or equal to'    => '<='  ],
            [ 'is less than'                => '<'   ],
            [ 'is not in'                   => '!@=' ],
            [ 'is in'                       => '@='  ],
            [ 'is not'                      => '!='  ],
            [ 'is'                          => '=='  ],
            [ 'does not begin with'         => '!^=' ],
            [ 'begins with'                 => '^='  ],

            # assignment
            [ 'to'   => '=' ],
            [ 'from' => '`' ],
            [ 'by'   => '~' ],

            # logical
            [ 'and' => '&&' ],
            [ 'or'  => '||' ],

            # value
            [ 'true'  => '=+' ],
            [ 'false' => '=-' ],

            # in
            [ 'in' => '=^' ],
        ) {
            $_->[0]  =~ s/\s/\\s+/g;
            $input =~ s/\b($_->[0])\b/$_->[1]/g;
        }

        $input =~ s/(?:,\s*)?\bthen\b/ ::/g;
        $input =~ s/(?:,\s*)?\bapply\b[\w\s]+\bblock\b\s*\./ {{{ /g;
        $input =~ s/[^\.\)]+\bend[\w\s]+\bblock\b/ }}} /g;

        $input =~ s/\bitem\s*([\d,\.]+)(?:\s*of)?/\[$1\]/g;
        $input =~ s/\((\d+)\)/'(' . $bits->{comments}[$1] . ')'/ge;
        $input =~ s/"(\d+)"/'"' . $bits->{strings}[$1] . '"'/ge;

        return $input . "\n";
    }

    sub _parse_prepared_input {
        my ( $self, $prepared_input ) = @_;

        my ( $stderr, $parse_tree );
        {
            local *STDERR;
            open( STDERR, '>', \$stderr );

            local $::RD_ERRORS = 1;
            local $::RD_WARN   = 1;

            $parse_tree = Parse::RecDescent->new( $self->{grammar} )->content($prepared_input);
        }
        if ($stderr) {
            $stderr =~ s/\r?\n[ ]{23}/ /g;
            $stderr =~ s/(?:\r?\n){2,}/\n/g;
            $stderr =~ s/^\s+//mg;

            my @errors = map {
                /^\s*(?<type>\w+)(?:\s+\(line\s+(?<line>\d+)\))?:\s+(?<message>.+)/s;
                my $error = {%+};
                $error->{type} = ucfirst lc $error->{type};
                $error;
            } split( /\n/, $stderr );

            return { errors => \@errors };
        }
        else {
            return $parse_tree;
        }
    }

    sub parse {
        my ( $self, $input ) = @_;
        $self->{data} = $self->_parse_prepared_input( $self->_prepare_input($input) );
        croak('Failed to parse input') if ( exists $self->{data}{errors} );
        return $self;
    }

    sub data {
        my ($self) = @_;
        return $self->{data};
    }

    sub yaml {
        my ($self) = @_;
        return Dump( $self->{data} );
    }

    sub render {
        my ( $self, $renderer, $render_args ) = @_;

        my $renderer_obj = ( $renderer or $render_args )
            ? $self->_instantiate_renderer(
                $renderer    // $self->{renderer},
                $render_args // $self->{render_args},
            )
            : $self->{renderer_obj};

        return $renderer_obj->render( $self->{data} );
    }
}

package English::Script::JavaScript {
    use 5.014;
    use exact;
    use JavaScript::Packer;

    our $VERSION = '1.07'; # VERSION

    sub new {
        my ( $self, $args ) = @_;
        return bless( { args => $args }, $self );
    }

    sub render {
        my ( $self, $data ) = @_;
        $self->{objects} = {};
        my $js = $self->content($data);

        return ( ref $self->{args} eq 'HASH' and %{ $self->{args} } )
            ? JavaScript::Packer->init->minify( \$js, $self->{args} )
            : $js;
    }

    sub content {
        my ( $self, $content ) = @_;

        my $text = join( '',
            map {
                ( exists $_->{comment}  ) ? $self->comment( $_->{comment}   ) :
                ( exists $_->{sentence} ) ? $self->sentence( $_->{sentence} ) : ''
            } @{ $content->{content} }
        );

        return join( "\n", (
            map {
                'if ( typeof( ' . $_ . ' ) == "undefined" ) ' . ( (/\./) ? '' : 'var ' ) . $_ .
                    ( ( $self->{objects}{$_} ) ? ' = ' . $self->{objects}{$_} : ' = ""' ) . ';'
            } sort keys %{ $self->{objects} }
        ), $text );
    }

    sub comment {
        my ( $self, $comment ) = @_;
        ( my $text = $_->{comment} ) =~ s|^|// |mg;
        return $text . "\n";
    }

    sub sentence {
        my ( $self, $sentence ) = @_;
        return $self->command( $sentence->{command} );
    }

    sub command {
        my ( $self, $command ) = @_;

        my ($command_name) = keys %$command;
        my $tree           = $command->{$command_name};

        if ( $command_name eq 'say' ) {
            return join( ' ',
                'console.log(', (
                    ( exists $tree->{list} )       ? $self->list( $tree->{list}             ) :
                    ( exists $tree->{expression} ) ? $self->expression( $tree->{expression} ) : 'undefined'
                ), ')',
            ) . ";\n";
        }
        elsif ( $command_name eq 'set' ) {
            my $object = $self->object( $tree->[0]{object} );
            $self->{objects}{$object} = '[]' if ( exists $tree->[1]{list} );

            return join( ' ',
                $object, '=', (
                    ( exists $tree->[1]{expression} )
                        ? $self->expression( $tree->[1]{expression} ) :
                    ( exists $tree->[1]{list} )
                        ? '[ ' . $self->list( $tree->[1]{list} ) . ' ]' : 'undefined'
                )
            ) . ";\n";
        }
        elsif ( $command_name eq 'append' ) {
            my $object_core   = $self->object_core( $tree->[1]{object} );
            my $object        = $self->object_calls( $tree->[1]{object}, $object_core );
            my $obj_is_a_list = ( $self->{objects}{$object} and $self->{objects}{$object} eq '[]' ) ? 1 : 0;
            my @predicate     =
                ( exists $tree->[0]{list}       ) ? $self->list( $tree->[0]{list} )             :
                ( exists $tree->[0]{expression} ) ? $self->expression( $tree->[0]{expression} ) : '';

            return join( ' ', (
                ($obj_is_a_list)
                    ? ( $object . '.push(', @predicate, ')' )
                    : ( $object, '+=', @predicate )
            ) ) . ";\n";
        }
        elsif ( $command_name eq 'add' ) {
            return join( ' ',
                $self->object( $tree->[1]{object} ), '+=', $self->expression( $tree->[0]{expression} ),
            ) . ";\n";
        }
        elsif ( $command_name eq 'subtract' ) {
            return join( ' ',
                $self->object( $tree->[1]{object} ), '-=', $self->expression( $tree->[0]{expression} ),
            ) . ";\n";
        }
        elsif ( $command_name eq 'multiply' ) {
            return join( ' ',
                $self->object( $tree->[0]{object} ), '*=', $self->expression( $tree->[1]{expression} ),
            ) . ";\n";
        }
        elsif ( $command_name eq 'divide' ) {
            return join( ' ',
                $self->object( $tree->[0]{object} ), '/=', $self->expression( $tree->[1]{expression} ),
            ) . ";\n";
        }
        elsif ( $command_name eq 'otherwise_if' ) {
            return 'else if ( ' .
                join( ' ', $self->expression( $tree->{expression} ) ) . " ) {\n" . join( ' ', (
                    ( exists $tree->{command} ) ? $self->command( $tree->{command} ) :
                    ( exists $tree->{block}   ) ? $self->block( $tree->{block}     ) : ''
                ) ) . "}\n";
        }
        elsif ( $command_name eq 'if' ) {
            return 'if ( ' .
                join( ' ', $self->expression( $tree->{expression} ) ) . " ) {\n" . join( ' ', (
                    ( exists $tree->{command} ) ? $self->command( $tree->{command} ) :
                    ( exists $tree->{block}   ) ? $self->block( $tree->{block}     ) : ''
                ) ) . "}\n";
        }
        elsif ( $command_name eq 'otherwise' ) {
            return "else {\n" . join( ' ', (
                ( exists $tree->{command} ) ? $self->command( $tree->{command} ) :
                ( exists $tree->{block}   ) ? $self->block( $tree->{block}     ) : ''
            ) ) . "}\n";
        }
        elsif ( $command_name eq 'for' ) {
            my $item = $self->object( $tree->{item}{object} );
            my $list = $self->object( $tree->{list}{object} );

            return 'for ( ' . $item . ' of ' . $list . " ) {\n" . join( ' ', (
                $self->block( $tree->{block} )
            ) ) . "}\n";
        }

        return '';
    }

    sub block {
        my ( $self, $block ) = @_;
        return join( '',
            map {
                ( exists $_->{comment}  ) ? $self->comment( $_->{comment}   ) :
                ( exists $_->{sentence} ) ? $self->sentence( $_->{sentence} ) : ''
            } @$block
        );
    }

    sub list {
        my ( $self, $list ) = @_;
        return join( ', ', map { $self->object( $_->{object} ) } @$list );
    }

    sub expression {
        my ( $self, $expression ) = @_;

        my @parts = map {
            ( exists ( $_->{object} ) ) ? +{ object => $self->object( $_->{object} ) } : +{%$_};
        } @$expression;

        for ( my $i = 0; $i < @parts; $i++ ) {
            if ( exists $parts[$i]{operator} ) {
                if ( $parts[$i]{operator} eq 'in' ) {
                    $parts[ $i - 1 ]{object} =
                        $parts[ $i + 1 ]{object} . '.indexOf( ' . $parts[ $i - 1 ]{object} . ' )';
                    $parts[$i]{operator}     = '>';
                    $parts[ $i + 1 ]{object} = -1;
                }
                elsif ( $parts[$i]{operator} eq 'not in' ) {
                    $parts[ $i - 1 ]{object} =
                        $parts[ $i + 1 ]{object} . '.indexOf( ' . $parts[ $i - 1 ]{object} . ' )';
                    $parts[$i]{operator}     = '==';
                    $parts[ $i + 1 ]{object} = -1;
                }
                elsif ( $parts[$i]{operator} eq 'begins' ) {
                    $parts[ $i - 1 ]{object} =
                        $parts[ $i - 1 ]{object} . '.indexOf( ' . $parts[ $i + 1 ]{object} . ' )';
                    $parts[$i]{operator}     = '==';
                    $parts[ $i + 1 ]{object} = 0;
                }
                elsif ( $parts[$i]{operator} eq 'not begins' ) {
                    $parts[ $i - 1 ]{object} =
                        $parts[ $i - 1 ]{object} . '.indexOf( ' . $parts[ $i + 1 ]{object} . ' )';
                    $parts[$i]{operator}     = '!=';
                    $parts[ $i + 1 ]{object} = 0;
                }
            }
        }

        return map { ( exists $_->{object} ) ? $_->{object} : $_->{operator} } @parts;
    }

    sub object {
        my ( $self, $object ) = @_;
        return $self->object_calls( $object, $self->object_core($object) );
    }

    sub object_core {
        my ( $self, $object ) = @_;

        my $text = '';
        if ( exists $object->{components} ) {
            if ( $object->{components}[0]{boolean} ) {
                $text .= join( ' ', map { values %$_ } @{ $object->{components} } );
            }
            elsif ( not $object->{components}[0]{string} ) {
                my $contains_non_number = grep { not exists $_->{number} } @{ $object->{components} };
                $object->{components}[0] = { word => '_' . $object->{components}[0]{number} }
                    if ( $contains_non_number and exists $object->{components}[0]{number} );

                my @parts = map { values %$_ } @{ $object->{components} };
                $text .= join( '.', @parts );

                if ($contains_non_number) {
                    for ( my $i = 0; $i < @parts; $i++ ) {
                        $self->{objects}{
                            join( '.', @parts[ 0 .. $i ] )
                        } //= ( $i == @parts - 1 ) ? '' : '{}';
                    }
                }
            }
            else {
                $text .= '"' . join( '', map { values %$_ } @{ $object->{components} } ) . '"';
            }
        }

        return $text;
    }

    sub object_calls {
        my ( $self, $object, $text ) = @_;

        my $object_text = $text;
        if ( exists $object->{calls} ) {
            for my $call ( reverse map { values %$_ } @{ $object->{calls} } ) {
                if ( $call eq 'length' ) {
                    $text .= '.length';
                }
                elsif ( $call eq 'shift' ) {
                    $text .= '.shift';
                    $self->{objects}{$object_text} = '[]';
                }
                elsif ( ref $call eq 'HASH' and exists $call->{item} ) {
                    $text .= '[' . ( $call->{item} - 1 ) . ']';
                }
            }
        }

        return $text;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

English::Script - Parse English subset and convert to data or code

=head1 VERSION

version 1.07

=for markdown [![test](https://github.com/gryphonshafer/English-Script/workflows/test/badge.svg)](https://github.com/gryphonshafer/English-Script/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/English-Script/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/English-Script)

=head1 SYNOPSIS

    use English::Script;

    my $js = English::Script->new->parse('Set the answer to 42.')->render;

    my $es = English::Script->new(
        grammar     => '# grammar',
        renderer    => 'JavaScript',
        render_args => {},
    );

    my $grammar  = $es->grammar('# set grammar');
    $es          = $es->append_grammar('# append grammar');
    my $renderer = $es->renderer('JavaScript');
    $renderer    = $es->renderer( 'JavaScript', {} );

    $es = $es->parse('Set the answer to 42.');

    my $data = $es->data;
    my $yaml = $es->yaml;

    $js = $es->render;
    $js = $es->render('JavaScript');
    $js = $es->render( 'JavaScript', {} );

=head1 DESCRIPTION

The module will parse a limited subset of English (using L<Parse::RecDescent>
grammar) and convert it to either a Perl data structure or YAML. It can then
render this to code. The default renderer is JavaScript.

Why? Well, the goal is to provide a means by which some basic logic can be
written in English and (at least in theory) be read, maintained, and extended
by normal humans (which is to say, non-programmers).

=head1 METHODS

The following are the methods of the module.

=head2 new

Returns an instantiated object of the class.

    my $js = English::Script->new;

Optionally, you can provide certain settings.

    $es = English::Script->new(
        grammar     => '# grammar',   # replaces default grammer
        renderer    => 'JavaScript',  # set the renderer; default: JavaScript
        render_args => {},            # arguments for the renderer
    );

Renderers are subclasses of English::Script. The default is
English::Script::JavaScript, which ships with English::Script. The name provided
via the C<renderer> property is appended to "English::Script::" to locate the
renderer class.

=head2 parse

Parse a string input based on the grammar.

    $es = $es->parse('Set the answer to 42.');

This method will return the object. If parsing fails, an error will be thrown.
You can catch this error and then inspect C<data> to get a list of all errors.

    use exact;
    use DDP;

    try {
        $es->parse('Set the answer to 42.');
    }
    catch {
        p $es->data->{errors};
    };

=head2 render

If no arguments are provided, this method will call whatever renderer is set
via the C<renderer> attribute to render code from the data parsed.

    $js = $es->render;

You can optionally explicitly set a renderer or a renderer and arguments for
the renderer.

    $js = $es->render('JavaScript');
    $js = $es->render( 'JavaScript', {} );

The method will return the rendered code as a scalar string.

=head2 grammar

This is a getter/setter for the grammar, which is a string suitable for
L<Parse::RecDescent>.

    my $grammar = $es->grammar('# set grammar');

=head2 append_grammar

Append a string to whatever's currently set in the C<grammar> attribute.

    $es = $es->append_grammar('# append grammar');

This method will return the object.

=head2 renderer

This is a getter/setter for the renderer. You can provide either the name of a
renderer (which should be the suffix added to "English::Script::" to locate the
renderer class) or the name of the renderer and a hashref of arguments for that
renderer.

    my $renderer = $es->renderer('JavaScript');
    $renderer    = $es->renderer( 'JavaScript', {} );

=head2 data

Returns the Perl data structure of whatever was succesfully C<parse>d.

    my $data = $es->data;

=head2 yaml

Returns YAML of whatever was succesfully C<parse>d.

    my $yaml = $es->yaml;

=head1 DEFAULT GRAMMAR

The default grammar is a limited and simple set of basic English phrases. The
intent of this "language" is not to be particularly expressive, but provide
just enough to be useful in basic situations.

Parsable input needs to be composed of sentences. Line breaks and other spacing
is ignored, but purely for the sake easy reading, the examples below generally
follow a sentence being all on one line. This is not required.

=head2 Say

To "say" something means to output it in some way. For the JavaScript renderer,
this means a call to C<console.log>. Say commands require an expression.
Expressions contain at least one object and possibly some operations. An object
is a string, number, word, or call.

Here are some simple examples:

    Say 42.
    Say "Hello World".
    Say 42 plus 1138 times 13 divided by 12.

=head2 Set

The "set" command assigns a value derived from an expression to an object.

    Set prime to 3.
    Set the special prime value to 3.
    Set the answer to 123,456.78.

Numbers can be floating point and contain commas, which will be ignored. For
example, "123,456.78" becomes C<123456.78>.

In the case of multiple words (or words and numbers) provided as an object, the
assumption will be that these are sequences of objects in a tree. For example:

    Set the special prime value to 3.

The special prime" becomes C<special.prime> in JavaScript.

Certain words are ignored completely, like "the" and "a" and all other articles.
Also phrases like "value of" or "list of" or "there are" and "there is" are
ignored. For objects, words like "list" or "value" or "text" or "number" are
ignored. For example:

    Set the special prime list value string text number list array to 3.

The object above becomes C<special.prime> in JavaScript (and is assigned the
integer 3).

Words and numbers can form an object. For example:

    Set the sum of 27 to the value of 3 plus 5 times 10 divided by 2 minus 1.

The object above is C<sum.of.27>.

In all cases, everything outside of strings, denoted by double-quotes, will be
considered case-insensitive.

=head2 Comments

Comments are any text between parentheses. The text can contain line-breaks or
any other spacing. However, comments must not be embedded inside sentences. They
can be inside blocks, like in "if" or "for" blocks, but in parallel to
sentences.

    (This is a single-line comment.)

    (This is a
    multi-line comment.)

    If prime is 3, then apply the following block.
        Set the answer to 42.
        (This is a comment.)
    This ends the block.

Note that the spacing and line breaks in the examples above is purely for easier
reading. It's not required.

=head2 Lists

To create an array, assign a list to an object.

    Set the primes to 5, 6, and 7.

The "and" isn't necessarily required; however, the spaces and commas are
required.

You can reference a specific item in a list by number (starting at 1):

    Set the favorite number to item 1 of favorite numbers.

Given a list stored in C<answer>, you can then C<shift> off a value:

    Set the prime value to a removed item from the primes list.

=head2 Length

You can get the length of a list (the number of items it contains) or the length
of a string by seeking it's "length":

    Set string size to the length of strings example.
    Set primes size to the length of the primes list.

You can also find the length of a specific item of a list:

    Set the special size to the length of item 1 of favorite numbers.

=head2 Append

You can append to a string or to a list.

    Append "+" to the answer text.
    Append 9 to the primes list.

=head2 Math

Basic math functions are supported:

    Add 42 to the favorite number.
    Subtract 42 from the favorite number.
    Multiply the favorite number by 42.
    Divide the favorite number by 42.

=head2 If

Basic conditionals are supported.

    If prime is 3, then set add 3 to the sum of primes.

You can also setup blocks. Note that in the following example, the spacing and
line breaks exist purely to aid in reading. They're not required.

    If prime is 3, then apply the following block.
        Set the answer to 42.
        Set THX to 1138.
    This ends the block.

You can name the blocks as well, if you want. So you could write "then apply
the following set up some things block."

The booleans of "true" and "false" are supported.

    Set something to true.
    If something is true, then say "It's true!".

=head2 Otherwise

The "otherwise" command works as an C<else>, but it must be in an immediately
following sentence from an "if" sentence.

    If the prime is 3, then set result to true. Otherwise, set result to false.

You can create the equivalent of an C<else if> via:

    If the prime is 3, then set result to true.
    Otherwise, if the answer is not 42, then set result to false.

=head2 Conditionals

A few basic conditionals are supported.

=over 4

=item *

is

=item *

is not

=item *

is less than

=item *

is greater than

=item *

is less than or equal to

=item *

is greater than or equal to

=back

You can check if a string is in a larger string, if an item is in a list, or
if a string begins with another string or not using:

=over 4

=item *

is in

=item *

is not in

=item *

begins with

=item *

does not begin with

=back

Basic logical combinations of conditionals are possible with:

=over 4

=item *

and

=item *

or

=back

=head2 For

For loops that iterate through items in a list are supported.

    Set primes to 3, 5, and 7. For each prime in primes, apply the following
    block. Add prime to sum. This ends the block.

=head2 Variable Scope

All variables are scoped globally. Everywhere. Always. If you setup a for loop
and name the iterator something, that something will available everywhere.

=head1 LANGUAGE RENDERER MODULES

Language renderer modules must support a C<new()> method and a C<render()>
method. Beyond that, you can do just about whatever you want to make rendering
work.

=head2 JavaScript

The default renderer "JavaScript" will render... wait for it... JavaScript.

    English::Script->new(
        renderer    => 'JavaScript',
        render_args => { compress => 'clean' },
    )->parse('Set answer to 42.')->render;

The optional C<render_args> value if provided should be a hashref of settings
that are passed directly to L<JavaScript::Packer> as options.

=head1 SEE ALSO

L<Parse::RecDescent>, L<JavaScript::Packer>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/English-Script>

=item *

L<MetaCPAN|https://metacpan.org/pod/English::Script>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/English-Script/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/English-Script>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/English-Script>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/D/English-Script.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
