
unless ($^O eq "MSWin32") {
  die "NA: This is Win32-specific; use File::HomeDir instead";
}

use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'File::HomeDir::Win32',
     license => 'perl',
     requires => {
       'perl'             => '5.6.0',
       'Carp'             => 0,
       'File::HomeDir'    => 0.06,
       'Win32'            => 0,
       'Win32::Security::SID' => 0,
       'Win32::TieRegistry'   => 0,
     },
     recommends => {
       'Pod::Readme'    => 0.03, # for building dist
     },
     build_requires => {
       'Test::More'     => 0,
       'Test::Warn'     => 0,
     },
     create_readme      => 0,
     create_makefile_pl => 'traditional',
     dist_author        => 'Ramdy Kobes <r.kobes at uwinnipeg.ca>',
     sign               => 1,
);

$build->create_build_script;

