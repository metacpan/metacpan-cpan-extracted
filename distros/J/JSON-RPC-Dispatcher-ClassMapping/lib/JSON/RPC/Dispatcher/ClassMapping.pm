package JSON::RPC::Dispatcher::ClassMapping;

use strict;
use warnings;
our $VERSION = '0.03';

use JSON::RPC::Dispatcher 0.0505;
use Moose;
use namespace::autoclean;

# XXX: Hack to relax "method" constraint of J::R::D::P so that it accepts "."
{
package
    JSON::RPC::Dispatcher::Procedure; # hide from PAUSE/indexers
use Moose;

__PACKAGE__->meta->make_mutable;
has method  => (
    is      => 'rw',
    default => undef,
    trigger => sub {
            my ($self, $new, $old) = @_;
            if (defined $new && $new !~ m{^[A-Za-z0-9_.]+$}xms) {
                $self->invalid_request($new.' is not a valid method name.');
            }
        },
);
no Moose;
__PACKAGE__->meta->make_immutable;
}


has 'rpc' => (
    is      => 'rw', 
    isa     => 'Object',
    default => sub { JSON::RPC::Dispatcher->new },
    handles => [ 'to_app', 'register' ],
);

has 'dispatch' => (
    is       => 'rw',
    isa      => 'HashRef[Str]',
    required => 1,
);


sub BUILD {
    my $self = shift;

    # setup dispatch to methods of classes defined in %dispatch
    while (my ($namespace, $module) = each %{ $self->dispatch }) {
        Class::MOP::load_class($module);
        my $metaclass = Class::MOP::Class->initialize($module);
        foreach my $method ($metaclass->get_method_list) {
            $self->register("$namespace.$method", sub { $module->$method(@_) })
                if substr($method, 0, 1) ne '_';
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

JSON::RPC::Dispatcher::ClassMapping - Expose all public methods of classes as RPC methods

=head1 SYNOPSIS

  # in app.psgi
  use JSON::RPC::Dispatcher::ClassMapping;

  my $server = JSON::RPC::Dispatcher::ClassMapping->new(
      dispatch => { 
          Foo   => 'My::Module', 
          Bar   => 'My::Another::Module', 
      },
  );

  $server->to_app;

=head1 DESCRIPTION

This module is a wrapper for L<JSON::RPC::Dispatcher> and provides an
easy way to expose all public methods of classes as JSON-RPC methods. It
treats methods with a leading underscore as private methods.

=head1 ATTRIBUTES

=over 4

=item I<dispatch>

This is a hashref that maps "package names" in RPC method requests
to actual Perl module names (in a format like C<My::Module::Name>).
For example, let's say that you have a C<dispatch> that looks like this:

 {
     'Util'     => 'Foo::Service::Util',
     'Calendar' => 'Bar::Baz'
 }

So then, calling the method C<Util.get> will call
C<< Foo::Service::Util->get >>. Calling C<Calendar.create> will call
C<< Bar::Baz->create >>. You don't have to pre-load the Perl modules,
JSON::RPC::Dispatcher::ClassMapping will load them for you.

=back

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

Based on the dispatcher of L<RPC::Any::Server>  by Max Kanat-Alexander.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<RPC::Any::Server> L<SOAP::Server>

=cut
