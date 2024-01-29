#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use Encode qw( encode from_to );
use File::LoadLines;

# Reference data.
my @data = ( "{title: Swing Low Sweet Chariot}", "{subtitle: Sub Títlë}" );

mkdir("out") unless -d "out";

# Recode to UTF-8.
my $data = join("\n", @data) . "\n";
$data = encode("UTF-8", $data);

my @BOMs = qw( UTF-8 UTF-16BE UTF-16LE UTF-32BE UTF-32LE );
my @noBOMs = qw( ISO-8859-1 UTF-8 );

my %enc2bom = map { $_ => encode($_, "\x{feff}") } @BOMs;

enctest( $_, 1 ) for @noBOMs;
enctest($_) for @BOMs;

done_testing( 4 * 3 * (@noBOMs + @BOMs) );

sub enctest {
    my ( $enc, $nobom ) = @_;
    my $encoded = $data;
    _enctest( $encoded, $enc, $nobom );
    $encoded = $data;
    $encoded =~ s/\n/\x0a/g;
    _enctest( $encoded, $enc, $nobom, "LF" );
    $encoded = $data;
    $encoded =~ s/\n/\x0d/g;
    _enctest( $encoded, $enc, $nobom, "CR" );
    $encoded = $data;
    $encoded =~ s/\n/\x0d\x0a/g;
    _enctest( $encoded, $enc, $nobom, "CRLF" );
}

sub _enctest {
    my ( $encoded, $enc, $nobom, $crlf ) = @_;
    from_to( $encoded, "UTF-8", $enc );
    unless ( $nobom ) {
	BAIL_OUT("Unknown encoding: $enc") unless $enc2bom{$enc};
	$encoded = $enc2bom{$enc} . $encoded;
    }

    my $fn = "out/$enc.cho";
    open( my $fh, ">:raw", $fn ) or die("$fn: $!\n");
    print $fh $encoded;
    close($fh);
    $enc .= " (no BOM)" if $nobom;
    $enc .= " ($crlf)" if $crlf;

    my $opts = { fail => "soft" };
    my @d = loadlines( $fn, $opts );
    diag("$fn: " . $opts->{error} ) unless @d;
    ok( scalar( @d ) == 2, "$enc: Two lines" );
    is( $d[0], $data[0], "$enc: Line 1" );
    is( $d[1], $data[1], "$enc: Line 2" );

    unlink($fn);
}
