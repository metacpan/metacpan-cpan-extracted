#!/usr/bin/env perl

use Test::More tests => 5;
use File::Temp;

use strict;
use warnings;

use IO::EditPrompt;

{
    my $p = IO::EditPrompt->new();
    my ($tmp, $filename) = $p->_create_tmp_file( "# One line\n" );

    ok( -f $filename, "Temp file exists" );
    is( do { local $/; open my $fh, '<', $filename; <$fh> }, "# One line\n", '... contains prompt' );
}

{
    my $dir = File::Temp->newdir();
    my $p = IO::EditPrompt->new({ tmpdir => $dir });
    my ($tmp, $filename) = $p->_create_tmp_file( "# One line\n" );

    ok( -f $filename, "Temp file exists" );
    like( $filename, qr/^\Q$dir/, '... in supplied path.' );
    is( do { local $/; open my $fh, '<', $filename; <$fh> }, "# One line\n", '... contains prompt' );
}
