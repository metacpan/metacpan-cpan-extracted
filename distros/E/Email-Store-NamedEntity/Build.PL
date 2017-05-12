use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Email::Store::NamedEntity",
         license     => 'perl',
         requires    => {
						    'Email::Store' => 0,
        					'File::Slurp' => 0,
                          	'Test::More'  => 0,
						    'Lingua::EN::NamedEntity' => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

