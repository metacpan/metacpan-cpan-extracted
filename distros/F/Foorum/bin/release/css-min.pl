#!/usr/bin/perl -w

use strict;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use CSS::Minifier qw(minify);
use File::Next;
use File::Basename;
use File::Path;
use File::Spec;

my $path = abs_path(
    File::Spec->catdir( $RealBin, '..', '..', 'root', 'static', 'css' ) );

my $files = File::Next::files($path);

while ( defined( my $file = $files->() ) ) {
    next if ( $file !~ /\.css$/ );
    next if ( $file =~ /(\/|\\)min(\/|\\)/ );                # skip /css/min
    next if ( $file =~ /(\/|\\)css(\/|\\)style(\/|\\)/ );    # skip /css/style

    my $in_file  = $file;
    my $out_file = $in_file;
    $out_file =~ s/(\/|\\)css(\/|\\)/\/css\/min\//is;

    my $out_dir = dirname($out_file);
    unless ( -d $out_dir ) {
        mkpath( [$out_dir], 0, 0777 );    ## no critic (ProhibitLeadingZeros)
    }

    eval { minify_css( $in_file, $out_file ); };

    if ($@) {
        print "$in_file fails\n";
    } else {
        print "$in_file > $out_file\n";
    }
}

sub minify_css {
    my ( $in_file, $out_file ) = @_;

    open( my $infh,  '<', $in_file )  or die $!;
    open( my $outfh, '>', $out_file ) or die $!;
    minify( input => $infh, outfile => $outfh );
    close($infh);
    close($outfh);
}

1;
