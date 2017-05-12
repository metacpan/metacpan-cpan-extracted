package Test::Enbld::Definition;

use strict;
use warnings;

use Test::Builder::Module;

use File::Temp;
use File::Spec;
use File::Path qw/make_path/;
use File::Copy;
use FindBin;

require Enbld::Home;
require Enbld::Logger;
require Enbld::Target;
require Enbld::Condition;

my $CLASS = __PACKAGE__;

use parent qw/Test::Builder::Module/;

our @EXPORT = qw/build_ok/;

sub build_ok($;$$$) {
    my $name        = $_[0];
    my $config      = $_[1];
    my $condition   = $_[2];
    my $description = $_[3];

    local $ENV{PERL_ENBLD_HOME} = File::Temp->newdir;

    Enbld::Home->initialize;
    Enbld::Home->create_build_directory;

    Enbld::Logger->rotate( Enbld::Home->log );

    my $target = Enbld::Target->new( $name, $config );

    my $installed;
    if ( $condition ) {
        eval { $installed = $target->install_declared( $condition ) };
    } else {
        eval { $installed = $target->install };
    }

    my $tb = $CLASS->builder;

    chdir $FindBin::Bin;

    if ( $@ ) {
        $tb->diag( "Error occured, please check logfile." );

        my $logfile = File::Spec->catfile(
                $FindBin::Bin,
                'build_' . time . '_log.txt'
                );
        $tb->diag( "logfile:" . $logfile );
        copy( Enbld::Logger->logfile, $logfile );

        return $tb->BAIL_OUT( $@ );
    }

    return $tb->ok(@_);
}

1;
