use Module::Build;
my $build = Module::Build->new
(

module_name => 'File::Samba',
license => 'perl',
create_makefile_pl => 'passthrough',
requires => {
            	'Data::Dump'   => '0',
            },
dist_author => 'Salvatore E. ScottoDiLuzio <lt>washu@olypmus.net<gt>',
dist_abstract => 'Module to manipulate a smb.conf file'
);
$build->create_build_script;
