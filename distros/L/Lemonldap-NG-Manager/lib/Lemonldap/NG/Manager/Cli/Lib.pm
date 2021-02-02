package Lemonldap::NG::Manager::Cli::Lib;

use strict;
use Mouse;
use Lemonldap::NG::Manager;

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Common::PSGI::Cli::Lib';

has mgr => ( is => 'ro', isa => 'Lemonldap::NG::Manager' );

has app => (
    is      => 'ro',
    isa     => 'CodeRef',
    builder => sub {
        my $args = { protection => 'none' };
        $args->{configStorage} = { confFile => $_[0]->{iniFile} }
          if ( $_[0]->{iniFile} );
        $_[0]->{mgr} = Lemonldap::NG::Manager->new($args);
        $_[0]->{mgr}->init($args);
        return $_[0]->{mgr}->run();
    }
);

1;
