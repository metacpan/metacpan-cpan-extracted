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
my (@made_meta, @made_dirs);
my $had_meta = -e 'META.yml' && -e 'META.json';
unless ($had_meta) {
    plan skip_all => 'no Makefile — run perl Makefile.PL first' unless -e 'Makefile';
    my %before = map { $_ => 1 } bsd_glob('EV-Etcd-*/');
    system($ENV{MAKE} || 'make', 'distmeta') == 0
        or plan skip_all => 'make distmeta failed';

    my ($dist_dir) = grep { !$before{$_} } bsd_glob('EV-Etcd-*/');
    ($dist_dir) = bsd_glob('EV-Etcd-*/') unless defined $dist_dir;
    if ($dist_dir && -e "${dist_dir}META.yml" && -e "${dist_dir}META.json") {
        for my $f ('META.yml', 'META.json') {
            next if -e $f;
            File::Copy::copy("${dist_dir}$f", $f) or plan skip_all => "copy $f: $!";
            push @made_meta, $f;
        }
        push @made_dirs, $dist_dir unless $before{$dist_dir};
    } else {
        plan skip_all => 'distmeta did not produce META files';
    }
}

kwalitee_ok();
done_testing();

END {
    # Remove only what this run created; a skipped run cleans nothing
    for my $d (@made_dirs) {
        system('rm', '-rf', $d);
    }
    unlink @made_meta if @made_meta;
}
