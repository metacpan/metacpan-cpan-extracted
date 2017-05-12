######################################################################
# Build.PL for Locale::VersionedMessages
######################################################################

use strict;
use warnings;
use 5.008;
use Module::Build 0.21;

my %module_prereq = (
   'perl'                     => '5.008',
   'File::Path'               => '0',
   'IO::File'                 => '0',
);

my %script_prereq = (
);

my %test_prereq = (
   'Test::Inter'              => '1.04',
   'Test::More'               => '0',
   'lib'                      => '0',
);

my %config_prereq = (
   'Module::Build'            => '0.21',
);

my %build_prereq = %config_prereq;
if ($Module::Build::VERSION < 0.4004) {
   %build_prereq = (%config_prereq,%test_prereq);
}

my $class = Module::Build->subclass(
   class  => "Module::Build::Custom",
   code   => q { sub ACTION_html { my $self = shift ; $self->SUPER::ACTION_html ( @_ ) if ( $ENV{ MAKE_HTML } ) ; } }
);

my $build = $class->new(
      module_name        => "Locale::VersionedMessages",
      dist_version       => "0.95",
      dist_abstract      => "handle all aspects of the localization process",
      license            => "perl",
      dist_author        => "Sullivan Beck <sbeck\@cpan.org>",

      requires           => \%module_prereq,
      ($Module::Build::VERSION >= 0.4004
       ? (test_requires  => \%test_prereq)
       : ()),
      ($Module::Build::VERSION >= 0.30
       ? (configure_requires  => \%config_prereq)
       : ()),
      build_requires     => \%build_prereq,
      recommends         => \%script_prereq,
      sign               => 1,

      ($Module::Build::VERSION >= 0.28
       ? (meta_merge => {
             resources => {
                repository => "https://github.com/SBECK-github/Locale-VersionedMessages",
             }
          })
       : ()),
      script_files       => [
                             'bin/lm_gui',
                            ],
);

$build->create_build_script;
