package Mecom::Surface;
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

use 5.006;
use strict;
use warnings FATAL => 'all';
use Bio::Structure::Model;
use Bio::Structure::IO::pdb;
use Bio::Structure::SecStr::DSSP::Res;
use IPC::Run qw( run );


sub cleanPDB{
    
    # Arguments
    my ($pdbFile, $chainID) = @_;
    
    # Output
    my $coord;
    
    # Open the pdbfile
    open PDB, $pdbFile;
    my @pdbArray = <PDB>;
    close PDB;
    
    # parse the input file saving only backbone atoms coordinates
    # format: [string "ATOM"] [number] [atom] [aa] whatever [3 decimal numbers] whateva with two dots in between
    for (my $line = 0; $line < scalar @pdbArray; $line++) {
        #if ($pdbArray[$line] =~ m/ATOM\s+\d+\s+(\w+)\s+\w{3}\s+$chainID+.+\s(\S+\.\S+)\s+(\S+\.\S+)\s+(\S+\.\S+)\s+.+\..+\..+/ig) {
        if ($pdbArray[$line] =~ m/ATOM\s+\d+\s+(\w+)(\s|.+)+\w{3}\s+$chainID+.+\s(\S+\.\S+)\s+(\S+\.\S+)\s+(\S+\.\S+)\s+.+\..+\..+/ig) {
            if (1) {
                $coord = $coord.$pdbArray[$line];
            }
        }
    }
    
    return $coord;
    
}



sub dssp{
    
    my ($pdb, $chain, $th_expo, $th_margin, $dssp_bin, @contact_data) = @_;
    my $inData = cleanPDB($pdb,$chain);
    my $temp_dssp_name = "dssp_temp";
    my @dssp = ($dssp_bin, "--", "dssp_temp");
    
    my $outData;
    
    # DSSP calling
    run(\@dssp,\$inData, \$outData);
    
    if( -e "dssp_temp"){
        
        open DSSP, $temp_dssp_name;
        my @dssp_info = <DSSP>;
        
        foreach my $line (@dssp_info){
            
            $outData = $outData.$line;
            
        }
        
    }else{
        # Error
    }
    
    
    my $rawTable = dssp_proc($temp_dssp_name, $th_expo, $th_margin, $chain, @contact_data);
    system("rm $temp_dssp_name");
    return $rawTable;
    
}

sub dssp_proc{
    
    my ($file, $th_expo, $th_margin, $chain, @contact_data) = @_;

    
    my @rawTable;
    my $contact;
    
    # ASA calculated for residue X in a GXG tripeptide with the main chain in an
    # extended conformation. This hash information is necessary to calculate
    # the relative exposition of each type of residue.
    my %ASA_GXG_total =  (
       'A' => 113,
       'R' => 241,
       'N' => 158,
       'D' => 151,
       'C' => 140,
       'Q' => 189,
       'E' => 183,
       'G' => 85,
       'H' => 194,
       'I' => 182,
       'L' => 180,
       'K' => 211,
       'M' => 204,
       'F' => 218,
       'P' => 143,
       'S' => 122,
       'T' => 146,
       'W' => 259,
       'Y' => 229,
       'V' => 160,
    # X: ambigueties
       'X' => 90
     );
    
    my %res_hash = (
       'ALA'=>'A',
       'ARG'=>'R',
       'ASN'=>'N',
       'ASP'=>'D',
       'CYS'=>'C',
       'GLN'=>'Q',
       'GLU'=>'E',
       'GLY'=>'G',
       'HIS'=>'H',
       'ILE'=>'I',
       'LEU'=>'L',
       'LYS'=>'K',
       'MET'=>'M',
       'PHE'=>'F',
       'PRO'=>'P',
       'SER'=>'S',
       'THR'=>'T',
       'TRP'=>'W',
       'TYR'=>'Y',
       'VAL'=>'V',
    );
    
    # DSSP processor
    #  GETTING DSSP INFORMATION
    #  This part of the script uses the previously called library (Bioperl)
    #  The argument "'-fh'=>\*STDIN" instead a file name is to read the
    #  text from the standar input. So, it is necesary to put the dssp data
    #  in the console and not in a file.
    my $dssp = new Bio::Structure::SecStr::DSSP::Res('-file' => $file );
    
    #  Store the whole information about each residue
    my @residues = $dssp->residues();
    
    #  Store the sequence
    my @seq = $dssp->getSeq();
        
    # Chain length
    my $chain_length = scalar(@residues);
    
    my @bin_array = ();
    foreach my $residueID (@residues) {
        
        # Just one residue
        my $res = $dssp->resAA($residueID);
        
        # The residue
        # Sometimes, Cys resisues are designated wiht the characters 'a' or 'b'
        if ($res eq 'a' or $res eq 'b'){ $res = 'C'; }
        
        # The secondary structure of such residue
        my $sur = $dssp->resSecStr($residueID);
        
        # 0: buried, 1: exposed
        my $bin = '0';
        my $total_asa = $ASA_GXG_total{"$res"};
     
        # The decision    
            if($dssp->resSolvAcc($residueID)/$total_asa > $th_expo + $th_margin){
                $bin = '1';
            }elsif($dssp->resSolvAcc($residueID)/$total_asa <= $th_expo - $th_margin){
                $bin = '0';
            }else{
                $bin = '-';
            }
        
        
        push(@bin_array,$bin);
        #push(@bin_array,$dssp->resSolvAcc($residueID)/$total_asa);
        
    }
    
    # Table drawing ################################################################
    push(@rawTable,"#Raw Table for $chain.");
    push(@rawTable,"#ChainID\tChainID2\tRes num.\tAA\tAA2\tContact\tExposition (th=$th_expo)");
    push(@rawTable,"#-------\t--------\t--------\t--\t--\t-------\t-----------------");
    
    
    #for(my $i=0;$i<=$chain_length;$i++){
    for(my $i=0;$i<scalar @bin_array;$i++){   
        my $no = $i+1;
        my $pdbNum = $dssp->_pdbNum( $no );
            # Avoid an error but not gives a solution /FIXED/
            #if($pdbNum eq ""){ next; }
        my $aa = $dssp->resAA($pdbNum);
        my $chainID2 = "--";
        my $aa2 = "-";
        
        # Check if the residue is in conctact
        my @bool_contact = grep /.{3}-$pdbNum\t$chain/, @contact_data;
        
        if(@bool_contact){
            
            my @array_res_con = ();
            
            $contact = 1;
            for my $one_contact (@bool_contact){
                
                my @cols = split(/\t/,$one_contact);
                    
                    my $res_one = $cols[1];
                    my $res_two = $cols[3];
                    
                    # Residuo de la otra cadena contra el que contacta
                    my @split_col2 = split(/-/,$cols[2]);
                    my $res_contra = $split_col2[0];
                    #
                    
                    $res_one =~ s/\n//g;
                    $res_two =~ s/\n//g;
                    
                    my $res_con = "";
                    
                    if($res_one eq $chain){
                        
                        $res_con = $res_two;
                        
                    }else{
                        
                        $res_con = $res_one;
                        
                    }
                    
                    if(!$res_hash{$res_contra}){ next }
                    
                    if($aa2 eq "-"){
                        $aa2 = $res_hash{$res_contra}."($res_con)";                    
                    }else{
                        $aa2 = $aa2."|".$res_hash{$res_contra}."($res_con)";
                    }
                    
                    push(@array_res_con, $res_con);
                    
                    if($chainID2 eq "--"){
                    
                        $chainID2 = $res_con;
                    
                    }else{
                        
                        $chainID2 = $chainID2."|".$res_con;
                        
                    }
                
            }
            
            $chainID2 = "";
            # The array is converted in a hash, giving to each element (key) the value 1
            my %hash = map {$_, 1} @array_res_con;
            # In this way the new_array doesn't contain duplicated elements
            my @new_array_rc = keys %hash;
            
            for my $res (@new_array_rc){
                
                if($chainID2 eq ""){
                    
                        $chainID2 = $res;
                    
                    }else{
                        
                        $chainID2 = $chainID2."|".$res;
                        
                    }
                
            }
            
            # Caution, this commented fragment was important
            # Changes in residue filtering do this fragmen deprecated
            # So, it can be removed
            # Just in case, I will wait for a while
            #IF Mode 2
            #if($string_contacts){
                # Change boolean if doesn't contact with one of the specified chains 
            #    $contact = 0;
            #    foreach my $chain_c (@chains_contact){
                    
            #        foreach my $chain_d (@new_array_rc){
                        
            #            if($chain_c eq $chain_d){ $contact = 1; }
                        
            #        }
                    
            #    }
            #}
                          
        }else{
            
            $contact = 0;
            
        }
        
        push(@rawTable,"$chain\t$chainID2\t$pdbNum\t$aa\t$aa2\t$contact\t$bin_array[$i]\n");
        
    }
    
    return \@rawTable;
    
}

1; # End of Coevolution::Surface
