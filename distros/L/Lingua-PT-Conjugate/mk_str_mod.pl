#!/usr/bin/perl -w
## usage: mk_str_mod.pl module_name string_name < string_content
##
## Creates a file module_name.pm which defines a perl package called
## "module_name", which exports a single string $string_name, which
## contains all the data passed on STDIN.
##
$modname = shift ;		# Module name
$strname = shift ;		# String name

$modname =~ s/\.pm$//g ;	# No suffix, please

$whichp = `which perl` ;
$today = `date` ;

open AA, ">$modname.pm" or 
    die "mk_str_mod : Can't open $modname.pm" ;

$tmp = <<EOF
#!$whichp
# Created by $0 on $today
package Lingua::PT::$modname ;
use Exporter ;
\@ISA = qw(Exporter);
\@EXPORT = qw( \$$strname );
\$$strname = <<EOSTR\n
EOF
 ;
chomp( $tmp ) ;

print AA $tmp ;

while( !eof(STDIN) ){print AA <>}

print AA <<EOF
EOSTR
    ;
1 ;
EOF
    ;
close AA ;

