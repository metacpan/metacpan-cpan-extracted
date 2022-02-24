package Lemonldap::NG::Portal::Main::Auth;

use strict;
use Mouse;

our $VERSION = '2.0.14';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# PROPERTIES

has authnLevel => ( is => 'rw' );

sub stop { 0 }

1;
