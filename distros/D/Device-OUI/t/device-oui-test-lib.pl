#!/usr/bin/env perl
# Device::OUI Copyright 2008 Jason Kohles
# $Id: device-oui-test-lib.pl 5 2008-01-30 02:41:44Z jason $
use strict;
use warnings;
use FindBin qw( $Bin );
use Test::More;
use Test::Exception;
use File::Copy;
BEGIN {
    eval "use Device::OUI";
    if ( $@ ) {
      plan skip_all => "Couldn't load Device::OUI, no sense trying to test it";
      exit;
    }
}
# This is to make sure that we don't accidentally affect system-wide cache
# files while running the tests
Device::OUI->cache_file( undef );
Device::OUI->cache_db( undef );

# Some test entries...
# Apple     : 00-17-F2 00-19-E3
# VMware    : 00-50-56
# Parallels : 00-1C-42
sub samples { (
  {
    oui => "00-17-F2",
    company_id => "0017F2",
    organization => "Apple Computer",
    address => "1 Infinite Loop MS:35GPO\nCupertino CA 95014\nUNITED STATES",
  },
  {
    oui => "00-19-E3",
    company_id => "0019E3",
    organization => "Apple Computers",
    address => "1 Infinite Loop\nCupertino California 94538\nUNITED STATES",
  },
  {
    oui => "00-1C-42",
    company_id => "001C42",
    organization => "Parallels, Inc.",
    address => "660 SW 39h Street\nSuite 205\nRenton WA 98057\nUNITED STATES",
  },
  {
    oui => "00-50-56",
    company_id => "005056",
    organization => "VMWare, Inc.",
    address => "44 ENCINA AVENUE\nPALO ALTO CA 94301\nUNITED STATES",
  },
  {
    oui => "AC-DE-48",
    company_id => "ACDE48",
    organization => "PRIVATE",
    _private    => 1,
  },
) }

sub mutate_oui {
    my $oui = shift;
    my @parts = split( '-', $oui );
    my @short = @parts; s/^0// for @short;

    my %temp = ( lc( $oui ) => 1 );
    $temp{ $_ } = 1 for (
        map { ( uc( $_ ), lc( $_ ) ) } (
            ( map { join( $_, @parts ) } ( q{ }, q{}, split( //, '-:,' ) ) ),
            ( map { join( $_, @short ) } ( q{ }, split( //, '-:,' ) ) ),
        ),
    );
    return keys %temp;
}

sub files_same {
    my $src = IO::File->new( shift ) || return 0;
    my $dst = IO::File->new( shift ) || return 0;
    my @src = $src->getlines;
    my @dst = $dst->getlines;
    if ( @src != @dst ) { return 0 }
    while ( @src || @dst ) {
        if ( shift( @src ) ne shift( @dst ) ) { return 0 }
    }
    return 1;
}

sub files_match {
    my ( $srcfile, $dstfile, $msg ) = @_;
    my $same = files_same( $srcfile, $dstfile );
    s{^$Bin/*}{} for ( $srcfile, $dstfile );
    ok( $same => $msg || "$srcfile matches $dstfile" );
}

sub files_dont_match {
    my ( $srcfile, $dstfile, $msg ) = @_;
    my $same = files_same( $srcfile, $dstfile );
    s{^$Bin/*}{} for ( $srcfile, $dstfile );
    ok( ! $same => $msg || "$srcfile matches $dstfile" );
}

sub rm {
    for my $f ( map { glob } @_ ) {
        if ( not -f $f ) { next }
        1 while unlink( $f );
    }
}

sub slurp {
    local $/;
    open( my $fh, $_[0] ) or die "Can't open $_[0]: $!";
    return <$fh>;
}

my %oui_entries = (
    '00-17-F2'  => join( "\n",
        "00-17-F2   (hex)\t\tApple Computer",
        "0017F2     (base 16)\t\tApple Computer",
        "\t\t\t\t1 Infinite Loop MS:35GPO",
        "\t\t\t\tCupertino CA 95014",
        "\t\t\t\tUNITED STATES",
    ),

    '00-19-E3'  => join( "\n",
        "00-19-E3   (hex)\t\tApple Computers",
        "0019E3     (base 16)\t\tApple Computers",
        "\t\t\t\t1 Infinite Loop",
        "\t\t\t\tCupertino California 94538",
        "\t\t\t\tUNITED STATES",
    ),

    '00-1C-42'  => join( "\n",
        "00-1C-42   (hex)\t\tParallels, Inc.",
        "001C42     (base 16)\t\tParallels, Inc.",
        "\t\t\t\t660 SW 39h Street",
        "\t\t\t\tSuite 205",
        "\t\t\t\tRenton WA 98057",
        "\t\t\t\tUNITED STATES",
    ),

    '00-50-56'  => join( "\n",
        "00-50-56   (hex)\t\tVMWare, Inc.",
        "005056     (base 16)\t\tVMWare, Inc.",
        "\t\t\t\t44 ENCINA AVENUE",
        "\t\t\t\tPALO ALTO CA 94301",
        "\t\t\t\tUNITED STATES",
    ),

    'AC-DE-48'  => join( "\n",
        "AC-DE-48   (hex)\t\tPRIVATE",
        "ACDE48     (base 16)\t\t",
        "\t\t\t\t",
    ),

    'FF-FF-FF'  => join( "\n",
        "FF-FF-FF   (hex)\t\tDevice::OUI Fake Test Entry",
        "FFFFFF     (base 16)\t\tDevice::OUI Fake Test Entry",
        "\t\t\t\tThis isn't a real entry.",
        "\t\t\t\tIt just confirms that the test environment was",
        "\t\t\t\tsuccessful in setting up a fake LWP::Simple get",
        "\t\t\t\tmethod so that testing can be done offline",
    ),

);

sub oui_entry_for {
    my $oui = shift;
    return $oui_entries{ $oui };
}

rm( "$Bin/test-*" );

1;
