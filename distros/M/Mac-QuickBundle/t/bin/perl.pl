#!/usr/bin/perl -w

print STDERR "# $^X\n";
# return value must be true
not system( $^X, "$PerlWrapper::ResourcesPath/Perl-Source/basic.pl");
