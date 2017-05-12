package Mecom;
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
no strict "refs";
our $VERSION = '1.15';

# Own modules
use Mecom::Contact; 
use Mecom::Surface;
use Mecom::Subsets;
use Mecom::Report;
use Mecom::Align::Subset;
use Mecom::EasyYang; 
use Mecom::Statistics::RatioVariance;
use Mecom::Config;

# PAML DIR
$ENV{PAMLDIR} = Mecom::Config->get_pamldir;

# External modules
use Bio::Structure::Model;
use Bio::Structure::IO::pdb;
use Bio::SimpleAlign;
use Bio::Align::Utilities qw(:all);
use warnings;
use Carp;
use Bio::AlignIO;



# -----------------------------------------------------------------------------
# Class data                                                          Chap.  1
# -----------------------------------------------------------------------------
{
    # A list of all attributes wiht default values and read/write/required
    # properties
    my %_attribute_properties = (
        
        # Required (pdb become optional if contactfile is set)
        _pdb                   => ["-"        , ""         ],
        _contactfile           => ["-"        , ""         ],
        _alignment             => [""         , "required" ],
        _chain                 => [""         , "required" ],
        
        # Optional
        _pth                   => [4          , ""         ],
        _sth                   => [0.05       , ""         ],
        _sthmargin             => [0          , ""         ],
        _contactwith           => ["-"        , ""         ],
        _informat              => ["fasta"    , ""         ],
        _oformat               => ["clustalw" , ""         ],
        _gc                    => ["0"        , ""         ],
        _ocontact              => ["data.str" , ""         ],
        _dsspbin               => ["dssp"     , ""         ],
        _report                => ["r.html"   , ""         ],
        
        # Processed information
        _struct_data           => [[]         , ""         ],
        _lists                 => [{}         , ""         ],
        _sub_alns              => [{}         , ""         ],
        _paml_res              => [{}         , ""         ],
        _stats                 => [{}         , ""         ],
        
    );
    
    # Global variable to keep count of existing objects
    my $_count = 0;
    # The list of all attributes
    sub _all_attributes {
        keys %_attribute_properties;
    }
    # Check if a given property is set for a given attribute
    sub _permissions{
        my ($self,$attribute, $permissions) = @_;
        $_attribute_properties{$attribute}[1] =~ /$permissions/;
    }
    # Return the default value for a given attribute
    sub _attribute_default{
        my ($self,$attribute) = @_;
        $_attribute_properties{$attribute}[0];
    }
    # Manage the count of existing objects
    sub get_count{
        $_count;
    }
    sub _incr_count{
        ++$_count;
    }
    sub _decr_count{
        --$_count;
    }

}

    

# -----------------------------------------------------------------------------
#                                                                            1.

#                                   #---#                                    #


# -----------------------------------------------------------------------------
# Constructor                                                         Chap.  2
# -----------------------------------------------------------------------------
sub new{
    
        
    my ($class, %arg) = @_;
    my $self = bless {}, $class;

    foreach my $attribute ($self->_all_attributes()){
        
        # E.g. attribute = "_name", argument = "name"
        my ($argument) = ($attribute =~ /^_(.*)/);
        
        # If explicitly given
        if($arg{$argument}){
            $self->{$attribute} = $arg{$argument};
        }
        
        # If not given but required
        elsif($self->_permissions($attribute,'required')){
            croak("No $argument specified as required");
        }
        
        # Set to default
        else{
            $self->{$attribute} = $self->_attribute_default($attribute);            
        }
        
    }
    
    # Test if DSSP and PAML exists
    if( -e $self->get_dsspbin ){
        croak("The DSSP program (".$self->get_dsspbin.") is missing.
               See documentation to solve this error.");
    }
    if($ENV{PAMLDIR} eq ""){
        croak("PAML software must be correctly installed in your system.
               See documentation to solve this error.");
    }
    
    # Called $class because it is a gobal method
    $class->_incr_count;
    

    # Input requirement
    if($self->get_pdbfilepath eq "-" && $self->get_contactfilepath eq "-"){
        croak("Input file (pdb or contact) is required")
    }
    
    return $self;
    
}
# -----------------------------------------------------------------------------
#                                                                            2.

#                                   #---#                                    #

# -----------------------------------------------------------------------------
# Methods                                                             Chap.  3
# -----------------------------------------------------------------------------
# Run complete
sub run{
    
    my $self = $_[0];
    # Structural data
    $self->run_struct;
    
    # Filtering
    $self->run_filtering;
    
    # Sub-alignments
    $self->run_subalign;
    
    # Yang
    $self->run_yang;
    
    # Stats
    $self->run_stats1;
    
}
# Get Structural data
sub run_struct{
    
    my $self = $_[0];
    if($self->get_contactfilepath eq "-"){
    
        # Contacts
        my @contact_data = $self->_run_contacts;
        # Surface
        $self->set_structdata($self->_run_surface(@contact_data));
    
    }else{
    
        $self->set_structdata($self->_run_contactFromFile);
        $self->set_ocontact($self->get_contactfilepath);
    
    }
    
    return 1;
    
}
# Get contacts
sub _run_contacts{
    
    my ($self) = $_[0];
    my @contact_data;
    my $stream = Bio::Structure::IO->new(-file => $self->get_pdbfilepath,
                                         -format => 'PDB')
                                 or die "\nInvalid pdb file.\n";

    # Switch if contact file or pdbfile
    if($self->get_contactfilepath() eq "-"){
   
    print "\tCalculating contacts ... it may take a few minutes, please wait.\n";
                                 
    my $obj_contact = new Mecom::Contact("th"         => $self->get_pth,
                                               "pdb"        => $stream,
                                               "chain"      => $self->get_chain);
    
    my $residue_contacts = $obj_contact->contacts;
    @contact_data = @$residue_contacts;
    
    return @contact_data;
    
    }
}
# Get surface
sub _run_surface{
    
    my ($self,@contact_data) = @_;
    my @structural_info;
    
    my $plus_dssp  = Mecom::Surface::dssp($self->get_pdbfilepath,
                                                $self->get_chain,
                                                $self->get_sth,
                                                $self->get_sthmargin,
                                                $self->get_dsspbin,
                                                @contact_data);
    # A new asignation just for clarity
    my @dssp = @$plus_dssp;
    @structural_info = @dssp;
    
    # Save this data (save time for further analisys)
    open OCONTACT, ">".$self->get_ocontact;
    foreach my $line (@dssp){
        print OCONTACT $line."\n";
    }
    close OCONTACT;
    
    return @structural_info
    
}
# Get structural info from contact file
sub _run_contactFromFile{
    
    my $self = $_[0];
    my $contact_file = $self->get_contactfilepath;
    
    print "\tGetting data from contact file\n";
    open CONTACT, $contact_file;
    my @structural_info = <CONTACT>;
    close CONTACT;
    
    return @structural_info;
    
}
# Get subsets
sub run_filtering{
    
    my $self = $_[0];
    
    # With the help of regular expresions, the program will extract a residue list
    # to build a new alignment
    my %subsets_list = Mecom::Subsets->build($self->get_chain,
                                               $self->get_contactwith,
                                               @{$self->get_structdata});
    
    # If a subset is empty, it will be deleted
    foreach my $key (keys %subsets_list){
        if(!$subsets_list{$key}[0]){ delete $subsets_list{$key}; }
    }
    
    $self->set_lists(%subsets_list);
    return 1;
    
}
# Get sub-alignments
sub run_subalign{
    
    my $self = $_[0];
    my %lists = %{$self->get_lists};
    my $obj = Mecom::Align::Subset->new(file   => $self->get_alignfilepath,
                                      format => $self->get_informat);
    
    my %aln_subsets;
    foreach my $key (keys %lists){
        # This function returns a Bio::SimpleAlign object
        $aln_subsets{$key} = $obj->build_subset($lists{$key});
    }

    $self->set_subalns(%aln_subsets);
    return 1;
    
}
# Get evolutionary analisys
sub run_yang{
    
    my $self = $_[0];
    my %alns = %{$self->get_subalns};
    my %paml_results;
    foreach my $aln_key (keys %alns){
        $paml_results{$aln_key} = {Mecom::EasyYang->
                                   yang($alns{$aln_key},$self->get_gc)};
    }
    
    $self->set_pamlres(%paml_results);
    return 1;
    
}
# Get statistics 1
sub run_stats1{
    
    my $self = $_[0];
    my %paml_results = %{$self->get_pamlres};
    my %results;
    my %paml_results_other = %paml_results;
    foreach my $category (keys %paml_results){
        foreach my $other (keys %paml_results_other){
            if($other ne $category){
                
                my ($x,$y,$var_x,$var_y) = ($paml_results{$category}{dN},
                                            $paml_results{$other}{dN},
                                            $paml_results{$category}{dN_VAR},
                                            $paml_results{$other}{dN_VAR});
                my @x = @$x;
                my @y = @$y;
                my @var_x = @$var_x;
                my @var_y = @$var_y;
                
               
                # Edit data set to get the same rows in each column
                while(scalar(@x) > scalar(@y)){
                   my $void = pop(@x);
                   my $var_void = pop(@var_x);
                }
                
                while(scalar(@y) > scalar(@x)){
                   my $void = pop(@y);
                   my $var_void = pop(@var_y);
                }
                
                
                if($#x == $#y){
                #print $#x." -- ".$#y."\n";
                    $results{$category." vs ".$other} =
                                        {Mecom::Statistics::RatioVariance->calc(\@x,
                                                                        \@y,
                                                                        \@var_x,
                                                                        \@var_y
                                                                        )};
                }
            }
        }
    }
    
    # Stats report
    foreach my $key (keys %results){
        if(!$results{$key}{standar_deviation}){ # Sets are equal
            delete $results{$key};
        }
        
    }
    
    $self->set_stats(%results);
    return 1;
    
}
# Get report
sub run_report{
    
    my $self = $_[0];
    my $html_report;
    my @input_info = (
                  $self->get_pdbfilepath,
                  $self->get_contactfilepath,
                  $self->get_alignfilepath,
                  $self->get_chain,
                  $self->get_gc,
                  $self->get_contactwith,
                  $self->get_pth,
                  $self->get_sth,
                  $self->get_sthmargin,
                  $self->get_informat,
                  $self->get_oformat,
                  $self->get_ocontact
                  );
    
    $html_report = Mecom::Report->input_information  (@input_info);
    $html_report.= Mecom::Report->struct_information ($self->get_pdbfilepath,
                                                            $self->get_structdata,
                                                            $self->get_chain,
                                                            $self->get_ocontact);
    $html_report.= Mecom::Report->codon_lists        ($self->get_lists);  
    $html_report.= Mecom::Report->sub_alignments     ($self->get_chain,
                                                        $self->get_oformat,
                                                        $self->get_subalns);  
    $html_report.= Mecom::Report->yang_report        ($self->get_pamlres);     
    $html_report.= Mecom::Report->stats1             ($self->get_stats);           
    
    open HTML, ">".$self->get_report;
    print HTML $html_report;
    close HTML,
    
    return 1;
    
}
# -----------------------------------------------------------------------------
#                                                                            3.

#                                   #---#                                    #

# -----------------------------------------------------------------------------
# Auxiliar Methods                                                    Chap.  4
# -----------------------------------------------------------------------------
# Concatenate alignments
# This is a global function and must be called as
# Mecom::Complex->cat_aln(@alns);
sub cat_aln{
    
    # Bio::SimpleAlign objects as arguments
    my ($self, @alns) = @_;
    # Call function Bio::Align::Utilities->cat();
    my $merge_aln = cat(@alns);
    
    return $merge_aln;
    
}
# -----------------------------------------------------------------------------
#                                                                            4.

#                                   #---#                                    #

# -----------------------------------------------------------------------------
# Accesor Methods                                                    Chap.  5
# -----------------------------------------------------------------------------
# This kind of method is called Accesor
# Method. It returns the value of a key
# and avoid the direct acces to the inner
# value of $obj->{_file}.
sub get_pdbfilepath        { $_[0] -> {_pdb}         }
sub get_contactfilepath    { $_[0] -> {_contactfile} }
sub get_alignfilepath      { $_[0] -> {_alignment}   }
sub get_chain              { $_[0] -> {_chain}       }
sub get_pth                { $_[0] -> {_pth}         }
sub get_sth                { $_[0] -> {_sth}         }
sub get_sthmargin          { $_[0] -> {_sthmargin}   }
sub get_contactwith        { $_[0] -> {_contactwith} }
sub get_informat           { $_[0] -> {_informat}    }
sub get_oformat            { $_[0] -> {_oformat}     }
sub get_gc                 { $_[0] -> {_gc}          }
sub get_ocontact           { $_[0] -> {_ocontact}    }
sub get_dsspbin            { $_[0] -> {_dsspbin}     }
sub get_report             { $_[0] -> {_report}      }
sub get_version            { return $VERSION         }
# Proc
sub get_structdata         { $_[0] -> {_struct_data} }
sub get_lists              { $_[0] -> {_lists}       }
sub get_subalns            { $_[0] -> {_sub_alns}    }
sub get_pamlres            { $_[0] -> {_paml_res}    }
sub get_stats              { $_[0] -> {_stats}       }
# -----------------------------------------------------------------------------
#                                                                            5.

#                                   #---#                                    #

# -----------------------------------------------------------------------------
# Mutator Methods                                                     Chap.  6
# -----------------------------------------------------------------------------
sub set_pdbfilepath        { my ($self, $var) = @_;
                            $self->{_pdb} = $var if $var; }
sub set_contactfilepath    { my ($self, $var) = @_;
                            $self->{_contactfile} = $var if $var; }
sub set_alignfilepath      { my ($self, $var) = @_;
                            $self->{_alignment} = $var if $var;   }
sub set_chain              { my ($self, $var) = @_;
                            $self->{_chain} = $var if $var;       }
sub set_pth                { my ($self, $var) = @_;
                            $self->{_pth} = $var if $var;         }
sub set_sth                { my ($self, $var) = @_;
                            $self->{_sth} = $var if $var;         }
sub set_sthmargin          { my ($self, $var) = @_;
                            $self->{_sthmargin} = $var if $var;   }
sub set_contactwith        { my ($self, $var) = @_;
                            $self->{_contactwith} = $var if $var; }
sub set_informat           { my ($self, $var) = @_;
                            $self->{_informat} = $var if $var;    }
sub set_oformat            { my ($self, $var) = @_;
                            $self->{_oformat} = $var if $var;     }
sub set_gc                 { my ($self, $var) = @_;
                            $self->{_gc} = $var if $var;          }
sub set_ocontact           { my ($self, $var) = @_;
                            $self->{_ocontact} = $var if $var;    }
sub set_dsspbin            { my ($self, $var) = @_;
                            $self->{_dsspbin} = $var if $var;     }
sub set_report             { my ($self, $var) = @_;
                            $self->{_report} = $var if $var;     }
# Proc
sub set_structdata         { my ($self, @var) = @_;
                            $self->{_struct_data} = \@var if @var;}
sub set_lists              { my ($self, %var) = @_;
                            $self->{_lists} = \%var if %var;     }
sub set_subalns            { my ($self, %var) = @_;
                            $self->{_sub_alns} = \%var if %var;     }
sub set_pamlres            { my ($self, %var) = @_;
                            $self->{_paml_res} = \%var if %var;     }
sub set_stats              { my ($self, %var) = @_;
                            $self->{_stats} = \%var if %var;     }
# -----------------------------------------------------------------------------
#                                                                            6.

#                                   #---#                                    #

# -----------------------------------------------------------------------------
#                                                                     Chap.  7
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
#                                                                            7.

#                                   #---#                                    #

1;

__END__

=head1 NAME

Mecom - A Perl module for protein contact interfaces evolutive analysis

=head1 VERSION

Version 1.11

=head1 SYNOPSIS

    # Create the object
    my $coe = Mecom->new(
                                    pdb         => 'pdb/files/path/2occ.pdb',
                                    alignment   => 'aln/files/path/chainM.aln',
                                    chain       => 'M',
                                    );
    # Run calcs
    $coe->run;
    
    # Write HTML Report
    open REP, ">report.html";
    print REP $coe->run_report;
    close REP;

=head1 DESCRIPTION

This module integrates a workflow aimed to address the evolvability of the
contact interfaces within a protein complex. The method C<Mecom-E<gt>run>
launchs the whole analysis. Also, such workflow is divided into the following steps:

=over 4

=item B<Step 1>, Structural analysis: C<Mecom-E<gt>run_struct>

=item B<Step 2>, Sub-sets filtering: C<Mecom-E<gt>run_filtering>

=item B<Step 3>, Sub-alignments building: C<Mecom-E<gt>run_subalign>

=item B<Step 4>, Evolutionary calcs: C<Mecom-E<gt>run_yang>

=item B<Step 5>, Statistical analysis: C<Mecom-E<gt>run_stats1>

=back

A detailed explanation about these methods is reported below.

=head1 REQUERIMENTS

=over 4

=item Bioperl

=item Bioperl-run

=item PAML

=item DSSP

=back

=head1 CONSTRUCTOR

=head2 new()

    $obj = Mecom->new(%input_data);

The new class method construct a new L<Mecom> object. The returned
object can be used to perform several evolutive analysis. C<new> accepts the
following parameters in an input hash as above used C<%input_data>:

=over 4

=item * B<pdbfilepath> (required if B<contactfile> is missing)

A valid pdb file path to be opened for reading.

=item * B<contactfilepath> (required if B<pdb> is missing)

A valid contact file path. This file must contain the structural information
retrieved by a previous analysis on the same chain

=item * B<alignfilepath> (required)

A valid DNA multiple alignment file path. The alignment must correspond with the specified
chain and must be at least as long as the pdb chain (x3)

=item * B<chain> (required)

A given subunits within the studied complex

=item * B<pth> (default 4 Angstroms)

Proximity threshold. The maximun distance between two residues to be considered
as a contact pair

=item * B<sth> (default 0.05)

Exposure threshold. The maximun exposure fraction to be considered as a buried
residue.

=item * B<sthmargin> (default 0)

An error margin for B<sth>. For instance: if is set to 0.01, residues with exposure
higher than 0.06 will be considered as exposed, those with exposure lower than
0.04 will be buried and those residues with exposure between 0.04 and 0.06 will
not be considered

=item * B<contactwith>

A string with valid chain identificators separated by commas:

    $contactwith = "A,B,D";
    
if it is set, the program will only consider as contact residues those in close
proximity with the specified chains. The others will be excluded.

=item * B<informat> (default fasta)

Specify the format of the input alignment file.  Supported formats include fasta,
genbank, embl, swiss (SwissProt), Entrez Gene and tracefile formats
such as abi (ABI) and scf. There are many more, for a complete listing
see the SeqIO HOWTO (L<http://bioperl.open-bio.org/wiki/HOWTO:SeqIO>).

If no format is specified and a filename is given then the module will
attempt to deduce the format from the filename suffix. If there is no
suffix that Bioperl understands then it will attempt to guess the
format based on file content. If this is unsuccessful then SeqIO will 
throw a fatal error.

The format name is case-insensitive: 'FASTA', 'Fasta' and 'fasta' are
all valid.

Currently, the tracefile formats (except for SCF) require installation
of the external Staden "io_lib" package, as well as the
Bio::SeqIO::staden::read package available from the bioperl-ext
repository.

=item * B<oformat> (default clustalw)

Specify the format of the output sub-alignments. As above.

=item * B<gc> (default 0)

The genetic code. The attribute must be one of the following integers, which
correspond with the indicated genetic code:
    
    0: Standar
    1: Mammailan mitochondrial
    2: Yeast mitochondrial
    3: Mold mitochondiral
    4: Invertebrate mitochondrial
    5: Ciliate nuclear
    6: Echinoderm mitochondrial
    7: Euplotid mitochondrial
    8: Alternative yeast nuclear
    9: Ascidian mitochondrial
    10: Blepharisma nuclear
    
These codes correspond to transl_table 1 to 11 of GENEBANK

=item * B<ocontact> (default ocontact)

A valid file path to write the structural results

=item * B<dsspbin> (default dssp)

The path to the DSSP binary

=back

=head1 MAIN METHODS

=head2 run()

    Title   : run
    Usage   : $obj->run
    Function: Launch the whole workflow analysis
    Returns : 
    Args    :

=head2 run_struct()

    Title   : run_struct
    Usage   : $obj->run_struct
    Function: Launch structural analysis and stores the result in the attribute:
              "structdata"
    Returns : True if success
    Args    :

=head2 run_filtering()

    Title   : run_struct
    Usage   : $obj->run_filtering
    Function: Build different categories of sets (Contact, NonContact ...)
              and set the attribute "lists" with the result
    Returns : True if success
    Args    :

=head2 run_subalign()

    Title   : run_subalign
    Usage   : $obj->run_subalign
    Function: Build new alignments from the input chain alignment and the categories
              built by run_filtering method. Stores the result into "subalns" attribute
    Returns : True if success
    Args    :

=head2 run_yang()

    Title   : run_yang
    Usage   : $obj->run_yang
    Function: Launch PAML for each alignment stored at "sub_alns" attribute and
              store the results into "paml_res"
    Returns : True if success
    Args    :

=head2 run_stats1()

    Title   : run_stats1
    Usage   : $obj->run_stats1
    Function: Run a Z-Test with the obtained evolutionary data and store the
              results into "stats" attribute
    Returns : True if success
    Args    :

=head2 run_report()

    Title   : run_report
    Usage   : $obj->run_report
    Function: Write a HTML report
    Returns : [String] HTML report with the results and input data
    Args    :

=head1 AUXILIAR METHODS

=head2 cat_aln()

    Title   : run_report
    Usage   : $obj->cat_aln(@alns)
    Function: Concatenates alignment objects. Sequences are identified by id.
             An error will be thrown if the sequence ids are not unique in the
             first alignment. If any ids are not present or not unique in any
             of the additional alignments then those sequences are omitted from
             the concatenated alignment, and a warning is issued. An error will
             be thrown if any of the alignments are not flush, since
             concatenating such alignments is unlikely to make biological
             sense.
    Returns : A unique Bio::SimpleAlign object
    Args    : A list of Bio::SimpleAlign objects

=head1 PROCESSED DATA STORAGE

Once each analysis has been performed, the resulting data is stored in other
setable attributes:

=over 4

=item * B<structdata>

[Array] A table with the structural information calculated by Mecom::Contact.pm
and DSSP

=item * B<lists>

[Hash] Each item contains a list of number corresponding with each type of residue.
The key for a given item is the name for the category.

    Contact
    NonContact
    ExposedNonContact
    ContactWith_$specified_chains [...]

=item * B<subalns>

[Hash] Each item contains a sub-alignment for a given category (see above)

=item * B<pamlres>

[Hash] Results for evolutive analysis. Each item contains the results for a
given sub-alignment (see above)

=item * B<stats>

[Hash] Statistical results

=back

=head1 SECONDARY METHODS (but not less important)

All attributes are accesible and mutable from methods called get_attribute and
set_attribute, respectively. For example:
    
    # Set the proximity threshold ("pth") to 3 Angstroms
    $obj->set_pth(3);
    # Print the current value of the attribute "pth"
    print $obj->get_pth;
    
The processed data is also stored in attributes. Thus, this kind of methods can
also be used to access and modify the results.

=head1 AUTHOR - Hector Valverde

Hector Valverde, C<< <hvalverde@uma.es> >>

=head1 CONTRIBUTORS

Juan Carlos Aledo, C<< <caledo@uma.es> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Mecom-Complex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mecom-Complex>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This module is the program core of MECOM Perl program. Further information about
this project is available at:

    http://mecom.hval.es/

You can find documentation for this module with the UNIX man command.

    man Mecom


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Hector Valverde and Juan Carlos Aledo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut