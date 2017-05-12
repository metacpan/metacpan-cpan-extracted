#!/usr/local/bin/perl -w

use strict ;
use Test::More ;
use File::Slurp ;

plan skip_all => "meaningless on Win32" if $^O =~ /win32/i ;
plan tests => 2 ;

my $file = "perms.$$" ;

my $text = <<END ;
This is a bit of contents
to store in a file.
END

umask 027 ;

write_file( $file, $text ) ;
is( getmode( $file ), 0640, 'default perms works' ) ;
unlink $file ;

write_file( $file, { perms => 0777 }, $text ) ;
is( getmode( $file ), 0750, 'set perms works' ) ;
unlink $file ;

exit ;

sub getmode {
	return 07777 & (stat $_[0])[2] ;
}
