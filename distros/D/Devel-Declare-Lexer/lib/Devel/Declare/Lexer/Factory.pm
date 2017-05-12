package Devel::Declare::Lexer::Factory;

use Devel::Declare::Lexer::Stream;
use Devel::Declare::Lexer::Tokens;

use v5;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    use Exporter;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw( _stream _statement _reference _variable _string _var_assign _list _keypair _if _return _bareword _block _sub _whitespace _operator );
    %EXPORT_TAGS = (
        'all'  => \@EXPORT_OK
    );
}

sub _stream
{
    my ($old_stream, $new_stream) = @_;
    my @stream = ();
    tie @stream, 'Devel::Declare::Lexer::Stream';

    if($old_stream) {
        push @stream, shift @$old_stream; # declarator
        push @stream, shift @$old_stream; # whitespace
    }
    if($new_stream) {
        push @stream, @$new_stream;
    }

    return @stream;
}

sub _statement
{
    my ($tokens) = @_;
    my @t = ();
    push @t, @$tokens;
    push @t, new Devel::Declare::Lexer::Token::EndOfStatement;
    return @t;
}

sub _reference
{
    my ($refto) = @_;
    my @tokens = ();
    push @tokens, new Devel::Declare::Lexer::Token::Operator( value => '\\' );
    push @tokens, @$refto;
    return @tokens;
}

sub _operator
{
    my ($operator) = @_;
    return ( new Devel::Declare::Lexer::Token::Operator( value => $operator ) );
}

sub _variable
{
    my ($sigil, $name) = @_;
    my @tokens = ();
    while($sigil) {
        push @tokens, new Devel::Declare::Lexer::Token::Variable( value => substr($sigil, 0, 1) );
        $sigil = substr($sigil, 1);
    }
    push @tokens, new Devel::Declare::Lexer::Token::Bareword( value => $name );
    return @tokens;
}

sub _bareword
{
    my ($word) = @_;
    return ( new Devel::Declare::Lexer::Token::Bareword( value => $word ) );
}

sub _string
{
    my ($type, $value) = @_;
    return ( new Devel::Declare::Lexer::Token::String( start => $type, end => $type, value => $value ) );
}

sub _var_assign
{
    my ($var, $value) = @_;
    my @tokens = ();
    push @tokens, @$var;
    push @tokens, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
    push @tokens, new Devel::Declare::Lexer::Token::Operator( value => '=' );
    push @tokens, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
    if(ref($value) =~ /ARRAY/) {
        push @tokens, @$value;
    } else {
        push @tokens, $value;
    }
    return @tokens;
}

sub _list
{
    my @items = @_;
    my @tokens = ();
    for my $item (@items) {
        if(ref($item) =~ /ARRAY/) {
            push @tokens, @$item;
        } else {
            push @tokens, $item;
        }
        push @tokens, new Devel::Declare::Lexer::Token::Operator( value => ',' );
        push @tokens, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
    }
    # Remove additional ,\s
    pop @tokens;
    pop @tokens;

    return @tokens;
}

sub _keypair
{
    my ($var1, $var2) = @_;
    my @tokens = ();
    push @tokens, @$var1;
    push @tokens, @$var2;
    return @tokens;
}

sub _return
{
    my ($value) = @_;
    my @tokens = ();
    push @tokens, new Devel::Declare::Lexer::Token::Bareword( value => 'return' );
    push @tokens, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
    push @tokens, @$value;
    return @tokens;
}

sub _block
{
    my ($inner, $type, $args) = @_;
    $type = $type || '{';
    my $etype = $type;
    $etype =~ tr/{([/})]/;
    my @tokens = ();
    push @tokens, new Devel::Declare::Lexer::Token::LeftBracket( value => $type );
    push @tokens, @$inner;
    if(!$args->{no_close}) {
       push @tokens, new Devel::Declare::Lexer::Token::RightBracket( value => $etype );
    }
    return @tokens;
}

sub _whitespace
{
    my ($ws) = @_;
    return ( new Devel::Declare::Lexer::Token::Whitespace( value => $ws ) );
}

sub _sub
{
    my ($name, $block) = @_;
    my @tokens = ();
    push @tokens, new Devel::Declare::Lexer::Token::Bareword( value => 'sub' );
    push @tokens, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
    push @tokens, new Devel::Declare::Lexer::Token::Bareword( value => $name );
    push @tokens, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
    push @tokens, @$block;
    return @tokens;
}

sub _if
{
    my ($condition, $then, $elsifs, $else) = @_;

    my @tokens = ();

    push @tokens, new Devel::Declare::Lexer::Token::Bareword( value => 'if' );
    push @tokens, new Devel::Declare::Lexer::Token::LeftBracket( value => '(' );
    push @tokens, @$condition;
    push @tokens, new Devel::Declare::Lexer::Token::RightBracket( value => ')' );
    push @tokens, new Devel::Declare::Lexer::Token::LeftBracket( value => '{' );
    push @tokens, @$then;
    push @tokens, new Devel::Declare::Lexer::Token::RightBracket( value => '}' );

    if($elsifs) {
        my @elsif = @$elsifs;
        if(scalar @elsif > 0) {
            for my $eif (@elsif) {
                push @tokens, new Devel::Declare::Lexer::Token::Bareword( value => 'elsif' );
                push @tokens, new Devel::Declare::Lexer::Token::LeftBracket( value => '(' );
                push @tokens, @{$eif->{condition}};
                push @tokens, new Devel::Declare::Lexer::Token::RightBracket( value => ')' );
                push @tokens, new Devel::Declare::Lexer::Token::LeftBracket( value => '{' );
                push @tokens, @{$eif->{then}};
                push @tokens, new Devel::Declare::Lexer::Token::RightBracket( value => '}' );
            }
        }
    }

    if($else) {
        push @tokens, new Devel::Declare::Lexer::Token::Bareword( value => 'else' );
        push @tokens, new Devel::Declare::Lexer::Token::LeftBracket( value => '{' );
        push @tokens, @$else;
        push @tokens, new Devel::Declare::Lexer::Token::RightBracket( value => '}' );
    }

    return @tokens;
}

1;
