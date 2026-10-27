#!perl -T

# Checks the documented behaviour in taint mode: reading a file with a
# tainted name works, but writing to one dies with Perl's own error,
# since the module can't know whether the caller has checked the name.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(tainted);
use Test::Most;
use Test::Warnings;

use File::pfopen qw(pfopen);

my %config = (
	prefix => 'taint',
	suffix => 'txt',
	content => "tainted\n",
	insecure => qr/\AInsecure dependency in open while running with -T switch/,
);

# Anything read from a file is tainted; an empty piece of it taints whatever it is added to
open(my $self, '<', __FILE__) or die __FILE__, ": $!";
my $taint = substr(<$self>, 0, 0);
close($self);

plan(skip_all => 'Taint mode is not on') unless(tainted($taint));

my $dir = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, "$config{prefix}.$config{suffix}");
open(my $fout, '>', $file) or die "$file: $!";
print $fout $config{content};
close($fout) or die "$file: $!";

my $tainted_dir = $dir . $taint;
ok(tainted($tainted_dir), 'the directory name is tainted');

subtest 'reading a file with a tainted name works' => sub {
	my ($fh, $found) = pfopen($tainted_dir, $config{prefix}, $config{suffix}, '<');
	ok(defined($fh), 'tainted directory');
	is(<$fh>, $config{content}, 'read the file');

	($fh, $found) = pfopen([$dir], $config{prefix} . $taint, $config{suffix}, '<');
	ok(defined($fh), 'tainted prefix');
};

subtest 'writing to a file with a tainted name dies' => sub {
	throws_ok { pfopen($tainted_dir, $config{prefix}, $config{suffix}) } $config{insecure}, 'default mode';
	throws_ok { pfopen($tainted_dir, $config{prefix}, $config{suffix}, '>>') } $config{insecure}, "mode '>>'";
};

# The tainted calls above used the same directory, so a remembered tainted
#	name would make this die
subtest 'writing to a file with an untainted name works' => sub {
	my $fh;
	lives_ok { $fh = pfopen($dir, $config{prefix}, $config{suffix}) } 'not given a remembered tainted name';
	ok(defined($fh), 'default mode');
};

# The untainted call above was remembered; reusing it would skip the taint check
subtest 'a remembered untainted name does not bypass taint checks' => sub {
	throws_ok { pfopen($tainted_dir, $config{prefix}, $config{suffix}) } $config{insecure}, 'still dies';
};

done_testing();
