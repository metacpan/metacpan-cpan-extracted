#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use File::Bidirectional;
use Time::HiRes qw/gettimeofday tv_interval/;
use IO::Handle;
use IO::File;

=pod
fwd: 42660.436
bwd: 40813.359
tie: 51228.955
raw: 5321.453
oo: 15722.043
=cut

my $file    = shift;
my $max     = -1;
# my $max     = 10;
my $usage   = <<EOT;
    Usage: $0 FILE
EOT

die $usage
    unless defined $file;

sub output { print shift, ": ", tv_interval(shift) * 1000, "\n"; }

{
    my $c = 0;
    my $fh = File::Bidirectional->new($file)
        or die $!;

    my $time = [gettimeofday()];
    while (my $line = $fh->readline()) {
        chomp $line;
        last if ++$c == $max;
    }
    output('File::Bidirectional (forward)', $time);
    $fh->close();
}

{
    my $c = 0;
    my $fh = File::Bidirectional->new($file, {mode => 'backward'})
        or die $!;

    my $time = [gettimeofday()];
    while (my $line = $fh->readline()) {
        chomp $line;
        last if ++$c == $max;
    }
    output('File::Bidirectional (backward)', $time);
    $fh->close();
}

{
    my $c = 0;
    local *F;
    tie *F, "File::Bidirectional", $file
        or die $!;
    my $fh = \*F;

    my $time = [gettimeofday()];
    while (my $line = <$fh>) {
        chomp $line;
        last if ++$c == $max;
    }
    output('File::Bidirectional (tie)', $time);
    $fh->close();

    undef $fh;
}

{
    my $c = 0;
    open my $fh, $file or die $!;

    my $time = [gettimeofday()];
    while (my $line = <$fh>) {
        chomp $line;
        last if ++$c == $max;
    }
    output('Native Perl', $time);
    close $fh;
}

{
    my $c = 0;
    my $fh = new IO::File $file or die $!;

    my $time = [gettimeofday()];
    while (my $line = $fh->getline()) {
        chomp $line;
        last if ++$c == $max;
    }
    output('IO::File', $time);

    $fh->close();
}
