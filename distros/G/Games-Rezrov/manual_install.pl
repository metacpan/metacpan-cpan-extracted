#!/usr/bin/perl -w
# manually install Games::Rezrov modules and script.
# - with no switch: install
# - with "-u" switch: uninstall

use strict;
use Config;

use File::Path;
use File::Copy;
use File::Spec;

my $scriptdir = $Config{"installscript"};
my $top_lib = $Config{"installsitelib"};

my $uninstall_mode = @ARGV ? lc($ARGV[0]) eq "-u" : 0;

my $glib = File::Spec->catfile($top_lib, "Games", "Rezrov");
unless (-d $glib) {
    mkpath($glib) || die "can't create $glib";
    # make Games::Rezrov directory
}

my @modules = glob("*.pm");
foreach my $module (@modules) {
    my $target_file = File::Spec->catfile($glib, $module);
    if ($uninstall_mode) {
      unlink $target_file || printf STDERR "can't unlink $target_file\n";
    } else {
      # install
      copy($module, $target_file) || die "can't copy $module to $target_file";
    }
}

printf "Modules installed to: %s\n", $glib unless $uninstall_mode;

my $script_target = File::Spec->catfile($scriptdir, "rezrov");
if ($uninstall_mode) {
  unlink($script_target) || printf STDERR "can't unlink $script_target\n";
} else {
  copy("rezrov", $script_target) || die "can't copy rezrov to $script_target";
  printf "rezrov installed to: %s\n", $script_target;
}





