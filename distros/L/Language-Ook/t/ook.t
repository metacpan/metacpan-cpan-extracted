#!perl
#
# This file is part of Language::Ook.
# Copyright (c) 2002-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use File::Spec::Functions;
use Language::Ook;
use POSIX qw! tmpnam !;
use Test;
BEGIN { plan tests => 2 };

#

# Classic hello world.
my %tests = ( "hello.ook" =>  "Hello, world!\n",
              "test.ook"  =>  "1..1\nok 1\n",
            );
for my $f ( sort keys %tests ) {
    my $file = tmpnam();
    open OUT, ">$file" or die $!;
    my $fh = select OUT;
    my $interp = new Language::Ook;
    $interp->read_file( catfile( "examples", $f ) );
    $interp->run_code;
    select $fh;
    close OUT;
    open OUT, "<$file" or die $!;
    my $content;
    {
        local $/;
        $content = <OUT>;
    }
    close OUT;
    unlink $file;
    ok( $content, $tests{$f} );
}
