package Enbld::Logger;

use strict;
use warnings;

use autodie;
use File::Spec;

our $LOGFILE;

sub logfile {
    return $LOGFILE;
}

sub rotate {
    my ( $pkg, $path ) = @_;

    _create_logfile( $path );
    _create_symlink( $path );

    return $LOGFILE;
}

sub write {
    my ( $pkg, $msg ) = @_;

    open my $fh, '>>', $LOGFILE;
    print $fh $msg;
    close $fh;

    return $msg;
}

sub _create_logfile {
    my $path = shift;

    $LOGFILE = File::Spec->catfile( $path, time . '-' . $$ . '.log' );
    open my $fh, ">", $LOGFILE;
    close $fh;
}

sub _create_symlink {
    my $path = shift;

    my $link = File::Spec->catfile( $path, 'latest_build.log' );
    unlink $link if ( -e $link );
    symlink $LOGFILE, $link;
}

1;
