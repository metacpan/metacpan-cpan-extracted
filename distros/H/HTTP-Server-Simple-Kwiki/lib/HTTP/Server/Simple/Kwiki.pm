package HTTP::Server::Simple::Kwiki;

use HTTP::Server::Simple::CGI;
use HTTP::Server::Simple::Static;
use IO::Capture::Stdout;
use base qw(HTTP::Server::Simple::CGI HTTP::Server::Simple::Static);
use strict;
use warnings;
use Kwiki;
our $VERSION = 0.29;

sub handle_request {
  my($self, $cgi) = @_;

  my $url = "http://localhost" . $ENV{REQUEST_URI};

  if ($url =~ /\.(gif|png|css)/) {
    $self->serve_static($cgi, ".");
  } else {
    my $capture = IO::Capture::Stdout->new();
    $capture->start();
    Kwiki->new->debug->process('config*.*', -plugins => 'plugins');
    $capture->stop();
    my $output = join '', $capture->read;

    if ($output =~ m{302}) {
      $output = "HTTP/1.0 302 OK\n$output";
    } else {
      $output = "HTTP/1.0 200 OK\n$output";
    }

    print $output;
  }
}

1;

__END__

=head1 NAME

HTTP::Server::Simple::Kwiki - Standalone Kwiki server

=head1 SYNOPSIS

  use HTTP::Server::Simple::Kwiki;

  chdir "my-kwiki"; 
  my $server = HTTP::Server::Simple::Kwiki->new();
  $server->run();

=head1 DESCRIPTION

L<HTTP::Server::Simple::Kwiki> is a standalone webserver for
Kwiki. This means that you don't need to run it under a proper
webserver. This is intended mostly for debugging Kwiki, or for when
you just want to play with it without having to configure Apache.

Note that all you need to do is write a script like in the synopsis,
remembering to chdir into your Kwiki directory.

=head1 CONSTRUCTOR

=head1 SEE ALSO

Related modules which may be of interest: L<Kwiki>,
L<HTTP::Server::Simple>.

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
