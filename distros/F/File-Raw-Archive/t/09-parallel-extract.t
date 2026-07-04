#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

if ($^O eq 'MSWin32') {
    plan skip_all => 'parallel extract requires fork(2)';
}

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/many.tar";

my $N = 60;
my @expect;
my $w = File::Raw::Archive->create($tar);
for my $i (1 .. $N) {
    my $name    = sprintf("dir%02d/file%03d.txt", $i % 5, $i);
    my $content = "entry $i: " . ("payload" x ($i % 17));
    $w->add(name => $name, content => $content, mode => 0644);
    push @expect, [ $name, $content ];
}
$w->close;

# Sequential extract for the baseline.
my $seq_dest = "$dir/seq";
File::Raw::Archive->extract_all($tar, $seq_dest, parallel => 1);

# Parallel extract with 4 workers.
my $par_dest = "$dir/par";
File::Raw::Archive->extract_all($tar, $par_dest, parallel => 4);

# Verify each entry exists in both, with bit-identical content.
for my $row (@expect) {
    my ($name, $content) = @$row;
    my $sp = "$seq_dest/$name";
    my $pp = "$par_dest/$name";
    ok(-f $sp, "sequential: $name exists");
    ok(-f $pp, "parallel:   $name exists");

    open my $sfh, '<:raw', $sp or die "open $sp: $!";
    my $sb = do { local $/; <$sfh> }; close $sfh;
    open my $pfh, '<:raw', $pp or die "open $pp: $!";
    my $pb = do { local $/; <$pfh> }; close $pfh;

    is($sb, $content, "sequential content matches for $name");
    is($pb, $content, "parallel content matches for $name");
}

# Error aggregation: write to a read-only directory; expect a structured
# croak with the worker error inside.
SKIP: {
    skip "running as root, can't test permission denial", 2 if $> == 0;

    my $bad_tar = "$dir/bad.tar";
    my $bw = File::Raw::Archive->create($bad_tar);
    $bw->add(name => 'inside.txt', content => 'oops');
    $bw->close;

    my $bad_dest = "$dir/badextract";
    mkdir $bad_dest or die "mkdir: $!";
    chmod 0500, $bad_dest;       # read+execute, no write

    my $err;
    eval { File::Raw::Archive->extract_all($bad_tar, $bad_dest, parallel => 2); 1 } or $err = $@;
    ok($err, 'parallel extract croaks when worker hits permission error');
    like($err, qr/Permission denied|errors during parallel extract/i,
        'error message names the failure mode');

    chmod 0755, $bad_dest;       # restore so tempdir cleanup works
}

done_testing;
