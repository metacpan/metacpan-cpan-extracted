#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker;

#------------------------------------------------------------
# Makefile:
#------------------------------------------------------------
my %extra_prereq = (
  'Mail::Address'     => 1.62,
  'MIME::Types'       => 1.28,
  'MIME::Base64'      => undef,
  'MIME::QuotedPrint' => undef,
);

for my $module (sort keys %extra_prereq) {
  local $@;
  my $ok = eval "require $module; \$extra_prereq{\$module} && \$module->VERSION(\$extra_prereq{\$module}); 1";
  delete $extra_prereq{ $module } if $ok;
}

my %prereq = (
  'File::Spec'          => 0,
  'File::Basename'      => 0,
  'Email::Date::Format' => '1.000', # first release
);

if (%extra_prereq) {
  print "MIME::Lite is designed to take advantage of a variety of external modules\n",
        "if they are not present then MIME::Lite will attempt to do its best\n",
        "but its strongly recommend that you install them.\n\n",
        "These modules are:\n",
        (map {; "\t$_\n" } sort keys %extra_prereq),
        "I can add these modules to the prereq list which will cause the files to be\n",
        "automatically installed if they aren't already present\n";

  if (prompt("Add prereqs?",'Yes')=~/y/i) {
    %prereq = (%prereq, %extra_prereq);
  }
}

# Write the Makefile:
WriteMakefile(
  NAME         => 'MIME::Lite',
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  VERSION_FROM => "lib/MIME/Lite.pm",
  DISTNAME     => "MIME-Lite",
  'dist'       => {
    #PREOP    => 'cvu_perl_preop -m MIME::Lite -f',#demerphq
    COMPRESS => 'gzip',
    SUFFIX   => 'gz',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) }
    ? (META_MERGE => {
        resources => {
          repository => 'http://github.com/rjbs/MIME-Lite'
        }
      })
    : ()
  ),
  'PREREQ_PM'    => \%prereq,
);

