use Module::Build;
my $build = Module::Build->new
(
   module_name => 'File::Lockfile',
   license => 'perl',
   requires => {
   	'perl' => '5.6.1',
	'Class::Data::Inheritable' => '0.06',
	'File::Temp' => '0.21'
   },
   dist_author => 'Sergey Sinkovskiy <glorybox@cpan.org>',
   add_to_cleanup => [
   	'META.yml', '*.gz',
   ],
);
$build->create_build_script;


