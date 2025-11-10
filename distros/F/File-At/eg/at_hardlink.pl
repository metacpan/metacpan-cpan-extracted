#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

use Getopt::Long qw(GetOptions);
use File::Find ();
use File::Basename qw(dirname);
use Fcntl qw(:DEFAULT :mode);
use Digest::MD5;
use File::Spec;

# relies on your File::At implementation
use File::At qw(dir open_fh_at linkat unlinkat mkdirat AT_FDCWD);

my $help   = 0;
my $apply  = 0;   # dry-run by default
my $verbose = 0;

GetOptions(
  'help|h'   => \$help,
  'apply'    => \$apply,
  'verbose'  => \$verbose,
) or die "Bad options\n";

if ($help || @ARGV != 2) {
  die <<"USAGE";
Usage: $0 [--apply] [--verbose] <src_root> <dst_root>

Scans SRC_ROOT and DST_ROOT. For each regular file in SRC_ROOT,
if DST_ROOT has a file at the same relative path and the contents
match (MD5), replace the destination file with a hard link to the
source (unless --apply is omitted, in which case it's a dry run).
USAGE
}

my ($src_root, $dst_root) = @ARGV;

# create dir objects (they hold opendir handles and fd)
my $src = File::At::dir($src_root);
my $dst = File::At::dir($dst_root);

# small helpers
sub md5_of_fh {
    my ($fh) = @_;
    my $ctx = Digest::MD5->new;
    my $buf;
    seek $fh, 0, 0 if tell($fh) && defined(&seek);
    while (my $r = sysread($fh, $buf, 8192)) {
        $ctx->add($buf);
    }
    die "read error: $!" unless defined $r;
    return $ctx->hexdigest;
}

sub ensure_dst_parent_dirs {
    my ($rel) = @_;
    my $dir_rel = dirname($rel);
    return if $dir_rel eq '.' || $dir_rel eq '';
    # walk from the root and ensure each component exists
    my @parts = File::Spec->splitdir($dir_rel);
    my $prefix = '';
    for my $p (@parts) {
        $prefix = $prefix eq '' ? $p : File::Spec->catfile($prefix, $p);
        eval {
            mkdirat($dst->fd, $prefix, 0755) == 0 or die $!;
            1;
        } or do {
            # if it failed, maybe it already existed; ignore EEXIST
            my $err = $@ || '';
            warn "mkdirat $prefix: $err" if $verbose;
        };
    }
}

# We'll build an array of relative paths by walking the source tree.
my @rel_paths;
File::Find::find(
  {
    no_chdir => 1,
    wanted => sub {
      my $full = $File::Find::name;
      # skip the root itself
      return if $full eq $src_root;
      # produce a relative path
      my $rel = File::Spec->abs2rel($full, $src_root);
      push @rel_paths, $rel if -f $full && -r $full; # only regular readable files
    },
  },
  $src_root
);

say "Found " . scalar(@rel_paths) . " regular files in source." if $verbose;

# Process each relative path
for my $rel (@rel_paths) {
    # Attempt to open src file via dirfd
    my $src_fh;
    eval {
        $src_fh = open_fh_at($src, $rel, O_RDONLY, 0);
        1;
    } or do {
        warn "open source $rel failed: $@" and next;
    };

    # compute md5 and size for src
    my $src_md5 = eval { md5_of_fh($src_fh) };
    seek $src_fh, 0, 0 if defined $src_fh;
    warn "md5 src $rel failed: $@" and next unless defined $src_md5;

    # Try to open dest; if missing, skip
    my $dst_fh;
    my $dst_exists = 1;
    eval {
        $dst_fh = open_fh_at($dst, $rel, O_RDONLY, 0);
        1;
    } or do {
        $dst_exists = 0;
    };

    unless ($dst_exists) {
        say "DEST missing: $rel" if $verbose;
        next;
    }

    my $dst_md5 = eval { md5_of_fh($dst_fh) };
    warn "md5 dst $rel failed: $@" and next unless defined $dst_md5;

    if ($src_md5 ne $dst_md5) {
        say "DIFFERS: $rel" if $verbose;
        next;
    }

    # contents match -> plan to replace dst with hard link to src
    say "MATCH: $rel" if $verbose;

    if ($apply) {
        # ensure parent dirs exist
        ensure_dst_parent_dirs($rel);

        # unlink destination (if present) then link
        eval {
            unlinkat($dst->fd, $rel, 0) == 0 or die "unlinkat: $!";
            1;
        } or do {
            warn "unlinkat $rel failed (proceeding anyway): $@";
        };

        eval {
            linkat($src->fd, $rel, $dst->fd, $rel, 0) == 0
              or die "linkat failed: $!";
            1;
        } or do {
            warn "linkat($rel) failed: $@. Maybe across filesystems?";
            # fallback: you might want to copy, or leave as-is
        };

        say "LINKED: $rel";
    } else {
        say "[dry-run] would link: $rel";
    }
}

say "done.";
