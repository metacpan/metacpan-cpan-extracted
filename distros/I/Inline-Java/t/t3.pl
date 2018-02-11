use strict ;

use blib ;


require "Inline/Java.pm" ;
use Inline::Java::Array ;
use Data::Dumper ;

$Inline::Java::DEBUG = 1 ;


my $obj = {} ;
bless($obj, "Inline::Java::Object") ;

my $a = new Inline::Java::Array("[[[I") ;

my $ref = [
	[
		[1, 2, 3],
		[4, 5],
	],
	[
		[6, 7, 8],
		[9],
	],
] ;

$a->__init_from_array($ref) ;
my $flat = $a->__flatten_array() ;

my $b = new Inline::Java::Array("[[[I") ;
$b->__init_from_flat(@{$flat}) ;


my $aa = Dumper($a) ;
my $bb = Dumper($b) ;


if ($aa eq $bb){
	die("Happy man!") ;
}

