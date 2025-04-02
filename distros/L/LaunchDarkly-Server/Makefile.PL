use v5.18.2;
use ExtUtils::MakeMaker;
use ExtUtils::Typemaps::STL;
use ExtUtils::Typemaps::ObjectMap;

my $CC = 'g++';

my $stl_map = ExtUtils::Typemaps::STL->new;
$stl_map->write(file => 'stl_typemap');
my $obj_map = ExtUtils::Typemaps::ObjectMap->new;
$obj_map->write(file => 'obj_typemap');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'LaunchDarkly::Server',
    VERSION_FROM        => 'lib/LaunchDarkly/Server.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    CONFIGURE_REQUIRES  => {
                            "ExtUtils::MakeMaker" => 0,
                            "ExtUtils::Typemaps::STL" => 0,
                            "ExtUtils::Typemaps::ObjectMap" => 0,
                        },
    PREREQ_PM           => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM       => 'lib/LaunchDarkly/Server.pm', # retrieve abstract from module
    AUTHOR              => 'Miklos Tirpak <miklos.tirpak@emnify.com>',
    LIBS                => ['-llaunchdarkly-cpp-server'],
    TYPEMAPS            => ['stl_typemap', 'obj_typemap'],
    'CC'                => $CC,
    'CCFLAGS'           => "$Config::Config{ccflags} -std=c++17",
    'LD'                => '$(CC)',
    'XSOPT'             => '-C++ -hiertype',
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());

  ExtUtils::Constant::WriteConstants(
                                   NAME         => 'LaunchDarkly::Server',
                                   NAMES        => \@names,
                                   DEFAULT_TYPE => 'IV',
                                   C_FILE       => 'const-c.inc',
                                   XS_FILE      => 'const-xs.inc',
                                );
}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
