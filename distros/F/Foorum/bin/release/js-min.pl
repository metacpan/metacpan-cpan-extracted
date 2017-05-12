#!/usr/bin/perl -w

use strict;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use JavaScript::Minifier qw(minify);
use File::Next;
use File::Basename;
use File::Path;
use File::Spec;

my $path = abs_path(
    File::Spec->catdir( $RealBin, '..', '..', 'root', 'static' ) );

my $files = File::Next::files($path);

while ( defined( my $file = $files->() ) ) {
    next if ( $file !~ /\.js$/ );
    next if ( $file =~ /(\/|\\)min(\/|\\)/ );    # skip /js/min

    my $in_file  = $file;
    my $out_file = $in_file;
    $out_file =~ s/(\/|\\)js(\/|\\)/\/js\/min\//is;

    my $out_dir = dirname($out_file);
    unless ( -d $out_dir ) {
        mkpath( [$out_dir], 0, 0777 );    ## no critic (ProhibitLeadingZeros)
    }

    eval { minify_js( $in_file, $out_file ); };

    if ($@) {
        print "$in_file fails\n";
    } else {
        print "$in_file > $out_file\n";
    }
}

sub minify_js {
    my ( $in_file, $out_file ) = @_;

    open( my $infh,  '<', $in_file )  or die $!;
    open( my $outfh, '>', $out_file ) or die $!;
    minify( input => $infh, outfile => $outfh );
    close($infh);
    close($outfh);
}

1;
