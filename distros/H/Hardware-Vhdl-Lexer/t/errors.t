
use Test::More tests => 11;
use File::Temp qw/ tempfile /;
use Scalar::Util qw/ refaddr /;
#use YAML;

# TODO:
#  check type of token recognised

use strict;
use warnings;

package DuffLineGiver;
# simple class which doesn't have a getline() method which returns the next line

sub new {
    my $class = shift;
    my $self = [];
    bless $self, $class;
}

sub addtokens {
    my $self = shift;
    for my $token (@_) {
        if (@$self==0 || $self->[-1] =~ /[\015\012]$/) {
            unshift @$self, $token;
        } else {
            $self->[-1] .= $token;
        }
    }
}

sub get_a_line {
    my $self = shift;
    pop @$self;
}

package main;

BEGIN {
    use_ok('Hardware::Vhdl::Lexer');
}

{
    my $fh = &string_to_file("foo bar baz");
    
    eval {
        my $tp = Hardware::Vhdl::Lexer->new({ linesource => $fh, nhistory => 2 });
    };
    is($@, '', 'baseline: construct without error');
    
    eval {
        my $tp = Hardware::Vhdl::Lexer->new( linesource => $fh, nhistory => 2 );
    };
    like($@, qr/Argument to Hardware::Vhdl::Lexer->new\(\) must be hash reference/ms, 'non-hashref arg to new()');

    eval {
        my $tp = Hardware::Vhdl::Lexer->new({ nhistory => 2 });
    };
    like($@, qr/Hardware::Vhdl::Lexer constructor requires a linesource to be specified/ms, 'missing linesource arg to new()');

    eval {
        my $tp = Hardware::Vhdl::Lexer->new({ linesource => "a string", nhistory => 2 });
    };
    like($@, qr/Hardware::Vhdl::Lexer->new 'linesource' parameter is not of a valid type \(it is not a reference\)/ms, 'linesource is not a ref');

    close $fh;
    ok(DuffLineGiver->can('get_a_line'), 'test case self-check');
    ok(!DuffLineGiver->can('get_next_line'), 'test case self-check');

    my $source = DuffLineGiver->new;
    eval {
        my $tp = Hardware::Vhdl::Lexer->new({ linesource => $source, nhistory => 2 });
    };
    like($@, qr/Hardware::Vhdl::Lexer->new 'linesource' parameter is not of a valid type \(type is 'DuffLineGiver'\)/ms, 'bad linesource type: object without the right method');

    eval {
        my $tp = Hardware::Vhdl::Lexer->new({ linesource => \\"hello world", nhistory => 2 });
    };
    like($@, qr/Hardware::Vhdl::Lexer->new 'linesource' parameter is not of a valid type \(type is 'REF'\)/ms, 'bad linesource type: scalar ref ref');

    eval {
        my $tp = Hardware::Vhdl::Lexer->new({ linesource => {hello  => "world"}, nhistory => 2 });
    };
    like($@, qr/Hardware::Vhdl::Lexer->new 'linesource' parameter is not of a valid type \(type is 'HASH'\)/ms, 'bad linesource type: hash ref');
}

ok( 1, 'End of tests' );

sub string_to_file {
    my $string = shift;
    my $fh = tempfile;
    binmode $fh;
    print $fh $string;
    seek $fh, 0, 0;
    $fh;
}
