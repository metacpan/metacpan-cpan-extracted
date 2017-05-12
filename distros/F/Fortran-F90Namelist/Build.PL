# Build.PL
#
# Usage:
#   perl Build.PL
#   ./Build
#   ./Build test
#   ./Build clean
#   ./Build install
# To see details about tests (what exactly failed?), use
#   ./Build test verbose=1
# or (equivalent)
#   ./Build test --verbose 1
# To install below your home directory, use
#   perl Build.PL destdir=${HOME}/opt
#
# Further options:
#   ./Build help        # Brief overview
#   ./Build manifest    # Create(?) or update MANIFEST file
#                       # (MANIFEST allows comments after each file name)
#   ./Build distcheck   # Find which files are in the build directory, but
#                       # not in MANIFEST
#   ./Build distmeta    # Create META.yml
#   ./Build docs        # Generate man pages form POD
#   ./Build fakeinstall # Tell what would be installed
#
# To run individual tests:
#   perl -Ilib t/01_basic.t
# or
#   ./Build test --test_files t/01_basic.t
#   ./Build test --test_files t/01_basic.t --verbose 1
#   ./Build test --test_files 't/3*.t'
# or just (see Module::Build::Cookbook)
#   alias t './Build test --verbose=1 --test_files'
#   t t/01_basic.t
#
# For more info, see Moudle::Build and in particular Module::Build::Cookbook.
#
# To produce a PDF version of the POD documentation:
#   pod2latex -full -modify -prefile preamble.tex lib/Namelist{,/Group}.pm -out Namelist.tex
#   pdflatex Namelist && makeindex Namelist && pdflatex Namelist && pdflatex Namelist

use Module::Build

my $build = Module::Build->new
    ( module_name => 'Fortran::F90Namelist',
      license     => 'perl',
      dist_author => 'Wolfgang Dobler <Wolfgang.Dobler@kis.uni-freiburg.de>',
      requires    => { },

      # For Test::Pod::Snippets (automatically tests that all code
      # snippets in POD documentation actually work):
      PL_files       => { 'script/test-pod-snippets.PL' => q{} },
      add_to_cleanup => [ 't/pod-snippets-*.t' ],
    ) -> create_build_script;


# End of file
