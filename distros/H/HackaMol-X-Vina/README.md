HackaMol-X-Vina
===============
HackaMol extension for running Autodock Vina  

VERSION 0.011
============= 
 

please see *[HackaMol::X::Vina on MetaCPAN](https://metacpan.org/release/DEMIAN/HackaMol-X-Vina-0.01) for formatted documentation.

SYNOPSIS
============
```perl
         use Modern::Perl;
         use HackaMol;
         use HackaMol::X::Vina;
         use Math::Vector::Real;
         
         my $receptor = "receptor.pdbqt";
         my $ligand   = "lig.pdbqt",
         my $rmol     = HackaMol -> new( hush_read=>1 ) -> read_file_mol( $receptor ); 
         my $lmol     = HackaMol -> new( hush_read=>1 ) -> read_file_mol( $ligand ); 
         my $fh = $lmol->print_pdb("lig_out.pdb");
  
         my @centers = map  {$_ -> xyz}
                       grep {$_ -> name    eq "OH" }
                       grep {$_ -> resname eq "TYR"} $rmol -> all_atoms;
         
         foreach my $center ( @centers ){
         
             my $vina = HackaMol::X::Vina -> new(
                 receptor       => $receptor,
                 ligand         => $ligand,
                 center         => $center,
                 size           => V( 20, 20, 20 ),
                 cpu            => 4,
                 exhaustiveness => 12,
                 exe            => '~/bin/vina',
                 scratch        => 'tmp',
             );
         
             my $mol = $vina->dock_mol(3); # fill mol with 3 binding configurations 
         
             printf ("Score: %6.1f\n", $mol->get_score($_) ) foreach (0 .. $mol->tmax);          

             $mol->print_pdb_ts([0 .. $mol->tmax], $fh); 

           }

           $_->segid("hgca") foreach $rmol->all_atoms; #for vmd rendering cartoons.. etc
           $rmol->print_pdb("receptor.pdb");
```

DESCRIPTION
============
HackaMol::X::Vina provides an interface to AutoDock Vina, which is a widely used program for docking small molecules
(ligands) into biological molecules (receptors). This class provides methods for writing configuration files and for 
processing output. The input/output associated with running Vina is pretty simple, but there is still a fair amount of
scripting required to apply the program to virtual drug-screens that often involve sets of around 100,000 ligands,
several sites within a given receptor, which may also have multiple configurations.  The goal of this interface is to reduce 
the amount of scripting needed to set up massive drug screens, provide flexibility in analysis/application, and improve
control of what is written into files that can quickly accumulate. For example, the synopsis docks a ligand into a 
receptor for a collection of centers located at the hydroxy group of tyrosine residues; there are a multitude of binding
site prediction software that can be used to provide a collection of centers. Loops over ligands, receptors, centers are 
straightforward to implement, but large screens on a computer cluster will require splitting the loops into chunks that
can be spread across the queueing system.  See examples.

This class does not include the AutoDock Vina program, which is 
[released under a very permissive Apache license](http://vina.scripps.edu/manual.html#license), with few 
restrictions on commercial or non-commercial use, or on the derivative works, such is this. Follow these 
[instructions ] (http://vina.scripps.edu/manual.html#installation) to acquire the program. Most importantly, if 
you use this interface effectively, please be sure to cite AutoDock Vina in your work:

O. Trott, A. J. Olson, AutoDock Vina: improving the speed and accuracy of docking with a new scoring function, efficient
optimization and multithreading, Journal of Computational Chemistry 31 (2010) 455-461 

Since HackaMol has no pdbqt writing capabilities (yet, HackaMol can read pdbqt files), the user is required to provide
those  files. [OpenBabel] (http://openbabel.org/wiki/Main_Page) and [MGLTools] (http://mgltools.scripps.edu) are popular
and effective. 
