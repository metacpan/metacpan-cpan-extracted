package Enbld::RcFile;

use strict;
use warnings;

use autodie;
use File::Spec;
use File::Path qw/make_path/;
use File::Temp;
use File::Copy;

use Digest::file qw/digest_file_hex/;
use Digest::SHA  qw/sha1_hex/;

use Carp;

require Enbld::Message;
require Enbld::Error;
require Enbld::Exception;

our @cmd_list = qw/load copy set/;

sub new {
    my $class = shift;

    my $self = {
        command     =>  undef,
        filepath    =>  undef,

        from        =>  undef,

        source      =>  undef,
        url         =>  undef,

        contents    =>  undef,

        directory   =>  undef,

        fullpath    =>  undef,
        filename    =>  undef,

        digest      =>  undef,

        @_,
    };

    bless $self, $class;

    $self->_parse_filepath;
    $self->_validate;

    return $self;
}

sub do {
    my $self = shift;

    if ( $self->{command} eq 'load' && $self->{from} ) {
        $self->{url} = $self->{from};
    }

    if ( $self->{command} eq 'copy' && $self->{from} ) {
        $self->{source} = $self->{from};
    }

    my $cmd    = 'do_' . $self->{command};
    my $result = $self->$cmd;

    return $result;
}

sub _validate {
    my $self = shift;

    _err( "Configuration file's command is not specified." ) unless $self->{command};

    if ( ! grep { $_ eq $self->{command} } @cmd_list ) {
        _err( "'$self->{command}' is invalid command type." );
    }

    _err( "Configuration file's path not set." )     unless $self->{filepath};

    unless ( -d $self->{directory} ) {
		make_path( $self->{directory} );
	}
}

sub _parse_filepath {
    my $self = shift;

    $self->{directory} = $ENV{HOME} unless $self->{directory};

    $self->{fullpath} = File::Spec->file_name_is_absolute( $self->{filepath} ) ?
        $self->{filepath} :
        File::Spec->catfile( $self->{directory}, $self->{filepath} );

    my $dirs;
    ( undef, $dirs, $self->{filename} ) = File::Spec->splitpath( $self->{fullpath} );

    if ( ! _check_permission( $dirs )) {
        _err( "Please check write permission for $dirs." );
    }

    if ( -f $self->{fullpath} ) {
        $self->{digest} = digest_file_hex( $self->{fullpath}, 'SHA-1' );
    }

    return $self->{fullpath};
}

sub _check_permission {
    my $dir = shift;

    my @list = File::Spec->splitdir( $dir );

    while( @list ) {
        my $path = File::Spec->catdir( @list );

        return $path if ( -d -w $path );

        pop @list;
    }

    return;
}

sub do_load {
    my $self = shift;

    _err( "Download URL is not set." ) unless $self->{url};

    _notify( "=====> Load configuration file '$self->{filename}' from '$self->{url}'." );

    require Enbld::HTTP;
    my $temp  = File::Temp->newdir;
    my $path  = File::Spec->catfile( $temp, $self->{filename} );
    my $downloaded = Enbld::HTTP->download( $self->{url}, $path );
    
    unless ( -f -T $downloaded )  {
       _err( "Configuration file '$self->{filename}' isn't text file." ); 
    }

    if ( $self->{contents} ) {
        open my $temphandle, '>>', $downloaded;
        print $temphandle $self->{contents};
        close $temphandle;
    }

    if ( $self->{digest} ) {
        my $digest = digest_file_hex( $path, 'SHA-1' );

        if ( $self->{digest} eq $digest ) {
            _notify( "Configuration file not have the necessity for change." );
            return;
        }

        my ( undef, $dir, $filename ) = File::Spec->splitpath( $self->{fullpath} );

        move( $self->{fullpath}, File::Spec->catfile( $dir, $filename . time ) )
            or _err( $! );
    }

    copy( $path, $self->{fullpath} ) or _err( $! );

    _notify( "=====> Finish configuration file '$self->{filename}'" );

    return $self->{filename};
}

sub do_set {
    my $self = shift;

    _err( "Configuration file's contents isn't set." ) unless $self->{contents};

    _notify( "=====> Set configuration file '$self->{filename}'" );

    my ( undef, $dir, $filename ) = File::Spec->splitpath( $self->{fullpath} );

    if ( $self->{digest} ) {
        if ( $self->{digest} eq sha1_hex( $self->{contents}) ) {
            _notify( "Configuration file not have the necessity for change." );
            return;
        };

        move( $self->{fullpath}, File::Spec->catfile( $dir, $filename . time ))
            or _err( $! );
    }

    make_path( $dir );

    open my $fh, '>', $self->{fullpath};
    print $fh $self->{contents};
    close $fh;

    _notify( "=====> Finish configuration file '$self->{filename}'" );

    return $self->{filename};
}

sub do_copy {
    my $self = shift;

    _err( "Configuration file's source path is not set." ) unless $self->{source};

    unless ( -f -T $self->{source} ) {
        _err( "Configuration file '$self->{filename}' isn't text file." ); 
    }

    _notify( "=====> Copy configuration file '$self->{filename}'" );

    my $temp = File::Temp->newdir;
    my $path = File::Spec->catfile( $temp, $self->{filename} );
    copy( $self->{source}, $path );

    if ( $self->{contents} ) {
        open my $temphandle, '>>', $path;
        print $temphandle $self->{contents};
        close $temphandle;
    }

    if ( $self->{digest} ) {
        my ( undef, $dir, $filename ) = File::Spec->splitpath( $self->{fullpath} );

        my $digest = digest_file_hex( $path, 'SHA-1' );

        if ( $self->{digest} eq $digest ) {
            _notify( "Configuration file not have the necessity for change." );
            return;
        }
        move( $self->{fullpath}, File::Spec->catfile( $dir, $filename . time ) )
            or _err( $! );
    }

    copy( $path, $self->{fullpath} ) or _err( $! );

    _notify( "=====> Finish configuration file '$self->{filename}'" );

    return $self->{filename};
}

sub filename {
    my $self = shift;

    return $self->{filename};
}

sub filepath {
    my $self = shift;

    return $self->{filepath};
}

sub serialize {
    my $self = shift;

    my $serialized;

    $serialized->{filepath}  = $self->{filepath};
    $serialized->{command}   = $self->{command};

    $serialized->{contents}  = $self->{contents} if $self->{contents};
    $serialized->{url}       = $self->{url}      if $self->{url};
    $serialized->{source}    = $self->{source}   if $self->{source}; 

    if ( $self->{directory} ne $ENV{HOME} ) {
        $serialized->{directory} = $self->{directory};
    }

    return $serialized;
}

sub DSL {
    my $self = shift;

    my @rcfile;

    my $str = "conf '" . $self->{filepath} . "' => " . $self->{command} . " {\n";

    push @rcfile, $str;

    if ( $self->{command} eq 'load' ) {
        push @rcfile, '    ' . "from '" . $self->{url} . "';\n";
    }

    if ( $self->{command} eq 'copy' ) {
        push @rcfile, '    ' . "from '" . $self->{source} . "';\n";
    }

    if ( $self->{directory} ne $ENV{HOME} ) {
        push @rcfile, '    ' . "to '" . $self->{directory} . "';\n";
    }

    if ( $self->{contents} ) {
        my @contents = split( "\n", $self->{contents} ); 

        foreach my $line ( @contents ) {
            push @rcfile, '    ' . "content '" . $line . "';\n";
        }
    }

    push @rcfile, "};\n";

    return \@rcfile;
}

sub _err {
    my $err = shift;
    my $param = shift;

    die( Enbld::Error->new( $err, $param ));
}

sub _exception {
    my $exception = shift;
    my $param = shift;

    croak( Enbld::Exception->new( $exception, $param ));
}

sub _notify {
    my $msg = shift;

    Enbld::Message->notify( $msg );
}

1;
