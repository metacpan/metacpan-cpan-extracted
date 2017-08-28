package MYDan::Node::Range;

=head1 NAME

MYDan::Node::Range - Extends MYDan::Node::KeySet.

=head1 SYNOPSIS

 use MYDan::Node::Range;

 my $a = MYDan::Node::Range->new()->load( 'foo{00~99},bar{2~9}baz,-/bar/' );

 ## ... see base class for other methods ...

=cut
use strict;
use warnings;

use base qw( MYDan::Node::KeySet );

=head1 SYMBOLS

=head3 misc

  '~' : range
  '{' : open
  '}' : close
  '/' : regex

=head3 range

  ',' : add
 ',-' : subtract
 ',&' : intersect
 ',^' : symdiff

=cut
our %SYMBOL =
(
    MISC =>
    {
        range => '~', open  => '{', close => '}', regex => '/'
    },

    RANGE =>
    {
        add => ',', subtract => ',-', intersect => ',&', symdiff => ',^'
    },
);

=head1 GRAMMAR

=head3 TOP

 ^ <expr> $

=cut
sub parse
{
    my ( $self, $string ) = @_;
    my $regex = join '|', $self->symbol;

    $self->{index} = 0;
    $self->{token} = [ grep { $_ ne '' } split /($regex)/, $string ];

    my $result = eval { $self->expr } || MYDan::Node::KeySet->new();
    warn sprintf "%s: $@\n", $self->{index} if $@;
    return $result;
}

sub symbol
{
    my $self = shift;
    my $symbol = $self->{symbol} = { map { reverse %$_ } values %SYMBOL };
    return reverse sort map { $_ =~ s/([?^])/\\$1/g; $_ } keys %$symbol;
}

=head3 expr

 <product> [ <range_symbol> [ <match> | <product> ] ]*

=cut
sub expr
{
    my $self = shift;
    my $result = $self->product;

    while ( ! $self->end && $self->op( RANGE => 0 ) )
    {
        my $op = $self->op( RANGE => 1 );
        my $stage = $self->token( 'regex' ) ? 'match' : 'product';

        $result->$op( $self->$stage ); 
    }
    return $result;
}

=head3 product

 [ <range> | <complex> ]+

=cut
sub product
{
    my $self = shift;
    my $stage = $self->token( 'open' ) ? 'complex' : 'range';
    my $result = $self->$stage;

    while ( ( ! $self->end )
        && ( $self->token( 'open' ) || ! $self->token( '' ) ) )
    {
        my $stage = $self->token( 'open' ) ? 'complex' : 'range';
        $result->multiply( $self->$stage );
    }
    return $result;
}

=head3 complex

 '{' <expr> '}'

=cut
sub complex
{
    my $self = shift;
    my $result = $self->incr->expr;
    die unless $self->token( 'close' );

    $self->incr;
    return $result;
}

=head3 match

 '/' <string> '/'

=cut
sub match
{
    my $self = shift;
    my $regex = $self->incr->token;
    die if $self->token( '' );

    die unless $self->incr->token( 'regex' );
    $self->incr;
    return qr/$regex/i;
}

=head3 range

 <string> [ '~' <string> ]?

=head3 string

 <-misc_symbol -range_symbol>+ 

=cut
sub range
{
    my $self = shift;
    die if $self->token( '' );

    my ( $x, $y ) = $self->token;

    if ( ! $self->incr->end && $self->token( 'range' ) )
    {
        die if $self->incr->token( '' );
        $y = $self->token;
        $self->incr;
    }
    return MYDan::Node::KeySet->new->load( $x, defined $y ? $y : $x );
}

sub op
{
    my ( $self, $type, $consume ) = @_;
    my $op = $self->token( '' );
    my $ok = $op && $SYMBOL{$type}{$op};

    return $ok unless $consume;
    die unless $ok;

    $self->incr;
    return $op;
}

sub token
{
    my ( $self, $val ) = @_;
    my $token = $self->{token}[ $self->{index} ];
    return $token unless defined $val;

    my $symbol = defined $token ? $self->{symbol}{$token} : $token;
    return $val eq '' ? $symbol : defined $symbol && $symbol eq $val;
}

sub incr
{
    my $self = shift;
    ++ $self->{index};
    return $self;
}

sub end
{
    my $self = shift;
    $self->{index} >= @{ $self->{token} };
}

=head1 METHODS

=head3 load( $o )

Loads from a I<string>, or an object supported by the base class namesake.

=cut
sub load
{
    my $self = shift;
    $self->SUPER::load( @_ ? ref $_[0] ? @_ : $self->parse( @_ ) : () );
}

1;
