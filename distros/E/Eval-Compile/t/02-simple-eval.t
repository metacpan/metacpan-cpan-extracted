#!/usr/bin/perl -I/home/sites/combats.ru/slib
#===============================================================================
#
#         FILE:  t.pl
#
#        USAGE:  ./t.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  11/29/2010 02:27:09 PM
#     REVISION:  ---
#===============================================================================

use strict;
use ExtUtils::testlib;
use Eval::Compile qw(ceval);
use Test::More 'no_plan';

my $sub;
my @r;
sub short{
	Eval::Compile::cache_eval($_[0],  sub { print $_,"\n"; 2*$_[0] });
	#Eval::Compile::cache_this($_[0],  sub { print $_,"\n"; 2*$_[0] });
}
my $b = 45;
abc();
sub abc {
    for ( 1, 2, 3 ) {
        my $a = $_;
		my $result;
		my $eval_str= '11+$a+$b';
        $result =  Eval::Compile::cached_eval('11+$a+$b');
		is( $result, 11+$a+$b, "eval '$eval_str'  " );
		is( $a, $_, "\$_ == \$a ( $_ )" );
		is( $b, 45, "\$b == 45 " );

        #print "nok \n" unless $b;
        #print Dumper( $_, Eval::Compile::cache_eval( '1-') || $@ ) ;
        #print Dumper( $_, Eval::Compile::cache_eval( 'die ;'));
        #print Dumper( $a, $b );
        # Eval::Compile::cache_this($_, sub { print $_,"\n"; 2*$_[0] }));
    }
}
for ( 1, 2){
	my $result = ceval( '1-');
	is( $result, undef );
	ok($@, "\$@ set for $_ time ");
	# if all ok
	$result = ceval( '1' );
	is( $result, 1);
	ok( !$@);
}
$@='asdfkljdsfl';
for ( 1, 2){
	my $result = ceval( 'die "abc\n";' );
	is( $result, undef );
	is( $@, "abc\n" );
	# if all ok
	$result = ceval( '1' );
	is( $result, 1);
	ok( !$@);
}
