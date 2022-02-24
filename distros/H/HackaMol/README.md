HackaMol
========
Object-oriented Perl 5, Moose library for molecular hacking on multiple scales. 

VERSION 0.046
============
       
Please see [HackaMol on MetaCPAN](https://metacpan.org/release/HackaMol) for formatted documentation.  The [HackaMol publication](http://pubs.acs.org/doi/abs/10.1021/ci500359e) has a more complete description of the library ([pdf available from researchgate](http://www.researchgate.net/profile/Demian_Riccardi/publication/273778191_HackaMol_an_object-oriented_Modern_Perl_library_for_molecular_hacking_on_multiple_scales/links/550ebec60cf27526109e6ade.pdf )). 

Citation: J. Chem. Inf. Model., 2015, 55 (4), pp 721–726 

[Link to Jupyter Notebooks with the IPerl Kernel](https://github.com/demianriccardi/p5-IPerl-Notebooks/tree/master/HackaMol)
       
SYNOPSIS
========
```perl
use HackaMol;
my $mol = HackaMol->new->pdbid_mol('1L2Y.pdb');
# 1LY2 is an NMR structure of TRP-cage with multiple models

#recenter all coordinates to center of mass
foreach my $t ( 0 .. $mol->tmax) {
    $mol->t($t);
    $mol->translate( -$mol->COM );
}

#create array of CA atoms with full occupancy 

my @CAs = grep {
                 $_->name    eq 'CA'  and
                 $_->occ == 1 
               } $mol->all_atoms;

#print out the pdb with CA for several models from the NMR 
HackaMol::Molecule->new( 
                         atoms=>[@CAs] 
                       )-> print_pdb_ts([8,2,4,6,8,0], 'some.pdb');
``` 

DESCRIPTION
============
The HackaMol library enables users to build simple, yet powerful scripts 
for carrying out computational work on molecules at multiple scales. The 
molecular object system organizes atoms within molecules using groups, bonds, 
angles, and dihedrals.  HackaMol seeks to provide intuitive attributes and 
methods that may be harnessed to coerce computational chemistry through a 
common core. It is organized into two regions: HackaMol, the core (contained 
here) that has classes for atoms and molecules, and HackaMol::X, the 
extensions, such as HackaMol::X::PDB (TODO), a parser for protein databank 
files,  and HackaMol::X::Calculator, an abstract calculator for coercing 
computational chemistry, that use the core. The three major goals of the 
core are for it to be well-tested, well-documented, and easy to install. 
The goal of the extensions is to provide a more flexible space for 
researchers to develop and share new methods that use the core. 
       
INSTALLATION
============

To install HackaMol, I recommend using cpanminus and local::lib. This approach avoids the need for root privileges and uses the system Perl 
(available on most systems; see Strawberry Perl for Windows). 
I use *[Perlbrew](http://perlbrew.pl)* to manage local versions of Perl, but Perlbrew is overkill unless your system Perl is very old (if you do use Perlbrew, you won't need local::lib).

Here is a quick summary of a *[step by step post on installing Perl modules](http://perlmaven.com/install-perl-modules-without-root-rights-on-linux-ubuntu-13-10)*. Below, prompt> denotes your terminal prompt.  

  1. install cpanminus 

         prompt> curl -L http://cpanmin.us | perl - App::cpanminus

     Execution without superuser privileges will complain about not being to write to a path.  This is ok! It will create a perl5 directory in your home directory, in which all modules will be installed. Thus, an uninstall involves deleting the ~/perl5 directory.
    
  2. install local::lib

         prompt> ~/perl5/bin/cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)  
    
     Execution should install local::lib and configure the cpanm command to know about the ~/perl5 directory in the local shell.  

  3. configure .bash\_profile

         prompt> echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bash\_profile

     Execution will add the stuff between the quotes to your bash_profile, which enables automatic configuration of cpanminus and local::lib with every new terminal shell. To uninstall, delete this line from .bash\_profile
   
     You are now ready to install anything installable from CPAN!!!

  4. install HackaMol

         prompt> cpanm HackaMol
       
I use Dist::Zilla and a bunch of plugins to manage the CPAN releases. Dist::Zilla is widely used but fairly dependency heavy. You can install Dist::Zilla and build the library from the github clone, but that shouldn't be necessary. 

HackaMol is too fun to not be experimental! Feedback and contributions welcome!

HackaMol can also be installed with this one-liner:

    prompt> curl -L cpanmin.us | perl - -n HackaMol

This will install HackaMol and its dependencies in a perl5 directory in your path.  You'll need to set the PERL5LIB variable in your shell to find the install directory.  Probably something like this (let me know if otherwise):

    prompt> PERL5LIB=/home/path/perl5; export PERL5LIB 
