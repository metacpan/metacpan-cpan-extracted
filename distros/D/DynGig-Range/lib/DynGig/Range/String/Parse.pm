=head1 NAME

DynGig::Range::String::Parse - Implements DynGig::Range::Interface::Parse.

=cut
package DynGig::Range::String::Parse;

use base DynGig::Range::Interface::Parse;

use warnings;
use strict;

use DynGig::Range::String::Object;

=head1 GRAMMAR

Tokenizer and parser implement the base class BNF with the
following differences.

=head2 <expression> ::=

  <multi> ( <operator> <multi> )* | <multi> ( <operator> <regex> )*

=head2 <regex> ::= <a subset of perl regex>

e.g.

 /^foobar$/i
 /[1-3]/

Range takes precedence on symbols that are common to both range and regex.

=cut

sub _expression
{
    my ( $this, $token, $scope ) = @_;
    my %symbol = $this->symbol();

    unless ( $this->_valid( $token, 2 ) )
    {
        splice @$token;
        return $this->new();
    }

    my %op = ( '+' => 'add', '-' => 'subtract', '&' => 'intersect' );
    my $range = $this->_multi( $token, $scope );

    while ( $this->_valid( $token, 1 ) )
    {
        my $op = shift @$token;

        if ( ref $token->[0] || $token->[0] eq $symbol{scope_begin} )
        {
            $op = $op{$op};
            $range->$op( $this->_multi( $token, $scope ) );
        }
        else
        {
            next if $op eq '+';

            my $regex = shift @$token;
            my $match = $op eq '-' ? '!~' : '=~';

            $range = $range
                ->new( grep { eval "'$_' $match $regex" } $range->list() );
        }
    }

    return $range;
}

=head1 OBJECT

A variable-level HASH with levels alternating between
numeric and non-numeric keys, and leaves as { '' => '' }.

e.g. 'abc000~4,123~4xyz,abc123xyz456,abc,xyz' is stored as
 
 '123':
   xyz:
     '': ''
 '124':
   xyz:
     '': ''
 abc:
   '': ''
   '000':
     '': ''
   '001':
     '': ''
   '002':
     '': ''
   '003':
     '': ''
   '004':
     '': ''
   '123':
     xyz:
       '456':
         '': ''
 xyz:
   '': ''

=cut
sub _object { DynGig::Range::String::Object->new( {} ) }

=head1 LITERAL

A rudimentary range form. e.g.

 'abc000~4'
 'xyz'
 '123'

=cut
sub _literal
{
    my $this = shift @_;
    my @token = $this->_tokenize_( @_ );

    return ref $token[0] ? $this->_parse_( @token ) : @token;
}

sub _tokenize_  ## tokenize literal
{
    my ( $this, $input ) = @_;
    my ( @range, @node, @segment );
    my %symbol = $this->symbol();

    return join $symbol{null}, @$input
        if $input->[0] eq '/' && 2 <= grep { $_ eq '/' } @$input;

    if ( $input->[0] ne $symbol{range} && $input->[-1] ne $symbol{range} )
    {
        while ( @$input )
        {
            my $char = $input->[0];
    
            if ( $char eq $symbol{range} )
            {
                push @node, [ @segment ];
                push @range, [ @node ];

                ( @segment, @node ) = ();

                last if @range == 2;
            }
            else
            {
                for my $regex ( qr/\d/, qr/\D/ )
                {
                    if ( $char =~ $regex )
                    {
                        if ( @segment && $segment[0] !~ $regex )
                        {
                            push @node, [ @segment ];
                            @segment = ();
                        }
    
                        push @segment, $char;
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
        push @node, \@segment;
        push @range, \@node;
    }

    return @range;
}

sub _parse_  ## parse literal tokens into a range structure ( unbless object )
{
    my ( $this, @range ) = @_;
    my %symbol = $this->symbol();
    my %range;

    goto DONE unless @range;

    my ( $null, $head, $tail, @number ) = $symbol{null};

    my $number = sub
    {
        return 0 if grep { $_->[0] !~ /\d/ } @_;

        my ( $a, $b ) = @_;
        my $diff = @$a - @$b;
        my $A = join $null, @$a;
        my $B = join $null, @$b;

        if ( $A == $B )
        {
            return 0 if $diff < 0;
            $B = $A;
        }
        elsif ( ! $diff )
        {
            return 0 if $A > $B;
        }
        elsif ( $diff > 0 )
        {
            if ( $A > $B )
            {
                return 0 if $B < join $null, splice @$a, $diff;
                $B = join $null, @$a, $B;
            }
        }
        elsif ( $A > $B || ! $a->[0] || ! $b->[0] )
        {
            return 0;
        }

        @number = ( $A, $B );
        return 1;
    };

    my $comp = sub
    {
        my @list;

        while ( @{ $range[0] } )
        {
            my @segment = map { join $null, @{ $_->[0] } } @range;

            last if $segment[0] ne $segment[1];

            map { shift @$_ } @range;
            push @list, [ $segment[0] ];
        }

        return \@list;
    };

    my $terse = sub
    {
        ( $head, $tail ) = @range;

        return 0 unless &$number( $head->[-1], $tail->[0] );

        pop @$head;
        shift @$tail;

        return 1;
    };

    my $verbose = sub
    {
        $head = &$comp( @range );

        return 1 unless @{ $range[0] };
        return 0 unless &$number( map { shift @$_ } @range );

        $tail = &$comp( @range );

        return ! grep { @$_ } @range;
    };

    goto DONE unless @range == 1 ? $head = $range[0]
        : &$terse() || @{ $range[0] } == @{ $range[1] } && &$verbose();

    my $R = \%range;
    my $H = @$head;

    map { $R = $R->{ join $null, @$_ } ||= {} } @$head if $H;

    if ( @number )
    {
        my $length = length $number[0];
        my $format = "%0${length}d";

        for my $number ( $number[0] .. $number[1] )
        {
            my $R = $R->{ sprintf( $format, $number ) } ||= {};

            map { $R = $R->{ join $null, @$_ } ||= {} } @$tail;
            $R->{$null} = $null;
        }
    }
    elsif ( %range )
    {
        $R->{$null} = $null;
    }

    DONE: DynGig::Range::String::Object->new( \%range );
}

=head1 NOTE

See DynGig::Range

=cut

1;

__END__
