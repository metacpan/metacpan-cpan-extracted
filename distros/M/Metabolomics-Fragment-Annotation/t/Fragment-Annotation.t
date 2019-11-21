# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl FragNot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib '../lib' ;
use Metabolomics::Fragment::Annotation qw( :all ) ;

use Test::More tests => 19 ;
use Data::Dumper ;




#########################



BEGIN {
	
	my $current_test = 1 ;
	my $modulePath = File::Basename::dirname( __FILE__ );
	
#########################	
	print "\n** Test $current_test FragNot package **\n" ; $current_test++ ;
	use_ok('Metabolomics::Fragment::Annotation') ;
	
	
#########################	
	print "\n** Test $current_test getContaminantsFromSource **\n" ; $current_test++;
	is_deeply( getContaminantsFromSourceTest(
			$modulePath.'/MaConDa__v1_0.xml'),
			bless( {
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_PUBCHEM_CID_' => '176',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_NAME_' => 'Acetic Acid',
                                                '_ID_' => 'CON00001',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_EXACT_MASS_' => '60.02113'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_EXACT_MASS_' => '26.003074',
                                                '_STD_INCHI_KEY_' => undef,
                                                '_ID_' => 'CON00002',
                                                '_NAME_' => 'Acetonitrile (fragment)',
                                                '_STD_INCHI_' => undef,
                                                '_PUBCHEM_CID_' => undef,
                                                '_FORMULA_' => 'CN'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_ID_' => 'CON00015',
                                                '_STD_INCHI_KEY_' => undef,
                                                '_EXACT_MASS_' => '132.905452',
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_FORMULA_' => 'Cs',
                                                '_PUBCHEM_CID_' => undef,
                                                '_STD_INCHI_' => undef,
                                                '_NAME_' => 'Cs-133'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_ID_' => 'CON00016',
                                                '_STD_INCHI_KEY_' => 'IAZDPXIOMUYVGZ-WFGJKAKNSA-N',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_EXACT_MASS_' => '84.051593',
                                                '_PUBCHEM_CID_' => '75151',
                                                '_FORMULA_' => 'C2D6OS',
                                                '_STD_INCHI_' => 'InChI=1S/C2H6OS/c1-4(2)3/h1-2H3/i1D3,2D3',
                                                '_NAME_' => 'd6-Dimethylsulfoxide'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_NAME_' => 'DDTDP',
                                                '_STD_INCHI_' => undef,
                                                '_FORMULA_' => 'C30H58O4S',
                                                '_PUBCHEM_CID_' => undef,
                                                '_EXACT_MASS_' => '514.405582',
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_STD_INCHI_KEY_' => undef,
                                                '_ID_' => 'CON00017'
                                              }, 'Metabolomics::Fragment::Annotation' )
                                     ]
               }, 'Metabolomics::Fragment::Annotation' ),
			'Method \'getContaminantsFromSource\' works with a well formatted source file');
	
#########################	
	print "\n** Test $current_test getContaminantsExtensiveFromSource **\n" ; $current_test++;
	is_deeply( getContaminantsExtFromSourceTest(
			$modulePath.'/MaConDa__v1_0__extensive.xml'),
			bless( {
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_ION_MODE_' => 'NEG',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_NAME_' => 'Acetic Acid',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_MZ_' => '59',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_PUBCHEM_CID_' => '176',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_ID_' => 'CON00001',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_ION_FORM_' => '[M-H]-'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_REFERENCE_' => 'Ijames, C. F., Dutky, R. C., & Fales, H. M. (1995). Iron carboxylate oxygen-centered-triangle complexes detected during electrospray use of organic acid modifiers with a comment on the Finnigan TSQ-700 electrospray inlet system. Journal of the American Society for Mass Spectrometry, 6(12), 1226-1231, doi:10.1016/1044-0305(95)00579-x.',
                                                '_MZ_' => '537.88',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_ID_' => 'CON00001',
                                                '_INSTRUMENT_TYPE_' => 'Triple quadrupole',
                                                '_ION_FORM_' => '[M6-H6+Fe3+O]+',
                                                '_PUBCHEM_CID_' => '176',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_NAME_' => 'Acetic Acid',
                                                '_INSTRUMENT_' => 'Finnigan TSQ-700',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_ION_MODE_' => 'POS',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_EXACT_ADDUCT_MASS_' => '537.8790134'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_REFERENCE_' => 'Ijames, C. F., Dutky, R. C., & Fales, H. M. (1995). Iron carboxylate oxygen-centered-triangle complexes detected during electrospray use of organic acid modifiers with a comment on the Finnigan TSQ-700 electrospray inlet system. Journal of the American Society for Mass Spectrometry, 6(12), 1226-1231, doi:10.1016/1044-0305(95)00579-x.',
                                                '_MZ_' => '555',
                                                '_INSTRUMENT_TYPE_' => 'Triple quadrupole',
                                                '_ID_' => 'CON00001',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_ION_FORM_' => '[M6-H6+H2O+Fe3+O]+',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_PUBCHEM_CID_' => '176',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_NAME_' => 'Acetic Acid',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_INSTRUMENT_' => 'Finnigan TSQ-700',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ION_MODE_' => 'POS',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_EXACT_ADDUCT_MASS_' => '555.8895784'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_EXACT_ADDUCT_MASS_' => '325.2584664',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_ION_MODE_' => 'POS',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_INSTRUMENT_' => 'ThermoFinnigan LCQ Deca XP',
                                                '_TYPE_OF_CONTAMINANT_' => 'Scintillation cocktail',
                                                '_NAME_' => 'Butyl Carbitol',
                                                '_STD_INCHI_' => 'InChI=1S/C8H18O3/c1-2-3-5-10-7-8-11-6-4-9/h9H,2-8H2,1H3',
                                                '_STD_INCHI_KEY_' => 'OAYXUHPQHDHDDZ-UHFFFAOYSA-N',
                                                '_PUBCHEM_CID_' => '8177',
                                                '_EXACT_MASS_' => '162.125595',
                                                '_ION_FORM_' => '[M2+H]+',
                                                '_FORMULA_' => 'C8H18O3',
                                                '_ID_' => 'CON00010',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_MZ_' => '324.9',
                                                '_REFERENCE_' => 'Gibson, C. R., & Brown, C. M. (2003). Identification of diethylene glycol monobutyl ether as a source of contamination in an ion trap mass spectrometer. Journal of the American Society for Mass Spectrometry, 14(11), 1247-1249, doi:10.1016/s1044-0305(03)00534-8.'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_INSTRUMENT_' => 'unknown',
                                                '_TYPE_OF_CONTAMINANT_' => 'Antioxidant',
                                                '_ION_MODE_' => 'POS',
                                                '_STD_INCHI_' => 'InChI=1S/C11H16O2/c1-11(2,3)9-7-8(13-4)5-6-10(9)12/h5-7,12H,1-4H3',
                                                '_NAME_' => 'Butylated Hydroxyanisole',
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_EXACT_ADDUCT_MASS_' => '181.1223064',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_MZ_' => '181.122306',
                                                '_STD_INCHI_KEY_' => 'MRBKEAMVRSLQPH-UHFFFAOYSA-N',
                                                '_EXACT_MASS_' => '180.11503',
                                                '_PUBCHEM_CID_' => '11954184',
                                                '_FORMULA_' => 'C11H16O2',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_ID_' => 'CON00011',
                                                '_ION_FORM_' => '[M+H]+'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_EXACT_ADDUCT_MASS_' => '203.1042514',
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_ION_MODE_' => 'POS',
                                                '_TYPE_OF_CONTAMINANT_' => 'Antioxidant',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_INSTRUMENT_' => 'unknown',
                                                '_NAME_' => 'Butylated Hydroxyanisole',
                                                '_STD_INCHI_' => 'InChI=1S/C11H16O2/c1-11(2,3)9-7-8(13-4)5-6-10(9)12/h5-7,12H,1-4H3',
                                                '_PUBCHEM_CID_' => '11954184',
                                                '_STD_INCHI_KEY_' => 'MRBKEAMVRSLQPH-UHFFFAOYSA-N',
                                                '_EXACT_MASS_' => '180.11503',
                                                '_ION_FORM_' => '[M+Na]+',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_ID_' => 'CON00011',
                                                '_FORMULA_' => 'C11H16O2',
                                                '_MZ_' => '203.104249',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_EXACT_ADDUCT_MASS_' => '441.0142384',
                                                '_STD_INCHI_' => 'InChI=1S/C10H7NO3/c11-6-8(10(13)14)5-7-1-3-9(12)4-2-7/h1-5,12H,(H,13,14)/b8-5+',
                                                '_NAME_' => '4-HCCA',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_TYPE_OF_CONTAMINANT_' => 'Matrix compound',
                                                '_ION_MODE_' => 'POS',
                                                '_FORMULA_' => 'C10H7NO3',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_ID_' => 'CON00298',
                                                '_ION_FORM_' => '[M2+63Cu(I)]+',
                                                '_PUBCHEM_CID_' => '5328791',
                                                '_STD_INCHI_KEY_' => 'AFVLVVWMAFSXCK-VMPITWQZSA-N',
                                                '_EXACT_MASS_' => '189.042594',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_MZ_' => '441.01479'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_MZ_' => '933',
                                                '_REFERENCE_' => 'NewObjective Common Background Ions for Electrospray (Positive Ion). http://www.newobjective.com/downloads/technotes/PV-3.pdf.',
                                                '_STD_INCHI_KEY_' => undef,
                                                '_EXACT_MASS_' => undef,
                                                '_PUBCHEM_CID_' => undef,
                                                '_ION_FORM_' => undef,
                                                '_ID_' => 'CON00315',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_FORMULA_' => 'unknown',
                                                '_ION_MODE_' => 'POS',
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_NAME_' => 'unknown',
                                                '_STD_INCHI_' => undef,
                                                '_EXACT_ADDUCT_MASS_' => undef,
                                                '_ION_SOURCE_TYPE_' => undef
                                              }, 'Metabolomics::Fragment::Annotation' )
                                     ]
               }, 'Metabolomics::Fragment::Annotation' ),
			'Method \'getContaminantsExtensiveFromSource\' works with a well formatted source file');


#########################	
	print "\n** Test $current_test getFragmentsFromSource **\n" ; $current_test++;
	is_deeply( getFragmentsFromSourceTest(
			$modulePath.'/MS_fragments-adducts-isotopes-test.txt'),
			bless( {
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_TYPE_' => 'adduct',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_TYPE_' => 'adduct',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-H+K'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '13C db '
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'isotope',
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'fragment',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '-352.064176'
                                           }, 'Metabolomics::Fragment::Annotation' )
                                  ],
                 '_THEO_PEAK_LIST_' => [],
                 '_EXP_PEAK_LIST_' => []
               }, 'Metabolomics::Fragment::Annotation' ),
			'Method \'getFragmentsFromSource\' works with a well formatted source file');
		

#########################	
	print "\n** Test $current_test buildTheoPeakBankFromFragments **\n" ; $current_test++;
	is_deeply( buildTheoPeakBankFromFragmentsTest(
			$modulePath.'/MS_fragments-adducts-isotopes-test.txt', 118.086),
			bless( {
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                         		  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '178.024',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0, 
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                         		  '_ID_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '156.042',
                                                  '_ANNOTATION_NAME_' => '-H+K', 
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                         		  '_ID_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.588',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                         		  '_ID_' => undef,
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '119.083',
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' )
                                       ],
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '59.9378259'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '37.95588165'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '13C db '
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'isotope',
                                             '_DELTA_MASS_' => '0.997034893'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_DELTA_MASS_' => '-352.064176',
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)'
                                           }, 'Metabolomics::Fragment::Annotation' )
                                  ],
                 '_EXP_PEAK_LIST_' => []
               }, 'Metabolomics::Fragment::Annotation' ),
			'Method \'buildTheoPeakBankFromFragments\' works with a refFragments object');

#########################	
	print "\n** Test $current_test compareExpMzToTheoMzList **\n" ; $current_test++;
	is_deeply( compareExpMzToTheoMzListTest(
			bless( {
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '178.024',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '156.042',
                                                  '_ANNOTATION_NAME_' => '-H+K',
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.588',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '119.083',
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' )
                                       ],
                 '_EXP_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 178.9942,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 156.0351,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 128.9587,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 118.9756,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 108.0666,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Fragment::Annotation' )
                                       ],
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_TYPE_' => 'adduct',
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_ANNOTATION_IN_NEG_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'isotope',
                                             '_DELTA_MASS_' => '0.501677419',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_TYPE_' => 'isotope'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_TYPE_' => 'fragment',
                                             '_DELTA_MASS_' => '-352.064176',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)'
                                           }, 'Metabolomics::Fragment::Annotation' )
                                  ]
               }, 'Metabolomics::Fragment::Annotation' ), 'DA', 0.5),
               bless( {
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '178.9942',
                                                 '_ANNOTATION_NAME_' => undef
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '156.042',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => 'adduct',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_PPM_ERROR_' => '45',
                                                 '_MMU_ERROR_' => '0.007',
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '156.0351',
                                                 '_ANNOTATION_NAME_' => '-H+K'
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '128.9587',
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_NAME_' => '15N',
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.9756',
                                                 '_MMU_ERROR_' => '0.107',
                                                 '_PPM_ERROR_' => '899',
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '119.083',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => 'isotope'
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '108.0666',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef
                                               }, 'Metabolomics::Fragment::Annotation' )
                                      ],
                 '_FRAGMENTS_' => [
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-2H+Na+K',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '59.9378259',
                                             '_TYPE_' => 'adduct',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_DELTA_MASS_' => '37.95588165',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-H+K',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_TYPE_' => 'adduct'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_POS_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '13C db ',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '0.501677419'
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_DELTA_MASS_' => '0.997034893',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '15N',
                                             '_TYPE_' => 'isotope',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_LOSSES_OR_GAINS_' => '-(C11H18O9)',
                                             '_DELTA_MASS_' => '-294.0950822',
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' ),
                                    bless( {
                                             '_LOSSES_OR_GAINS_' => '-(C12H16O12)',
                                             '_ANNOTATION_IN_NEG_MODE_' => '',
                                             '_DELTA_MASS_' => '-352.064176',
                                             '_TYPE_' => 'fragment',
                                             '_ANNOTATION_IN_POS_MODE_' => ''
                                           }, 'Metabolomics::Fragment::Annotation' )
                                  ],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '178.024',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-2H+Na+K',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '-H+K',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '156.042',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'adduct',
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => '13C db ',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '118.588',
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '119.083',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_NAME_' => '15N',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_TYPE_' => 'isotope',
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_PPM_ERROR_' => '0',
                                                  '_MMU_ERROR_' => '0',
                                                }, 'Metabolomics::Fragment::Annotation' )
                                       ]
               }, 'Metabolomics::Fragment::Annotation' ),
			'Method \'compareExpMzToTheoMzList\' works with a refFragments object');
			
			
#########################	
	print "\n** Test $current_test extractContaminantTypes **\n" ; $current_test++;
	is_deeply( extractContaminantTypesTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml'),
	{
          'Antioxidant' => 2,
          'unknown' => 1,
          'Scintillation cocktail' => 1,
          'Matrix compound' => 1,
          'Solvent' => 3
     },
		'Method \'extractContaminantTypes\' works with a refContaminant object');
		
#########################	
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
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_MZ_' => '537.88',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_ION_MODE_' => 'POS',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ID_' => 'CON00001',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_EXACT_ADDUCT_MASS_' => '537.8790134',
                                                '_INSTRUMENT_' => 'Finnigan TSQ-700',
                                                '_ION_FORM_' => '[M6-H6+Fe3+O]+',
                                                '_NAME_' => 'Acetic Acid',
                                                '_REFERENCE_' => 'Ijames, C. F., Dutky, R. C., & Fales, H. M. (1995). Iron carboxylate oxygen-centered-triangle complexes detected during electrospray use of organic acid modifiers with a comment on the Finnigan TSQ-700 electrospray inlet system. Journal of the American Society for Mass Spectrometry, 6(12), 1226-1231, doi:10.1016/1044-0305(95)00579-x.',
                                                '_PUBCHEM_CID_' => '176',
                                                '_INSTRUMENT_TYPE_' => 'Triple quadrupole',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_INSTRUMENT_TYPE_' => 'Triple quadrupole',
                                                '_PUBCHEM_CID_' => '176',
                                                '_NAME_' => 'Acetic Acid',
                                                '_REFERENCE_' => 'Ijames, C. F., Dutky, R. C., & Fales, H. M. (1995). Iron carboxylate oxygen-centered-triangle complexes detected during electrospray use of organic acid modifiers with a comment on the Finnigan TSQ-700 electrospray inlet system. Journal of the American Society for Mass Spectrometry, 6(12), 1226-1231, doi:10.1016/1044-0305(95)00579-x.',
                                                '_ION_FORM_' => '[M6-H6+H2O+Fe3+O]+',
                                                '_INSTRUMENT_' => 'Finnigan TSQ-700',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_EXACT_ADDUCT_MASS_' => '555.8895784',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_ID_' => 'CON00001',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ION_MODE_' => 'POS',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_MZ_' => '555',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_STD_INCHI_KEY_' => 'OAYXUHPQHDHDDZ-UHFFFAOYSA-N',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_PUBCHEM_CID_' => '8177',
                                                '_REFERENCE_' => 'Gibson, C. R., & Brown, C. M. (2003). Identification of diethylene glycol monobutyl ether as a source of contamination in an ion trap mass spectrometer. Journal of the American Society for Mass Spectrometry, 14(11), 1247-1249, doi:10.1016/s1044-0305(03)00534-8.',
                                                '_NAME_' => 'Butyl Carbitol',
                                                '_ION_FORM_' => '[M2+H]+',
                                                '_INSTRUMENT_' => 'ThermoFinnigan LCQ Deca XP',
                                                '_EXACT_ADDUCT_MASS_' => '325.2584664',
                                                '_STD_INCHI_' => 'InChI=1S/C8H18O3/c1-2-3-5-10-7-8-11-6-4-9/h9H,2-8H2,1H3',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_ID_' => 'CON00010',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_EXACT_MASS_' => '162.125595',
                                                '_ION_MODE_' => 'POS',
                                                '_TYPE_OF_CONTAMINANT_' => 'Scintillation cocktail',
                                                '_FORMULA_' => 'C8H18O3',
                                                '_MZ_' => '324.9'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_ID_' => 'CON00011',
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_STD_INCHI_' => 'InChI=1S/C11H16O2/c1-11(2,3)9-7-8(13-4)5-6-10(9)12/h5-7,12H,1-4H3',
                                                '_EXACT_ADDUCT_MASS_' => '181.1223064',
                                                '_MZ_' => '181.122306',
                                                '_FORMULA_' => 'C11H16O2',
                                                '_TYPE_OF_CONTAMINANT_' => 'Antioxidant',
                                                '_ION_MODE_' => 'POS',
                                                '_EXACT_MASS_' => '180.11503',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_PUBCHEM_CID_' => '11954184',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_STD_INCHI_KEY_' => 'MRBKEAMVRSLQPH-UHFFFAOYSA-N',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_ION_FORM_' => '[M+H]+',
                                                '_NAME_' => 'Butylated Hydroxyanisole',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_ION_FORM_' => '[M+Na]+',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_NAME_' => 'Butylated Hydroxyanisole',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_STD_INCHI_KEY_' => 'MRBKEAMVRSLQPH-UHFFFAOYSA-N',
                                                '_PUBCHEM_CID_' => '11954184',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_TYPE_OF_CONTAMINANT_' => 'Antioxidant',
                                                '_FORMULA_' => 'C11H16O2',
                                                '_MZ_' => '203.104249',
                                                '_EXACT_MASS_' => '180.11503',
                                                '_ION_MODE_' => 'POS',
                                                '_ID_' => 'CON00011',
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_EXACT_ADDUCT_MASS_' => '203.1042514',
                                                '_STD_INCHI_' => 'InChI=1S/C11H16O2/c1-11(2,3)9-7-8(13-4)5-6-10(9)12/h5-7,12H,1-4H3'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_INSTRUMENT_' => 'unknown',
                                                '_REFERENCE_' => 'Keller, B. O., Suj, J., Young, A. B., & Whittal, R. M. (2008). Interferences and contaminants encountered in modern mass spectrometry. Analytica Chimica Acta, 627(1), 71-81, doi:10.1016/j.aca.2008.04.043.',
                                                '_NAME_' => '4-HCCA',
                                                '_ION_FORM_' => '[M2+63Cu(I)]+',
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_PUBCHEM_CID_' => '5328791',
                                                '_STD_INCHI_KEY_' => 'AFVLVVWMAFSXCK-VMPITWQZSA-N',
                                                '_EXACT_MASS_' => '189.042594',
                                                '_ION_MODE_' => 'POS',
                                                '_TYPE_OF_CONTAMINANT_' => 'Matrix compound',
                                                '_FORMULA_' => 'C10H7NO3',
                                                '_MZ_' => '441.01479',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_STD_INCHI_' => 'InChI=1S/C10H7NO3/c11-6-8(10(13)14)5-7-1-3-9(12)4-2-7/h1-5,12H,(H,13,14)/b8-5+',
                                                '_EXACT_ADDUCT_MASS_' => '441.0142384',
                                                '_ID_' => 'CON00298'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_EXACT_MASS_' => undef,
                                                '_ION_MODE_' => 'POS',
                                                '_TYPE_OF_CONTAMINANT_' => 'unknown',
                                                '_FORMULA_' => 'unknown',
                                                '_MZ_' => '933',
                                                '_CHROMATOGRAPHY_' => undef,
                                                '_EXACT_ADDUCT_MASS_' => undef,
                                                '_STD_INCHI_' => undef,
                                                '_ION_SOURCE_TYPE_' => undef,
                                                '_ID_' => 'CON00315',
                                                '_INSTRUMENT_' => 'unknown',
                                                '_REFERENCE_' => 'NewObjective Common Background Ions for Electrospray (Positive Ion). http://www.newobjective.com/downloads/technotes/PV-3.pdf.',
                                                '_NAME_' => 'unknown',
                                                '_ION_FORM_' => undef,
                                                '_INSTRUMENT_TYPE_' => 'unknown',
                                                '_PUBCHEM_CID_' => undef,
                                                '_STD_INCHI_KEY_' => undef
                                              }, 'Metabolomics::Fragment::Annotation' )
                                     ]
               }, 'Metabolomics::Fragment::Annotation' ),
		'Method \'filterContaminantIonMode\' works with a refContaminants object and POSITIVE ion mode');

#########################	
	print "\n** Test $current_test filterContaminantIonMode **\n" ; $current_test++;
	is_deeply( filterContaminantIonModeTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml', 
		'NEGATIVE'
		),
		bless( {
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_ION_FORM_' => '[M-H]-',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_ID_' => 'CON00001',
                                                '_NAME_' => 'Acetic Acid',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_ION_MODE_' => 'NEG',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_MZ_' => '59',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_PUBCHEM_CID_' => '176',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.'
                                              }, 'Metabolomics::Fragment::Annotation' )
                                     ]
               }, 'Metabolomics::Fragment::Annotation' ),
		'Method \'filterContaminantIonMode\' works with a refContaminants object and NEGATIVE ion mode');
		
#########################	
	print "\n** Test $current_test filterContaminantInstruments **\n" ; $current_test++;
	is_deeply( filterContaminantInstrumentsTest(
		$modulePath.'/MaConDa__v1_0__extensive.xml', 
		['Micromass Platform II']
		),
		##### Expected results
		bless( {
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_ID_' => 'CON00001',
                                                '_NAME_' => 'Acetic Acid',
                                                '_ION_MODE_' => 'NEG',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_MZ_' => '59',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_PUBCHEM_CID_' => '176',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_ION_FORM_' => '[M-H]-'
                                              }, 'Metabolomics::Fragment::Annotation' )
                                     ]
               }, 'Metabolomics::Fragment::Annotation' ),
		'Method \'filterContaminantInstruments\' works with a refContaminants object and \'unknown\' instrument');

#########################	
	print "\n** Test $current_test filterContaminantInstrumentTypes **\n" ; $current_test++;
	is_deeply( filterContaminantInstrumentTypesTest(
			$modulePath.'/MaConDa__v1_0__extensive.xml', 
			['Ion trap']
		),
		##### Expected results
		bless( {
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_ION_FORM_' => '[M-H]-',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_ION_MODE_' => 'NEG',
                                                '_EXACT_MASS_' => '60.02113',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_PUBCHEM_CID_' => '176',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_NAME_' => 'Acetic Acid',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_ID_' => 'CON00001',
                                                '_MZ_' => '59'
                                              }, 'Metabolomics::Fragment::Annotation' ),
                                       bless( {
                                                '_FORMULA_' => 'C8H18O3',
                                                '_INSTRUMENT_' => 'ThermoFinnigan LCQ Deca XP',
                                                '_PUBCHEM_CID_' => '8177',
                                                '_REFERENCE_' => 'Gibson, C. R., & Brown, C. M. (2003). Identification of diethylene glycol monobutyl ether as a source of contamination in an ion trap mass spectrometer. Journal of the American Society for Mass Spectrometry, 14(11), 1247-1249, doi:10.1016/s1044-0305(03)00534-8.',
                                                '_CHROMATOGRAPHY_' => 'LC',
                                                '_ION_FORM_' => '[M2+H]+',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_EXACT_MASS_' => '162.125595',
                                                '_ION_MODE_' => 'POS',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_ID_' => 'CON00010',
                                                '_EXACT_ADDUCT_MASS_' => '325.2584664',
                                                '_MZ_' => '324.9',
                                                '_TYPE_OF_CONTAMINANT_' => 'Scintillation cocktail',
                                                '_STD_INCHI_KEY_' => 'OAYXUHPQHDHDDZ-UHFFFAOYSA-N',
                                                '_NAME_' => 'Butyl Carbitol',
                                                '_STD_INCHI_' => 'InChI=1S/C8H18O3/c1-2-3-5-10-7-8-11-6-4-9/h9H,2-8H2,1H3'
                                              }, 'Metabolomics::Fragment::Annotation' )
                                     ]
               }, 'Metabolomics::Fragment::Annotation' ),
		'Method \'filterContaminantInstrumentTypes\' works with a refContaminants object and \'Ion trap\' instrument');
		
		

#########################	
	print "\n** Test $current_test buildTheoPeakBankFromContaminants **\n" ; $current_test++;
	is_deeply( buildTheoPeakBankFromContaminantsTest(
		# oBank
		bless( {
                 '_FRAGMENTS_' => [],
                 '_THEO_PEAK_LIST_' => [],
                 '_EXP_PEAK_LIST_' => []
               }, 'Metabolomics::Fragment::Annotation' ),
        # oContaminants
        bless( {
                 '_CONTAMINANTS_' => [
                                       bless( {
                                                '_EXACT_MASS_' => '60.02113',
                                                '_REFERENCE_' => 'Tong, H., Bell, D., Tabei, K., & Siegel, M. M. (1999). Automated data massaging, interpretation, and E-mailing modules for high throughput open access mass spectrometry. Journal of the American Society for Mass Spectrometry, 10(11), 1174-1187, doi:10.1016/s1044-0305(99)00090-2.',
                                                '_NAME_' => 'Acetic Acid',
                                                '_STD_INCHI_' => 'InChI=1S/C2H4O2/c1-2(3)4/h1H3,(H,3,4)',
                                                '_ION_FORM_' => '[M-H]-',
                                                '_ION_MODE_' => 'NEG',
                                                '_INSTRUMENT_' => 'Micromass Platform II',
                                                '_STD_INCHI_KEY_' => 'QTBSBXVTEAMEQO-UHFFFAOYSA-N',
                                                '_EXACT_ADDUCT_MASS_' => '59.0138536',
                                                '_INSTRUMENT_TYPE_' => 'Ion trap',
                                                '_MZ_' => '59',
                                                '_ID_' => 'CON00001',
                                                '_FORMULA_' => 'C2H4O2',
                                                '_ION_SOURCE_TYPE_' => 'ESI',
                                                '_TYPE_OF_CONTAMINANT_' => 'Solvent',
                                                '_PUBCHEM_CID_' => '176',
                                                '_CHROMATOGRAPHY_' => 'LC'
                                              }, 'Metabolomics::Fragment::Annotation' )
                                     ]
        	}, 'Metabolomics::Fragment::Annotation' ),
        # query mode
        'ION'
		),
		##### Expected results
		bless( {
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '59.0138536',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                  '_ID_' => 'CON00001',
                                                  '_ANNOTATION_IN_NEG_MODE_' => '[M-H]-',
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef
                                                }, 'Metabolomics::Fragment::Annotation' )
                                       ],
                 '_EXP_PEAK_LIST_' => [],
                 '_FRAGMENTS_' => []
               }, 'Metabolomics::Fragment::Annotation' ),
		'Method \'buildTheoPeakBankFromContaminants\' works with Bank and Contaminants objects and \'ION\' mode');
		
#########################	
	print "\n** Test $current_test compareExpMzToTheoMzList **\n" ; $current_test++;
	is_deeply( compareExpMzToTheoMzListTest(
		## oBank
		bless( {
                 '_FRAGMENTS_' => [],
                 '_EXP_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 178.9942,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 156.0351,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 128.9587,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 118.9756,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                }, 'Metabolomics::Fragment::Annotation' ),
                                         bless( {
                                                  '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 60.02425,
                                                  '_ANNOTATION_NAME_' => undef,
                                                  '_ANNOTATION_TYPE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_PPM_ERROR_' => 0,
                                                  '_MMU_ERROR_' => 0,
                                                }, 'Metabolomics::Fragment::Annotation' )
                                       ],
                 '_THEO_PEAK_LIST_' => [
                                         bless( {
                                                  '_ANNOTATION_TYPE_' => 'Solvent',
                                                  '_ANNOTATION_IN_POS_MODE_' => undef,
                                                  '_COMPUTED_MONOISOTOPIC_MASS_' => '60.02113',
                                                  '_MESURED_MONOISOTOPIC_MASS_' => 0,
                                                  '_ANNOTATION_IN_NEG_MODE_' => '[M-H]-',
                                                  '_ID_' => 'CON00001',
                                                  '_ANNOTATION_NAME_' => 'Acetic Acid'
                                                }, 'Metabolomics::Fragment::Annotation' )
                                       ]
               }, 'Metabolomics::Fragment::Annotation' ),
        ## query params
        'DA', 0.05),
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
                                                }, 'Metabolomics::Fragment::Annotation' )
                                       ],
                 '_FRAGMENTS_' => [],
                 '_EXP_PEAK_LIST_' => [
                                        bless( {
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '178.9942',
                                                 '_PPM_ERROR_' => 0,
                                                 '_MMU_ERROR_' => 0,
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '156.0351',
                                                 '_PPM_ERROR_' => 0,
                                                 '_MMU_ERROR_' => 0,
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '128.9587',
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_MMU_ERROR_' => 0,
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '118.9756',
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => 0,
                                                 '_ANNOTATION_TYPE_' => undef,
                                                 '_ANNOTATION_NAME_' => undef,
                                                 '_PPM_ERROR_' => 0,
                                                 '_MMU_ERROR_' => 0,
                                               }, 'Metabolomics::Fragment::Annotation' ),
                                        bless( {
                                                 '_ANNOTATION_IN_NEG_MODE_' => undef,
                                                 '_COMPUTED_MONOISOTOPIC_MASS_' => '60.02113',
                                                 '_MESURED_MONOISOTOPIC_MASS_' => '60.02425',
                                                 '_MMU_ERROR_' => '0.00312',
                                                 '_ANNOTATION_TYPE_' => 'Solvent',
                                                 '_ANNOTATION_NAME_' => 'Acetic Acid',
                                                 '_ID_' => 'CON00001',
                                                 '_ANNOTATION_IN_POS_MODE_' => undef,
                                                 '_PPM_ERROR_' => 52,
                                               }, 'Metabolomics::Fragment::Annotation' )
                                      ]
               }, 'Metabolomics::Fragment::Annotation' ),
		'Method \'compareExpMzToTheoMzList\' works with refBank and Contaminant mapped content');
	


#########################	
	print "\n** Test $current_test writeTabularWithPeakBankObject **\n" ; $current_test++;
	is_deeply( writeTabularWithPeakBankObjectTest(
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
                                                }, 'Metabolomics::Fragment::Annotation' )
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
                                                }, 'Metabolomics::Fragment::Annotation' )
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
		
		
		
#########################	
	print "\n** Test $current_test fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysisTest( 	
		$modulePath.'/cpd-val-pro.TSV',
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		214.1317,
		$modulePath.'/_template.tabular',
		$modulePath.'/cpd-val-pro__ANNOTATED__.TSV'),
		$modulePath.'/cpd-val-pro__ANNOTATED__.TSV',
		'Method \'writeFullTabularWithPeakBankObject\' works with a bank and tabular template');
		
#########################	
	print "\n** Test $current_test fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysis **\n" ; $current_test++;
	is_deeply( fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysisTest(
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146.TSV',
		$modulePath.'/MS_fragments-adducts-isotopes.txt',
		298.1146,
		$modulePath.'/_template.tabular',
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146__ANNOTATED__.TSV'),
		$modulePath.'/Cmpd_4.4-Methylguanosine-298.1146__ANNOTATED__.TSV',
		'Method \'writeFullTabularWithPeakBankObject\' works with a bank and tabular template');

################################################## SUBs ##################################################	
		
		
	## sub
	sub getFragmentsFromSourceTest {
		
		my ( $source ) = @_ ;
		
		my $o = Metabolomics::Fragment::Annotation->getFragmentsFromSource($source) ;
#		print Dumper $o ;
		return ($o) ;
	}
	## sub
	sub buildTheoPeakBankFromFragmentsTest {
		my ( $source, $mzParent ) = @_ ;
		my $obank = Metabolomics::Fragment::Annotation->getFragmentsFromSource($source) ;
		$obank->buildTheoPeakBankFromFragments($mzParent) ;
		
#		print Dumper $obank ;
		
		return ($obank) ;
	}
	
	sub compareExpMzToTheoMzListTest {
		my ( $oBank, $deltaType, $deltaValue ) = @_ ;
		
		$oBank->compareExpMzToTheoMzList($deltaType, $deltaValue) ;
		
#		print Dumper $oBank ;
		
		return ($oBank) ;
		
	}
	## sub
	sub getContaminantsFromSourceTest {
		my ( $source ) = @_ ;
		
		my $o = Metabolomics::Fragment::Annotation->getContaminantsFromSource($source) ;
#		print Dumper $o ;
		return ($o) ;
	}
	## sub
	sub getContaminantsExtFromSourceTest {
		my ( $source ) = @_ ;

		my $o = Metabolomics::Fragment::Annotation->getContaminantsExtensiveFromSource($source) ;
#		print Dumper $o ;
		return ($o) ;
	}
	## sub
	sub extractContaminantTypesTest {
		my ( $source ) = @_ ;
		
		my $o = Metabolomics::Fragment::Annotation->getContaminantsExtensiveFromSource($source) ;
		my $typeList = extractContaminantTypes($o) ;
#		print Dumper $typeList ;
		return ($typeList) ;
	}
	## sub
	sub extractContaminantInstrumentsTest {
		my ( $source ) = @_ ;
		
		my $o = Metabolomics::Fragment::Annotation->getContaminantsExtensiveFromSource($source) ;
		my $instrumentList = extractContaminantInstruments($o) ;
#		print Dumper $instrumentList ;
		return ($instrumentList) ;
	}
		## sub
	sub extractContaminantInstrumentTypesTest {
		my ( $source ) = @_ ;
		
		my $o = Metabolomics::Fragment::Annotation->getContaminantsExtensiveFromSource($source) ;
		my $instrumentTypeList = extractContaminantInstrumentTypes($o) ;
#		print Dumper $instrumentTypeList ;
		return ($instrumentTypeList) ;
	}
	
		## sub
	sub filterContaminantIonModeTest  {
		my ( $source, $IonMode ) = @_ ;
		my $o = Metabolomics::Fragment::Annotation->getContaminantsExtensiveFromSource($source) ;
		my $oNew = $o->filterContaminantIonMode($IonMode) ;
#		print Dumper $o ;
#		print Dumper $oNew ;
		return ($oNew) ;
	}
	
	
	## sub
	sub filterContaminantInstrumentsTest  {
		my ( $source, $Instrument ) = @_ ;
		my $o = Metabolomics::Fragment::Annotation->getContaminantsExtensiveFromSource($source) ;
		my ($oNew, $totalEntryNum, $fiteredEntryNum) = $o->filterContaminantInstruments($Instrument) ;
#		print Dumper $o ;
#		print Dumper $oNew ;
#		print "$fiteredEntryNum on $totalEntryNum\n" ;
		return ($oNew) ;
	}
	
	## sub
	sub filterContaminantInstrumentTypesTest  {
		my ( $source, $Instrument ) = @_ ;
		my $o = Metabolomics::Fragment::Annotation->getContaminantsExtensiveFromSource($source) ;
		my ($oNew, $totalEntryNum, $fiteredEntryNum) = $o->filterContaminantInstrumentTypes($Instrument) ;
#		print Dumper $o ;
#		print Dumper $oNew ;
#		print "$fiteredEntryNum on $totalEntryNum\n" ;
		return ($oNew) ;
	}
	
	## sub buildTheoPeakBankFromContaminants
	## SUB TEST for 
	sub buildTheoPeakBankFromContaminantsTest {
	    # get values
	    my ( $oBank, $oContaminants, $queryMode ) = @_;
	    
	    $oBank->buildTheoPeakBankFromContaminants($oContaminants, $queryMode ) ;
#	    print Dumper $oBank ;
	    return($oBank) ;
	}
	## End SUB
	
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
	
	## sub fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysis
	sub fullCompareExpPeakListAndTheoFragmentBankFromDataAnalysisTest {
		# get values
		my ($expFile, $theoFile, $mzParent, $template, $tabular) = @_ ;
				
		my $obank = Metabolomics::Fragment::Annotation->getFragmentsFromSource($theoFile) ;
		$obank->buildTheoPeakBankFromFragments($mzParent) ;
		$obank->parsingMsFragments($expFile, 'asheader', 2) ; # get mz in colunm 2
#		print Dumper $obank ;
		$obank->compareExpMzToTheoMzList('DA', 0.05) ;
		
#		print Dumper $obank ;
		
		my $tabularfile = $obank->writeFullTabularWithPeakBankObject($expFile, $template, $tabular) ;
		
		return($tabularfile) ;
		
	}
	
	
}## END BEGIN part
