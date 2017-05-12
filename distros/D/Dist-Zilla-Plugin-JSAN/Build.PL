
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'a plugin for Dist::Zilla for building JSAN distributions',
  'dist_author' => [
    'Nickolay Platonov <nplatonov@cpan.org>'
  ],
  'dist_name' => 'Dist-Zilla-Plugin-JSAN',
  'dist_version' => '0.06',
  'license' => 'perl',
  'module_name' => 'Dist::Zilla::Plugin::JSAN',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Archive::Tar' => '1.52',
    'Capture::Tiny' => '0.08',
    'Data::Section' => '0.004',
    'Dist::Zilla' => '4.102343',
    'Dist::Zilla::Plugin::CheckChangesHasContent' => '0.003',
    'Dist::Zilla::Plugin::Git' => '1.102810',
    'Dist::Zilla::Plugin::GithubMeta' => '0.10',
    'File::Find::Rule' => '0.28',
    'File::Temp' => '0.22',
    'Getopt::LL' => '1.00',
    'JSON' => '2.00',
    'MIME::Types' => '0.00',
    'Path::Class' => '0.16',
    'Text::Markdown' => '1.0.26',
    'Text::MultiMarkdown' => '1.0.29'
  },
  'script_files' => [
    'script/shotenjin.pl'
  ],
  'share_dir' => {
    'dist' => 'share',
    'module' => {
      'Dist::Zilla::MintingProfile::JSAN' => 'share/profiles'
    }
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
