package Enbld::Module::Perl;

use strict;
use warnings;

use parent qw/Enbld::Module/;

use FindBin qw/$Bin/;

use File::Spec;

require Enbld::Home;
require Enbld::Feature;
require Enbld::Error;

sub initialize {
    my $self = shift;

    # install cpanm
    my $cpan = File::Spec->catfile( $self->{path}, 'bin', 'cpan' );
    $self->{installer} = File::Spec->catfile( $self->{path}, 'bin', 'cpanm' );

    require Enbld::Logger;
    my $logfile = Enbld::Logger->logfile;

    system( "$cpan App::cpanminus >> $logfile 2>&1" );

    if ( $? >> 8 ) {
        Enbld::Error->throw( "Can't install cpanm" );
    }

    # fullpath
    my $path;
    if ( File::Spec->file_name_is_absolute( $self->{module_file} ) ) {
        $path = $self->{module_file};
    } else {
        $path = File::Spec->catfile( $Bin, $self->{module_file} );
    }

    if ( ! -e $path ) {
        Enbld::Error->throw( "Can't find cpanfile:$path" );
    }

    $self->{module_file_fullpath} = $path;
}

sub install_command {
    my $self = shift;

    my $cmd = $self->{installer} . ' --cpanfile !file! --installdeps .';
    $cmd =~ s/!file!/$self->{module_file_fullpath}/;

    return $cmd;
}

1;
