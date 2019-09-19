package MS::Protein;

use strict;
use warnings;

use Carp;
use Exporter qw/import/;
use List::Util qw/any sum/;
use List::MoreUtils qw/uniq/;
use Scalar::Util qw/blessed/;

use MS::Mass qw/:all/;
use MS::CV   qw/:MS regex_for/;
use MS::Peptide;

use parent qw/MS::Peptide/;

BEGIN {

    *ec = \&extinction_coefficient; 
    *pI = \&isoelectric_point; 
    *ai = \&aliphatic_index; 
    *mw = \&molecular_weight; 

}

our @EXPORT_OK = qw/
    digest
    isoelectric_point
    pI
    molecular_weight
    mw
    gravy
    aliphatic_index
    ai
    n_residues
    n_atoms
    extinction_coefficient
    ec
    charge_at_pH
/;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

# build lookup tables
my $kyte_doolittle = _kyte_doolittle();
my $pK  = _pK();
my $pKt = _pKt();

sub molecular_weight {

    my ($seq, $type) = @_;
    return sum( map {aa_mass($_, $type) // return undef}
        split('', $seq) ) + formula_mass('H2O');

}

sub n_atoms {

    my ($seq) = @_;
    my %counts;
    ++$counts{$_} for (split '', $seq);
    my %atoms = (H => 2, O => 1);
    for my $aa (keys %counts) {
        my $a = atoms('aa' => $aa);
        $atoms{$_} += $a->{$_}*$counts{$aa} for (keys %$a);
    }
    return \%atoms; 

}

sub n_residues {

    my ($seq) = @_;
    my %counts;
    ++$counts{$_} for (split '', $seq);
    return \%counts;

}

sub aliphatic_index {

    my ($seq) = @_;

    $seq = "$seq";
    my $mf_A   = $seq =~ tr/A//;
    my $mf_V   = $seq =~ tr/V//;
    my $mf_IL  = $seq =~ tr/IL//;

    return ($mf_A + 2.9*$mf_V + 3.9*$mf_IL) * 100 / length($seq);

}

sub extinction_coefficient {

    my ($seq, %args) = @_;

    my $is_reduced = $args{reduced};

    $seq = "$seq";
    my $Y = $seq =~ tr/Y//;
    my $W = $seq =~ tr/W//;
    my $C = $seq =~ tr/C//;

    return $is_reduced
        ? 1490*$Y + 5500*$W
        : 1490*$Y + 5500*$W + 125*int($C/2);

}

sub gravy {

    my ($seq) = @_;
    return sum( map {$kyte_doolittle->{$_}} split( '', $seq) )
        / length($seq);

}

sub digest {

    my ($arg1, %args) = @_;

    # can be used as function or method, so test whether first argument is
    # MS::Protein object (otherwise should be simple string)
    my $as_method = ref($arg1) && blessed($arg1) && $arg1->isa('MS::Protein');

    my $seq     = $as_method ? $arg1->seq : $arg1;
    my $enzymes = $args{enzymes} // croak "enzyme must be specified";
    my $missed  = $args{missed}  // 0;
    my $min_len = $args{min_len} // 1;

    my @re = map {regex_for($_)} @$enzymes;
    croak "one or more enzyme CVs are not valid" if (any {! defined $_} @re);

    my @cut_sites = (0);

    for (@re) {
        while ($seq =~ /$_/ig) {
            push @cut_sites, $-[0];
        }
    }

    my $seq_len = length $seq;
    push @cut_sites, $seq_len;
    @cut_sites = sort {$a <=> $b} uniq @cut_sites;

    my @peptides;
    for my $i (0..$#cut_sites) {
        A:
        for my $a (1..$missed+1) {
            $a = $i + $a;
            last A if ($a > $#cut_sites);
            my $str = substr $seq, $cut_sites[$i],
                $cut_sites[$a]-$cut_sites[$i];
            next if (length($str) < $min_len);
            if ($as_method) {

                push @peptides, $arg1->range(
                    $cut_sites[$i]+1,
                    $cut_sites[$a],
                );
                
            }
            else {

                #return simple strings
                push @peptides, $str;

            }
        }
    }
    
    return @peptides

}

sub isoelectric_point {

    my ($seq) = @_;
    $seq = "$seq"; # convert object to string if needed

    # the ProMoST webserver counts charged terminal residues twice
    # (maybe a bug). Swap comments to emulate this behavior.
    #my $nt  = substr $seq, 0,  1;
    #my $ct  = substr $seq, -1, 1;
    my $nt  = substr $seq, 0,  1, '';
    my $ct  = substr $seq, -1, 1, '';
    my $res = n_residues($seq);

    my $z        = 1;
    my $pH       = 7;
    my $cut      = 0.002;
    my $upper    = 14;
    my $lower    = 0;
    my $max_iter = 100;

    for (1..$max_iter) {
        $z     = _charge_at_pH( $nt, $ct, $res, $pH );
        $upper = $z < 0 ? $pH    : $upper;
        $lower = $z < 0 ? $lower : $pH;
        $pH    = ($upper+$lower)/2;
        last if (abs($z) <= $cut);
    }
    return undef if (abs($z) > $cut); # failed to converge
    return $pH;

}

sub charge_at_pH {

    my ($seq, $pH) = @_;
    $seq = "$seq";
    die "Must specify pH"
        if (! defined $pH);

    # the ProMoST webserver counts charged terminal residues twice
    # (maybe a bug). Swap comments to emulate this behavior.
    #my $nt  = substr $seq, 0,  1;
    #my $ct  = substr $seq, -1, 1;
    my $nt  = substr $seq, 0,  1, '';
    my $ct  = substr $seq, -1, 1, '';
    my $res = n_residues($seq);

    return _charge_at_pH( $nt, $ct, $res, $pH );

}
        

sub _charge_at_pH {

    my ($nt, $ct, $other, $pH) = @_;

    my @p = map { ($pK->{$_}->[0]) x ($other->{$_} // 0) } qw/K R H  /;
    my @n = map { ($pK->{$_}->[0]) x ($other->{$_} // 0) } qw/D E C Y/;

    # terminal charges
    push @p, $pKt->{$nt}->[0];
    push @n, defined $ct ? $pKt->{$ct}->[1] : $pKt->{$nt}->[1];

    push @p, $pK->{$nt}->[1] if (any {$nt eq $_} qw/K R H  /); # N-term res
    push @p, $pK->{$ct}->[2] if (any {$ct eq $_} qw/K R H  /); # C-term res
    push @n, $pK->{$nt}->[1] if (any {$nt eq $_} qw/D E C Y/); # N-term res
    push @n, $pK->{$ct}->[2] if (any {$ct eq $_} qw/D E C Y/); # C-term res

    my $Ct = 0;
    $Ct += sum map { 1/(1 + 10**($pH-$_))} @p if (scalar @p);
    $Ct += sum map {-1/(1 + 10**($_-$pH))} @n if (scalar @n);

    return $Ct;

}

sub _kyte_doolittle {

    return {
        A =>  1.8,
        R => -4.5,
        N => -3.5,
        D => -3.5,
        C =>  2.5,
        Q => -3.5,
        E => -3.5,
        G => -0.4,
        H => -3.2,
        I =>  4.5,
        L =>  3.8,
        K => -3.9,
        M =>  1.9,
        F =>  2.8,
        P => -1.6,
        S => -0.8,
        T => -0.7,
        W => -0.9,
        Y => -1.3,
        V =>  4.2,
        X =>  0.0,
    };

}

sub _pK {

    return {   #  in  Nterm  Cterm
        K => [  9.80, 10.00, 10.30 ],
        R => [ 12.50, 11.50, 11.50 ],
        H => [  6.08,  4.89,  6.89 ],
        D => [  4.07,  3.57,  4.57 ],
        E => [  4.45,  4.15,  4.75 ],
        C => [  8.28,  8.00,  9.00 ],
        Y => [  9.84,  9.34, 10.34 ],
    };

}

sub _pKt {

    return {    # N     C
        G => [ 7.50, 3.70 ],
        A => [ 7.58, 3.75 ],
        S => [ 6.86, 3.61 ],
        P => [ 8.36, 3.40 ],
        V => [ 7.44, 3.69 ],
        T => [ 7.02, 3.57 ],
        C => [ 8.12, 3.10 ],
        I => [ 7.48, 3.72 ],
        L => [ 7.46, 3.73 ],
        N => [ 7.22, 3.64 ],
        D => [ 7.70, 3.50 ],
        Q => [ 6.73, 3.57 ],
        K => [ 6.67, 3.40 ],
        E => [ 7.19, 3.50 ],
        M => [ 6.98, 3.68 ],
        H => [ 7.18, 3.17 ],
        F => [ 6.96, 3.98 ],
        R => [ 6.76, 3.41 ],
        Y => [ 6.83, 3.60 ],
        W => [ 7.11, 3.78 ],
    };

}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Protein - A class representing protein species for proteomic analysis

=head1 SYNOPSIS

    use MS::Protein;
    use BioX::Seq::Stream;

    my $p = BioX::Seq::Stream->new('some_proteome.fasta');
    my $seq = $p->next_seq;

    my $pro = MS::Protein->new($seq);

    say "pI:", $pro->isoelectric_point; # or $pro->pI;
    say "MW:", $pro->molecular_weight;  # or $pro->mw;
    say "hydropathy:", $pro->gravy;
    say "AI:", $pro->aliphatic_index;   # or $pro->ai;
    say "EC:", $pro->extinction_coefficient;  # or $pro->ec;

    my $z = $pro->charge_at_pH( 7.0 );

    my $atoms = $pro->n_atoms;
    say "Atom counts:";
    for (keys %$atoms) {
        say join "\t", $_, $atoms->{$_};
    }

    my $res = $pro->n_residues;
    say "Residue counts:";
    for (keys %$res) {
        say join "\t", $_, $res->{$_};
    }

    use MS::CV qw/:MS/; # use enzyme constants

    my @peptides = $pro->digest(
        enzymes => [
           MS_TRYPSIN,
        ],
        missed => 1,
        min_len => 6,
    );

    ## All methods can also be used as functions, e.g.

    my $pi = pI( 'AAPLSYAMK' );
    my $z  = charge_at_pH( 'AAPLSYAMK' );

=head1 DESCRIPTION

B<MS::Protein> is a class representing protein species for use in proteomics
analysis. It inherits from the L<MS::Peptide> class. It is intended to hold
methods more likely to be useful for complete protein sequences, but this
distinction is entirely semantic. There may be times when the methods
contained here may be usefully implied on partial peptide sequences as well.
At some point these methods may be moved into the L<MS::Peptide> class and
this class become a simple stub for L<MS::Peptide>, but the change will be
backward-compatible.

All methods of the class can also be used as functions on simple scalar
strings. This can improve performance in some situations where a large number
of protein (or peptide) sequences are processed. The only method/function that
produces a different output when called as a method vs function is digest(),
as detailed in its documentation below.

=head1 METHODS

All methods of the L<MS::Peptide> class, including the constructor, are shared.
Methods specific to L<MS::Protein> are:

=head2 digest

    use MS::CV qw/:MS/;
    my @peptides = $pro->digest(
        enzymes => [
           MS_TRYPSIN,
        ],
        missed => 1,
        min_len => 6,
    );

Performs an I<in silico>  hydrolytic cleavage on a protein sequence based on
the supplied parameters. When called as a method, returns an array of
L<MS::Peptide> objects representing digested peptides. When called as a
function, returns an array of strings representing digested peptides.
Available options include:

=over

=item * C<enzymes> — a reference to an array of CV terms representing cleavage
enzymes. See details below on finding valid IDs to use. Required.

=item * C<missed> — the number of allowable missed cleavages. All possible valid
peptides satisfying this criterion will be reported. Default: 0.

=item * C<min_len> — the minimum length of peptide to be returned. Default: 1.
be left undefined if not known.

=back

=head3 Enzyme IDs

The method requires that cleavage enzymes be specified by their psi-ms CV
terms, due to the fact that the regex patterns used are also extracted from
the psi-ms CV. The easiest way to do this is to use the constants exported by
L<MS::CV>. A full list of available constants can be exported using:

    use MS::CV;
    MS::CV::print_tree('MS');

and then look for the terms under the 'cleavage agent name' parent term. A
(possibly out of date) list of available constants:

=over

=item * C<MS_TRYPSIN> (Trypsin)

=item * C<MS_TRYPSIN_P> (Trypsin/P)

=item * C<MS_ASP_N> (Asp-N)

=item * C<MS_ARG_C> (Arg-C)

=item * C<MS_LYS_C> (Lys-C)

=item * C<MS_LYS_C_P> (Lys-C/P)

=item * C<MS_LEUKOCYTE_ELASTASE> (leukocyte elastase)

=item * C<MS_GLUTAMYL_ENDOPEPTIDASE> (glutamyl endopeptidase)

=item * C<MS_CNBR> (CNBr)

=item * C<MS_PROLINE_ENDOPEPTIDASE> (proline endopeptidase)

=item * C<MS_2_IODOBENZOATE> (2-iodobenzoate)

=item * C<MS_V8_DE> (V8-DE)

=item * C<MS_FORMIC_ACID> (Formic_acid)

=item * C<MS_CHYMOTRYPSIN> (Chymotrypsin)

=item * C<MS_ASP_N_AMBIC> (Asp-N_ambic)

=item * C<MS_PEPSINA> (PepsinA)

=item * C<MS_V8_E> (V8-E)

=item * C<MS_TRYPCHYMO> (TrypChymo)

=back

=head2 isoelectric_point
=head2 pI

    my $pi = $pro->isoelectric_point;
    my $pi = pI( 'ACDEF' );

Returns the isoelectric point of the protein (the pH at which the net charge
is expected to be zero). The pKA values used are based on those of the ProMoST
webserver (L<https://dx.doi.org/10.1007%2F978-1-60327-834-8_21>).

=head2 molecular_weight
=head2 mw

    my $mw = $pro->molecular_weight;
    my $mw = $pro->mw('mono'); monoisotopic mass
    my $mw = $pro->mw('average'); average mass
    my $mw = mw( 'ACDEF', 'mono' );

Returns the neutral molecular weight of the protein. Takes an optional
argument specifying the type of mass to use (C<mono> for monoisotopic or
C<average> for average mass).

=head2 aliphatic_index
=head2 ai

    my $ai = $pro->aliphatic_index;
    my $ai = $pro->ai;
    my $ai = ai( 'ACDEF' );

Returns the aliphatic index of the protein (the relative volume taken up by
aliphatic side chains). 

=head2 extinction_coefficient
=head2 ec

    my $ec = $pro->extinction_coefficient;
    my $ec = $pro->ec;
    my $ec = ec( 'ACDEF' );

Returns the extinction coefficient of the protein.

=head2 gravy

    my $gravy = $pro->gravy;
    my $gravy = gravy( 'ACDEF' );

Returns the GRAVY (grand average of hydropathy) of a protein. Calculated based
on the values of Kyte and Doolittle
(L<https://doi.org/10.1016/0022-2836(82)90515-0>).

=head2 charge_at_pH

    my $z = $pro->charge_at_pH( 7.0 );
    my $z = charge_at_pH( 'ACDEF', 7.0 );

Returns the expected net charge of the protein at the given pH. The pKA values
used are based on those of the ProMoST webserver
(L<https://dx.doi.org/10.1007%2F978-1-60327-834-8_21>).

=head2 n_atoms

=head2 n_residues

    my $n_res   = $pro->n_residues;
    my $n_res   = n_residues( 'ACDEF' );
    my $n_atoms = $pro->n_atoms;
    my $n_atoms = n_atoms( 'ACDEF' );

Returns a hash reference where the keys are atom or residue names,
respectively, and the values are the counts of those units in the protein.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<InSilicoSpectro>

=back

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2019 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
