package Kwiki::Simple::Server::HTTP;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use HTTP::Server::Simple::Kwiki;
our $VERSION = '0.03';

const class_id => 'simple_server_http';
const config_file => 'simple_server_http.yaml';

sub register {
    my $register = shift;
    $register->add(command => 'start',
                   description => 'Start a stand-alone kwiki http server');
}

sub handle_start {
    my $port = shift || $self->hub->config->simple_server_http_port;
    my $server = HTTP::Server::Simple::Kwiki->new($port);
    $server->run();
}

__DATA__

=head1 NAME

  Kwiki::Simple::Server::HTTP - Start a stand-alone kwiki http server

=head1 SYNOPSIS

  kwiki -add Kwiki::Simple::Server::HTTP
  kwiki -start
  HTTP::Server::Simple: You can connect to your server at http://localhost:8080

Or starts it on different port:

  kwiki -start 1234
  HTTP::Server::Simple: You can connect to your server at http://localhost:1234

=head1 DESCRIPTION

This Kwiki plugin let you run a standalone http server for your Kwiki
under current working directory. It is helpful for debugging purpose
or just startup a wiki site quickly. After installed, just run

  kwiki -start

And a http server (based on L<HTTP::Server::Simple::Kwiki> would be started.
If you wish to run it on different port number, pass it as a command line
argument:

  kwiki -start 1234

or edit config.yaml, change the value of C<simple_server_http_port> like this:

  simple_server_http_port: 1234

Command line option has higher precedence then configuration.

=head1 SEE ALSO

L<Kwiki>, L<HTTP::Server::Simple::Kwiki>

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__config/simple_server_http.yaml__
simple_server_http_port: 8080
