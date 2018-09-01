package HackaMol::Roles::ReadPdbRole;
$HackaMol::Roles::ReadPdbRole::VERSION = '0.048';
# ABSTRACT: Read files with molecular information
use Moose::Role;
use HackaMol::PeriodicTable qw(_element_name _trim _qstring_num);
use Math::Vector::Real;
use Carp;

requires 'readline_func';

sub read_pdb_parts{
    my $self = shift;
    my $fh   = shift;

    my $header             = $self->read_pdb_header( $fh );
    my ($atoms,$model_ids) = $self->read_pdb_atoms( $fh );

    return ($header,$atoms,$model_ids);

}

sub read_pdb_header{
    my $self = shift;
    my $fh   = shift;
    my $header;
    my $line;
    while($line = <$fh>){
        if ($line =~ m/^(?:MODEL|ATOM|HETATM)\s/){
            seek($fh, -length($line),1); # rewind back and end
            last;
        }
        else{
            $header .= $line;
        }
    }
    return ($header);
}

sub read_pdb_atoms {

    #read pdb file and generate list of Atom objects
    my $self = shift;

    my $fh   = shift;
    #my $file = shift;
    #my $fh   = FileHandle->new("<$file") or croak "unable to open $file";

    my @atoms;
    my @model_ids;
    my ( $n, $t ) = ( 0, 0 );
    my $q_tbad          = 0;
    my $something_dirty = 0;
    my $t0_atom_count = 0;
    my $t_atom_count = 0;
    my $pdb_model_id;

    while (<$fh>) {
        if($self->has_readline_func){
            next if $self->readline_func->($_) eq 'PDB_SKIP';
        }
        if (/^(?:MODEL\s+(\d+))/) {

            $n      = 0;
            $q_tbad = 0;    # flag a bad model and never read again!
            $t_atom_count = 0 ;
            $pdb_model_id = $1;
            $model_ids[$t] = $pdb_model_id;
        }
        elsif (/^(?:ENDMDL)/) {
            # delete coords if the number of atoms on t is != to that at start
            if ($t){
                if ($t_atom_count != $t0_atom_count){
                    my $carp_message =
                        "BAD t->$t PDB atom list length changed from $t0_atom_count to $t_atom_count: ignoring model $t";
                    carp $carp_message;
                    $_->delete_coords($t) foreach @atoms;
                    $t--;
                }
            }
            $t++;
        }
        elsif (/^(?:HETATM|ATOM)/) {
            next if $q_tbad;
            my (
                $record_name, $serial,  $name,    $altloc,
                $resName,     $chainID, $resSeq,  $icod,
                $x,           $y,       $z,       $occ,
                $B,           $segID,   $element, $charge
            ) = unpack "A6A5x1A4A1A3x1A1A4A1x3A8A8A8A6A6x6A4A2A2", $_ . (" " x 12); # padded out to accommodate truncated pdbs

            if   ( $charge =~ m/\d/ ) { $charge = _qstring_num($charge) }
            else                      { $charge = 0 }

            if   ( $chainID =~ m/\w/ ) { $chainID =  _trim($chainID) }
            else                       { $chainID = ' ' }

            $name    = _trim($name);
            $resName = _trim($resName);
            $resSeq  = _trim($resSeq);

            #$resSeq  = 0 if ( $resSeq < 0 );
            $serial = _trim($serial);
            $segID  = _trim($segID);

            $element = ucfirst( lc( _trim($element) ) );
            my $qdirt = 0;
            ( $element, $qdirt ) = _element_name($name)
              unless ( $element =~ /\w+/ );
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
                    icode       => $icod,
                    segid       => $segID,
                    altloc      => $altloc,
                );
                $atoms[$n]->is_dirty($qdirt) unless $atoms[$n]->is_dirty;
                $t0_atom_count++;
            }
            else {
                # croak condition if atom changes between models
                # does not catch case were number of atoms shrinks!
                if ( $n > $#atoms or  $name ne $atoms[$n]->name
                    or $element ne $atoms[$n]->symbol )
                {
                    my $carp_message =
                        "BAD t->$t PDB Atom $n "
                      . "serial $serial resname $resName "
                      . "has changed";
                    carp $carp_message;
                    $q_tbad = $t;    # this is a bad model!
                                     # wipe out all the coords prior
                    $atoms[$_]->delete_coords($t) foreach 0 .. $n - 1;
                    $t--;
                    next;
                }
                $atoms[$n]->set_coords( $t, $xyz );
                $t_atom_count++;
            }
            $n++;
        }
    }

    # set iatom to track the array.  diff from serial which refers to pdb
    $atoms[$_]->iatom($_) foreach ( 0 .. $#atoms );
    if ($something_dirty) {
        if ( $self->hush_read <= 0 ) {
            my $message = "MolReadRole> found $something_dirty dirty atoms. ";
            $message .= "Check symbols and lookup names PeriodicTable.pm:";
            my @sprintf;
            foreach my $atom (grep {$_->is_dirty} @atoms){
              push @sprintf, sprintf(" DIRTY: index %s name %s element %s %10.3f %10.3f %10.3f;", $atom->iatom, $atom->name, $atom->symbol, @{$atom->xyz});
            }
            $message .= $_ foreach @sprintf;
            carp $message;
        }
    }
    return (\@atoms,\@model_ids);
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::ReadPdbRole - Read files with molecular information

=head1 VERSION

version 0.048

=head1 SYNOPSIS

   my @atoms = HackaMol->new
                       ->read_pdb_atoms("some.pdb");

=head1 DESCRIPTION

The HackaMol::Roles::ReadPdbRole provides read_pdb_atoms reading protein database files.

=head1 METHODS

=head2 read_pdb_atoms

One argument: the filename
Returns a list of HackaMol::Atom objects.

=head1 Additional information

According to the PDB specification, the element symbol should be present in columns 
77-78.  The element is often ommitted by programs, such as charmm, that can write 
pdbs because it makes the file larger, and the information is accessible somewhere 
else (protein structure file). Unfortunately, other programs require the information.  
HackaMol::MolReadRole, uses HackaMol::PeriodicTable to map common names to the element 
(e.g. POT => 'K'). read_pdb_atoms will carp if the name is not in the hash, and then 
set the element to the first letter of the name. If you see one of these messages for 
a common atom, please submit an issue or pull request so the atom can be added!

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
