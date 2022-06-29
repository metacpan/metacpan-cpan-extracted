# Nuggit Tests

## Usage
   - From root repo, run `make test` without arguments to execute all tests in standard test harness
   - To run manually, simply run the desired script:
        - To check that all files compile: `perl 00-compile.t`
        - To run all tests: `perl 03-ops.t`
   - See GetOptions in TestDriver.pm for all available parameters

## Options
- `perl 03-ops.t --list` Lists the number and description of available tests.
- `perl 03-ops.t --test <number>` Runs the specified test.

## Pre-requisites
Pre-requisites for tests are defined in Makefile.PL.
- Alternatively:  `cpan install File::pushd File::Slurp IPC::Run3 Test::Most`
- Or using cpanm (local repository management):
   - `curl -L https://cpanmin.us/ -o cpanm && chmod +x cpanm`
   - `./cpanm $LIST_OF_DEPS_FROM_ABOVE`
   - `./cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)`


## Test files
Tests will place temporary files at ./testrepo, or the location can be overridden with `--root <tmpdir>`

# What is TestDriver.pm
   What are the enviroments set up or available via TestDrive?  David mentioned one common repo configuration set up by TestDrive.pm... what does that look like?  Should we enumerate this configuration and allow for other configurations?  
   We should document that 030ops.t uses the specific test configuration defined in TestDriver.pm
   drives the test
   array
   parses
   command line argument parsing


# 03-ops.t
   array of tests  @tests is the array of all the tests in this file
   descriptions
   optional arguments
   function reference for the test
   
# Example test in 03-ops.t
   simple_merge... merge_test1 is the function name
   this is the test definition...

