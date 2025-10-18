# Base library for tests

use strict;
use Data::Dumper;
use File::Copy;
use JSON;
use File::Temp qw/ tempdir /;
use IO::String;

use_ok('Lemonldap::NG::Manager::Cli::Lib');

our $tmpdir = tempdir( DIR => "t/", CLEANUP => 1 );

mkdir("$tmpdir/conf");
mkdir("$tmpdir/sessions");

copy_subst_file( "t/conf/lmConf-1.json",        "conf/lmConf-1.json" );
copy_subst_file( "t/lemonldap-ng.ini",          "lemonldap-ng.ini" );
copy_subst_file( "t/lemonldap-ng-DBI-conf.ini", "lemonldap-ng-DBI-conf.ini" );

sub substitute_io_handle {
    my ($filename) = @_;
    return get_conf_body_from_fixture($filename);
}

# Reads a configuration fixture file, replace TMPDIR by the current tmpdir, and
# apply optional transformation to the decoded JSON data structure
sub get_conf_body_from_fixture {
    my ( $filename, $transformation ) = @_;

    open( my $fh, "<", $filename );
    my $file_content = do { local $/; <$fh> };
    close($fh);
    $file_content =~ s/TMPDIR/$main::tmpdir/g;

    if ($transformation) {
        my $conf_data = decode_json($file_content);
        $transformation->($conf_data);
        $file_content = encode_json($conf_data);
    }

    return ( length($file_content), IO::String->new($file_content) );
}

sub copy_subst_file {
    my ( $ini_file, $destname ) = @_;

    open my $in, '<', $ini_file or die "Can't open input: $!";
    my $conf_content = do { local $/; <$in> };
    close $in;

    # Perform regex substitution
    $conf_content =~ s#TMPDIR#$main::tmpdir#g;

    # Write to output file
    open my $out, '>', "$main::tmpdir/$destname"
      or die "Can't open output: $!";
    print $out $conf_content;
    close $out;

}

# Legacy way to obtain a test Manager client
our $client;

sub client {
    if ( !$client ) {
        ok( $client = LLNG::Manager::Test->new, 'Client object' );
        count(1);
    }
    return $client;
}

our $count = 1;

sub count {
    my $c = shift;
    $count += $c if ($c);
    return $count;
}

1;

package LLNG::Manager::Test;

use strict;
use Mouse;
use IO::String;

extends 'Lemonldap::NG::Common::PSGI::Cli::Lib';

our $defaultIni = { protection => "none" };

has app => (
    is  => 'rw',
    isa => 'CodeRef',
);

has iniFile => ( is => 'ro', default => "$main::tmpdir/lemonldap-ng.ini" );

has ini => ( is => 'rw', );
has p   => ( is => 'rw', );

sub BUILD {
    my ($self) = @_;
    my $ini = $self->ini;
    foreach my $k ( keys %$defaultIni ) {
        $ini->{$k} //= $defaultIni->{$k};
    }
    if ( $ENV{DEBUG} ) {
        $ini->{logLevel} = 'debug';
    }
    if ( $ENV{LLNGLOGLEVEL} ) {
        $ini->{logLevel} = $ENV{LLNGLOGLEVEL};
    }

    $ini->{configStorage} = { confFile => $self->iniFile };
    $self->ini($ini);

    main::ok( $self->p( Lemonldap::NG::Manager->new($ini) ), 'Manager object' );
    main::ok( $self->p->init($ini),                          'Init' );
    main::ok( $self->app( $self->p->run() ),                 'Manager app' );
    main::count(3);
    return $self;
}

1;
