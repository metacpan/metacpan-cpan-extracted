#!/usr/bin/perl

use strict ;
use warnings ;
use File::Basename ;
use FreeMind::Convert ;

my $output ;

my $file    = shift || die "Usage : " . basename($0) . " <mmfile>\n" ;
my $mm = FreeMind::Convert->new ;
$mm->setOutputJcode('sjis') ;
$mm->loadFile($file) ;
$output = $mm->toMediaWiki() ;

print $output ;

if( $^O eq 'MSWin32' ){
    use Win32::Clipboard;
    Win32::Clipboard( $output ) ;
}

exit 0 ;
