package Encode::Wechsler;
use strict;
use warnings FATAL => 'all';
our $VERSION = '1.00';

my $i = 0;
# {0, 1, 2, ..., 8, 9, a, b, ..., v} correspond to the bitstrings {'00000', '00001', '00010', ..., '11111'}.
our %bits = map { $_ => sprintf("%05d", unpack( 'B32', pack( 'N', $i++ ) ) ) } 0 .. 9, 'a' .. 'v';
our %stib = reverse %bits;

$i = 4;
# We use the characters 'w' and 'x' to abbreviate '00' and '000'
# the symbols {'y0', 'y1', y2', ..., 'yx', 'yy', 'yz'} correspond to runs of between 4 and 39 consecutive '0's.
our %zero = map { 'y' . $_ => 0 x $i++ } 0 .. 9, 'a' .. 'z';
$zero{w} = '00';
$zero{x} = '000';
#our %orez = reverse %zero;

sub new {
    my $self = shift;
    return bless {@_}, $self;
}


sub encode {
    my $self   = shift;
    my %args   = @_;
    my $thingy = $args{board};

    # multi-line string
    $thingy = [ split "\n", $thingy ] unless ref( $thingy );

    # array of strings
    $thingy = [ map [ split //, $_ ], @$thingy ] unless ref( $thingy->[0] );

    # all become 2D array of true or false values
    $thingy = [ map [ map { $_ eq '.' ? 0 : 1 } @$_ ], @$thingy ];

=for later
    my @chunks;
    my $start_pruning;
    for (my $i = 0; $i < @$thingy; $i += 5) {
        # all zeros are ok until we found our first non all zeros
        # then prune all zeros that are "trailing"
        my @chunk;
        for (@$thingy[ $i .. $i + 4 ]) {
            $start_pruning ||= int( join '', @$_ );
            if ($start_pruning) {
                push @chunk, $_ if ref($_) && int( join '', @$_ );
            } else {
                push @chunk, $_ if ref($_);
            }
        }
        push @chunks, [@chunk] if @chunk;
    }
=cut
    my @chunks;
    for (my $i = 0; $i < @$thingy; $i += 5) {
        my @chunk = map { 
            ref( $_ ) && int( join '', @$_ ) ? $_ : () 
        } @$thingy[ $i .. $i + 4 ];
        push @chunks, [@chunk];
    }

    @chunks = map _transpose( $_ ), @chunks;

    #TODO: detect consecutive zero runs
    my @bits;
    for my $chunk (@chunks) {
        push @bits, join '',
            map { $stib{$_} }
            map { sprintf '%05d', join '', reverse @$_ } @$chunk
        ;
    }

    # this could be removed by detecting consecutive zero runs
    my $str = join 'z', @bits;
    $str =~ s/0*$//;

    return $str;
}

sub decode {
    my ($self,$code) = @_;

    $code =~ s/^\s+//;
    $code =~ s/\s+$//;
    die "invalid format: $code\n" unless $code =~ /x[spq][0-9]+_[0-9a-z]+/;

    my ($prefix,$format) = split '_', $code, 2;

    $self->{max} = 0;
    $format = join 'z', map {
        s/(w|x|y.)/$zero{$1}/g;
        $self->{max} = length($_) if length($_) > $self->{max};
        $_;
    } split 'z', $format;

    my @grid;
    for my $part (split 'z', $format ) {

        if (length($part) < $self->{max}) {
            $part .= '0' x ( $self->{max} - length($part) );
        }

        # pad left and right
        $part = ('0' x $self->{pad}) . $part . ('0' x $self->{pad}) if $self->{pad};

        my $i = 0;
        for (split '', $part) {
            push @{ $grid[$i] }, map int $_, reverse split //, $bits{$_};
            $i++;
        }
    }

    my @trans;
    for my $i (reverse 0 .. $#{ $grid[0] }) {
        push @trans, [ map $_->[$i] || 0, @grid ];
    }

    #remove leading blank rows
    for (@trans) {
        if (_sum( @$_ )) {
            last;
        }
        shift @trans;
    }

    @grid = reverse @trans;


    if ($self->{pad}) {
        unshift @grid, ([(0) x ($self->{max} + (2 * $self->{pad}))]) x $self->{pad} if _sum( $grid[ 0] );
        push    @grid, ([(0) x ($self->{max} + (2 * $self->{pad}))]) x $self->{pad} if _sum( $grid[-1] );
    }
    
    return wantarray ? @grid : $self->_to_string( @grid );
}

sub _to_string {
    my $self = shift;
    my $str = '';
    for (@_) {
        $str .= $_ ? '*' : '.' for @$_;
        $str .= "\n";
    }
    return $str;
}

sub _sum {
    my $s = 0;
    $s += $_ for @_;
    return $s;
}

# credit: Math::Matrix
sub _transpose {
    my $data = shift;
    my @trans;
    for my $i (0 .. $#{ $data->[0] }) {
        push @trans, [ map $_->[$i], @$data ]
    }
    return \@trans;
}

1;

__END__
=head1 NAME

Encode::Wechsler - Just another Wechsler encoder/decoder

THIS MODULE IS AN ALPHA RELEASE!

=head1 SYNOPSIS

Object oriented interface:

  use Encode::Wechsler;

  my $wechsler = Encode::Wechsler->new;
  my @array  = $wechsler->decode( 'xp3_0ggmligkcz32w46' );
  my $string = scalar $wechsler->decode( 'xp3_0ggmligkcz32w46' );

=head1 DESCRIPTION

Wechsler encoding is used to describe game boards for Conway's Game of Life.

THIS MODULE IS AN ALPHA RELEASE!

Interface will most likely change. Also, there is no encode() method for this
release. This release only provides decode(). No procedural interface is currently
available but should be in a future release, as well as an encode() method.
(The author's current needs only require decoding.) :D

=head1 METHODS

=over 4

=item C<new( %params )>

  my $wechsler = Encode::Wechsler->new();

Constructs object. Accepts the following named parameters:

=back

=over 8

=item * C<pad>

Integer. Ensure resulting game grid has empty cells on all four edges: the top
and bottom rows and left most and right most columns will all be "turned off."
The amount of padding determines how many rows/cols of padding will be added.

  my $wechsler = Encode::Wechsler->new( pad => 4 );

Some codes require additional padding in order to sustain properly.

=back

=over 4

=item C<encode( $string or $array_ref )>

Not currently implemented.

=item C<decode( $string )>

Attempts to decode the string argument. Returns a list of array references (2d array)
when called in list context:

  my @array  = $wechsler->decode( 'xp3_0ggmligkcz32w46' );

Or returns a text representation of the game board in scalar context:

  my $string = scalar $wechsler->decode( 'xp3_0ggmligkcz32w46' );

Throws exception if code is invalid.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to either

=over 4

=item * Email: C<bug-encode-wechsler at rt.cpan.org>

=item * Web: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-Wechsler>

=back

I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Encode::Wechsler

The Github project is L<https://github.com/jeffa/Encode-Wechsler>

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here) L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Encode-Wechsler>

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/Encode-Wechsler>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/Encode-Wechsler>

=item * Search CPAN L<http://search.cpan.org/dist/Encode-Wechsler/>

=back

=head1 ACKNOWLEDGEMENTS

Pattern notion developed by Allan Wechsler 1992. L<https://catagolue.appspot.com/help/wechsler.txt>

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

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
