package Enbld::Home;

use strict;
use warnings;

use Carp;
use File::Spec;
use File::Path qw/make_path remove_tree/;
use autodie;
use Time::Piece;
use Time::Seconds;

require Enbld::Feature;
require Enbld::Error;
require Enbld::Exception;

our $dirs = {
    home        =>  undef,
    dists       =>  undef,
    depository  =>  undef,
    build       =>  undef,
    conf        =>  undef,
    log         =>  undef,
    etc         =>  undef,
    extlib      =>  undef,
    library     =>  undef,
    deploy_path =>  undef,
};

sub initialize {
    my $pkg = shift;

    $pkg->_create_home_directory;
    $pkg->_set_deploy_directory if Enbld::Feature->is_deploy_mode;
	$pkg->_delete_old_build_directory;

    return $dirs->{home};
}

sub AUTOLOAD {
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;

    unless ( exists $dirs->{$method} ) {
        my $err = "Can't execute Enbld::Home's method.";
        Enbld::Exception->throw( $err, $method );
    }

    unless ( $dirs->{$method} ) {
        my $err = "Not initialized Enbld home's path yet.";
        Enbld::Exception->throw( $err );
    }

    return $dirs->{$method};
}

sub create_build_directory {

    make_path( $dirs->{build} = File::Spec->catdir(
                $dirs->{home}, 'build', time
                ));

    return $dirs->{build};
}

sub install_path {

    return Enbld::Home->deploy_path if Enbld::Feature->is_deploy_mode;
    return Enbld::Home->home;

}

sub _create_home_directory {
    my $pkg = shift;

    $dirs->{home} = $ENV{PERL_ENBLD_HOME} ? $ENV{PERL_ENBLD_HOME} :
        File::Spec->catdir( $ENV{HOME}, '.enbld' );

    my $error;
    make_path( $dirs->{home}, { error => \$error } );

    if ( @{ $error } ) {
        Enbld::Error->throw(
                    "Can't create Enbld's home directory:$dirs->{home}\n" .
                    "Please check write permission for $dirs->{home}",
                    );
    }

    if ( ! -w $dirs->{home} ) {
        Enbld::Error->throw(
                    "No permission to write directory:$dirs->{home}" .
                    "Please check write permission for $dirs->{home}"
                    );
    }

    make_path( $dirs->{$_} = File::Spec->catdir( $dirs->{home}, $_ )) for
        qw/dists build depository conf etc log extlib/;

    $dirs->{library} = $dirs->{home};

    return $dirs->{home};
}

sub _set_deploy_directory {

    my $deploy_path = Enbld::Feature->deploy_path;

    $dirs->{deploy_path}    = $deploy_path;
    $dirs->{library}        = $deploy_path;

    return $dirs->{deploy_path};
}

sub _delete_old_build_directory {

	opendir my $dh, $dirs->{build};
	my @list = grep { !/^\.{1,2}$/ } readdir $dh;
	closedir $dh;

	my $limit = localtime;
	$limit -= ONE_MONTH;

	foreach my $build_dir ( @list ) {
        next if ( $build_dir !~ /\d{10}/ ); # for skip .DS_Store

		if ( $limit->epoch > $build_dir ) {
			remove_tree( File::Spec->catdir( $dirs->{build}, $build_dir ) );
		}
	}
}

sub DESTROY {
    # do nothing.
}

1;
