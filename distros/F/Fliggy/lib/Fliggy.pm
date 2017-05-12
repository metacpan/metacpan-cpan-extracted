package Fliggy;

use strict;
use warnings;

use 5.008_001;

our $VERSION = '0.009003';

1;
__END__

=head1 NAME

Fliggy - Twiggy with inlined Flash Policy Server

=head1 SYNOPSIS

  fliggy --listen :8080

See C<fliggy -h> for more details.

  use Fliggy::Server;

  my $server = Fliggy::Server->new(
      host => $host,
      port => $port,
  );
  $server->register_service($app);

  AE::cv->recv;

=head1 DESCRIPTION

Fliggy inherits Twiggy and adds support for inlined Flash Policy server (useful
for L<Plack::Middleware::SocketIO> or Flash WebSocket fallback).

No need to run Flash Policy server as root on 843 port!

Usage is exactly the same as L<Twiggy>, whenever you run C<twiggy> command, replace it
with C<fliggy> and you're ready to go.

=head1 SEE ALSO

L<Plack> L<AnyEvent> L<Twiggy>

=cut

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/fliggy

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 CREDITS

L<Twiggy> authors.

Johannes Plunien (plu)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
