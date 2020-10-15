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

use Test::More tests =>  28 ;
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
	
	
## #################################################################################################################################
##
#########################	######################### BLOOD Exposome TESTS #########################  #########################
##
####################################################################################################################################

#########################		
	print "\n** Test $current_test getMetaboliteFromSource **\n" ; $current_test++;
	is_deeply( init_BloodExposomeBankObject_TEST(),
		bless( {
                 '_DATABASE_NAME_' => 'Blood Exposome',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_ENTRIES_' => [],
                 '_THEO_PEAK_LIST_' => [],
                 '_EXP_PEAK_LIST_' => [],
               }, 'Metabolomics::Banks::BloodExposome' ) ,
		'Method \'initBloodExpBankObject\' init a well formatted bank object'
	) ;
	
	
#########################	

	print "\n** Test $current_test getMetaboliteFromSource **\n" ; $current_test++;
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
	print "\n** Test $current_test getMetaboliteFromSource **\n" ; $current_test++;
	is_deeply( init_AbInitioFragBankObject_TEST(),
		##Expected:
		bless( {
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_FRAGMENTS_' => [],
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_URL_' => 'database_url',
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_DATABASE_ENTRIES_' => []
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		'Method \'initBloodExpBankObject\' init a well formatted bank object'
	) ;

	print "\n** Test $current_test getFragmentsFromSource **\n" ; $current_test++;
	is_deeply( getFragmentsFromSourceTest(
		## Argts
			$modulePath.'/MS_fragments-adducts-isotopes-test.txt'),
		## Expected:
			bless( {
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_DOI_' => 'database_doi',
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
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '178.024',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '156.042',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.588',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '119.083',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_DOI_' => 'database_doi',
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'isotope',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '15N'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_TYPE_' => 'fragment'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'fragment',
                                             '_DELTA_MASS_' => '-352.064176',
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ]
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
                 '_DATABASE_URL_' => 'database_url',
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 159.93784,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
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
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
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
                 '_DATABASE_NAME_' => 'Ab Initio Fragments'
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		## Eval
			'Method \'buildTheoPeakBankFromFragments\' works with a refFragments object');


#########################	
	print "\n** Test $current_test buildTheoDimerFromMz **\n" ; $current_test++;
	is_deeply( buildTheoDimerFromMzTest(
		## Argts
			bless( {
                 '_DATABASE_URL_' => 'database_url',
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
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
                 '_DATABASE_NAME_' => 'Ab Initio Fragments'
               }, 'Metabolomics::Banks::AbInitioFragments' ),
			100.00001,
			'POSITIVE'),
		## Expected
			bless( {
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '159.93784',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '137.95589',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_NAME_' => '-H+K',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ID_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ID_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.50169',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.99704',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '228.02314',
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+3H2O+2H',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => '2M+3H2O+2H',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '242.03384',
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+ACN+H',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ID_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_NAME_' => '2M+ACN+H'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+ACN+Na',
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '264.01578',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_NAME_' => '2M+ACN+Na',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '201.00730',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+H',
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '2M+H',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ID_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => '2M+K',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '238.96318',
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+K'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+Na',
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '222.98924',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_NAME_' => '2M+Na',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'dimeric adduct',
                                                  '_ANNOTATION_IN_POS_MODE_' => '2M+NH4',
                                                  '_MMU_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '218.03384',
                                                  '_ID_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_NAME_' => '2M+NH4',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_ENTRIES_' => [],
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_TYPE_' => 'adduct',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'isotope',
                                             '_DELTA_MASS_' => '0.501677419'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'fragment'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '-352.064176',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'fragment',
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)'
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_URL_' => 'database_url'
               }, 'Metabolomics::Banks::AbInitioFragments' ),
		## Eval
			'Method \'buildTheoDimerFromMz\' works with a oBank object' );


#########################	
	print "\n** Test $current_test isotopicAdvancedCalculation **\n" ; $current_test++;
	is_deeply( isotopicAdvancedCalculationTest(
		## Argts
			bless( {
                 '_DATABASE_URL_' => 'database_url',
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 159.93784,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
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
                 '_DATABASE_NAME_' => 'Ab Initio Fragments'
               }, 'Metabolomics::Banks::AbInitioFragments' ),
			'POSITIVE'),
		## Expected
			bless( {
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'adduct'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'isotope'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_DELTA_MASS_' => '-294.0950822'
                                           }, 'Metabolomics::Banks::AbInitioFragments' ),
                                    bless( {
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_DELTA_MASS_' => '-352.064176'
                                           }, 'Metabolomics::Banks::AbInitioFragments' )
                                  ],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_ENTRIES_' => [],
                 '_EXP_PEAK_LIST_' => [],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '159.93784',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '137.95589',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K'
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.50169',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '100.99704',
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_PPM_ERROR_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '160.43952',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_13C db ',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K_13C db ',
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_MMU_ERROR_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K_15N',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_15N',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '160.93487',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_13C db ',
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K_13C db ',
                                                  '_MMU_ERROR_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '138.45757',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef
                                                }, 'Metabolomics::Banks' ),
                                         bless( {
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K_15N',
                                                  '_MMU_ERROR_' => 0,
                                                  '_ID_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotopic massif',
                                                  '_ANNOTATION_IN_POS_MODE_' => 'x_15N',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '138.95292',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_PPM_ERROR_' => 0
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments'
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
                 '_THEO_PEAK_LIST_' => [],
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_VERSION_' => '1.0',
                 '_CONTAMINANTS_' => [],
                 '_DATABASE_NAME_' => 'MaConDa'
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
                 '_DATABASE_URL_' => 'database_url',
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_VERSION_' => '1.0',
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
                 '_DATABASE_URL_' => 'database_url',
                 '_EXP_PEAK_LIST_' => [],
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
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_ENTRIES_' => [],
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
                 '_DATABASE_URL_' => 'database_url',
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
                 '_DATABASE_URL_' => 'database_url',
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
                 '_EXP_PEAK_LIST_' => [],
                 '_DATABASE_VERSION_' => '1.0',
                 '_DATABASE_URL_' => 'database_url',
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
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_NAME_' => 'MaConDa',
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
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_VERSION_' => '1.0',
                 '_THEO_PEAK_LIST_' => []
               }, 'Metabolomics::Banks::MaConDa' ),
        # query mode
        'ION'
		),
		##### Expected results
		bless( {
                 '_DATABASE_DOI_' => 'database_doi',
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_PUBCHEM_CID_' => '176',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_NAME_' => 'Acetic Acid',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_ID_' => 'CON00001',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_ION_FORM_' => '[M-H]-',
                                                '_ION_MODE_' => 'NEG',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_MZ_' => '59',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_FORMULA_' => 'C2H4O2'
                                              }, 'Metabolomics::Banks::MaConDa' )
                                     ],
                 '_DATABASE_ENTRIES_NB_' => 'database_entries_nb',
                 '_DATABASE_NAME_' => 'MaConDa',
                 '_DATABASE_VERSION_' => '1.0',
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                  '_MMU_ERROR_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_ONLY_IN_' => undef,
                                                  '_ANNOTATION_FORMULA_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '59.0138536',
                                                  '_ANNOTATION_IN_NEG_MODE_' => '[M-H]-',
                                                  '_ID_' => 'CON00001'
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_URL_' => 'database_url',
                 '_EXP_PEAK_LIST_' => []
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
                 '_DATABASE_ENTRIES_' => [],
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
                 '_DATABASE_VERSION_' => '1.1',
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
#########################	######################### 		ALL TESTS SUB		 #########################  ########################
##
####################################################################################################################################



##
#########################	######################### 	BLOOD EXPOSOME TESTS SUB	 #########################  ####################
##

	## SUB TEST for test bank object init
	sub init_BloodExposomeBankObject_TEST {
	    # get values
	    my (  ) = @_;
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
	    my (  ) = @_;
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
	    my (  ) = @_;
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
	    my (  ) = @_;
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

	
}## END BEGIN part




