package Mecom::Subsets;
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
sub get_query{
    
    my ($query, $current_chain, $spec_chains) = @_;
    $spec_chains =~ s/ /,/g;
    my %categories = (
                      "Contact"           => "^[$current_chain]\t.*\t[0-9]*\t[A-Z]\t.*\t1\t[0,1]",
                      "ContactWith"       => "^[$current_chain]\t([$spec_chains,\|]*)\t[0-9]*\t[A-Z]\t.*\t1\t[0,1]",
                      "NonContact"        => "^[$current_chain]\t.*\t[0-9]*\t[A-Z]\t.*\t0\t[0,1]",
                      "BuriedNonContact"  => "^[$current_chain]\t.*\t[0-9]*\t[A-Z]\t.*\t[0,1]\t0",
                      "ExposedNonContact" => "^[$current_chain]\t.*\t[0-9]*\t[A-Z]\t.*\t0\t1"
                      );
    my $expression = $categories{$query};
    return ($query, $expression);
    
}

sub get_list{
    
    my ($self,$exp,@structural_info) = @_;
    my @subset = grep(/$exp/,@structural_info);
    
    my @list;
    foreach my $row (@subset){
        # Avoid header from Raw Table
        if(!(grep(/^#/,$row))){
            my @columns = split(/\t/,$row);
            my $num = $columns[2];
            push(@list, $num);
        }
            
    }
     
    return @list;   
    
}

sub build{
    
    my ($self,$current_chain,$spec_chains,@structural_info) = @_;
    my %sets = (
        "Contact"           => [get_list(get_query("Contact",$current_chain) ,@structural_info)],
        "NonContact"        => [get_list(get_query("NonContact",$current_chain) ,@structural_info)],
        "BuriedNonContact"  => [get_list(get_query("BuriedNonContact",$current_chain) ,@structural_info)],
        "ExposedNonContact" => [get_list(get_query("ExposedNonContact",$current_chain) ,@structural_info)]
                );
    
    # If are there values for specific chains
    if($spec_chains ne "-"){
        my $spec_chains_key = $spec_chains;
        $spec_chains_key =~ s/ //g;
        $sets{"ContactWith_".$spec_chains} = [get_list(get_query("ContactWith",$current_chain,$spec_chains) ,@structural_info)];
    }
 
    return %sets;
    
}



1;