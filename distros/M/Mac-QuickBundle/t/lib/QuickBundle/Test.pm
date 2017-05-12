package t::lib::QuickBundle::Test;

use strict;
use warnings;

use Mac::QuickBundle;
use Config::IniFiles;
use File::Path qw();
use Test::More qw();

our @EXPORT = ( qw(create_bundle), @Test::More::EXPORT );

sub import {
    shift;

    strict->import;
    Test::More->import( @_ );
    Exporter::export( __PACKAGE__, scalar caller );
}

sub create_bundle {
    my( $config, $bundle ) = @_;

    File::Path::mkpath( 't/outdir' );
    File::Path::rmtree( "t/outdir/$bundle.app" );
    open my $ini, '<', \$config;
    Mac::QuickBundle::build_application
        ( Config::IniFiles->new( -file => $ini ), 't/outdir' );
    die "Did not create bundle '$bundle'" unless -d "t/outdir/$bundle.app";
}

1;
