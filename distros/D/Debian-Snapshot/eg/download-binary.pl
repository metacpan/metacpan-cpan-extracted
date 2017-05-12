#! /usr/bin/perl

use strict;
use warnings;

use Debian::Snapshot;
use Pod::Usage;

pod2usage() unless @ARGV == 4;
my ($binary, $binary_version, $arch, $directory) = @ARGV;

my $snapshot = Debian::Snapshot->new;
my $binaries = $snapshot->binaries($binary, $binary_version);

error("Package not found.") unless @$binaries;
error("More than one binary with the same version found. I am confused.")
    unless @$binaries == 1;

my $files  = $$binaries[0]->download(architecture => $arch, directory => $directory);

print "Downloaded the following files:\n";
print "$files\n";

sub error {
	print STDERR @_, "\n";
	exit 1;
}

__END__

=head1 NAME

download-binary.pl - download binary packages from snapshot.debian.org

=head1 SYNOPSIS

  download-binary.pl [binary-package] [binary-version] [arch] [target-directory]
