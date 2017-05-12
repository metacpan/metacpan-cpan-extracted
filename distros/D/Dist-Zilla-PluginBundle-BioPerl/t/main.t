#!/usr/bin/env perl
use utf8;

# AUTHOR:   Carnë Draug <carandraug+dev@gmail.com>
# OWNER:    2017 Carnë Draug
# LICENSE:  Perl_5

use strict;
use warnings;

use Test::More;

use Test::DZil;
use Test::Fatal;

my $module_text = <<'END';
package Foo::Bar;

# AUTHOR: this guy
# OWNER: that other guy
# LICENSE: Perl_5

1;
END


my $dzil_ini = simple_ini (
  {name => 'Foo-Bar', version => '0.010'},
  '@BioPerl',
);

my $tzil = Test::DZil->Builder->from_config (
  {dist_root => 'does-not-exist'},
  {
    add_files => {
      "source/dist.ini" => $dzil_ini,
      "source/lib/Foo/Bar.pm" => $module_text,
      "source/Changes" => "",
    },
  }
);
$tzil->chrome->logger->set_debug (1);

## At the very least, check that we can make a build with it.
is (exception { $tzil->build },undef, 'build completes');

done_testing;
