package ExampleSyntax;

BEGIN {
    push @INC, '../lib';
}

use strict;
use warnings;
use Devel::Declare::Lexer qw/ debug function has auto_sprintf /; 
use Devel::Declare::Lexer::Factory qw( :all );

BEGIN {
    #$Devel::Declare::Lexer::DEBUG = 1;
    Devel::Declare::Lexer::lexed(auto_sprintf => sub {
        my ($stream_r) = @_;
        my @stream = @$stream_r;

        my @vars = $stream[4]->deinterpolate;
        my @args = (
            "%s",
            "£%04d"
        );
        $stream[4]->{value} = $stream[4]->interpolate(@args);
       
        my @start = @stream[0..3];
        my @str = @stream[4..4];
        my @end = @stream[5..$#stream];
     
        push @start, (
            new Devel::Declare::Lexer::Token::Bareword( value => 'sprintf' ),
            new Devel::Declare::Lexer::Token::LeftBracket( value => '(' ),
        );
        unshift @end, (
            new Devel::Declare::Lexer::Token::Operator( value => ',' ),
            new Devel::Declare::Lexer::Token::Variable( value => $vars[0] ),
            new Devel::Declare::Lexer::Token::Operator( value => ',' ),
            new Devel::Declare::Lexer::Token::Variable( value => $vars[1] ),
            new Devel::Declare::Lexer::Token::RightBracket( value => ')' ),
        );

        @stream = (@start, @str, @end);

        return \@stream;
    });
   Devel::Declare::Lexer::lexed(debug => sub {
        my ($stream_r) = @_;
        my @stream = @$stream_r;

        my $string = $stream[2]; # keyword [whitespace] "string"

        my @ns = ();
        tie @ns, "Devel::Declare::Lexer::Stream";

        push @ns, (
            new Devel::Declare::Lexer::Token::Declarator( value => 'debug' ),
            new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
            new Devel::Declare::Lexer::Token( value => 'print' ),
            new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
            $string,
            new Devel::Declare::Lexer::Token::EndOfStatement,
            new Devel::Declare::Lexer::Token::Newline,
        );

        return \@ns;
    });
    Devel::Declare::Lexer::lexed(function => sub {
        my ($stream_r) = @_;

        my @stream = @{$stream_r};
        my @start = @stream[0..1];
        my @end = @stream[2..$#stream];

        my $name = shift @end; # get function name

        # Capture the variables
        my @vars = ();
        # Consume everything until the start of block
        while($end[0]->{value} !~ /{/) {
            my $tok = shift @end;
            next if ref($tok) =~ /Devel::Declare::Lexer::Token::(Left|Right)Bracket/;
            next if ref($tok) =~ /Devel::Declare::Lexer::Token::Operator/;
            next if ref($tok) =~ /Devel::Declare::Lexer::Token::Whitespace/;
           
            # If we've got a variable, capture it
            if(ref($tok) =~ /Devel::Declare::Lexer::Token::Variable/) {
                push @vars, [
                    $tok,
                    shift @end
                ];
            }
        }

        shift @end; # remove the {

        # Build a sub with an opening my statement
        my @output = _stream(\@start, [
            _statement([_bareword(1)]),
            _sub($name->{value}, [
                _block([
                    _statement([
                        _bareword('my'),
                        _block([
                            _list(@vars)
                        ], '('),
                        _operator('='),
                        _variable('@', '_')
                    ]),
                    _stream(undef, \@end)
                ], '{', { no_close => 1 }), # don't close it ( #FIXME lexer bug, stops at first ; )
            ]),
        ]);

        return \@output;
    });
    Devel::Declare::Lexer::lexed(has => sub {
        my ($stream_r) = @_;

        my @stream = @{$stream_r};
        my @start = @stream[0..1];
        my @end = @stream[2..$#stream];

        shift @stream; # remove keyword
        while(ref($stream[0]) =~ /Devel::Declare::Lexer::Token::Whitespace/) {
            shift @stream;
        }

        # Get the name (could be string or variable)
        my $name = shift @stream;
        if(ref($name =~ /Devel::Declare::Lexer::Token::Variable/)) {
            $name = shift @stream;
        }
        
        # Consume whitespace and => 
        while($stream[0]->{value} !~ /{/) {
            shift @stream;
        }

        my $nest = 0;
        my @propblock = ();
        shift @stream; # consume the {
        while(@stream) {
            if(ref($stream[0]) =~ /Devel::Declare::Lexer::Token::LeftBracket/) {
                $nest++;
            }elsif(ref($stream[0]) =~ /Devel::Declare::Lexer::Token::RightBracket/) {
                last if $nest == 0 && $stream[0]->{value} =~ /}/;
                $nest--;
            }
            push @propblock, shift @stream; # consume tokens
        }
        shift @stream; # consume the }

        my @output = _stream($stream_r, [
            _statement([_bareword(1)]),
            _statement([
                _bareword('my'),
                _whitespace(' '),
                _var_assign(
                    [_variable('$','__props_lexer_' . $name->{value})], 
                    [_block([
                       @propblock 
                    ], '{')]
                )
            ]),
            _statement([
                _var_assign(
                    [_variable('$','__props_lexer_' . $name->{value} . '->{\'value\'}')],
                    [_variable('$','__props_lexer_' . $name->{value} . '->{\'default\'}')]
                )
            ]),
            _sub(
                $name->{value}, 
                [_block([
                    _statement([
                        _bareword('my'),
                        _whitespace(' '),
                        _var_assign(
                            [_block([
                                _variable('$','value')
                            ], '(')],
                            [_variable('@','_')]
                        )
                    ]),
                    _if([
                        _variable('$','value'),
                    ],
                    [
                        _var_assign(
                            [_variable('$','__props_lexer_' . $name->{value} . '->{\'value\'}')],
                            [_variable('$','value')]
                        )
                    ]),
                    _return(
                        [_variable('$','__props_lexer_' . $name->{value} . '->{\'value\'}')]
                    )
                ])]
            ),
        ]);

        # Stick everything else back on the end
        push @output, @stream;
        return \@output;
    });
}

sub import
{
    my $caller = caller;
    Devel::Declare::Lexer::import_for($caller, "debug");
    Devel::Declare::Lexer::import_for($caller, "function");
    Devel::Declare::Lexer::import_for($caller, "has");
    Devel::Declare::Lexer::import_for($caller, "auto_sprintf");
}

1;
