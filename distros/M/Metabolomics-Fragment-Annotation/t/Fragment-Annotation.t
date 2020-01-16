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

use Test::More tests => 18 ;
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
        {
            '_ANNOTATION_FORMULA_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '85.02824868',
            '_PPM_ERROR_' => 0,
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_ANNOTATION_NAME_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA'
        },
		{
            '_ANNOTATION_FORMULA_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '993.9955766',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_ANNOTATION_NAME_' => 'NA',
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_PPM_ERROR_' => 0,
            '_ANNOTATION_TYPE_' => 'NA'
          },
          {
            '_ANNOTATION_FORMULA_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '994.245866',
            '_PPM_ERROR_' => 0,
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_ANNOTATION_NAME_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA'
          }
    ]
    ),
	## Expected	
		[
          {
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_ANNOTATION_FORMULA_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_ANNOTATION_NAME_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '85.02824868',
            '_PPM_ERROR_' => 0
          },
          {
            '_ANNOTATION_FORMULA_' => 'NA',
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_MESURED_MONOISOTOPIC_MASS_' => '993.9955766',
            '_PPM_ERROR_' => 0,
            '_ANNOTATION_NAME_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA'
          },
          {
            '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
            '_ANNOTATION_FORMULA_' => 'NA',
            '_ANNOTATION_NAME_' => 'NA',
            '_ANNOTATION_IN_POS_MODE_' => 'NA',
            '_ANNOTATION_TYPE_' => 'NA',
            '_ANNOTATION_IN_NEG_MODE_' => 'NA',
            '_MESURED_MONOISOTOPIC_MASS_' => '994.245866',
            '_PPM_ERROR_' => 0
          }
        ],
	## MSG
		'Method \'_mapPeakListWithTemplateFields\' maps well with a peak list and template fields content');
	
	
	
	
#########################	
	print "\n** Test $current_test compareExpMzToTheoMzList with Ab initio fragments bank**\n" ; $current_test++ ;
	is_deeply( compareExpMzToTheoMzListTest(
	## ARGTS
		bless( {
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
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
        'DA', 0.05),
	## Expected	
		bless( {
				 '_ANNOTATION_TOOL_' => 'mzBiH',
                 '_ANNOTATION_DB_SOURCE_' => 'Ab Initio Fragments',
                 '_ANNOTATION_TOOL_VERSION_' => '0.1',
                 '_ANNOTATION_DB_SOURCE_VERSION' => '1.0',
                 '_ANNOTATION_ION_MODE_' => 'annotation_ion_mode',
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '358.0524',
                                                 '_ANNOTATION_ONLY_IN_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '358.0924 ',
                                                 '_ID_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_PPM_ERROR_' => '111.703012965369',
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
                 '_ANNOTATION_DB_SOURCE_' => 'MaConDa',
                 '_ANNOTATION_DB_SOURCE_VERSION' => '1.0',
                 '_ANNOTATION_DB_SOURCE_' => 'mzBiH',
                 '_ANNOTATION_TOOL_VERSION_' => '0.1',
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
                                                 '_PPM_ERROR_' => '0.0979864278998716',
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
                 '_ANNOTATION_DB_SOURCE_VERSION' => undef,
                 '_ANNOTATION_DB_SOURCE_' => undef,
                 '_ANNOTATION_TOOL_VERSION_' => '0.1',
                 '_ANNOTATION_TOOL_' => 'mzBiH',
                 '_ANNOTATION_ION_MODE_' => 'annotation_ion_mode'
               }, 'Metabolomics::Fragment::Annotation' ),
	## MSG
		'Method \'compareExpMzToTheoMzList\' works with peak list file and Contaminant content');

########################	
	print "\n** Test $current_test compareExpMzToTheoMzList with BloodExposome db content**\n" ; $current_test++ ;
	is_deeply( compareExpMzToTheoMzListTest(
	## ARGTS
		bless( {
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_NAME_' => 'Blood Exposome',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
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
        'DA', 0.05),
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
                 '_ANNOTATION_DB_SOURCE_VERSION' => '1.0',
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
                 '_ANNOTATION_TOOL_' => 'mzBiH',
                 '_ANNOTATION_ION_MODE_' => 'annotation_ion_mode'
               }, 'Metabolomics::Fragment::Annotation' ),
	## MSG
		'Method \'compareExpMzToTheoMzList\' works with peak list file and BloodExposome db content');	


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
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '156.0351',
                                                 '_PPM_ERROR_' => 0,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '128.9587',
                                                 '_PPM_ERROR_' => 0
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.9756',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MMU_ERROR_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef
                                               }, 'Metabolomics::Fragment::Annotation' ),
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
                                               }, 'Metabolomics::Fragment::Annotation' )
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
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '156.0351'
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '128.9587',
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.9756',
                                                 '_ANNOTATION_TYPE_' => undef
                                               }, 'Metabolomics::Fragment::Annotation' ),
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
                                               }, 'Metabolomics::Fragment::Annotation' )
                                      ]
               }, 'Metabolomics::Fragment::Annotation' ),
        $modulePath.'/in_test01_pos.tabular',
		$modulePath.'/_template.tabular',
		$modulePath.'/out_test01.tabular'),
		$modulePath.'/out_test01.tabular',
		'Method \'writeFullTabularWithPeakBankObject\' works with a bank and tabular template');
		
## #################################################################################################################################
##
#########################	######################### Full Analysis FOR Ab Initio Frag db #########################  ###############
##
####################################################################################################################################
	
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST( 	
		$modulePath.'/cpd-val-pro.TSV',
		2, 
		0.05,
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		214.1317,
		$modulePath.'/_template.tabular',
		$modulePath.'/cpd-val-pro__ANNOTATED__.TSV'),
		$modulePath.'/cpd-val-pro__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on val-pro example');
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146.TSV',
		2, 
		0.05,
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		298.1146,
		$modulePath.'/_template.tabular',
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146__ANNOTATED__.TSV'),
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on a Methylguanosine example');
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis on PeakForest Data with a positively charged methylguanosine**\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/pfs002787+.tsv',
		3, 
		0.002,
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		298.11460,
		$modulePath.'/_template.tabular',
		$modulePath.'/pfs002787__ANNOTATED__.TSV'),
		$modulePath.'/pfs002787__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on PeakForest Data with a positively charged methylguanosine');
		
#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis on PeakForest Data with L-prolyl-L-glycine (CEA)**\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/pfs003731.tsv',
		3, 
		0.002,
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		172.084792254,
		$modulePath.'/_template.tabular',
		$modulePath.'/pfs003731__ANNOTATED__.TSV'),
		$modulePath.'/pfs003731__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on PeakForest Data with L-prolyl-L-glycine (CEA)');

#########################	
	print "\n** Test $current_test fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis on PeakForest Data with L-prolyl-L-glycine (TOXALIM)**\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST(
		$modulePath.'/pfs007110.tsv',
		1, 
		0.002,
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		172.084792254,
		$modulePath.'/_template.tabular',
		$modulePath.'/pfs007110__ANNOTATED__.TSV'),
		$modulePath.'/pfs007110__ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis\' works on PeakForest Data with L-prolyl-L-glycine (TOXALIM)');

## #################################################################################################################################
##
#########################	######################### Full Analysis FOR MaConDa db #########################  ###############
##
####################################################################################################################################

#########################	

	print "\n** Test $current_test fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis_TEST (
		# my ($expFile, $col, $delta, $queryMode, $template, $tabular) - - using MaConDa extension database from metabolomics-references by defaut
		$modulePath.'/in_test02_pos.tabular',
		2, 
		5,
		'ION',
		'POSITIVE',
		$modulePath.'/_template.tabular',
		$modulePath.'/in_test02_pos__CONTAMINANTS_ANNOTATED__.TSV'),
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
		# my ($expFile, $col, $delta, $source, $ionMode, $template, $tabular)
		$modulePath.'/in_test02_pos.tabular',
		2, 
		5,
		$modulePath.'/BloodExposome_v1_0_part.txt',
		'POSITIVE',
		$modulePath.'/_template.tabular',
		$modulePath.'/in_test02_pos__BLOODEXP_ANNOTATED__.TSV'),
		$modulePath.'/in_test02_pos__BLOODEXP_ANNOTATED__.TSV',
		'Method \'fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis\' works with a bank and tabular template');


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

##
#########################	######################### 	full Analysis TESTS SUB	 #########################  ####################
##

##
#########################	######################### 	AB INITIO FRAG DB TESTS SUB	 #########################  ####################
##

	## sub fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis
	sub fullCompare_ExpPeakList_And_AbInitioFragmentBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $col, $delta, $theoFile, $mzParent, $template, $tabular) = @_ ;
		
		my $oBank = Metabolomics::Banks::AbInitioFragments->new() ;
#		print Dumper $oBank ;
		
		$oBank->getFragmentsFromSource($theoFile) ;
#		print Dumper $oBank ;
		
		my $nb = $oBank->buildTheoPeakBankFromFragments($mzParent) ;
#		print Dumper $oBank ;
		
		$oBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm 2
#		print Dumper $obank ;

		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;
#		print Dumper $oAnalysis ;

		$oAnalysis->compareExpMzToTheoMzList('DA', $delta) ;
#		print Dumper $oAnalysis ;
		
		my $tabularfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular) ;
		
		return($tabularfile) ;	
	}
##
#########################	######################### 	MACONDA TESTS SUB	 #########################  ####################
##
	## sub fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis
	sub fullCompare_ExpPeakList_And_MaConDaBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $col, $delta, $queryMode, $IonMode, $template, $tabular) = @_ ;
		
		my $oBank = Metabolomics::Banks::MaConDa->new() ;
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

		$oAnalysis->compareExpMzToTheoMzList('PPM', $delta) ;
#		print Dumper $oAnalysis ;
		
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular) ;
		
		return($tabularfile) ;	
	}	
##
#########################	######################### 	BLOOD EXPOSOME TESTS SUB	 #########################  ####################
##

	## sub fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysis
	sub fullCompare_ExpPeakList_And_TheoBloodExposomeBank_FromDataAnalysis_TEST {
		# get values
		my ($expFile, $col, $delta, $source, $IonMode, $template, $tabular) = @_ ;
				
		my $oBank = Metabolomics::Banks::BloodExposome->new() ;
#		print Dumper $oBank ;

	    $oBank->getMetabolitesFromSource($source) ;
#	    print Dumper $oBank ;

	    my $nb = $oBank->buildTheoPeakBankFromEntries($IonMode) ;
#	    print Dumper $oBank ;

		$oBank->parsingMsFragments($expFile, 'asheader', $col) ; # get mz in colunm 2
#		print Dumper $oBank ;

		my $oAnalysis = Metabolomics::Fragment::Annotation->new($oBank) ;
#		print Dumper $oAnalysis ;

		$oAnalysis->compareExpMzToTheoMzList('PPM', $delta) ;		
#		print Dumper $oAnalysis ;
		
#		my $tabularfile = $oAnalysis->writeFullTabularWithPeakBankObject($expFile, $template, $tabular) ;
		my $tabularfile = $oAnalysis->writeTabularWithPeakBankObject($template, $tabular) ;
		
		return($tabularfile) ;		
	}
	
}## END BEGIN part
