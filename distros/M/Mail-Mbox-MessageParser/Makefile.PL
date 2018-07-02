#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use lib '.';
use inc::Module::Install;
use Module::Install::GetProgramLocations;
use File::Slurp;

BEGIN {
  my $commands = q{$(CP) t/mailboxes/*\\ * $(DISTVNAME)/t/mailboxes; $(CP) t/results/*\\ * $(DISTVNAME)/t/results};

  makemaker_args(
    # To prevent MakeMaker from processing our old directory
    NORECURS => 1,
    # Copy files that have spaces in them.
    dist => { PREOP => q{$(PERL) -I. "-MModule::Install::Admin" -e "dist_preop(q($(DISTVNAME)))"; } . $commands },
  )
}

all_from('lib/Mail/Mbox/MessageParser.pm');

auto_set_bugtracker;
githubmeta;

configure_requires(
  'File::Slurp' => 0,
);

requires(
  'FileHandle::Unget' => 0,
  'Storable' => 0,
);

test_requires(
  'Test::Compile' => 0,
  'File::Slurp' => 0,
  'Test::More' => 0,
  'Text::Diff' => 0,
  'File::Path' => 2.08,
);

check_optional('Benchmark::Timer' => '0.7100',
  "Install Benchmark::Timer if you want to run \"make testspeed\"\n");

Add_Test_Target('testspeed', 't/speed.pl');

configure_programs();

license 'gpl2';
auto_license(holder => 'David Coppit');

no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

WriteAll();

use_standard_tests;

fix_sort_versions('inc/Sort/Versions.pm');
