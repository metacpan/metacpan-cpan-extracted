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
use Path::Tiny;

################################################################################
# main
################################################################################
my $pronomfile;
GetOptions (
    "signature=s" => \$pronomfile,
    "help" => sub {
        say "$0 --signature=droid_signature_filename <files or directory>";
        say "$0 --help ";
        say "";
        exit 1;
    }
) or croak "wrong option, try '$0 --help'";

if ( !defined $pronomfile ) {
    say "you need at least a pronom signature file";
    exit;
}
my @files;
if (scalar @ARGV > 1) {
      # assert all are files
    if (any {path($_)->is_dir} @ARGV) {
        say "you should use either files or one directory!";
        exit;
    } else {
        @files = @ARGV;
    }
} elsif (scalar @ARGV == 1) {
    my $path = path( $ARGV[0] );
    if ($path->is_dir) {
        @files = grep { $_->is_file() } $path->children;
    }
    if ($path->is_file) {
        push @files, $path;
    }
} else {
    say "you should use at least a file or directory!";
    exit;
}

my $pronom = File::FormatIdentification::Pronom->new(
    "droid_signature_filename" => $pronomfile
);



foreach my $binaryfile ( @files ) {
    map_file my $filestream, $binaryfile, "<";
    advise( $filestream, 'random' );
    say "checking $binaryfile";
    foreach my $internalid ( $pronom->get_all_internal_ids() ) {
        my @regexes = $pronom->get_regular_expressions_by_internal_id($internalid);
        if (all {$filestream =~ m/$_/saa} @regexes ) {
            my $sig = $pronom->get_signature_id_by_internal_id($internalid);
            if (!defined $sig) {next;}
            my $puid = $pronom->get_puid_by_signature_id($sig);
            my $name = $pronom->get_name_by_signature_id($sig);
            my $quality = $pronom->get_qualities_by_internal_id($internalid);
            say "\tidentified as $name with PUID $puid (regex quality $quality)";
            last;
        }
    }
}
;

__END__

=pod

=encoding UTF-8

=head1 NAME

pronomidentify.pl

=head1 VERSION

version 0.07

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
