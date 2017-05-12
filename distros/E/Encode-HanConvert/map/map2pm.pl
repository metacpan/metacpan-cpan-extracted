#!/usr/bin/perl

use strict;
use File::Spec;
use File::Basename;

my $path = dirname($0);

open IN, File::Spec->catfile(
    $path, qw(.. lib Encode HanConvert Perl.pm-orig),
) or die $!;

open OUT, '>'. File::Spec->catfile(
    $path, qw(.. lib Encode HanConvert Perl.pm),
) or die $!;

while (<IN>) {
    print OUT $_;
    if (/### include (\S+)/) {
        my $file = $1;
        my $is_utf8 = ($file =~ /utf8/);
        open INC, File::Spec->catdir($path, $file) or die $!;
        <INC>; <INC>;
        while (<INC>) {
            chomp;
            $_ = substr($_, 0, ($is_utf8 ? 7 : 5)) . "\n";
            s/\\/\\\\\\/g;
            s/^/'/;
            s/ /', '/;
            s/$/',/;
            print OUT $_;
        }
        close INC;
    }
    elsif (/### perl (\S+) ###/) {
        print OUT "=begin comment\n" unless $] >= $1;
    }
    elsif (/### \/perl (\S+) ###/) {
        print OUT "=end comment\n=cut\n" unless $] >= $1;
    }
}

close OUT;
