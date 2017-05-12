package Enbld::HTTP;

use strict;
use warnings;

use File::Spec;
use Carp;

use HTTP::Tiny;

our $ua;
our $download_hook;
our $get_hook;

require Enbld::Message;
require Enbld::Error;
require Enbld::Exception;

sub initialize_ua {
    $ua = HTTP::Tiny->new;
}

sub download {
    my ( $pkg, $url, $path ) = @_;

    my ( undef, undef, $file ) = File::Spec->splitpath( $path );

    if ( -e $path ) {
        my $msg = "--> Use file '$file' that is previously downloaded.";
        Enbld::Message->notify( $msg );
        return $path;
    }

    # for debug hook
    if ( $download_hook ) {
        $download_hook->( $pkg, $url, $path );
        return $path;
    }

    Enbld::Message->notify( "--> Download '$file' from '$url'." );

    my $curl = `which curl`;
    chomp $curl;
    if ( $curl ) {
        system("$curl -L $url -o $path -s");
    } else {
        initialize_ua() unless $ua;
        my $res = $ua->mirror( $url, $path );

        if ( ! $res->{success} ) {
            Enbld::Error->throw( $res->{reason} );
        }
    }

    return $path;
}

sub download_archivefile {
    my ( $pkg, $url, $path ) = @_;

    my $downloaded = Enbld::HTTP->download( $url, $path );

    require Enbld::Archivefile;
    return Enbld::Archivefile->new( $downloaded );
}

sub get {
    my ( $pkg, $url ) = @_;

    if ( $get_hook ) {
        return $get_hook->( $pkg, $url );
    }

    initialize_ua() unless $ua;
    my $res = $ua->get( $url );

    if ( ! $res->{success} ) {
        Enbld::Error->throw( $res->{reason} );
    }

    return $res->{content};
}

sub get_html {
    my ( $pkg, $url ) = @_;

    my $content = Enbld::HTTP->get( $url );

    require Enbld::HTML;
    return Enbld::HTML->new( $content );
}

# For debug methods.

sub register_get_hook {
    my ( $pkg, $coderef ) = @_;

    if ( ref( $coderef ) eq 'CODE' ) {
        $get_hook = $coderef;
        return $pkg;
    }

    my $err = "register get hook requires CODE reference parameter.";
    require Enbld::Exception;
    Enbld::Exception->throw( $err, $coderef );
}

sub register_download_hook {
    my ( $pkg, $coderef ) = @_;

    if ( ref( $coderef ) eq 'CODE' ) {
        $download_hook = $coderef;
        return $pkg;
    }

    my $err = "register download hook requires CODE reference parameter.";
    require Enbld::Exception;
    Enbld::Exception->throw( $err, $coderef );
}

1;
