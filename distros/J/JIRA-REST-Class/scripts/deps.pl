#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use CPAN::Meta;
use Module::Load;

my $file = shift @ARGV or die "Must provide META file!\n";

my $meta = CPAN::Meta->load_file($file);
my $prereqs = $meta->effective_prereqs;

if (my $phase = shift @ARGV) {
    my $missing = shift @ARGV;
    my $reqs = $prereqs->requirements_for($phase, "requires");
    for my $module ( sort $reqs->required_modules ) {
        my $status;
        if ( eval { load $module unless $module eq 'perl'; 1 } ) {
            my $version = $module eq 'perl' ? $] : $module->VERSION;
            $status = $reqs->accepts_module($module, $version)
                    ? "ok" : "not ok";
        } else {
            $status = "missing"
        };
        if ($missing) {
            say $module if $status eq "missing";
        }
        else {
            say "  $module ($status)";
        }
    }
}
else {
    say "PHASES: ".join q{ }, $prereqs->phases;
}
