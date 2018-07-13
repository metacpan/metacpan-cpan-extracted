#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use lib '.';
use inc::Module::Install;
use Module::Install::GetProgramLocations;

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

# Perl 5.6 doesn't work with URI::Escape. We get an error about Exporter not exporting "import"
perl_version '5.008';

configure_requires(
  # Module::Install::Bugtracker needs this
  'URI::Escape' => 0,
);

requires(
  'FileHandle::Unget' => 0,
  'Storable' => 0,
);

test_requires(
  'Test::Compile' => 0,
  'File::Slurper' => 0,
  'Test::More' => 0,
  'Text::Diff' => 0,
  'File::Path' => 2.08,
);

check_optional('Benchmark::Timer' => '0.7100',
  "Install Benchmark::Timer if you want to run \"make testspeed\"\n");

Add_Test_Target('testspeed', 't/speed.pl');

configure_programs();

license 'gpl2';

use_standard_tests;

auto_license(holder => 'David Coppit');

no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

realclean_files('inc');

WriteAll;

# ---- Workaround for broken module ----
# https://rt.cpan.org/Ticket/Display.html?id=125772
{
  package Module::Install::StandardTests;

  sub write_standard_test_compile {
      my $self = shift;
      $self->write_test_file('000_standard__compile.t', q/
          BEGIN {
            if ($^O eq 'MSWin32') {
              require Test::More;
              Test::More->import(skip_all =>
                  "Test::Compile doesn't work properly on Windows");
            } else {
              require Test::More;
              Test::More->import();
              eval "use Test::Compile";
              Test::More->builder->BAIL_OUT(
                  "Test::Compile required for testing compilation") if $@;
              all_pm_files_ok();
            }
          }
      /);
  }
}

fix_sort_versions('inc/Sort/Versions.pm');
