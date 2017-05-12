#! /usr/bin/perl

use strict;
use warnings;

use Debian::Snapshot;
use Pod::Usage;

pod2usage() unless @ARGV == 3;
my ($source, $version, $directory) = @ARGV;

my $snapshot = Debian::Snapshot->new;
my $package  = $snapshot->package($source, $version);
my $files    = $package->download(directory => $directory);

print "Downloaded the following files:\n";
print join("\n", @$files);
print "\n";

__END__

=head1 NAME

download-source.pl - download source packages from snapshot.debian.org

=head1 SYNOPSIS

  download-source.pl [package] [version] [target-directory]
