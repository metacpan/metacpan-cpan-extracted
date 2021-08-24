# metabolomics-references

This project centralizes all metabolomics documents, files as reference sources for central metabolomics databases without any webservices.

## Resource: MS_fragments-adducts-isotopes.txt

The MS_fragments-adducts-isotopes text file is a listing of most common adducts, isotopes and fragments found in LCMS metabolomics

## Database: MaConDa__v1_0__extensive.xml

MaConDa is a comprehensive and manually annotated database that provides a useful and unique resource for the MS community. The information contained in MaConDa is based on published literature and data provided by several colleagues and instrument manufacturers. MaConDa currently contains ca. 313 contaminant records detected across several MS platforms (Nov. 2020). The majority of records include theoretical as well as experimental MS data. In a few cases experimental data was included without definite identification.

MaConDa is offered to the public as a freely available resource. If you use MaConDa in your work, please cite:

Ralf J. M. Weber, Eva Li, Jonathan Bruty, Shan He & Mark R. Viant (2012). MaConDa: a publicly accessible Mass spectrometry Contaminants Database. Bioinformatics, doi:10.1093/bioinformatics/bts527.

MaConDa extensive version contains all contaminant properties (chemical features and instruments).

## Database: MaConDa__v1_0.xml

MaConDa__v1_0 version is a light version of MaConDa database and contains only chemical features as contaminant properties.

MaConDa is offered to the public as a freely available resource. If you use MaConDa in your work, please cite:

Ralf J. M. Weber, Eva Li, Jonathan Bruty, Shan He & Mark R. Viant (2012). MaConDa: a publicly accessible Mass spectrometry Contaminants Database. Bioinformatics, doi:10.1093/bioinformatics/bts527.

## Database: BloodExposome_v1_0.txt - Nov. 2019

The Blood Exposome DB is a collection of chemical compounds and associated information that were automatically extracted by text mining the content of PubMed and PubChem databases. The database also unifies chemical lists from metabolomics, systems biology, environmental epidemiology, occupational expossure, toxiology and nutrition fields.

https://doi.org/10.1289/EHP4713

http://bloodexposome.org

Properties:
  + Formal Charge: Formal charge is the difference between the number of valence electrons of each atom and the number of electrons the atom is associated with. Formal charge assumes any shared electrons are equally shared between the two bonded atoms.
  + Exact Mass: The exact mass of an isotopic species is obtained by summing the masses of the individual isotopes of the molecule. 
  + XLogP3: Computed Octanol/Water Partition Coefficient


## Database: Knapsack__v1_0.txt - Fev. 2017

KNApSAcK is a Comprehensive Species-Metabolite Relationship Database proposed by Yukiko Nakamura, Hiroko Asahi, Md. Altaf-Ul-Amin, Ken Kurokawa and Shigehiko Kanaya from NAIST Comparative Genomics Laboratory

This version was crawled in 2017 by anonymous and upload on https://datasetsearch.research.google.com with 50899 entries.

http://www.knapsackfamily.com/KNApSAcK_Family/

More updated statistics:
  + last update 	2020/01/06
  + metabolite 	51179 entries
  + metabolite-species pair    	116315 entries


## Database: PhytoHUB__v1_4 - Nov. 2020

PhytoHUB is a freely available electronic database containing detailed information about dietary phytochemicals and their human and animal metabolites.

Th V1.4 version contains more than 1700 precursors and metabolites.

This version was exported from the online db version (SQL query)
```sql

## get All entries with mz, inchikey and externals ids
SELECT entries.identifier, entries.name, entries.precursor_role, entries.metabolite_role, entries.moldb_mono_mass, entries.moldb_average_mass, entries.moldb_formula, entries.moldb_smiles, entries.original_inchi, entries.original_inchikey,  linkings.link_id, external_databases.`name` FROM `linkings`, `external_databases`, `entries` WHERE entries.id = linkings.`linker_id` AND linkings.`external_database_id` = `external_databases`.`id` AND `linker_type` = 'Entry' ;

## get minimum features for all entries
SELECT entries.identifier as phytohub_id, entries.name as compound_name, entries.precursor_role as is_a_precursor, entries.metabolite_role as is_a_metabolite, entries.moldb_mono_mass as exact_mass, entries.moldb_formula as molecular_formula, entries.moldb_smiles as smiles, entries.original_inchikey  as inchikey FROM `entries` WHERE entries.moldb_mono_mass IS NOT NULL ;

```