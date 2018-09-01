package HackaMol::Roles::ReadPdbqtRole;
$HackaMol::Roles::ReadPdbqtRole::VERSION = '0.048';
# ABSTRACT: Read files with molecular information
use Moose::Role;
use HackaMol::PeriodicTable qw(_element_name _trim _qstring_num);
use Math::Vector::Real;
use Carp;

sub read_pdbqt_atoms {

 # this is too similar to reading pdb for it too exist separately... think about
    my $self = shift;
    my $fh   = shift;
    #my $file = shift;
    #my $fh = FileHandle->new("<$file") or croak "unable to open $file";

# $RtBrnch{ROOT}{iatoms}    = LIST integers of atoms in root
# $RtBrnch{BRNCH1}{iatoms}  = LIST integers of atoms in BRNCH1
# $RtBrnch{BRNCH1}{ROOT}    = LIST two integers of rotable bond for BRNCH1
# $RtBrnch{BRNCH2}{iatoms}  = LIST integers of atoms in BRNCH2
# $RtBrnch{BRNCH2}{SBRNCH1} iatoms}  = LIST integers of atoms in BRNCH2
# each branch is rigid block of atoms
#  NONONONONO!!!!  for now, just read in atoms.  We'll figure out how to save the tree later
    my %RtBrnch;

    my @atoms;
    my ( $n, $t ) = ( 0, 0 );
    my $q_tbad          = 0;
    my $something_dirty = 0;

    while (<$fh>) {

        if (/^(?:MODEL\s+(\d+))/) {
            $n      = 0;
            $q_tbad = 0;    # flag a bad model and never read again!
        }
        elsif (/^(?:ENDMDL)/) {
            $t++;
        }
        elsif (/^(?:HETATM|ATOM)/) {
            next if $q_tbad;
            my (
                $record_name, $serial, $name, $altloc, $resName,
                $chainID,     $resSeq, $icod, $x,      $y,
                $z,           $occ,    $B,    $charge, $ADTtype
            ) = unpack "A6A5x1A4A1A3x1A1A4A1x3A8A8A8A6A6x4A6x1A2", $_;

#ATOM      1  O   LIG d   1       8.299   4.799  79.371  0.00  0.00    -0.292 OA
#-----|----|x---||--|x|---||xxx-------|-------|-------|-----|-----|xxxx-----|x-|

            if   ( $chainID =~ m/\w/ ) { $chainID = uc( _trim($chainID) ) }
            else                       { $chainID = ' ' }

            $name    = _trim($name);
            $resName = _trim($resName);
            $resSeq  = _trim($resSeq);

            #$resSeq  = 0 if ( $resSeq < 0 );
            $serial  = _trim($serial);
            $charge  = _trim($charge);
            $ADTtype = _trim($ADTtype);

            my ( $element, $qdirt ) = _element_name($ADTtype);
            $something_dirty++ if ($qdirt);
            my $xyz = V( $x, $y, $z );

            if ( $t == 0 ) {
                $atoms[$n] = HackaMol::Atom->new(
                    name        => $name,
                    record_name => $record_name,
                    serial      => $serial,
                    chain       => $chainID,
                    symbol      => $element,
                    charges     => [$charge],
                    coords      => [$xyz],
                    occ         => $occ * 1,
                    bfact       => $B * 1,
                    resname     => $resName,
                    resid       => $resSeq,
                    segid       => $ADTtype,
                    altloc      => $altloc,
                );
                $atoms[$n]->is_dirty($qdirt) unless $atoms[$n]->is_dirty;
            }
            else {
                #croak condition if atom changes between models
                if ( $n > $#atoms or   $name ne $atoms[$n]->name
                    or $element ne $atoms[$n]->symbol )
                {
                    my $carp_message =
                        "BAD t->$t PDB Atom $n "
                      . "serial $serial resname $resName "
                      . "has changed";
                    carp $carp_message;
                    $q_tbad = $t;    # this is a bad model!
                                     #wipe out all the coords prior
                    $atoms[$_]->delete_coords($t) foreach 0 .. $n - 1;
                    $t--;
                    next;
                }
                $atoms[$n]->set_coords( $t, $xyz );
            }
            $n++;
        }
    }

    # set iatom to track the array.  diff from serial which refers to pdb
    $atoms[$_]->iatom($_) foreach ( 0 .. $#atoms );
    if ($something_dirty) {
        unless ( $self->hush_read ) {
            my $message = "MolReadRole> found $something_dirty dirty atoms. ";
            $message .= "Check symbols and lookup names";
            carp $message;
        }
    }
    return (\@atoms);
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::ReadPdbqtRole - Read files with molecular information

=head1 VERSION

version 0.048

=head1 SYNOPSIS

   my @atoms = HackaMol->new
                       ->read_pdbqt_atoms("some.pdbqt");

=head1 DESCRIPTION

The HackaMol::Roles::ReadPdbqtRole provides read_pdbqt_atoms for reading docking files.

=head1 METHODS

=head2 read_pdbqt_atoms

One argument: the filename
Returns a list of HackaMol::Atom objects.

=head1 Additional information

Similar format to PDB but even trickier... whoa.

=head1 SEE ALSO

=over 4

=item *

L<HackaMol>

=item *

L<HackaMol::Atom>

=item *

L<HackaMol::Roles::MolReadRole>

=item *

L<Protein Data Bank|http://pdb.org>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
