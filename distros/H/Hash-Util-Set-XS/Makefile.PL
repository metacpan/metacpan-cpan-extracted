use lib '.';
use strict;
use warnings;

BEGIN {
  unshift @INC, 'inc';
  
  my @required = (
    'inc::Module::Install'           => '1.00',
    'Module::Install::XSUtil'        => '0.36',
    'Module::Install::ReadmeFromPod' => '0',
  );

  my @missing;
  while(my($module, $version) = splice(@required, 0, 2)) {
    eval qq{use $module $version (); 1}
      or push @missing, $module;
  }

  if(@missing) {
    print qq{# The following modules are not available.\n};
    print qq{# `perl $0 | cpanm` will install them:\n};
    s/\A inc:: //x for @missing;
    print $_, "\n" for @missing;
    exit 1;
   }
}

use inc::Module::Install;

name           'Hash-Util-Set-XS';
perl_version   '5.010001';
all_from       'lib/Hash/Util/Set/XS.pm';
repository     'https://github.com/chansen/p5-hash-util-set-xs';
bugtracker     'https://github.com/chansen/p5-hash-util-set-xs/issues';
readme_from    'lib/Hash/Util/Set/XS.pod';

requires       'XSLoader'        => '0';
requires       'Hash::Util::Set' => '0';
test_requires  'Test::More'      => '0.88';

cc_warnings;

requires_external_cc;

WriteAll;
