RECOMMENDATIONS
===============
Recommendations for setting up Autodock Vina screens with a large number of ligands compared to the number of 
receptors.  For the situation where you have a large number of receptors compared to the number of ligands (say
screening a single molecule against many possible target biological molecules, see HackaMol-CaseStudy) you can 
switch the descriptions below for the receptor and ligand directories.

Stage 1. in a main working directory have three directories:
  
    receptors/ contains the pdbqt files for receiving molecule of interest. After some initial prepping 
               (strip hydrogens, etc) I generate them using MGLTools, which free and easy to install. 
               Please see:
               https://github.com/demianriccardi/HackaMol-CaseStudy/tree/master/Vina_disulfide

    centers/   In Autodock Vina, a center localizes a search area (x,y,z dimensional box) that 
               may or may not contain a reasonable binding site (depends on your educated guess). In the 
               HackaMol-CaseStudy, which is part of a paper that is in review, I use the centers of disulfide
               bonds in a collection of X-ray crystal structures to screen the ligands cystine and glutathione 
               disulfide. For this the centers are determined on the fly by a disulfide search. You can 
               cook up your own algorithms for finding reasonable binding sites, or you can use one of the 
               many methods available online (I have been using ftmap.bu.edu for more conventional screens). 
               There are also a ton of awesome tools at the Yang Zhang lab at the University of Michigan 
               (They use some Perl too!!!): http://zhanglab.ccmb.med.umich.edu
               
               Whatever approach is used, if it takes a long time, you should store the centers for future use 
               in this directory. I construct a yaml file of a hash with centers stored for each receptor for 
               easy reference. Yaml is easy to read and edit by human or script. Copy and paste
               from this yaml into the docking configuration file used for screens.
               
               If using FTMap, I have included some scripts:
                1. A simple scripts for processing FTMAP pdbs using kmeans clustering provided by 
                   from Math::Vector::Real::kdTree (THANK YOU SALVA).  This script dumps an XYZ file of search 
                   centers (with Hg atoms).
                2. center_gen.pl center_append.pl can be used to generate summary YAML.

    ligands/   sets of json files that contain subsets of a big database of ligand pdbqt files.  
               scripts: setup_ligands_sets_mce.pl 
                   will pull all the pdbqts and file them into subsets of json files with some additional information.
                
               I used OpenBabel and MGLTools for my setup of the db of pdbqt files.  e.g. I have a ~/db directory 
               with a couple of sets (NCI_diversityset2 and a ZINC subset) that are too big to share.

   Setting up Stage 2. next create the "scratch" directories for work and analyses
    docking_NCI/
    docking_ZINC/
    etc.
  
    Within these working directories, copy the broadcast.pl script over and the example.yaml 
    configuration file. Adjust configuration file and do some tests to make sure everything is
    working.  You are now entering stage 2. 
    
Stage 2. Briefly, THE FIRST SCREEN should pull from the ligands/ directory above, do some docking, and then write 
    to a directory of dbs in the working directory.  You have to set this in the configuration YAML file.  You can write
    back to the original json subsets, but this gets very annoyting if you want to run different screens in parallel.
    FOR EACH FOLLOWING SCREEN,(say new receptor and or center), reading and writing from the same working directory 
    json subsets seems to work pretty well.  There may be a need to merge json files, which isn't too difficult. 
  
    see descriptions in ligands_example.yaml and ligands_dock.pl.
    see descriptions in receptors_example.yaml and receptors_dock.pl.

Stage 3. Analysis!  Updates to follow.

In the future, I would like to creat a generalized class for virtual screens that is 1. agnostic to the docking method
and 2. knows how to deal with both situations (many more ligands than receptors vs many more receptors than ligands).
  

 







