#!/usr/bin/perl -w

use strict;
use warnings;

use CDB_File;
use LWP::Simple;
use Getopt::Long;
use Archive::Lha::Stream;
use Archive::Lha::Header;
use Archive::Lha::Decode;
use Carp;
use File::Spec;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::FmtJapan2;
use Encode;
use File::Path;

my $lzhurl = 'http://www.nttdocomo.co.jp/binary/archive/service/imode/make/content/iarea/iareadata.lzh';
my $tmpdir = "./";
my $file   = "./iarea.cdb";
my $result = GetOptions ("tmpdir=s" => \$tmpdir,    # string
                         "file=s"   => \$file);     # string

my $lzhfil = $tmpdir.'iareadata.lzh';

# Fetch LZH file

my $lzh = get($lzhurl);

open my $fh, '>:raw', $lzhfil;
binmode $fh;
print   $fh  $lzh;
close   $fh;

# Extract LZH

my $stream = Archive::Lha::Stream->new(file => $lzhfil);
my $extdir;
my $listxls;
while(defined(my $level = $stream->search_header)) {
    my $header = Archive::Lha::Header->new(level => $level, stream => $stream);
    $stream->seek($header->data_top);

    my @file     = split( /\\/, $header->pathname );
    my $filename = $tmpdir;
    for ( my $i = 0; $i <= $#file; $i++ ) {
        $filename = File::Spec->catfile( $filename, $file[$i] );
        mkdir $filename unless ( $i == $#file || -e $filename );
        $extdir = $filename if ( !$extdir && $i == $#file - 1 );
    }

    $listxls = $filename if ( $filename =~ /areatable.+xls$/ );

    open my $fh, '>:raw', $filename;
    binmode $fh;
    my $decoder = Archive::Lha::Decode->new(
        header => $header,
        read   => sub { $stream->read(@_) },
        write  => sub { print $fh @_ }, 
    );
    my $crc16 = $decoder->decode;
    croak "crc mismatch" if $crc16 != $header->crc16;
}

# Parse area list excel file 

my $xls = Spreadsheet::ParseExcel->new();
my $fmt = Spreadsheet::ParseExcel::FmtJapan->new(Code => 'CP932');
my $ws  = $xls->Parse( $listxls, $fmt )->{Worksheet}[0];

my %areas = ();

foreach my $row ($ws->{MinRow} .. $ws->{MaxRow}) {
    my $oid = $ws->{Cells}[$row][0];
    next if ( !$oid->{Val} || $oid->{Val} !~ /^\d+$/ );

    my ( $region, $pref, $code, $subcode, $area ) = 
        map { my $v = Encode::decode('sjis',$_->Value); $v =~ s/^\s*(\S+)\s*$/$1/; $v } @{$ws->{Cells}[$row]}[1..5];

    $code .= $subcode;

    $areas{$code} = {
        name   => $area,
        region => $region,
        pref   => $pref,
    };
}

# Create CDB file

my $tmpcdb = $tmpdir . "iarea.tmp";
my $cdb = new CDB_File ($file, $tmpcdb) or die "Create failed: $!\n";

# Parse each area text file

foreach my $code ( sort keys %areas ) {
    open my $fl, "<", "$extdir/iarea$code\.txt";
    my $line = <$fl>;
    my $data = $areas{$code};

    my ($minlng,$minlat,$maxlng,$maxlat,$meshes) = 
      $line =~ /\d{3},\d{2},[^,]+,(\d+),(\d+),(\d+),(\d+),(?:\d+,){7}([\d,]+)$/;

    ($minlng,$minlat,$maxlng,$maxlat) = map { sprintf('%.6f',$_ / 3600000) } ($minlng,$minlat,$maxlng,$maxlat);

    $cdb->insert( $code, sprintf( '%s,%s,%s,%s,%s,%s,%s,%s,', 
      ( $code, $data->{name}, $data->{region}, $data->{pref}, $minlat, $minlng, $maxlat, $maxlng ) ) ); 
   
    my @meshes = split( /,/, $meshes );
    foreach my $mesh ( @meshes ) {
        next unless ( $mesh );
        $cdb->insert( $mesh, $code );
    }   

    close $fl;
}

$cdb->finish;

# Finish all

rmtree $extdir;
unlink $lzhfil;

__END__



