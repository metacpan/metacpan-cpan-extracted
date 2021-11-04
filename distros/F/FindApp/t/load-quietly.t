#!/usr/bin/env perl

use t::setup;
use Capture::Tiny qw(:all);

#######################################################################

my @modules = grep ! / \b Exporter \b /x => modules_in_libdirs @LIBDIRS;
plan tests => 1 + 3*@modules;

my $MIN_MODS = 30;
cmp_ok(@modules, ">=", $MIN_MODS,
       "found at least $MIN_MODS modules to use under @LIBDIRS");

for my $module (@modules) {

    my($stdout, $stderr, $status) = capture {
        system $^X, qw(-Ilib -It/lib -w), "-M$module", "-e1";
    };
    cmp_ok($status, "==",   0, "$module loaded ok");
    cmp_ok($stdout, "eq", q(), "loading $module emitted nothing on stdout");
    cmp_ok($stderr, "eq", q(), "loading $module emitted nothing on stderr");

}

#######################################################################

done_testing();

__END__
