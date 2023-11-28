#/!bin/sh

# Clean up from previous test run (optional)
cover -d ./cover_db/ -delete

# Run the tests (adding in the patch for B:Deparse) with coverage enabled. 
PERL5OPT="-I./t/lib/patches/ -I./lib/ -MB::DeparsePatch -MDevel::Cover=-db,./cover_db/,-select_re,'^lib/*'" prove --lib --failures --comments --jobs 9 --recurse ./t ./xt
# PERL5OPT options:
# -I./t/lib/patches/ and -MB::DeparsePatch    Include our patch for B::Deparse if necessary
# -MDevel::Cover=-db,./cover_db/,-select_re,'^lib/*' Include Devel::Cover setting ./cover_db to store the data but only processing files matching ^lib/*
# prove options:
# --lib             Add 'lib' to the path for your tests (-Ilib).
# --failures        Show failed tests.
# --comments        Show comments.
#  -jobs 9          Run 9 test jobs in parallel
# --recurse         Recursively descend into directories.
# ./t               Include our test directory
# ./xt              Include our author test directory

# Create the output
cover -select_re ^lib/* -d ./cover_db/ -outputdir ./docs/coverage/ -report html
# cover options
# -select_re ^lib/*           Only process files matching ^lib/*
# -d ./cover_db/                Use the coverage database in ./cover_db/
# -output dir ./docs/coverage/  Output to docs/coverage
# -report                       Make a HTML format report