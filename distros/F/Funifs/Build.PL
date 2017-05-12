#!/usr/bin/perl
use Module::Build;

my $build = new Module::Build (
  dist_version_from => 'Funifs.pm',
  module_name   => 'Funifs',
  license       => 'perl',
  dist_author   => q{Vladimir Kolpakov <vova@cpan.org>},
  requires => {
    'Fuse' => 0.09,
    'Unix::Syslog' => 0,
    'Filesys::Statvfs' => 0,
  },
  bindoc_dirs => [
    'blib/docs',
  ],
  pod_files => {
    'Funifs.pm' => 'docs/funifs',
  },
  sys_files => {
    'funifs'    => 'sys/usr/sbin/funifs',
    'rcfunifs'  => 'sys/etc/init.d/funifs',
    'README'    => 'sys/usr/share/doc/packages/funifs/README',
    'fstab'     => 'sys/usr/share/doc/packages/funifs/fstab',
  },
  install_path  => { 'sys' => '/', },
  #create_packlist => 0,        #-- enable this to disable .packlist creation
);

my $ib = $build->install_base() ;       #-- run "./Build.PL --install_base=/var/tmp/Funifs"  to see how it works
$build->do_create_readme;
$build->add_build_element('sys');
$build->install_path('sys' =>  $ib ? $ib : '/');

$build->create_build_script;
__END__
