#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename;
use LWP::UserAgent;
use POSIX qw(strftime);

my $path_to_default = abs_path(dirname(__FILE__) . '/../lib/Domain/PublicSuffix/Default.pm');
print "Altering $path_to_default\n";


print "Retrieving suffix...\n";
my $suffix = retrieve_suffix();

print "Retrieved suffix (" . length($suffix) . " bytes).\n";

print "Reading...\n";
my $lines = read_default();

print "Transforming...\n";
my $updated = inject_new_suffix($lines, $suffix);

print "Writing...\n";
write_default($updated);

sub read_default {
    my @default;
    open(my $rfh, '<:utf8', $path_to_default) or die $!;
    while (<$rfh>) {
        push(@default, $_);
    }
    close($rfh);
    return \@default;
}

sub inject_new_suffix {
    my ($default_lines, $suffix_blob) = @_;
    my @new_file;
    my $in_blob = 0;
    foreach my $line (@{$default_lines}) {
        if ($line =~ /This was last updated on/) {
            $line = 'This was last updated on ' . strftime('%Y-%m-%d', localtime) . ".\n";
        }
        if ($line =~ /^\}\)/) {
            $in_blob = 0;
            push(@new_file, split(/\r\n/, $suffix_blob));
        }
        unless ($in_blob) {
            push(@new_file, $line);
        }
        if ($line =~ /my \@lines/) {
            $in_blob++;
        }
    }
    return \@new_file;
}

sub write_default {
    my ($lines) = @_;

    open(my $wfh, '>:utf8', $path_to_default) or die $!;
    foreach (@{$lines}) {
        print $wfh $_;
    }
    close($wfh);
}

sub retrieve_suffix {
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $response = $ua->get('https://publicsuffix.org/list/public_suffix_list.dat');
    if ($response->is_success()) {
        return $response->decoded_content((charset => 'UTF-8'));
    } else {
        die 'Unable to retrieve suffix: ' . $response->status_line;
    }
}

1;
