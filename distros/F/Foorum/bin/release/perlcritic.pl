#!/usr/bin/perl -w

use strict;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use Perl::Critic;
use File::Next;
use File::Spec;

my $path = abs_path( File::Spec->catdir( $RealBin, '..', '..' ) );

my $files  = File::Next::files($path);
my $critic = Perl::Critic->new();

open( my $fh, '>', File::Spec->catfile( $RealBin, 'critic.txt' ) );
flock( $fh, 2 );

while ( defined( my $file = $files->() ) ) {
    next if ( $file !~ /\.(p[ml]|t)$/ );    # only .pm .pl .t
    next if ( $file =~ /Schema\.pm$/ );     # skip this file
    next
        if ( $file =~ /(\/|\\)Schema(\/|\\)/ )
        ;                                   # skip Schema dir and Schema.pm
    next if ( $file =~ /Version\.pm/ );     # skip Foorum/Version.pm

    print "$file\n";

    my @violations = $critic->critique($file);
    $file =~ s/\\/\//isg;                   # for Win32
    $file =~ s/^$path//isg;
    unless ( scalar @violations ) {
        print $fh "$file source OK\n";
    } else {
        foreach (@violations) {
            print $fh "$file: $_";
        }
    }
}
close($fh);

1;
