package Enbld::Archivefile;

use strict;
use warnings;

use Archive::Tar;
use File::Spec;

sub new {
    my ( $class, $path ) = @_;

    my $self = {
        archivefile =>  $path,
    };

    return bless $self, $class;
}

require Enbld::Error;

sub extract {
    my ( $self, $dir ) = @_;

    my ( undef, undef, $file ) = File::Spec->splitpath( $self->{archivefile} );

    require Enbld::Message;
    Enbld::Message->notify( "--> Extract archive file '$file'." );

    my $tar = Archive::Tar->new;
    $tar->read( $self->{archivefile} ) or
        _err( "Can't read archive file.", $tar->error );

    my @list = $tar->list_files or _err( "Can't list up file.", $tar->error );

    my @frag = split( '/', $list[0] );

    my $path = File::Spec->catdir( $dir, $frag[0] );
    $tar->setcwd( $dir ) or _err( "Can't move to cwd dir.", $tar->error );
    $tar->extract or _err( "Can't extract archive file.", $tar->error );

    return $path;
}

sub _err {
    my ( $err, $msg ) = @_;

    require Enbld::Error;
    Enbld::Error->throw( $err, $msg );
}

1;
