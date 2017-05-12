#!/usr/bin/perl -w

use strict;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use Acme::PlayCode;
use File::Next;
use File::Spec;

my $path = abs_path( File::Spec->catdir( $RealBin, '..', '..' ) );

my $files = File::Next::files($path);
my $app   = new Acme::PlayCode;
$app->load_plugin('Averything');

while ( defined( my $file = $files->() ) ) {
    next if ( $file !~ /\.(p[ml]|t)$/ );    # only .pm .pl .t

    print "$file\n";

    $app->play( $file, { rewrite_file => 1 } );
}

1;
