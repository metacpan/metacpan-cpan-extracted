#!/usr/bin/perl
use warnings;
use strict;

use Array::Utils qw(unique);
use Data::Dumper;
use Getopt::Long;
use IO::All;
use Pod::Usage;
use autodie;

$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;

my %opts = (
    help => 0,
    'mime-types' => '/etc/mime.types',
);

{
    local $SIG{__WARN__};
    my $ok = eval {GetOptions(\%opts, qw(help mime-types=s dans=s))};
    if (!$ok) {
        die($@);
    }
}

pod2usage(0) if ($opts{help});

my @required = qw(dans mime-types);
foreach (@required) {
    if (!defined $opts{$_}) {
        pod2usage(1);
    }
}

my %list;
my $type;
my %mime;

open my $mime, '<', $opts{'mime-types'};
while (<$mime>) {
    next if ($_ =~ /^#/);
    chomp();

    my ($type, @ext) = split(/\s+/, $_);
    foreach (@ext) {
        $mime{".$_"} = $type;
    }
}
close($mime);

open my $dans, '<', $opts{dans};
my $mimetype;
while(<$dans>) {
    chomp();

    if ($_ =~ /2.\d+\s+(.*)/) {
        $type = $1;
        next;
    }
    if ($_ =~ /•\s*(.*) \((.*)\)/) {
        my $what = $1;
        my $ext = $2;
        if ($what =~ /Related files: (.*)/) {
            $ext = $1;
            $what = "Related files";
        }
        my @extensions = split(/[,;\/\&]/, $ext);
        foreach my $ext (@extensions) {
            $ext =~ s/^\s+//g;
            $mimetype = $mime{$ext} // $ext;
            push(@{$list{$mimetype}{allowed_extensions}}, $ext);
            @{$list{$mimetype}{allowed_extensions}} = unique(@{$list{$mimetype}{allowed_extensions}}, $ext);
            push(@{$list{$mimetype}{types}}, "$type ($what)");
        }
    }
}
close($dans);

print Dumper (\%list);
