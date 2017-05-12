package JSORB::Server::Traits::WithInvocant;
use Moose::Role;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

has 'invocant' => (
    is       => 'ro',
    isa      => 'Object',   
    required => 1,
);

sub prepare_handler_args {
    #my ($self, $call, $request) = @_;
    (shift)->invocant
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

JSORB::Server::Traits::WithInvocant - A JSORB::Server::Simple trait for working with invocants

=head1 SYNOPSIS

  JSORB::Server::Simple->new_with_traits(
      traits     => [ 'JSORB::Server::Traits::WithInvocant' ],
      dispatcher => JSORB::Dispatcher::Path->new_with_traits(
          traits    => [ 'JSORB::Dispatcher::Traits::WithInvocant' ],
          namespace => $ns,
      ),
      invocant   => App::Foo->new(bar => 'Bar', baz => 'Baz')
  )->run;

=head1 DESCRIPTION

This is mostly for when you use the L<JSORB::Dispatcher::Traits::WithInvocant>
trait with your dispatcher to make sure that the invocant is handled correctly.

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
