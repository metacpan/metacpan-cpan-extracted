#!/usr/bin/perl

use strict;
use warnings;
use Encode 1.41;
use File::Spec;
use File::Basename;

my $path = dirname($0);
conv(File::Spec->catdir($path, 'b2g_map.utf8') => 'trad-simp');
conv(File::Spec->catdir($path, 'g2b_map.utf8') => 'simp-trad');

sub conv {
    my ($src, $target) = @_;
    my %count;
    my @has;

    open IN, '<:utf8', $src or die $!;
    open OUT, ">$target.ucm" or die $!;

    print OUT << ".";
# This is generated from $src -- please change that file instead.
# Yes, this .ucm map is not round-trip safe; HanConvert is a lossy operation.
<code_set_name> "$target"
.
    print OUT +HEADER();

    <IN>; <IN>;
    while (<IN>) {
        my ($fchar, $tchar) = m/^(.) (.)/;
        print OUT ucm_entry($fchar, $tchar);
        $has[ord $fchar] = 1;
    }
    close IN;

    open IN, File::Spec->catdir($path, 'DerivedAge.txt') or die $!;
    while(<IN>) {
        next if /<noncharacter/ || /<surrogate/;
        if (/^([0-9A-F]+)\s+;/) {
            $has[hex $1] || print OUT ucm_entry(chr hex $1, chr hex $1);
        } elsif(/^([0-9A-F]+)\.\.([0-9A-F]+)\s+;/) {
            $has[$_] || print OUT ucm_entry(chr $_, chr $_) for hex $1 .. hex $2;
        }
    }

    print OUT +FOOTER();

    close OUT;
}

sub ucm_entry {
    my ($fchar, $tchar) = @_;
    my $utf8 = encode_utf8($fchar);
    return sprintf("<U%04X> %s |%u\n",
        ord($tchar),
        join('', map sprintf('\\x%02X', ord($_)), split('', $utf8)),
        0);     # XXX - suggestions welcome to the fallback char here
}

use constant HEADER => << '.';
<mb_cur_min> 1
<mb_cur_max> 2
<subchar> \x3F
#
CHARMAP
.

use constant FOOTER => << '.';
END CHARMAP
.
