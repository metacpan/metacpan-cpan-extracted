package HackaMol::Roles::PdbRole;
$HackaMol::Roles::PdbRole::VERSION = '0.045';
#ABSTRACT: PdbRole of lazy attributes for HackaMol atoms
use Moose::Role;
use Carp;

my %aa321 = (
  ALA=>'A', ARG=>'R', ASN=>'N', ASP=>'D', CYS=>'C',
  GLU=>'E', GLN=>'Q', GLY=>'G', HIS=>'H', ILE=>'I',
  LEU=>'L', LYS=>'K', MET=>'M', PHE=>'F', PRO=>'P',
  SER=>'S', THR=>'T', TRP=>'W', TYR=>'Y', VAL=>'V',
  SEC=>'U',
);

sub aa321 {
  my $resname = uc($_[0]->resname);
  unless ( exists($aa321{$resname}) ){
    carp "PDBRole> residue $resname name has no 1 letter code; return X";
    return ('X');
  }
  return ($aa321{$resname});
}

has 'record_name', is => 'rw', isa => 'Str', lazy => 1, default => 'HETATM';
has 'occ',         is => 'rw', isa => 'Num', lazy => 1, default => 1.0;
has 'bfact',       is => 'rw', isa => 'Num', lazy => 1, default => 20.0;
has 'resname',     is => 'rw', isa => 'Str', lazy => 1, default => 'UNK';
has 'chain',       is => 'rw', isa => 'Str', lazy => 1, default => ' ';
has 'altloc',      is => 'rw', isa => 'Str', lazy => 1, default => ' ';
has 'icode',       is => 'rw', isa => 'Str', lazy => 1, default => ' ';
has 'pdbid',       is => 'rw', isa => 'Str', lazy => 1, default => ' ';
has 'segid',       is => 'rw', isa => 'Str', lazy => 1, default => ' ';
has 'iatom',       is => 'rw', isa => 'Int', lazy => 1, default => 0;
has 'resid',       is => 'rw', isa => 'Int', lazy => 1, default => 1;
has 'serial',      is => 'rw', isa => 'Int', lazy => 1, default => 1;
has 'sasa',        is => 'rw', isa => 'Num', lazy => 1, default => 0.0;

#lifted from Bio::PDB::Structure::Atom. Thank you, Raul Alcantara Aragon!


my %pdb_atom_names = (
    'C'    => ' C  ',
    'C1'   => ' C1 ',
    'C1A'  => ' C1A',
    'C1B'  => ' C1B',
    'C1C'  => ' C1C',
    'C1D'  => ' C1D',
    'C2'   => ' C2 ',
    'C2A'  => ' C2A',
    'C2B'  => ' C2B',
    'C2C'  => ' C2C',
    'C2D'  => ' C2D',
    'C3'   => ' C3 ',
    'C3A'  => ' C3A',
    'C3B'  => ' C3B',
    'C3C'  => ' C3C',
    'C3D'  => ' C3D',
    'C4'   => ' C4 ',
    'C4A'  => ' C4A',
    'C4A'  => ' C4A',
    'C4B'  => ' C4B',
    'C4C'  => ' C4C',
    'C4D'  => ' C4D',
    'C5'   => ' C5 ',
    'C6'   => ' C6 ',
    'CA'   => ' CA ',
    'CAA'  => ' CAA',
    'CAB'  => ' CAB',
    'CAC'  => ' CAC',
    'CAD'  => ' CAD',
    'CB'   => ' CB ',
    'CBA'  => ' CBA',
    'CBB'  => ' CBB',
    'CBC'  => ' CBC',
    'CBD'  => ' CBD',
    'CD'   => ' CD ',
    'CD1'  => ' CD1',
    'CD2'  => ' CD2',
    'CE'   => ' CE ',
    'CE1'  => ' CE1',
    'CE2'  => ' CE2',
    'CE3'  => ' CE3',
    'CG'   => ' CG ',
    'CG1'  => ' CG1',
    'CG2'  => ' CG2',
    'CGA'  => ' CGA',
    'CGD'  => ' CGD',
    'CH2'  => ' CH2',
    'CHA'  => ' CHA',
    'CHB'  => ' CHB',
    'CHC'  => ' CHC',
    'CHD'  => ' CHD',
    'CMA'  => ' CMA',
    'CMB'  => ' CMB',
    'CMC'  => ' CMC',
    'CMD'  => ' CMD',
    'CZ'   => ' CZ ',
    'CZ2'  => ' CZ2',
    'CZ3'  => ' CZ3',
    'FE'   => 'FE  ',
    'H'    => ' H  ',
    'HA'   => ' HA ',
    'HB'   => ' HB ',
    'HG'   => ' HG ',
    'HE'   => ' HE ',
    'HZ'   => ' HZ ',
    'HH'   => ' HH ',
    '1H'   => '1H  ',
    '2H'   => '2H  ',
    '3H'   => '3H  ',
    '1HA'  => '1HA ',
    '1HB'  => '1HB ',
    '1HD'  => '1HD ',
    '1HE'  => '1HE ',
    '1HG'  => '1HG ',
    '1HZ'  => '1HZ ',
    '2HA'  => '2HA ',
    '2HB'  => '2HB ',
    '2HD'  => '2HD ',
    '2HE'  => '2HE ',
    '2HG'  => '2HG ',
    '1HZ'  => '1HZ ',
    '2HZ'  => '2HZ ',
    '3HB'  => '3HB ',
    '3HE'  => '3HE ',
    '3HZ'  => '3HZ ',
    'N'    => ' N  ',
    'NA'   => ' NA ',
    'NB'   => ' NB ',
    'NC'   => ' NC ',
    'ND'   => ' ND ',
    'N A'  => ' N A',
    'N B'  => ' N B',
    'N C'  => ' N C',
    'N D'  => ' N D',
    'N1'   => ' N1 ',
    'N2'   => ' N2 ',
    'N3'   => ' N3 ',
    'ND1'  => ' ND1',
    'ND2'  => ' ND2',
    'NE'   => ' NE ',
    'NE1'  => ' NE1',
    'NE2'  => ' NE2',
    'NH1'  => ' NH1',
    'NH2'  => ' NH2',
    'NZ'   => ' NZ ',
    'O'    => ' O  ',
    'O1'   => ' O1 ',
    'O1A'  => ' O1A',
    'O1D'  => ' O1D',
    'O2'   => ' O2 ',
    'O2A'  => ' O2A',
    'O2D'  => ' O2D',
    'O3'   => ' O3 ',
    'O4'   => ' O4 ',
    'O5'   => ' O5 ',
    'O6'   => ' O6 ',
    'OD1'  => ' OD1',
    'OD2'  => ' OD2',
    'OE1'  => ' OE1',
    'OE2'  => ' OE2',
    'OG'   => ' OG ',
    'OG1'  => ' OG1',
    'OH'   => ' OH ',
    'OXT'  => ' OXT',
    'S'    => ' S  ',
    'SD'   => ' SD ',
    'SG'   => ' SG '
);

sub pdb_rename{
  my $self = shift;
  my $name = $self->name;
  if(exists($pdb_atom_names{$self->name})){
    $self->name($pdb_atom_names{$self->name});
  }
  return $name;
}

no Moose::Role;
1;

# added attributes for parsing a PDB file
# Histidine 64 for Human Carbonic Anhydrase II from pdbid: 2CBA
#some lines for reference that did not translate well into POD
#my $lines_H64_2cba = '
#         1         2         3         4         5         6         7         8
#12345678901234567890123456789012345678901234567890123456789012345678901234567890
#ATOM    504  N   HIS A  64      -0.822  -1.995   6.439  1.00 10.63           N
#ATOM    505  CA  HIS A  64      -0.847  -2.773   7.721  1.00 10.22           C
#ATOM    506  C   HIS A  64      -2.270  -3.278   7.949  1.00  9.51           C
#ATOM    507  O   HIS A  64      -2.449  -4.225   8.736  1.00 11.94           O
#ATOM    508  CB AHIS A  64      -0.335  -2.173   8.991  0.70 10.98           C
#ATOM    509  CB BHIS A  64      -0.409  -1.888   8.917  0.20  9.21           C
#ATOM    510  CG AHIS A  64      -0.736  -0.782   9.258  0.70 12.16           C
#ATOM    511  CG BHIS A  64       0.714  -0.964   8.521  0.20  8.70           C
#ATOM    512  ND1AHIS A  64      -1.795  -0.353  10.014  0.70 14.34           N
#ATOM    513  ND1BHIS A  64       0.513   0.338   8.162  0.20  8.57           N
#ATOM    514  CD2AHIS A  64      -0.117   0.344   8.805  0.70 12.79           C
#ATOM    515  CD2BHIS A  64       2.037  -1.198   8.364  0.20  8.90           C
#ATOM    516  CE1AHIS A  64      -1.809   0.971  10.061  0.70 13.80           C
#ATOM    517  CE1BHIS A  64       1.691   0.868   7.814  0.20  8.65           C
#ATOM    518  NE2AHIS A  64      -0.844   1.403   9.281  0.70 15.45           N
#ATOM    519  NE2BHIS A  64       2.615  -0.026   7.936  0.20  6.94           N
#';
#
#my $ATOM_record_format = '
#Record Format:  http://www.wwpdb.org/documentation/format23/sect9.html
#COLUMNS      DATA TYPE        FIELD      DEFINITION
#------------------------------------------------------
# 1 -  6      Record name      "ATOM    "
# 7 - 11      Integer          serial     Atom serial number.
#13 - 16      Atom             name       Atom name.
#17           Character        altLoc     Alternate location indicator.
#18 - 20      Residue name     resName    Residue name.
#22           Character        chainID    Chain identifier.
#23 - 26      Integer          resSeq     Residue sequence number.
#27           AChar            iCode      Code for insertion of residues.
#31 - 38      Real(8.3)        x          Orthogonal coordinates for X in
#                                         Angstroms
#39 - 46      Real(8.3)        y          Orthogonal coordinates for Y in
#                                         Angstroms
#47 - 54      Real(8.3)        z          Orthogonal coordinates for Z in
#                                         Angstroms
#55 - 60      Real(6.2)        occupancy  Occupancy.
#61 - 66      Real(6.2)        tempFactor Temperature factor.
#77 - 78      LString(2)       element    Element symbol, right-justified.
#79 - 80      LString(2)       charge     Charge on the atom.
#';
#

__END__

=pod

=head1 NAME

HackaMol::Roles::PdbRole - PdbRole of lazy attributes for HackaMol atoms

=head1 VERSION

version 0.045

=head1 SYNOPSIS

   use HackaMol::Atom;

   my $atom = Atom->new(Z=>6);

   print $atom->$_ foreach ( qw( 
                              record_name  
                              serial       
                              occ          
                              bfact        
                              resname      
                              chain        
                              altloc       
                              resid        
                              iatom        
                              pdbid        
                              segid  
                            )
   );
    
   foreach my $resn (qw(TRP TYR GLN ASN ETC)){
     $atom->resname($resn);
     print $atom->aa321;
   }

=head1 DESCRIPTION

PdbRole provides atom attributes for PDB parsing.  All attributes are 'rw' and
lazy, so they will not contaminate the namespace unless called upon. The
functionality of the PdbRole may be extended in the future.  An extension 
(HackaMolX::PDB or HackaMol::X::PDB) will be released soon.

=head1 METHODS

=head2 pdb_rename

no arguments.  Returns the current name. Renames the atom based on names used by the PDB (if exists).  This is useful for programs that render the secondary structure of molecules.

=head2 aa321

returns 1 letter code for amino acid. Generated from resname attribute. throws a warning and returns 'X' if residue name is unrecognized.

=head1 ATTRIBUTES

=head2 record_name  

pdb cols 1-6:  ATOM|HETATM.  default = 'HETATM'

=head2 serial       

pdb cols 7-11: index. default = 0

=head2 occ          

pdb cols 55-60: occupancy.  range 0 to 1. default = 1.0  (all there)

=head2 bfact        

pdb cols 61-66: temperature factor. see Willis and Pryor. default = 20.0

=head2 altloc       

pdb col 17. is AHIS and BHIS above. default = ' '

=head2 resname      

pdb cols 18-20: residue name. defaults to 'ALA' 

=head2 chain        

pdb cols 22. protein chain.  default = '  '

=head2 resid        

pdb cols 23-26. residue index. PDB calls is resSeq, but resid is more familiar
(to me). default = 64  

=head2 icode

pdb cols 27. see code comments or
L<http://www.wwpdb.org/documentation/format23/sect9.html>

=head2 pdbid        

a place to store which PDB it came from

=head2 segid 

a CHARMMish parameter that may not belong here. default = 'TIP3'

=head2 iatom        

this is a place for the actual index.  Segid does not have to start from 0 (cut
and paste as above, etc). 

=head2 sasa        

Solvent accessible surface area; isa 'Num'. A place for storing results from such calculations.  

=head1 SEE ALSO

=over 4

=item *

L<http://www.pdb.org>

=item *

L<Bio::PDB::Structure::Atom>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
