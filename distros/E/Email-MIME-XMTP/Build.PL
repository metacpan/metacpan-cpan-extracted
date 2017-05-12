use strict;
use Module::Build;

my $build = Module::Build->new(
				'module_name' => 'Email::MIME::XMTP',
				'dist_author' => 'Alberto Reggiori <alberto@asemantics.com>',	
			       	'dist_abstract' => 'Add XMTP support to Email::MIME',
				'dist_version_from' => 'lib/Email/MIME/XMTP.pm',
				'license' => 'bsd', # see LICENSE file
				'requires' => {
					'Email::Simple' => '1.92',
					'Email::MIME' => '1.82',
					'Email::MIME::Encodings' => '1.3',
					'XML::Parser' => '2.20',
					'Test::More' => '0.47'
					},
				'create_readme' => 1,
				'create_makefile_pl' => 'passthrough' );

$build->create_build_script();
