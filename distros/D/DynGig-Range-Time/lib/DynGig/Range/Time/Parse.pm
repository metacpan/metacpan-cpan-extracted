=head1 NAME

DynGig::Range::Time::Parse - Implements DynGig::Range::Interface::Parse.

=cut
package DynGig::Range::Time::Parse;

use base DynGig::Range::Interface::Parse;

use warnings;
use strict;

use DynGig::Range::Integer;

=head1 OBJECT

ARRAY of I<size> DynGig::Range::Integer objects. Time is stored in seconds.
Object 0 is linked to the last object.

e.g. if I<size> is 7, object 0 and object 7 are the same.

=cut
sub _init
{
    my ( $class, $size ) = @_;
    my @this = map { DynGig::Range::Integer->new() } 1 .. $size;

    unshift @this, $this[-1];
    return \@this;
}

=head1 GRAMMAR

Tokenizer and parser implement the following BNF.

=cut
sub _parse
{
    my ( $this, $input ) = @_;
    my $token = $this->_tokenize( $input, qr/[&;]/ );

    $this += $this->_expression( $token );
}

sub _valid
{
    my ( $this, $token, $lex ) = @_;

    return 0 unless @$token;
    return ref $token->[0] || $token->[0] eq '&' unless $lex;
    return $token->[0] eq '+' if $lex == 1;
    return $token->[0] eq ';' if $lex == 2;
    return ref $token->[0];
}

=head2 <expression> ::= <multi> ( ';' <multi> )*

=cut
sub _expression
{
    my ( $this, $token ) = @_;

    unless ( $this->_valid( $token, 3 ) )
    {
        splice @$token;
        return $this->new();
    }

    my $range = $this->_multi( $token );

    while ( $this->_valid( $token, 2 ) )
    {
        shift @$token;
        $range->add( $this->_multi( $token ) );
    }

    return $range;
}

=head2 <multi> ::= <scope> ( '&' <scope> )*

=cut
sub _multi
{
    my ( $this, $token ) = @_;
    my $range = $this->_scope( $token );

    while ( $this->_valid( $token ) )
    {
        shift @$token;
        $range->filter( $this->_scope( $token ) );
    }

    return $range;
}

=head2 <scope> ::= <range> ( ',' <range> )*

=cut
sub _scope
{
    my ( $this, $token ) = @_;
    my $range = $this->_range( $token );

    while ( $this->_valid( $token, 1 ) )
    {
        shift @$token;
        $range->add( $this->_range( $token ) );
    }

    return $range;
}

=head2 <range> ::= <validated literal>

=head2 LITERAL

String of characters, excluding symbols, in a rudimentary range form.

=head2 SYMBOLS

I<operator>:

',' : high precedence add

';' : low precedence add

'&' : filter

=cut
sub _literal
{
    my $this = shift @_;
    $this->_parse_( $this->_tokenize_( @_ ) );
}

sub _tokenize_  ## tokenize literal
{
    my ( $this, $input ) = @_;
    my ( $segment, @range, @node ) = '';
    my %symbol = $this->symbol();

    if ( $input->[0] ne $symbol{range} && $input->[-1] ne $symbol{range} )
    {
        while ( @$input )
        {
            my $char = $input->[0];

            if ( $char eq $symbol{range} )
            {
                push @node, $segment;
                push @range, [ @node ];

                ( $segment, @node ) = '';

                last if @range == 2;
            }
            else
            {
                for my $regex ( qr/\d/, qr/\D/ )
                {
                    if ( $char =~ $regex )
                    {
                        if ( $segment ne '' && $segment !~ $regex )
                        {
                            push @node, $segment;
                            $segment = '';
                        }

                        $segment .= $char;
                        last;
                    }
                }
            }

            shift @$input;
        }
    }

    if ( @$input )
    {
        splice @range;
        splice @$input;
    }
    else
    {
        push @node, $segment;
        push @range, \@node;
    }

    return @range;
}

1;

__END__

=head1 NOTE

See DynGig::Range::Time

=cut
