=head1 NAME

Froody::Server::Test

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package Froody::Server::Test;
use warnings;
use strict;
use Froody::Dispatch;
use Froody::Server::Standalone; 

=head1 METHODS

=over

=item client( 'Froody::Service', 'Froody::Service', .. )

Starts a standalone Froody server, implementing the passed service classes,
and returns a Froody::Client object that will talk to the server, for local
testing of implementations. The server will be stopped on script exit.

=cut

# This is our random port, which is an attempt to not tromp over other users who might
# be testing their own froody clients at the same time.
our $port = 30_000 + ( $> % 400 );

my $child;

=item start

Starts the Test server with a list of configuration details as specified
by the C<config> method of L<Froody::Dispatch>. Returns the pid of the
started process, or 0 if it happens to be the child process.
This will only start the server once, without calling C<stop> first.

=cut

sub start {
  my ($class, @impl) = @_;
  return $child if defined $child;
  unless ($child = fork()) {
  
    # loading Froody::Server::Standalone does some things
    # to our enviroment (for example, it piddles with the SIG handlers
    # so we only want to do that in the child.)
      
    my $server = Froody::Server::Standalone->new();
    $server->config({ 
        modules => \@impl, 
    });
    $server->port($port);
    $server->run;
  }
  return $child;
}

=item endpoint

Returns the endpoint for the Test server

=cut

sub endpoint {
    my $class = shift;
    return "http://localhost:$port/";
}

# start the web server

=item client

Returns a C<Froody::Dispatch> based client that points to the test
server. As a side-effect, it will start up the test server if it has
not already been started.

=cut

sub client {
  my ($class, @impl) = @_;
  
  $class->start(@impl);
  
  sleep 1;
  my $client = Froody::Dispatch->new();
  $client->repository( Froody::Repository->new() );
  $client->add_endpoint("http://localhost:$port");
  return $client;
}

# stop is documented
sub stop {
  if ($child) {
    # what the gosh-darn signals numbered on this box then?
    use Config;
    defined $Config{sig_name} || die "No sigs?";
    my ($i, %signo);
    foreach my $name (split(' ', $Config{sig_name})) {
       $signo{$name} = $i;
       $i++;
    }
    
    # die with more and more nastyness
    for my $signal (qw(TERM KILL)) {
      kill $signo{$signal}, $child;
      exit unless kill 0, $child;
      sleep 1;
    }
    
    $child = undef;
  }
}

END { stop() }


=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

