#!/usr/bin/perl

package Devel::Declare::Lexer::Factory::t;

use strict;
use warnings;
use Devel::Declare::Lexer qw/ test function has /;
use Devel::Declare::Lexer::Factory qw/ _stream _statement _reference _variable _string _var_assign _list _keypair _if _return _bareword _block _whitespace _operator _sub /;

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }

my $tests = 0;

BEGIN {
    Devel::Declare::Lexer::lexed(test => sub {
        my ($stream_r) = @_;

        # Create a new stream from the old one (consumes declarator and whitespace)
        my @stream = _stream($stream_r,[
            # Create a new statement (passing in array ref of tokens)
            _statement([
                # Create a variable assignment, passing in a array ref variable and a token value
                _var_assign(
                    # Create an array ref variable
                    [_variable('$', 'test')],
                    # Create a new string
                    _string( "'", "123" )
                )
            ])
        ]);

        return \@stream;
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

my $test;
test "a b c";
++$tests && is($test, '123', 'Using factory methods');

function something ($a, $b) {
    return 5 * ($a + $b);
};
++$tests && is(something(1,2), 15, 'Function definition');

has 'a' => { is => 'rw', isa => 'Int', default => '123', random => 'abc' };
++$tests && is(a, 123, 'Property construct and value get');
a(50);
++$tests && is(a, 50, 'Property value set');

++$tests && is(__LINE__, 189, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
