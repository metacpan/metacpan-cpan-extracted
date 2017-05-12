use Test::More;
use strict;

use Geo::Address::Mail::US;
use Geo::Address::Mail::Standardizer::USPS;

my $std = Geo::Address::Mail::Standardizer::USPS->new;

my %address_designator = (
    'ALY-00' => {
        'input'  => '23 Something ALLEE',
        'output' => '23 SOMETHING ALY'
    },
    'ALY-01' => {
        'input'  => '23 Something ALLEY',
        'output' => '23 SOMETHING ALY'
    },
    'ALY-02' => {
        'input'  => '23 Something ALLY',
        'output' => '23 SOMETHING ALY'
    },
    'ALY-03' => {
        'input'  => '23 Something ALY',
        'output' => '23 SOMETHING ALY'
    },
    'ALY-04' => {
        'input'  => '23 Something ALY.',
        'output' => '23 SOMETHING ALY'
    },
    'ANX-00' => {
        'input'  => '23 Something ANEX',
        'output' => '23 SOMETHING ANX'
    },
    'ANX-01' => {
        'input'  => '23 Something ANNEX',
        'output' => '23 SOMETHING ANX'
    },
    'ANX-02' => {
        'input'  => '23 Something ANNX',
        'output' => '23 SOMETHING ANX'
    },
    'ANX-03' => {
        'input'  => '23 Something ANX',
        'output' => '23 SOMETHING ANX'
    },
    'ANX-04' => {
        'input'  => '23 Something ANX.',
        'output' => '23 SOMETHING ANX'
    },
    'ARC-00' => {
        'input'  => '23 Something ARC',
        'output' => '23 SOMETHING ARC'
    },
    'ARC-01' => {
        'input'  => '23 Something ARC.',
        'output' => '23 SOMETHING ARC'
    },
    'ARC-02' => {
        'input'  => '23 Something ARCADE',
        'output' => '23 SOMETHING ARC'
    },
    'AVE-00' => {
        'input'  => '23 Something AV',
        'output' => '23 SOMETHING AVE'
    },
    'AVE-01' => {
        'input'  => '23 Something AVE',
        'output' => '23 SOMETHING AVE'
    },
    'AVE-02' => {
        'input'  => '23 Something AVE.',
        'output' => '23 SOMETHING AVE'
    },
    'AVE-03' => {
        'input'  => '23 Something AVEN',
        'output' => '23 SOMETHING AVE'
    },
    'AVE-04' => {
        'input'  => '23 Something AVENU',
        'output' => '23 SOMETHING AVE'
    },
    'AVE-05' => {
        'input'  => '23 Something AVENUE',
        'output' => '23 SOMETHING AVE'
    },
    'AVE-06' => {
        'input'  => '23 Something AVN',
        'output' => '23 SOMETHING AVE'
    },
    'AVE-07' => {
        'input'  => '23 Something AVNUE',
        'output' => '23 SOMETHING AVE'
    },
    'BCH-00' => {
        'input'  => '23 Something BCH',
        'output' => '23 SOMETHING BCH'
    },
    'BCH-01' => {
        'input'  => '23 Something BCH.',
        'output' => '23 SOMETHING BCH'
    },
    'BCH-02' => {
        'input'  => '23 Something BEACH',
        'output' => '23 SOMETHING BCH'
    },
    'BG-00' => {
        'input'  => '23 Something BG',
        'output' => '23 SOMETHING BG'
    },
    'BG-01' => {
        'input'  => '23 Something BG.',
        'output' => '23 SOMETHING BG'
    },
    'BG-02' => {
        'input'  => '23 Something BURG',
        'output' => '23 SOMETHING BG'
    },
    'BGS-00' => {
        'input'  => '23 Something BGS',
        'output' => '23 SOMETHING BGS'
    },
    'BGS-01' => {
        'input'  => '23 Something BGS.',
        'output' => '23 SOMETHING BGS'
    },
    'BGS-02' => {
        'input'  => '23 Something BURGS',
        'output' => '23 SOMETHING BGS'
    },
    'BLF-00' => {
        'input'  => '23 Something BLF',
        'output' => '23 SOMETHING BLF'
    },
    'BLF-01' => {
        'input'  => '23 Something BLF.',
        'output' => '23 SOMETHING BLF'
    },
    'BLF-02' => {
        'input'  => '23 Something BLUF',
        'output' => '23 SOMETHING BLF'
    },
    'BLF-03' => {
        'input'  => '23 Something BLUFF',
        'output' => '23 SOMETHING BLF'
    },
    'BLFS-00' => {
        'input'  => '23 Something BLFS',
        'output' => '23 SOMETHING BLFS'
    },
    'BLFS-01' => {
        'input'  => '23 Something BLFS.',
        'output' => '23 SOMETHING BLFS'
    },
    'BLFS-02' => {
        'input'  => '23 Something BLUFFS',
        'output' => '23 SOMETHING BLFS'
    },
    'BLVD-00' => {
        'input'  => '23 Something BLVD',
        'output' => '23 SOMETHING BLVD'
    },
    'BLVD-01' => {
        'input'  => '23 Something BLVD.',
        'output' => '23 SOMETHING BLVD'
    },
    'BLVD-02' => {
        'input'  => '23 Something BOUL',
        'output' => '23 SOMETHING BLVD'
    },
    'BLVD-03' => {
        'input'  => '23 Something BOULEVARD',
        'output' => '23 SOMETHING BLVD'
    },
    'BLVD-04' => {
        'input'  => '23 Something BOULV',
        'output' => '23 SOMETHING BLVD'
    },
    'BND-00' => {
        'input'  => '23 Something BEND',
        'output' => '23 SOMETHING BND'
    },
    'BND-01' => {
        'input'  => '23 Something BND',
        'output' => '23 SOMETHING BND'
    },
    'BND-02' => {
        'input'  => '23 Something BND.',
        'output' => '23 SOMETHING BND'
    },
    'BR-00' => {
        'input'  => '23 Something BR',
        'output' => '23 SOMETHING BR'
    },
    'BR-01' => {
        'input'  => '23 Something BR.',
        'output' => '23 SOMETHING BR'
    },
    'BR-02' => {
        'input'  => '23 Something BRANCH',
        'output' => '23 SOMETHING BR'
    },
    'BR-03' => {
        'input'  => '23 Something BRNCH',
        'output' => '23 SOMETHING BR'
    },
    'BRG-00' => {
        'input'  => '23 Something BRDGE',
        'output' => '23 SOMETHING BRG'
    },
    'BRG-01' => {
        'input'  => '23 Something BRG',
        'output' => '23 SOMETHING BRG'
    },
    'BRG-02' => {
        'input'  => '23 Something BRG.',
        'output' => '23 SOMETHING BRG'
    },
    'BRG-03' => {
        'input'  => '23 Something BRIDGE',
        'output' => '23 SOMETHING BRG'
    },
    'BRK-00' => {
        'input'  => '23 Something BRK',
        'output' => '23 SOMETHING BRK'
    },
    'BRK-01' => {
        'input'  => '23 Something BRK.',
        'output' => '23 SOMETHING BRK'
    },
    'BRK-02' => {
        'input'  => '23 Something BROOK',
        'output' => '23 SOMETHING BRK'
    },
    'BRKS-00' => {
        'input'  => '23 Something BRKS',
        'output' => '23 SOMETHING BRKS'
    },
    'BRKS-01' => {
        'input'  => '23 Something BRKS.',
        'output' => '23 SOMETHING BRKS'
    },
    'BRKS-02' => {
        'input'  => '23 Something BROOKS',
        'output' => '23 SOMETHING BRKS'
    },
    'BTM-00' => {
        'input'  => '23 Something BOT',
        'output' => '23 SOMETHING BTM'
    },
    'BTM-01' => {
        'input'  => '23 Something BOTTM',
        'output' => '23 SOMETHING BTM'
    },
    'BTM-02' => {
        'input'  => '23 Something BOTTOM',
        'output' => '23 SOMETHING BTM'
    },
    'BTM-03' => {
        'input'  => '23 Something BTM',
        'output' => '23 SOMETHING BTM'
    },
    'BTM-04' => {
        'input'  => '23 Something BTM.',
        'output' => '23 SOMETHING BTM'
    },
    'BYP-00' => {
        'input'  => '23 Something BYP',
        'output' => '23 SOMETHING BYP'
    },
    'BYP-01' => {
        'input'  => '23 Something BYP.',
        'output' => '23 SOMETHING BYP'
    },
    'BYP-02' => {
        'input'  => '23 Something BYPA',
        'output' => '23 SOMETHING BYP'
    },
    'BYP-03' => {
        'input'  => '23 Something BYPAS',
        'output' => '23 SOMETHING BYP'
    },
    'BYP-04' => {
        'input'  => '23 Something BYPASS',
        'output' => '23 SOMETHING BYP'
    },
    'BYP-05' => {
        'input'  => '23 Something BYPS',
        'output' => '23 SOMETHING BYP'
    },
    'BYU-00' => {
        'input'  => '23 Something BAYOO',
        'output' => '23 SOMETHING BYU'
    },
    'BYU-01' => {
        'input'  => '23 Something BAYOU',
        'output' => '23 SOMETHING BYU'
    },
    'BYU-02' => {
        'input'  => '23 Something BYU',
        'output' => '23 SOMETHING BYU'
    },
    'BYU-03' => {
        'input'  => '23 Something BYU.',
        'output' => '23 SOMETHING BYU'
    },
    'CIR-00' => {
        'input'  => '23 Something CIR',
        'output' => '23 SOMETHING CIR'
    },
    'CIR-01' => {
        'input'  => '23 Something CIR.',
        'output' => '23 SOMETHING CIR'
    },
    'CIR-02' => {
        'input'  => '23 Something CIRC',
        'output' => '23 SOMETHING CIR'
    },
    'CIR-03' => {
        'input'  => '23 Something CIRCL',
        'output' => '23 SOMETHING CIR'
    },
    'CIR-04' => {
        'input'  => '23 Something CIRCLE',
        'output' => '23 SOMETHING CIR'
    },
    'CIR-05' => {
        'input'  => '23 Something CRCL',
        'output' => '23 SOMETHING CIR'
    },
    'CIR-06' => {
        'input'  => '23 Something CRCLE',
        'output' => '23 SOMETHING CIR'
    },
    'CIRS-00' => {
        'input'  => '23 Something CIRCLES',
        'output' => '23 SOMETHING CIRS'
    },
    'CIRS-01' => {
        'input'  => '23 Something CIRS',
        'output' => '23 SOMETHING CIRS'
    },
    'CIRS-02' => {
        'input'  => '23 Something CIRS.',
        'output' => '23 SOMETHING CIRS'
    },
    'CLB-00' => {
        'input'  => '23 Something CLB',
        'output' => '23 SOMETHING CLB'
    },
    'CLB-01' => {
        'input'  => '23 Something CLB.',
        'output' => '23 SOMETHING CLB'
    },
    'CLB-02' => {
        'input'  => '23 Something CLUB',
        'output' => '23 SOMETHING CLB'
    },
    'CLF-00' => {
        'input'  => '23 Something CLF',
        'output' => '23 SOMETHING CLF'
    },
    'CLF-01' => {
        'input'  => '23 Something CLF.',
        'output' => '23 SOMETHING CLF'
    },
    'CLF-02' => {
        'input'  => '23 Something CLIFF',
        'output' => '23 SOMETHING CLF'
    },
    'CLFS-00' => {
        'input'  => '23 Something CLFS',
        'output' => '23 SOMETHING CLFS'
    },
    'CLFS-01' => {
        'input'  => '23 Something CLFS.',
        'output' => '23 SOMETHING CLFS'
    },
    'CLFS-02' => {
        'input'  => '23 Something CLIFFS',
        'output' => '23 SOMETHING CLFS'
    },
    'CMN-00' => {
        'input'  => '23 Something CMN',
        'output' => '23 SOMETHING CMN'
    },
    'CMN-01' => {
        'input'  => '23 Something CMN.',
        'output' => '23 SOMETHING CMN'
    },
    'CMN-02' => {
        'input'  => '23 Something COMMON',
        'output' => '23 SOMETHING CMN'
    },
    'COR-00' => {
        'input'  => '23 Something COR',
        'output' => '23 SOMETHING COR'
    },
    'COR-01' => {
        'input'  => '23 Something COR.',
        'output' => '23 SOMETHING COR'
    },
    'COR-02' => {
        'input'  => '23 Something CORNER',
        'output' => '23 SOMETHING COR'
    },
    'CORS-00' => {
        'input'  => '23 Something CORNERS',
        'output' => '23 SOMETHING CORS'
    },
    'CORS-01' => {
        'input'  => '23 Something CORS',
        'output' => '23 SOMETHING CORS'
    },
    'CORS-02' => {
        'input'  => '23 Something CORS.',
        'output' => '23 SOMETHING CORS'
    },
    'CP-00' => {
        'input'  => '23 Something CAMP',
        'output' => '23 SOMETHING CP'
    },
    'CP-01' => {
        'input'  => '23 Something CMP',
        'output' => '23 SOMETHING CP'
    },
    'CP-02' => {
        'input'  => '23 Something CP',
        'output' => '23 SOMETHING CP'
    },
    'CP-03' => {
        'input'  => '23 Something CP.',
        'output' => '23 SOMETHING CP'
    },
    'CPE-00' => {
        'input'  => '23 Something CAPE',
        'output' => '23 SOMETHING CPE'
    },
    'CPE-01' => {
        'input'  => '23 Something CPE',
        'output' => '23 SOMETHING CPE'
    },
    'CPE-02' => {
        'input'  => '23 Something CPE.',
        'output' => '23 SOMETHING CPE'
    },
    'CRES-00' => {
        'input'  => '23 Something CRECENT',
        'output' => '23 SOMETHING CRES'
    },
    'CRES-01' => {
        'input'  => '23 Something CRES',
        'output' => '23 SOMETHING CRES'
    },
    'CRES-02' => {
        'input'  => '23 Something CRES.',
        'output' => '23 SOMETHING CRES'
    },
    'CRES-03' => {
        'input'  => '23 Something CRESCENT',
        'output' => '23 SOMETHING CRES'
    },
    'CRES-04' => {
        'input'  => '23 Something CRESENT',
        'output' => '23 SOMETHING CRES'
    },
    'CRES-05' => {
        'input'  => '23 Something CRSCNT',
        'output' => '23 SOMETHING CRES'
    },
    'CRES-06' => {
        'input'  => '23 Something CRSENT',
        'output' => '23 SOMETHING CRES'
    },
    'CRES-07' => {
        'input'  => '23 Something CRSNT',
        'output' => '23 SOMETHING CRES'
    },
    'CRK-00' => {
        'input'  => '23 Something CK',
        'output' => '23 SOMETHING CRK'
    },
    'CRK-01' => {
        'input'  => '23 Something CR',
        'output' => '23 SOMETHING CRK'
    },
    'CRK-02' => {
        'input'  => '23 Something CREEK',
        'output' => '23 SOMETHING CRK'
    },
    'CRK-03' => {
        'input'  => '23 Something CRK',
        'output' => '23 SOMETHING CRK'
    },
    'CRK-04' => {
        'input'  => '23 Something CRK.',
        'output' => '23 SOMETHING CRK'
    },
    'CRSE-00' => {
        'input'  => '23 Something COURSE',
        'output' => '23 SOMETHING CRSE'
    },
    'CRSE-01' => {
        'input'  => '23 Something CRSE',
        'output' => '23 SOMETHING CRSE'
    },
    'CRSE-02' => {
        'input'  => '23 Something CRSE.',
        'output' => '23 SOMETHING CRSE'
    },
    'CRST-00' => {
        'input'  => '23 Something CREST',
        'output' => '23 SOMETHING CRST'
    },
    'CRST-01' => {
        'input'  => '23 Something CRST',
        'output' => '23 SOMETHING CRST'
    },
    'CRST-02' => {
        'input'  => '23 Something CRST.',
        'output' => '23 SOMETHING CRST'
    },
    'CSWY-00' => {
        'input'  => '23 Something CAUSEWAY',
        'output' => '23 SOMETHING CSWY'
    },
    'CSWY-01' => {
        'input'  => '23 Something CAUSWAY',
        'output' => '23 SOMETHING CSWY'
    },
    'CSWY-02' => {
        'input'  => '23 Something CSWY',
        'output' => '23 SOMETHING CSWY'
    },
    'CSWY-03' => {
        'input'  => '23 Something CSWY.',
        'output' => '23 SOMETHING CSWY'
    },
    'CT-00' => {
        'input'  => '23 Something COURT',
        'output' => '23 SOMETHING CT'
    },
    'CT-01' => {
        'input'  => '23 Something CRT',
        'output' => '23 SOMETHING CT'
    },
    'CT-02' => {
        'input'  => '23 Something CT',
        'output' => '23 SOMETHING CT'
    },
    'CT-03' => {
        'input'  => '23 Something CT.',
        'output' => '23 SOMETHING CT'
    },
    'CTR-00' => {
        'input'  => '23 Something CENT',
        'output' => '23 SOMETHING CTR'
    },
    'CTR-01' => {
        'input'  => '23 Something CENTER',
        'output' => '23 SOMETHING CTR'
    },
    'CTR-02' => {
        'input'  => '23 Something CENTR',
        'output' => '23 SOMETHING CTR'
    },
    'CTR-03' => {
        'input'  => '23 Something CENTRE',
        'output' => '23 SOMETHING CTR'
    },
    'CTR-04' => {
        'input'  => '23 Something CNTER',
        'output' => '23 SOMETHING CTR'
    },
    'CTR-05' => {
        'input'  => '23 Something CNTR',
        'output' => '23 SOMETHING CTR'
    },
    'CTR-06' => {
        'input'  => '23 Something CTR',
        'output' => '23 SOMETHING CTR'
    },
    'CTR-07' => {
        'input'  => '23 Something CTR.',
        'output' => '23 SOMETHING CTR'
    },
    'CTRS-00' => {
        'input'  => '23 Something CENTERS',
        'output' => '23 SOMETHING CTRS'
    },
    'CTRS-01' => {
        'input'  => '23 Something CTRS',
        'output' => '23 SOMETHING CTRS'
    },
    'CTRS-02' => {
        'input'  => '23 Something CTRS.',
        'output' => '23 SOMETHING CTRS'
    },
    'CTS-00' => {
        'input'  => '23 Something COURTS',
        'output' => '23 SOMETHING CTS'
    },
    'CTS-01' => {
        'input'  => '23 Something CTS',
        'output' => '23 SOMETHING CTS'
    },
    'CTS-02' => {
        'input'  => '23 Something CTS.',
        'output' => '23 SOMETHING CTS'
    },
    'CURV-00' => {
        'input'  => '23 Something CURV',
        'output' => '23 SOMETHING CURV'
    },
    'CURV-01' => {
        'input'  => '23 Something CURV.',
        'output' => '23 SOMETHING CURV'
    },
    'CURV-02' => {
        'input'  => '23 Something CURVE',
        'output' => '23 SOMETHING CURV'
    },
    'CV-00' => {
        'input'  => '23 Something COVE',
        'output' => '23 SOMETHING CV'
    },
    'CV-01' => {
        'input'  => '23 Something CV',
        'output' => '23 SOMETHING CV'
    },
    'CV-02' => {
        'input'  => '23 Something CV.',
        'output' => '23 SOMETHING CV'
    },
    'CVS-00' => {
        'input'  => '23 Something COVES',
        'output' => '23 SOMETHING CVS'
    },
    'CVS-01' => {
        'input'  => '23 Something CVS',
        'output' => '23 SOMETHING CVS'
    },
    'CVS-02' => {
        'input'  => '23 Something CVS.',
        'output' => '23 SOMETHING CVS'
    },
    'CYN-00' => {
        'input'  => '23 Something CANYN',
        'output' => '23 SOMETHING CYN'
    },
    'CYN-01' => {
        'input'  => '23 Something CANYON',
        'output' => '23 SOMETHING CYN'
    },
    'CYN-02' => {
        'input'  => '23 Something CNYN',
        'output' => '23 SOMETHING CYN'
    },
    'CYN-03' => {
        'input'  => '23 Something CYN',
        'output' => '23 SOMETHING CYN'
    },
    'CYN-04' => {
        'input'  => '23 Something CYN.',
        'output' => '23 SOMETHING CYN'
    },
    'DL-00' => {
        'input'  => '23 Something DALE',
        'output' => '23 SOMETHING DL'
    },
    'DL-01' => {
        'input'  => '23 Something DL',
        'output' => '23 SOMETHING DL'
    },
    'DL-02' => {
        'input'  => '23 Something DL.',
        'output' => '23 SOMETHING DL'
    },
    'DM-00' => {
        'input'  => '23 Something DAM',
        'output' => '23 SOMETHING DM'
    },
    'DM-01' => {
        'input'  => '23 Something DM',
        'output' => '23 SOMETHING DM'
    },
    'DM-02' => {
        'input'  => '23 Something DM.',
        'output' => '23 SOMETHING DM'
    },
    'DR-00' => {
        'input'  => '23 Something DR',
        'output' => '23 SOMETHING DR'
    },
    'DR-01' => {
        'input'  => '23 Something DR.',
        'output' => '23 SOMETHING DR'
    },
    'DR-02' => {
        'input'  => '23 Something DRIV',
        'output' => '23 SOMETHING DR'
    },
    'DR-03' => {
        'input'  => '23 Something DRIVE',
        'output' => '23 SOMETHING DR'
    },
    'DR-04' => {
        'input'  => '23 Something DRV',
        'output' => '23 SOMETHING DR'
    },
    'DRS-00' => {
        'input'  => '23 Something DRIVES',
        'output' => '23 SOMETHING DRS'
    },
    'DRS-01' => {
        'input'  => '23 Something DRS',
        'output' => '23 SOMETHING DRS'
    },
    'DRS-02' => {
        'input'  => '23 Something DRS.',
        'output' => '23 SOMETHING DRS'
    },
    'DV-00' => {
        'input'  => '23 Something DIV',
        'output' => '23 SOMETHING DV'
    },
    'DV-01' => {
        'input'  => '23 Something DIVIDE',
        'output' => '23 SOMETHING DV'
    },
    'DV-02' => {
        'input'  => '23 Something DV',
        'output' => '23 SOMETHING DV'
    },
    'DV-03' => {
        'input'  => '23 Something DV.',
        'output' => '23 SOMETHING DV'
    },
    'DV-04' => {
        'input'  => '23 Something DVD',
        'output' => '23 SOMETHING DV'
    },
    'EST-00' => {
        'input'  => '23 Something EST',
        'output' => '23 SOMETHING EST'
    },
    'EST-01' => {
        'input'  => '23 Something EST.',
        'output' => '23 SOMETHING EST'
    },
    'EST-02' => {
        'input'  => '23 Something ESTATE',
        'output' => '23 SOMETHING EST'
    },
    'ESTS-00' => {
        'input'  => '23 Something ESTATES',
        'output' => '23 SOMETHING ESTS'
    },
    'ESTS-01' => {
        'input'  => '23 Something ESTS',
        'output' => '23 SOMETHING ESTS'
    },
    'ESTS-02' => {
        'input'  => '23 Something ESTS.',
        'output' => '23 SOMETHING ESTS'
    },
    'EXPY-00' => {
        'input'  => '23 Something EXP',
        'output' => '23 SOMETHING EXPY'
    },
    'EXPY-01' => {
        'input'  => '23 Something EXPR',
        'output' => '23 SOMETHING EXPY'
    },
    'EXPY-02' => {
        'input'  => '23 Something EXPRESS',
        'output' => '23 SOMETHING EXPY'
    },
    'EXPY-03' => {
        'input'  => '23 Something EXPRESSWAY',
        'output' => '23 SOMETHING EXPY'
    },
    'EXPY-04' => {
        'input'  => '23 Something EXPW',
        'output' => '23 SOMETHING EXPY'
    },
    'EXPY-05' => {
        'input'  => '23 Something EXPY',
        'output' => '23 SOMETHING EXPY'
    },
    'EXPY-06' => {
        'input'  => '23 Something EXPY.',
        'output' => '23 SOMETHING EXPY'
    },
    'EXT-00' => {
        'input'  => '23 Something EXT',
        'output' => '23 SOMETHING EXT'
    },
    'EXT-01' => {
        'input'  => '23 Something EXT.',
        'output' => '23 SOMETHING EXT'
    },
    'EXT-02' => {
        'input'  => '23 Something EXTENSION',
        'output' => '23 SOMETHING EXT'
    },
    'EXT-03' => {
        'input'  => '23 Something EXTN',
        'output' => '23 SOMETHING EXT'
    },
    'EXT-04' => {
        'input'  => '23 Something EXTNSN',
        'output' => '23 SOMETHING EXT'
    },
    'EXTS-00' => {
        'input'  => '23 Something EXTENSIONS',
        'output' => '23 SOMETHING EXTS'
    },
    'EXTS-01' => {
        'input'  => '23 Something EXTS',
        'output' => '23 SOMETHING EXTS'
    },
    'EXTS-02' => {
        'input'  => '23 Something EXTS.',
        'output' => '23 SOMETHING EXTS'
    },
    'FALL-00' => {
        'input'  => '23 Something FALL',
        'output' => '23 SOMETHING FALL'
    },
    'FALL-01' => {
        'input'  => '23 Something FALL.',
        'output' => '23 SOMETHING FALL'
    },
    'FLD-00' => {
        'input'  => '23 Something FIELD',
        'output' => '23 SOMETHING FLD'
    },
    'FLD-01' => {
        'input'  => '23 Something FLD',
        'output' => '23 SOMETHING FLD'
    },
    'FLD-02' => {
        'input'  => '23 Something FLD.',
        'output' => '23 SOMETHING FLD'
    },
    'FLDS-00' => {
        'input'  => '23 Something FIELDS',
        'output' => '23 SOMETHING FLDS'
    },
    'FLDS-01' => {
        'input'  => '23 Something FLDS',
        'output' => '23 SOMETHING FLDS'
    },
    'FLDS-02' => {
        'input'  => '23 Something FLDS.',
        'output' => '23 SOMETHING FLDS'
    },
    'FLS-00' => {
        'input'  => '23 Something FALLS',
        'output' => '23 SOMETHING FLS'
    },
    'FLS-01' => {
        'input'  => '23 Something FLS',
        'output' => '23 SOMETHING FLS'
    },
    'FLS-02' => {
        'input'  => '23 Something FLS.',
        'output' => '23 SOMETHING FLS'
    },
    'FLT-00' => {
        'input'  => '23 Something FLAT',
        'output' => '23 SOMETHING FLT'
    },
    'FLT-01' => {
        'input'  => '23 Something FLT',
        'output' => '23 SOMETHING FLT'
    },
    'FLT-02' => {
        'input'  => '23 Something FLT.',
        'output' => '23 SOMETHING FLT'
    },
    'FLTS-00' => {
        'input'  => '23 Something FLATS',
        'output' => '23 SOMETHING FLTS'
    },
    'FLTS-01' => {
        'input'  => '23 Something FLTS',
        'output' => '23 SOMETHING FLTS'
    },
    'FLTS-02' => {
        'input'  => '23 Something FLTS.',
        'output' => '23 SOMETHING FLTS'
    },
    'FRD-00' => {
        'input'  => '23 Something FORD',
        'output' => '23 SOMETHING FRD'
    },
    'FRD-01' => {
        'input'  => '23 Something FRD',
        'output' => '23 SOMETHING FRD'
    },
    'FRD-02' => {
        'input'  => '23 Something FRD.',
        'output' => '23 SOMETHING FRD'
    },
    'FRDS-00' => {
        'input'  => '23 Something FORDS',
        'output' => '23 SOMETHING FRDS'
    },
    'FRDS-01' => {
        'input'  => '23 Something FRDS',
        'output' => '23 SOMETHING FRDS'
    },
    'FRDS-02' => {
        'input'  => '23 Something FRDS.',
        'output' => '23 SOMETHING FRDS'
    },
    'FRG-00' => {
        'input'  => '23 Something FORG',
        'output' => '23 SOMETHING FRG'
    },
    'FRG-01' => {
        'input'  => '23 Something FORGE',
        'output' => '23 SOMETHING FRG'
    },
    'FRG-02' => {
        'input'  => '23 Something FRG',
        'output' => '23 SOMETHING FRG'
    },
    'FRG-03' => {
        'input'  => '23 Something FRG.',
        'output' => '23 SOMETHING FRG'
    },
    'FRGS-00' => {
        'input'  => '23 Something FORGES',
        'output' => '23 SOMETHING FRGS'
    },
    'FRGS-01' => {
        'input'  => '23 Something FRGS',
        'output' => '23 SOMETHING FRGS'
    },
    'FRGS-02' => {
        'input'  => '23 Something FRGS.',
        'output' => '23 SOMETHING FRGS'
    },
    'FRK-00' => {
        'input'  => '23 Something FORK',
        'output' => '23 SOMETHING FRK'
    },
    'FRK-01' => {
        'input'  => '23 Something FRK',
        'output' => '23 SOMETHING FRK'
    },
    'FRK-02' => {
        'input'  => '23 Something FRK.',
        'output' => '23 SOMETHING FRK'
    },
    'FRKS-00' => {
        'input'  => '23 Something FORKS',
        'output' => '23 SOMETHING FRKS'
    },
    'FRKS-01' => {
        'input'  => '23 Something FRKS',
        'output' => '23 SOMETHING FRKS'
    },
    'FRKS-02' => {
        'input'  => '23 Something FRKS.',
        'output' => '23 SOMETHING FRKS'
    },
    'FRST-00' => {
        'input'  => '23 Something FOREST',
        'output' => '23 SOMETHING FRST'
    },
    'FRST-01' => {
        'input'  => '23 Something FORESTS',
        'output' => '23 SOMETHING FRST'
    },
    'FRST-02' => {
        'input'  => '23 Something FRST',
        'output' => '23 SOMETHING FRST'
    },
    'FRST-03' => {
        'input'  => '23 Something FRST.',
        'output' => '23 SOMETHING FRST'
    },
    'FRY-00' => {
        'input'  => '23 Something FERRY',
        'output' => '23 SOMETHING FRY'
    },
    'FRY-01' => {
        'input'  => '23 Something FRRY',
        'output' => '23 SOMETHING FRY'
    },
    'FRY-02' => {
        'input'  => '23 Something FRY',
        'output' => '23 SOMETHING FRY'
    },
    'FRY-03' => {
        'input'  => '23 Something FRY.',
        'output' => '23 SOMETHING FRY'
    },
    'FT-00' => {
        'input'  => '23 Something FORT',
        'output' => '23 SOMETHING FT'
    },
    'FT-01' => {
        'input'  => '23 Something FRT',
        'output' => '23 SOMETHING FT'
    },
    'FT-02' => {
        'input'  => '23 Something FT',
        'output' => '23 SOMETHING FT'
    },
    'FT-03' => {
        'input'  => '23 Something FT.',
        'output' => '23 SOMETHING FT'
    },
    'FWY-00' => {
        'input'  => '23 Something FREEWAY',
        'output' => '23 SOMETHING FWY'
    },
    'FWY-01' => {
        'input'  => '23 Something FREEWY',
        'output' => '23 SOMETHING FWY'
    },
    'FWY-02' => {
        'input'  => '23 Something FRWAY',
        'output' => '23 SOMETHING FWY'
    },
    'FWY-03' => {
        'input'  => '23 Something FRWY',
        'output' => '23 SOMETHING FWY'
    },
    'FWY-04' => {
        'input'  => '23 Something FWY',
        'output' => '23 SOMETHING FWY'
    },
    'FWY-05' => {
        'input'  => '23 Something FWY.',
        'output' => '23 SOMETHING FWY'
    },
    'GDN-00' => {
        'input'  => '23 Something GARDEN',
        'output' => '23 SOMETHING GDN'
    },
    'GDN-01' => {
        'input'  => '23 Something GARDN',
        'output' => '23 SOMETHING GDN'
    },
    'GDN-02' => {
        'input'  => '23 Something GDN',
        'output' => '23 SOMETHING GDN'
    },
    'GDN-03' => {
        'input'  => '23 Something GDN.',
        'output' => '23 SOMETHING GDN'
    },
    'GDN-04' => {
        'input'  => '23 Something GRDEN',
        'output' => '23 SOMETHING GDN'
    },
    'GDN-05' => {
        'input'  => '23 Something GRDN',
        'output' => '23 SOMETHING GDN'
    },
    'GDNS-00' => {
        'input'  => '23 Something GARDENS',
        'output' => '23 SOMETHING GDNS'
    },
    'GDNS-01' => {
        'input'  => '23 Something GDNS',
        'output' => '23 SOMETHING GDNS'
    },
    'GDNS-02' => {
        'input'  => '23 Something GDNS.',
        'output' => '23 SOMETHING GDNS'
    },
    'GDNS-03' => {
        'input'  => '23 Something GRDNS',
        'output' => '23 SOMETHING GDNS'
    },
    'GLN-00' => {
        'input'  => '23 Something GLEN',
        'output' => '23 SOMETHING GLN'
    },
    'GLN-01' => {
        'input'  => '23 Something GLN',
        'output' => '23 SOMETHING GLN'
    },
    'GLN-02' => {
        'input'  => '23 Something GLN.',
        'output' => '23 SOMETHING GLN'
    },
    'GLNS-00' => {
        'input'  => '23 Something GLENS',
        'output' => '23 SOMETHING GLNS'
    },
    'GLNS-01' => {
        'input'  => '23 Something GLNS',
        'output' => '23 SOMETHING GLNS'
    },
    'GLNS-02' => {
        'input'  => '23 Something GLNS.',
        'output' => '23 SOMETHING GLNS'
    },
    'GRN-00' => {
        'input'  => '23 Something GREEN',
        'output' => '23 SOMETHING GRN'
    },
    'GRN-01' => {
        'input'  => '23 Something GRN',
        'output' => '23 SOMETHING GRN'
    },
    'GRN-02' => {
        'input'  => '23 Something GRN.',
        'output' => '23 SOMETHING GRN'
    },
    'GRNS-00' => {
        'input'  => '23 Something GREENS',
        'output' => '23 SOMETHING GRNS'
    },
    'GRNS-01' => {
        'input'  => '23 Something GRNS',
        'output' => '23 SOMETHING GRNS'
    },
    'GRNS-02' => {
        'input'  => '23 Something GRNS.',
        'output' => '23 SOMETHING GRNS'
    },
    'GRV-00' => {
        'input'  => '23 Something GROV',
        'output' => '23 SOMETHING GRV'
    },
    'GRV-01' => {
        'input'  => '23 Something GROVE',
        'output' => '23 SOMETHING GRV'
    },
    'GRV-02' => {
        'input'  => '23 Something GRV',
        'output' => '23 SOMETHING GRV'
    },
    'GRV-03' => {
        'input'  => '23 Something GRV.',
        'output' => '23 SOMETHING GRV'
    },
    'GRVS-00' => {
        'input'  => '23 Something GROVES',
        'output' => '23 SOMETHING GRVS'
    },
    'GRVS-01' => {
        'input'  => '23 Something GRVS',
        'output' => '23 SOMETHING GRVS'
    },
    'GRVS-02' => {
        'input'  => '23 Something GRVS.',
        'output' => '23 SOMETHING GRVS'
    },
    'GTWY-00' => {
        'input'  => '23 Something GATEWAY',
        'output' => '23 SOMETHING GTWY'
    },
    'GTWY-01' => {
        'input'  => '23 Something GATEWY',
        'output' => '23 SOMETHING GTWY'
    },
    'GTWY-02' => {
        'input'  => '23 Something GATWAY',
        'output' => '23 SOMETHING GTWY'
    },
    'GTWY-03' => {
        'input'  => '23 Something GTWAY',
        'output' => '23 SOMETHING GTWY'
    },
    'GTWY-04' => {
        'input'  => '23 Something GTWY',
        'output' => '23 SOMETHING GTWY'
    },
    'GTWY-05' => {
        'input'  => '23 Something GTWY.',
        'output' => '23 SOMETHING GTWY'
    },
    'HBR-00' => {
        'input'  => '23 Something HARB',
        'output' => '23 SOMETHING HBR'
    },
    'HBR-01' => {
        'input'  => '23 Something HARBOR',
        'output' => '23 SOMETHING HBR'
    },
    'HBR-02' => {
        'input'  => '23 Something HARBR',
        'output' => '23 SOMETHING HBR'
    },
    'HBR-03' => {
        'input'  => '23 Something HBR',
        'output' => '23 SOMETHING HBR'
    },
    'HBR-04' => {
        'input'  => '23 Something HBR.',
        'output' => '23 SOMETHING HBR'
    },
    'HBR-05' => {
        'input'  => '23 Something HRBOR',
        'output' => '23 SOMETHING HBR'
    },
    'HBRS-00' => {
        'input'  => '23 Something HARBORS',
        'output' => '23 SOMETHING HBRS'
    },
    'HBRS-01' => {
        'input'  => '23 Something HBRS',
        'output' => '23 SOMETHING HBRS'
    },
    'HBRS-02' => {
        'input'  => '23 Something HBRS.',
        'output' => '23 SOMETHING HBRS'
    },
    'HL-00' => {
        'input'  => '23 Something HILL',
        'output' => '23 SOMETHING HL'
    },
    'HL-01' => {
        'input'  => '23 Something HL',
        'output' => '23 SOMETHING HL'
    },
    'HL-02' => {
        'input'  => '23 Something HL.',
        'output' => '23 SOMETHING HL'
    },
    'HLS-00' => {
        'input'  => '23 Something HILLS',
        'output' => '23 SOMETHING HLS'
    },
    'HLS-01' => {
        'input'  => '23 Something HLS',
        'output' => '23 SOMETHING HLS'
    },
    'HLS-02' => {
        'input'  => '23 Something HLS.',
        'output' => '23 SOMETHING HLS'
    },
    'HOLW-00' => {
        'input'  => '23 Something HLLW',
        'output' => '23 SOMETHING HOLW'
    },
    'HOLW-01' => {
        'input'  => '23 Something HOLLOW',
        'output' => '23 SOMETHING HOLW'
    },
    'HOLW-02' => {
        'input'  => '23 Something HOLLOWS',
        'output' => '23 SOMETHING HOLW'
    },
    'HOLW-03' => {
        'input'  => '23 Something HOLW',
        'output' => '23 SOMETHING HOLW'
    },
    'HOLW-04' => {
        'input'  => '23 Something HOLW.',
        'output' => '23 SOMETHING HOLW'
    },
    'HOLW-05' => {
        'input'  => '23 Something HOLWS',
        'output' => '23 SOMETHING HOLW'
    },
    'HTS-00' => {
        'input'  => '23 Something HEIGHT',
        'output' => '23 SOMETHING HTS'
    },
    'HTS-01' => {
        'input'  => '23 Something HEIGHTS',
        'output' => '23 SOMETHING HTS'
    },
    'HTS-02' => {
        'input'  => '23 Something HGTS',
        'output' => '23 SOMETHING HTS'
    },
    'HTS-03' => {
        'input'  => '23 Something HT',
        'output' => '23 SOMETHING HTS'
    },
    'HTS-04' => {
        'input'  => '23 Something HTS',
        'output' => '23 SOMETHING HTS'
    },
    'HTS-05' => {
        'input'  => '23 Something HTS.',
        'output' => '23 SOMETHING HTS'
    },
    'HVN-00' => {
        'input'  => '23 Something HAVEN',
        'output' => '23 SOMETHING HVN'
    },
    'HVN-01' => {
        'input'  => '23 Something HAVN',
        'output' => '23 SOMETHING HVN'
    },
    'HVN-02' => {
        'input'  => '23 Something HVN',
        'output' => '23 SOMETHING HVN'
    },
    'HVN-03' => {
        'input'  => '23 Something HVN.',
        'output' => '23 SOMETHING HVN'
    },
    'HWY-00' => {
        'input'  => '23 Something HIGHWAY',
        'output' => '23 SOMETHING HWY'
    },
    'HWY-01' => {
        'input'  => '23 Something HIGHWY',
        'output' => '23 SOMETHING HWY'
    },
    'HWY-02' => {
        'input'  => '23 Something HIWAY',
        'output' => '23 SOMETHING HWY'
    },
    'HWY-03' => {
        'input'  => '23 Something HIWY',
        'output' => '23 SOMETHING HWY'
    },
    'HWY-04' => {
        'input'  => '23 Something HWAY',
        'output' => '23 SOMETHING HWY'
    },
    'HWY-05' => {
        'input'  => '23 Something HWY',
        'output' => '23 SOMETHING HWY'
    },
    'HWY-06' => {
        'input'  => '23 Something HWY.',
        'output' => '23 SOMETHING HWY'
    },
    'INLT-00' => {
        'input'  => '23 Something INLET',
        'output' => '23 SOMETHING INLT'
    },
    'INLT-01' => {
        'input'  => '23 Something INLT',
        'output' => '23 SOMETHING INLT'
    },
    'INLT-02' => {
        'input'  => '23 Something INLT.',
        'output' => '23 SOMETHING INLT'
    },
    'IS-00' => {
        'input'  => '23 Something IS',
        'output' => '23 SOMETHING IS'
    },
    'IS-01' => {
        'input'  => '23 Something IS.',
        'output' => '23 SOMETHING IS'
    },
    'IS-02' => {
        'input'  => '23 Something ISLAND',
        'output' => '23 SOMETHING IS'
    },
    'IS-03' => {
        'input'  => '23 Something ISLND',
        'output' => '23 SOMETHING IS'
    },
    'ISLE-00' => {
        'input'  => '23 Something ISLE',
        'output' => '23 SOMETHING ISLE'
    },
    'ISLE-01' => {
        'input'  => '23 Something ISLE.',
        'output' => '23 SOMETHING ISLE'
    },
    'ISLE-02' => {
        'input'  => '23 Something ISLES',
        'output' => '23 SOMETHING ISLE'
    },
    'ISS-00' => {
        'input'  => '23 Something ISLANDS',
        'output' => '23 SOMETHING ISS'
    },
    'ISS-01' => {
        'input'  => '23 Something ISLNDS',
        'output' => '23 SOMETHING ISS'
    },
    'ISS-02' => {
        'input'  => '23 Something ISS',
        'output' => '23 SOMETHING ISS'
    },
    'ISS-03' => {
        'input'  => '23 Something ISS.',
        'output' => '23 SOMETHING ISS'
    },
    'JCT-00' => {
        'input'  => '23 Something JCT',
        'output' => '23 SOMETHING JCT'
    },
    'JCT-01' => {
        'input'  => '23 Something JCT.',
        'output' => '23 SOMETHING JCT'
    },
    'JCT-02' => {
        'input'  => '23 Something JCTION',
        'output' => '23 SOMETHING JCT'
    },
    'JCT-03' => {
        'input'  => '23 Something JCTN',
        'output' => '23 SOMETHING JCT'
    },
    'JCT-04' => {
        'input'  => '23 Something JUCTION',
        'output' => '23 SOMETHING JCT'
    },
    'JCT-05' => {
        'input'  => '23 Something JUCTN',
        'output' => '23 SOMETHING JCT'
    },
    'JCT-06' => {
        'input'  => '23 Something JUCTON',
        'output' => '23 SOMETHING JCT'
    },
    'JCTS-00' => {
        'input'  => '23 Something JCTNS',
        'output' => '23 SOMETHING JCTS'
    },
    'JCTS-01' => {
        'input'  => '23 Something JCTS',
        'output' => '23 SOMETHING JCTS'
    },
    'JCTS-02' => {
        'input'  => '23 Something JCTS.',
        'output' => '23 SOMETHING JCTS'
    },
    'JCTS-03' => {
        'input'  => '23 Something JUCTIONS',
        'output' => '23 SOMETHING JCTS'
    },
    'KNL-00' => {
        'input'  => '23 Something KNL',
        'output' => '23 SOMETHING KNL'
    },
    'KNL-01' => {
        'input'  => '23 Something KNL.',
        'output' => '23 SOMETHING KNL'
    },
    'KNL-02' => {
        'input'  => '23 Something KNOL',
        'output' => '23 SOMETHING KNL'
    },
    'KNL-03' => {
        'input'  => '23 Something KNOLL',
        'output' => '23 SOMETHING KNL'
    },
    'KNLS-00' => {
        'input'  => '23 Something KNLS',
        'output' => '23 SOMETHING KNLS'
    },
    'KNLS-01' => {
        'input'  => '23 Something KNLS.',
        'output' => '23 SOMETHING KNLS'
    },
    'KNLS-02' => {
        'input'  => '23 Something KNOLLS',
        'output' => '23 SOMETHING KNLS'
    },
    'KY-00' => {
        'input'  => '23 Something KEY',
        'output' => '23 SOMETHING KY'
    },
    'KY-01' => {
        'input'  => '23 Something KY',
        'output' => '23 SOMETHING KY'
    },
    'KY-02' => {
        'input'  => '23 Something KY.',
        'output' => '23 SOMETHING KY'
    },
    'KYS-00' => {
        'input'  => '23 Something KEYS',
        'output' => '23 SOMETHING KYS'
    },
    'KYS-01' => {
        'input'  => '23 Something KYS',
        'output' => '23 SOMETHING KYS'
    },
    'KYS-02' => {
        'input'  => '23 Something KYS.',
        'output' => '23 SOMETHING KYS'
    },
    'LAND-00' => {
        'input'  => '23 Something LAND',
        'output' => '23 SOMETHING LAND'
    },
    'LAND-01' => {
        'input'  => '23 Something LAND.',
        'output' => '23 SOMETHING LAND'
    },
    'LCK-00' => {
        'input'  => '23 Something LCK',
        'output' => '23 SOMETHING LCK'
    },
    'LCK-01' => {
        'input'  => '23 Something LCK.',
        'output' => '23 SOMETHING LCK'
    },
    'LCK-02' => {
        'input'  => '23 Something LOCK',
        'output' => '23 SOMETHING LCK'
    },
    'LCKS-00' => {
        'input'  => '23 Something LCKS',
        'output' => '23 SOMETHING LCKS'
    },
    'LCKS-01' => {
        'input'  => '23 Something LCKS.',
        'output' => '23 SOMETHING LCKS'
    },
    'LCKS-02' => {
        'input'  => '23 Something LOCKS',
        'output' => '23 SOMETHING LCKS'
    },
    'LDG-00' => {
        'input'  => '23 Something LDG',
        'output' => '23 SOMETHING LDG'
    },
    'LDG-01' => {
        'input'  => '23 Something LDG.',
        'output' => '23 SOMETHING LDG'
    },
    'LDG-02' => {
        'input'  => '23 Something LDGE',
        'output' => '23 SOMETHING LDG'
    },
    'LDG-03' => {
        'input'  => '23 Something LODG',
        'output' => '23 SOMETHING LDG'
    },
    'LDG-04' => {
        'input'  => '23 Something LODGE',
        'output' => '23 SOMETHING LDG'
    },
    'LF-00' => {
        'input'  => '23 Something LF',
        'output' => '23 SOMETHING LF'
    },
    'LF-01' => {
        'input'  => '23 Something LF.',
        'output' => '23 SOMETHING LF'
    },
    'LF-02' => {
        'input'  => '23 Something LOAF',
        'output' => '23 SOMETHING LF'
    },
    'LGT-00' => {
        'input'  => '23 Something LGT',
        'output' => '23 SOMETHING LGT'
    },
    'LGT-01' => {
        'input'  => '23 Something LGT.',
        'output' => '23 SOMETHING LGT'
    },
    'LGT-02' => {
        'input'  => '23 Something LIGHT',
        'output' => '23 SOMETHING LGT'
    },
    'LGTS-00' => {
        'input'  => '23 Something LGTS',
        'output' => '23 SOMETHING LGTS'
    },
    'LGTS-01' => {
        'input'  => '23 Something LGTS.',
        'output' => '23 SOMETHING LGTS'
    },
    'LGTS-02' => {
        'input'  => '23 Something LIGHTS',
        'output' => '23 SOMETHING LGTS'
    },
    'LK-00' => {
        'input'  => '23 Something LAKE',
        'output' => '23 SOMETHING LK'
    },
    'LK-01' => {
        'input'  => '23 Something LK',
        'output' => '23 SOMETHING LK'
    },
    'LK-02' => {
        'input'  => '23 Something LK.',
        'output' => '23 SOMETHING LK'
    },
    'LKS-00' => {
        'input'  => '23 Something LAKES',
        'output' => '23 SOMETHING LKS'
    },
    'LKS-01' => {
        'input'  => '23 Something LKS',
        'output' => '23 SOMETHING LKS'
    },
    'LKS-02' => {
        'input'  => '23 Something LKS.',
        'output' => '23 SOMETHING LKS'
    },
    'LN-00' => {
        'input'  => '23 Something LA',
        'output' => '23 SOMETHING LN'
    },
    'LN-01' => {
        'input'  => '23 Something LANE',
        'output' => '23 SOMETHING LN'
    },
    'LN-02' => {
        'input'  => '23 Something LANES',
        'output' => '23 SOMETHING LN'
    },
    'LN-03' => {
        'input'  => '23 Something LN',
        'output' => '23 SOMETHING LN'
    },
    'LN-04' => {
        'input'  => '23 Something LN.',
        'output' => '23 SOMETHING LN'
    },
    'LNDG-00' => {
        'input'  => '23 Something LANDING',
        'output' => '23 SOMETHING LNDG'
    },
    'LNDG-01' => {
        'input'  => '23 Something LNDG',
        'output' => '23 SOMETHING LNDG'
    },
    'LNDG-02' => {
        'input'  => '23 Something LNDG.',
        'output' => '23 SOMETHING LNDG'
    },
    'LNDG-03' => {
        'input'  => '23 Something LNDNG',
        'output' => '23 SOMETHING LNDG'
    },
    'LOOP-00' => {
        'input'  => '23 Something LOOP',
        'output' => '23 SOMETHING LOOP'
    },
    'LOOP-01' => {
        'input'  => '23 Something LOOP.',
        'output' => '23 SOMETHING LOOP'
    },
    'LOOP-02' => {
        'input'  => '23 Something LOOPS',
        'output' => '23 SOMETHING LOOP'
    },
    'MALL-00' => {
        'input'  => '23 Something MALL',
        'output' => '23 SOMETHING MALL'
    },
    'MALL-01' => {
        'input'  => '23 Something MALL.',
        'output' => '23 SOMETHING MALL'
    },
    'MDW-00' => {
        'input'  => '23 Something MDW',
        'output' => '23 SOMETHING MDW'
    },
    'MDW-01' => {
        'input'  => '23 Something MDW.',
        'output' => '23 SOMETHING MDW'
    },
    'MDW-02' => {
        'input'  => '23 Something MEADOW',
        'output' => '23 SOMETHING MDW'
    },
    'MDWS-00' => {
        'input'  => '23 Something MDWS',
        'output' => '23 SOMETHING MDWS'
    },
    'MDWS-01' => {
        'input'  => '23 Something MDWS.',
        'output' => '23 SOMETHING MDWS'
    },
    'MDWS-02' => {
        'input'  => '23 Something MEADOWS',
        'output' => '23 SOMETHING MDWS'
    },
    'MDWS-03' => {
        'input'  => '23 Something MEDOWS',
        'output' => '23 SOMETHING MDWS'
    },
    'MEWS-00' => {
        'input'  => '23 Something MEWS',
        'output' => '23 SOMETHING MEWS'
    },
    'MEWS-01' => {
        'input'  => '23 Something MEWS.',
        'output' => '23 SOMETHING MEWS'
    },
    'ML-00' => {
        'input'  => '23 Something MILL',
        'output' => '23 SOMETHING ML'
    },
    'ML-01' => {
        'input'  => '23 Something ML',
        'output' => '23 SOMETHING ML'
    },
    'ML-02' => {
        'input'  => '23 Something ML.',
        'output' => '23 SOMETHING ML'
    },
    'MLS-00' => {
        'input'  => '23 Something MILLS',
        'output' => '23 SOMETHING MLS'
    },
    'MLS-01' => {
        'input'  => '23 Something MLS',
        'output' => '23 SOMETHING MLS'
    },
    'MLS-02' => {
        'input'  => '23 Something MLS.',
        'output' => '23 SOMETHING MLS'
    },
    'MNR-00' => {
        'input'  => '23 Something MANOR',
        'output' => '23 SOMETHING MNR'
    },
    'MNR-01' => {
        'input'  => '23 Something MNR',
        'output' => '23 SOMETHING MNR'
    },
    'MNR-02' => {
        'input'  => '23 Something MNR.',
        'output' => '23 SOMETHING MNR'
    },
    'MNRS-00' => {
        'input'  => '23 Something MANORS',
        'output' => '23 SOMETHING MNRS'
    },
    'MNRS-01' => {
        'input'  => '23 Something MNRS',
        'output' => '23 SOMETHING MNRS'
    },
    'MNRS-02' => {
        'input'  => '23 Something MNRS.',
        'output' => '23 SOMETHING MNRS'
    },
    'MSN-00' => {
        'input'  => '23 Something MISSION',
        'output' => '23 SOMETHING MSN'
    },
    'MSN-01' => {
        'input'  => '23 Something MISSN',
        'output' => '23 SOMETHING MSN'
    },
    'MSN-02' => {
        'input'  => '23 Something MSN',
        'output' => '23 SOMETHING MSN'
    },
    'MSN-03' => {
        'input'  => '23 Something MSN.',
        'output' => '23 SOMETHING MSN'
    },
    'MSN-04' => {
        'input'  => '23 Something MSSN',
        'output' => '23 SOMETHING MSN'
    },
    'MT-00' => {
        'input'  => '23 Something MNT',
        'output' => '23 SOMETHING MT'
    },
    'MT-01' => {
        'input'  => '23 Something MOUNT',
        'output' => '23 SOMETHING MT'
    },
    'MT-02' => {
        'input'  => '23 Something MT',
        'output' => '23 SOMETHING MT'
    },
    'MT-03' => {
        'input'  => '23 Something MT.',
        'output' => '23 SOMETHING MT'
    },
    'MTN-00' => {
        'input'  => '23 Something MNTAIN',
        'output' => '23 SOMETHING MTN'
    },
    'MTN-01' => {
        'input'  => '23 Something MNTN',
        'output' => '23 SOMETHING MTN'
    },
    'MTN-02' => {
        'input'  => '23 Something MOUNTAIN',
        'output' => '23 SOMETHING MTN'
    },
    'MTN-03' => {
        'input'  => '23 Something MTIN',
        'output' => '23 SOMETHING MTN'
    },
    'MTN-04' => {
        'input'  => '23 Something MTN',
        'output' => '23 SOMETHING MTN'
    },
    'MTN-05' => {
        'input'  => '23 Something MTN.',
        'output' => '23 SOMETHING MTN'
    },
    'MTNS-00' => {
        'input'  => '23 Something MOUNTAINS',
        'output' => '23 SOMETHING MTNS'
    },
    'MTNS-01' => {
        'input'  => '23 Something MTNS',
        'output' => '23 SOMETHING MTNS'
    },
    'MTNS-02' => {
        'input'  => '23 Something MTNS.',
        'output' => '23 SOMETHING MTNS'
    },
    'MTWY-00' => {
        'input'  => '23 Something MOTORWAY',
        'output' => '23 SOMETHING MTWY'
    },
    'MTWY-01' => {
        'input'  => '23 Something MTWY',
        'output' => '23 SOMETHING MTWY'
    },
    'MTWY-02' => {
        'input'  => '23 Something MTWY.',
        'output' => '23 SOMETHING MTWY'
    },
    'NCK-00' => {
        'input'  => '23 Something NCK',
        'output' => '23 SOMETHING NCK'
    },
    'NCK-01' => {
        'input'  => '23 Something NCK.',
        'output' => '23 SOMETHING NCK'
    },
    'NCK-02' => {
        'input'  => '23 Something NECK',
        'output' => '23 SOMETHING NCK'
    },
    'OPAS-00' => {
        'input'  => '23 Something OPAS',
        'output' => '23 SOMETHING OPAS'
    },
    'OPAS-01' => {
        'input'  => '23 Something OPAS.',
        'output' => '23 SOMETHING OPAS'
    },
    'OPAS-02' => {
        'input'  => '23 Something OVERPASS',
        'output' => '23 SOMETHING OPAS'
    },
    'ORCH-00' => {
        'input'  => '23 Something ORCH',
        'output' => '23 SOMETHING ORCH'
    },
    'ORCH-01' => {
        'input'  => '23 Something ORCH.',
        'output' => '23 SOMETHING ORCH'
    },
    'ORCH-02' => {
        'input'  => '23 Something ORCHARD',
        'output' => '23 SOMETHING ORCH'
    },
    'ORCH-03' => {
        'input'  => '23 Something ORCHRD',
        'output' => '23 SOMETHING ORCH'
    },
    'OVAL-00' => {
        'input'  => '23 Something OVAL',
        'output' => '23 SOMETHING OVAL'
    },
    'OVAL-01' => {
        'input'  => '23 Something OVAL.',
        'output' => '23 SOMETHING OVAL'
    },
    'OVAL-02' => {
        'input'  => '23 Something OVL',
        'output' => '23 SOMETHING OVAL'
    },
    'PARK-00' => {
        'input'  => '23 Something PARK',
        'output' => '23 SOMETHING PARK'
    },
    'PARK-01' => {
        'input'  => '23 Something PARK.',
        'output' => '23 SOMETHING PARK'
    },
    'PARK-02' => {
        'input'  => '23 Something PARKS',
        'output' => '23 SOMETHING PARK'
    },
    'PARK-03' => {
        'input'  => '23 Something PK',
        'output' => '23 SOMETHING PARK'
    },
    'PARK-04' => {
        'input'  => '23 Something PRK',
        'output' => '23 SOMETHING PARK'
    },
    'PASS-00' => {
        'input'  => '23 Something PASS',
        'output' => '23 SOMETHING PASS'
    },
    'PASS-01' => {
        'input'  => '23 Something PASS.',
        'output' => '23 SOMETHING PASS'
    },
    'PATH-00' => {
        'input'  => '23 Something PATH',
        'output' => '23 SOMETHING PATH'
    },
    'PATH-01' => {
        'input'  => '23 Something PATH.',
        'output' => '23 SOMETHING PATH'
    },
    'PATH-02' => {
        'input'  => '23 Something PATHS',
        'output' => '23 SOMETHING PATH'
    },
    'PIKE-00' => {
        'input'  => '23 Something PIKE',
        'output' => '23 SOMETHING PIKE'
    },
    'PIKE-01' => {
        'input'  => '23 Something PIKE.',
        'output' => '23 SOMETHING PIKE'
    },
    'PIKE-02' => {
        'input'  => '23 Something PIKES',
        'output' => '23 SOMETHING PIKE'
    },
    'PKWY-00' => {
        'input'  => '23 Something PARKWAY',
        'output' => '23 SOMETHING PKWY'
    },
    'PKWY-01' => {
        'input'  => '23 Something PARKWAYS',
        'output' => '23 SOMETHING PKWY'
    },
    'PKWY-02' => {
        'input'  => '23 Something PARKWY',
        'output' => '23 SOMETHING PKWY'
    },
    'PKWY-03' => {
        'input'  => '23 Something PKWAY',
        'output' => '23 SOMETHING PKWY'
    },
    'PKWY-04' => {
        'input'  => '23 Something PKWY',
        'output' => '23 SOMETHING PKWY'
    },
    'PKWY-05' => {
        'input'  => '23 Something PKWY.',
        'output' => '23 SOMETHING PKWY'
    },
    'PKWY-06' => {
        'input'  => '23 Something PKWYS',
        'output' => '23 SOMETHING PKWY'
    },
    'PKWY-07' => {
        'input'  => '23 Something PKY',
        'output' => '23 SOMETHING PKWY'
    },
    'PL-00' => {
        'input'  => '23 Something PL',
        'output' => '23 SOMETHING PL'
    },
    'PL-01' => {
        'input'  => '23 Something PL.',
        'output' => '23 SOMETHING PL'
    },
    'PL-02' => {
        'input'  => '23 Something PLACE',
        'output' => '23 SOMETHING PL'
    },
    'PLN-00' => {
        'input'  => '23 Something PLAIN',
        'output' => '23 SOMETHING PLN'
    },
    'PLN-01' => {
        'input'  => '23 Something PLN',
        'output' => '23 SOMETHING PLN'
    },
    'PLN-02' => {
        'input'  => '23 Something PLN.',
        'output' => '23 SOMETHING PLN'
    },
    'PLNS-00' => {
        'input'  => '23 Something PLAINES',
        'output' => '23 SOMETHING PLNS'
    },
    'PLNS-01' => {
        'input'  => '23 Something PLAINS',
        'output' => '23 SOMETHING PLNS'
    },
    'PLNS-02' => {
        'input'  => '23 Something PLNS',
        'output' => '23 SOMETHING PLNS'
    },
    'PLNS-03' => {
        'input'  => '23 Something PLNS.',
        'output' => '23 SOMETHING PLNS'
    },
    'PLZ-00' => {
        'input'  => '23 Something PLAZA',
        'output' => '23 SOMETHING PLZ'
    },
    'PLZ-01' => {
        'input'  => '23 Something PLZ',
        'output' => '23 SOMETHING PLZ'
    },
    'PLZ-02' => {
        'input'  => '23 Something PLZ.',
        'output' => '23 SOMETHING PLZ'
    },
    'PLZ-03' => {
        'input'  => '23 Something PLZA',
        'output' => '23 SOMETHING PLZ'
    },
    'PNE-00' => {
        'input'  => '23 Something PINE',
        'output' => '23 SOMETHING PNE'
    },
    'PNE-01' => {
        'input'  => '23 Something PNE',
        'output' => '23 SOMETHING PNE'
    },
    'PNE-02' => {
        'input'  => '23 Something PNE.',
        'output' => '23 SOMETHING PNE'
    },
    'PNES-00' => {
        'input'  => '23 Something PINES',
        'output' => '23 SOMETHING PNES'
    },
    'PNES-01' => {
        'input'  => '23 Something PNES',
        'output' => '23 SOMETHING PNES'
    },
    'PNES-02' => {
        'input'  => '23 Something PNES.',
        'output' => '23 SOMETHING PNES'
    },
    'PR-00' => {
        'input'  => '23 Something PR',
        'output' => '23 SOMETHING PR'
    },
    'PR-01' => {
        'input'  => '23 Something PR.',
        'output' => '23 SOMETHING PR'
    },
    'PR-02' => {
        'input'  => '23 Something PRAIRIE',
        'output' => '23 SOMETHING PR'
    },
    'PR-03' => {
        'input'  => '23 Something PRARIE',
        'output' => '23 SOMETHING PR'
    },
    'PR-04' => {
        'input'  => '23 Something PRR',
        'output' => '23 SOMETHING PR'
    },
    'PRT-00' => {
        'input'  => '23 Something PORT',
        'output' => '23 SOMETHING PRT'
    },
    'PRT-01' => {
        'input'  => '23 Something PRT',
        'output' => '23 SOMETHING PRT'
    },
    'PRT-02' => {
        'input'  => '23 Something PRT.',
        'output' => '23 SOMETHING PRT'
    },
    'PRTS-00' => {
        'input'  => '23 Something PORTS',
        'output' => '23 SOMETHING PRTS'
    },
    'PRTS-01' => {
        'input'  => '23 Something PRTS',
        'output' => '23 SOMETHING PRTS'
    },
    'PRTS-02' => {
        'input'  => '23 Something PRTS.',
        'output' => '23 SOMETHING PRTS'
    },
    'PSGE-00' => {
        'input'  => '23 Something PASSAGE',
        'output' => '23 SOMETHING PSGE'
    },
    'PSGE-01' => {
        'input'  => '23 Something PSGE',
        'output' => '23 SOMETHING PSGE'
    },
    'PSGE-02' => {
        'input'  => '23 Something PSGE.',
        'output' => '23 SOMETHING PSGE'
    },
    'PT-00' => {
        'input'  => '23 Something POINT',
        'output' => '23 SOMETHING PT'
    },
    'PT-01' => {
        'input'  => '23 Something PT',
        'output' => '23 SOMETHING PT'
    },
    'PT-02' => {
        'input'  => '23 Something PT.',
        'output' => '23 SOMETHING PT'
    },
    'PTS-00' => {
        'input'  => '23 Something POINTS',
        'output' => '23 SOMETHING PTS'
    },
    'PTS-01' => {
        'input'  => '23 Something PTS',
        'output' => '23 SOMETHING PTS'
    },
    'PTS-02' => {
        'input'  => '23 Something PTS.',
        'output' => '23 SOMETHING PTS'
    },
    'RADL-00' => {
        'input'  => '23 Something RAD',
        'output' => '23 SOMETHING RADL'
    },
    'RADL-01' => {
        'input'  => '23 Something RADIAL',
        'output' => '23 SOMETHING RADL'
    },
    'RADL-02' => {
        'input'  => '23 Something RADIEL',
        'output' => '23 SOMETHING RADL'
    },
    'RADL-03' => {
        'input'  => '23 Something RADL',
        'output' => '23 SOMETHING RADL'
    },
    'RADL-04' => {
        'input'  => '23 Something RADL.',
        'output' => '23 SOMETHING RADL'
    },
    'RAMP-00' => {
        'input'  => '23 Something RAMP',
        'output' => '23 SOMETHING RAMP'
    },
    'RAMP-01' => {
        'input'  => '23 Something RAMP.',
        'output' => '23 SOMETHING RAMP'
    },
    'RD-00' => {
        'input'  => '23 Something RD',
        'output' => '23 SOMETHING RD'
    },
    'RD-01' => {
        'input'  => '23 Something RD.',
        'output' => '23 SOMETHING RD'
    },
    'RD-02' => {
        'input'  => '23 Something ROAD',
        'output' => '23 SOMETHING RD'
    },
    'RDG-00' => {
        'input'  => '23 Something RDG',
        'output' => '23 SOMETHING RDG'
    },
    'RDG-01' => {
        'input'  => '23 Something RDG.',
        'output' => '23 SOMETHING RDG'
    },
    'RDG-02' => {
        'input'  => '23 Something RDGE',
        'output' => '23 SOMETHING RDG'
    },
    'RDG-03' => {
        'input'  => '23 Something RIDGE',
        'output' => '23 SOMETHING RDG'
    },
    'RDGS-00' => {
        'input'  => '23 Something RDGS',
        'output' => '23 SOMETHING RDGS'
    },
    'RDGS-01' => {
        'input'  => '23 Something RDGS.',
        'output' => '23 SOMETHING RDGS'
    },
    'RDGS-02' => {
        'input'  => '23 Something RIDGES',
        'output' => '23 SOMETHING RDGS'
    },
    'RDS-00' => {
        'input'  => '23 Something RDS',
        'output' => '23 SOMETHING RDS'
    },
    'RDS-01' => {
        'input'  => '23 Something RDS.',
        'output' => '23 SOMETHING RDS'
    },
    'RDS-02' => {
        'input'  => '23 Something ROADS',
        'output' => '23 SOMETHING RDS'
    },
    'RIV-00' => {
        'input'  => '23 Something RIV',
        'output' => '23 SOMETHING RIV'
    },
    'RIV-01' => {
        'input'  => '23 Something RIV.',
        'output' => '23 SOMETHING RIV'
    },
    'RIV-02' => {
        'input'  => '23 Something RIVER',
        'output' => '23 SOMETHING RIV'
    },
    'RIV-03' => {
        'input'  => '23 Something RIVR',
        'output' => '23 SOMETHING RIV'
    },
    'RIV-04' => {
        'input'  => '23 Something RVR',
        'output' => '23 SOMETHING RIV'
    },
    'RNCH-00' => {
        'input'  => '23 Something RANCH',
        'output' => '23 SOMETHING RNCH'
    },
    'RNCH-01' => {
        'input'  => '23 Something RANCHES',
        'output' => '23 SOMETHING RNCH'
    },
    'RNCH-02' => {
        'input'  => '23 Something RNCH',
        'output' => '23 SOMETHING RNCH'
    },
    'RNCH-03' => {
        'input'  => '23 Something RNCH.',
        'output' => '23 SOMETHING RNCH'
    },
    'RNCH-04' => {
        'input'  => '23 Something RNCHS',
        'output' => '23 SOMETHING RNCH'
    },
    'ROW-00' => {
        'input'  => '23 Something ROW',
        'output' => '23 SOMETHING ROW'
    },
    'ROW-01' => {
        'input'  => '23 Something ROW.',
        'output' => '23 SOMETHING ROW'
    },
    'RPD-00' => {
        'input'  => '23 Something RAPID',
        'output' => '23 SOMETHING RPD'
    },
    'RPD-01' => {
        'input'  => '23 Something RPD',
        'output' => '23 SOMETHING RPD'
    },
    'RPD-02' => {
        'input'  => '23 Something RPD.',
        'output' => '23 SOMETHING RPD'
    },
    'RPDS-00' => {
        'input'  => '23 Something RAPIDS',
        'output' => '23 SOMETHING RPDS'
    },
    'RPDS-01' => {
        'input'  => '23 Something RPDS',
        'output' => '23 SOMETHING RPDS'
    },
    'RPDS-02' => {
        'input'  => '23 Something RPDS.',
        'output' => '23 SOMETHING RPDS'
    },
    'RST-00' => {
        'input'  => '23 Something REST',
        'output' => '23 SOMETHING RST'
    },
    'RST-01' => {
        'input'  => '23 Something RST',
        'output' => '23 SOMETHING RST'
    },
    'RST-02' => {
        'input'  => '23 Something RST.',
        'output' => '23 SOMETHING RST'
    },
    'RTE-00' => {
        'input'  => '23 Something ROUTE',
        'output' => '23 SOMETHING RTE'
    },
    'RTE-01' => {
        'input'  => '23 Something RTE',
        'output' => '23 SOMETHING RTE'
    },
    'RTE-02' => {
        'input'  => '23 Something RTE.',
        'output' => '23 SOMETHING RTE'
    },
    'RUE-00' => {
        'input'  => '23 Something RUE',
        'output' => '23 SOMETHING RUE'
    },
    'RUE-01' => {
        'input'  => '23 Something RUE.',
        'output' => '23 SOMETHING RUE'
    },
    'RUN-00' => {
        'input'  => '23 Something RUN',
        'output' => '23 SOMETHING RUN'
    },
    'RUN-01' => {
        'input'  => '23 Something RUN.',
        'output' => '23 SOMETHING RUN'
    },
    'SHL-00' => {
        'input'  => '23 Something SHL',
        'output' => '23 SOMETHING SHL'
    },
    'SHL-01' => {
        'input'  => '23 Something SHL.',
        'output' => '23 SOMETHING SHL'
    },
    'SHL-02' => {
        'input'  => '23 Something SHOAL',
        'output' => '23 SOMETHING SHL'
    },
    'SHLS-00' => {
        'input'  => '23 Something SHLS',
        'output' => '23 SOMETHING SHLS'
    },
    'SHLS-01' => {
        'input'  => '23 Something SHLS.',
        'output' => '23 SOMETHING SHLS'
    },
    'SHLS-02' => {
        'input'  => '23 Something SHOALS',
        'output' => '23 SOMETHING SHLS'
    },
    'SHR-00' => {
        'input'  => '23 Something SHOAR',
        'output' => '23 SOMETHING SHR'
    },
    'SHR-01' => {
        'input'  => '23 Something SHORE',
        'output' => '23 SOMETHING SHR'
    },
    'SHR-02' => {
        'input'  => '23 Something SHR',
        'output' => '23 SOMETHING SHR'
    },
    'SHR-03' => {
        'input'  => '23 Something SHR.',
        'output' => '23 SOMETHING SHR'
    },
    'SHRS-00' => {
        'input'  => '23 Something SHOARS',
        'output' => '23 SOMETHING SHRS'
    },
    'SHRS-01' => {
        'input'  => '23 Something SHORES',
        'output' => '23 SOMETHING SHRS'
    },
    'SHRS-02' => {
        'input'  => '23 Something SHRS',
        'output' => '23 SOMETHING SHRS'
    },
    'SHRS-03' => {
        'input'  => '23 Something SHRS.',
        'output' => '23 SOMETHING SHRS'
    },
    'SKWY-00' => {
        'input'  => '23 Something SKWY',
        'output' => '23 SOMETHING SKWY'
    },
    'SKWY-01' => {
        'input'  => '23 Something SKWY.',
        'output' => '23 SOMETHING SKWY'
    },
    'SKWY-02' => {
        'input'  => '23 Something SKYWAY',
        'output' => '23 SOMETHING SKWY'
    },
    'SMT-00' => {
        'input'  => '23 Something SMT',
        'output' => '23 SOMETHING SMT'
    },
    'SMT-01' => {
        'input'  => '23 Something SMT.',
        'output' => '23 SOMETHING SMT'
    },
    'SMT-02' => {
        'input'  => '23 Something SUMIT',
        'output' => '23 SOMETHING SMT'
    },
    'SMT-03' => {
        'input'  => '23 Something SUMITT',
        'output' => '23 SOMETHING SMT'
    },
    'SMT-04' => {
        'input'  => '23 Something SUMMIT',
        'output' => '23 SOMETHING SMT'
    },
    'SPG-00' => {
        'input'  => '23 Something SPG',
        'output' => '23 SOMETHING SPG'
    },
    'SPG-01' => {
        'input'  => '23 Something SPG.',
        'output' => '23 SOMETHING SPG'
    },
    'SPG-02' => {
        'input'  => '23 Something SPNG',
        'output' => '23 SOMETHING SPG'
    },
    'SPG-03' => {
        'input'  => '23 Something SPRING',
        'output' => '23 SOMETHING SPG'
    },
    'SPG-04' => {
        'input'  => '23 Something SPRNG',
        'output' => '23 SOMETHING SPG'
    },
    'SPGS-00' => {
        'input'  => '23 Something SPGS',
        'output' => '23 SOMETHING SPGS'
    },
    'SPGS-01' => {
        'input'  => '23 Something SPGS.',
        'output' => '23 SOMETHING SPGS'
    },
    'SPGS-02' => {
        'input'  => '23 Something SPRINGS',
        'output' => '23 SOMETHING SPGS'
    },
    'SPUR-00' => {
        'input'  => '23 Something SPUR',
        'output' => '23 SOMETHING SPUR'
    },
    'SPUR-01' => {
        'input'  => '23 Something SPUR.',
        'output' => '23 SOMETHING SPUR'
    },
    'SPUR-02' => {
        'input'  => '23 Something SPURS',
        'output' => '23 SOMETHING SPUR'
    },
    'SQ-00' => {
        'input'  => '23 Something SQ',
        'output' => '23 SOMETHING SQ'
    },
    'SQ-01' => {
        'input'  => '23 Something SQ.',
        'output' => '23 SOMETHING SQ'
    },
    'SQ-02' => {
        'input'  => '23 Something SQR',
        'output' => '23 SOMETHING SQ'
    },
    'SQ-03' => {
        'input'  => '23 Something SQRE',
        'output' => '23 SOMETHING SQ'
    },
    'SQ-04' => {
        'input'  => '23 Something SQU',
        'output' => '23 SOMETHING SQ'
    },
    'SQ-05' => {
        'input'  => '23 Something SQUARE',
        'output' => '23 SOMETHING SQ'
    },
    'SQS-00' => {
        'input'  => '23 Something SQRS',
        'output' => '23 SOMETHING SQS'
    },
    'SQS-01' => {
        'input'  => '23 Something SQS',
        'output' => '23 SOMETHING SQS'
    },
    'SQS-02' => {
        'input'  => '23 Something SQS.',
        'output' => '23 SOMETHING SQS'
    },
    'SQS-03' => {
        'input'  => '23 Something SQUARES',
        'output' => '23 SOMETHING SQS'
    },
    'ST-00' => {
        'input'  => '23 Something ST',
        'output' => '23 SOMETHING ST'
    },
    'ST-01' => {
        'input'  => '23 Something ST.',
        'output' => '23 SOMETHING ST'
    },
    'ST-02' => {
        'input'  => '23 Something STR',
        'output' => '23 SOMETHING ST'
    },
    'ST-03' => {
        'input'  => '23 Something STREET',
        'output' => '23 SOMETHING ST'
    },
    'ST-04' => {
        'input'  => '23 Something STRT',
        'output' => '23 SOMETHING ST'
    },
    'STA-00' => {
        'input'  => '23 Something STA',
        'output' => '23 SOMETHING STA'
    },
    'STA-01' => {
        'input'  => '23 Something STA.',
        'output' => '23 SOMETHING STA'
    },
    'STA-02' => {
        'input'  => '23 Something STATION',
        'output' => '23 SOMETHING STA'
    },
    'STA-03' => {
        'input'  => '23 Something STATN',
        'output' => '23 SOMETHING STA'
    },
    'STA-04' => {
        'input'  => '23 Something STN',
        'output' => '23 SOMETHING STA'
    },
    'STRA-00' => {
        'input'  => '23 Something STRA',
        'output' => '23 SOMETHING STRA'
    },
    'STRA-01' => {
        'input'  => '23 Something STRA.',
        'output' => '23 SOMETHING STRA'
    },
    'STRA-02' => {
        'input'  => '23 Something STRAV',
        'output' => '23 SOMETHING STRA'
    },
    'STRA-03' => {
        'input'  => '23 Something STRAVE',
        'output' => '23 SOMETHING STRA'
    },
    'STRA-04' => {
        'input'  => '23 Something STRAVEN',
        'output' => '23 SOMETHING STRA'
    },
    'STRA-05' => {
        'input'  => '23 Something STRAVENUE',
        'output' => '23 SOMETHING STRA'
    },
    'STRA-06' => {
        'input'  => '23 Something STRAVN',
        'output' => '23 SOMETHING STRA'
    },
    'STRA-07' => {
        'input'  => '23 Something STRVN',
        'output' => '23 SOMETHING STRA'
    },
    'STRM-00' => {
        'input'  => '23 Something STREAM',
        'output' => '23 SOMETHING STRM'
    },
    'STRM-01' => {
        'input'  => '23 Something STREME',
        'output' => '23 SOMETHING STRM'
    },
    'STRM-02' => {
        'input'  => '23 Something STRM',
        'output' => '23 SOMETHING STRM'
    },
    'STRM-03' => {
        'input'  => '23 Something STRM.',
        'output' => '23 SOMETHING STRM'
    },
    'STS-00' => {
        'input'  => '23 Something STREETS',
        'output' => '23 SOMETHING STS'
    },
    'STS-01' => {
        'input'  => '23 Something STS',
        'output' => '23 SOMETHING STS'
    },
    'STS-02' => {
        'input'  => '23 Something STS.',
        'output' => '23 SOMETHING STS'
    },
    'TER-00' => {
        'input'  => '23 Something TER',
        'output' => '23 SOMETHING TER'
    },
    'TER-01' => {
        'input'  => '23 Something TER.',
        'output' => '23 SOMETHING TER'
    },
    'TER-02' => {
        'input'  => '23 Something TERR',
        'output' => '23 SOMETHING TER'
    },
    'TER-03' => {
        'input'  => '23 Something TERRACE',
        'output' => '23 SOMETHING TER'
    },
    'TPKE-00' => {
        'input'  => '23 Something TPK',
        'output' => '23 SOMETHING TPKE'
    },
    'TPKE-01' => {
        'input'  => '23 Something TPKE',
        'output' => '23 SOMETHING TPKE'
    },
    'TPKE-02' => {
        'input'  => '23 Something TPKE.',
        'output' => '23 SOMETHING TPKE'
    },
    'TPKE-03' => {
        'input'  => '23 Something TRNPK',
        'output' => '23 SOMETHING TPKE'
    },
    'TPKE-04' => {
        'input'  => '23 Something TRPK',
        'output' => '23 SOMETHING TPKE'
    },
    'TPKE-05' => {
        'input'  => '23 Something TURNPIKE',
        'output' => '23 SOMETHING TPKE'
    },
    'TPKE-06' => {
        'input'  => '23 Something TURNPK',
        'output' => '23 SOMETHING TPKE'
    },
    'TRAK-00' => {
        'input'  => '23 Something TRACK',
        'output' => '23 SOMETHING TRAK'
    },
    'TRAK-01' => {
        'input'  => '23 Something TRACKS',
        'output' => '23 SOMETHING TRAK'
    },
    'TRAK-02' => {
        'input'  => '23 Something TRAK',
        'output' => '23 SOMETHING TRAK'
    },
    'TRAK-03' => {
        'input'  => '23 Something TRAK.',
        'output' => '23 SOMETHING TRAK'
    },
    'TRAK-04' => {
        'input'  => '23 Something TRK',
        'output' => '23 SOMETHING TRAK'
    },
    'TRAK-05' => {
        'input'  => '23 Something TRKS',
        'output' => '23 SOMETHING TRAK'
    },
    'TRCE-00' => {
        'input'  => '23 Something TRACE',
        'output' => '23 SOMETHING TRCE'
    },
    'TRCE-01' => {
        'input'  => '23 Something TRACES',
        'output' => '23 SOMETHING TRCE'
    },
    'TRCE-02' => {
        'input'  => '23 Something TRCE',
        'output' => '23 SOMETHING TRCE'
    },
    'TRCE-03' => {
        'input'  => '23 Something TRCE.',
        'output' => '23 SOMETHING TRCE'
    },
    'TRFY-00' => {
        'input'  => '23 Something TRAFFICWAY',
        'output' => '23 SOMETHING TRFY'
    },
    'TRFY-01' => {
        'input'  => '23 Something TRFY',
        'output' => '23 SOMETHING TRFY'
    },
    'TRFY-02' => {
        'input'  => '23 Something TRFY.',
        'output' => '23 SOMETHING TRFY'
    },
    'TRL-00' => {
        'input'  => '23 Something TR',
        'output' => '23 SOMETHING TRL'
    },
    'TRL-01' => {
        'input'  => '23 Something TRAIL',
        'output' => '23 SOMETHING TRL'
    },
    'TRL-02' => {
        'input'  => '23 Something TRAILS',
        'output' => '23 SOMETHING TRL'
    },
    'TRL-03' => {
        'input'  => '23 Something TRL',
        'output' => '23 SOMETHING TRL'
    },
    'TRL-04' => {
        'input'  => '23 Something TRL.',
        'output' => '23 SOMETHING TRL'
    },
    'TRL-05' => {
        'input'  => '23 Something TRLS',
        'output' => '23 SOMETHING TRL'
    },
    'TRWY-00' => {
        'input'  => '23 Something THROUGHWAY',
        'output' => '23 SOMETHING TRWY'
    },
    'TRWY-01' => {
        'input'  => '23 Something TRWY',
        'output' => '23 SOMETHING TRWY'
    },
    'TRWY-02' => {
        'input'  => '23 Something TRWY.',
        'output' => '23 SOMETHING TRWY'
    },
    'TUNL-00' => {
        'input'  => '23 Something TUNEL',
        'output' => '23 SOMETHING TUNL'
    },
    'TUNL-01' => {
        'input'  => '23 Something TUNL',
        'output' => '23 SOMETHING TUNL'
    },
    'TUNL-02' => {
        'input'  => '23 Something TUNL.',
        'output' => '23 SOMETHING TUNL'
    },
    'TUNL-03' => {
        'input'  => '23 Something TUNLS',
        'output' => '23 SOMETHING TUNL'
    },
    'TUNL-04' => {
        'input'  => '23 Something TUNNEL',
        'output' => '23 SOMETHING TUNL'
    },
    'TUNL-05' => {
        'input'  => '23 Something TUNNELS',
        'output' => '23 SOMETHING TUNL'
    },
    'TUNL-06' => {
        'input'  => '23 Something TUNNL',
        'output' => '23 SOMETHING TUNL'
    },
    'UN-00' => {
        'input'  => '23 Something UN',
        'output' => '23 SOMETHING UN'
    },
    'UN-01' => {
        'input'  => '23 Something UN.',
        'output' => '23 SOMETHING UN'
    },
    'UN-02' => {
        'input'  => '23 Something UNION',
        'output' => '23 SOMETHING UN'
    },
    'UNS-00' => {
        'input'  => '23 Something UNIONS',
        'output' => '23 SOMETHING UNS'
    },
    'UNS-01' => {
        'input'  => '23 Something UNS',
        'output' => '23 SOMETHING UNS'
    },
    'UNS-02' => {
        'input'  => '23 Something UNS.',
        'output' => '23 SOMETHING UNS'
    },
    'UPAS-00' => {
        'input'  => '23 Something UNDERPASS',
        'output' => '23 SOMETHING UPAS'
    },
    'UPAS-01' => {
        'input'  => '23 Something UPAS',
        'output' => '23 SOMETHING UPAS'
    },
    'UPAS-02' => {
        'input'  => '23 Something UPAS.',
        'output' => '23 SOMETHING UPAS'
    },
    'VIA-00' => {
        'input'  => '23 Something VDCT',
        'output' => '23 SOMETHING VIA'
    },
    'VIA-01' => {
        'input'  => '23 Something VIA',
        'output' => '23 SOMETHING VIA'
    },
    'VIA-02' => {
        'input'  => '23 Something VIA.',
        'output' => '23 SOMETHING VIA'
    },
    'VIA-03' => {
        'input'  => '23 Something VIADCT',
        'output' => '23 SOMETHING VIA'
    },
    'VIA-04' => {
        'input'  => '23 Something VIADUCT',
        'output' => '23 SOMETHING VIA'
    },
    'VIS-00' => {
        'input'  => '23 Something VIS',
        'output' => '23 SOMETHING VIS'
    },
    'VIS-01' => {
        'input'  => '23 Something VIS.',
        'output' => '23 SOMETHING VIS'
    },
    'VIS-02' => {
        'input'  => '23 Something VIST',
        'output' => '23 SOMETHING VIS'
    },
    'VIS-03' => {
        'input'  => '23 Something VISTA',
        'output' => '23 SOMETHING VIS'
    },
    'VIS-04' => {
        'input'  => '23 Something VST',
        'output' => '23 SOMETHING VIS'
    },
    'VIS-05' => {
        'input'  => '23 Something VSTA',
        'output' => '23 SOMETHING VIS'
    },
    'VL-00' => {
        'input'  => '23 Something VILLE',
        'output' => '23 SOMETHING VL'
    },
    'VL-01' => {
        'input'  => '23 Something VL',
        'output' => '23 SOMETHING VL'
    },
    'VL-02' => {
        'input'  => '23 Something VL.',
        'output' => '23 SOMETHING VL'
    },
    'VLG-00' => {
        'input'  => '23 Something VILL',
        'output' => '23 SOMETHING VLG'
    },
    'VLG-01' => {
        'input'  => '23 Something VILLAG',
        'output' => '23 SOMETHING VLG'
    },
    'VLG-02' => {
        'input'  => '23 Something VILLAGE',
        'output' => '23 SOMETHING VLG'
    },
    'VLG-03' => {
        'input'  => '23 Something VILLG',
        'output' => '23 SOMETHING VLG'
    },
    'VLG-04' => {
        'input'  => '23 Something VILLIAGE',
        'output' => '23 SOMETHING VLG'
    },
    'VLG-05' => {
        'input'  => '23 Something VLG',
        'output' => '23 SOMETHING VLG'
    },
    'VLG-06' => {
        'input'  => '23 Something VLG.',
        'output' => '23 SOMETHING VLG'
    },
    'VLGS-00' => {
        'input'  => '23 Something VILLAGES',
        'output' => '23 SOMETHING VLGS'
    },
    'VLGS-01' => {
        'input'  => '23 Something VLGS',
        'output' => '23 SOMETHING VLGS'
    },
    'VLGS-02' => {
        'input'  => '23 Something VLGS.',
        'output' => '23 SOMETHING VLGS'
    },
    'VLY-00' => {
        'input'  => '23 Something VALLEY',
        'output' => '23 SOMETHING VLY'
    },
    'VLY-01' => {
        'input'  => '23 Something VALLY',
        'output' => '23 SOMETHING VLY'
    },
    'VLY-02' => {
        'input'  => '23 Something VLLY',
        'output' => '23 SOMETHING VLY'
    },
    'VLY-03' => {
        'input'  => '23 Something VLY',
        'output' => '23 SOMETHING VLY'
    },
    'VLY-04' => {
        'input'  => '23 Something VLY.',
        'output' => '23 SOMETHING VLY'
    },
    'VLYS-00' => {
        'input'  => '23 Something VALLEYS',
        'output' => '23 SOMETHING VLYS'
    },
    'VLYS-01' => {
        'input'  => '23 Something VALLYS',
        'output' => '23 SOMETHING VLYS'
    },
    'VLYS-02' => {
        'input'  => '23 Something VLLYS',
        'output' => '23 SOMETHING VLYS'
    },
    'VLYS-03' => {
        'input'  => '23 Something VLYS',
        'output' => '23 SOMETHING VLYS'
    },
    'VLYS-04' => {
        'input'  => '23 Something VLYS.',
        'output' => '23 SOMETHING VLYS'
    },
    'VW-00' => {
        'input'  => '23 Something VIEW',
        'output' => '23 SOMETHING VW'
    },
    'VW-01' => {
        'input'  => '23 Something VW',
        'output' => '23 SOMETHING VW'
    },
    'VW-02' => {
        'input'  => '23 Something VW.',
        'output' => '23 SOMETHING VW'
    },
    'VWS-00' => {
        'input'  => '23 Something VIEWS',
        'output' => '23 SOMETHING VWS'
    },
    'VWS-01' => {
        'input'  => '23 Something VWS',
        'output' => '23 SOMETHING VWS'
    },
    'VWS-02' => {
        'input'  => '23 Something VWS.',
        'output' => '23 SOMETHING VWS'
    },
    'WALK-00' => {
        'input'  => '23 Something WALK',
        'output' => '23 SOMETHING WALK'
    },
    'WALK-01' => {
        'input'  => '23 Something WALK.',
        'output' => '23 SOMETHING WALK'
    },
    'WALK-02' => {
        'input'  => '23 Something WALKS',
        'output' => '23 SOMETHING WALK'
    },
    'WALL-00' => {
        'input'  => '23 Something WALL',
        'output' => '23 SOMETHING WALL'
    },
    'WALL-01' => {
        'input'  => '23 Something WALL.',
        'output' => '23 SOMETHING WALL'
    },
    'WAY-00' => {
        'input'  => '23 Something WAY',
        'output' => '23 SOMETHING WAY'
    },
    'WAY-01' => {
        'input'  => '23 Something WAY.',
        'output' => '23 SOMETHING WAY'
    },
    'WAY-02' => {
        'input'  => '23 Something WY',
        'output' => '23 SOMETHING WAY'
    },
    'WAYS-00' => {
        'input'  => '23 Something WAYS',
        'output' => '23 SOMETHING WAYS'
    },
    'WAYS-01' => {
        'input'  => '23 Something WAYS.',
        'output' => '23 SOMETHING WAYS'
    },
    'WL-00' => {
        'input'  => '23 Something WELL',
        'output' => '23 SOMETHING WL'
    },
    'WL-01' => {
        'input'  => '23 Something WL',
        'output' => '23 SOMETHING WL'
    },
    'WL-02' => {
        'input'  => '23 Something WL.',
        'output' => '23 SOMETHING WL'
    },
    'WLS-00' => {
        'input'  => '23 Something WELLS',
        'output' => '23 SOMETHING WLS'
    },
    'WLS-01' => {
        'input'  => '23 Something WLS',
        'output' => '23 SOMETHING WLS'
    },
    'WLS-02' => {
        'input'  => '23 Something WLS.',
        'output' => '23 SOMETHING WLS'
    },
    'XING-00' => {
        'input'  => '23 Something CROSSING',
        'output' => '23 SOMETHING XING'
    },
    'XING-01' => {
        'input'  => '23 Something CRSSING',
        'output' => '23 SOMETHING XING'
    },
    'XING-02' => {
        'input'  => '23 Something CRSSNG',
        'output' => '23 SOMETHING XING'
    },
    'XING-03' => {
        'input'  => '23 Something XING',
        'output' => '23 SOMETHING XING'
    },
    'XING-04' => {
        'input'  => '23 Something XING.',
        'output' => '23 SOMETHING XING'
    },
    'XRD-00' => {
        'input'  => '23 Something CROSSROAD',
        'output' => '23 SOMETHING XRD'
    },
    'XRD-01' => {
        'input'  => '23 Something XRD',
        'output' => '23 SOMETHING XRD'
    },
    'XRD-02' => {
        'input'  => '23 Something XRD.',
        'output' => '23 SOMETHING XRD'
    }
);

foreach my $k ( sort keys %address_designator ) {
    my $address = Geo::Address::Mail::US->new(
        name        => 'Test Testerson',
        street      => $address_designator{$k}{input},
        street2     => q{ },
        city        => 'Testville',
        state       => 'TN',
        postal_code => '12345'
    );

    my $res  = $std->standardize($address);
    my $corr = $res->standardized_address;
    cmp_ok(
        $res->standardized_address->street, 'eq',
        $address_designator{$k}{output},    $k
    );

}

done_testing;

