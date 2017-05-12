use Test::More tests => 12;

use_ok( 'DicomPack::IO::DicomReader' );
require_ok( 'DicomPack::IO::DicomReader' );

use_ok( 'DicomPack::IO::DicomWriter' );
require_ok( 'DicomPack::IO::DicomWriter' );

use_ok( 'DicomPack::Util::DicomAnonymizer' );
require_ok( 'DicomPack::Util::DicomAnonymizer' );

use_ok( 'DicomPack::Util::DicomDumper' );
require_ok( 'DicomPack::Util::DicomDumper' );

use_ok( 'DicomPack::DB::DicomTagDict' );
require_ok( 'DicomPack::DB::DicomTagDict' );

use_ok( 'DicomPack::DB::DicomVRDict' );
require_ok( 'DicomPack::DB::DicomVRDict' );

