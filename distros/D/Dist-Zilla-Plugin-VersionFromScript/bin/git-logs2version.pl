#!/usr/bin/perl
#===============================================================================
#
#     ABSTRACT:  use number of git log messages as a standin for version number
#      PODNAME:  git-logs2version.pl
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      CREATED:  09/07/2011 11:27:40 AM PST
#===============================================================================

use strict;
use warnings;

use File::Basename;

our $VERSION = '0.017'; # VERSION

my $major = 0;
my $offset = 0;

my ($myname, undef, $suffix) = fileparse($0);
$myname .= $suffix;
my $help = "$myname [ --major number ] [ --offset number ]\n";

while (my $arg = shift) {
    if ($arg =~ s/^--?//) {
        if ($arg eq 'major') {
            $major = shift;
        } elsif ($arg eq 'offset') {
            $offset = shift;
        }
    } else {
        die $help;
    }
}
if (not defined ($major) or
    ($major =~ m/\D/)) {
    $major = '<undefined>' unless (defined($major));
    die "$help\n*** illegal major: $major (must be a non-negative integer)\n";
}
if (not defined ($offset) or
    ($offset !~ m/^-?\d+$/)) {
    $offset = '<undefined>' unless (defined($offset));
    die "$help\n*** illegal offset: $offset (must be an integer)\n";
}

my $cmd = "git log --pretty=oneline";
my @logs = `$cmd`;  # could use Git::Wrapper here

if ($? == -1) {
    die "failed to execute \"$cmd\": $!";
}
elsif ($? & 127) {
    die sprintf("$cmd failed (with%s coredump) with signal %d\n",
            ($? & 128) ? '' : 'out',
            ($? & 127),
        );
}
else {
    # printf "child exited with value %d\n", $? >> 8;
}

if (not @logs) {
    die "No log entries.  Is this really a git repo?";
}

my $ver = scalar(@logs) + $offset;

print STDERR "Version too big: $ver\n" if ($ver > 999);
printf ("%d.%03d\n", $major, $ver);



__END__
=pod

=head1 NAME

git-logs2version.pl - use number of git log messages as a standin for version number

=head1 VERSION

version 0.017

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

