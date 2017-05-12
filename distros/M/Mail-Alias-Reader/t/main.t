# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Mail::Alias::Reader ();

use File::Temp qw(mkstemp);

use Test::More ( 'tests' => 8 );
use Test::Exception;

throws_ok {
    Mail::Alias::Reader->open(
        'mode' => 'foo',
        'file' => 'bar'
    );
}
qr/Unknown parsing mode/, 'Mail::Alias::Reader->open() fails when passed unknown mode';

throws_ok {
    Mail::Alias::Reader->open(
        'mode' => 'aliases',
        'file' => '/dev/null/this/file/cannot/possibly/exist'
    );
}
qr/Unable to open aliases file/, 'Mail::Alias::Reader->open() fails when file open() fails';

throws_ok {
    Mail::Alias::Reader->open( 'mode' => 'aliases' );
}
qr/No file or file handle specified/, 'Mail::Alias::Reader->open() fails when no file or file handle is passed';

lives_ok {
    open( my $fh, '<', '/dev/null' ) or die("Cannot open /dev/null: $!");

    Mail::Alias::Reader->open( 'handle' => $fh )->close;
}
'Mail::Alias::Reader->open() defaults to a mode of "aliases"';

{
    my %TESTS = (
        'foo'  => 'bar baz',
        'name' => '"|destination meow"',
        'this' => 'should@work.mil'
    );

    my ( $fh, $file ) = mkstemp('/tmp/.mail-alias-parser-test-XXXXXX') or die("Cannot create temporary file: $!");

    print {$fh} "          \n";                                                                 # Throw in a line of whitespace to attempt to trip up the parser
    print {$fh} "# This entire line is a comment and shouldn't show up in \%aliases below\n";

    foreach my $alias ( sort keys %TESTS ) {
        print {$fh} "$alias: $TESTS{$alias}\n";
    }

    close $fh;

    my $reader = Mail::Alias::Reader->open(
        'mode' => 'aliases',
        'file' => $file
    );

    my %aliases;

    while ( my ( $name, $destinations ) = $reader->read ) {
        $aliases{$name} = $destinations;
    }

    $reader->close;
    unlink($file);

    ok( keys %aliases == keys %TESTS, 'Mail::Alias::Reader->read() returns the correct number of results' );

    foreach my $test ( keys %TESTS ) {
        ok( exists $aliases{$test}, qq{Mail::Alias::Reader->read() found an alias for "$test"} );
    }
}
