use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::Tournament::Swiss',
    license             => 'perl',
    dist_author         => 'Dr Bean <drbean, followed by the at mark (@), cpan, then a dot, and finally, org>',
    dist_version_from   => 'lib/Games/Tournament/Swiss.pm',
    create_makefile_pl  => 'traditional',
    requires            => { 'List::MoreUtils' => 0 },
    build_requires      => {
				'Test::More' => 0,
				'Test::Base' => 0,
				'YAML' => 0,
				'IO::All' => 0,
				'Parse::RecDescent' => 0,
				},
    recommends => { YAML => 0, 'IO::All' => 0, 'Parse::RecDescent' => 0,
   				},
    script_files	=> [qw(
        		    script_files/pair
        		    script_files/pairingtable
        		    script_files/crosstable
			    script_files/pairtable2yaml
			    script_files/pairyaml2txt
        		    script_files/pairstately
					web/script_files/create_table.pl
        			)],
    add_to_cleanup      => [ 'Games-Tournament-Swiss-*' ],
			);
			$builder->create_build_script();
