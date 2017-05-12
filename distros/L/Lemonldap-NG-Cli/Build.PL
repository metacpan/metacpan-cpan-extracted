#!/usr/bin/perl -w

use 5.010;
use Module::Build;
use Config::IniFiles;
use strict;

my $build = Module::Build->new (
          module_name       => 'Lemonldap::NG::Cli',
          license           => 'perl',
          dist_author       => 'David Delassus <david.jose.delassus@gmail.com>',
          dist_version_from => 'lib/Lemonldap/NG/Cli.pm',

          configure_requires =>
          {
               'Config::IniFiles' => 0,
               'Module::Build'    => '0.38',
          },

          requires =>
          {
               'Config::IniFiles'            => 0,
               'Lemonldap::NG::Common::Conf' => '1.0',
               'perl'                        => '5.010',
          },

          conf_files =>
          {
               'lemonldap-cli.ini' => 'conf/lemonldap-ng/lemonldap-cli.ini',
          },

          PL_files =>
          {
               'lemonldap-ng-cli.PL' => 'bin/lemonldap-ng-cli',
          },
);

if (not defined ($build->install_path ('conf')))
{
     if (not defined ($build->prefix ()))
     {
          $build->prefix ('/usr/local');
     }

     my $path = $build->prefix ().'/etc';
     $build->install_path (conf => $path);
}

my $confpath = $build->install_path ('conf');

# Save configuration to the "config" file
my $cfg = Config::IniFiles->new ();

$cfg->AddSection ('build');
$cfg->newval ('build', 'prefix', $build->prefix);
$cfg->newval ('build', 'confpath', $confpath);

$cfg->WriteConfig ('config');

# Generate script
$build->add_to_cleanup ('config');
$build->add_build_element ('conf');
$build->create_build_script ();
