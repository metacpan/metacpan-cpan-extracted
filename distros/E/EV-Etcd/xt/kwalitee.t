#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Copy ();
use File::Spec;
use File::Glob ':bsd_glob';

eval "use Test::Kwalitee 1.28 'kwalitee_ok'; 1"
    or plan skip_all => 'Test::Kwalitee 1.28 required';

# Test::Kwalitee reads META.yml/META.json from the cwd, but make distmeta
# writes them into the staging dir, so they are copied up for the run
my $had_meta = -e 'META.yml' && -e 'META.json';
unless ($had_meta) {
    plan skip_all => 'no Makefile — run perl Makefile.PL first' unless -e 'Makefile';
    system($ENV{MAKE} || 'make', 'distmeta') == 0
        or plan skip_all => 'make distmeta failed';

    my ($dist_dir) = bsd_glob('EV-Etcd-*/');
    if ($dist_dir && -e "${dist_dir}META.yml" && -e "${dist_dir}META.json") {
        File::Copy::copy("${dist_dir}META.yml",  'META.yml')  or plan skip_all => "copy META.yml: $!";
        File::Copy::copy("${dist_dir}META.json", 'META.json') or plan skip_all => "copy META.json: $!";
    } else {
        plan skip_all => 'distmeta did not produce META files';
    }
}

kwalitee_ok();
done_testing();

END {
    # A staging dir left behind by make distmeta would shadow the next run's
    for my $d (bsd_glob('EV-Etcd-*/')) {
        system('rm', '-rf', $d);
    }
    unless ($had_meta) {
        unlink 'META.yml', 'META.json';
    }
}
