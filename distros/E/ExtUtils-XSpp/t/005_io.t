#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';
use if -d 'blib' => 'blib';

use Test::More tests => 2;
use Test::Differences;
use ExtUtils::XSpp::Driver;

unlink $_ foreach 't/files/foo.h';

my $driver = ExtUtils::XSpp::Driver->new
  ( typemaps   => [ 't/files/typemap.xsp' ],
    file       => 't/files/test1.xsp',
    );

open my $fh, '>', \my $out;

{
    local *STDOUT = $fh;
    $driver->process;
}

sub slurp($) {
    open my $fh, '<', $_[0]
      or die "Could not open file '$_[0]' for reading: $!";
    return join '', <$fh>;
}

eq_or_diff( $out, <<EOT, 'Output on stdout' );
#include <exception>
#undef  xsp_constructor_class
#define xsp_constructor_class(c) (c)


MODULE=Foo::Bar::Baz
#include <foo.h>



MODULE=Foo::Bar::Baz PACKAGE=Foo::Bar::Baz::Buz

int
foo( int a, int b, int c )
  CODE:
    try {
      RETVAL = foo( a, b, c );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

EOT

eq_or_diff( slurp 't/files/foo.h', <<EOT, 'Output on external file' );
#include <exception>
#undef  xsp_constructor_class
#define xsp_constructor_class(c) (c)



/* header file */

int foo( int, int, int );


EOT
