# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl FragNot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../lib";  # use the parent directory

use Metabolomics::Fragment::Annotation qw( :all ) ;
use Metabolomics::Banks qw( :all ) ;
use Metabolomics::Banks::BloodExposome qw( :all ) ;
use Metabolomics::Banks::MaConDa qw( :all ) ;
use Metabolomics::Banks::AbInitioFragments qw( :all ) ;
use Metabolomics::Banks::Knapsack qw( :all ) ;
use Metabolomics::Banks::PhytoHub qw( :all ) ;
use Metabolomics::Banks::PeakForest qw( :all ) ;

use Test::More tests => 33 ;
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
	print "\n** Test $current_test _mapPeakListWithTemplateFields **\n" ; $current_test++ ;
	is_deeply( _mapPeakListWithTemplateFields_TEST (
	## ARGTS
		## Fields:
	[
          '_MESURED_MONOISOTOPIC_MASS_',
          '_PPM_ERROR_',
          '_COMPUTED_MONOISOTOPIC_MASS_',
          '_ANNOTATION_NAME_',
          '_ANNOTATION_TYPE_',
          '_ANNOTATION_IN_NEG_MODE_',
          '_ANNOTATION_IN_POS_MODE_',
          '_ANNOTATION_FORMULA_'
    ],
      ## PeakList:
	[
         bless( {
            '_ANNOTATION_FORMULA_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '85.02824868',
            '_PPM_ERROR_' => 0,
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_ANNOTATION_NAME_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA'
        },  'Metabolomics::Banks' ),
		 bless( {
            '_ANNOTATION_FORMULA_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '993.9955766',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_ANNOTATION_NAME_' => 'NA',
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_PPM_ERROR_' => 0,
            '_ANNOTATION_TYPE_' => 'NA'
          },  'Metabolomics::Banks' ),
           bless( {
            '_ANNOTATION_FORMULA_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '994.245866',
            '_PPM_ERROR_' => 0,
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_ANNOTATION_NAME_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA'
          }, 'Metabolomics::Banks' ),
    ]
    ),
	## Expected	
		[
           bless( {
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_ANNOTATION_FORMULA_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_ANNOTATION_NAME_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '85.02824868',
            '_PPM_ERROR_' => 0
          }, 'Metabolomics::Banks' ),
           bless( {
            '_ANNOTATION_FORMULA_' => 'NA',
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_MESURED_MONOISOTOPIC_MASS_' => '993.9955766',
            '_PPM_ERROR_' => 0,
            '_ANNOTATION_NAME_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA'
          }, 'Metabolomics::Banks' ),
           bless( {
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_ANNOTATION_FORMULA_' => 'NA',
            '_ANNOTATION_NAME_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '994.245866',
            '_PPM_ERROR_' => 0
          }, 'Metabolomics::Banks' ),
        ],
	## MSG
		'Method \'_mapPeakListWithTemplateFields\' maps well with a peak list and template fields content');
	
	
	
	
#########################	
	print "\n** Test $current_test compareExpMzToTheoMzList with Ab initio fragments bank**\n" ; $current_test++ ;
	is_deeply( compareExpMzToTheoMzListTest(
	## ARGTS
		bless( {
                 '_DATABASE_ENTRIES_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_URL_CARD_' => 'database_url_card',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_DATABASE_TYPE_'	=> 'FRAGMENT',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => {},
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '358.0924 ',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '358.0023 ',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef
                                               }, 'Metabolomics::Banks' ),
                                      ],
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_TYPE_' => 'adduct',
                                             '_ANNOTATION_IN_NEG_MODE_' => '[(M-H+Na+K)-H]-',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                  ],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_MMU_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '358.0524',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' ),
                                       ],
               }, 'Metabolomics::Banks' ),
        'MMU', 0.05),
	## Expected	
		bless( {
				 '_ANNOTATION_TOOL_' => 'mzBiH',
                 '_ANNOTATION_DB_SOURCE_' => 'Ab Initio Fragments',
                 '_ANNOTATION_DB_SOURCE_URL_' => 'database_url',
                 '_ANNOTATION_DB_SOURCE_URL_CARD_' => 'database_url_card',
                 '_ANNOTATION_DB_SOURCE_TYPE_' => 'FRAGMENT',
                 '_ANNOTATION_TOOL_VERSION_' => '0.1',
                 '_ANNOTATION_PARAMS_DELTA_' => 0.05,
                 '_ANNOTATION_PARAMS_DELTA_TYPE_' => 'MMU',
                 '_ANNOTATION_PARAMS_INSTRUMENTS_' => [],
                 '_ANNOTATION_PARAMS_FILTERS_' => [],
                 '_ANNOTATION_DB_SOURCE_VERSION_' => '1.0',
                 '_ANNOTATION_DB_SPECTRA_INDEX_' => undef,
                 '_EXP_PSEUDOSPECTRA_LIST_' => undef,
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => {},
                 '_ANNOTATION_ION_MODE_' => 'annotation_ion_mode',
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '358.0524',
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '358.0924 ',
                                                 '_ID_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_PPM_ERROR_' => '111.7',
                                                 '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => 'adduct',
                                                 '_MMU_ERROR_' => '0.0400'
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '358.0023 ',
                                                 '_ID_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef
                                               }, 'Metabolomics::Banks' )
                                      ],
                 
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '358.0524',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
                                                }, 'Metabolomics::Banks' )
                                       ],
               }, 'Metabolomics::Fragment::Annotation' ),
	## MSG
		'Method \'compareExpMzToTheoMzList\' works with peak list and Ab initio fragments content');
		
#########################	
	print "\n** Test $current_test compareExpMzToTheoMzList with MaConDa content**\n" ; $current_test++ ;
	is_deeply( compareExpMzToTheoMzListTest(
	## ARGTS
		bless( {
				 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_DATABASE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_DATABASE_TYPE_'	=> 'METABOLITE',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => {},
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '102.05495',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '103.05000',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef
                                               }, 'Metabolomics::Banks' ),
                                      ],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '102.0549554',
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_ANNOTATION_IN_POS_MODE_' => '[M+H]+',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ID_' => 'CON00004',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_NAME_' => 'Acetonitrile.1.Acetic acid.1'
                                                }, 'Metabolomics::Banks' ),
                                       ],
               }, 'Metabolomics::Fragment::Annotation' ),
        'PPM', 5),
	## Expected	
		bless( {
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '102.0549554',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ID_' => 'CON00004',
                                                  '_ANNOTATION_NAME_' => 'Acetonitrile.1.Acetic acid.1',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => '[M+H]+',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'Solvent'
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_MMU_ERROR_' => '0.00001',
                                                 '_ANNOTATION_NAME_' => 'Acetonitrile.1.Acetic acid.1',
                                                 '_ID_' => 'CON00004',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '102.0549554',
                                                 '_PPM_ERROR_' => 0.1,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_TYPE_' => 'Solvent',
                                                 '_ANNOTATION_IN_POS_MODE_' => '[M+H]+',
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '102.05495'
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '103.05000',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ID_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef
                                               }, 'Metabolomics::Banks' )
                                      ],
                 '_ANNOTATION_DB_SOURCE_VERSION_' => '1.0',
                 '_ANNOTATION_DB_SOURCE_' => 'MaConDa',
                 '_ANNOTATION_DB_SOURCE_URL_' => 'https://maconda.bham.ac.uk/',
                 '_ANNOTATION_DB_SOURCE_URL_CARD_' => 'https://www.maconda.bham.ac.uk/contaminant.php?id=',           
                 '_ANNOTATION_DB_SOURCE_TYPE_' => 'METABOLITE',
                 '_ANNOTATION_TOOL_VERSION_' => '0.1',
                 '_ANNOTATION_PARAMS_DELTA_' => 5,
                 '_ANNOTATION_PARAMS_DELTA_TYPE_' => 'PPM',
                 '_ANNOTATION_PARAMS_INSTRUMENTS_' => [],
                 '_ANNOTATION_PARAMS_FILTERS_' => [],
                 '_ANNOTATION_DB_SPECTRA_INDEX_' => undef,
                 '_ANNOTATION_TOOL_' => 'mzBiH',
                 '_ANNOTATION_ION_MODE_' => 'annotation_ion_mode',
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => {},
                 '_EXP_PSEUDOSPECTRA_LIST_' => {},
                 
               }, 'Metabolomics::Fragment::Annotation' ),
	## MSG
		'Method \'compareExpMzToTheoMzList\' works with peak list file and Contaminant content');

########################	
	print "\n** Test $current_test compareExpMzToTheoMzList with BloodExposome db content**\n" ; $current_test++ ;
	is_deeply( compareExpMzToTheoMzListTest(
	## ARGTS
		bless( {
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_URL_' => 'http://bloodexposome.org/',
                 '_DATABASE_URL_CARD_' => 'https://pubchem.ncbi.nlm.nih.gov/#query=',
                 '_DATABASE_NAME_' => 'Blood Exposome',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_TYPE_'	=> 'METABOLITE',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_EXP_PSEUDOSPECTRA_LIST_' => undef,
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {}, 
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '119.086',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef
                                               }, 'Metabolomics::Banks' ),
                                      ],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => 'L-valine',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.086'
                                                }, 'Metabolomics::Banks' ),
                                       ],
               }, 'Metabolomics::Fragment::Annotation' ),
        'MMU', 0.05),
	## Expected	
		bless( {
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ID_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => 'L-valine',
                                                 '_MMU_ERROR_' => '0.000',
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '118.086'
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ID_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '119.086',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MMU_ERROR_' => 0
                                               }, 'Metabolomics::Banks' )
                                      ],
                 '_ANNOTATION_TOOL_VERSION_' => '0.1',
                 '_ANNOTATION_PARAMS_DELTA_' => 0.05,
                 '_ANNOTATION_PARAMS_DELTA_TYPE_' => 'MMU',
                 '_ANNOTATION_PARAMS_INSTRUMENTS_' => [],
                 '_ANNOTATION_PARAMS_FILTERS_' => [],
                 '_ANNOTATION_DB_SOURCE_VERSION_' => '1.0',
                 '_ANNOTATION_DB_SPECTRA_INDEX_' => undef,
                 '_EXP_PSEUDOSPECTRA_LIST_' => undef,
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [],
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {}, 
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => 'L-valine',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.086',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_ANNOTATION_DB_SOURCE_' => 'Blood Exposome',
                 '_ANNOTATION_DB_SOURCE_URL_' => 'http://bloodexposome.org/',
                 '_ANNOTATION_DB_SOURCE_URL_CARD_' => 'https://pubchem.ncbi.nlm.nih.gov/#query=',
                 '_ANNOTATION_DB_SOURCE_TYPE_' => 'METABOLITE',
                 '_ANNOTATION_TOOL_' => 'mzBiH',
                 '_ANNOTATION_ION_MODE_' => 'annotation_ion_mode'
               }, 'Metabolomics::Fragment::Annotation' ),
	## MSG
		'Method \'compareExpMzToTheoMzList\' works with peak list file and BloodExposome db content');	


#########################
	print "\n** Test $current_test compareExpMzToTheoMzListAllMatches with BloodExposome db content**\n" ; $current_test++ ;
	is_deeply( compareExpMzToTheoMzListAllMatchesTest(
	## ARGTS
		bless( {
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_URL_' => 'http://bloodexposome.org/',
                 '_DATABASE_URL_CARD_' => 'https://pubchem.ncbi.nlm.nih.gov/#query=',
                 '_DATABASE_NAME_' => 'Blood Exposome',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_TYPE_' => 'METABOLITE',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_ANNOTATION_DB_SPECTRA_INDEX_' => undef,
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_EXP_PSEUDOSPECTRA_LIST_' => undef,
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '119.086',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef
                                               }, 'Metabolomics::Banks' ),
                                      ],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => 'L-valine',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.086'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ID_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => 'D-valine',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.087'
                                                }, 'Metabolomics::Banks' ),
                                       ],
               }, 'Metabolomics::Fragment::Annotation' ),
        'MMU', 0.05),
	## Expected	
		bless( {
                 '_ANNOTATION_DB_SOURCE_' => 'Blood Exposome',
                 '_ANNOTATION_DB_SOURCE_URL_' => 'http://bloodexposome.org/',
                 '_ANNOTATION_DB_SOURCE_URL_CARD_' => 'https://pubchem.ncbi.nlm.nih.gov/#query=',
                 '_ANNOTATION_DB_SOURCE_TYPE_' => 'METABOLITE',
                 '_ANNOTATION_TOOL_' => 'mzBiH',
                 '_ANNOTATION_ION_MODE_' => 'annotation_ion_mode',
                 '_ANNOTATION_DB_SPECTRA_INDEX_' => undef,
                 '_EXP_PSEUDOSPECTRA_LIST_' => undef,
                 '_PSEUDOSPECTRA_SPECTRA_INDEX_' => {},
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.086',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => 'L-valine',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.087',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => 'D-valine',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_ANNOTATION_DB_SOURCE_VERSION_' => '1.0',
                 '_ANNOTATION_TOOL_VERSION_' => '0.1',
                 '_ANNOTATION_PARAMS_DELTA_' => 0.05,
                 '_ANNOTATION_PARAMS_DELTA_TYPE_' => 'MMU',
                 '_ANNOTATION_PARAMS_INSTRUMENTS_' => [],
                 '_ANNOTATION_PARAMS_FILTERS_' => [],
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 118.086,
                                                 '_ID_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_ANNOTATION_NAME_' => 'L-valine',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATIONS_' => [
                                                 		bless( {
                                                                               '_RELATIVE_INTENSITY_100_' => undef,
                                                                               '_CLUSTER_ID_' => undef,
                                                                               '_ANNOTATION_ONLY_IN_' => undef,
                                                                               '_ANNOTATION_INCHIKEY_' => undef,
                                                                               '_ANNOTATION_NAME_' => 'L-valine',
                                                                               '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                                               '_ANNOTATION_SMILES_' => undef,
                                                                               '_ANNOTATION_IN_POS_MODE_' => undef,
                                                                               '_PPM_ERROR_' => 0,
                                                                               '_INTENSITY_' => undef,
                                                                               '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                                               '_COMPUTED_MONOISOTOPIC_MASS_' => '118.086',
                                                                               '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                                               '_MMU_ERROR_' => '0.000',
                                                                               '_ANNOTATION_TYPE_' => undef,
                                                                               '_ANNOTATION_FORMULA_' => undef,
                                                                               '_SPECTRA_ID_' => undef,
                                                                               '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                                               '_RELATIVE_INTENSITY_999_' => undef,
                                                                               '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                                               '_ID_' => undef,
                                                                               '_ANNOTATIONS_' => []
                                                                             }, 'Metabolomics::Banks' ),
                                                                      bless( {
                                                                               '_SPECTRA_ID_' => undef,
                                                                               '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                                               '_ANNOTATION_TYPE_' => undef,
                                                                               '_ANNOTATION_FORMULA_' => undef,
                                                                               '_ANNOTATIONS_' => [],
                                                                               '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                                               '_ID_' => undef,
                                                                               '_RELATIVE_INTENSITY_999_' => undef,
                                                                               '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                                               '_ANNOTATION_SMILES_' => undef,
                                                                               '_ANNOTATION_INCHIKEY_' => undef,
                                                                               '_ANNOTATION_NAME_' => 'D-valine',
                                                                               '_ANNOTATION_ONLY_IN_' => undef,
                                                                               '_CLUSTER_ID_' => undef,
                                                                               '_RELATIVE_INTENSITY_100_' => undef,
                                                                               '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                                               '_MMU_ERROR_' => '0.001',
                                                                               '_COMPUTED_MONOISOTOPIC_MASS_' => '118.087',
                                                                               '_INTENSITY_' => undef,
                                                                               '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                                               '_ANNOTATION_IN_POS_MODE_' => undef,
                                                                               '_PPM_ERROR_' => '8.5'
                                                                             }, 'Metabolomics::Banks' )
                                                               ]
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '119.086',
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ID_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0
                                               }, 'Metabolomics::Banks' )
                                      ],
                 '_EXP_PEAK_LIST_ALL_ANNOTATIONS_' => [
                                                        bless( {
                                                                 '_CLUSTER_ID_' => undef,
                                                                 '_PPM_ERROR_' => 0,
                                                                 '_MMU_ERROR_' => '0.000',
                                                                 '_SPECTRA_ID_' => undef,
                                                                 '_ANNOTATIONS_' => [],
                                                                 '_ANNOTATION_FORMULA_' => undef,
                                                                 '_ID_' => undef,
                                                                 '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                                 '_RELATIVE_INTENSITY_100_' => undef,
                                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                                 '_ANNOTATION_NAME_' => 'L-valine',
                                                                 '_ANNOTATION_SMILES_' => undef,
                                                                 '_INTENSITY_' => undef,
                                                                 '_RELATIVE_INTENSITY_999_' => undef,
                                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                                 '_ANNOTATION_INCHIKEY_' => undef,
                                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                                 '_ANNOTATION_TYPE_' => undef,
                                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '118.086'
                                                               }, 'Metabolomics::Banks' ),
                                                        bless( {
                                                                 '_ANNOTATION_INCHIKEY_' => undef,
                                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '118.087',
                                                                 '_ANNOTATION_TYPE_' => undef,
                                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                                 '_ANNOTATION_SMILES_' => undef,
                                                                 '_RELATIVE_INTENSITY_999_' => undef,
                                                                 '_INTENSITY_' => undef,
                                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                                 '_RELATIVE_INTENSITY_100_' => undef,
                                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                                 '_ANNOTATION_NAME_' => 'D-valine',
                                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                                 '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                                 '_ID_' => undef,
                                                                 '_MMU_ERROR_' => '0.001',
                                                                 '_SPECTRA_ID_' => undef,
                                                                 '_PPM_ERROR_' => '8.5',
                                                                 '_ANNOTATION_FORMULA_' => undef,
                                                                 '_ANNOTATIONS_' => [],
                                                                 '_CLUSTER_ID_' => undef
                                                               }, 'Metabolomics::Banks' ),
                                                        bless( {
                                                                 '_CLUSTER_ID_' => undef,
                                                                 '_ANNOTATIONS_' => [],
                                                                 '_ANNOTATION_FORMULA_' => undef,
                                                                 '_MMU_ERROR_' => 0,
                                                                 '_SPECTRA_ID_' => undef,
                                                                 '_PPM_ERROR_' => 0,
                                                                 '_ID_' => undef,
                                                                 '_ANNOTATION_SPECTRAL_IDS_' => [],
                                                                 '_ANNOTATION_NAME_' => undef,
                                                                 '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                                 '_RELATIVE_INTENSITY_100_' => undef,
                                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                                 '_INTENSITY_' => undef,
                                                                 '_RELATIVE_INTENSITY_999_' => undef,
                                                                 '_ANNOTATION_SMILES_' => undef,
                                                                 '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                                 '_ANNOTATION_TYPE_' => undef,
                                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                                 '_ANNOTATION_INCHIKEY_' => undef,
                                                                 '_MESURED_MONOISOTOPIC_MASS_' => '119.086'
                                                               }, 'Metabolomics::Banks' )
                                                      ]
               }, 'Metabolomics::Fragment::Annotation' ),
	## MSG
		'Method \'compareExpMzToTheoMzListAllMatches\' works with peak list file and BloodExposome db content');	

#########################	
	print "\n** Test $current_test writeTabularWithPeakBankObject **\n" ; $current_test++;
	is_deeply( writeTabularWithPeakBankObjectTest(
		bless( {
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ID_' => 'CON00001',
                                                  '_ANNOTATION_IN_NEG_MODE_' => '[M-H]-',
                                                  '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '60.02113'
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_FRAGMENTS_' => [],
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '178.9942',
                                                 '_PPM_ERROR_' => 0,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '156.0351',
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '128.9587',
                                                 '_PPM_ERROR_' => 0
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.9756',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '60.02425',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '60.02113',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_PPM_ERROR_' => '52',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                 '_MMU_ERROR_' => '0.00312',
                                                 '_ANNOTATION_TYPE_' => 'Solvent',
                                                 '_ID_' => 'CON00001'
                                               }, 'Metabolomics::Banks' )
                                      ]
               }, 'Metabolomics::Fragment::Annotation' ),
		$modulePath.'/_template.tabular',
		$modulePath.'/test.tabular'),
		$modulePath.'/test.tabular',
		'Method \'writeTabularWithPeakBankObject\' works with a bank and tabular template');
		
#########################	
	print "\n** Test $current_test writeFullTabularWithPeakBankObject **\n" ; $current_test++;
	is_deeply( writeFullTabularWithPeakBankObjectTest( 
		bless( {
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '60.02113',
                                                  '_ANNOTATION_IN_NEG_MODE_' => '[M-H]-',
                                                  '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                  '_ID_' => 'CON00001',
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_FRAGMENTS_' => [],
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '178.9942',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '156.0351'
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '128.9587',
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.9756',
                                                 '_ANNOTATION_TYPE_' => undef
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '60.02113',
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '60.05425',
                                                 '_MMU_ERROR_' => '0.03312',
                                                 '_ANNOTATION_TYPE_' => 'Solvent',
                                                 '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                 '_ID_' => 'CON00001',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_PPM_ERROR_' => 552,
                                               }, 'Metabolomics::Banks' )
                                      ]
               }, 'Metabolomics::Fragment::Annotation' ),
        $modulePath.'/in_test01_pos.tabular',
		$modulePath.'/_template.tabular',
		$modulePath.'/out_test01.tabular'),
		$modulePath.'/out_test01.tabular',
		'Method \'writeFullTabularWithPeakBankObject\' works with a bank and tabular template');
		
		
		
#########################	
	print "\n** Test $current_test writeFullTabularWithPeakBankObject with multi annot **\n" ; $current_test++;
	is_deeply( writeFullTabularWithPeakBankObjectWithMultiAnnotTest(
		bless( {
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '60.02113',
                                                  '_ANNOTATION_IN_NEG_MODE_' => '[M-H]-',
                                                  '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                  '_ID_' => 'CON00001',
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_FRAGMENTS_' => [],
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '178.9942',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATIONS_' => []
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '156.0351',
                                                 '_ANNOTATIONS_' => []
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '128.9587',
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATIONS_' => []
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.9756',
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATIONS_' => []
                                               }, 'Metabolomics::Banks' ),
                                        bless( {
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '60.02113',
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '60.05425',
                                                 '_MMU_ERROR_' => '0.03312',
                                                 '_ANNOTATION_TYPE_' => 'Solvent',
                                                 '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                 '_ID_' => 'CON00001',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_PPM_ERROR_' => 552,
                                                 '_ANNOTATIONS_' => [
                                                 		bless( {
                                                                               '_COMPUTED_MONOISOTOPIC_MASS_' => '118.086',
                                                                               '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                                               '_MMU_ERROR_' => '0.000',
                                                                               '_ANNOTATION_FORMULA_' => undef,
                                                                               '_PPM_ERROR_' => 0,
                                                                               '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                                               '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                                               '_ID_' => undef,
                                                                               '_ANNOTATION_TYPE_' => undef,
                                                                               '_ANNOTATION_INCHIKEY_' => undef,
                                                                               '_SPECTRA_ID_' => undef,
                                                                               '_ANNOTATION_ONLY_IN_' => undef,
                                                                               '_ANNOTATIONS_' => [],
                                                                               '_ANNOTATION_NAME_' => 'L-valine',
                                                                               '_ANNOTATION_IN_POS_MODE_' => undef,
                                                                               '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                                               '_ANNOTATION_SMILES_' => undef
                                                                             }, 'Metabolomics::Banks' ),
                                                                      bless( {
                                                                               '_SPECTRA_ID_' => undef,
                                                                               '_ANNOTATION_INCHIKEY_' => undef,
                                                                               '_ANNOTATION_ONLY_IN_' => undef,
                                                                               '_ANNOTATION_NAME_' => 'D-valine',
                                                                               '_ANNOTATIONS_' => [],
                                                                               '_ID_' => undef,
                                                                               '_ANNOTATION_TYPE_' => undef,
                                                                               '_ANNOTATION_SMILES_' => undef,
                                                                               '_ANNOTATION_IN_POS_MODE_' => undef,
                                                                               '_ANNOTATION_IS_A_PRECURSOR_' => undef,
                                                                               '_ANNOTATION_IS_A_METABOLITE_' => undef,
                                                                               '_COMPUTED_MONOISOTOPIC_MASS_' => '118.087',
                                                                               '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                                               '_MESURED_MONOISOTOPIC_MASS_' => '118.086',
                                                                               '_MMU_ERROR_' => '0.001',
                                                                               '_ANNOTATION_FORMULA_' => undef,
                                                                               '_PPM_ERROR_' => '8.5'
                                                                             }, 'Metabolomics::Banks' )
                                                 
                                                 
                                                 ]
                                               }, 'Metabolomics::Banks' )
                                      ]
               }, 'Metabolomics::Fragment::Annotation' ),
        $modulePath.'/in_test01_pos.tabular',
		$modulePath.'/_template.tabular',
		$modulePath.'/out_test01.tabular',
		'FALSE'),
		$modulePath.'/out_test01.tabular',
		'Method \'writeFullTabularWithPeakBankObject\' works with a bank and tabular template in multi mode');		
## #################################################################################################################################
##
#########################	######################### Full Analysis FOR Ab Initio Frag db #########################  ###############
##
####################################################################################################################################
	
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST( 	
		$modulePath.'/Cmpd_16_RFDAIACWWDREDC-FRVQLJSFSA-N_Glycocholic_acid__RT__=11.72.csv',
		2, ## mz
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		465.3090381,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'FALSE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/Cmpd_16_RFDAIACWWDREDC-FRVQLJSFSA-N_Glycocholic_acid__RT__=11.72__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/Cmpd_16_RFDAIACWWDREDC-FRVQLJSFSA-N_Glycocholic_acid__RT__=11.72__ANNOTATED__.HTML',
		),
		$modulePath.'/Cmpd_16_RFDAIACWWDREDC-FRVQLJSFSA-N_Glycocholic_acid__RT__=11.72__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on Glycocholic acid example with CSV input');

#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST( 	
		$modulePath.'/Cmpd_1_DCXYFEDJOCDNAF-REOHCLBHSA-N_Asparagine__RT__=0.83.csv',
		2, ## mz
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		132.0534921,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'FALSE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/Cmpd_1_DCXYFEDJOCDNAF-REOHCLBHSA-N_Asparagine__RT__=0.83__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/Cmpd_1_DCXYFEDJOCDNAF-REOHCLBHSA-N_Asparagine__RT__=0.83__ANNOTATED__.HTML',
		),
		$modulePath.'/Cmpd_1_DCXYFEDJOCDNAF-REOHCLBHSA-N_Asparagine__RT__=0.83__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on Asparagine example with CSV input');
		
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST( 	
		$modulePath.'/Cmpd_2_BTCSSZJGUNDROE-UHFFFAOYSA-N_gamma-aminobutyric_acid__RT__=0.86.csv',
		2, ## mz
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		103.0633285,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'FALSE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/Cmpd_2_BTCSSZJGUNDROE-UHFFFAOYSA-N_gamma-aminobutyric_acid__RT__=0.86__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/Cmpd_2_BTCSSZJGUNDROE-UHFFFAOYSA-N_gamma-aminobutyric_acid__RT__=0.86__ANNOTATED__.HTML',
		),
		$modulePath.'/Cmpd_2_BTCSSZJGUNDROE-UHFFFAOYSA-N_gamma-aminobutyric_acid__RT__=0.86__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on gamma-aminobutyric acid example with CSV input');

#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST( 	
		$modulePath.'/Cmpd_13_QIAFMBKCNZACKA-UHFFFAOYSA-N_Hippuric_acid__RT__=8.27.csv',
		2, ## mz
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		179.0582432,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'FALSE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/Cmpd_13_QIAFMBKCNZACKA-UHFFFAOYSA-N_Hippuric_acid__RT__=8.27__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/Cmpd_13_QIAFMBKCNZACKA-UHFFFAOYSA-N_Hippuric_acid__RT__=8.27__ANNOTATED__.HTML',
		),
		$modulePath.'/Cmpd_13_QIAFMBKCNZACKA-UHFFFAOYSA-N_Hippuric_acid__RT__=8.27__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on Hippuric acid example with CSV input');

#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST( 	
		$modulePath.'/Cmpd_10_LRFVTYWOQMYALW-UHFFFAOYSA-N_Xanthine__RT__=1.85.csv',
		2, ## mz
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		152.0334254,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'FALSE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/Cmpd_10_LRFVTYWOQMYALW-UHFFFAOYSA-N_Xanthine__RT__=1.85__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/Cmpd_10_LRFVTYWOQMYALW-UHFFFAOYSA-N_Xanthine__RT__=1.85__ANNOTATED__.HTML',
		),
		$modulePath.'/Cmpd_10_LRFVTYWOQMYALW-UHFFFAOYSA-N_Xanthine__RT__=1.85__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on Xanthine example with CSV input');
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST( 	
		$modulePath.'/Cmpd_7_RDHQFKQIGNGIED-MRVPVSSYSA-N_Acetyl-L-carnitin__RT__=1.18.csv',
		2, ## mz
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		203.11576,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'FALSE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/Cmpd_7_RDHQFKQIGNGIED-MRVPVSSYSA-N_Acetyl-L-carnitin__RT__=1.18__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/Cmpd_7_RDHQFKQIGNGIED-MRVPVSSYSA-N_Acetyl-L-carnitin__RT__=1.18__ANNOTATED__.HTML',
		),
		$modulePath.'/Cmpd_7_RDHQFKQIGNGIED-MRVPVSSYSA-N_Acetyl-L-carnitin__RT__=1.18__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on Acetyl-L-carnitin example with CSV input');

			
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST( 	
		$modulePath.'/cpd-val-pro.TSV',
		1, 
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		214.1317,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'TRUE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/cpd-val-pro__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/cpd-val-pro__ANNOTATED__.HTML',
		),
		$modulePath.'/cpd-val-pro__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on val-pro example');
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146.TSV',
		2, 
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		298.1146,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'TRUE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146__ANNOTATED__.HTML',
		),
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on a Methylguanosine example');
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis on PeakForest Data with a positively charged methylguanosine**\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/pfs002787+.tsv',
		1, 
		5, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		298.11460,
		'POSITIVE', #mode
		'POSITIVE', #stateMolecule
		'TRUE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/pfs002787+__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/pfs002787+__ANNOTATED__.HTML',
		),
		$modulePath.'/pfs002787+__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on PeakForest Data with a positively charged methylguanosine');
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis on PeakForest Data with with a dipeptide (PRO-LEU)e**\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/pfs003129.tsv',
		1, 
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		228.14739251,
		'NEGATIVE', #mode
		'NEUTRAL', #stateMolecule
		'TRUE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/pfs003129__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/pfs003129__ANNOTATED__.HTML',
		),
		$modulePath.'/pfs003129__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on PeakForest Data with a dipeptide (PRO-LEU)');
		
	
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis on PeakForest Data with L-prolyl-L-glycine (CEA)**\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/pfs003731.tsv',
		1, 
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		172.084792254,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'TRUE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/pfs003731__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/pfs003731__ANNOTATED__.HTML',
		),
		$modulePath.'/pfs003731__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on PeakForest Data with L-prolyl-L-glycine (CEA)');
		

#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis on PeakForest Data with L-prolyl-L-glycine (TOXALIM)**\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/pfs007110.tsv',
		1,
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		172.084792254,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'TRUE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/pfs007110__ANNOTATED__.TSV',
		$modulePath.'/_template_db_frag_peaks.tmpl',
		$modulePath.'/pfs007110__ANNOTATED__.HTML',
		),
		$modulePath.'/pfs007110__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on PeakForest Data with L-prolyl-L-glycine (TOXALIM)');



	
#########################	
	print "\n** Test $current_test fullCompare_ExpComplexPeakListFromBruker_And_AbInitioFragmentBank_FromDataAnalysis_TEST **\n" ; $current_test++;
	is_deeply( fullCompare_ExpComplexPeakListFromBruker_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		# ($expFile, $mzCol, $intCol, $delta, $theoFile, $mzParent, $mode, $stateMolecule, $isotopicDetection, $template, $tabular) 	
		$modulePath.'/Cmpd_16_RFDAIACWWDREDC-FRVQLJSFSA-N_Glycocholic_acid__RT__=11.72.csv',
		2,	## mz
		4,  ##  i
		10, #ppm
		$modulePath.'/MS_fragments-adducts-isotopes__V1.1.txt',
		465.3090381,
		'POSITIVE', #mode
		'NEUTRAL', #stateMolecule
		'FALSE',
		$modulePath.'/_template_pforest_peaklist_lcms.tmpl',
		$modulePath.'/Cmpd_16_RFDAIACWWDREDC-FRVQLJSFSA-N_Glycocholic_acid__RT__=11.72__ANNOTATED__.TSV'
		),
		$modulePath.'/_template_pforest_peaklist_lcms.tmpl',
		'Method \'fullCompare_ExpComplexPeakListFromBruker_And_AbInitioFragmentBank_FromDataAnalysis_TEST\' works on Glycocholic acid example with SPECIFIC PEAKFOREST CSV input');

## #################################################################################################################################
##
#########################	######################### Full Analysis FOR MaConDa db #########################  ###############
##
####################################################################################################################################

#########################	

	print "\n** Test $current_test fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis **\n" ; $current_test++ ;
	is_deeply( fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis_TEST (
		# my ($expFile, $col, $delta, $queryMode, $template, $tabular) - - using MaConDa extension database from metabolomics-references by defaut
		$modulePath.'/in_test02_pos.tabular',
		2, 
		5,
		'ION',
		'POSITIVE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/in_test02_pos__CONTAMINANTS_ANNOTATED__.TSV',
		$modulePath.'/_template_db_met_peaks.tmpl',
		$modulePath.'/in_test02_pos__CONTAMINANTS_ANNOTATED__.HTML',
		),
		## Expected:
		$modulePath.'/in_test02_pos__CONTAMINANTS_ANNOTATED__.TSV',
		## MSG
		'Method \'fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis\' works with a MaConDa bank and tabular example');



## #################################################################################################################################
##
#########################	######################### Full Analysis FOR Blood exposome db #########################  ###############
##
####################################################################################################################################

#########################	

	print "\n** Test $current_test fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis_TEST(
		# my ($expFile, $col, $delta, $source, $ionMode, $template, $tabular, $htmltemplate, $htmlout)
		$modulePath.'/in_test01_pos.tabular',
		2, 
		5,
		$modulePath.'/BloodExposome_v1_0_part.txt',
		'POSITIVE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/in_test01_pos__BLOODEXP_ANNOTATED__.TSV',
		$modulePath.'/_template_db_met_peaks.tmpl',
		$modulePath.'/in_test01_pos__BLOODEXP_ANNOTATED__.HTML',
		),
		$modulePath.'/in_test01_pos__BLOODEXP_ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis\' works with a bank and tabular template');


#########################	

	print "\n** Test $current_test fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis_TEST(
		# my ($expFile, $col, $delta, $source, $ionMode, $template, $tabular, $htmltemplate, $htmlout)
		$modulePath.'/in_test02_pos.tabular',
		2, 
		5,
		$modulePath.'/BloodExposome_v1_0_part.txt',
		'POSITIVE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/in_test02_pos__BLOODEXP_ANNOTATED__.TSV',
		$modulePath.'/_template_db_met_peaks.tmpl',
		$modulePath.'/in_test02_pos__BLOODEXP_ANNOTATED__.HTML',
		),
		$modulePath.'/in_test02_pos__BLOODEXP_ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis\' works with a bank and tabular template');
		
## #################################################################################################################################
##
#########################	######################### Full Analysis FOR Knapsack db 	  #########################  ###############
##
####################################################################################################################################

#########################	

	print "\n** Test $current_test fullCompare_ExpPeakList_And_TheoKnapSackBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_TheoKnapSackBank_FromDataAnalysis_TEST(
		# my ($expFile, $col, $delta, $source, $ionMode, $template, $tabular, $htmltemplate, $htmlout)
		$modulePath.'/in_test02_pos.tabular',
		2, 
		5,
		$modulePath.'/Knapsack__dump.csv',
		'POSITIVE',
		$modulePath.'/_template_v2.tabular',
		$modulePath.'/in_test02_pos__KNAPSACK_ANNOTATED__.TSV',
		$modulePath.'/_template_db_met_peaks.tmpl',
		$modulePath.'/in_test02_pos__KNAPSACK_ANNOTATED__.HTML',
		),
		$modulePath.'/in_test02_pos__KNAPSACK_ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_TheoKnapSackBank_FromDataAnalysis\' works with a bank and tabular template');

## #################################################################################################################################
##
#########################	######################### Full Analysis FOR PhytoHUB db 	  #########################  ###############
##
####################################################################################################################################

#########################	

	print "\n** Test $current_test fullCompare_ExpPeakList_And_TheoPhytoHubBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_TheoPhytoHubBank_FromDataAnalysis_TEST(
		# my ($expFile, $col, $delta, $source, $ionMode, $template, $tabular, $htmltemplate, $htmlout)
		$modulePath.'/in_test03_pos.tabular',
		2, 
		5,
		$modulePath.'/PhytoHUB__dump.tsv',
		'POSITIVE',
		$modulePath.'/_template-phytohub.tabular',
		$modulePath.'/in_test03_pos__PHYTOHUB_ANNOTATED__.TSV',
		$modulePath.'/_template_db_met_peaks.tmpl',
		$modulePath.'/in_test03_pos__PHYTOHUB_ANNOTATED__.HTML',
		),
		$modulePath.'/in_test03_pos__PHYTOHUB_ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_TheoPhytoHubBank_FromDataAnalysis\' works with a bank and tabular template');
		
## #################################################################################################################################
##
#########################	######################### Full Analysis FOR PeakForest db 	  #########################  ###############
##
####################################################################################################################################

#########################	

#	print "\n** Test $current_test fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2 **\n" ; $current_test++;
#	is_deeply( fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2_TEST(
#		# $expFile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds, $delta, $url, $token, $polarity, $resolution, $column_code, $template, $tabular
#		$modulePath.'/input_gcms_fake_clusters.tabular',
#		'TRUE',
#		2, 
#		21,
#		13,
#		0.05, ##PPM
#		'MMU',
#		'https://metabohub.peakforest.org/rest/v2/',
#		undef, # url card
#		'2big17k7a871tfatk1b4cm8pr7',
#		'POSITIVE',
#		'high',
#		undef,
#		$modulePath.'/_template-peakforest.tabular',
#		$modulePath.'/in_testGCMS_pos__PEAKFOREST_ANNOTATED__.TSV',
#		$modulePath.'/_template_db_spectra.tmpl',
#		$modulePath.'/in_testGCMS_pos__PEAKFOREST_ANNOTATED__.HTML',
#		),
#		## Expected
#		$modulePath.'/in_testGCMS_pos__PEAKFOREST_ANNOTATED__.TSV',
#		## Answer
#		'Method \'fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2\' works with a bank and tabular template');

#	print "\n** Test $current_test fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2 with Lab data **\n" ; $current_test++;
#	is_deeply( fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2_TEST(
#		# $expFile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds, $delta, $url, $token, $polarity, $resolution, $column_code, $template, $tabular
#		$modulePath.'/ASM0683_VariableMetaData.TSV',
#		'TRUE',
#		3, 
#		22,
#		14,
#		0.05, ## DA
#		'MMU',
#		'https://pfem.peakforest.org/rest/v2/',
#		'https://pfem.peakforest.org/webapp/home?PFc=',
#		'ta8j54uq85k00hi9qrnrrghgei',
#		'POSITIVE',
#		'high',
#		undef,
#		$modulePath.'/_template-peakforest.tabular',
#		$modulePath.'/ASM0683_VariableMetaData__PEAKFOREST_ANNOTATED__.TSV',
#		$modulePath.'/_template_db_spectra.tmpl',
#		$modulePath.'/ASM0683_VariableMetaData__PEAKFOREST_ANNOTATED__.HTML',
#		),
#		## Expected
#		$modulePath.'/ASM0683_VariableMetaData__PEAKFOREST_ANNOTATED__.TSV',
#		## Answer
#		'Method \'fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2\' works with a bank and tabular template');

#########################	

	print "\n** Test $current_test computeScorePairedPeaksIntensitiesPearsonCorrelation **\n" ; $current_test++;
	is_deeply( computeScorePairedPeaksIntensitiesPearsonCorrelation_TEST(
	[
		[1,1], [2,2], [3,3], [10,10], [100.1, 100.1]
	]
	),
	## Expected
	"1.000", # r
	## Answer
	'Method \'computeScorePairedPeaksIntensitiesPearsonCorrelation\' works and return the right r');
	
#########################	

	print "\n** Test $current_test computeScorePairedPeaksIntensitiesPearsonCorrelation **\n" ; $current_test++;
	is_deeply( computeScorePairedPeaksIntensitiesPearsonCorrelation_TEST(
	# validation based on hmdb page: https://hmdb.ca/spectra/c_ms/search?utf8=%E2%9C%93&peaks=70+54%0D%0A71+63%0D%0A72+296%0D%0A77+86%0D%0A81+260%0D%0A87+87%0D%0A88+240%0D%0A89+128%0D%0A90+12%0D%0A101+73%0D%0A102+83%0D%0A103+348%0D%0A105+82%0D%0A106+11%0D%0A115+98%0D%0A117+295%0D%0A118+32%0D%0A119+78%0D%0A121+11%0D%0A133+737%0D%0A134+94%0D%0A135+46%0D%0A145+14%0D%0A150+66%0D%0A151+18%0D%0A161+403%0D%0A175+9%0D%0A177+1000%0D%0A178+183%0D%0A179+81%0D%0A180+8%0D%0A207+51&mass_charge_tolerence=0.1&commit=Search
	[	
		[5.4,5.4],[6.3,6.3],[29.6,29.6],[0,6.5],[26,26],[0,2.2],[0,1.9],[8.7,8.7],[24,24],[12.8,12.8],[1.2,1.2],[0,4.2],[0,2.6],[7.4,7.4],[8.3,8.3],[34.8,34.8],[0,4],[8.2,8.2],[1.1,1.1],[0,4],[9.8,9.8],[0,9],[29.5,29.5],[3.2,3.2],[7.8,7.8],[1.1,1.1],[0,32.2],[0,6.5],[73.7,73.7],[9.4,9.4],[4.6,4.6],[1.4,1.4],[6.6,6.6],[1.8,1.8],[40.3,40.3],[0,6.6],[0,3.1],[0.9,0.9],[100,100],[18.3,18.3],[8.1,8.1],[0.8,0.8],[0,2.9],[0,59.7],[0,10.4],[5.1,5.1]
	]
	),
	## Expected
	"0.874", # r (diff with hmdb - 0.86)
	## Answer
	'Method \'computeScorePairedPeaksIntensitiesPearsonCorrelation\' works and return the right r');

## #################################################################################################################################
##
#########################	######################### 		ALL SUB TESTS		 #########################  ########################
##
####################################################################################################################################

##
#########################	######################### 	private methods unit TESTS SUB	 #########################  ####################
##

	## SUB TEST for 
	sub _mapPeakListWithTemplateFields_TEST {
	    # get values
	    my ( $fields, $peakList  ) = @_;
	    
	    my $rows = Metabolomics::Fragment::Annotation::_mapPeakListWithTemplateFields($fields, $peakList) ;
#	    print Dumper $rows ;
	    
	    return($rows) ;
	}
	## End SUB




##
#########################	######################### 	generic Analysis TESTS SUB	 #########################  ####################
##
	
	sub compareExpMzToTheoMzListTest {
		my ( $oBank, $deltaType, $deltaValue ) = @_ ;
		
		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;

		$oAnalysis->compareExpMzToTheoMzList($deltaType, $deltaValue) ;
#		print Dumper $oAnalysis ;
		
		return ($oAnalysis) ;
	}
	
	
	sub compareExpMzToTheoMzListAllMatchesTest {
		my ( $oBank, $deltaType, $deltaValue ) = @_ ;
		
		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;

		$oAnalysis->compareExpMzToTheoMzListAllMatches($deltaType, $deltaValue) ;
#		print Dumper $oAnalysis ;

		return ($oAnalysis) ;
	}
	
	## sub writeTabularWithPeakBankObjectTest
	sub writeTabularWithPeakBankObjectTest {
		# get values
	    my ( $oBank, $template, $tabular ) = @_;
	    my $tabularfile = $oBank->writeTabularWithPeakBankObject($template, $tabular) ;
	    
		return($tabularfile) ;
	}
	## End SUB
	
	## sub writeTabularWithPeakBankObjectTest
	sub writeFullTabularWithPeakBankObjectTest {
		# get values
	    my ( $oBank, $inputTabular, $template, $tabular ) = @_;
	    my $tabularfile = $oBank->writeFullTabularWithPeakBankObject($inputTabular, $template, $tabular) ;
		return($tabularfile) ;
	}
	## End SUB
	
	## sub writeTabularWithPeakBankObjectTest
	sub writeFullTabularWithPeakBankObjectWithMultiAnnotTest {
		# get values
	    my ( $oBank, $inputTabular, $template, $tabular, $bestHit ) = @_;
	    my $tabularfile = $oBank->writeFullTabularWithPeakBankObject($inputTabular, $template, $tabular, $bestHit) ;
		return($tabularfile) ;
	}
	## End SUB

##
#########################	######################### 	full Analysis TESTS SUB	 #########################  ####################
##

##
#########################	######################### 	AB INITIO FRAG DB TESTS SUB	 #########################  ####################
##

	## sub fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis
	sub fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $col, $delta, $theoFile, $mzParent, $mode, $stateMolecule, $isotopicDetection, $template, $tabular, $templateHTML, $htmlFile) = @_ ;
		
		my $oBank = Metabolomics::Banks::AbInitioFragments->new(  { POLARITY => $mode, }  ) ;
#		print Dumper $oBank ;
		
		$oBank->getFragmentsFromSource($theoFile) ;
#		print Dumper $oBank ;
		
		my $nb = $oBank->buildTheoPeakBankFromFragments($mzParent, $mode, $stateMolecule, $isotopicDetection) ;
#		print Dumper $oBank ;

		$oBank->buildTheoDimerFromMz($mzParent, $mode) ;
#		print Dumper $oBank ;

		if ($isotopicDetection eq 'TRUE') {
			$oBank->isotopicAdvancedCalculation($mode) ;
		}
		
		$oBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm 2
		
		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;

#		$oAnalysis->compareExpMzToTheoMzList('PPM', $delta) ;
		$oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ;
		
		my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ;
		
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ;
		
		my $HtmlOuput = $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile ) ;
		
		return($tabularFullfile) ;	
	}

	## sub fullCompare_ExpComplexPeakListFromBruker_And_AbInitioFragmentBank_FromDataAnalysis_TEST
	sub fullCompare_ExpComplexPeakListFromBruker_And_AbInitioFragmentBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $mzCol, $intCol, $delta, $theoFile, $mzParent, $mode, $stateMolecule, $isotopicDetection, $template, $tabular) = @_ ;
		
		my $oBank = Metabolomics::Banks::AbInitioFragments->new(  { POLARITY => $mode, }  ) ;
#		print Dumper $oBank ;
		
		$oBank->getFragmentsFromSource($theoFile) ;
#		print Dumper $oBank ;
		
		my $nb = $oBank->buildTheoPeakBankFromFragments($mzParent, $mode, $stateMolecule, $isotopicDetection) ;
#		print Dumper $oBank ;

		$oBank->buildTheoDimerFromMz($mzParent, $mode) ;
#		print Dumper $oBank ;

		if ($isotopicDetection eq 'TRUE') {
			$oBank->isotopicAdvancedCalculation($mode) ;
		}
		
		$oBank->parsingFeaturesFragments($expFile, 'asheader', [$mzCol, $intCol]) ; # get mz in colunm 2 and I in column 4
		
		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;

		$oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ;
		
		$oAnalysis->writePForestTabularWithPeakBankObject($template , $tabular.'.PFOREST', 'FALSE') ;
		
#		my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ;
#		
#		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ;
#		
#		my $HtmlOuput = $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile ) ;
		
		return($template) ;	
	}
##
#########################	######################### 	MACONDA TESTS SUB	 #########################  ####################
##
	## sub fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis
	sub fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $col, $delta, $queryMode, $IonMode, $template, $tabular, $templateHTML, $htmlFile) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new( { POLARITY => $IonMode, } ) ;
#		print Dumper $oBank ;
		
		$oBank->getContaminantsExtensiveFromSource() ;
#		print Dumper $oBank ;
		
		my $oNewBank = $oBank->filterContaminantIonMode($IonMode) ;
#		print Dumper $oNewBank ;
		
		$oNewBank->buildTheoPeakBankFromContaminants($queryMode) ; #ION | NEUTRAL
#		print Dumper $oNewBank ;
		
		$oNewBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm 2
#		print Dumper $oNewBank ;

		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oNewBank) ;
#		print Dumper $oAnalysis ;

#		$oAnalysis->compareExpMzToTheoMzList('PPM', $delta) ;
		$oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ;
#		print Dumper $oAnalysis ;
		
		my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ;
		
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ;
		
		my $HtmlOuput = $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile ) ;
				
		return($tabularFullfile) ;	
	}	
##
#########################	######################### 	BLOOD EXPOSOME TESTS SUB	 #########################  ####################
##

	## sub fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysis
	sub fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $col, $delta, $source, $IonMode, $template, $tabular, $templateHTML, $htmlFile) = @_ ;
				
		my $oBank = Metabolomics::Banks::BloodExposome->new( { POLARITY => $IonMode, } ) ;
#		print Dumper $oBank ;

	    $oBank->getMetabolitesFromSource($source) ;
#	    print Dumper $oBank ;

	    my $nb = $oBank->buildTheoPeakBankFromEntries($IonMode) ;
#	    print Dumper $oBank ;

		$oBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm 2
#		print Dumper $oBank ;

		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;
#		print Dumper $oAnalysis ;

#		$oAnalysis->compareExpMzToTheoMzList('PPM', $delta) ;
		$oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ;
#		print Dumper $oAnalysis ;
		
		my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ;
		
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ;
		
		my $HtmlOuput = $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile ) ;
		
		return($tabularFullfile) ;		
	}
	
##
#########################	######################### 	KNAPSACK TESTS SUB	 #########################  ####################
##

	## sub fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysis
	sub fullCompare_ExpPeakList_And_TheoKnapSackBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $col, $delta, $source, $IonMode, $template, $tabular, $templateHTML, $htmlFile ) = @_ ;
				
		my $oBank = Metabolomics::Banks::Knapsack->new( { POLARITY => $IonMode, } ) ;
#		print Dumper $oBank ;

	    $oBank->getKSMetabolitesFromSource($source) ;
#	    print Dumper $oBank ;

	    my $nb = $oBank->buildTheoPeakBankFromKnapsack($IonMode) ;
#	    print Dumper $oBank ;

		$oBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm 2
#		print Dumper $oBank ;

		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;
#		print Dumper $oAnalysis ;

#		$oAnalysis->compareExpMzToTheoMzList('PPM', $delta) ;		
		$oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ;
#		print Dumper $oAnalysis ;
		
		my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ;
		
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ;
		
		my $HtmlOuput = $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile ) ;
		
		return($tabularFullfile) ;		
	}
	
##
#########################	######################### 	PHYTOHUB TESTS SUB	 #########################  ####################
##

	## sub fullCompare_ExpPeakList_And_TheoPhytoHubBank_FromDataAnalysis
	sub fullCompare_ExpPeakList_And_TheoPhytoHubBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $col, $delta, $source, $IonMode, $template, $tabular, $templateHTML, $htmlFile) = @_ ;
				
		my $oBank = Metabolomics::Banks::PhytoHub->new( { POLARITY => $IonMode, } ) ;
#		print Dumper $oBank ;

	    $oBank->getMetabolitesFromSource($source) ;
#	    print Dumper $oBank ;

	    my $nb = $oBank->buildTheoPeakBankFromPhytoHub($IonMode) ;
#	    print Dumper $oBank ;

		$oBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm 2
#		print Dumper $oBank ;

		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;
#		print Dumper $oAnalysis ;

#		$oAnalysis->compareExpMzToTheoMzList('PPM', $delta) ;
		my $Annot = $oAnalysis->compareExpMzToTheoMzListAllMatches('PPM', $delta) ;
#		print Dumper $oAnalysis ;
		
		my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ;
		
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ;
		
		my $HtmlOuput = $oAnalysis->writeHtmlWithPeakBankObject($templateHTML, $htmlFile ) ;
		
		return($tabularFullfile) ;		
	}

##
#########################	######################### 	PEAKFOREST TESTS SUB REST V02	 #########################  ####################
##

	## sub fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2
	sub fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2_TEST {
		# get values
		my ($expFile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds, $delta, $deltaType, $url, $url_card, $token, $polarity, $resolution, $column_code, $template, $tabular, $templateHTML, $htmlFile) = @_ ;
		
		## sending REST API Query as:
		#curl "https://metabohub.peakforest.org/rest/v2//spectra-peakmatching/fullscan-gcms
		#?list_mz=73.047,326.1374,209.0996,311.1138,267.1236,179.0527,296.0901,327.139,
		#75.0283,312.1154,237.0763,252.0996,206.0395,268.1248,210.1015,163.0563,297.0925,
		#180.0547,74.0479,282.1464,149.0276,313.1125,162.049,193.0669,178.0475,140.5326,269.122,
		#207.0721,253.0987,298.0895,211.0984,148.0458,164.0618,238.0779,59.0309,177.0694,135.0316,
		#104.0612,161.0414,181.0517,147.0613,308.9579,283.1456,192.0596,77.031,89.0401,239.0739,
		#254.0968,91.0535,133.0215,221.0614,194.0696,306.9547,236.0826,76.0277,150.0389,78.0453,141.0336,
		#61.0109,165.0565,314.1131,103.0533,208.0612,105.0662,251.0901,105.0307,255.09,293.9343,270.1219,
		#284.1445,148.5454,58.0235,58.9949,151.0417,90.0452,131.0362,119.0829,299.0913,72.0386,117.0672,
		#195.0675,278.916,291.9319,107.0468,51.0226&token=XXX"
		
		my $oBank = Metabolomics::Banks::PeakForest->new(
			{	
	    		DATABASE_URL => $url,
	    		DATABASE_URL_CARD => $url_card,
	    		TOKEN => $token,
	    		POLARITY => $polarity,
	    		RESOLUTION => $resolution,
	    	}
		) ;

#		print Dumper $oBank ;
		# $oBank, $Xfile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds 
		$oBank->parsingMsFragmentsByCluster($expFile, $is_header, $col_Mzs, $col_Ints, $col_ClusterIds) ;
#		print Dumper $oBank ;
		
		# build pseudo spectra from 
		my $NbSpectra = $oBank->buildSpectralBankFromPeakForest($column_code, $deltaType, $delta, undef) ; ## Support ONLY MMU
#	    print Dumper $oBank ;
		
		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;
#		print Dumper $oAnalysis ;
		
#		$oAnalysis->compareExpMzToTheoMzList('PPM', $delta) ;
		$oAnalysis->compareExpMzToTheoMzListAllMatches($deltaType, $delta) ;
		
		my $scores = $oAnalysis->computeHrGcmsMatchingScores() ;
#		print Dumper $oAnalysis ;
		
		$oAnalysis->filterAnalysisSpectralAnnotationByScores($scores, '_SCORE_PEARSON_CORR_', "0.5") ; # _SCORE_PEARSON_CORR_
#		print Dumper $oAnalysis ;
#		print Dumper $scores ;
		
		my $tabularFullfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular, 'FALSE') ;
		
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular.'.SIMPLE', 'FALSE') ;
		
		my $HtmlOuput = $oAnalysis->writeHtmlWithSpectralBankObject($templateHTML, $htmlFile, $scores ) ;
		
		return($tabularFullfile) ;		
	}
	

	
	
	## sub fullCompare_GCMS_ExpPeakList_And_TheoPeakForestBank_FromDataAnalysis_V2
	sub computeScorePairedPeaksIntensitiesPearsonCorrelation_TEST {
		my ($matchingArrays) = @_ ;
		
		my $oUtils = Metabolomics::Utils->new() ;
		my $correlation = $oUtils->computeScorePairedPeaksIntensitiesPearsonCorrelation($matchingArrays) ;
		
#		print "r = $correlation\n" ;
		
		return($correlation) ;		
	}	
	
	
	
}## END BEGIN part







