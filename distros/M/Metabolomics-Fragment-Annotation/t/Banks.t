# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Banks.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Metabolomics::Fragment::Annotation qw( :all ) ;

use Metabolomics::Banks qw( :all ) ;
use Metabolomics::Banks::BloodExposome qw( :all ) ;
use Metabolomics::Banks::AbInitioFragments qw( :all ) ;
use Metabolomics::Banks::MaConDa qw( :all ) ;
use Metabolomics::Banks::Knapsack qw( :all ) ;
use Metabolomics::Banks::PeakForest qw( :all ) ;

use Test::More tests =>  35 ;
use Data::Dumper ;




#########################



BEGIN {
	
	my $current_test = 1 ;
	my $modulePath = File::Basename::dirname( __FILE__ );
	
#########################	
	print "\n** Test $current_test FragNot package **\n" ; $current_test++ ;
	use_ok('Metabolomics::Fragment::Annotation') ;
	
#########################	
	print "\n** Test $current_test FragNot package **\n" ; $current_test++ ;
	use_ok('Metabolomics::Banks') ;
	
#########################	
	print "\n** Test $current_test FragNot package **\n" ; $current_test++ ;
	use_ok('Metabolomics::Banks::BloodExposome') ;	
	
#########################	
	print "\n** Test $current_test FragNot package **\n" ; $current_test++ ;
	use_ok('Metabolomics::Banks::AbInitioFragments') ;

#########################	
	print "\n** Test $current_test FragNot package **\n" ; $current_test++ ;
	use_ok('Metabolomics::Banks::MaConDa') ;
	
#########################	
	print "\n** Test $current_test FragNot package **\n" ; $current_test++ ;
	use_ok('Metabolomics::Banks::Knapsack') ;

#########################	
	print "\n** Test $current_test FragNot package **\n" ; $current_test++ ;
	use_ok('Metabolomics::Banks::PhytoHub') ;
	
## #################################################################################################################################
##
#########################	######################### 		BANKS TESTS 		#########################  #########################
##
####################################################################################################################################

#########################
	print "\n** Test $current_test - parsingMsFragmentsByCluster method **\n" ; $current_test++;
	is_deeply( parsingMsFragmentsByCluster_TEST(
		$modulePath.'/input_gcms_Diapason-annotation.tabular',
		'TRUE', #i_header
		2,	#$col_Mzs
		21, #$col_Ints
		13	#$col_ClusterIds
		),
		2468, #Nb of entries
		'Method \'parsingMsFragmentsByCluster\' return a bank object with exp peaks'
	) ;
	
## #################################################################################################################################
##
#########################	######################### BLOOD Exposome TESTS #########################  #########################
##
####################################################################################################################################

#########################		
	print "\n** Test $current_test init_BloodExposomeBankObject **\n" ; $current_test++;
	is_deeply( init_BloodExposomeBankObject_TEST(),
		bless( {
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_SPECTRA_' => {},
                 '_DATABASE_DOI_' => 'database_doi',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_URL_' => 'http://bloodexposome.org/',
                 '_DATABASE_URL_CARD_' => 'https://pubchem.ncbi.nlm.nih.gov/#query=',
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_POLARITY_' =>  undef,
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_NAME_' => 'Blood Exposome',
                 '_THEO_PEAK_LIST_' => []
               }, 'Metabolomics::Banks::BloodExposome' ) ,
		'Method \'initBloodExpBankObject\' init a well formatted bank object'
	) ;
	
	
#########################	

	print "\n** Test $current_test getBloodExposomeFromSource **\n" ; $current_test++;
	is_deeply( getBloodExposomeFromSourceTest(
			$modulePath.'/BloodExposome_v1_0_part.txt'),
			31, ## Nb of entries
			'Method \'getMetabolitesFromSource\' works with BloodExposome db as a well formatted source file');
		
#########################

	print "\n** Test $current_test buildTheoPeakBankFromEntries **\n" ; $current_test++;
	is_deeply( buildTheoPeakBankFromEntriesTest(
		$modulePath.'/BloodExposome_v1_0_part.txt', 
		'POSITIVE'),
		29, ## Nb of theo peaks from entries - 31 is the total and 29 is POS filtered entries
		'Method \'buildTheoPeakBankFromEntries\' works with BloodExposome db object' );
		
		
## #################################################################################################################################
##
#########################	######################### AB INITIO FRAGMENTS TESTS #########################  #########################
##
####################################################################################################################################

#########################		
	print "\n** Test $current_test init_AbInitioFragBankObject **\n" ; $current_test++;
	is_deeply( init_AbInitioFragBankObject_TEST(),
		##Expected:
		bless( {
                 '_FRAGMENTS_' => [],
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_SPECTRA_' => {},
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_URL_CARD_' => 'database_url_card',
                 '_DATABASE_TYPE_' => 'FRAGMENT',
                 '_POLARITY_' =>  undef,
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_THEO_PEAK_LIST_' => []
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		'Method \'init_AbInitioFragBankObject\' init a well formatted bank object'
	) ;

	print "\n** Test $current_test getFragmentsFromSource for AbInitioFrag **\n" ; $current_test++;
	is_deeply( getFragmentsFromSourceTest(
		## Argts
			$modulePath.'/MS_fragments-adducts-isotopes-test.txt'),
		## Expected:
			bless( {
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_URL_CARD_' => 'database_url_card',
                 '_DATABASE_TYPE_' => 'FRAGMENT',
                 '_POLARITY_' =>  undef,
                 '_DATABASE_DOI_' => 'database_doi',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_TYPE_' => 'adduct'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '13C db '
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '0.997034893'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_TYPE_' => 'fragment',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '-352.064176',
                                             '_TYPE_' => 'fragment'
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [], 
                 '_DATABASE_VERSION_' => '1.0'
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		## Eval:
			'Method \'getFragmentsFromSource\' works with a well formatted source file');

#########################	
	print "\n** Test $current_test buildTheoPeakBankFromFragments **\n" ; $current_test++;
	is_deeply( buildTheoPeakBankFromFragmentsTest(
		## Argts
			$modulePath.'/MS_fragments-adducts-isotopes-test.txt', 118.086),
		## Expected
			bless( {
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_URL_CARD_' => 'database_url_card',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_TYPE_' => 'FRAGMENT',
                 '_POLARITY_' =>  undef,
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_TYPE_' => 'adduct'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_TYPE_' => 'adduct'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'fragment',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_DELTA_MASS_' => '-352.064176',
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '178.024',
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_RELATIVE_INTENSITY_999_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '156.042',
                                                  '_INTENSITY_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ID_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_MMU_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.588',
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_INTENSITY_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '119.083',
                                                  '_MMU_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_CLUSTER_ID_' => undef
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_SPECTRA_' => {},
                 '_DATABASE_ENTRIES_' => [],
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_VERSION_' => '1.0'
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		## Eval
			'Method \'buildTheoPeakBankFromFragments\' works with a refFragments object');
		

#########################	
	print "\n** Test $current_test buildTheoPeakBankFromFragments **\n" ; $current_test++;
	is_deeply( buildTheoPeakBankFromFragmentsTest(
		## Argts
			$modulePath.'/MS_fragments-adducts-isotopes-test.txt', 100.00001),
		## Expected
			bless( {
                 '_DATABASE_DOI_' => 'database_doi',
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '37.95588165'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_TYPE_' => 'isotope'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '0.997034893'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_TYPE_' => 'fragment'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '-352.064176',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'fragment'
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '159.93784',
                                                  '_INTENSITY_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_NAME_' => '-H+K',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ID_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '137.95589',
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_CLUSTER_ID_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.50169',
                                                  '_INTENSITY_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.99704',
                                                  '_INTENSITY_' => undef
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_SPECTRA_' => {},
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_URL_CARD_' => 'database_url_card',
                 '_DATABASE_TYPE_' => 'FRAGMENT',
                 '_POLARITY_' =>  undef,
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_VERSION_' => '1.0',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {}
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		## Eval
			'Method \'buildTheoPeakBankFromFragments\' works with a refFragments object');


#########################	
	print "\n** Test $current_test buildTheoDimerFromMz **\n" ; $current_test++;
	is_deeply( buildTheoDimerFromMzTest(
		## Argts
			bless( {
                 '_DATABASE_URL_' => 'database_url',
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                         		  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 159.93784,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                         		  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 137.95589,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                         		  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 100.50169,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                         		  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 100.99704
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '59.9378259'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_TYPE_' => 'adduct',
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'isotope',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_TYPE_' => 'isotope'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_TYPE_' => 'fragment',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'fragment',
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_DELTA_MASS_' => '-352.064176'
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
               }, 'Metabolomics::Banks::AbInitioFragments' ),
			100.00001,
			'POSITIVE'),
		## Expected
			bless( {
                 '_DATABASE_DOI_' => 'database_doi',
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '159.93784',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_SMILES_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_PPM_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_NAME_' => '-H+K',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '137.95589',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_PPM_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.50169',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.99704',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+3H2O+2H',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_NAME_' => '2M+3H2O+2H',
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '228.02314',
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+ACN+H',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_NAME_' => '2M+ACN+H',
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '242.03384',
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '264.01578',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_INTENSITY_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+ACN+Na',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_NAME_' => '2M+ACN+Na',
                                                  '_RELATIVE_INTENSITY_100_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_ANNOTATION_NAME_' => '2M+H',
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+H',
                                                  '_MMU_ERROR_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '201.00730',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '238.96318',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_NAME_' => '2M+K',
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+K',
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+Na',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_ANNOTATION_NAME_' => '2M+Na',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '222.98924',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_INTENSITY_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '218.03384',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+NH4',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_ANNOTATION_NAME_' => '2M+NH4',
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATIONS_' => []
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_URL_' => 'database_url',
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_TYPE_' => 'adduct',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'isotope',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'fragment',
                                             '_DELTA_MASS_' => '-352.064176'
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_EXP_PEAK_LIST_' => [],
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_NAME_' => 'Ab Initio Fragments'
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		## Eval
			'Method \'buildTheoDimerFromMz\' works with a oBank object' );


#########################	
	print "\n** Test $current_test isotopicAdvancedCalculation **\n" ; $current_test++;
	is_deeply( isotopicAdvancedCalculationTest(
		## Argts
			bless( {
                 '_DATABASE_URL_' => 'database_url',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '159.93784',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '137.95589',
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ID_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.50169',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.99704',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K_13C db ',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '160.43952',
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_13C db ',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K_15N',
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '160.93487',
                                                  '_ID_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_15N',
                                                  '_MMU_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATIONS_' => []
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_13C db ',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ID_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '138.45757',
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K_13C db '
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K_15N',
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '138.95292',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_15N',
                                                  '_MMU_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '59.9378259'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_TYPE_' => 'adduct',
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'isotope',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_TYPE_' => 'isotope'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_TYPE_' => 'fragment',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'fragment',
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_DELTA_MASS_' => '-352.064176'
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_EXP_PEAK_LIST_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments'
               }, 'Metabolomics::Banks::AbInitioFragments' ),
			'POSITIVE'),
		## Expected
			bless( {
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_TYPE_' => 'adduct',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '59.9378259'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'isotope',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '0.501677419'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'isotope',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '0.997034893'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_TYPE_' => 'fragment',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'fragment',
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '-352.064176'
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_ENTRIES_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '159.93784'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '137.95589',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_INCHIKEY_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.50169',
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.99704',
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_13C db ',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K_13C db ',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '160.43952',
                                                  '_ANNOTATION_FORMULA_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '160.93487',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_15N',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K_15N',
                                                  '_ANNOTATION_SMILES_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K_13C db ',
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_13C db ',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '138.45757',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_SPECTRA_ID_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_15N',
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K_15N',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '138.95292',
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_SPECTRA_ID_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_13C db ',
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K_13C db ',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '160.43952',
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_RELATIVE_INTENSITY_999_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATIONS_' => [],
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '160.93487',
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_15N',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K_15N'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_CLUSTER_ID_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_13C db ',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K_13C db ',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '138.45757',
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_RELATIVE_INTENSITY_999_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '138.95292',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_ANNOTATIONS_' => [],
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K_15N',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_15N',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_CLUSTER_ID_' => undef,
                                                  '_SPECTRA_ID_' => undef
                                                }, 'Metabolomics::Banks' )
                                       ]
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		## Eval
			'Method \'isotopicAdvancedCalculation\' works with a oBank object' );

## #################################################################################################################################
##
#########################	######################### MACONDA DB TESTS #########################  #########################
##
####################################################################################################################################


#########################		
	print "\n** Test $current_test getMetaboliteFromSource **\n" ; $current_test++;
	is_deeply( init_MaConDaBankObject_TEST(),
		##Expected:
		bless( {
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_THEO_PEAK_LIST_' => [],
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_DATABASE_ENTRIES_' => [],
                 '_CONTAMINANTS_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE', 
               }, 'Metabolomics::Banks::MaConDa' ),
		'Method \'initBloodExpBankObject\' init a well formatted bank object'
	) ;

#########################	
	print "\n** Test $current_test getContaminantsFromSource **\n" ; $current_test++;
	is_deeply( getContaminantsFromSourceTest(
		## Argts
			$modulePath.'/MaConDa__v1_0.xml'),
		## Expected:
			bless( {
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_SPECTRA_' => {},
                 '_DATABASE_ENTRIES_' => [],
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_PUBCHEM_CID_' => '176',
                                                '_ID_' => 'CON00001',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_NAME_' => 'Acetic Acid',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_STD_INCHI_' => undef,
                                                '_PUBCHEM_CID_' => undef,
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_ID_' => 'CON00002',
                                                '_STD_INCHI_KEY_' => undef,
                                                '_NAME_' => 'Acetonitrile (fragment)',
                                                '_EXACT_MASS_' => '26.003074',
                                                '_FORMULA_' => 'CN'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_ID_' => 'CON00015',
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_EXACT_MASS_' => '132.905452',
                                                '_FORMULA_' => 'Cs',
                                                '_NAME_' => 'Cs-133',
                                                '_STD_INCHI_KEY_' => undef,
                                                '_STD_INCHI_' => undef,
                                                '_PUBCHEM_CID_' => undef
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_STD_INCHI_KEY_' => 'IAZDPXIOMUYVGZ-WFGJKAKNSA-N',
                                                '_EXACT_MASS_' => '84.051593',
                                                '_FORMULA_' => 'C2D6OS',
                                                '_NAME_' => 'd6-Dimethylsulfoxide',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_ID_' => 'CON00016',
                                                '_PUBCHEM_CID_' => '75151',
                                                '_STD_INCHI_' => 'InChI=1S/C2H6OS/c1-4(2)3/h1-2H3/i1D3,2D3'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_STD_INCHI_' => undef,
                                                '_PUBCHEM_CID_' => undef,
                                                '_ID_' => 'CON00017',
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_EXACT_MASS_' => '514.405582',
                                                '_NAME_' => 'DDTDP',
                                                '_FORMULA_' => 'C30H58O4S',
                                                '_STD_INCHI_KEY_' => undef
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_DATABASE_NAME_' => 'MaConDa'
               }, 'Metabolomics::Banks::MaConDa' ),
		## MSG:
			'Method \'getContaminantsFromSource\' works with a well formatted source file');

#########################	
	print "\n** Test $current_test getContaminantsExtensiveFromSource **\n" ; $current_test++;
	is_deeply( getContaminantsExtFromSourceTest(
		## ARGTS
			$modulePath.'/MaConDa__v1_0__extensive.xml'),
		## Expected:
			bless( {
                 '_DATABASE_VERSION_' => '1.0',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_MZ_' => '59',
                                                '_NAME_' => 'Acetic Acid',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_ID_' => 'CON00001',
                                                '_ION_FORM_' => '[M-H]-',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_PUBCHEM_CID_' => '176',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_ION_MODE_' => 'NEG'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_EXACT_ADDUCT_MASS_' => '537.8790134',
                                                '_MZ_' => '537.88',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_NAME_' => 'Acetic Acid',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_ION_FORM_' => '[M6-H6+Fe3+O]+',
                                                '_INSTRUMENT_' => 'Finnigan TSQ-700',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_REFERENCE_' => 'Ijames, C. F., Dutky, R. C., & Fales, H. M. (1995). Iron carboxylate oxygen-centered-triangle complexes detected during electrospray use of organic acid modifiers with a comment on the Finnigan TSQ-700 electrospray inlet system. Journal of the American Society for Mass Spectrometry, 6(12), 1226-1231, doi:10.1016/1044-0305(95)00579-x.',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_ID_' => 'CON00001',
                                                '_ION_MODE_' => 'POS',
                                                '_PUBCHEM_CID_' => '176',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_INSTRUMENT_TYPE_' => 'Triple quadrupole'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_ION_MODE_' => 'POS',
                                                '_PUBCHEM_CID_' => '176',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_INSTRUMENT_TYPE_' => 'Triple quadrupole',
                                                '_ION_FORM_' => '[M6-H6+H2O+Fe3+O]+',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_INSTRUMENT_' => 'Finnigan TSQ-700',
                                                '_REFERENCE_' => 'Ijames, C. F., Dutky, R. C., & Fales, H. M. (1995). Iron carboxylate oxygen-centered-triangle complexes detected during electrospray use of organic acid modifiers with a comment on the Finnigan TSQ-700 electrospray inlet system. Journal of the American Society for Mass Spectrometry, 6(12), 1226-1231, doi:10.1016/1044-0305(95)00579-x.',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_ID_' => 'CON00001',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_NAME_' => 'Acetic Acid',
                                                '_EXACT_ADDUCT_MASS_' => '555.8895784',
                                                '_MZ_' => '555'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_EXACT_ADDUCT_MASS_' => '325.2584664',
                                                '_MZ_' => '324.9',
                                                '_NAME_' => 'Butyl Carbitol',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_REFERENCE_' => 'Gibson, C. R., & Brown, C. M. (2003). Identification of diethylene glycol monobutyl ether as a source of contamination in an ion trap mass spectrometer. Journal of the American Society for Mass Spectrometry, 14(11), 1247-1249, doi:10.1016/s1044-0305(03)00534-8.',
                                                '_TYPE_OF_CONTAMINANT_' => 'Scintillation cocktail',
                                                '_EXACT_MASS_' => '162.125595',
                                                '_FORMULA_' => 'C8H18O3',
                                                '_INSTRUMENT_' => 'ThermoFinnigan LCQ Deca XP',
                                                '_ID_' => 'CON00010',
                                                '_ION_FORM_' => '[M2+H]+',
                                                '_STD_INCHI_KEY_' => 'OAYXUHPQHDHDDZ-UHFFFAOYSA-N',
                                                '_PUBCHEM_CID_' => '8177',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_STD_INCHI_' => 'InChI=1S/C8H18O3/c1-2-3-5-10-7-8-11-6-4-9/h9H,2-8H2,1H3',
                                                '_ION_MODE_' => 'POS'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_NAME_' => 'Butylated Hydroxyanisole',
                                                '_EXACT_ADDUCT_MASS_' => '181.1223064',
                                                '_MZ_' => '181.122306',
                                                '_ION_MODE_' => 'POS',
                                                '_STD_INCHI_' => 'InChI=1S/C11H16O2/c1-11(2,3)9-7-8(13-4)5-6-10(9)12/h5-7,12H,1-4H3',
                                                '_PUBCHEM_CID_' => '11954184',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_STD_INCHI_KEY_' => 'MRBKEAMVRSLQPH-UHFFFAOYSA-N',
                                                '_ION_FORM_' => '[M+H]+',
                                                '_FORMULA_' => 'C11H16O2',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_EXACT_MASS_' => '180.11503',
                                                '_TYPE_OF_CONTAMINANT_' => 'Antioxidant',
                                                '_ID_' => 'CON00011'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_ION_FORM_' => '[M+Na]+',
                                                '_STD_INCHI_KEY_' => 'MRBKEAMVRSLQPH-UHFFFAOYSA-N',
                                                '_ID_' => 'CON00011',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_FORMULA_' => 'C11H16O2',
                                                '_EXACT_MASS_' => '180.11503',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_TYPE_OF_CONTAMINANT_' => 'Antioxidant',
                                                '_ION_MODE_' => 'POS',
                                                '_PUBCHEM_CID_' => '11954184',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_STD_INCHI_' => 'InChI=1S/C11H16O2/c1-11(2,3)9-7-8(13-4)5-6-10(9)12/h5-7,12H,1-4H3',
                                                '_MZ_' => '203.104249',
                                                '_EXACT_ADDUCT_MASS_' => '203.1042514',
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_NAME_' => 'Butylated Hydroxyanisole'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_STD_INCHI_KEY_' => 'AFVLVVWMAFSXCK-VMPITWQZSA-N',
                                                '_ION_FORM_' => '[M2+63Cu(I)]+',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_TYPE_OF_CONTAMINANT_' => 'Matrix compound',
                                                '_EXACT_MASS_' => '189.042594',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_FORMULA_' => 'C10H7NO3',
                                                '_ID_' => 'CON00298',
                                                '_ION_MODE_' => 'POS',
                                                '_STD_INCHI_' => 'InChI=1S/C10H7NO3/c11-6-8(10(13)14)5-7-1-3-9(12)4-2-7/h1-5,12H,(H,13,14)/b8-5+',
                                                '_PUBCHEM_CID_' => '5328791',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_EXACT_ADDUCT_MASS_' => '441.0142384',
                                                '_MZ_' => '441.01479',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_NAME_' => '4-HCCA'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_NAME_' => 'unknown',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_EXACT_ADDUCT_MASS_' => undef,
                                                '_MZ_' => '933',
                                                '_STD_INCHI_' => undef,
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_PUBCHEM_CID_' => undef,
                                                '_ION_MODE_' => 'POS',
                                                '_REFERENCE_' => 'NewObjective Common Background Ions for Electrospray (Positive Ion). http://www.newobjective.com/downloads/technotes/PV-3.pdf.',
                                                '_EXACT_MASS_' => undef,
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_FORMULA_' => 'unknown',
                                                '_ID_' => 'CON00315',
                                                '_ION_FORM_' => undef,
                                                '_STD_INCHI_KEY_' => undef
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb'
               }, 'Metabolomics::Banks::MaConDa' ),
		## MSG:
			'Method \'getContaminantsExtensiveFromSource\' works with a well formatted source file');

#########################	
	print "\n** Test $current_test extractContaminantTypes **\n" ; $current_test++;
	is_deeply( extractContaminantTypesTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml'),
	## Expected:
	{
          'Antioxidant' => 2,
          'unknown' => 1,
          'Scintillation cocktail' => 1,
          'Matrix compound' => 1,
          'Solvent' => 3
     },
     ## MSG:
		'Method \'extractContaminantTypes\' works with a refContaminant object');

########################	
	print "\n** Test $current_test extractContaminantInstruments **\n" ; $current_test++;
	is_deeply( extractContaminantInstrumentsTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml'),
	{
		'Finnigan TSQ-700' => 2,
        'Micromass Platform II' => 1,
        'ThermoFinnigan LCQ Deca XP' => 1,
        'unknown' => 4
     },
		'Method \'extractContaminantInstruments\' works with a refContaminant object');
		
#########################	
	print "\n** Test $current_test extractContaminantInstrumentTypes **\n" ; $current_test++;
	is_deeply( extractContaminantInstrumentTypesTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml'),
	{
          'Triple quadrupole' => 2,
          'Ion trap' => 2,
          'unknown' => 4
     },
		'Method \'extractContaminantInstrumentTypes\' works with a refContaminant object');



#########################	
	print "\n** Test $current_test filterContaminantIonMode **\n" ; $current_test++;
	is_deeply( filterContaminantIonModeTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml', 
		'POSITIVE'
		),
		bless( {
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_SPECTRA_' => {},
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_FORMULA_' => 'C2H4O2',
                                                '_MZ_' => '537.88',
                                                '_NAME_' => 'Acetic Acid',
                                                '_ION_MODE_' => 'POS',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_EXACT_MASS_' => '60.02113',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_PUBCHEM_CID_' => '176',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_INSTRUMENT_' => 'Finnigan TSQ-700',
                                                '_ION_FORM_' => '[M6-H6+Fe3+O]+',
                                                '_ID_' => 'CON00001',
                                                '_EXACT_ADDUCT_MASS_' => '537.8790134',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_REFERENCE_' => 'Ijames, C. F., Dutky, R. C., & Fales, H. M. (1995). Iron carboxylate oxygen-centered-triangle complexes detected during electrospray use of organic acid modifiers with a comment on the Finnigan TSQ-700 electrospray inlet system. Journal of the American Society for Mass Spectrometry, 6(12), 1226-1231, doi:10.1016/1044-0305(95)00579-x.',
                                                '_INSTRUMENT_TYPE_' => 'Triple quadrupole'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_PUBCHEM_CID_' => '176',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_INSTRUMENT_' => 'Finnigan TSQ-700',
                                                '_ION_FORM_' => '[M6-H6+H2O+Fe3+O]+',
                                                '_ID_' => 'CON00001',
                                                '_EXACT_ADDUCT_MASS_' => '555.8895784',
                                                '_INSTRUMENT_TYPE_' => 'Triple quadrupole',
                                                '_REFERENCE_' => 'Ijames, C. F., Dutky, R. C., & Fales, H. M. (1995). Iron carboxylate oxygen-centered-triangle complexes detected during electrospray use of organic acid modifiers with a comment on the Finnigan TSQ-700 electrospray inlet system. Journal of the American Society for Mass Spectrometry, 6(12), 1226-1231, doi:10.1016/1044-0305(95)00579-x.',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_MZ_' => '555',
                                                '_NAME_' => 'Acetic Acid',
                                                '_ION_MODE_' => 'POS',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_EXACT_MASS_' => '60.02113'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_EXACT_MASS_' => '162.125595',
                                                '_ION_MODE_' => 'POS',
                                                '_FORMULA_' => 'C8H18O3',
                                                '_NAME_' => 'Butyl Carbitol',
                                                '_MZ_' => '324.9',
                                                '_EXACT_ADDUCT_MASS_' => '325.2584664',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_REFERENCE_' => 'Gibson, C. R., & Brown, C. M. (2003). Identification of diethylene glycol monobutyl ether as a source of contamination in an ion trap mass spectrometer. Journal of the American Society for Mass Spectrometry, 14(11), 1247-1249, doi:10.1016/s1044-0305(03)00534-8.',
                                                '_STD_INCHI_' => 'InChI=1S/C8H18O3/c1-2-3-5-10-7-8-11-6-4-9/h9H,2-8H2,1H3',
                                                '_ID_' => 'CON00010',
                                                '_TYPE_OF_CONTAMINANT_' => 'Scintillation cocktail',
                                                '_ION_FORM_' => '[M2+H]+',
                                                '_INSTRUMENT_' => 'ThermoFinnigan LCQ Deca XP',
                                                '_STD_INCHI_KEY_' => 'OAYXUHPQHDHDDZ-UHFFFAOYSA-N',
                                                '_PUBCHEM_CID_' => '8177',
                                                '_ION_SOURCE_TYPE_' => 'ESI'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_TYPE_OF_CONTAMINANT_' => 'Antioxidant',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_ION_FORM_' => '[M+H]+',
                                                '_STD_INCHI_KEY_' => 'MRBKEAMVRSLQPH-UHFFFAOYSA-N',
                                                '_PUBCHEM_CID_' => '11954184',
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_EXACT_ADDUCT_MASS_' => '181.1223064',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_STD_INCHI_' => 'InChI=1S/C11H16O2/c1-11(2,3)9-7-8(13-4)5-6-10(9)12/h5-7,12H,1-4H3',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_ID_' => 'CON00011',
                                                '_ION_MODE_' => 'POS',
                                                '_FORMULA_' => 'C11H16O2',
                                                '_MZ_' => '181.122306',
                                                '_NAME_' => 'Butylated Hydroxyanisole',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_EXACT_MASS_' => '180.11503'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_STD_INCHI_' => 'InChI=1S/C11H16O2/c1-11(2,3)9-7-8(13-4)5-6-10(9)12/h5-7,12H,1-4H3',
                                                '_EXACT_ADDUCT_MASS_' => '203.1042514',
                                                '_ID_' => 'CON00011',
                                                '_ION_FORM_' => '[M+Na]+',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_TYPE_OF_CONTAMINANT_' => 'Antioxidant',
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_PUBCHEM_CID_' => '11954184',
                                                '_STD_INCHI_KEY_' => 'MRBKEAMVRSLQPH-UHFFFAOYSA-N',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_EXACT_MASS_' => '180.11503',
                                                '_ION_MODE_' => 'POS',
                                                '_MZ_' => '203.104249',
                                                '_NAME_' => 'Butylated Hydroxyanisole',
                                                '_FORMULA_' => 'C11H16O2'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_STD_INCHI_KEY_' => 'AFVLVVWMAFSXCK-VMPITWQZSA-N',
                                                '_PUBCHEM_CID_' => '5328791',
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_TYPE_OF_CONTAMINANT_' => 'Matrix compound',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_ION_FORM_' => '[M2+63Cu(I)]+',
                                                '_ID_' => 'CON00298',
                                                '_EXACT_ADDUCT_MASS_' => '441.0142384',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_STD_INCHI_' => 'InChI=1S/C10H7NO3/c11-6-8(10(13)14)5-7-1-3-9(12)4-2-7/h1-5,12H,(H,13,14)/b8-5+',
                                                '_FORMULA_' => 'C10H7NO3',
                                                '_MZ_' => '441.01479',
                                                '_NAME_' => '4-HCCA',
                                                '_ION_MODE_' => 'POS',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_EXACT_MASS_' => '189.042594'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_EXACT_MASS_' => undef,
                                                '_MZ_' => '933',
                                                '_NAME_' => 'unknown',
                                                '_FORMULA_' => 'unknown',
                                                '_ION_MODE_' => 'POS',
                                                '_ID_' => 'CON00315',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_REFERENCE_' => 'NewObjective Common Background Ions for Electrospray (Positive Ion). http://www.newobjective.com/downloads/technotes/PV-3.pdf.',
                                                '_STD_INCHI_' => undef,
                                                '_EXACT_ADDUCT_MASS_' => undef,
                                                '_PUBCHEM_CID_' => undef,
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_STD_INCHI_KEY_' => undef,
                                                '_ION_FORM_' => undef,
                                                '_INSTRUMENT_' => 'unknown',
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown'
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => 'POSITIVE',
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb'
               }, 'Metabolomics::Banks::MaConDa' ),
		'Method \'filterContaminantIonMode\' works with a refContaminants object and POSITIVE ion mode');

#########################	
	print "\n** Test $current_test filterContaminantIonMode **\n" ; $current_test++;
	is_deeply( filterContaminantIonModeTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml', 
		'NEGATIVE'
		),
	##Expected :
		bless( {
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_MZ_' => '59',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_ION_MODE_' => 'NEG',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_NAME_' => 'Acetic Acid',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_ID_' => 'CON00001',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_PUBCHEM_CID_' => '176',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_ION_FORM_' => '[M-H]-'
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => 'NEGATIVE',
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_VERSION_' => '1.0',
                 '_THEO_PEAK_LIST_' => []
               }, 'Metabolomics::Banks::MaConDa' ),
		'Method \'filterContaminantIonMode\' works with a refContaminants object and NEGATIVE ion mode');
		
#########################	
	print "\n** Test $current_test filterContaminantInstruments **\n" ; $current_test++;
	is_deeply( filterContaminantInstrumentsTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml', 
		['Micromass Platform II']
		),
		##### Expected results
		bless( {
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_DATABASE_ENTRIES_' => [],
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_FORMULA_' => 'C2H4O2',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_PUBCHEM_CID_' => '176',
                                                '_ION_MODE_' => 'NEG',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_ID_' => 'CON00001',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_ION_FORM_' => '[M-H]-',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_MZ_' => '59',
                                                '_NAME_' => 'Acetic Acid',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N'
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb'
               }, 'Metabolomics::Banks::MaConDa' ),
		'Method \'filterContaminantInstruments\' works with a refContaminants object and \'unknown\' instrument');

#########################	
	print "\n** Test $current_test filterContaminantInstrumentTypes **\n" ; $current_test++;
	is_deeply( filterContaminantInstrumentTypesTest(
			$modulePath.'/MaConDa__v1_0__extensive.xml', 
			['Ion trap']
		),
		##### Expected results
		bless( {
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_' => [],
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_ION_FORM_' => '[M-H]-',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_MZ_' => '59',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_ION_MODE_' => 'NEG',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_NAME_' => 'Acetic Acid',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_ID_' => 'CON00001',
                                                '_PUBCHEM_CID_' => '176',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.'
                                              }, 'Metabolomics::Banks::MaConDa' ),
                                       bless( {
                                                '_FORMULA_' => 'C8H18O3',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_MZ_' => '324.9',
                                                '_TYPE_OF_CONTAMINANT_' => 'Scintillation cocktail',
                                                '_ION_MODE_' => 'POS',
                                                '_STD_INCHI_' => 'InChI=1S/C8H18O3/c1-2-3-5-10-7-8-11-6-4-9/h9H,2-8H2,1H3',
                                                '_EXACT_ADDUCT_MASS_' => '325.2584664',
                                                '_ION_FORM_' => '[M2+H]+',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_INSTRUMENT_' => 'ThermoFinnigan LCQ Deca XP',
                                                '_ID_' => 'CON00010',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_EXACT_MASS_' => '162.125595',
                                                '_NAME_' => 'Butyl Carbitol',
                                                '_PUBCHEM_CID_' => '8177',
                                                '_REFERENCE_' => 'Gibson, C. R., & Brown, C. M. (2003). Identification of diethylene glycol monobutyl ether as a source of contamination in an ion trap mass spectrometer. Journal of the American Society for Mass Spectrometry, 14(11), 1247-1249, doi:10.1016/s1044-0305(03)00534-8.',
                                                '_STD_INCHI_KEY_' => 'OAYXUHPQHDHDDZ-UHFFFAOYSA-N'
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_DATABASE_VERSION_' => '1.0'
               }, 'Metabolomics::Banks::MaConDa' ),
		'Method \'filterContaminantInstrumentTypes\' works with a refContaminants object and \'Ion trap\' instrument');

#########################	
	print "\n** Test $current_test buildTheoPeakBankFromContaminants **\n" ; $current_test++;
	is_deeply( buildTheoPeakBankFromContaminantsTest(
		# oBank
		bless( {
                 '_DATABASE_ENTRIES_' => [],
                 '_EXP_PEAK_LIST_' => [],
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_MZ_' => '59',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_ION_MODE_' => 'NEG',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_NAME_' => 'Acetic Acid',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_ID_' => 'CON00001',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_PUBCHEM_CID_' => '176',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_ION_FORM_' => '[M-H]-'
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_VERSION_' => '1.0',
                 '_THEO_PEAK_LIST_' => []
               }, 'Metabolomics::Banks::MaConDa' ),
        # query mode
        'ION'
		),
		##### Expected results
		bless( {
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_ION_MODE_' => 'NEG',
                                                '_ION_FORM_' => '[M-H]-',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_MZ_' => '59',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_NAME_' => 'Acetic Acid',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_ID_' => 'CON00001',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_PUBCHEM_CID_' => '176',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_EXACT_MASS_' => '60.02113'
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ID_' => 'CON00001',
                                                  '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '59.0138536',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_SPECTRA_ID_' => undef,
                                                  '_ANNOTATION_INCHIKEY_' => undef,
                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => '[M-H]-',
                                                  '_RELATIVE_INTENSITY_999_' => undef,
                                                  '_ANNOTATION_SMILES_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_INTENSITY_' => undef,
                                                  '_ANNOTATIONS_' => [],
                                                  '_CLUSTER_ID_' => undef,
                                                  '_RELATIVE_INTENSITY_100_' => undef
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_ENTRIES_' => [],
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
               }, 'Metabolomics::Banks::MaConDa' ),
		## MSG
		'Method \'buildTheoPeakBankFromContaminants\' works with Bank and Contaminants objects and \'ION\' mode');
		
## #################################################################################################################################
##
#########################	######################### KNAPSACK TESTS #########################  #########################
##
####################################################################################################################################

#########################		
	print "\n** Test $current_test initKnapSackBankObject **\n" ; $current_test++;
	is_deeply( init_KnapSackBankObject_TEST(),
		bless( {
                 '_DATABASE_NAME_' => 'Knapsack',
                 '_DATABASE_DOI_' => '10.1093/pcp/pct176',
                 '_DATABASE_ENTRIES_NB_' => 51187,
                 '_DATABASE_VERSION_' => '1.1',
                 '_DATABASE_URL_' => 'http://www.knapsackfamily.com/KNApSAcK_Family/',
                 '_DATABASE_URL_CARD_' => 'http://www.knapsackfamily.com/knapsack_core/information.php?word=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_THEO_PEAK_LIST_' => [],
                 '_EXP_PEAK_LIST_' => [],
               }, 'Metabolomics::Banks::Knapsack' ) ,
		'Method \'initKnapSackBankObject\' init a well formatted bank object'
	) ;
	
	
#########################	

	print "\n** Test $current_test getMetaboliteFromSource **\n" ; $current_test++;
	is_deeply( getKnapSackFromSourceTest(
			$modulePath.'/Knapsack__dump.csv'),
			45, ## Nb of entries
			'Method \'getMetabolitesFromSource\' works with KnapSack db as a well formatted source file');
		
#########################	
	print "\n** Test $current_test buildTheoPeakBankKnapSack **\n" ; $current_test++;
	is_deeply( buildTheoPeakBankFromKSTest(
		# oBank
		bless( {
                 '_DATABASE_ENTRIES_' => [
                                           bless( {
                                                    '_CAS_' => '545-97-1',
                                                    '_INCHIKEY_' => 'JLJLRLWOEMWYQK-BKYUDGNBNA-N',
                                                    '_KNAPSACK_ID_' => 'C00000001',
                                                    '_COMPOUND_NAME_' => 'Gibberellin A1,GA1',
                                                    '_MOLECULAR_FORMULA_' => 'C19H24O6',
                                                    '_EXACT_MASS_' => '348.1572885'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '63959-45-5',
                                                    '_INCHIKEY_' => 'QYOJSKGCWNAKGW-BIWBQAJPNA-N',
                                                    '_KNAPSACK_ID_' => 'C00000002',
                                                    '_COMPOUND_NAME_' => 'Shikimic acid 3-phosphate,S3P',
                                                    '_EXACT_MASS_' => '254.01915382',
                                                    '_MOLECULAR_FORMULA_' => 'C7H11O8P'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C25H32O9',
                                                    '_EXACT_MASS_' => '476.20463262',
                                                    '_CAS_' => '65256-31-7',
                                                    '_COMPOUND_NAME_' => 'Aurovertin D,(-)-Aurovertin D',
                                                    '_INCHIKEY_' => 'UKPVUEBWITXZRF-YELUXDJBNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038536'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '146345-73-5',
                                                    '_COMPOUND_NAME_' => 'Bastadin 14',
                                                    '_INCHIKEY_' => 'HXWATZFIMWEHEG-YUALJMAISA-N',
                                                    '_KNAPSACK_ID_' => 'C00038582',
                                                    '_EXACT_MASS_' => '1011.75892831',
                                                    '_MOLECULAR_FORMULA_' => 'C34H25Br5N4O8'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_COMPOUND_NAME_' => 'Bastadin 21',
                                                    '_CAS_' => '437762-27-1',
                                                    '_INCHIKEY_' => 'TUYUXKVFCXANLL-QHTJZBTGSA-N',
                                                    '_KNAPSACK_ID_' => 'C00038583',
                                                    '_MOLECULAR_FORMULA_' => 'C34H29Br3N4O8',
                                                    '_EXACT_MASS_' => '857.95355263'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '1107.68000586',
                                                    '_MOLECULAR_FORMULA_' => 'C34H26Br6N4O9',
                                                    '_CAS_' => '1016170-12-9',
                                                    '_KNAPSACK_ID_' => 'C00038584',
                                                    '_INCHIKEY_' => 'MHAGECXZXFMEGD-OJYBBUQINA-N',
                                                    '_COMPOUND_NAME_' => 'Bastadin 24,(-)-Bastadin 24'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '1019854-19-3',
                                                    '_KNAPSACK_ID_' => 'C00038585',
                                                    '_INCHIKEY_' => 'XUYBKWQPNPBFTE-UVWHYCHGNA-N',
                                                    '_COMPOUND_NAME_' => 'Berkeleyamide A,(-)-Berkeleyamide A',
                                                    '_MOLECULAR_FORMULA_' => 'C18H25NO3',
                                                    '_EXACT_MASS_' => '303.18344367'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '371.13688741',
                                                    '_MOLECULAR_FORMULA_' => 'C20H21NO6',
                                                    '_INCHIKEY_' => 'TYALAHHUSALVLR-UHFFFAOYNA-N',
                                                    '_CAS_' => '1019854-22-8',
                                                    '_KNAPSACK_ID_' => 'C00038586',
                                                    '_COMPOUND_NAME_' => 'Berkeleyamide B,(+)-Berkeleyamide B'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '1019854-23-9',
                                                    '_INCHIKEY_' => 'QLDSNWFOEOVFHQ-UHFFFAOYNA-N',
                                                    '_COMPOUND_NAME_' => 'Berkeleyamide C,(+)-Berkeleyamide C',
                                                    '_KNAPSACK_ID_' => 'C00038587',
                                                    '_EXACT_MASS_' => '414.17908658',
                                                    '_MOLECULAR_FORMULA_' => 'C22H26N2O6'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '1019854-25-1',
                                                    '_INCHIKEY_' => 'XIINWDLLZRIJAK-UHFFFAOYNA-N',
                                                    '_COMPOUND_NAME_' => 'Berkeleyamide D,(-)-Berkeleyamide D',
                                                    '_KNAPSACK_ID_' => 'C00038588',
                                                    '_MOLECULAR_FORMULA_' => 'C18H21NO5',
                                                    '_EXACT_MASS_' => '331.14197279'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C7H15NO4',
                                                    '_EXACT_MASS_' => '177.10010798',
                                                    '_CAS_' => '125711-55-9',
                                                    '_INCHIKEY_' => 'ZEWFPWKROPWRKE-QIJQUKAINA-N',
                                                    '_COMPOUND_NAME_' => 'beta-L-Homofuconojirimycin',
                                                    '_KNAPSACK_ID_' => 'C00038589'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '956.46169474',
                                                    '_MOLECULAR_FORMULA_' => 'C47H72O20',
                                                    '_CAS_' => '168111-48-6',
                                                    '_KNAPSACK_ID_' => 'C00038590',
                                                    '_INCHIKEY_' => 'GNCYMXULNXKROG-YRMWMADHNA-N',
                                                    '_COMPOUND_NAME_' => 'Betavulgaroside III'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '168111-49-7',
                                                    '_INCHIKEY_' => 'VYVPIFXAYNIMKK-BJVKLRLMNA-N',
                                                    '_COMPOUND_NAME_' => 'Betavulgaroside V,(+)-Betavulgaroside V',
                                                    '_KNAPSACK_ID_' => 'C00038591',
                                                    '_EXACT_MASS_' => '1118.51451817',
                                                    '_MOLECULAR_FORMULA_' => 'C53H82O25'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_INCHIKEY_' => 'HDASKGQSKPVDTC-XHBZCXTENA-N',
                                                    '_CAS_' => '181301-33-7',
                                                    '_COMPOUND_NAME_' => 'Betonyoside F,(-)-Betonyoside F',
                                                    '_KNAPSACK_ID_' => 'C00038592',
                                                    '_EXACT_MASS_' => '756.24767923',
                                                    '_MOLECULAR_FORMULA_' => 'C34H44O19'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '584.19473664',
                                                    '_MOLECULAR_FORMULA_' => 'C36H28N2O6',
                                                    '_CAS_' => '113425-61-9',
                                                    '_INCHIKEY_' => 'ORORFDPGSXPOAI-UHFFFAOYSA-N',
                                                    '_COMPOUND_NAME_' => 'Bidebiline E',
                                                    '_KNAPSACK_ID_' => 'C00038593'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C23H24O10',
                                                    '_EXACT_MASS_' => '460.13694699',
                                                    '_CAS_' => '99552-25-7',
                                                    '_INCHIKEY_' => 'AMXQRHQMVKOSQE-ZNSZPHFHNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038594',
                                                    '_COMPOUND_NAME_' => 'Bipinnatin E'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C23H26O9',
                                                    '_EXACT_MASS_' => '446.15768243',
                                                    '_INCHIKEY_' => 'GXPJROHGAPZOAA-HIUAZFPXNA-N',
                                                    '_CAS_' => '1020661-83-9',
                                                    '_KNAPSACK_ID_' => 'C00038595',
                                                    '_COMPOUND_NAME_' => 'Bipinnatin K,(-)-Bipinnatin K'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '1020661-84-0',
                                                    '_KNAPSACK_ID_' => 'C00038596',
                                                    '_INCHIKEY_' => 'KQNTYLDBCDIZDP-YRHBYULONA-N',
                                                    '_COMPOUND_NAME_' => 'Bipinnatin L,(+)-Bipinnatin L',
                                                    '_EXACT_MASS_' => '538.16864105',
                                                    '_MOLECULAR_FORMULA_' => 'C25H30O13'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C25H30O12',
                                                    '_EXACT_MASS_' => '522.17372642',
                                                    '_INCHIKEY_' => 'XXCSCQVYTNDURK-VYZIPOFDNA-N',
                                                    '_CAS_' => '1020661-85-1',
                                                    '_KNAPSACK_ID_' => 'C00038597',
                                                    '_COMPOUND_NAME_' => 'Bipinnatin M,(+)-Bipinnatin M'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C20H24O6',
                                                    '_EXACT_MASS_' => '360.1572885',
                                                    '_INCHIKEY_' => 'SMFDDGNKJZPWQS-UHFFFAOYNA-N',
                                                    '_CAS_' => '1020661-91-9',
                                                    '_KNAPSACK_ID_' => 'C00038598',
                                                    '_COMPOUND_NAME_' => 'Bipinnatin N'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C23H26O10',
                                                    '_EXACT_MASS_' => '462.15259705',
                                                    '_COMPOUND_NAME_' => 'Bipinnatin O,(+)-Bipinnatin O',
                                                    '_CAS_' => '1020661-93-1',
                                                    '_INCHIKEY_' => 'ZBWYJRQHHPDMIG-DNSXWDLYNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038599'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '1020661-86-2',
                                                    '_INCHIKEY_' => 'RNDAYVNSDZTQEQ-QQYWDQJINA-N',
                                                    '_COMPOUND_NAME_' => 'Bipinnatin P,(+)-Bipinnatin P',
                                                    '_KNAPSACK_ID_' => 'C00038600',
                                                    '_MOLECULAR_FORMULA_' => 'C25H28O11',
                                                    '_EXACT_MASS_' => '504.16316174'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C23H26O11',
                                                    '_EXACT_MASS_' => '478.14751167',
                                                    '_INCHIKEY_' => 'KSXUAYYEMGKRGW-CGBYMSTNNA-N',
                                                    '_CAS_' => '1020661-88-4',
                                                    '_COMPOUND_NAME_' => 'Bipinnatin Q,(+)-Bipinnatin Q',
                                                    '_KNAPSACK_ID_' => 'C00038601'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_INCHIKEY_' => 'SJBBGMVJNAOUOI-VLURGLOZSA-N',
                                                    '_CAS_' => '1065546-02-2',
                                                    '_COMPOUND_NAME_' => 'Bipinnatone A',
                                                    '_KNAPSACK_ID_' => 'C00038602',
                                                    '_MOLECULAR_FORMULA_' => 'C30H38O5',
                                                    '_EXACT_MASS_' => '478.27192432'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C25H30O5',
                                                    '_EXACT_MASS_' => '410.20932407',
                                                    '_INCHIKEY_' => 'NJIYMLLTXNGJHV-REZTVBANSA-N',
                                                    '_CAS_' => '1065546-06-6',
                                                    '_KNAPSACK_ID_' => 'C00038603',
                                                    '_COMPOUND_NAME_' => 'Bipinnatone B'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_INCHIKEY_' => 'PGWUCFFEOUVLTN-UHFFFAOYSA-N',
                                                    '_CAS_' => '52897-70-8',
                                                    '_COMPOUND_NAME_' => 'Bis(2,3,6-tribromo-4,5-dihydroxybenzyl) ether',
                                                    '_KNAPSACK_ID_' => 'C00038604',
                                                    '_EXACT_MASS_' => '589.89746296',
                                                    '_MOLECULAR_FORMULA_' => 'C16H29Br3O3Si3'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_COMPOUND_NAME_' => 'Bisaprasin',
                                                    '_CAS_' => '112514-43-9',
                                                    '_INCHIKEY_' => 'VVFUCWCIWIOTJW-QEYYFATHSA-N',
                                                    '_KNAPSACK_ID_' => 'C00038605',
                                                    '_MOLECULAR_FORMULA_' => 'C44H46Br4N8O12S4',
                                                    '_EXACT_MASS_' => '1321.88515351'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_INCHIKEY_' => 'CUPRGZVKNKNTTN-IMZWYYTHNA-N',
                                                    '_CAS_' => '244247-14-1',
                                                    '_COMPOUND_NAME_' => 'Bisezakyne A,(-)-Bisezakyne A',
                                                    '_KNAPSACK_ID_' => 'C00038606',
                                                    '_EXACT_MASS_' => '330.03860587',
                                                    '_MOLECULAR_FORMULA_' => 'C15H20BrClO'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '424.02076292',
                                                    '_MOLECULAR_FORMULA_' => 'C17H23BrCl2O3',
                                                    '_CAS_' => '244247-15-2',
                                                    '_INCHIKEY_' => 'WLCJKJLAQCETBJ-NWVDLYHONA-N',
                                                    '_COMPOUND_NAME_' => 'Bisezakyne B,(-)-Bisezakyne B',
                                                    '_KNAPSACK_ID_' => 'C00038607'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '428.29265977',
                                                    '_MOLECULAR_FORMULA_' => 'C27H40O4',
                                                    '_COMPOUND_NAME_' => 'Bisgravillol',
                                                    '_CAS_' => '932033-22-2',
                                                    '_INCHIKEY_' => 'HACJVLBLYFAKNF-UHFFFAOYSA-N',
                                                    '_KNAPSACK_ID_' => 'C00038608'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C20H20O6',
                                                    '_EXACT_MASS_' => '356.12598837',
                                                    '_CAS_' => '260969-76-4',
                                                    '_INCHIKEY_' => 'RSPDYFDYHDJBLU-OMQMIFNENA-N',
                                                    '_KNAPSACK_ID_' => 'C00038609',
                                                    '_COMPOUND_NAME_' => 'Blepharolide A,(-)-Blepharolide A'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_COMPOUND_NAME_' => 'Blepharolide B,(-)-Blepharolide B',
                                                    '_CAS_' => '260969-77-5',
                                                    '_INCHIKEY_' => 'VXXMAEFQGRAWNP-KSGRVOAUNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038610',
                                                    '_EXACT_MASS_' => '340.13107375',
                                                    '_MOLECULAR_FORMULA_' => 'C20H20O5'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C32H52O2',
                                                    '_EXACT_MASS_' => '468.39673089999997',
                                                    '_COMPOUND_NAME_' => 'Boehmerol acetate',
                                                    '_CAS_' => '123409-83-6',
                                                    '_INCHIKEY_' => 'LVDIOSHGTKUVMX-VGHIVREWNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038611'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_KNAPSACK_ID_' => 'C00038612',
                                                    '_CAS_' => '960233-06-1',
                                                    '_INCHIKEY_' => 'SPNFRQDQOJKTSQ-ZNZUWQLQNA-N',
                                                    '_COMPOUND_NAME_' => 'Boivinide A',
                                                    '_MOLECULAR_FORMULA_' => 'C36H54O14',
                                                    '_EXACT_MASS_' => '710.35135643'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_INCHIKEY_' => 'CSVNMGCNZRUZHN-LHNIQKSDNA-N',
                                                    '_CAS_' => '960233-12-9',
                                                    '_COMPOUND_NAME_' => 'Boivinide B',
                                                    '_KNAPSACK_ID_' => 'C00038613',
                                                    '_EXACT_MASS_' => '694.35644181',
                                                    '_MOLECULAR_FORMULA_' => 'C36H54O13'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '680.37717725',
                                                    '_MOLECULAR_FORMULA_' => 'C36H56O12',
                                                    '_CAS_' => '960233-19-6',
                                                    '_COMPOUND_NAME_' => 'Boivinide C',
                                                    '_INCHIKEY_' => 'BPGWSHOXZQEBEG-PVEWUKRWNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038614'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '680.34079175',
                                                    '_MOLECULAR_FORMULA_' => 'C35H52O13',
                                                    '_CAS_' => '960233-26-5',
                                                    '_COMPOUND_NAME_' => 'Boivinide D',
                                                    '_INCHIKEY_' => 'DNLXAKKKWMFLON-QMMKOHGYNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038615'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '696.33570637',
                                                    '_MOLECULAR_FORMULA_' => 'C35H52O14',
                                                    '_COMPOUND_NAME_' => 'Boivinide E',
                                                    '_CAS_' => '960233-32-3',
                                                    '_INCHIKEY_' => 'ZVWJQICTCWWGNW-MNGQFYAGNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038616'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '752.36192112',
                                                    '_MOLECULAR_FORMULA_' => 'C38H56O15',
                                                    '_COMPOUND_NAME_' => 'Boivinide F',
                                                    '_CAS_' => '960233-36-7',
                                                    '_INCHIKEY_' => 'PFTYEQWDSBMMNY-RFNQMGJHNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038617'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_KNAPSACK_ID_' => 'C00038618',
                                                    '_CAS_' => '955999-16-3',
                                                    '_INCHIKEY_' => 'ZYLJCUKCYXHXHV-BBUVWLLZNA-N',
                                                    '_COMPOUND_NAME_' => 'Bonducellpin E,(+)-Bonducellpin E',
                                                    '_MOLECULAR_FORMULA_' => 'C23H30O8',
                                                    '_EXACT_MASS_' => '434.19406794'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_MOLECULAR_FORMULA_' => 'C22H28O6',
                                                    '_EXACT_MASS_' => '388.18858863',
                                                    '_CAS_' => '955999-17-4',
                                                    '_COMPOUND_NAME_' => 'Bonducellpin F,(+)-Bonducellpin F',
                                                    '_INCHIKEY_' => 'XKTJWVAVUXZAPA-MCDREQFLNA-N',
                                                    '_KNAPSACK_ID_' => 'C00038619'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_CAS_' => '955999-18-5',
                                                    '_INCHIKEY_' => 'IHXOABPCUNFFPZ-IHYGVPAINA-N',
                                                    '_COMPOUND_NAME_' => 'Bonducellpin G,(+)-Bonducellpin G',
                                                    '_KNAPSACK_ID_' => 'C00038620',
                                                    '_EXACT_MASS_' => '432.21480338',
                                                    '_MOLECULAR_FORMULA_' => 'C24H32O7'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '214.08412356',
                                                    '_MOLECULAR_FORMULA_' => 'C10H14O5',
                                                    '_CAS_' => '1005344-34-2',
                                                    '_KNAPSACK_ID_' => 'C00038621',
                                                    '_INCHIKEY_' => 'BVFFUSVHPGHUFQ-ONCWJTSGNA-N',
                                                    '_COMPOUND_NAME_' => 'Botryolide A,(-)-Botryolide A'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_INCHIKEY_' => '',
                                                    '_CAS_' => '',
                                                    '_COMPOUND_NAME_' => 'Nororientaline',
                                                    '_KNAPSACK_ID_' => 'C00052018',
                                                    '_EXACT_MASS_' => '315.14705817',
                                                    '_MOLECULAR_FORMULA_' => 'C18H21NO4'
                                                  }, 'Metabolomics::Banks::Knapsack' ),
                                           bless( {
                                                    '_KNAPSACK_ID_' => 'C00052019',
                                                    '_CAS_' => '',
                                                    '_INCHIKEY_' => '',
                                                    '_COMPOUND_NAME_' => 'Notoamide E',
                                                    '_EXACT_MASS_' => '433.23654188',
                                                    '_MOLECULAR_FORMULA_' => 'C26H31N3O3'
                                                  }, 'Metabolomics::Banks::Knapsack' )
                                         ],
                 '_DATABASE_ENTRIES_NB_' => 51187,
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_URL_' => 'http://www.knapsackfamily.com/KNApSAcK_Family/',
                 '_DATABASE_URL_CARD_' => 'http://www.knapsackfamily.com/knapsack_core/information.php?word=',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_VERSION_' => '1.1',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_DOI_' => '10.1093/pcp/pct176',
                 '_DATABASE_NAME_' => 'Knapsack',
                 '_THEO_PEAK_LIST_' => []
               }, 'Metabolomics::Banks::Knapsack' ),
        # query mode
        'POSITIVE'
		),
		##### Expected results
		45,
		## MSG
		'Method \'buildTheoPeakBankFromContaminants\' works with Bank and Contaminants objects and \'ION\' mode');		


## #################################################################################################################################
##
#########################	######################### PhytoHUB TESTS #########################  #########################
##
####################################################################################################################################

#########################
	print "\n** Test $current_test initPhytoHubBankObject **\n" ; $current_test++;
	is_deeply( initPhytoHubBankObject_TEST(),
		bless( {
                 '_DATABASE_VERSION_' => '1.4_Beta',
                 '_DATABASE_ENTRIES_NB_' => 1757,
                 '_DATABASE_URL_' => 'http://phytohub.eu/',
                 '_DATABASE_URL_CARD_' => 'https://phytohub.eu/entries/',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_DOI_' => 'NA',
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_NAME_' => 'PhytoHub',
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_EXP_PEAK_LIST_' => []
               }, 'Metabolomics::Banks::PhytoHub'  ) ,
		'Method \'initPhytoHubBankObject\' init a well formatted bank object'
	) ;

#########################	

	print "\n** Test $current_test getPhytoHubFromSource **\n" ; $current_test++;
	is_deeply( getPhytoHubFromSource_Test(
			$modulePath.'/PhytoHUB__dump.tsv'),
			7, ## Nb of entries
			'Method \'getPhytoHubFromSource\' works with PhytoHub db as a well formatted source file');

#########################	
	print "\n** Test $current_test buildTheoPeakBankFromPhytoHub **\n" ; $current_test++;
	is_deeply( buildTheoPeakBankFromPhytoHubTest(
		# oBank
		bless( {
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_ENTRIES_NB_' => 1757,
                 '_DATABASE_URL_' => 'http://phytohub.eu/',
                 '_DATABASE_URL_CARD_' => 'https://phytohub.eu/entries/',
                 '_POLARITY_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_SPECTRA_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_DOI_' => 'NA',
                 '_DATABASE_NAME_' => 'PhytoHub',
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_DATABASE_VERSION_' => '1.4_Beta',
                 '_DATABASE_ENTRIES_' => [
                                           bless( {
                                                    '_INCHIKEY_' => 'BDVVNPOGDNWUOI-VVHJISIGSA-N',
                                                    '_IS_A_PRECURSOR_' => '1',
                                                    '_MOLECULAR_FORMULA_' => 'C21H30O3',
                                                    '_IS_A_METABOLITE_' => '0',
                                                    '_COMPOUND_NAME_' => '16-O-Methylcafestol',
                                                    '_SMILES_' => 'CO[C@]1(CO)C[C@]23C[C@@H]1CC[C@H]2[C@]1(C)CCC2=C(C=CO2)[C@H]1CC3',
                                                    '_EXACT_MASS_' => '330.2194948260',
                                                    '_PHYTOHUB_ID_' => 'PHUB000001'
                                                  }, 'Metabolomics::Banks::PhytoHub' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '728.3619211030',
                                                    '_MOLECULAR_FORMULA_' => 'C36H56O15',
                                                    '_IS_A_PRECURSOR_' => '1',
                                                    '_INCHIKEY_' => 'DOYDQNQLCHBFDK-KSEREDHQSA-N',
                                                    '_COMPOUND_NAME_' => '3\'-O-beta-D-glucopyranosyl-2\'-O-isovaleryl-2beta-(2-desoxy-atractyligenin)-beta-D-glucopyranoside',
                                                    '_SMILES_' => '[H][C@]12C[C@@]3(CC[C@]4([H])[C@@H](C[C@H](C[C@@]4(C)[C@]3([H])CC1)OC1O[C@H](CO)[C@@H](O)[C@H](O[C@@H]3O[C@H](CO)[C@@H](O)[C@H](O)[C@H]3O)[C@H]1OC(=O)CC(C)C)C(O)=O)[C@@H](O)C2=C',
                                                    '_IS_A_METABOLITE_' => '0',
                                                    '_PHYTOHUB_ID_' => 'PHUB000002'
                                                  }, 'Metabolomics::Banks::PhytoHub' ),
                                           bless( {
                                                    '_PHYTOHUB_ID_' => 'PHUB000003',
                                                    '_COMPOUND_NAME_' => 'Atractyligenin',
                                                    '_SMILES_' => '[H][C@]12C[C@@]3(CC[C@]4([H])[C@@H](C[C@@H](O)C[C@@]4(C)[C@]3([H])CC1)C(O)=O)[C@@H](O)C2=C',
                                                    '_IS_A_METABOLITE_' => '0',
                                                    '_MOLECULAR_FORMULA_' => 'C19H28O4',
                                                    '_INCHIKEY_' => 'YRHWUYVCCPXYMB-JIMOHSCASA-N',
                                                    '_IS_A_PRECURSOR_' => '1',
                                                    '_EXACT_MASS_' => '320.1987593820'
                                                  }, 'Metabolomics::Banks::PhytoHub' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '480.2723182480',
                                                    '_IS_A_PRECURSOR_' => '1',
                                                    '_INCHIKEY_' => 'YEAZCNLETNYACR-DRBRKHBCSA-N',
                                                    '_MOLECULAR_FORMULA_' => 'C26H40O8',
                                                    '_IS_A_METABOLITE_' => '0',
                                                    '_SMILES_' => '[H][C@]12C[C@@]3(CC[C@]4([H])[C@@H](C[C@H](C[C@@]4(C)[C@]3([H])CC1)OC1O[C@H](CO)[C@@H](O)[C@H](C)[C@H]1O)C(O)=O)[C@@H](O)C2=C',
                                                    '_COMPOUND_NAME_' => 'Atractyligenin (2-O-beta-glucopyranosyl-)',
                                                    '_PHYTOHUB_ID_' => 'PHUB000004'
                                                  }, 'Metabolomics::Banks::PhytoHub' ),
                                           bless( {
                                                    '_EXACT_MASS_' => '724.2081748450',
                                                    '_INCHIKEY_' => 'FYQXODZRNSCOTR-QLKRWLHJSA-L',
                                                    '_IS_A_PRECURSOR_' => '1',
                                                    '_MOLECULAR_FORMULA_' => 'C30H44O16S2',
                                                    '_IS_A_METABOLITE_' => '0',
                                                    '_COMPOUND_NAME_' => 'Atractyloside',
                                                    '_SMILES_' => '[H][C@]12C[C@@]3(CC[C@]4([H])[C@@H](C[C@H](C[C@@]4(C)[C@]3([H])CC1)O[C@@H]1O[C@H](CO)[C@@H](OS([O-])(=O)=O)[C@H](OS([O-])(=O)=O)[C@H]1OC(=O)CC(C)C)C(O)=O)[C@@H](O)C2=C',
                                                    '_PHYTOHUB_ID_' => 'PHUB000005'
                                                  }, 'Metabolomics::Banks::PhytoHub' ),
                                           bless( {
                                                    '_INCHIKEY_' => 'DNJVYWXIDISQRD-JTSSGKSMSA-N',
                                                    '_IS_A_PRECURSOR_' => '1',
                                                    '_MOLECULAR_FORMULA_' => 'C20H28O3',
                                                    '_IS_A_METABOLITE_' => '0',
                                                    '_COMPOUND_NAME_' => 'Cafestol',
                                                    '_SMILES_' => 'C[C@@]12CCC3=C(C=CO3)[C@H]1CC[C@@]13C[C@H](CC[C@@H]21)[C@@](O)(CO)C3',
                                                    '_EXACT_MASS_' => '316.2038447620',
                                                    '_PHYTOHUB_ID_' => 'PHUB000006'
                                                  }, 'Metabolomics::Banks::PhytoHub' ),
                                           bless( {
                                                    '_PHYTOHUB_ID_' => 'PHUB000007',
                                                    '_EXACT_MASS_' => '768.1980040850',
                                                    '_IS_A_PRECURSOR_' => '1',
                                                    '_INCHIKEY_' => 'NULL',
                                                    '_MOLECULAR_FORMULA_' => 'C31H44O18S2',
                                                    '_IS_A_METABOLITE_' => '0',
                                                    '_SMILES_' => '[H]OC([H])([H])C1([H])OC([H])(OC2([H])C([H])([H])C(C([O-])=O)(C([O-])=O)C3([H])C([H])([H])C([H])([H])[C@@]45C([H])([H])[C@]([H])(C(=C([H])[H])[C@@]4([H])O[H])C([H])([H])C([H])([H])C5([H])[C@@]3(C([H])([H])[H])C2([H])[H])C([H])(OC(=O)C([H])([H])C([H])(C([H])([H])[H])C([H])([H])[H])C([H])(OS(=O)(=O)O[H])C1([H])OS(=O)(=O)O[H]',
                                                    '_COMPOUND_NAME_' => 'Carboxyatractyloside'
                                                  }, 'Metabolomics::Banks::PhytoHub' )
                                         ]
               }, 'Metabolomics::Banks::PhytoHub' ),
		# query mode
        'POSITIVE'
		),
		##### Expected results
		7,
		## MSG
		'Method \'buildTheoPeakBankFromPhytoHub\' works with Bank and Phytohub objects and \'ION\' mode');
		
## #################################################################################################################################
##
#########################	######################### PeakForest TESTS #########################  #########################
##
####################################################################################################################################

#########################
	print "\n** Test $current_test initPeakForestBankObject **\n" ; $current_test++;
	is_deeply( initPeakForestBankObject_TEST(
		'https://metabohub.peakforest.org/rest/',
		'csisvmi83usaf4plnr29biobkb'
		),
		bless( {
                 '_DATABASE_ENTRIES_' => [],
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_SPECTRA_' => undef,
                 '_POLARITY_' => undef,
                 '_RESOLUTION_' => undef,
                 '_DATABASE_VERSION_' => '2.3.2',
                 '_DATABASE_DOI_' => 'NA',
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_TOKEN_' => 'csisvmi83usaf4plnr29biobkb',
                 '_DATABASE_ENTRIES_NB_' => undef,
                 '_DATABASE_NAME_' => 'PeakForest',
                 '_DATABASE_URL_' => 'https://metabohub.peakforest.org/rest/',
                 '_DATABASE_URL_CARD_' => 'https://metabohub.peakforest.org/webapp/home?PFc=',
                 '_POLARITY_' => undef,
                 '_RESOLUTION_' => undef,
                 '_DATABASE_TYPE_' => 'METABOLITE',
               }, 'Metabolomics::Banks::PeakForest' ),
		'Method \'initPeakForestBankObject\' init a well formatted bank object'
	) ;
	
#########################
	print "\n** Test $current_test PeakForest (REST v2) getCompoundFromId -- DEPRECATED **\n" ; $current_test++;
#	is_deeply( getCompoundFromId_TEST(
#		'https://demo.peakforest.org/rest/v2',
#		't41epopfuaqiukluac1ff723hd',
#		1
#		),
#		bless( {
##                 '_BIOACTIVE_' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
#				 '_BIOACTIVE_' => 1,
#                 '_LOG_P_' => -3.43,
#                 '_EXACT_MASS_' => '161.068807837',
#                 '_IUPAC_' => '2-aminohexanedioic acid',
#                 '_FORMULA_' => 'C6H11NO4',
#                 '_SPECTRA_' => ['PFs000012', 'PFs000013', 'PFs000294', 'PFs000295', 'PFs000312', 'PFs000313', 'PFs000314', 'PFs000315'],
#                 '_ID_' => 'PFc000001',
#                 '_INCHIKEY_' => 'OYIFNHCXNCRBQI-UHFFFAOYSA-N',
#                 '_NAME_' => '2-Aminoadipic Acid',
#                 '_SYNONYMS_' => ['(+/-)-2-Aminoadipic acid', 'DL-2-Aminohexanedioic acid', 'DL-alpha-Aminoadipic acid', 'alpha-Aminoadipic acid', 'DL-2-Aminoadipic acid'],
#                 '_CAN_SMILES_' => 'OC(=O)CCCC(C(=O)O)N',
#                 '_AVERAGE_MASS_' => '161.15584',
#                 '_INCHI_' => 'InChI=1S/C6H11NO4/c7-4(6(10)11)2-1-3-5(8)9/h4H,1-3,7H2,(H,8,9)(H,10,11)'
#               }, 'Metabolomics::Banks::PeakForest' ),
#		'Method \'getCompoundFromId\' return a well formatted compound object for id PFc000001'
#	) ;
	
	
#########################
	print "\n** Test $current_test PeakForest (REST v2) getGcmsSpectraMatchingPeaks (One spectrum) - DEPRECATED **\n" ; $current_test++;
#	is_deeply( getGcmsSpectraMatchingPeaks_TEST(
#		'https://metabohub.peakforest.org/rest/v2',
#		'2big17k7a871tfatk1b4cm8pr7',
#		undef, #column_code
#		undef, #polarity
#		undef, #resolution
#		[171.0768, 189.0875], #list_mz
#		0.05, #delta
#		),
#		['PFs008654'],
#		'Method \'getGcmsSpectraMatchingPeaks\' return a well formatted specta object for a specific gcms search'
#	) ;
	


#########################
	print "\n** Test $current_test PeakForest (REST v2) getGcmsSpectraMatchingPeaks (N spectra) -- DEPRECATED **\n" ; $current_test++;
#	is_deeply( getGcmsSpectraMatchingPeaks_TEST(
#		'https://metabohub.peakforest.org/rest/v2',
#		'2big17k7a871tfatk1b4cm8pr7',
#		undef, #column_code
#		undef, #polarity
#		undef, #resolution
#		[73.047], #list_mz
#		0.05, #delta
#		),
#		['PFs008654', 'PFs008655'],
#		'Method \'getGcmsSpectraMatchingPeaks\' return a well formatted specta object for a specific gcms search'
#	) ;
	
#########################
	print "\n** Test $current_test PeakForest (REST v2) getGcmsSpectraFromIds (N spectra) -- DEPRECATED **\n" ; $current_test++;
#	is_deeply( getGcmsSpectraFromIds_TEST(
#		'https://metabohub.peakforest.org/rest/v2',
#		'2big17k7a871tfatk1b4cm8pr7',
#		['PFs008654', 'PFs008655'], #list_ids
#		),
#		2,
#		'Method \'getGcmsSpectraFromIds\' return a list of Two specta object for a specific gcms search'
#	) ;
	
	
#########################
	print "\n** Test $current_test PeakForest (REST v2) buildSpectralBankFromPeakForest (N spectra) -- DEPRECATED **\n" ; $current_test++;
#	is_deeply( buildSpectralBankFromPeakForest_TEST(
#		## ARGT 
#		bless( {
#                 '_DATABASE_URL_' => 'https://metabohub.peakforest.org/rest/v2',
#                 '_DATABASE_URL_CARD_' => 'database_url_card',
#                 '_DATABASE_TYPE_' => 'METABOLITE',
#                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
#                 '_THEO_PEAK_LIST_' => [],
#                 '_DATABASE_NAME_' => 'PeakForest',
#                 '_DATABASE_TOKEN_' => '2big17k7a871tfatk1b4cm8pr7',
#                 '_DATABASE_ENTRIES_NB_' => undef,
#                 '_RESOLUTION_' => 'high',
#                 '_EXP_PEAK_LIST_' => [
#                                        bless( {
#                                        		 '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                 '_ANNOTATION_SMILES_' => undef,
#                                                 '_SPECTRA_ID_' => undef,
#                                                 '_ANNOTATION_INCHIKEY_' => undef,
#                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                 '_ANNOTATION_ONLY_IN_' => undef,
#                                                 '_ANNOTATIONS_' => [],
#                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                 '_RELATIVE_INTENSITY_999_' => undef,
#                                                 '_ID_' => undef,
#                                                 '_ANNOTATION_NAME_' => undef,
#                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                 '_RELATIVE_INTENSITY_100_' => undef,
#                                                 '_MESURED_MONOISOTOPIC_MASS_' => '50.9994825424595',
#                                                 '_PPM_ERROR_' => 0,
#                                                 '_CLUSTER_ID_' => 1,
#                                                 '_MMU_ERROR_' => 0,
#                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                 '_INTENSITY_' => '19932.8992306905',
#                                                 '_ANNOTATION_TYPE_' => undef,
#                                                 '_ANNOTATION_FORMULA_' => undef
#                                               }, 'Metabolomics::Banks' ),
#                                        bless( {
#                                        		'_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                 '_MMU_ERROR_' => 0,
#                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                 '_ANNOTATION_TYPE_' => undef,
#                                                 '_INTENSITY_' => '29711.21202827083',
#                                                 '_ANNOTATION_FORMULA_' => undef,
#                                                 '_ANNOTATION_NAME_' => undef,
#                                                 '_RELATIVE_INTENSITY_100_' => undef,
#                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                 '_MESURED_MONOISOTOPIC_MASS_' => '147.06580000000',
#                                                 '_PPM_ERROR_' => 0,
#                                                 '_CLUSTER_ID_' => 2,
#                                                 '_ANNOTATION_INCHIKEY_' => undef,
#                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                 '_ANNOTATION_ONLY_IN_' => undef,
#                                                 '_ANNOTATIONS_' => [],
#                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                 '_ID_' => undef,
#                                                 '_RELATIVE_INTENSITY_999_' => undef,
#                                                 '_ANNOTATION_SMILES_' => undef,
#                                                 '_SPECTRA_ID_' => undef
#                                               }, 'Metabolomics::Banks' ),
#                                        bless( {
#                                        		 '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                 '_SPECTRA_ID_' => undef,
#                                                 '_ANNOTATION_SMILES_' => undef,
#                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                 '_ID_' => undef,
#                                                 '_RELATIVE_INTENSITY_999_' => undef,
#                                                 '_ANNOTATION_ONLY_IN_' => undef,
#                                                 '_ANNOTATIONS_' => [],
#                                                 '_ANNOTATION_INCHIKEY_' => undef,
#                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                 '_CLUSTER_ID_' => 2,
#                                                 '_PPM_ERROR_' => 0,
#                                                 '_ANNOTATION_NAME_' => undef,
#                                                 '_MESURED_MONOISOTOPIC_MASS_' => '171.0768000000',
#                                                 '_RELATIVE_INTENSITY_100_' => undef,
#                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                 '_ANNOTATION_FORMULA_' => undef,
#                                                 '_ANNOTATION_TYPE_' => undef,
#                                                 '_INTENSITY_' => '17439.745499466',
#                                                 '_MMU_ERROR_' => 0
#                                               }, 'Metabolomics::Banks' )
#										],
#                 '_DATABASE_DOI_' => 'NA',
#                 '_EXP_PSEUDOSPECTRA_LIST_' => {
#                 								'1' => [
#                                                 	bless( {
#                                                 	 '_ANNOTATION_SPECTRAL_IDS_' => [],
#	                                                 '_ANNOTATION_SMILES_' => undef,
#	                                                 '_SPECTRA_ID_' => undef,
#	                                                 '_ANNOTATION_INCHIKEY_' => undef,
#	                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#	                                                 '_ANNOTATION_ONLY_IN_' => undef,
#	                                                 '_ANNOTATIONS_' => [],
#	                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#	                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
#	                                                 '_RELATIVE_INTENSITY_999_' => undef,
#	                                                 '_ID_' => undef,
#	                                                 '_ANNOTATION_NAME_' => undef,
#	                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#	                                                 '_RELATIVE_INTENSITY_100_' => undef,
#	                                                 '_MESURED_MONOISOTOPIC_MASS_' => '50.9994825424595',
#	                                                 '_PPM_ERROR_' => 0,
#	                                                 '_CLUSTER_ID_' => 1,
#	                                                 '_MMU_ERROR_' => 0,
#	                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#	                                                 '_INTENSITY_' => '19932.8992306905',
#	                                                 '_ANNOTATION_TYPE_' => undef,
#	                                                 '_ANNOTATION_FORMULA_' => undef
#	                                               }, 'Metabolomics::Banks' )
#                                                          ],
#                                                '2' => [
#                                                    bless( {
#                                                     '_ANNOTATION_SPECTRAL_IDS_' => [],
#	                                                 '_MMU_ERROR_' => 0,
#	                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#	                                                 '_ANNOTATION_TYPE_' => undef,
#	                                                 '_INTENSITY_' => '29711.21202827083',
#	                                                 '_ANNOTATION_FORMULA_' => undef,
#	                                                 '_ANNOTATION_NAME_' => undef,
#	                                                 '_RELATIVE_INTENSITY_100_' => undef,
#	                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#	                                                 '_MESURED_MONOISOTOPIC_MASS_' => '147.06580000000',
#	                                                 '_PPM_ERROR_' => 0,
#	                                                 '_CLUSTER_ID_' => 2,
#	                                                 '_ANNOTATION_INCHIKEY_' => undef,
#	                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#	                                                 '_ANNOTATION_ONLY_IN_' => undef,
#	                                                 '_ANNOTATIONS_' => [],
#	                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#	                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
#	                                                 '_ID_' => undef,
#	                                                 '_RELATIVE_INTENSITY_999_' => undef,
#	                                                 '_ANNOTATION_SMILES_' => undef,
#	                                                 '_SPECTRA_ID_' => undef
#	                                               		}, 'Metabolomics::Banks' ),
#	                                        		bless( {
#	                                        		 '_ANNOTATION_SPECTRAL_IDS_' => [],
#	                                                 '_SPECTRA_ID_' => undef,
#	                                                 '_ANNOTATION_SMILES_' => undef,
#	                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
#	                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#	                                                 '_ID_' => undef,
#	                                                 '_RELATIVE_INTENSITY_999_' => undef,
#	                                                 '_ANNOTATION_ONLY_IN_' => undef,
#	                                                 '_ANNOTATIONS_' => [],
#	                                                 '_ANNOTATION_INCHIKEY_' => undef,
#	                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#	                                                 '_CLUSTER_ID_' => 2,
#	                                                 '_PPM_ERROR_' => 0,
#	                                                 '_ANNOTATION_NAME_' => undef,
#	                                                 '_MESURED_MONOISOTOPIC_MASS_' => '171.0768000000',
#	                                                 '_RELATIVE_INTENSITY_100_' => undef,
#	                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#	                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#	                                                 '_ANNOTATION_FORMULA_' => undef,
#	                                                 '_ANNOTATION_TYPE_' => undef,
#	                                                 '_INTENSITY_' => '17439.745499466',
#	                                                 '_MMU_ERROR_' => 0
#	                                               }, 'Metabolomics::Banks' )
#                                                  ]
#                                                },
#                 '_DATABASE_SPECTRA_' => undef,
#                 '_DATABASE_ENTRIES_' => [],
#                 '_POLARITY_' => 'POSITIVE',
#                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
#                 '_DATABASE_VERSION_' => '2.3.2',
#               }, 'Metabolomics::Banks::PeakForest' )
#		),
#		## Expected
#		bless( {
#                 '_THEO_PEAK_LIST_' => [
#                                         bless( {
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '51.0226',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '51.0226',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.5',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '58.0235',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '58.0235',
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.74',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.73',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '58.9949',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '58.9949',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '59.0309',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '59.0309',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.31',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '61.0109',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '61.0109',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '1.15',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '72.0386',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '72.0386',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.56',
#                                                  '_RELATIVE_INTENSITY_999_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_RELATIVE_INTENSITY_100_' => 100,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '73.047',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '73.047',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '8.42',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '74.0479',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '74.0479',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '17.74',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '75.0283',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '75.0283',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '76.0277',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '76.0277',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '1.4',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '1.95',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '77.031',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '77.031',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '78.0453',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '78.0453',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.25',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.65',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '89.0401',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '89.0401',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.68',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '90.0452',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '90.0452',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.59',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '91.0535',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '91.0535'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '103.0533',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '103.0533',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.11',
#                                                  '_RELATIVE_INTENSITY_999_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '2.83',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '104.0612',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '104.0612',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.92',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '105.0307',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '105.0307',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.03',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '105.0662',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '105.0662',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '107.0468',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '107.0468',
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.51',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '117.0672',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '117.0672',
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.54',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.64',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '119.0829',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '119.0829',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '131.0362',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '131.0362',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.66',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '133.0215',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '133.0215',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_RELATIVE_INTENSITY_100_' => '1.59',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '135.0316',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '135.0316',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '2.93',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '5.16',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '140.5326',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '140.5326'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '141.0336',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '141.0336',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.25',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '2.45',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '147.0613',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '147.0613',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '148.0458',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '148.0458',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.44',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.76',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '148.5454',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '148.5454',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '6.78',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '149.0276',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '149.0276',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '150.0389',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '150.0389',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.31',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '151.0417',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '151.0417',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_RELATIVE_INTENSITY_100_' => '0.7',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_RELATIVE_INTENSITY_100_' => '2.67',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '161.0414',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '161.0414',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '6.26',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '162.049',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '162.049',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '10.37',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '163.0563',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '163.0563',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '3.43',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '164.0618',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '164.0618',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '165.0565',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '165.0565',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.15',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '177.0694',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '177.0694',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '2.94',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '5.19',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '178.0475',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '178.0475'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '179.0527',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '179.0527',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '53.18',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '8.68',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '180.0547',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '180.0547',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '2.46',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '181.0517',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '181.0517',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '2.19',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '192.0596',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '192.0596',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '193.0669',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '193.0669',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '5.43',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_RELATIVE_INTENSITY_100_' => '1.51',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '194.0696',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '194.0696'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '0.54',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '195.0675',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '195.0675',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '13.96',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '206.0395',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '206.0395',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '207.0721',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '207.0721',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '4.82',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '208.0612',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '208.0612',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.04',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '74.11',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '209.0996',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '209.0996',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '12.66',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '210.1015',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '210.1015',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '211.0984',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '211.0984',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.51',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '221.0614',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '221.0614',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.59',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '236.0826',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '236.0826',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.43',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '16.98',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '237.0763',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '237.0763',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '238.0779',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '238.0779',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.34',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.63',
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '239.0739',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '239.0739',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.94',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '251.0901',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '251.0901',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '15.28',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '252.0996',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '252.0996',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_RELATIVE_INTENSITY_100_' => '3.81',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '253.0987',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '253.0987',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '254.0968',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '254.0968',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.63'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '0.91',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '255.09',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '255.09',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '53.79',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '267.1236',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '267.1236',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '268.1248',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '268.1248',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '13.33',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '269.122',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '269.122',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '4.92',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.83',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '270.1219',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '270.1219'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '278.916',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '278.916',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '0.54',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '282.1464',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '282.1464',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '8.4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '283.1456',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '283.1456',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '2.2',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.77',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '284.1445',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '284.1445',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.52',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '291.9319',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '291.9319',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.91',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '293.9343',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '293.9343',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '296.0901',
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '296.0901',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '39.25',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '297.0925',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '297.0925',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '9.63',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.73',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '298.0895',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '298.0895',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '299.0913',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '299.0913',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.64',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_RELATIVE_INTENSITY_100_' => '1.45',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '306.9547',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '306.9547',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '2.4',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '308.9579',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '308.9579',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_RELATIVE_INTENSITY_100_' => '67.98',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '311.1138',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '311.1138',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '312.1154',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '312.1154',
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '17.24',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '313.1125',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '313.1125',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '6.54',
#                                                  '_RELATIVE_INTENSITY_999_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.14',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '314.1131',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '314.1131',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '326.1374',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '326.1374',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_RELATIVE_INTENSITY_100_' => '76.94',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '327.139',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '327.139',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '20.62',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '328.1364',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '328.1364',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '7.95',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'COc1cc(ccc1O)CC(=O)O',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '329.1364',
#                                                  '_ANNOTATION_INCHIKEY_' => 'QRMZSPFSDQBLIX-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008655',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000244',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '329.1364',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.44',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'hva - homovanillic acid',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'C9H10O4',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '52.0063',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '52.0063',
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.39',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.54',
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '52.0295',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '52.0295',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.6',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '55.9959',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '55.9959',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.69',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '57.014',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '57.014',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '58.0146',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '58.0146',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.94',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.54',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '59.0301',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '59.0301',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.03',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '60.026',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '60.026'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.16',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '61.0109',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '61.0109',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '2.08',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '64.0108',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '64.0108',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.75',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '65.0025',
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '65.0025',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '66.0207',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '66.0207',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.95',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.65',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '66.5204',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '66.5204'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '68.9926',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '68.9926',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_RELATIVE_INTENSITY_100_' => '3.2',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '6.01',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '69.9742',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '69.9742'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.44',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '71.0062',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '71.0062',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '10.34',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '71.9899',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '71.9899',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.67',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '72.9909',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '72.9909',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '73.0465',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '73.0465',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '24.85',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '74.0423',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '74.0423',
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '34.17',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '75.0266',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '75.0266',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '31.33',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '76.0302',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '76.0302',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '3.03',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.82',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '77.0223',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '77.0223',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.71',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '78.0311',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '78.0311',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.83',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '79.0348',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '79.0348',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.16',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '84.0261',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '84.0261',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '85.0224',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '85.0224',
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.68',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '86.0052',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '86.0052',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.78',
#                                                  '_RELATIVE_INTENSITY_999_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '87.031',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '87.031',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.39',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '89.041',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '89.041',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.62',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '26.11',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '99.037',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '99.037',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '100.0217',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.0217',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '42.99',
#                                                  '_RELATIVE_INTENSITY_999_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.0703',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '100.0703',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_RELATIVE_INTENSITY_100_' => '0.96',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '101.024',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '101.024',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '4.41',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '102.0183',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '102.0183',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.78',
#                                                  '_RELATIVE_INTENSITY_999_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '113.0242',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '113.0242',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.8',
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '114.0204',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '114.0204',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.53',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '115.0041',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '115.0041',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.37',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '11.09',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '117.0476',
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '117.0476',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '118.0487',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.0487',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.02',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.72',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '119.0455',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '119.0455',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '130.0499',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '130.0499',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '6.18',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '4.53',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '131.0369',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '131.0369'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.41',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '131.0851',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '131.0851',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.41',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '132.0329',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '132.0329',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '133.0412',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '133.0412',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.88',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '135.0603',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '135.0603',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.58',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '5.66',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '146.081',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '146.081',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => 100,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '147.0658',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '147.0658',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '148.0666',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '148.0666',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '15.61',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '149.0621',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '149.0621',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '7.94',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '150.0622',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '150.0622',
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.8',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '1.1',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '155.0459',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '155.0459',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '157.0293',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '157.0293',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.94',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '52.6',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '171.0768',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '171.0768',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '172.0775',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '172.0775',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '9.12',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '8.88',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '173.0645',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '173.0645'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.96',
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '174.0608',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '174.0608',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '175.0558',
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '175.0558',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.56',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '179.052',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '179.052',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '0.87',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => []
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '189.0875',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_ID_' => 'PFc000341',
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '189.0875',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_RELATIVE_INTENSITY_100_' => '50.66',
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea'
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_PPM_ERROR_' => 0,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '190.0881',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '190.0881',
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '8.63',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_INTENSITY_' => undef
#                                                }, 'Metabolomics::Banks' ),
#                                         bless( {
#                                                  '_INTENSITY_' => undef,
#                                                  '_ANNOTATION_FORMULA_' => 'CH4N2O',
#                                                  '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                  '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                  '_RELATIVE_INTENSITY_100_' => '3.94',
#                                                  '_RELATIVE_INTENSITY_999_' => undef,
#                                                  '_ANNOTATIONS_' => [],
#                                                  '_ANNOTATION_NAME_' => 'Urea',
#                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                  '_MESURED_MONOISOTOPIC_MASS_' => '191.085',
#                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                  '_ANNOTATION_TYPE_' => 'fragment',
#                                                  '_SPECTRA_ID_' => 'PFs008654',
#                                                  '_ANNOTATION_ONLY_IN_' => undef,
#                                                  '_MMU_ERROR_' => 0,
#                                                  '_ID_' => 'PFc000341',
#                                                  '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '191.085',
#                                                  '_ANNOTATION_INCHIKEY_' => 'XSQUKJJJFZCRTK-UHFFFAOYSA-N',
#                                                  '_ANNOTATION_SMILES_' => 'NC(=O)N',
#                                                  '_CLUSTER_ID_' => undef,
#                                                  '_PPM_ERROR_' => 0
#                                                }, 'Metabolomics::Banks' )
#                                       ],
#                 '_DATABASE_ENTRIES_' => [],
#                 '_DATABASE_VERSION_' => '2.3.2',
#                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {
#                                                       '1' => [
#                                                                'PFs008655'
#                                                              ],
#                                                       '2' => [
#                                                                'PFs008654',
#                                                                'PFs008655'
#                                                              ]
#                                                     },
#                 '_EXP_PEAK_LIST_' => [
#                                        bless( {
#                                                 '_MESURED_MONOISOTOPIC_MASS_' => '50.9994825424595',
#                                                 '_ANNOTATION_INCHIKEY_' => undef,
#                                                 '_ANNOTATION_FORMULA_' => undef,
#                                                 '_ANNOTATION_NAME_' => undef,
#                                                 '_MMU_ERROR_' => 0,
#                                                 '_ID_' => undef,
#                                                 '_ANNOTATIONS_' => [],
#                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                 '_ANNOTATION_TYPE_' => undef,
#                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                 '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                 '_RELATIVE_INTENSITY_100_' => '100.00',
#                                                 '_RELATIVE_INTENSITY_999_' => undef,
#                                                 '_ANNOTATION_SMILES_' => undef,
#                                                 '_CLUSTER_ID_' => 1,
#                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                 '_ANNOTATION_ONLY_IN_' => undef,
#                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                 '_PPM_ERROR_' => 0,
#                                                 '_INTENSITY_' => '19932.8992306905',
#                                                 '_SPECTRA_ID_' => undef,
#                                                 '_ANNOTATION_IN_NEG_MODE_' => undef
#                                               }, 'Metabolomics::Banks' ),
#                                        bless( {
#                                                 '_ANNOTATIONS_' => [],
#                                                 '_ID_' => undef,
#                                                 '_MMU_ERROR_' => 0,
#                                                 '_ANNOTATION_NAME_' => undef,
#                                                 '_ANNOTATION_FORMULA_' => undef,
#                                                 '_ANNOTATION_INCHIKEY_' => undef,
#                                                 '_MESURED_MONOISOTOPIC_MASS_' => '147.06580000000',
#                                                 '_ANNOTATION_SMILES_' => undef,
#                                                 '_RELATIVE_INTENSITY_999_' => undef,
#                                                 '_RELATIVE_INTENSITY_100_' => '100.00',
#                                                 '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                 '_ANNOTATION_TYPE_' => undef,
#                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                 '_PPM_ERROR_' => 0,
#                                                 '_INTENSITY_' => '29711.21202827083',
#                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                 '_ANNOTATION_ONLY_IN_' => undef,
#                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                 '_CLUSTER_ID_' => 2,
#                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                 '_SPECTRA_ID_' => undef
#                                               }, 'Metabolomics::Banks' ),
#                                        bless( {
#                                                 '_ANNOTATION_FORMULA_' => undef,
#                                                 '_ANNOTATION_NAME_' => undef,
#                                                 '_ANNOTATION_INCHIKEY_' => undef,
#                                                 '_MESURED_MONOISOTOPIC_MASS_' => '171.0768000000',
#                                                 '_ID_' => undef,
#                                                 '_ANNOTATIONS_' => [],
#                                                 '_MMU_ERROR_' => 0,
#                                                 '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                 '_ANNOTATION_TYPE_' => undef,
#                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                 '_RELATIVE_INTENSITY_999_' => undef,
#                                                 '_ANNOTATION_SMILES_' => undef,
#                                                 '_RELATIVE_INTENSITY_100_' => '58.70',
#                                                 '_CLUSTER_ID_' => 2,
#                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                 '_INTENSITY_' => '17439.745499466',
#                                                 '_PPM_ERROR_' => 0,
#                                                 '_ANNOTATION_ONLY_IN_' => undef,
#                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                 '_SPECTRA_ID_' => undef
#                                               }, 'Metabolomics::Banks' )
#                                      ],
#                 '_DATABASE_TOKEN_' => '2big17k7a871tfatk1b4cm8pr7',
#                 '_DATABASE_URL_CARD_' => 'database_url_card',
#                 '_DATABASE_TYPE_' => 'METABOLITE',
#                 '_RESOLUTION_' => 'high',
#                 '_POLARITY_' => 'POSITIVE',
#                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
#                 '_DATABASE_ENTRIES_NB_' => undef,
#                 '_DATABASE_SPECTRA_' => {
#                                           'PFs008655' => bless( {
#                                                                   '_PEAKS_' => [
#                                                                     {'ri' => '0.5','mz' => '51.0226'},
#                                                                     {'mz' => '58.0235','ri' => '0.74'},
#                                                                     {'ri' => '0.73','mz' => '58.9949'},
#                                                                     {'ri' => '3.31','mz' => '59.0309'},
#                                                                     {'mz' => '61.0109','ri' => '1.15'},
#                                                                     {'mz' => '72.0386','ri' => '0.56'},
#                                                                     {'ri' => '100','mz' => '73.047'},
#                                                                     {'mz' => '74.0479','ri' => '8.42'},
#                                                                     {'ri' => '17.74','mz' => '75.0283'},
#                                                                     {'ri' => '1.4','mz' => '76.0277'},
#                                                                     {'ri' => '1.95','mz' => '77.031'},
#                                                                     {'ri' => '1.25','mz' => '78.0453'},
#                                                                     {'ri' => '1.65','mz' => '89.0401'},
#                                                                     {'mz' => '90.0452','ri' => '0.68'},
#                                                                     {'ri' => '1.59','mz' => '91.0535'},
#                                                                     {'ri' => '1.11','mz' => '103.0533'},
#                                                                     {'ri' => '2.83','mz' => '104.0612'},
#                                                                     {'mz' => '105.0307','ri' => '0.92'},
#                                                                     {'mz' => '105.0662','ri' => '1.03'},
#                                                                     {'mz' => '107.0468','ri' => '0.51'},
#                                                                     {'mz' => '117.0672','ri' => '0.54'},
#                                                                     {'ri' => '0.64','mz' => '119.0829'},
#                                                                     {'ri' => '0.66','mz' => '131.0362'},
#                                                                     {'mz' => '133.0215','ri' => '1.59'},
#                                                                     {'ri' => '2.93','mz' => '135.0316'},
#                                                                     {'ri' => '5.16','mz' => '140.5326'},
#                                                                     {'mz' => '141.0336','ri' => '1.25'},
#                                                                     {'mz' => '147.0613','ri' => '2.45'},
#                                                                     {'ri' => '3.44','mz' => '148.0458'},
#                                                                     {'ri' => '0.76','mz' => '148.5454'},
#                                                                     {'ri' => '6.78','mz' => '149.0276'},
#                                                                     {'mz' => '150.0389','ri' => '1.31'},
#                                                                     {'mz' => '151.0417','ri' => '0.7'},
#                                                                     {'mz' => '161.0414','ri' => '2.67'},
#                                                                     {'mz' => '162.049','ri' => '6.26'},
#                                                                     {'mz' => '163.0563','ri' => '10.37'},
#                                                                     {'ri' => '3.43','mz' => '164.0618'},
#                                                                     {'ri' => '1.15','mz' => '165.0565'},
#                                                                     {'mz' => '177.0694','ri' => '2.94'},
#                                                                     {'ri' => '5.19','mz' => '178.0475'},
#                                                                     {'mz' => '179.0527','ri' => '53.18'},
#                                                                     {'mz' => '180.0547','ri' => '8.68'},
#                                                                     {'mz' => '181.0517','ri' => '2.46'},
#                                                                     {'mz' => '192.0596','ri' => '2.19'},
#                                                                     {'ri' => '5.43','mz' => '193.0669'},
#                                                                     {'mz' => '194.0696','ri' => '1.51'},
#                                                                     {'mz' => '195.0675','ri' => '0.54'},
#                                                                     {'mz' => '206.0395','ri' => '13.96'},
#                                                                     {'mz' => '207.0721','ri' => '4.82'},
#                                                                     {'ri' => '1.04','mz' => '208.0612'},
#                                                                     {'mz' => '209.0996','ri' => '74.11'},
#                                                                     {'ri' => '12.66','mz' => '210.1015'},
#                                                                     {'ri' => '3.51','mz' => '211.0984'},
#                                                                     {'mz' => '221.0614','ri' => '1.59'},
#                                                                     {'mz' => '236.0826','ri' => '1.43'},
#                                                                     {'ri' => '16.98','mz' => '237.0763'},
#                                                                     {'mz' => '238.0779','ri' => '3.34'},
#                                                                     {'mz' => '239.0739','ri' => '1.63'},
#                                                                     {'mz' => '251.0901','ri' => '0.94'},
#                                                                     {'mz' => '252.0996','ri' => '15.28'},
#                                                                     {'mz' => '253.0987','ri' => '3.81'},
#                                                                     {'mz' => '254.0968','ri' => '1.63'},
#                                                                     {'mz' => '255.09','ri' => '0.91'},
#                                                                     {'mz' => '267.1236','ri' => '53.79'},
#                                                                     {'mz' => '268.1248','ri' => '13.33'},
#                                                                     {'mz' => '269.122','ri' => '4.92'},
#                                                                     {'ri' => '0.83','mz' => '270.1219'},
#                                                                     {'mz' => '278.916','ri' => '0.54'},
#                                                                     {'ri' => '8.4','mz' => '282.1464'},
#                                                                     {'ri' => '2.2','mz' => '283.1456'},
#                                                                     {'mz' => '284.1445','ri' => '0.77'},
#                                                                     {'mz' => '291.9319','ri' => '0.52'},
#                                                                     {'ri' => '0.91','mz' => '293.9343'},
#                                                                     {'mz' => '296.0901','ri' => '39.25'},
#                                                                     {'mz' => '297.0925','ri' => '9.63'},
#                                                                     {'mz' => '298.0895','ri' => '3.73'},
#                                                                     {'ri' => '0.64','mz' => '299.0913'},
#                                                                     {'mz' => '306.9547','ri' => '1.45'},
#                                                                     {'mz' => '308.9579','ri' => '2.4'},
#                                                                     {'ri' => '67.98','mz' => '311.1138'},
#                                                                     {'ri' => '17.24','mz' => '312.1154'},
#                                                                     {'ri' => '6.54','mz' => '313.1125'},
#                                                                     {'mz' => '314.1131','ri' => '1.14'},
#                                                                     {'ri' => '76.94','mz' => '326.1374'},
#                                                                     {'mz' => '327.139','ri' => '20.62'},
#                                                                     {'mz' => '328.1364','ri' => '7.95'},
#                                                                     {'ri' => '1.44','mz' => '329.1364'}
#                                                                                ],
#                                                                   '_ANALYSER_TYPE_' => 'electron impact (EI)',
#                                                                   '_MANUFACTURER_BRAND_' => 'Agilent',
#                                                                   '_IONISATION_METHOD_' => undef,
#                                                                   '_CREATED_' => '2021-08-10T15:20:41Z',
#                                                                   '_ID_' => 'PFs008655',
#                                                                   '_SYNONYMS_' => 'single compound',
#                                                                   '_SPECTRUM_NAME_' => 'hva - homovanillic acid; GC-EI-QTOF; MS; 2 TMS; ',
#                                                                   '_COMPOUNDS_' => [
#                                                                                      'PFc000244'
#                                                                                    ],
#                                                                   '_SPECTRUM_TYPE_' => 'fullscan-gcms-spectrum',
#                                                                   '_POLARITY_' => 'positive',
#                                                                   '_RESOLUTION_' => 'high'
#                                                                 }, 'Metabolomics::Banks::PeakForest' ),
#                                           'PFs008654' => bless( {
#                                                                   '_ID_' => 'PFs008654',
#                                                                   '_COMPOUNDS_' => [
#                                                                                      'PFc000341'
#                                                                                    ],
#                                                                   '_SPECTRUM_NAME_' => 'Urea; GC-EI-QTOF; MS; 2 TMS; ',
#                                                                   '_SYNONYMS_' => 'single compound',
#                                                                   '_SPECTRUM_TYPE_' => 'fullscan-gcms-spectrum',
#                                                                   '_POLARITY_' => 'positive',
#                                                                   '_RESOLUTION_' => 'high',
#                                                                   '_PEAKS_' => [
#                                                                     {'ri' => '1.39','mz' => '52.0063'},
#                                                                     {'ri' => '0.54','mz' => '52.0295'},
#                                                                     {'ri' => '1.6','mz' => '55.9959'},
#                                                                     {'mz' => '57.014','ri' => '0.69'},
#                                                                     {'mz' => '58.0146','ri' => '0.94'},
#                                                                     {'ri' => '3.54','mz' => '59.0301'},
#                                                                     {'ri' => '1.03','mz' => '60.026'},
#                                                                     {'ri' => '1.16','mz' => '61.0109'},
#                                                                     {'ri' => '2.08','mz' => '64.0108'},
#                                                                     {'mz' => '65.0025','ri' => '0.75'},
#                                                                     {'mz' => '66.0207','ri' => '3.95'},
#                                                                     {'ri' => '0.65','mz' => '66.5204'},
#                                                                     {'mz' => '68.9926','ri' => '3.2'},
#                                                                     {'mz' => '69.9742','ri' => '6.01'},
#                                                                     {'ri' => '3.44','mz' => '71.0062'},
#                                                                     {'mz' => '71.9899','ri' => '10.34'},
#                                                                     {'ri' => '0.67','mz' => '72.9909'},
#                                                                     {'ri' => '24.85','mz' => '73.0465'},
#                                                                     {'ri' => '34.17','mz' => '74.0423'},
#                                                                     {'mz' => '75.0266','ri' => '31.33'},
#                                                                     {'ri' => '3.03','mz' => '76.0302'},
#                                                                     {'mz' => '77.0223','ri' => '1.82'},
#                                                                     {'ri' => '1.71','mz' => '78.0311'},
#                                                                     {'mz' => '79.0348','ri' => '0.83'},
#                                                                     {'mz' => '84.0261','ri' => '1.16'},
#                                                                     {'mz' => '85.0224','ri' => '0.68'},
#                                                                     {'ri' => '0.78','mz' => '86.0052'},
#                                                                     {'ri' => '1.39','mz' => '87.031'},
#                                                                     {'mz' => '89.041','ri' => '1.62'},
#                                                                     {'ri' => '26.11','mz' => '99.037'},
#                                                                     {'mz' => '100.0217','ri' => '42.99'},
#                                                                     {'ri' => '0.96','mz' => '100.0703'},
#                                                                     {'ri' => '4.41','mz' => '101.024'},
#                                                                     {'ri' => '1.78','mz' => '102.0183'},
#                                                                     {'mz' => '113.0242','ri' => '0.8'},
#                                                                     {'ri' => '0.53','mz' => '114.0204'},
#                                                                     {'mz' => '115.0041','ri' => '1.37'},
#                                                                     {'mz' => '117.0476','ri' => '11.09'},
#                                                                     {'mz' => '118.0487','ri' => '1.02'},
#                                                                     {'mz' => '119.0455','ri' => '0.72'},
#                                                                     {'mz' => '130.0499','ri' => '6.18'},
#                                                                     {'ri' => '4.53','mz' => '131.0369'},
#                                                                     {'ri' => '1.41','mz' => '131.0851'},
#                                                                     {'mz' => '132.0329','ri' => '3.41'},
#                                                                     {'ri' => '1.88','mz' => '133.0412'},
#                                                                     {'mz' => '135.0603','ri' => '0.58'},
#                                                                     {'ri' => '5.66','mz' => '146.081'},
#                                                                     {'mz' => '147.0658','ri' => '100'},
#                                                                     {'mz' => '148.0666','ri' => '15.61'},
#                                                                     {'mz' => '149.0621','ri' => '7.94'},
#                                                                     {'mz' => '150.0622','ri' => '0.8'},
#                                                                     {'ri' => '1.1','mz' => '155.0459'},
#                                                                     {'mz' => '157.0293','ri' => '0.94'},
#                                                                     {'mz' => '171.0768','ri' => '52.6'},
#                                                                     {'ri' => '9.12','mz' => '172.0775'},
#                                                                     {'ri' => '8.88','mz' => '173.0645'},
#                                                                     {'ri' => '0.96','mz' => '174.0608'},
#                                                                     {'mz' => '175.0558','ri' => '0.56'},
#                                                                     {'ri' => '0.87','mz' => '179.052'},
#                                                                     {'ri' => '50.66','mz' => '189.0875'},
#                                                                     {'ri' => '8.63','mz' => '190.0881'},
#                                                                     {'ri' => '3.94','mz' => '191.085'}
#                                                                 ],
#                                                                   '_ANALYSER_TYPE_' => 'electron impact (EI)',
#                                                                   '_MANUFACTURER_BRAND_' => 'Agilent',
#                                                                   '_CREATED_' => '2021-08-10T12:41:36Z',
#                                                                   '_IONISATION_METHOD_' => undef
#                                                                 }, 'Metabolomics::Banks::PeakForest' )
#                                         },
#                 '_DATABASE_DOI_' => 'NA',
#                 '_DATABASE_NAME_' => 'PeakForest',
#                 '_DATABASE_URL_' => 'https://metabohub.peakforest.org/rest/v2',
#                 '_EXP_PSEUDOSPECTRA_LIST_' => {
#                                                 '1' => [
#                                                          bless( {
#                                                                   '_ID_' => undef,
#                                                                   '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                                   '_RELATIVE_INTENSITY_100_' => undef,
#                                                                   '_INTENSITY_' => '19932.8992306905',
#                                                                   '_ANNOTATIONS_' => [],
#                                                                   '_SPECTRA_ID_' => undef,
#                                                                   '_RELATIVE_INTENSITY_999_' => undef,
#                                                                   '_ANNOTATION_NAME_' => undef,
#                                                                   '_CLUSTER_ID_' => 1,
#                                                                   '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                                   '_ANNOTATION_ONLY_IN_' => undef,
#                                                                   '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                                   '_ANNOTATION_FORMULA_' => undef,
#                                                                   '_ANNOTATION_TYPE_' => undef,
#                                                                   '_MESURED_MONOISOTOPIC_MASS_' => '50.9994825424595',
#                                                                   '_MMU_ERROR_' => 0,
#                                                                   '_PPM_ERROR_' => 0,
#                                                                   '_ANNOTATION_SMILES_' => undef,
#                                                                   '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                                   '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                                   '_ANNOTATION_INCHIKEY_' => undef,
#                                                                   '_ANNOTATION_IN_POS_MODE_' => undef
#                                                                 }, 'Metabolomics::Banks' )
#                                                        ],
#                                                 '2' => [
#                                                          bless( {
#                                                                   '_ANNOTATION_NAME_' => undef,
#                                                                   '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                                   '_CLUSTER_ID_' => 2,
#                                                                   '_RELATIVE_INTENSITY_999_' => undef,
#                                                                   '_ANNOTATION_ONLY_IN_' => undef,
#                                                                   '_INTENSITY_' => '29711.21202827083',
#                                                                   '_RELATIVE_INTENSITY_100_' => undef,
#                                                                   '_SPECTRA_ID_' => undef,
#                                                                   '_ANNOTATIONS_' => [],
#                                                                   '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                                   '_ID_' => undef,
#                                                                   '_ANNOTATION_INCHIKEY_' => undef,
#                                                                   '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                                   '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                                   '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                                   '_PPM_ERROR_' => 0,
#                                                                   '_ANNOTATION_SMILES_' => undef,
#                                                                   '_ANNOTATION_TYPE_' => undef,
#                                                                   '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                                   '_ANNOTATION_FORMULA_' => undef,
#                                                                   '_MMU_ERROR_' => 0,
#                                                                   '_MESURED_MONOISOTOPIC_MASS_' => '147.06580000000'
#                                                                 }, 'Metabolomics::Banks' ),
#                                                          bless( {
#                                                                   '_PPM_ERROR_' => 0,
#                                                                   '_ANNOTATION_SMILES_' => undef,
#                                                                   '_ANNOTATION_TYPE_' => undef,
#                                                                   '_ANNOTATION_FORMULA_' => undef,
#                                                                   '_ANNOTATION_IS_A_PRECURSOR_' => undef,
#                                                                   '_MMU_ERROR_' => 0,
#                                                                   '_MESURED_MONOISOTOPIC_MASS_' => '171.0768000000',
#                                                                   '_ANNOTATION_INCHIKEY_' => undef,
#                                                                   '_ANNOTATION_IN_POS_MODE_' => undef,
#                                                                   '_ANNOTATION_SPECTRAL_IDS_' => [],
#                                                                   '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
#                                                                   '_ANNOTATION_IS_A_METABOLITE_' => undef,
#                                                                   '_ID_' => undef,
#                                                                   '_CLUSTER_ID_' => 2,
#                                                                   '_ANNOTATION_IN_NEG_MODE_' => undef,
#                                                                   '_ANNOTATION_NAME_' => undef,
#                                                                   '_RELATIVE_INTENSITY_999_' => undef,
#                                                                   '_ANNOTATION_ONLY_IN_' => undef,
#                                                                   '_INTENSITY_' => '17439.745499466',
#                                                                   '_RELATIVE_INTENSITY_100_' => undef,
#                                                                   '_SPECTRA_ID_' => undef,
#                                                                   '_ANNOTATIONS_' => []
#                                                                 }, 'Metabolomics::Banks' )
#                                                        ]
#                                               }
#               }, 'Metabolomics::Banks::PeakForest' ),
#        ## MSG
#		'Method \'buildSpectralBankFromPeakForest\' return a well formatted bank object with matched PeakForest spectra for a specific gcms search'
#	) ;
	
## #################################################################################################################################
##
#########################	######################### 		ALL TESTS SUB		 #########################  ########################
##
####################################################################################################################################

##
#########################	######################### 	BANK TESTS SUB	 #########################  ####################
##


	## SUB TEST for test bank object init
	sub parsingMsFragmentsByCluster_TEST {
		my ( $Xfile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds ) = @_ ;
	    # get values
	    #
	    my $o = Metabolomics::Banks::PeakForest->new(
	    	{	
	    		DATABASE_URL => 'https://metabohub.peakforest.org/rest/v2', 
	    		TOKEN => '2big17k7a871tfatk1b4cm8pr7',
	    		POLARITY => 'POSITIVE',
	    		RESOLUTION => 'high'
	    	}
	    
	    ) ;
	    
	    my ($numMzs, $numInt, $numClusters) = $o->parsingMsFragmentsByCluster($Xfile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds);
#	    print Dumper $o ;
	    return($numMzs) ;
	}
	## End SUB


##
#########################	######################### 	BLOOD EXPOSOME TESTS SUB	 #########################  ####################
##

	## SUB TEST for test bank object init
	sub init_BloodExposomeBankObject_TEST {
	    # get values
	    #
	    my $o = Metabolomics::Banks::BloodExposome->new() ;
#	    print Dumper $o ;

	    return($o) ;
	}
	## End SUB

		## sub
	sub getBloodExposomeFromSourceTest {
		my ( $source ) = @_ ;
		my $o = Metabolomics::Banks::BloodExposome->new() ;
		my $MetaboliteNb = $o->getMetabolitesFromSource($source) ;
#		print Dumper $o ;
		return ($MetaboliteNb) ;
	}
	## sub
	
	## SUB TEST for 
	sub buildTheoPeakBankFromEntriesTest {
	    # get values
	    my ( $source, $ionMode ) = @_;
	    my $o = Metabolomics::Banks::BloodExposome->new() ;
	    $o->getMetabolitesFromSource($source) ;
	    my $nb = $o->buildTheoPeakBankFromEntries($ionMode) ;
#	    print Dumper $o ;
	    return($nb) ;
	}
	## End SUB

##
#########################	######################### 	AB INITIO FRAG TESTS SUB	 #########################  ####################
##
	## SUB TEST for test bank object init
	sub init_AbInitioFragBankObject_TEST {
	    # get values
	    #
	    my $o = Metabolomics::Banks::AbInitioFragments->new() ;
#	    print Dumper $o ;

	    return($o) ;
	}
	## End SUB

	## sub
	sub getFragmentsFromSourceTest {
		
		my ( $source ) = @_ ;
		
		my $oFragBank = Metabolomics::Banks::AbInitioFragments->new ;
		$oFragBank->getFragmentsFromSource($source) ;
#		print Dumper $oFragBank ;
		
		return ($oFragBank) ;
	}

	## sub
	sub buildTheoPeakBankFromFragmentsTest {
		my ( $source, $mzParent ) = @_ ;
		
		my $oBank = Metabolomics::Banks::AbInitioFragments->new() ;
		$oBank->getFragmentsFromSource($source) ;
		
		my $nb = $oBank->buildTheoPeakBankFromFragments($mzParent) ;
#		print Dumper $oBank ;
		
		return ($oBank) ;
	}
	
	
	## SUB TEST for 
	sub buildTheoDimerFromMzTest {
	    # get values
	    my ( $oBank, $MassParent, $mode ) = @_;
	    
	    $oBank->buildTheoDimerFromMz($MassParent, $mode) ;
#	    print Dumper $oBank ;
	    
	    return($oBank) ;
	}
	## End SUB
	
	## SUB TEST for 
	sub isotopicAdvancedCalculationTest {
	    # get values
	    my ( $oBank, $mode ) = @_;
	    
	    $oBank->isotopicAdvancedCalculation($mode) ;
#	    print Dumper $oBank ;
	    
	    return($oBank) ;
	}
	## End SUB

##
#########################	######################### 	MACONDA TESTS SUB	 #########################  ####################
##


	## SUB TEST for test bank object init
	sub init_MaConDaBankObject_TEST {
	    # get values
	    #
	    my $o = Metabolomics::Banks::MaConDa->new() ;
#	    print Dumper $o ;
	    return($o) ;
	}
	## End SUB

	## sub
	sub getContaminantsFromSourceTest {
		my ( $source ) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new() ;
		$oBank->getContaminantsFromSource($source) ;
#		print Dumper $oBank ;
		return ($oBank) ;
	}
	
	## sub
	sub getContaminantsExtFromSourceTest {
		my ( $source ) = @_ ;

		my $oBank = Metabolomics::Banks::MaConDa->new() ;
		$oBank->getContaminantsExtensiveFromSource($source) ;
#		print Dumper $oBank ;
		return ($oBank) ;
	}
	
		## sub
	sub extractContaminantTypesTest {
		my ( $source ) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new() ;
		$oBank->getContaminantsExtensiveFromSource($source) ;
#		print Dumper $oBank ;
		my $typeList = $oBank->extractContaminantTypes() ;
#		print Dumper $typeList ;
		return ($typeList) ;
	}
	## sub
	sub extractContaminantInstrumentsTest {
		my ( $source ) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new() ;
		$oBank->getContaminantsExtensiveFromSource($source) ;
#		print Dumper $oBank ;
		
		my $instrumentList = $oBank->extractContaminantInstruments() ;
#		print Dumper $instrumentList ;
		return ($instrumentList) ;
	}
		## sub
	sub extractContaminantInstrumentTypesTest {
		my ( $source ) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new() ;
		$oBank->getContaminantsExtensiveFromSource($source) ;
		
		my $instrumentTypeList = $oBank->extractContaminantInstrumentTypes() ;
#		print Dumper $instrumentTypeList ;
		return ($instrumentTypeList) ;
	}
	
		## sub
	sub filterContaminantIonModeTest  {
		my ( $source, $IonMode ) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new() ;
		$oBank->getContaminantsExtensiveFromSource($source) ;
		
		my $oNew = $oBank->filterContaminantIonMode($IonMode) ;
#		print Dumper $oNew ;
		return ($oNew) ;
	}
	
	## sub
	sub filterContaminantInstrumentsTest  {
		my ( $source, $Instrument ) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new() ;
		$oBank->getContaminantsExtensiveFromSource($source) ;
		
		my ($oNew, $totalEntryNum, $fiteredEntryNum) = $oBank->filterContaminantInstruments($Instrument) ;
#		print Dumper $oNew ;
#		print "$fiteredEntryNum on $totalEntryNum\n" ;
		return ($oNew) ;
	}
	
	## sub
	sub filterContaminantInstrumentTypesTest  {
		my ( $source, $Instrument ) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new() ;
		$oBank->getContaminantsExtensiveFromSource($source) ;
		
		my ($oNew, $totalEntryNum, $fiteredEntryNum) = $oBank->filterContaminantInstrumentTypes($Instrument) ;
#		print Dumper $oNew ;
#		print "$fiteredEntryNum on $totalEntryNum\n" ;
		return ($oNew) ;
	}
	
		## sub buildTheoPeakBankFromContaminants
	## SUB TEST for 
	sub buildTheoPeakBankFromContaminantsTest {
	    # get values
	    my ( $oBank, $queryMode ) = @_;
	    
	    $oBank->buildTheoPeakBankFromContaminants($queryMode ) ;
#	    print Dumper $oBank ;
	    return($oBank) ;
	}
	## End SUB
	
	
##
#########################	######################### 	KNAPSACK TESTS SUB	 #########################  ####################
##

	## SUB TEST for test bank object init
	sub init_KnapSackBankObject_TEST {
	    # get values
	    #
	    my $o = Metabolomics::Banks::Knapsack->new() ;
#	    print Dumper $o ;
	    return($o) ;
	}
	## End SUB

	## sub
	sub getKnapSackFromSourceTest {
		my ( $source ) = @_ ;
		my $o = Metabolomics::Banks::Knapsack->new() ;
		my $MetaboliteNb = $o->getKSMetabolitesFromSource($source) ;
#		print Dumper $o ;
		return ($MetaboliteNb) ;
	}
	
	## sub
	sub buildTheoPeakBankFromKSTest {
		# get values
	    my ( $oBank, $queryMode ) = @_;
	    
	    my $oBankNb = $oBank->buildTheoPeakBankFromKnapsack($queryMode ) ;
#	    print Dumper $oBank ;
	    return($oBankNb) ;
	}	

##
#########################	######################### 	PHYTOHUB TESTS SUB	 #########################  ####################
##
	## sub
	sub initPhytoHubBankObject_TEST {
		# get values
	    #
	    my $o = Metabolomics::Banks::PhytoHub->new() ;
#	    print Dumper $o ;
	    return($o) ;
	}
	## END
	
	## sub
	sub getPhytoHubFromSource_Test {
		my ( $source ) = @_ ;
		my $o = Metabolomics::Banks::PhytoHub->new() ;
		my $MetaboliteNb = $o->getMetabolitesFromSource($source) ;
#		print Dumper $o ;
		return ($MetaboliteNb) ;
	}
	
	sub buildTheoPeakBankFromPhytoHubTest {
		# get values
	    my ( $oBank, $queryMode ) = @_;
	    
	    my $oBankNb = $oBank->buildTheoPeakBankFromPhytoHub($queryMode ) ;
#	    print Dumper $oBank ;
	    return($oBankNb) ;
	}
	
	
##
#########################	######################### 	PEAKFOREST TESTS SUB REST V01	 #########################  ####################
##
	## sub
	sub initPeakForestBankObject_TEST {
		# get values
		my ($url, $token) = @_ ;
	    #
	    my $o = Metabolomics::Banks::PeakForest->new( 
	    	{	
	    		DATABASE_URL => $url, 
	    		TOKEN => $token,
	    	}
	    ) ;
#	    print Dumper $o ;
	    return($o) ;
	}
	## END
	
	## sub
	sub getCleanRangeSpectraFromSource_TEST {
		my ( $url, $token, $mode, $minMass, $maxMass ) = @_ ; 
		
		my $o = Metabolomics::Banks::PeakForest->new({	
	    		DATABASE_URL => $url, 
	    		TOKEN => $token,
	    	}
	    ) ;
	    
	    $o->initPeakForestQuery({	
	    		MODE => $mode, 
	    	}
	    ) ;
	    
		my $spectraNb = $o->getCleanRangeSpectraFromSource($minMass, $maxMass) ;
#		print Dumper $o ;
		return ($spectraNb) ;
	}
	## END
	
##
#########################	######################### 	PEAKFOREST TESTS SUB REST V02	 #########################  ####################
##
	## sub
	sub getCompoundFromId_TEST {
		# get values
		my ($url, $token, $cpdId) = @_ ;
	    #
	    my $o = Metabolomics::Banks::PeakForest->new( 
	    	{	
	    		DATABASE_URL => $url, 
	    		TOKEN => $token,
	    		POLARITY => 'positive',
	    		RESOLUTION => 'high'
	    	}
	    ) ;
	    
	    my $oCpd = $o->_getCompoundFromId( $cpdId ) ;
	    
#	    print Dumper $oCpd ;
	    return($oCpd) ;
	}
	## END
	
	## sub
	sub getGcmsSpectraMatchingPeaks_TEST {
		# get values
		my ($url, $token, $column_code, $polarity, $resolution, $list_mz, $delta) = @_ ;
	    #
	    my $o = Metabolomics::Banks::PeakForest->new( 
	    	{	
	    		DATABASE_URL => $url, 
	    		TOKEN => $token,
	    		POLARITY => $polarity,
	    		RESOLUTION => $resolution
	    	}
	    ) ;
	    
	    my $oSpectra = $o->_getGcmsSpectraByMatchingPeaks($column_code, $list_mz, $delta) ;
	    
#	    print Dumper $oSpectra ;

	    return($oSpectra) ;
	}
	## END
	
	## sub
	sub getGcmsSpectraFromIds_TEST {
		# get values
		my ($url, $token, $list_ids) = @_ ;
		
		my $o = Metabolomics::Banks::PeakForest->new( 
	    	{	
	    		DATABASE_URL => $url, 
	    		TOKEN => $token,
	    	}
	    ) ;
	    
	    my ($oSpectra, $nbSpectra) = $o->_getGcmsSpectraFromIds($list_ids) ;
	    
#	    print Dumper $oSpectra ;
	    return($nbSpectra) ;
	}
	## END
	
	## sub
	sub buildSpectralBankFromPeakForest_TEST {
		#  get values
		my ( $o ) = @_ ;
		
		# colonm_code and delta
		$o->buildSpectralBankFromPeakForest(undef, 'MMU', 0.05, 1) ; ## column, delta type, delta in MMU, MIN_FRAG filter 
#		print Dumper $o ;
		
		return($o) ;
	}
	
}## END BEGIN part




