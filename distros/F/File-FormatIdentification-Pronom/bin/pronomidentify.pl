#!/usr/bin/env perl
#===============================================================================
#
#         FILE: pronom2wxhexeditor.pl
#
#        USAGE: ./pronom2wxhexeditor.pl
#
#  DESCRIPTION: perl ./pronom2wxhexeditor.pl <DROIDSIGNATURE-FILE> <BINARYFILE>
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Andreas Romeyke,
#      CREATED: 22.07.2020 14:26:43
#     REVISION: ---
#===============================================================================
# PODNAME: pronomidentify.pl
use strict;
use warnings 'FATAL';
use utf8;
use feature qw(say);
use Fcntl qw(:seek);
use File::Map qw(:map :extra);
use File::FormatIdentification::Pronom;
use Getopt::Long;
use Carp;
use List::Util qw( all );

################################################################################
# main
################################################################################
my $pronomfile;
my $binaryfile;

GetOptions (
    "signature=s" => \$pronomfile,
    "binary=s" => \$binaryfile,
    "help" => sub {
        say "$0 --signature=droid_signature_filename --binary=binary_filename";
        say "$0 --help ";
        say "";
        exit 1;
    }
) or croak "wrong option, try '$0 --help'";

if ( !defined $pronomfile ) {
    say "you need at least a pronom signature file";
    exit;
}
if ( !defined $binaryfile ) {
    say "you need an binaryfile";
    exit;
}

my $pronom = File::FormatIdentification::Pronom->new(
    "droid_signature_filename" => $pronomfile
);

map_file my $filestream, $binaryfile, "<";
advise( $filestream, 'random' );

foreach my $internalid ( $pronom->get_all_internal_ids() ) {
    my $sig = $pronom->get_signature_id_by_internal_id($internalid);
    if (!defined $sig) {next;}
    my $puid = $pronom->get_puid_by_signature_id($sig);
    my $name = $pronom->get_name_by_signature_id($sig);
    my $quality = $pronom->get_qualities_by_internal_id($internalid);
    my @regexes = $pronom->get_regular_expressions_by_internal_id($internalid);
    if ( all {$filestream =~ m/$_/saa} @regexes ) {
        say "$binaryfile identified as $name with PUID $puid (regex quality $quality)";
    }
}
;

__END__

=pod

=encoding UTF-8

=head1 NAME

pronomidentify.pl

=head1 VERSION

version 0.04

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
