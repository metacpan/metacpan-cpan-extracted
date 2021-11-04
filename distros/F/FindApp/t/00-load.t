#!/usr/bin/env perl

use t::setup;

#######################################################################
# t/000-load.t # Give up entirely if cannot load our modules.
#######################################################################

my @modules = modules_in_libdirs @LIBDIRS;
plan tests => 1 + @modules;

my $MIN_MODS = 30;
cmp_ok(@modules, ">=", $MIN_MODS,
       "found at least $MIN_MODS modules to use under @LIBDIRS");

my @failed;
for my $module (@modules) {
    require_ok($module) || push @failed, $module;
}

if (@failed) {
    BAIL_OUT(sprintf("Cannot run test suite without module%s %s.\n",
        @failed > 1 ? "s" : "", join(", " => @failed)));
}

done_testing();

__END__

