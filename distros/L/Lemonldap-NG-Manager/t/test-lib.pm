# Base library for tests

use strict;
use Data::Dumper;

use_ok('Lemonldap::NG::Manager::Cli::Lib');

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

has iniFile => ( is => 'ro', default => 't/lemonldap-ng.ini' );

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
    $ini->{configStorage} = { confFile => $self->iniFile }
      if ( $self->iniFile );
    $self->ini($ini);

    main::ok( $self->p( Lemonldap::NG::Manager->new($ini) ), 'Manager object' );
    main::ok( $self->p->init($ini),                          'Init' );
    main::ok( $self->app( $self->p->run() ),                 'Manager app' );
    main::count(3);
    return $self;
}

1;
