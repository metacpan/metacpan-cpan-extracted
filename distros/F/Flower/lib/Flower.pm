=head1 NAME

Flower - pasive agent

=head1 VERSION

Version 0.02


=head1 SYNOPSIS

 git clone https://github.com/santex/Flower.git;
 cd Flower;
 dzil build;
 dzil test;
 sudo dzil install;
 pwd=$(pwd);
 ip=127.0.0.1;

 perl $pwd"/bin/flower" --ip $ip --filepath $pwd"/data/"


=cut

package Flower;

use strict;
use warnings;

use Mojo::Base 'Mojolicious';
use Data::Printer;
use Mojo::Server::Daemon;
use EV;
use AnyEvent;
use Data::UUID;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Routes
  my $r = $self->routes;

  # Normal route to controller
  $r->route('/')->to('interface#root');
  $r->route('/about')->to('interface#root');

  # RESTful routes
  # routes for the remote nodes to hit
  #$r->route('/REST/1.0/:file')->to('upload#store');
  $r->route('/REST/1.0/ping')->via(qw/POST/)->to('rest#ping');
  $r->route('/REST/1.0/files')->to('rest#file_get_by_uuid');
  $r->route('/REST/1.0/file/:uuid')->to('rest#files');

  # routes for the local interface to use
  # XXX should check it is the local user!
  $r->route('/REST/1.0/files/all')->to('rest#files_all');



}


1;
# ABSTRACT: your pasive agent arround the web
=head1 AUTHOR

Hagen Geissler, C<< <santex at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Hagen Geissler

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
