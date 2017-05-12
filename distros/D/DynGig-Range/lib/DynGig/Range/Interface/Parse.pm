=head1 NAME

DynGig::Range::Interface::Parse - Base class for Range parsers

=cut
package DynGig::Range::Interface::Parse;

use warnings;
use strict;
use Carp;

use constant
{
    NULL        => '',
    LIST        => ',',
    RANGE       => '~',
    SCOPE_BEGIN => '{',
    SCOPE_END   => '}',
};

sub new
{
    my $class = shift @_;
    my $this = bless $class->_object(), ref $class || $class;

    for my $input ( @_ )
    {
        next unless defined $input;

        for my $input ( ref $input eq 'ARRAY' ? @$input : $input )
        {
            unless ( ref $input )
            {
                $this->_parse( $input );
            }
            elsif ( UNIVERSAL::isa( $input, ref $this ) )
            {
                $this->add( $input );
            }
        }
    }

    return $this;
}

=head1 DESCRIPTION

=head2 symbol()

Returns a flattened HASH of symbols.

=cut
sub symbol
{
    my %symbol = 
    (
        null => NULL, list => LIST, range => RANGE,
        scope_begin => SCOPE_BEGIN, scope_end => SCOPE_END,
    );
}

=head1 GRAMMAR

Tokenizer and parser implement the following BNF.

=cut
sub _parse
{
    my ( $this, $input ) = @_;
    my $token = $this->_tokenize( $input, qr/[{}]/, qr/[-&]/ );

    $this += $this->_expression( $token, { SCOPE_END => 0 } );
}

sub _tokenize
{
    my ( $this, $input, @regex ) = @_;
    my %symbol = $this->symbol();
    my $symbol = NULL;
    my @input = split $symbol, $input;
    my ( @token, @literal );

    while ( @input )
    {
        my $char = shift @input;

        next if $char =~ /\s/o;

        if ( $char =~ /$regex[0]/o )
        {
            $symbol = $char;
        }
        elsif ( $char eq $symbol{list} )
        {
            $symbol = '+';
            $symbol = shift @input
                if $regex[1] && @input && $input[0] =~ $regex[1];
        }
        else
        {
            push @literal, $char;
        }

        if ( $symbol )
        {
            push @token, $this->_literal( \@literal ) if @literal;
            push @token, $symbol;

            $symbol = NULL;
        }
    }

    push @token, $this->_literal( \@literal ) if @literal;
    return \@token;
}

=head2 <expression> ::= <multi> ( <operator> <multi> )*

=cut
sub _expression
{
    my ( $this, $token, $scope ) = @_;

    unless ( $this->_valid( $token, 2 ) )
    {
        splice @$token;
        return $this->new();
    }

    my %op = ( '+' => 'add', '-' => 'subtract', '&' => 'intersect' );
    my $range = $this->_multi( $token, $scope );

    while ( $this->_valid( $token, 1 ) )
    {
        my $op = $op{ shift @$token };
        $range->$op( $this->_multi( $token, $scope ) );
    }

    return $range;
}

=head2 <multi> ::= <scope>+

=cut
sub _multi
{
    my ( $this, $token, $scope ) = @_;
    my $range = $this->_scope( $token, $scope );

    $range->multiply( $this->_scope( $token, $scope ) )
        while $this->_valid( $token );

    return $range;
}

=head2 <scope> ::= <range> | '{' <expression> '}'

=cut
sub _scope
{
    my ( $this, $token, $scope ) = @_;
    my ( $type, $range ) = SCOPE_END;
    my $count = $scope->{$type};

    return $this->_range( $token, $scope ) if ref $token->[0];

    $this->_balance( $token, $scope, $type );
    $range = $this->_expression( $token, $scope );
    $this->_balance( $token, $scope, $type, $count ) ? $range : $range->clear();
}

=head2 <range> ::= <validated literal>

=cut
sub _range
{
    my ( $this, $token ) = @_;

    croak 'private method' unless $this->isa( ( caller )[0] );

    return bless shift @$token, ref $this;
}

=head2 LITERAL

String of characters, excluding symbols, in a rudimentary range form.

=head2 SYMBOLS

I<operator>:

','  : add

',-' : subtract

',&' : intersect

I<scope>:

'{'  : begin

'}'  : end   

=cut

sub _valid
{
    my ( $this, $token, $lex ) = @_;

    return 0 unless @$token;

    my $ref = ref $token->[0];

    return $ref || $token->[0] eq SCOPE_BEGIN unless $lex;
    return $ref || $token->[0] !~ /[-+&}]/o if $lex == 2;
    return $token->[0] =~ /[-+&]/o;
}

sub _balance
{
    my ( $this, $token, $scope, $type, $count ) = @_;

    unless ( defined $count )
    {
        shift @$token;
        return ++ $scope->{$type};
    }

    while ( $scope->{$type} > $count )
    {
        return 0 unless my $symbol = shift @$token;

        if ( ref $symbol || $symbol ne $type )
        {
            splice @$token;
            return 0;
        }

        $scope->{$type} --;
    }

    return 1;
}

=head1 NOTE

See DynGig::Range

=cut

1;

__END__
