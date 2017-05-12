use Module::Build;

use strict;
use warnings;

my $build = Module::Build->new (
    module_name		=> 'Encode::Korean',
    license			=> 'perl',
    dist_author		=> 'You Hyun Jo',
    dist_version_from	=> 'lib/Encode/Korean.pm',
    create_readme		=> 1,
    requires		=> {
				 'perl'  => 5.008,
			     },
    build_requires => {
			'Test::More'	=> 0,
			},
    add_to_cleanup	=> [ 'Encode-Korean-*' ],
);

$build->create_build_script();

