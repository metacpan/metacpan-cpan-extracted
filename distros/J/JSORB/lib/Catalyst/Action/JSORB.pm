package Catalyst::Action::JSORB;
use Moose;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use JSORB;
use JSON::RPC::Common::Marshal::HTTP;

extends 'Catalyst::Action';

sub execute {
    my $self = shift;
    my ($controller, $c) = @_;

    $self->NEXT::execute(@_);

    # try local, but if none exists, use global
    my $dispatcher = $controller->config->{'Action::JSORB'} || $c->config->{'Action::JSORB'};

    (blessed $dispatcher && $dispatcher->isa('JSORB::Dispatcher::Catalyst'))
        || confess "Bad dispatcher - $dispatcher (must inherit JSORB::Dispatcher::Catalyst)";

    my $marshaler = JSON::RPC::Common::Marshal::HTTP->new;
    my $call      = $marshaler->request_to_call($c->request);
    my $result    = $dispatcher->handler($call, $c);

    $marshaler->write_result_to_response($result, $c->response);
}

no Moose; 1;

__END__

=pod

=head1 NAME

Catalyst::Action::JSORB - Catalyst Action for JSORB dispatchers

=head1 SYNOPSIS

  use Catalyst::Action::JSORB;

  TestApp->config(
      name => 'TestApp',
      who  => 'World',
      # add the JSORB config ...
      'Action::JSORB' => JSORB::Dispatcher::Catalyst->new(
          namespace     => JSORB::Namespace->new(
              name     => 'Test',
              elements => [
                  JSORB::Interface->new(
                      name       => 'App',
                      procedures => [
                          JSORB::Procedure->new(
                              name  => 'greeting',
                              body  => sub {
                                  my ($c) = @_;
                                  return 'Hello ' . $c->config->{'who'};
                              },
                              spec  => [ 'Catalyst' => 'Str' ],
                          ),
                      ]
                  )
              ]
          )
      )
  );

  TestApp->setup;

  sub rpc : Global : ActionClass(JSORB) {}

=head1 DESCRIPTION

This is basically a Catalyst Action that can be used as a gateway
to a JSORB dispatcher. It will first look for the dispatcher in
the local controller config and failing that will look in the
global config.

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
