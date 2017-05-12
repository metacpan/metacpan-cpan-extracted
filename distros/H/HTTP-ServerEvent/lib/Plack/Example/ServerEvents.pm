package Plack::Example::ServerEvents;
use strict;
use AnyEvent;
use HTTP::ServerEvent;

=head1 NAME

Plack::Example::ServerEvents - Sample Server-Sent Events server

=head1 SYNOPSIS

  plackup -MPlack::Example::ServerEvents -e "Plack::Example::ServerEvents->countdown"

=cut

use vars qw($VERSION);
$VERSION = '0.02';

my $html= join "", <DATA>;

# Creates a PSGI responder
sub countdown {
    my $app= sub {
      my $env = shift;

      if( $env->{PATH_INFO} ne '/events' ) {
          # Send the JS+HTML
          return [ 200, ['Content-Type', 'text/html'], [$html] ]
      };

      if( ! $env->{"psgi.streaming"}) {
          my $err= "Server does not support streaming responses";
          warn $err;
          return [ 500, ['Content-Type', 'text/plain'], [$err] ]
      };

      # immediately starts the response and stream the content
      return sub {
          my $responder = shift;
          my $writer = $responder->(
              [ 200, [ 'Content-Type', 'text/event-stream' ]]);
          my $countdown= 10;
          
          my $w; $w= AnyEvent->timer(
              after => 1,
              interval => 1,
              cb => sub {
                  $countdown--;
                  if (0 < $countdown) {
                      my $event= HTTP::ServerEvent->as_string(
                              data => $countdown,
                              event => 'tick',
                          );

                      $writer->write($event);
                  } else {
                      warn "Boom";
                      undef $w;
                      $writer->close;
                  }
              }
          );
      };
  };

};

1;

=head1 SEE ALSO

The source code of this module

L<HTTP::ServerEvent>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2013-2013 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

__DATA__
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<script language="javascript">
  var events = new EventSource('/events');
  // Subscribe to "tick" event
  events.addEventListener('tick', function(event) {
    var out= document.getElementById("my_console");
    out.appendChild(document.createTextNode(event.data));
  }, false);
</script>
</head>
<h1>Countdown</h1>
<div id="my_console">
</div>
<h2>...</h2>
</html>