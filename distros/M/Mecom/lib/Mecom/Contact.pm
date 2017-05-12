package Mecom::Contact;
# -----------------------------------------------------------------------------
# Molecular Evolution of Protein Complexes Contact Interfaces
# -----------------------------------------------------------------------------
# @Authors:  HŽctor Valverde <hvalverde@uma.es> and Juan Carlos Aledo
# @Date:     May-2013
# @Location: Depto. Biolog’a Molecular y Bioqu’mica
#            Facultad de Ciencias. Universidad de M‡laga
#
# Copyright 2013 Hector Valverde and Juan Carlos Aledo.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
#
# See http://dev.perl.org/licenses/ for more information.
# -----------------------------------------------------------------------------
use Carp;




{
    # Maximun distance (Angstroms) between two residues to be considered as
    # a contact.
    my $dis_threshold;
    # PDB data handle: a Bio::Structure::IO instance (From BioPerl; see
    # documentation)
    my $stream;
    # If a chain id is specified, the program just report the distances for that
    # chain
    my $givenChain;
    # The overall arrays:
    # detailed_array contains the distances between atoms
    my @detailed_array;
    # residue_array cotains residues in close contact    
    my @residue_array;
}

sub new{
    
    my ($class, %arg) = @_;
    my $self = bless {}, $class;
    
    # CAUTION: Variable validation shuld be completed before
    # object construction.
    
    # Proximity threshold
    $dis_threshold = $arg{"th"};
    # PDB file handle
    $stream = $arg{"pdb"};
    # Chain specified
    $givenChain = $arg{"chain"};
    
    return $self;
    
}


sub contacts{
    
    my $self = $_;

    # For each structure in pdb file (just one)
    while (my $struc = $stream->next_structure) {
        
        # Models
        my @models = $struc->get_models;
        my @chains = ();
        foreach my $model (@models){
          
          my @chains_model = $struc->get_chains($model);
          # Store all chains from all models in the same array
          push(@chains, @chains_model);
          
        }
        
        # Check number of chains > 1
        if(scalar @chains <= 1){
            
            croak("This pdb file contains only one chain. No contact detected with other chains");
            
        }
        
        # For each chain
        for(my $i=0;$i<scalar @chains;$i++){
            
            # Chain
            my $chain = $chains[$i];
            
            # Chain identifier
            my $chainid = $chain->id;
            
            # Swich for a given chain
            my $letsCalc = 1;
            
            if($givenChain){
                $letsCalc = 0;
            }
            if($givenChain eq $chainid){
                $letsCalc = 1;
            }
            
            if($letsCalc == 1){
             
                # Auxiliar loop probe
                my $probe = 0;
                # For remaining chains
                for (my $j=$i+1;$j<scalar @chains;$j++){
                    
                    if($givenChain and $probe == 0){ $j = 0; $probe = 1 }
                    
                    # Do not compare with it self
                    if ($j eq $i){ $j++; }
                    
                    # Chain 2
                    my $chain2 = $chains[$j];
                    
                    # For each residue from Chain
                    for my $res ($struc->get_residues($chain)) {
                        
                        # For each atom from Chain
                        for my $atom ($struc->get_atoms($res)){
                            
                            # For each residue from Chain2
                            for my $res2 ($struc->get_residues($chain2)) {
                        
                                 # For each atom from Chain2
                                for my $atom2 ($struc->get_atoms($res2)){
                            
                                    # Distance
                                    my $distance = sqrt( ($atom->x()-$atom2->x())**2 +
                                                      ($atom->y()-$atom2->y())**2 +
                                                      ($atom->z()-$atom2->z())**2 );
                                    
                                    
                                    if($distance < $dis_threshold){
                                        
                                            # Build single hashes
                                            #my %single_atom_pair = ("chainFrom" => $chain->id,
                                            #                   "chainTo"   => $chain2->id,
                                            #                   "atom"      => $atom->serial(),
                                            #                   "atomId"    => $atom->id,
                                            #                   "resId"     => $res->id,
                                            #                   "atom2Id"   => $atom2->serial(),
                                            #                   "res2Id"    => $res2->id,
                                            #                   "distance"  => $distance);
                                            
                                            # Push into overall array
                                            #push(@detailed_array, \%single_atom_pair);
                                            push(@residue_array, $res->id."\t".$chain->id."\t".$res2->id."\t".$chain2->id."\n");
                                        
                                            
                                            
                                    }
                            
                                }
                        
                            }
                            
                        }
                        
                    }
                      
                }
            
            }
            
        }
        
    }
    

    # 3. Remove duplicated items and convert into a hash:
    # -----------------------------------------------------------------------------
    # -----------------------------------------------------------------------------
    # The array is converted in a hash, giving to each element (key) the value 1
    my %hash = map {$_, 1} @residue_array;
    # In this way the new_array doesn't contain contain duplicated elements
    my @contact_array = keys %hash;
    # -----------------------------------------------------------------------------

    return \@contact_array;

}



1;
