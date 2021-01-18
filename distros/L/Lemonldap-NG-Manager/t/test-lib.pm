# Base library for tests

use strict;
use Data::Dumper;

use_ok('Lemonldap::NG::Manager::Cli::Lib');

our $client;

ok(
    $client =
      Lemonldap::NG::Manager::Cli::Lib->new( iniFile => 't/lemonldap-ng.ini' ),
    'Client object'
);

sub client {
    return $client;
}

our $count = 2;

sub count {
    my $c = shift;
    $count += $c if ($c);
    return $count;
}

1;
