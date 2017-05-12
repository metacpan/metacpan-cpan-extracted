#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use YAML;
use FindBin;

# how to make 103-111-HTML_2.0.0.txt
# 1. get PDF from http://www2.developers.softbankmobile.co.jp/dp/tool_dl/download.php?docid=120&companyid=
# 2. xdoc2txt -n 103-111-HTML_2.0.0.pdf > 103-111-HTML_2.0.0.txt
#  ref. http://www31.ocn.ne.jp/~h_ishida/xdoc2txt.html

my $pdf_text_file = shift or die "Usage: softbank-scrape-autosjis.pl 103-111-HTML_2.0.0.txt";
my $pdf_fh =file($pdf_text_file)->openr;

my %map;
while (my $line = <$pdf_fh>) {
    chomp $line;
    next if $line !~ /^&#\d\d\d\d\d;\s*&#x/;

    my @codes = split /\s+/, $line;
    next if @codes != 4;

    my $unicode  = strip_entity_ref_mark($codes[1]);
    my $shiftjis = $codes[3];

    $map{ $unicode } = $shiftjis;
}
close $pdf_fh;

print Dump(\%map);


sub strip_entity_ref_mark {
    local $_ = shift;
    s/(^&#x|;$)//g;
    $_;
}

