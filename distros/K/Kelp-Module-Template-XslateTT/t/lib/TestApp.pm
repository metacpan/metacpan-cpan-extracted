package TestApp;

# $Id: TestApp.pm 62 2018-11-16 16:47:13Z stro $

use strict;
use warnings;

use Kelp::Base 'Kelp';

use Kelp::Module::Template::XslateTT;

sub build {
  my $self = shift;
  my $r    = $self->routes;
  $r->add( '/' => { to => 'home' } );
}

sub home {
  my $self = shift;

  my $version = $Kelp::Module::Template::XslateTT::VERSION;

  return $self->res->template('home', { 'version' => $version });
}

1;
