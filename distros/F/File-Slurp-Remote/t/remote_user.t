#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Test::More;
use File::Temp qw(tempdir);

BEGIN { unshift(@INC, "$FindBin::Bin/../lib") unless $ENV{HARNESS_ACTIVE}; }

plan skip_all => 'Needs a POSIX shell' if $^O eq 'MSWin32';

use File::Slurp::Remote;
use File::Slurp::Remote::SmartOpen;

my $dir = tempdir(CLEANUP => 1);
my $log = "$dir/ssh.log";

# A stand-in for ssh: record user@host, then run the command locally
my $fake = "$dir/fake_ssh";
open(my $fh, '>', $fake) or die "$fake: $!";
print $fh <<'EOF';
my $log = shift;
my $user;
while (@ARGV && $ARGV[0] =~ /^-/) {
	my $opt = shift;
	shift if $opt eq '-o';
	$user = shift if $opt eq '-l';
}
my $dest = shift;
$dest = "$user\@$dest" if defined $user;
open(my $l, '>>', $log) or die "$log: $!";
print $l "$dest\n";
close $l;
exec('/bin/sh', '-c', join(' ', @ARGV)) or die "exec: $!";
EOF
close($fh);

$File::Slurp::Remote::SmartOpen::ssh = "$^X $fake $log";

$File::Slurp::Remote::BrokenDNS::myfqdn = 'local';
$File::Slurp::Remote::BrokenDNS::cache{local} = 'local';
$File::Slurp::Remote::BrokenDNS::cache{otherhost} = 'otherhost';

sub last_dest
{
	open(my $l, '<', $log) or return;
	my @lines = <$l>;
	chomp(my $d = $lines[-1]);
	return $d;
}

write_remote_file('fred@otherhost', "$dir/A", "A1\nA2\n");
is(last_dest(), 'fred@otherhost', 'write: user@host passed to ssh');
is(read_file("$dir/A"), "A1\nA2\n", 'write: contents arrived');

is(read_remote_file('fred@otherhost', "$dir/A"), "A1\nA2\n", 'read: user@host');
is(last_dest(), 'fred@otherhost', 'read: user@host passed to ssh');

my @lines = read_remote_file('fred@otherhost', "$dir/A");
is_deeply(\@lines, ["A1\n", "A2\n"], 'read: list context returns lines');

read_remote_file('otherhost', "$dir/A");
is(last_dest(), 'otherhost', 'no user: host passed unchanged');

# Like ssh, the user name ends at the last @
read_remote_file('fred@example.com@otherhost', "$dir/A");
is(last_dest(), 'fred@example.com@otherhost', 'user containing @');

# Like scp, the host ends at the first colon, so the path may contain colons
write_remote_file('fred@otherhost', "$dir/x:y", "XY\n");
is(last_dest(), 'fred@otherhost', 'path with a colon: host found');
is(read_file("$dir/x:y"), "XY\n", 'path with a colon: written to the right file');

# A colon after a slash is part of a local path
unlink $log;
smartopen("$dir/L:1", my $lfd, 'w');
print $lfd "L\n";
close $lfd;
is(read_file("$dir/L:1"), "L\n", 'local path with a colon');
ok(!-e $log, 'local path with a colon does not use ssh');

# A different user on the local host must still go via ssh
unlink $log;
my $me = File::Slurp::Remote::SmartOpen::_local_user();
my $other = "not_$me";
is(read_remote_file("$other\@local", "$dir/A"), "A1\nA2\n", 'other user on local host');
is(last_dest(), "$other\@local", 'other user on local host uses ssh');

# The same user on the local host does not
SKIP: {
	skip 'Cannot determine the local user name', 2 if $me eq '';
	unlink $log;
	is(read_remote_file("$me\@local", "$dir/A"), "A1\nA2\n", 'same user on local host');
	ok(!-e $log, 'same user on local host does not use ssh');
}

# Option injection and empty names are refused
eval { read_remote_file('-oProxyCommand=x@otherhost', "$dir/A") };
like($@, qr/invalid user/, 'user beginning with - is refused');
eval { read_remote_file('-oProxyCommand=x', "$dir/A") };
like($@, qr/invalid host/, 'host beginning with - is refused');
eval { read_remote_file('@otherhost', "$dir/A") };
like($@, qr/invalid user/, 'empty user is refused');
eval { read_remote_file('fred@', "$dir/A") };
like($@, qr/invalid host/, 'empty host is refused');

done_testing();
