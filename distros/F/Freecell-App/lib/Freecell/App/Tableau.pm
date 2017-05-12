package Freecell::App::Tableau;
use version;
our $VERSION = '0.03';
use warnings;
use strict;
use Storable qw(dclone);
use List::Util qw(min);

my %conf = (
    winxp_opt => 0,  # 1 is solve for XP
    winxp_warn => 0, # 1 is invalid for XP
);
sub _property {
    my ($class, $attr, $value) = @_;
    if (defined $value) {
        my $oldv = $conf{$attr};
        $conf{$attr} = $value;
        return $oldv;
    }
    return $conf{$attr};
}
sub winxp_opt ()  { return shift->_property('winxp_opt', @_) }
sub winxp_warn () { return shift->_property('winxp_warn', @_) }

sub rank            { $_[0] & 15 }
sub suit            { $_[0] >> 4 & 3 }
sub opposite_colors { ( $_[0] & 16 ) != ( $_[1] & 16 ) }

sub new {
    my ( $class, $key, $token ) = @_;
    my $self = [ map [ (0) x 21 ], 0 .. 7 ];
    bless $self, $class;
    $self;
}

sub from_string {
    my ( $self, $string ) = @_;
    my $r = 0;
    foreach ( split /\n/, $string ) {
        my $c = 0;
        while (/(.)(.) ?/g) {
            my ( $rank, $suit ) = ( $1, $2 );
            unless ( "$rank$suit" eq "  " ) {
                $rank =~ tr/ATJQK/1\:\;\<\=/;
                $suit =~ tr/DCHS/0123/;
                $self->[$c][$r] =
                  64 | ( ( 3 & ord $suit ) << 4 ) + ( 15 & ord $rank );
            }
            $c++;
        }
        $r++;
    }
    # fix home if out of order

    my %home = map {
        my $card = $self->[$_][0];
        suit($card) + 4, $card;
    } 4 .. 7;
    foreach ( 4 .. 7 ) {
        $self->[$_][0] = exists( $home{$_} ) ? $home{$_} : 0;
    }
    $self;
}

sub from_token {
    my ( $self, $key, $token ) = @_;
    my @i = @{$token};
    my @t = split / /, $key;
    my @f = split //, shift @t;
    foreach ( splice @i, 0, @f ) {    # array,offset,length
        $self->[$_][0] = ord shift @f;
    }
    foreach my $i (@i) {
        my $j = 1;
        foreach ( split //, shift @t ) {
            $self->[$i][ $j++ ] = ord $_;
        }
    }
    $self;
}

sub from_deal {    # http://rosettacode.org/wiki/Deal_cards_for_FreeCell#Perl
    my ( $self, $s ) = @_;
    my $rnd = sub {
        return ( ( $s = ( $s * 214013 + 2531011 ) % 2**31 ) >> 16 );
    };
    my @d;
    for my $b ( split "", "A23456789TJQK" ) {
        push @d, map ( "$b$_", qw/C D H S/ );
    }
    for my $idx ( reverse 0 .. $#d ) {
        my $r = $rnd->() % ( $idx + 1 );
        @d[ $r, $idx ] = @d[ $idx, $r ];
    }
    my $cards               = [ reverse @d ];
    my $num_cards_in_height = 8;
    my $string              = '';
    while (@$cards) {
        $string .= join( ' ', splice( @$cards, 0, 8 ) ) . "\n";
    }
    $self->from_string( "\n" . $string );
}

sub to_token {
    my $self = shift;
    my @t = sort { $a->[1] cmp $b->[1] } grep $_->[1],
      map [ $_, join "", map chr($_), grep $_, @{ $self->[$_] }[ 1 .. 20 ] ],
      0 .. 7;
    my @f = sort { $a->[1] <=> $b->[1] } grep $_->[1],
      map [ $_, $self->[$_][0] ], 0 .. 7;

    join( " ", join( "", map chr( $_->[1] ), @f ), map $_->[1], @t ),
      [ ( map $_->[0], @f ), ( map $_->[0], @t ) ];
}

sub undo {
    my $self = shift;
    foreach ( reverse @{ $_[0] } ) {
        my ( $src_col, $src_row, $dst_col, $dst_row ) = @$_;

        # return dst back to src

        $self->[$src_col][$src_row] = $self->[$dst_col][ $dst_row + 1 ];

        # if dst == home && rank > Ace decrement home else clear

        if (   $dst_col > 3
            && $dst_row < 0
            && rank( $self->[$dst_col][ $dst_row + 1 ] ) > 1 )
        {
            $self->[$dst_col][ $dst_row + 1 ]--;
        }
        else {
            $self->[$dst_col][ $dst_row + 1 ] = 0;
        }
    }
}

sub play {
    my $self = shift;
    my ( $src_col, $src_row, $dst_col, $dst_row ) = @{ $_[0] };

    # dst points to last card in col so move src to dst_row +1

    $self->[$dst_col][ $dst_row + 1 ] = $self->[$src_col][$src_row];
    $self->[$src_col][$src_row] = 0;
}

sub _home {
    my ( $self, $move, $src, $src_col, $src_row, $type ) = @_;

    # src rank == home rank+1 and an A or duece

    if (
        rank($src) == rank( $self->[ suit($src) + 4 ][0] ) + 1
        && (
            rank($src) < 3

            # or src rank <= rank+1 of both home cards of opposite color

            || 2 ==
            grep rank($src) <= rank($_) + 1,   # rank($self->[suit($src) + 4][0]

            # home cards of opposite colors

            ( map $_->[0], @$self )

            # index of home cards of opposite color; << 4 = 0100.... 0101.... 0110.... 0111....

              [ grep opposite_colors( $src, $_ << 4 ), 4 .. 7 ]

        )
      )
    {

        $self->play( $_ = [ $src_col, $src_row, suit($src) + 4, -1, $type ] );
        push @{$move}, $_;
        1;
    }
    else {
        0;
    }
}

sub autoplay {
    my ( $self, $move ) = @_;
    my ( $safe, @z, @auto ) = 1;
    while ($safe) {
        map { $z[$_] = grep $_, @{ $self->[$_] }[ 1 .. 20 ] } 0 .. 7;
        $safe = 0;
        foreach my $c ( 0 .. 3 ) {
            my $src = $self->[$c][0];
            next unless $src;
            $safe ||=
              $self->_home( $move, $src, $c, 0, 'afh' );    # auto free -> home
        }
        foreach my $c ( 0 .. 7 ) {
            my $r = $z[$c];
            next unless $r;    # any cards in src col?
            my $src = $self->[$c][$r];    # yes, get last one;
            $safe ||=
              $self->_home( $move, $src, $c, $r, 'ach' );    # auto col -> home
        }
    }
}

sub generate_nodelist {
    my ( $self ) = @_;
    my @z = map { scalar grep $_, @$_[ 1 .. 20 ] } @$self;
    my @empty = grep !$self->[$_][1], 0 .. 7;
    my @free  = grep !$self->[$_][0], 0 .. 3;
    my @moves;

    foreach my $c ( 0 .. 3 ) {
        my $src = $self->[$c][0];
        next unless $src;
        if ( rank($src) - 1 == rank( $self->[ suit($src) + 4 ][0] ) ) {
            push @moves, [ [ $c, 0, suit($src) + 4, -1, 'fh' ] ];   # free->home
        }
        if ( @empty > 0 ) {
            push @moves, [ [ $c, 0, $empty[0], 0, 'fe' ] ];    # free->empty
        }
        foreach my $j ( 0 .. 7 ) {
            next unless $z[$j];
            my $dst = $self->[$j][ $z[$j] ];
            if (   rank($src) + 1 == rank($dst)
                && opposite_colors( $src, $dst ) )
            {
                push @moves, [ [ $c, 0, $j, $z[$j], 'fc' ] ];    # free -> col
            }
        }
    }

    foreach my $c ( 0 .. 7 ) {
        next unless $z[$c];    # any cards in src col?
        my $src = $self->[$c][ $z[$c] ];    # then get last one;
        if ( rank($src) - 1 == rank( $self->[ suit($src) + 4 ][0] ) ) {
            push @moves,
              [ [ $c, $z[$c], suit($src) + 4, -1, 'ch' ] ];    # col->home
        }
        if ( @free > 0 ) {
            push @moves, [ [ $c, $z[$c], $free[0], -1, 'cf' ] ];    # col->free
        }
        if (   @empty > 0
            && $z[$c] > 1 )
        {
            push @moves, [ [ $c, $z[$c], $empty[0], 0, 'ce' ] ];    # col->empty
        }

        my $flag = 1;
        foreach my $j ( 0 .. 7 ) {
            next if $c == $j;
            next unless $z[$j];

            #        my $src = $self->[$c][$z[$c]];  # then get last one;
            my $dst = $self->[$j][ $z[$j] ];

            if (   rank($src) + 1 == rank($dst)
                && opposite_colors( $src, $dst ) )
            {
                push @moves, [ [ $c, $z[$c], $j, $z[$j], 'cc' ] ];    # col->col
            }

            #       super move
            if ( $z[$c] > 1 ) {
                foreach my $k ( reverse 1 .. $z[$c] - 1 ) {
                    my $srx = $self->[$c][$k];
                    unless ( rank($srx) - 1 == rank( $self->[$c][ $k + 1 ] )
                        && opposite_colors( $srx, $self->[$c][ $k + 1 ] ) )
                    {
                        last;
                    }
                    if (   @empty > 0
                        && $k > 1
                        && $flag == 1
                        && ( $conf{winxp_opt} ? min( 1, scalar @empty ) : @empty ) *
                        ( @free + 1 ) >= ( @_ = $k .. $z[$c] ) )
                    {    # e*(f+1)
                        my $x = 0;
                        push @moves,
                          [ map { [ $c, $_, $empty[0], $x++, 'sce' ] }
                              $k .. $z[$c] ];    # col->empty
                    }
                    if (   rank($srx) + 1 == rank($dst)
                        && opposite_colors( $srx, $dst )
                        && (
                            ( $conf{winxp_opt} ? min( 1, scalar @empty ) : @empty ) + 1 )
                        * ( @free + 1 ) >= ( @_ = $k .. $z[$c] ) )
                    {                            # (e+1)*(f+1)
                        my $x = $z[$j];
                        push @moves,
                          [ map { [ $c, $_, $j, $x++, 'scc' ] } $k .. $z[$c] ]
                          ;                      # col->col
                    }
                }
                $flag = 0;
            }
        }
    }
    \@moves;
}

sub to_card {
    qw(0 A 2 3 4 5 6 7 8 9 T J Q K) [ rank( $_[0] ) ]
      . qw(D C H S) [ suit( $_[0] ) ];
}

sub to_string {
    my $self = shift;
    my ( $x, $result ) = 0;
    while (1) {
        my @r = map {
            my $card = $_->[$x];
            $card == 0 ? "   " : to_card($card) . " ";
        } @$self;
        $result .= sprintf "%s\n", join "", @r;
        last if $x++ > 0 && 8 == grep $_ eq "   ", @r;
    }
    $result;
}

sub notation {
    my $self = dclone shift;
    my (
        $i,       $super_cnt, $super_orig, $std_src,
        $std_dst, @dsc_src,   $dsc_dst,    %auto,
        @z,       @empty,     @free
    ) = ( 0, 0, "" );

    map {
        my ( $src_col, $src_row, $dst_col, $dst_row, $origin ) = @$_;

        # build both standard and descriptive notation

        if ( $i == 0 ) {
            $std_src =
              (   $src_row > 0 ? $src_col + 1
                : $src_col > 3 ? "h"
                :                qw(a b c d) [$src_col] );
            $std_dst =
              (   $dst_row > -1 ? $dst_col + 1
                : $dst_col > 3 ? "h"
                :                qw(a b c d) [$dst_col] );
            $dsc_dst =
                $dst_row == 0    ? "empty column"
              : $std_dst =~ /\d/ ? to_card( $self->[$dst_col][$dst_row] )
              : $std_dst =~ /h/  ? "home"
              :                    "freecell";
        }

        # gather move card cnt for super move

        if ( $origin =~ /^s/ ) {
            if ( $super_cnt == 0 ) {
                $super_orig = $origin;
                @empty      = grep !$self->[$_][1], 0 .. 7;
                @free       = grep !$self->[$_][0], 0 .. 3;
            }
            $super_cnt++;
        }

        # build descriptive source notation

        my $num = $self->[$src_col][$src_row];
        if ( $origin =~ /^a/ ) {
            $auto{ suit($num) }[ rank($num) ] = to_card($num);
        }
        else {
            push @dsc_src, to_card($num);
        }
        $self->play($_);
        $i++;
    } @{ $_[0] };    # node array

    # if a super move, is it valid for XP ?

    if (
        $super_cnt
        && !(
            ( min( 1, scalar @empty ) + $super_orig =~ /c$/ ) * ( @free + 1 )
            >= $super_cnt
        )
      )
    {
        $conf{winxp_warn} = 1;
    }

    # output notation

      $std_src . $std_dst,    # standard notation
      $dsc_src[0] . ( @dsc_src == 1 ? "" : "-" . $dsc_src[-1] ),
      $dsc_dst,                    # descriptive notation
      join ", ", map {
        my @h = grep $_, @{ $auto{$_} };    # autoplay notation
        $h[0] . ( @h == 1 ? "" : "-" . $h[-1] );
      } sort keys %auto;
}

sub heuristic {
    my ($self) = @_;
    my $score = 64;
    my @z = map { scalar grep $_, @$_[ 1 .. 20 ] } @$self;
    map $score -= rank( $self->[$_][0] ), 4 .. 7;    # -sum home
    $score -= grep !$self->[$_][1], 0 .. 7;          # -empty
    $score -= grep !$self->[$_][0], 0 .. 3;          # -free

    my $seq = 0;
    foreach my $c ( 0 .. 7 ) {    # +sum column sequence breaks
        next unless $z[$c] > 1;
        foreach my $r ( 1 .. ( $z[$c] - 1 ) ) {
            my $src0 = $self->[$c][$r];
            my $src1 = $self->[$c][ $r + 1 ];
            my $brk  = !opposite_colors( $src1, $src0 )
              || rank($src1) + 1 != rank($src0);
            if ($brk) {
                $score += $brk;              # algorithn 1
                $seq   += $src1 >= $src0;    # algorithm 2 - major seq break
            }
        }
    }
    [ $score, $score + $seq ];
}

__END__

=head1 NAME

Freecell::Tableau - Freecell layout.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

The Tableau class manages the creation of the Tableau array from both input
gameno and the position key and token. 

    use Freecell::Tableau;

    my $tableau = Freecell::Tableau->new()->from_deal($gameno);

    -or-

    my $tableau = Freecell::Tableau->new()->from_token($key, $token);


=head1 EXPORT

none.

=head1 SUBROUTINES/METHODS

=head2 new()

Initializes the Tableau with 8 columns and 21 rows of 0's

    columns 0 .. 3 row 0 are the freecells
    columns 4 .. 7 row 0 are the homecells D, C, H, S
    columns 0 .. 7 rows 1 .. 20 are the cascades

=head2 from_token()

This creates a Tableau from the Key and Token built in C<to_token()>.

=head2 to_token()

The key for position is created with C<to_token()> which also creates a 
token array. The token array is needed to rebuild the Tableau from the key.
The key is the chr() of each integer in the Tableau. 

    card->key     A    2    3    4    5    6    7    8    9    T    J    Q    K
      ....0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101
    D 0100....    A    B    C    D    E    F    G    H    I    J    K    L    M
    C 0101....    Q    R    S    T    U    V    W    X    Y    Z    [    \    ]
    H 0110....    a    b    c    d    e    f    g    h    i    j    k    l    m
    S 0111....    q    r    s    t    u    v    w    x    y    z    {    |    }



=head2 from_string($str)

Given a C<new()> Tableau, it will take an input string from C<deal($gameno)> 
and populate the Tableau.
    
    TC -> 'C' -> '1' -> x31 <<4 -> ..01.... 
    +-> + 'T' -> ':' -> x3a &15 -> ....1010 
        + 64  ->        x40     -> .1...... 
        =                          01011010 = x5a ('Z')

=head2 to_string()

Creates a human readable string from Tableau.

=head2 from_deal($gameno)

Thanks to L<http://rosettacode.org/wiki/Deal_cards_for_FreeCell#Perl> 
this generates hands 1 to 1 million with a perl one-liner.

        return (($s = ($s * 214013 + 2531011) % 2**31) >> 16 );

=head2 play($move)

This will take a generated_nodelist entry and perform the move to create a
new Tableau state.

=head2 undo($node)

This will undo a call to C<play()>.

=head2 autoplay($node)

Append to the node all safe moves to home.

=head2 notation($node)

During backtrack, the notation is pushed onto the solution array.

=head2 generate_nodelist()

Creates a node for all valid plays of a given Tableau.

=head2 heuristic

The algorithm is simple.

=over 4

=item * Start with 64.

=item * Subtract the rank of all the top home cards.

=item * Subtract 1 for each empty freecell and empty column.

=item * Add 1 for each sequence break in the cascade
        e.g. 6C 5H 4S 2C KD QS TH has 3 sequence breaks,
        one major at 2C because the KD is greater than
        the 2C.

=back

=head2 helper subroutines

=over 4

=item * opposite_colors() - test if two cards are of opposite color

=item * rank() - return the rank of a card

=item * suit() - return the suit of a card

=item * to_card() - convert a numeric tableau card to a two character string

=back

=head2 getters and setters for two class variables

=over 4

=item * winxp_opt() - was the --win_xp option specified

=item * winxp_warn() - if not, is solution valid for XP

=back

=head1 AUTHOR

Shirl Hart, C<< <shirha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freecell-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Freecell-App>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Freecell::Tableau


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Freecell-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Freecell-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Freecell-App>

=item * Search CPAN

L<http://search.cpan.org/dist/Freecell-App/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Shirl Hart.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Freecell::Tableau
