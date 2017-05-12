package Lingua::EO::Supersignoj;
use Attribute::Property;
use strict;
use utf8;

our $VERSION = '0.02';

our %cxapeloj = (
    h          => [ qw/ Ch ch Gh gh Hh hh Jh jh Sh sh Uw uw / ],
    H          => [ qw/ CH ch GH gh HH hh JH jh SH sh UW uw / ],
    x          => [ qw/ Cx cx Gx gx Hx hx Jx jx Sx sx Ux ux / ],
    X          => [ qw/ CX cx GX gx HX hx JX jx SX sx UX ux / ],
    poste      => [ qw/ C^ c^ G^ g^ H^ h^ J^ j^ S^ s^ U^ u^ / ],
    fronte     => [ qw/ ^C ^c ^G ^g ^H ^h ^J ^j ^S ^s ^U ^u / ],
    apostrofoj => [ qw/ C' c' G' g' H' h' J' j' S' s' U' u' / ],
    iso        => [ map chr,
                   198, 230, 216, 248, 166, 182, 172, 188, 222, 254, 221, 253 ],
    unikodo    => [ map chr,
                   264, 265, 284, 285, 292, 293, 308, 309, 348, 349, 364, 365 ]
);

sub nova : New;
sub de : Property { exists $cxapeloj{$_} }
sub al : Property { exists $cxapeloj{$_} }
sub u  : Property { $_ = [ $_ ] if not ref $_; ref $_ eq 'ARRAY' or !defined }
sub U  : Property { $_ = [ $_ ] if not ref $_; ref $_ eq 'ARRAY' or !defined }

sub transkodigu {
    my ($mem, @tekstoj) = (@_);
    my ($de, $al, $u, $U) = ($mem->de, $mem->al, $mem->u, $mem->U);
    $U = [ map uc, @$u ] if $u and not $U;
    $u = [ map lc, @$U ] if $U and not $u;
    $de ||= 'X';
    $al ||= 'unikodo';
    my $modelfolio = join '|', map quotemeta,
            $u
            ? (@{ $cxapeloj{$de} }[ 0 .. 9 ], @$u)
            : @{ $cxapeloj{$de} };
    my %transkodotabelo =
        map { ($cxapeloj{$de}[$_] => $cxapeloj{$al}[$_]) } 0 .. 11;
    if ($u) {
        delete @transkodotabelo{ @{ $cxapeloj{$de} }[10, 11] };
        $transkodotabelo{$_} = $cxapeloj{$al}[10] for @$U;
        $transkodotabelo{$_} = $cxapeloj{$al}[11] for @$u;
    }
    @tekstoj = map { $_ =~ s/($modelfolio)/$transkodotabelo{$1}/g; $_ } @tekstoj;
    return wantarray ? @tekstoj : $tekstoj[-1];
}

1;

__END__

=head1 NAME

Lingua::EO::Supersignoj - Convert Esperanto characters

=head1 SYNOPSIS

    use Lingua::EO::Supersignoj;

    my $transkodigilo = Lingua::EO::Supersignoj->nova(
        de => 'fronte',
        al => 'X',
        u  => 'u*'
    );
    print $transkodigilo->transkodigu('Mia ^suoj estas ankau* en la ^cambro.');
    # prints: Mia sxuoj estas ankaux en la cxambro.
    
    my $transkodigilo = Lingua::EO::Supersignoj->nova(de => 'X');

    for (qw(X x H h poste fronte apostrofoj iso unikodo)) {
        $transkodigilo->al = $_;
        print $transkodigilo->transkodigu(
            'Laux Ludoviko Zamenhof bongustas ' .
            'fresxa cxecxa mangxajxo kun spicoj.'
        );
    }
    
=head1 DESCRIPTION

Esperanto has 6 letters that ASCII doesn't have. These characters do exist in
Unicode and ISO-8859-3. This object orientated module makes conversion easier.

=head2 Constructor

=over 12

=item nova

Returns a converter object. Takes name => value pairs to populate object
properties.

=back

=head2 Properties

=over 12

=item de

The character set to convert B<from>. Must be one of the sets listed below.

=item al

The character set to convert B<to>. Must be one of the sets listed below.

=item u

An alternative collection of surrogates for u with a caron to be converted.
Must be either a single scalar or an array reference.

If any alternative for u-caron or U-caron is given, the ones from the
source character set are not used.

To leave u's alone, assign a reference to an empty array:
C<< $objekto->u = []; >>.

=item U

Same as C<u>, but for uppercase U.

=back

=head2 Method

=over 12

=item transkodigu

Takes one or more strings to convert and returns a list of converted strings.

Converts from C<X> if C<< $objekto->de >> has not been set.

Converts to C<unikodo> if C<< $objekto->al >> has not been set.

=back

=head1 CHARACTER SETS

The character sets are array references in %Lingua::EO::Supersignoj::cxapeloj.
Feel free to add your own.

=over 12

=item h

Ch ch Gh gh Hh hh Jh jh Sh sh Uw uw

=item H

CH ch GH gh HH hh JH jh SH sh UW uw

=item x

Cx cx Gx gx Hx hx Jx jx Sx sx Ux ux

=item X

CX cx GX gx HX hx JX jx SX sx UX ux

=item poste

C^ c^ G^ g^ H^ h^ J^ j^ S^ s^ U^ u^

=item fronte

^C ^c ^G ^g ^H ^h ^J ^j ^S ^s ^U ^u

=item apostrofoj

C' c' G' g' H' h' J' j' S' s' U' u'

=item iso

198 230 216 248 166 182 172 188 222 254 221 253
(iso-8859-3/9)

=item unikodo

264 265 284 285 292 293 308 309 348 349 364 365
    
=back

=head1 TODO / KNOWN ISSUES

There currently is no way to define an alternative u-caron to convert B<to>.

Since converting bare C<u> without diacritic would require a word list, this
module does not provide such functionality.

=head1 AUTHOR

Juerd <juerd@cpan.org> <http://juerd.nl/>

=head1 SEE ALSO

L<perl>, L<encoding>, L<perlunicode>.

=cut
