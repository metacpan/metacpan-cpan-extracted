[![pipeline status](https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragment-annotation/badges/master/pipeline.svg)](https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragment-annotation/commits/master)

[![coverage report](https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragment-annotation/badges/master/coverage.svg)](https://services.pfem.clermont.inra.fr/gitlab/fgiacomoni/metabolomics-fragment-annotation/commits/master)

# NAME

Metabolomics::Fragment::Annotation - Perl extension for fragment annotation in metabolomics 

# VERSION

        Version 0.6.4 - POD Update, multiAnnotation support in matching algo and writers, PeakForest REST API integration, supporting CSV and TSV as inputs (sniffer), HTML outputs
        Version 0.6.5 - Package architecture modification (PeakForest Part), POD improvement, Annotation results filtering based on scores
        Version 0.6.6 - Fix cpan bugs (#24) and fix several templates and properties issues (rel int, peakforest compliance, ...)
        Version 0.6.7 - version in progress

# SYNOPSIS

Note that this documentation is intended as a reference to the module.

        Metabolomics::Banks::MaConDa is allowing to build a contaminant database usefull to clean your LC-MS filtered peak list:
        
                my $oBank = Metabolomics::Banks::MaConDa->new() ;                       # init the bank object
                $oBank->getContaminantsExtensiveFromSource() ;                  # get theorical contaminants from the extensive version of MaConDa database
                $oNewBank->buildTheoPeakBankFromContaminants($queryMode) ;                      # build theorical bank (ION | NEUTRAL)
    
        Metabolomics::Banks::BloodExposome is giving access to a local Blood Exposome database (Cf publication here L<https://doi.org/10.1289/EHP4713>):
        
                my $oBank = Metabolomics::Banks::BloodExposome->new() ;                 # init the bank object
                $oBank->getMetabolitesFromSource($source) ;                     # get theorical metabolites from local database version
                $oBank->buildTheoPeakBankFromEntries($IonMode) ;                        # produce the new theorical bank depending of chosen acquisition mode
    
        Metabolomics::Banks::Knapsack is giving access to a local Knapsack database (Cf publication here L<https://doi.org/10.1093/pcp/pcr165>):
        
                my $oBank = Metabolomics::Banks::Knapsack->new() ;
                $oBank->getKSMetabolitesFromSource($source) ;
                $oBank->buildTheoPeakBankFromKnapsack($IonMode) ;
    
        Metabolomics::Banks::AbInitioFragments is used abinitio fragment, adduct and isotope annotation:
    
                my $oBank = Metabolomics::Banks::AbInitioFragments->new() ;                     # init the bank object
                $oBank->getFragmentsFromSource() ;                      # get theorical fragment/adduct/isotopes loses or adds
                $oBank->buildTheoPeakBankFromFragments($mzMolecule, $mode, $stateMolecule) ;                    # produce the new theorical bank from neutral (or not) molecule mass
                
        Metabolomics::Banks::PeakForest is giving access to any PeakForest database by its REST API
                
                my $oBank = Metabolomics::Banks::PeakForest->new(%PARAMS) ; # init the bank object with %PARAMS as DATABASE_URL, TOKEN, POLARITY, RESOLUTION
                $oBank->parsingMsFragmentsByCluster($expFile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds) ; # get fragments by cluster or pcgroup
                $oBank->buildSpectralBankFromPeakForest($column_code, $delta) ; # produce the new theorical bank querying REST API (GCMS part for this version)
                
                
        When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:

                my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;                       # init analysis object
                $oAnalysis->compareExpMzToTheoMzList('PPM', $ppmError) ;                        # compare theorical bank vs experimental bank (Best hit only)
                $oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ;         # compare theorical bank vs experimental bank (supporting multi annotation)
                
                $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular) ; # Write TSV enriched output with integrated input data
                $oAnalysis->writeTabularWithPeakBankObject($template, $tabular) ;                               # Write TSV enriched output
                $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile, $bestHitOnly ) ; # Write Html enriched output
                
        For spectral Annotation, Package allows to compute scores (ONLY GCMS scores for current package version) and filter results by threshold based on these scores
        
                my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;                       # init analysis object
                $oAnalysis->compareExpMzToTheoMzListAllMatches('MMU', $delta) ;         # compare theorical bank vs experimental bank (supporting multi annotation)
                
                my $scores = $oAnalysis->computeHrGcmsMatchingScores() ; # Compute _SCORE_PEARSON_CORR_ , _SCORE_Q_ and _SCORE_LIB_
                
                $oAnalysis->filterAnalysisSpectralAnnotationByScores($scores, '_SCORE_PEARSON_CORR_', 0.5) ;    
                
                $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular) ; # Write TSV enriched output with integrated input data
                $oAnalysis->writeTabularWithPeakBankObject($template, $tabular) ;                               # Write TSV enriched output
                $oAnalysis->writeHtmlWithSpectralBankObject($templateHTML, $htmlFile, $scores ) ; # Write Html enriched output
                
        Possible scores are:
                # For GC/MS Spectral annotation
                _SCORE_LIB_: Proportion of library spectrum's peaks with matches.
                _SCORE_Q_: Proposition of query peaks with matches.
                _SCORE_PEARSON_CORR_: Pearson correlation between intensities of paired peaks, where unmatched peaks are paired with zero-intensity "pseudo-peaks"

                # For LC/MS spectral annotation
                Work is in progress for version 0.6.6 of Metabolomics::Fragment::Annotation
                

# DESCRIPTION

Metabolomics::Fragment::Annotation is a full package for Perl dev allowing MS fragments annotation with ab initio database, contaminant and public metabolites ressources.

All resources used are described and available here:

# Metabolomics::Fragment::Annotation 0.6.x

Metabolomics::Fragment::Annotation Perl package proposes several databases and algorithms to help metabolomics identification step:

## Using BloodExposome database

The exposome represents the sum of all exposures during the life-span of an organism (from chemicals to microbes, viruses, radiation and other sources). Exposome chemicals are a major component of the exposome and are known to alter activities of cellular pathways and structures. In humans, exposome chemicals are transported throughout the body, linking chemical exposures to phenotypes such as such as cancer, ageing or diabetes. 
The Blood Exposome Database ([https://bloodexposome.org](https://bloodexposome.org)) is a collection of chemical compounds and associated information that were automatically extracted by text mining the content of PubMed and PubChem databases.
The database also unifies chemical lists from metabolomics, systems biology, environmental epidemiology, occupational expossure, toxiology and nutrition fields.
This db is developped and supported by Dinesh Kumar Barupal and Oliver Fiehn.
The database can be used in following applications - 1) to rank chemicals for building target libraries and expand metabolomics assays 2) to associate blood compounds with phenotypes 3) to get detailed descriptions about chemicals 4) to prepare lists of blood chemical lists by chemical classes and associated properties. 5) to interpret of metabolomics datasets from plasma or serum analyses 6) to prioritize chemicals for hazard assessments.

Metabolomics::Banks::BloodExposome is giving access to a up to date Blood Exposome database stored in metabolomics::references package

        # init the bank object
        
        my $oBank = Metabolomics::Banks::BloodExposome->new() ;
        
        # Get theorical metabolites from local database version
        
        $oBank->getMetabolitesFromSource($source) ;                     
        
        # produce the new theorical bank depending of chosen acquisition mode
        
        $oBank->buildTheoPeakBankFromEntries($IonMode) ;

When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:

        # Get experimental mz listing to annotate
        
        $oBank->parsingMsFragments($inputFile, $asHeader, $mzCol) ;                     
                
        # init analysis object based on a Knapsack bank object
        
        my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;                       
        
        # Compare theorical bank vs experimental bank with a delta on mz (Da or PPM are both supported)
        
        $oAnalysis->compareExpMzToTheoMzList('PPM', $ppmError) ;

Intensity and retention time variables are not used in this annotation because the reference bank does not store such features.

## Using KnapSack database

KnapSack database is a comprehensive Species-Metabolite Relationship Database with more than 53,000 metabolites and 128,000 metabolite-species pair entities.
This db is developped and supported by Yukiko Nakamura, Hiroko Asahi, Md. Altaf-Ul-Amin, Ken Kurokawa and Shigehiko Kanaya.
This resource is very useful for plant or natural product community trying to identify metabolites in samples analysed by LC-MS

        # init the bank object
        
        my $oBank = Metabolomics::Banks::Knapsack->new()
        
        # get theorical metabolites from last database version (crawled by metabolomics::references package)                    
        
        $oBank->getKSMetabolitesFromSource($source) ;
        
        # build potential candidates depending of your acquisition mode used on LC-MS instrument and produce the new theorical bank
        # Only POSITIVE or NEGATIVE is today supported - - "BOTH" does not work
        
        $oBank->buildTheoPeakBankFromKnapsack($IonMode) ;

When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:

        # Get experimental mz listing to annotate
        
        $oBank->parsingMsFragments($inputFile, $asHeader, $mzCol) ;                     
                
        # init analysis object based on a Knapsack bank object
        
        my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;                       
        
        # Compare theorical bank vs experimental bank with a delta on mz (Da or PPM are both supported)
        
        $oAnalysis->compareExpMzToTheoMzList('PPM', $ppmError) ; # Keep best hit only

Intensity and retention time variables are not used in this annotation because the reference bank does not store such features.

## Using PhytoHUB database

PhytoHub is a freely available electronic database containing detailed information about dietary phytochemicals and their human and animal metabolites. 
Around 1,200 polyphenols, terpenoids, alkaloids and other plant secondary metabolites present in commonly consumed foods (>350) are included, with >560 of their human or animal metabolites. 
For every phytochemical, the following is or will be soon available: 
	1) the chemical structure and identifyers 
	2) physico-chemical data such as solubility and physiological charge 
	3) the main dietary sources (extracted from the literature by a team of invited experts and from online databases such as FooDB and Phenol-Explorer) 
	4) known human metabolites (also manually extracted from the literature and from online databases by the curators), 
	5) in silico predicted metabolites, generated by Biotransformer (developed by Univ of Alberta) based on machine learning and expert knowledge of host and microbial metabolism, 
	6) monoisotopic mass and spectral data (collated from libraries of spectra such as MassBank and ReSpect (RIKEN MSn spectral database for phytochemicals), as well as from the literature and from our mass spectrometry/metabolomics laboratory and collaborating groups) 
	7) hyperlinks to other online databases.

PhytoHUB is a key resource in European JPI Projects FOODBALL (https://foodmetabolome.org/) and FOODPHYT (2019-2022).

This resource is very useful for foodmetabolome studies, trying to identify metabolites in samples analysed by LC-MS

\# init the bank object

        my $oBank = Metabolomics::Banks::PhytoHub->new( { POLARITY => $IonMode, } ) ;
        
        # get theorical metabolites from last database version (crawled by metabolomics::references package)                    
        
        $oBank->getMetabolitesFromSource($source) ;
        
        # build potential candidates depending of your acquisition mode used on LC-MS instrument and produce the new theorical bank
        # Only POSITIVE or NEGATIVE is today supported - - "BOTH" does not work
        
        $oBank->buildTheoPeakBankFromPhytoHub($IonMode) ;

When resources are built, Metabolomics::Fragment::Annotation drives the annotation process:

        # Don't forget to parse your tabular or CSV input peak list
        
        $oBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm $col

        # init analysis object based on a PhytoHUB bank object
        
        my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;

        # Compare theorical bank vs experimental bank with a delta on mz (Da or PPM are both supported)
        
        my $Annot = $oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ; ## multi annotation method

        # Write different outputs adapted for different view of results
        
        my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ; ## add result columns at the end of your inputfile 
                
                my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ; ## foreach mz from your peak list, give annotation results (can be several lines by mz)
                
                my $HtmlOuput = $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile ) ; A html results view + hyperlinks to database

# PUBLIC METHODS 

## Metabolomics::Fragment::Annotation

- new 

            ## Description : new
            ## Input : $self
            ## Ouput : bless $self ;
            ## Usage : my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;

- compareExpMzToTheoMzList

            ## Description : comparing two lists of mzs (theo and experimental) with a mz delta
            ## Input : $deltaValue, $deltaType
            ## Output : $oAnalysis with annotation results
            ## Usage : $oAnalysis->compareExpMzToTheoMzList ( $deltaValue, $deltaType ) ;

- compareExpMzToTheoMzListAllMatches

            ## Description : comparing two lists of mzs (theo and experimental) with a mz delta and keep all matches
            ## Input : $deltaValue, $deltaType
            ## Output : $oAnalysis with annotation results
            ## Usage : $oAnalysis->compareExpMzToTheoMzListAllMatches ( $deltaValue, $deltaType ) ;

- computeHrGcmsMatchingScores

            ## Description : compute by fullscan High resolution GCMS pseudospectra, all needed scores
            ## Input : $oAnalysis
            ## Output : $scores
            ## Usage : my ( $scores ) = $oAnalysis->computeHrGcmsMatchingScores ( ) ;

- filterAnalysisSpectralAnnotationByScores

            ## Description : filter a analysis object (after spectral annotation) by score
            ## Input : $oAnalysis, $scoreType, $scoreFilterValue
            ## Output : $oAnalysis
            ## Usage : my ( $oAnalysis ) = $oAnalysis->filterAnalysisSpectralAnnotationByScores ( $oAnalysis, $scoreType, $scoreFilterValue ) ;

- writeHtmlWithPeakBankObject

            ## Description : write a full html file from a template and mapping peak bank objects features
            ## Input : $oBank, $templateHTML, $htmlfile
            ## Output : $tabular
            ## Usage : my ( $htmlfile ) = $oBank->writeHtmlWithPeakBankObject ( $templateHTML, $htmlfile ) ;

- writeHtmlWithSpectralBankObject

            ## Description : write a output file in HTML format from a template and mapping spectral bank objects features
            ## Input : $oBank, $templateHTML, $htmlfile
            ## Output : $htmlfile
            ## Usage : my ( $htmlfile ) = $oBank->writeTabularWithPeakBankObject ( $templateHTML, $htmlfile ) ;

- writeTabularWithPeakBankObject

            ## Description : write a full tabular file from a template and mapping peak bank objects features
            ## Input : $oBank, $templateTabular, $tabular
            ## Output : $tabular
            ## Usage : my ( $tabular ) = $oBank->writeTabularWithPeakBankObject ( $templateTabular, $tabular ) ;

- writeFullTabularWithPeakBankObject

            ## Description : write a output containing the input data and new column concerning annotation work
            ## Input : $oBank, $inputData, $templateTabular, $tabular
            ## Output : $tabular
            ## Usage : my ( $tabular ) = $oBank->writeFullTabularWithPeakBankObject ( $inputData, $templateTabular, $tabular ) ;

- writePForestTabularWithPeakBankObject

            ## Description : write PForest compatible Tabular output file From a Peak Bank Object
            ## Input : $templateTabular, $tabular, $bestHitOnly
            ## Output : $PForestSpectraPeakListInTabular
            ## Usage : my ( $PForestSpectraPeakListInTabular ) = writePForestTabularWithPeakBankObject ( $inputTabularFile ) ;

# PRIVATE METHODS

## Metabolomics::Fragment::Annotation

- PRIVATE\_ONLY \_addAnnotatedPeakList

            ## Description : _addAnnotatedPeakList
            ## Input : $self, $type, $peakList ;
            ## Ouput : NA;
            ## Usage : _addAnnotatedPeakList($type, $peakList);

- PRIVATE\_ONLY \_getANNOTATION\_PARAMS\_DELTA

            ## Description : _getANNOTATION_PARAMS_DELTA
            ## Input : void
            ## Output : $VALUE
            ## Usage : my ( $VALUE ) = _getANNOTATION_PARAMS_DELTA () ;

- PRIVATE\_ONLY \_setANNOTATION\_PARAMS\_DELTA

            ## Description : _setANNOTATION_PARAMS_DELTA
            ## Input : $VALUE
            ## Output : TRUE
            ## Usage : _setANNOTATION_PARAMS_DELTA ( $VALUE ) ;

- PRIVATE\_ONLY \_getANNOTATION\_PARAMS\_DELTA\_TYPE

            ## Description : _getANNOTATION_PARAMS_DELTA_TYPE
            ## Input : void
            ## Output : $VALUE
            ## Usage : my ( $VALUE ) = _getANNOTATION_PARAMS_DELTA_TYPE () ;

- PRIVATE\_ONLY \_setANNOTATION\_PARAMS\_DELTA\_TYPE

            ## Description : _setANNOTATION_PARAMS_DELTA_TYPE
            ## Input : $VALUE
            ## Output : TRUE
            ## Usage : _setANNOTATION_PARAMS_DELTA_TYPE ( $VALUE ) ;

- PRIVATE\_ONLY \_getANNOTATION\_DB\_SOURCE

            ## Description : _getANNOTATION_DB_SOURCE
            ## Input : void
            ## Output : $VALUE
            ## Usage : my ( $VALUE ) = _getANNOTATION_DB_SOURCE () ;

- PRIVATE\_ONLY \_setANNOTATION\_DB\_SOURCE

            ## Description : _setANNOTATION_DB_SOURCE
            ## Input : $VALUE
            ## Output : TRUE
            ## Usage : _setANNOTATION_DB_SOURCE ( $VALUE ) ;

- PRIVATE\_ONLY \_getPeaksToAnnotated

            ## Description : get a specific list of peaks from the Annotation analysis object
            ## Input : $self, $type
            ## Output : $peakList
            ## Usage : my ( $peakList ) = $oAnalysis->_getPeakList ($type) ;

- PRIVATE\_ONLY \_setSpectraHtmlTboby

            ## Description : set Html body object (spectra) for output creation from the Annotation analysis object
            ## Input : 
            ## Output : oHtmlTbody
            ## Usage : my ( oHtmlTbody ) = _setSpectraHtmlTboby () ;

- PRIVATE\_ONLY \_setPeakHtmlTbody

            ## Description : set Html body object for ouput creation from the Annotation analysis object
            ## Input : 
            ## Output : oHtmlTbody
            ## Usage : my ( oHtmlTbody ) = _setPeakHtmlTbody () ;

- PRIVATE\_ONLY \_getTEMPLATE\_TABULAR\_FIELDS

            ## Description : get all fields of the tabular template file
            ## Input : $template
            ## Output : $fields
            ## Usage : my ( $fields ) = _getTEMPLATE_TABULAR_FIELDS ( $template ) ;

- PRIVATE\_ONLY \_mapPeakListWithTemplateFields

            ## Description : map any PeakList with any template fields from tabular
            ## Input : $fields, $peakList
            ## Output : $rows
            ## Usage : my ( $rows ) = _mapPeakListWithTemplateFields ( $fields, $peakList ) ;

- PRIVATE\_ONLY \_mergeAnnotationsAsString

            ## Description : Merge all annotations in a single string (annotation separated by '|') by annotated peak.
            ## Input : $rows, $peakList
            ## Output : $newRows
            ## Usage : my ( $newRows ) = _mergeAnnotationsAsString ( $rows, $peakList ) ;

- PRIVATE\_ONLY \_mz\_delta\_conversion

            ## Description : returns the minimum and maximum mass according to the delta
            ## Input : \$mass, \$delta_type, \$mz_delta
            ## Output : \$min, \$max
            ## Usage : ($min, $max)= mz_delta_conversion($mass, $delta_type, $mz_delta) ;

- PRIVATE\_ONLY \_computeMzDeltaInMmu

            ## Description : compute a delta (Da) between exp. mz and calc. mz
            ## based on http://www.waters.com/waters/en_GB/Mass-Accuracy-and-Resolution/nav.htm?cid=10091028&locale=en_GB
            ## Other ref : https://www.sciencedirect.com/science/article/pii/S1044030510004022
            ## Input : $expMz, $calcMz
            ## Output : $mzDeltaDa
            ## Usage : my ( $mzDeltaDa ) = _computeMzDeltaInMmu ( $expMz, $calcMz ) ;

- PRIVATE\_ONLY computeMzDeltaInPpm

            ## Description : compute a delta (PPM) between exp. mz and calc. mz - Delta m/Monoisotopic calculated exact mass * 100 
            ## Input : $expMz, $calcMz
            ## Output : $mzDeltaPpm
            ## Usage : my ( $mzDeltaPpm ) = computeMzDeltaInPpm ( $expMz, $calcMz ) ;

# AUTHOR

Franck Giacomoni, `<franck.giacomoni at inrae.fr>`
Biological computing & Metabolomics
INRAE - UMR 1019 Human Nutrition Unit – Metabolism Exploration Platform MetaboHUB – Clermont

# SEE ALSO

All information about FragNot should be find here: https://services.pfem.clermont.inrae.fr/gitlab/fgiacomoni/metabolomics-fragment-annotation

# BUGS

Please report any bugs or feature requests to `bug-metabolomics-fragment-annotation at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Metabolomics-Fragment-Annotation](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Metabolomics-Fragment-Annotation).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Metabolomics::Fragment::Annotation

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Metabolomics-Fragment-Annotation](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Metabolomics-Fragment-Annotation)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Metabolomics-Fragment-Annotation](http://annocpan.org/dist/Metabolomics-Fragment-Annotation)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Metabolomics-Fragment-Annotation](https://cpanratings.perl.org/d/Metabolomics-Fragment-Annotation)

- Search CPAN

    [https://metacpan.org/release/Metabolomics-Fragment-Annotation](https://metacpan.org/release/Metabolomics-Fragment-Annotation)

# ACKNOWLEDGEMENTS

Thank you to INRAE and All metabolomics colleagues.

# LICENSE AND COPYRIGHT

CeCILL Copyright (C) 2019 by Franck Giacomoni

Initiated by Franck Giacomoni

followed by INRAE PFEM team

Web Site = INRAE PFEM
