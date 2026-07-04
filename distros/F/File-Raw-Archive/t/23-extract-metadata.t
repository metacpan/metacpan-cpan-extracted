#!perl
# extract_all should preserve mode, mtime, and (when applicable) uid/
# gid on the materialised on-disk files. Mode round-trip is verified
# precisely; mtime is verified within a one-second tolerance because
# some filesystems round to second resolution.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;
use Fcntl qw(:mode);

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/meta.tar";

# Build with distinct modes per entry so we can verify each.
my $past_mtime = 1500000000;   # 2017-07
my $w = File::Raw::Archive->create($tar);
$w->add(name => 'plain.txt',  content => 'A', mode => 0644, mtime => $past_mtime);
$w->add(name => 'priv.txt',   content => 'B', mode => 0600, mtime => $past_mtime + 100);
$w->add(name => 'exec.sh',    content => "#!/bin/sh\n", mode => 0755, mtime => $past_mtime + 200);
$w->add(name => 'sub/',       mode => 0755, mtime => $past_mtime + 300);
$w->add(name => 'sub/a.txt',  content => 'C', mode => 0640);
$w->close;

my $dest = "$dir/out";
File::Raw::Archive->extract_all($tar, $dest);

# Mode preservation. Mask to 07777 to ignore suid/setgid/sticky bits
# (which the archive doesn't carry on these entries).
sub file_mode { (stat($_[0]))[2] & 07777 }

is(file_mode("$dest/plain.txt"),     0644, 'plain.txt mode preserved');
is(file_mode("$dest/priv.txt"),      0600, 'priv.txt mode preserved');
is(file_mode("$dest/exec.sh"),       0755, 'exec.sh mode preserved');
is(file_mode("$dest/sub/a.txt"),     0640, 'sub/a.txt mode preserved');

# Directory mode: created at 0755 by extract_all from the entry mode.
ok(-d "$dest/sub", 'sub/ is a directory');
ok(file_mode("$dest/sub") & 0700, 'sub/ has owner-traversal bits');

# mtime preservation (one-second tolerance for filesystem rounding).
sub mtime_of { (stat($_[0]))[9] }
my $delta1 = abs(mtime_of("$dest/plain.txt") - $past_mtime);
ok($delta1 <= 1, "plain.txt mtime within 1s of expected (delta=$delta1)");
my $delta2 = abs(mtime_of("$dest/priv.txt") - ($past_mtime + 100));
ok($delta2 <= 1, "priv.txt mtime within 1s of expected (delta=$delta2)");

# Content matches.
sub slurp_file {
    open my $fh, '<:raw', $_[0] or die "open $_[0]: $!";
    local $/; <$fh>;
}
is(slurp_file("$dest/plain.txt"), 'A',          'plain.txt content');
is(slurp_file("$dest/priv.txt"),  'B',          'priv.txt content');
is(slurp_file("$dest/exec.sh"),   "#!/bin/sh\n", 'exec.sh content');
is(slurp_file("$dest/sub/a.txt"), 'C',          'sub/a.txt content');

# extract_one should also preserve mode.
my $single_dest = "$dir/single.sh";
File::Raw::Archive->extract($tar, 'exec.sh', $single_dest);
is(file_mode($single_dest), 0755, 'extract single preserves mode');

done_testing;
