use Test::More;
use lib 'lib';
use MCP::Run::Compress;

subtest 'compress ls -la' => sub {
  my $c = MCP::Run::Compress->new;

  my $input = <<'OUTPUT';
total 24
drwxr-xr-x  14 getty getty  4096 Apr 24 02:32 .
drwxr-xr-x  22 getty getty  4096 Apr 24 00:29 ..
drwxr-xr-x   7 getty getty  4096 Apr 24 02:28 .git
-rw-r--r--   1 getty getty   246 Mar 12 04:03 .gitignore
drwxr-xr-x  14 getty getty  4096 Apr 24 02:32 .build
drwxr-xr-x   2 getty getty  4096 Mar 25 20:10 .claude
Device: 801h/2049d      Inode: 1234567     Links: 1
 Birth: 2024-01-01 00:00:00.000000000 +0000
OUTPUT

  my ($out, $err) = $c->compress('ls -la', $input, '');
  note "OUTPUT: $out";

  unlike($out, qr/Device:/, 'Device stripped');
  unlike($out, qr/Inode:/, 'Inode stripped');
  unlike($out, qr/Birth:/, 'Birth stripped');
  unlike($out, qr/total\s+\d+/, 'total stripped');
  like($out, qr/\.gitignore/, '.gitignore kept');

  done_testing;
};

subtest 'compress stat' => sub {
  my $c = MCP::Run::Compress->new;

  my $input = <<'OUTPUT';
  File: main.rs
  Size: 12345           Blocks: 24         IO Block: 4096   regular file
Device: 801h/2049d      Inode: 1234567     Links: 1
Access: (0644/-rw-r--r--)  Uid: ( 1000/ patrick)   Gid: ( 1000/ patrick)
Access: 2026-03-10 12:00:00.000000000 +0100
Modify: 2026-03-10 11:00:00.000000000 +0100
Change: 2026-03-10 11:00:00.000000000 +0100
 Birth: 2026-03-09 10:00:00.000000000 +0100
OUTPUT

  my ($out, $err) = $c->compress('stat main.rs', $input, '');
  note "OUTPUT: $out";

  unlike($out, qr/Device:/, 'Device stripped');
  unlike($out, qr/Inode:/, 'Inode stripped');
  unlike($out, qr/Birth:/, 'Birth stripped');
  like($out, qr/Size: 12345/, 'Size kept');
  like($out, qr/Access: \(0644/, 'Mode kept');

  done_testing;
};

subtest 'compress make' => sub {
  my $c = MCP::Run::Compress->new;

  my $input = <<'OUTPUT';
make[1]: Entering directory '/home/user/project'
gcc -O2 foo.c
bar.c
make[1]: Leaving directory '/home/user/project'
Nothing to be done
OUTPUT

  my ($out, $err) = $c->compress('make', $input, '');
  note "OUTPUT: $out";

  unlike($out, qr/Entering directory/, 'Entering stripped');
  unlike($out, qr/Leaving directory/, 'Leaving stripped');
  unlike($out, qr/Nothing to be done/, 'Nothing stripped');
  like($out, qr/gcc/, 'gcc kept');
  like($out, qr/bar\.c/, 'bar.c kept');

  done_testing;
};

subtest 'compress grep' => sub {
  my $c = MCP::Run::Compress->new;

  my $input = <<'OUTPUT';
src/main.rs:sub main {
src/main.rs:  say "hello";
src/main.rs:}
lib/Foo.pm:sub bar {
lib/Foo.pm:  my $self = shift;
OUTPUT

  my ($out, $err) = $c->compress('grep -r hello .', $input, '');
  note "OUTPUT: $out";

  like($out, qr/src\/main\.rs/, 'file:line kept');
  like($out, qr/say "hello"/, 'match content kept');

  done_testing;
};

subtest 'compress df' => sub {
  my $c = MCP::Run::Compress->new;

  my $input = <<'OUTPUT';
Filesystem     1K-blocks   Used Available Use% Mounted on
/dev/sda1        4096000 123456   3972544   4% /
tmpfs            1024000   1024   1022976   1% /dev/shm
/dev/sdb1      209715200 7890120 201866080  20% /home
/dev/sdc1      524288000 1234567896 400831104  75% /data/very/long/path/that/exceeds/80/columns
OUTPUT

  my ($out, $err) = $c->compress('df -h', $input, '');
  note "OUTPUT: $out";

  unlike($out, qr/very\/long\/path\/that\/exceeds\/80\/columns/, 'long path truncated');
  like($out, qr/\/dev\/sda1/, 'filesystem kept');

  done_testing;
};

subtest 'compress git diff' => sub {
  my $c = MCP::Run::Compress->new;

  my $input = <<'OUTPUT';
diff --git a/lib/Foo.pm b/lib/Foo.pm
index 1234567..89abcdef 100644
--- a/lib/Foo.pm
+++ b/lib/Foo.pm
@@ -10,6 +10,8 @@ sub bar {
+use strict;
+use warnings;
   my $self = shift;
   return $self->{bar};
 }
OUTPUT

  my ($out, $err) = $c->compress('git diff', $input, '');
  note "OUTPUT: $out";

  unlike($out, qr/diff --git/, 'diff header stripped');
  unlike($out, qr/index /, 'index stripped');
  like($out, qr/\+use strict/, 'added line kept');

  done_testing;
};

subtest 'no compress for unknown command' => sub {
  my $c = MCP::Run::Compress->new;

  my $input = "some output\nwith lines\nand more";
  my ($out, $err) = $c->compress('unknown-command --flag', $input, '');
  is($out, $input, 'unknown command passes through unchanged');

  done_testing;
};

subtest 'max_lines truncation' => sub {
  my $c = MCP::Run::Compress->new;

  # Use find which has max_lines => 50 and minimal strip_lines_matching
  my @lines = map { "/path/to/file$_" } (1..60);
  my $input = join("\n", @lines);
  my ($out, $err) = $c->compress('find', $input, '');
  note "OUTPUT: $out";

  like($out, qr/more lines/, 'shows truncation notice');

  done_testing;
};

subtest 'on_empty fallback' => sub {
  my $c = MCP::Run::Compress->new;

  # Force whitespace-only content that gets stripped to empty
  my ($out, $err) = $c->compress('make', "   \n\n  \n", '');
  note "OUTPUT: $out";

  is($out, 'make: ok', 'on_empty message shown');

  done_testing;
};

done_testing;
