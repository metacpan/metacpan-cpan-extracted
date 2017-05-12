#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;

$| = 1;

my $bin_dir = shift;

while ( my $plist = shift ) {
    my ( undef, undef, $leaf ) = File::Spec->splitpath( $plist );
    my %lookup = (
        BIN_DIR  => $bin_dir,
        HOME_DIR => glob '~',
    );
    patch_bin( $plist, $leaf, \%lookup );
}

sub patch_bin {
    my ( $in, $out, $lookup ) = @_;
    open my $ph, '<', $in or die "Can't read $in ($!)\n";
    my $pl = do { local $/; <$ph> };
    close $ph;
    $pl =~ s/\%(\w+)\%/$lookup->{$1}/g;
    open my $po, '>', $out or die "Can't write $out ($!)\n";
    print $po $pl;
    close $po;
}
