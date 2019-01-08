package HackaMol::PeriodicTable;
$HackaMol::PeriodicTable::VERSION = '0.051';
#ABSTRACT: package for period table data... needs to change
use 5.008;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(%KNOWN_NAMES %ATOM_MULTIPLICITY @EXHEAT @ELEMENTS
  %ELEMENTS %ATOMIC_MASSES @COVALENT_RADII @VDW_RADII _element_name _trim _qstring_num);

# lifted from Ivan's PerlMol
our @ELEMENTS = qw(
  X
  H                                                                   He
  Li  Be                                          B   C   N   O   F   Ne
  Na  Mg                                          Al  Si  P   S   Cl  Ar
  K   Ca  Sc  Ti  V   Cr  Mn  Fe  Co  Ni  Cu  Zn  Ga  Ge  As  Se  Br  Kr
  Rb  Sr  Y   Zr  Nb  Mo  Tc  Ru  Rh  Pd  Ag  Cd  In  Sn  Sb  Te  I   Xe
  Cs  Ba
  La  Ce  Pr  Nd  Pm  Sm  Eu  Gd  Tb  Dy  Ho  Er  Tm  Yb
  Lu  Hf  Ta  W   Re  Os  Ir  Pt  Au  Hg  Tl  Pb  Bi  Po  At  Rn
  Fr  Ra
  Ac  Th  Pa  U   Np  Pu  Am  Cm  Bk  Cf  Es  Fm  Md  No
  Lr  Rf  Db  Sg  Bh  Hs  Mt  Ds  Uuu Uub Uut Uuq Uup Uuh Uus Uuo
);

our %ELEMENTS;
$ELEMENTS{ $ELEMENTS[$_] } = $_ foreach ( 0 .. $#ELEMENTS );
$ELEMENTS{D} = $ELEMENTS{T} = 1;

# lifted from Ivan's PerlMol
our %ATOMIC_MASSES = (
    H  => 1.00794,
    D  => 2.014101,
    T  => 3.016049,
    He => 4.002602,
    Li => 6.941,
    Be => 9.012182,
    B  => 10.811,
    C  => 12.0107,
    N  => 14.00674,
    O  => 15.9994,
    F  => 18.9984032,
    Ne => 20.1797,
    Na => 22.989770,
    Mg => 24.3050,
    Al => 26.981538,
    Si => 28.0855,
    P  => 30.973761,
    S  => 32.066,
    Cl => 35.4527,
    Ar => 39.948,
    K  => 39.0983,
    Ca => 40.078,
    Sc => 44.955910,
    Ti => 47.867,
    V  => 50.9415,
    Cr => 51.9961,
    Mn => 54.938049,
    Fe => 55.845,
    Co => 58.933200,
    Ni => 58.6934,
    Cu => 63.546,
    Zn => 65.382,
    Ga => 69.723,
    Ge => 72.61,
    As => 74.92160,
    Se => 78.96,
    Br => 79.904,
    Kr => 83.80,
    Rb => 85.4678,
    Sr => 87.62,
    Y  => 88.90585,
    Zr => 91.224,
    Nb => 92.90638,
    Mo => 95.94,
    Tc => 98,
    Ru => 101.07,
    Rh => 102.90550,
    Pd => 106.42,
    Ag => 107.8682,
    Cd => 112.411,
    In => 114.818,
    Sn => 118.710,
    Sb => 121.760,
    Te => 127.60,
    I  => 126.90447,
    Xe => 131.29,
    Cs => 132.90545,
    Ba => 137.327,
    La => 138.9055,
    Ce => 140.116,
    Pr => 140.90765,
    Nd => 144.24,
    Pm => 145,
    Sm => 150.36,
    Eu => 151.964,
    Gd => 157.25,
    Tb => 158.92534,
    Dy => 162.50,
    Ho => 164.93032,
    Er => 167.26,
    Tm => 168.93421,
    Yb => 173.04,
    Lu => 174.967,
    Hf => 178.49,
    Ta => 180.9479,
    W  => 183.84,
    Re => 186.207,
    Os => 190.23,
    Ir => 192.217,
    Pt => 195.078,
    Au => 196.96655,
    Hg => 200.592,
    Tl => 204.3833,
    Pb => 207.2,
    Bi => 208.98038,
    Po => 209,
    At => 210,
    Rn => 222,
    Fr => 223,
    Ra => 226,
    Ac => 227,
    Th => 232.038,
    Pa => 231.03588,
    U  => 238.0289,
    Np => 237,
    Pu => 244,
    Am => 243,
    Cm => 247,
    Bk => 247,
    Cf => 251,
    Es => 252,
    Fm => 257,
    Md => 258,
    No => 259,
    Lr => 262,
    Rf => 261,
    Db => 262,
    Sg => 266,
    Bh => 264,
    Hs => 269,
    Mt => 268,
    Ds => 271,
    X  => 0.0,
);

our %ATOM_MULTIPLICITY = (

    # from jerry's thermo script
    # see webelements.com .. thinking about term symbols and shit like that
    H  => 2,
    C  => 3,
    N  => 4,
    O  => 3,
    F  => 2,
    P  => 4,
    S  => 3,
    Cl => 2,
    Br => 2,
    I  => 2,
    Hg => 1,
);

# directly from MNDO99, which grabbed them from mopac
# I believe these are at 298, from the thermo gaussian thingy
# enthalpy correction from 0K (as calculated by gaussian) to 298
# is on the order of 1 kcal/mol, which seems silly to mess with
# unless one is actually interested in absolute heats of formation
# SEQM HOF is something like this:
#  HoF(M) = tot_Eelec(M) - sum(x[X]*Hof_exp[X] -x[X]*atom_energy)
our @EXHEAT;
$EXHEAT[0]  = 0.000;
$EXHEAT[1]  = 52.102;
$EXHEAT[2]  = 0.000;
$EXHEAT[3]  = 38.410;
$EXHEAT[4]  = 76.960;
$EXHEAT[5]  = 135.700;
$EXHEAT[6]  = 170.890;
$EXHEAT[7]  = 113.000;
$EXHEAT[8]  = 59.559;
$EXHEAT[9]  = 18.890;
$EXHEAT[10] = 0.000;
$EXHEAT[11] = 25.650;
$EXHEAT[12] = 35.000;
$EXHEAT[13] = 79.490;
$EXHEAT[14] = 108.390;
$EXHEAT[15] = 75.570;
$EXHEAT[16] = 66.400;
$EXHEAT[17] = 28.990;
$EXHEAT[18] = 0.000;
$EXHEAT[19] = 21.420;
$EXHEAT[20] = 42.600;
$EXHEAT[21] = 90.300;
$EXHEAT[22] = 112.300;
$EXHEAT[23] = 122.900;
$EXHEAT[24] = 95.000;
$EXHEAT[25] = 67.700;
$EXHEAT[26] = 99.300;
$EXHEAT[27] = 102.400;
$EXHEAT[28] = 102.800;
$EXHEAT[29] = 80.700;
$EXHEAT[30] = 31.170;
$EXHEAT[31] = 65.400;
$EXHEAT[32] = 89.500;
$EXHEAT[33] = 72.300;
$EXHEAT[34] = 54.300;
$EXHEAT[35] = 26.740;
$EXHEAT[36] = 0.000;
$EXHEAT[37] = 19.600;
$EXHEAT[38] = 39.100;
$EXHEAT[39] = 101.500;
$EXHEAT[40] = 145.500;
$EXHEAT[41] = 172.400;
$EXHEAT[42] = 157.300;
$EXHEAT[43] = 0.000;
$EXHEAT[44] = 155.500;
$EXHEAT[45] = 133.000;
$EXHEAT[46] = 90.000;
$EXHEAT[47] = 68.100;
$EXHEAT[48] = 26.720;
$EXHEAT[49] = 58.000;
$EXHEAT[50] = 72.200;
$EXHEAT[51] = 63.200;
$EXHEAT[52] = 47.000;
$EXHEAT[53] = 25.517;
$EXHEAT[54] = 0.000;
$EXHEAT[55] = 18.700;
$EXHEAT[56] = 42.500;
$EXHEAT[57] = 0.000;
$EXHEAT[58] = 101.300;
$EXHEAT[59] = 0.000;
$EXHEAT[60] = 0.000;
$EXHEAT[61] = 0.000;
$EXHEAT[62] = 49.400;
$EXHEAT[63] = 0.000;
$EXHEAT[64] = 0.000;
$EXHEAT[65] = 0.000;
$EXHEAT[66] = 0.000;
$EXHEAT[67] = 0.000;
$EXHEAT[68] = 75.800;
$EXHEAT[69] = 0.000;
$EXHEAT[70] = 36.350;
$EXHEAT[71] = 0.000;
$EXHEAT[72] = 148.000;
$EXHEAT[73] = 186.900;
$EXHEAT[74] = 203.100;
$EXHEAT[75] = 185.000;
$EXHEAT[76] = 188.000;
$EXHEAT[77] = 160.000;
$EXHEAT[78] = 135.200;
$EXHEAT[79] = 88.000;
$EXHEAT[80] = 14.690;
$EXHEAT[81] = 43.550;
$EXHEAT[82] = 46.620;
$EXHEAT[83] = 50.100;
$EXHEAT[84] = 0.000;
$EXHEAT[85] = 0.000;
$EXHEAT[86] = 34.800;

our @COVALENT_RADII = (

#in pm http://en.wikipedia.org/wiki/Covalent_radius
# P. Pyykkö, M. Atsumi (2009).
#"Molecular Single-Bond Covalent Radii for Elements 1-118". Chemistry: A European Journal 15: 186–197.
# doi:10.1002/chem.200800987.
# P. Pyykkö, M. Atsumi (2009).
# "Molecular Double-Bond Covalent Radii for Elements Li–E112". Chemistry: A European Journal 15 (46):
# 12770–12779.
# doi:10.1002/chem.200901472.. Figure 3 of this paper contains all radii of refs. The mean-square deviation of each set is 3 pm.
# P. Pyykkö, S. Riedel, M. Patzschke (2005).
# "Triple-Bond Covalent Radii". Chemistry: A European Journal 11 (12): 3511–3520.
# doi:10.1002/chem.200401299. PMID 15832398.
# Z   sng  dub  trip  all in pm
    [ 0,   0,   '-', '-' ],
    [ 1,   32,  '-', '-' ],
    [ 2,   46,  '-', '-' ],
    [ 3,   133, 133, 124 ],
    [ 4,   102, 90,  85 ],
    [ 5,   85,  78,  73 ],
    [ 6,   75,  67,  60 ],
    [ 7,   71,  60,  54 ],
    [ 8,   63,  57,  53 ],
    [ 9,   64,  59,  53 ],
    [ 10,  67,  96,  '-' ],
    [ 11,  155, 160, '-' ],
    [ 12,  139, 132, 127 ],
    [ 13,  126, 113, 111 ],
    [ 14,  116, 107, 102 ],
    [ 15,  111, 102, 94 ],
    [ 16,  103, 94,  95 ],
    [ 17,  99,  95,  93 ],
    [ 18,  96,  107, 96 ],
    [ 19,  196, 193, '-' ],
    [ 20,  171, 147, 133 ],
    [ 21,  148, 116, 114 ],
    [ 22,  136, 117, 108 ],
    [ 23,  134, 112, 106 ],
    [ 24,  122, 111, 103 ],
    [ 25,  119, 105, 103 ],
    [ 26,  116, 109, 102 ],
    [ 27,  111, 103, 96 ],
    [ 28,  110, 101, 101 ],
    [ 29,  112, 115, 120 ],
    [ 30,  118, 120, '-' ],
    [ 31,  124, 117, 121 ],
    [ 32,  121, 111, 114 ],
    [ 33,  121, 114, 106 ],
    [ 34,  116, 107, 107 ],
    [ 35,  114, 109, 110 ],
    [ 36,  117, 121, 108 ],
    [ 37,  210, 202, '-' ],
    [ 38,  185, 157, 139 ],
    [ 39,  163, 130, 124 ],
    [ 40,  154, 127, 121 ],
    [ 41,  147, 125, 116 ],
    [ 42,  138, 121, 113 ],
    [ 43,  128, 120, 110 ],
    [ 44,  125, 114, 103 ],
    [ 45,  125, 110, 106 ],
    [ 46,  120, 117, 112 ],
    [ 47,  128, 139, 137 ],
    [ 48,  136, 144, '-' ],
    [ 49,  142, 136, 146 ],
    [ 50,  140, 130, 132 ],
    [ 51,  140, 133, 127 ],
    [ 52,  136, 128, 121 ],
    [ 53,  133, 129, 125 ],
    [ 54,  131, 135, 122 ],
    [ 55,  232, 209, '-' ],
    [ 56,  196, 161, 149 ],
    [ 57,  180, 139, 139 ],
    [ 58,  163, 137, 131 ],
    [ 59,  176, 138, 128 ],
    [ 60,  174, 137, '-' ],
    [ 61,  173, 135, '-' ],
    [ 62,  172, 134, '-' ],
    [ 63,  168, 134, '-' ],
    [ 64,  169, 135, 132 ],
    [ 65,  168, 135, '-' ],
    [ 66,  167, 133, '-' ],
    [ 67,  166, 133, '-' ],
    [ 68,  165, 133, '-' ],
    [ 69,  164, 131, '-' ],
    [ 70,  170, 129, '-' ],
    [ 71,  162, 131, 131 ],
    [ 72,  152, 128, 122 ],
    [ 73,  146, 126, 119 ],
    [ 74,  137, 120, 115 ],
    [ 75,  131, 119, 110 ],
    [ 76,  129, 116, 109 ],
    [ 77,  122, 115, 107 ],
    [ 78,  123, 112, 110 ],
    [ 79,  124, 121, 123 ],
    [ 80,  133, 142, '-' ],
    [ 81,  144, 142, 150 ],
    [ 82,  144, 135, 137 ],
    [ 83,  151, 141, 135 ],
    [ 84,  145, 135, 129 ],
    [ 85,  147, 138, 138 ],
    [ 86,  142, 145, 133 ],
    [ 87,  223, 218, '-' ],
    [ 88,  201, 173, 159 ],
    [ 89,  186, 153, 140 ],
    [ 90,  175, 143, 136 ],
    [ 91,  169, 138, 129 ],
    [ 92,  170, 134, 118 ],
    [ 93,  171, 136, 116 ],
    [ 94,  172, 135, '-' ],
    [ 95,  166, 135, '-' ],
    [ 96,  166, 136, '-' ],
    [ 97,  168, 139, '-' ],
    [ 98,  168, 140, '-' ],
    [ 99,  165, 140, '-' ],
    [ 100, 167, '-', '-' ],
    [ 101, 173, 139, '-' ],
    [ 102, 176, '-', '-' ],
    [ 103, 161, 141, '-' ],
    [ 104, 157, 140, 131 ],
    [ 105, 149, 136, 126 ],
    [ 106, 143, 128, 121 ],
    [ 107, 141, 128, 119 ],
    [ 108, 134, 125, 118 ],
    [ 109, 129, 125, 113 ],
    [ 110, 128, 116, 112 ],
    [ 111, 121, 116, 118 ],
    [ 112, 122, 137, 130 ],
    [ 113, 136, '-', '-' ],
    [ 114, 143, '-', '-' ],
    [ 115, 162, '-', '-' ],
    [ 116, 175, '-', '-' ],
    [ 117, 165, '-', '-' ],
    [ 118, 157, '-', '-' ],
);

our @VDW_RADII = (

    # http://en.wikipedia.org/wiki/Atomic_radii_of_the_elements_%28data_page%29
    # the covalent vals are shady on this page
    [ 0,   0 ],
    [ 1,   120 ],
    [ 2,   140 ],
    [ 3,   182 ],
    [ 4,   153 ],
    [ 5,   192 ],
    [ 6,   170 ],
    [ 7,   155 ],
    [ 8,   152 ],
    [ 9,   147 ],
    [ 10,  154 ],
    [ 11,  227 ],
    [ 12,  173 ],
    [ 13,  184 ],
    [ 14,  210 ],
    [ 15,  180 ],
    [ 16,  180 ],
    [ 17,  175 ],
    [ 18,  188 ],
    [ 19,  275 ],
    [ 20,  231 ],
    [ 21,  211 ],
    [ 22,  999 ],
    [ 23,  999 ],
    [ 24,  999 ],
    [ 25,  999 ],
    [ 26,  999 ],
    [ 27,  999 ],
    [ 28,  163 ],
    [ 29,  140 ],
    [ 30,  139 ],
    [ 31,  187 ],
    [ 32,  211 ],
    [ 33,  185 ],
    [ 34,  190 ],
    [ 35,  185 ],
    [ 36,  202 ],
    [ 37,  303 ],
    [ 38,  249 ],
    [ 39,  999 ],
    [ 40,  999 ],
    [ 41,  999 ],
    [ 42,  999 ],
    [ 43,  999 ],
    [ 44,  999 ],
    [ 45,  999 ],
    [ 46,  163 ],
    [ 47,  172 ],
    [ 48,  158 ],
    [ 49,  193 ],
    [ 50,  217 ],
    [ 51,  206 ],
    [ 52,  206 ],
    [ 53,  198 ],
    [ 54,  216 ],
    [ 55,  343 ],
    [ 56,  268 ],
    [ 57,  999 ],
    [ 58,  999 ],
    [ 59,  999 ],
    [ 60,  999 ],
    [ 61,  999 ],
    [ 62,  999 ],
    [ 63,  999 ],
    [ 64,  999 ],
    [ 65,  999 ],
    [ 66,  999 ],
    [ 67,  999 ],
    [ 68,  999 ],
    [ 69,  999 ],
    [ 70,  999 ],
    [ 71,  999 ],
    [ 72,  999 ],
    [ 73,  999 ],
    [ 74,  999 ],
    [ 75,  999 ],
    [ 76,  999 ],
    [ 77,  999 ],
    [ 78,  175 ],
    [ 79,  166 ],
    [ 80,  155 ],
    [ 81,  196 ],
    [ 82,  202 ],
    [ 83,  207 ],
    [ 84,  197 ],
    [ 85,  202 ],
    [ 86,  220 ],
    [ 87,  348 ],
    [ 88,  283 ],
    [ 89,  999 ],
    [ 90,  999 ],
    [ 91,  999 ],
    [ 92,  186 ],
    [ 93,  999 ],
    [ 94,  999 ],
    [ 95,  999 ],
    [ 96,  999 ],
    [ 97,  999 ],
    [ 98,  999 ],
    [ 99,  999 ],
    [ 100, 999 ],
    [ 101, 999 ],
    [ 102, 999 ],
    [ 103, 999 ],
    [ 104, 999 ],
    [ 105, 999 ],
    [ 106, 999 ],
    [ 107, 999 ],
    [ 108, 999 ],
    [ 109, 999 ],
    [ 110, 999 ],
    [ 111, 999 ],
    [ 112, 999 ],
    [ 113, 999 ],
    [ 114, 999 ],
    [ 115, 999 ],
    [ 116, 999 ],
    [ 117, 999 ],
    [ 118, 999 ],
);

our %KNOWN_NAMES;
$KNOWN_NAMES{$_} = 'C' foreach qw(C CA CB CD CD1 CD2 CE CE1 
                                 CE2 CE3 CG CG1 CG2 CH2 CZ CZ2 CZ3);
$KNOWN_NAMES{$_} = 'H' foreach qw(H H1 H2 H3 H4 HA HA1 HA2 HB HB1 HB2 HB3 HD1 HD11 
                                 HD12 HD13 HD2 HD21 HD22 HD23 HD3 HE 
                                 HE1 HE2 HE21 HE22 HE3 HG HG1 HG11 HG12 
                                 HG13 HG2 HG21 HG22 HG23 HH HH11 HH12 HH2 
                                 HH21 HH22 HN HT1 HT2 HT3 HZ HZ1 HZ2 HZ3
                                 DUM); 
$KNOWN_NAMES{$_} = 'N' foreach qw(N ND1 ND2 NE NE1 NE2 NH1 NH2 NZ);
$KNOWN_NAMES{$_} = 'O' foreach qw(O OD1 OD2 OE1 OE2 OG OG1 OH OT1 OT2 OH2 OXT);
$KNOWN_NAMES{$_} = 'S' foreach qw(S SD SG);
$KNOWN_NAMES{$_} = 'Cl' foreach qw(CLA);
$KNOWN_NAMES{$_} = 'Na' foreach qw(SOD);
$KNOWN_NAMES{$_} = 'K'  foreach qw(POT);

sub _trim {
    my $string = shift;
    $string =~ s/^\s+//;

    #   $string =~ s/\s+$//; #unpack will delete the \s+ in the end;
    return $string;
}

sub _qstring_num {

    # _qstring something like 2+  or 2-
    my $string = shift;
    $string =~ s/\+//;
    $string =~ s/(.*?)(\-)/$2$1/;
    $string = sprintf( "%g", $string );
    return $string;

}

sub _element_name {

    # guess the element using the atom name
    my $name = uc(shift);
    my $dirt = 0;
    unless ( exists( $KNOWN_NAMES{$name} ) ) {

#carp "$name doesn not exist in HackaMol::PeriodicTable, if common please add to KNOWN_NAMES";
        $dirt = 1;
        my $symbol = substr $name, 0, 1; #doesn't work if two letters for symbol
        $symbol = 'C' if ($symbol eq 'A');
        return ( $symbol, $dirt );
    }
    return ( $KNOWN_NAMES{$name}, $dirt );
}


1;

__END__

=pod

=head1 NAME

HackaMol::PeriodicTable - package for period table data... needs to change

=head1 VERSION

version 0.051

=head1 EXTENDS

=over 4

=item * L<Exporter>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
