package JSORB;
use Moose;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use JSORB::Namespace;
use JSORB::Interface;
use JSORB::Procedure;
use JSORB::Method;

use JSORB::Types;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB - Javascript Object Request Broker

=head1 SYNOPSIS

  use JSORB;
  use JSORB::Server::Simple;
  use JSORB::Dispatcher::Path;
  use JSORB::Reflector::Package;
  use JSORB::Client::Compiler::Javascript;

  # create some code to expose over RPC
  {
      package Math::Simple;
      use Moose;
      sub add { $_[0] + $_[1] }
  }

  # Set up a simple JSORB server
  JSORB::Server::Simple->new(
      port       => 8080,
      dispatcher => JSORB::Dispatcher::Path->new(
          namespace => JSORB::Reflector::Package->new(
              # tell JSORB to introspect the package
              introspector   => Math::Simple->meta,
              # add some type information
              # about the procedure
              procedure_list => [
                  { name => 'add', spec => [ ('Int', 'Int') => 'Int' ] }
              ]
          )->namespace
      )
  )->run;

  ## Now you can ...

  ## go to the URL directly

  http://localhost:8080/?method=/math/simple/add&params=[2,2]

  # and get back a response
  { "jsonrpc" : "2.0", "result" : 2 }

  ## compile your own Javascript client
  ## library for use in a web page ...

  my $c = JSORB::Client::Compiler::Javascript->new;
  $c->compile(
      namespace => $namespace,
      to        => [ 'webroot', 'js', 'MathSimple.js' ]
  );

  # and in your JS

  var math = new Math.Simple ( 'http://localhost:8080' );
  math.add( 2, 2, function (result) { alert(result) } );

  ## or use the more low level
  ## JSORB client library directly

  var c = new JSORB.Client ({
      base_url : 'http://localhost:8080/',
  })

  c.call({
      method : '/math/simple/add',
      params : [ 2, 2 ]
  }, function (result) {
      alert(result)
  });

=head1 DESCRIPTION

                                         __
          __                            /\ \
         /\_\      ____    ___    _ __  \ \ \____
         \/\ \    /',__\  / __`\ /\`'__\ \ \ '__`\
          \ \ \  /\__, `\/\ \L\ \\ \ \/   \ \ \L\ \
          _\ \ \ \/\____/\ \____/ \ \_\    \ \_,__/
         /\ \_\ \ \/___/  \/___/   \/_/     \/___/
         \ \____/
          \/___/

=head2 DISCLAIMER

This is a B<VERY VERY> early release of this module, and while
it is quite functional, this module should in no way be seen as
complete. You are more then welcome to experiment and play
around with this module, but don't come crying to me if it
accidently deletes your MP3 collection, kills the neighbors dog
and causes the large hadron collider to create a black hole that
swallows up all of existence tearing you molecule from molecule
along the event horizon for all eternity.

=head2 GOAL

The goal of this module is to provide a cleaner and more formalized
way to do AJAX programming using JSON-RPC in the flavor of Object
Request Brokers.

=head2 FUTURE PLANS

Currently this is more focused on RPC calls between Perl on the
server side and Javascript on the client side. Eventually we will
have a Perl client and possibly some servers written in other
languages as well.

=head2 GETTING STARTED

The documentation is very sparse and I apologize for that, but the
test suite has a lot of good stuff to read and there is a couple
neat things in the example directory. If you want to know more
about the Javascript end there are tests for that as well. As this
module matures more the docs will improve, but as mentioned above,
it is still pretty new and we have big plans for its future.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
