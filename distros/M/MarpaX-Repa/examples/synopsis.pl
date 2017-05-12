use 5.010;
use strict;
use warnings;
use lib 'lib/';

use Marpa::R2;
use MarpaX::Repa::Lexer;
use MarpaX::Repa::Actions;

my $grammar = Marpa::R2::Grammar->new( {
    action_object => 'MarpaX::Repa::Actions',
    default_action => 'do_scalar_or_list',
    start   => 'query',
    rules   => [
        {
            lhs => 'query', rhs => [qw(condition)],
            min => 1, separator => 'OP', proper => 1, keep => 1,
        },
        [ condition => [qw(word)] ],
        [ condition => [qw(quoted)] ],
        [ condition => [qw(OPEN-PAREN SPACE? query SPACE? CLOSE-PAREN)] ],
        [ condition => [qw(NOT condition)] ],

        [ 'SPACE?' => [] ],
        { lhs => 'SPACE?', rhs => [qw(SPACE)], action => 'do_ignore', },
    ],
});
$grammar->precompute;

use Regexp::Common qw /delimited/;
my $lexer = MyLexer->new(
    tokens => {
        word          => { match => qr{\b\w+\b}, store => 'scalar' },
        'quoted'      => {
            match => qr[$RE{delimited}{-delim=>qq{\"}}],
            store => sub {
                ${$_[1]} =~ s/^"//;
                ${$_[1]} =~ s/"$//;
                ${$_[1]} =~ s/\\([\\"])/$1/g;
                return $_[1];
            },
        },
        OP            => { match => qr{\s+OR\s+|\s+}, store => sub { ${$_[1]} =~ /\S/? \'|' : \'&' } },
        NOT           => { match => '!', store => sub {\'!'} },
        'OPEN-PAREN'  => { match => '(', store => 'undef' },
        'CLOSE-PAREN' => { match => ')', store => 'undef' },
        'SPACE'       => { match => qr{\s+}, store => 'undef' },
    },
    debug => 1,
);

my $recognizer = $lexer->recognize( Marpa::R2::Recognizer->new( { grammar => $grammar } ), \*DATA );

use Data::Dumper;
print Dumper $recognizer->value;

package MyLexer;
use base 'MarpaX::Repa::Lexer';

sub grow_buffer {
    my $self = shift;
    my $rv = $self->SUPER::grow_buffer( @_ );
    ${ $self->buffer } =~ s/[\r\n]+//g;
    return $rv;
}

package main;
__DATA__
hello !world OR "he hehe hee" ( foo OR !boo )
