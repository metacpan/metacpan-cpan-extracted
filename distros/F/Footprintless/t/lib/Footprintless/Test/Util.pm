use strict;
use warnings;

package Footprintless::Test::Util;

use Carp;
use Cwd qw(abs_path);
use Exporter qw(import);
use File::Basename;
use File::Temp;
use Footprintless::Util qw(
    dynamic_module_new
);
use Log::Any;

our @EXPORT_OK = qw(
    command_runner
    copy_recursive
    is_empty_dir
    test_dir
);

my $logger = Log::Any->get_logger();

my $test_dir = abs_path( File::Spec->catfile( dirname(__FILE__), '..', '..', '..' ) );

sub command_runner {
    my ($name) = shift || 'IPCRun';
    return dynamic_module_new("Footprintless::CommandRunner::$name");
}

sub copy_recursive {
    my ( $from, $to ) = @_;
    $logger->infof( 'copy_recursive [%s]->[%s]', $from, $to );

    require File::Copy;
    if ( -f $from ) {
        $logger->tracef( 'copy [%s]->[%s]', $from, $to );
        File::Copy::copy( $from, $to );
    }
    elsif ( -d $from ) {
        croak('cannot copy directory to file') if ( -f $to );

        $from =~ s/\/?$/\//;
        my $from_base_length = length($from);

        require File::Find;
        require File::Path;
        require File::Spec;
        File::Find::find(
            sub {
                return if /^\.\.?$/;
                my $relative = substr( $File::Find::name, $from_base_length );
                my $destination = File::Spec->catfile( $to, $relative );
                if ( -d $File::Find::name ) {
                    $logger->tracef( 'make path [%s]', $destination );
                    File::Path::make_path($destination);
                }
                else {
                    $logger->tracef( 'copy [%s]->[%s]', $File::Find::name, $destination );
                    File::Copy::copy( $File::Find::name, $destination )
                        || croak("unable to copy file $relative: $!");
                }
            },
            $from
        );
    }
    else {
        croak("not a file or directory");
    }
}

sub is_empty_dir {
    my ($dir) = @_;
    opendir( my $handle, $dir ) or die "Not a directory";
    return scalar( grep { $_ ne "." && $_ ne ".." } readdir($handle) ) == 0;
}

sub test_dir {
    return File::Spec->catfile( $test_dir, @_ );
}

1;
