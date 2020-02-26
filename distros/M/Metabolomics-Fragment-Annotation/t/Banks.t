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

use Test::More tests =>  25 ;
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
               }, 'Metabolomics::Banks' ) ,
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
                                                  '_PPM_ERROR_' => 0
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_URL_' => 'database_url',
                 '_DATABASE_DOI_' => 'database_doi',
                 '_DATABASE_NAME_' => 'Ab Initio Fragments'
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
               }, 'Metabolomics::Banks' ),
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
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '59.0138536',
                                                  '_ANNOTATION_IN_NEG_MODE_' => '[M-H]-',
                                                  '_ID_' => 'CON00001'
                                                }, 'Metabolomics::Banks' )
                                       ],
                 '_DATABASE_ENTRIES_' => [],
                 '_DATABASE_URL_' => 'database_url',
                 '_EXP_PEAK_LIST_' => []
               }, 'Metabolomics::Banks' ),
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
	
}## END BEGIN part




