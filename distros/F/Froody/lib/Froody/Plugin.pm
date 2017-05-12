package Froody::Plugin;
use strict;
use warnings;
use Froody::Invoker::PluginService;

=head1 NAME

Froody::Plugin

=head1 SYNOPSIS

  package My::Plugin;
  use base qw( Froody::Plugin );
  
  sub new {
    my ($class, $impl, @args) = @_;
    my $self = $class->SUPER::new($impl, @args);
    $impl->mk_accessors( 'leg_count' );
    return $self;
  }
  
  sub pre_process {
    my ($impl, $method, $params) = @_;
    $impl->leg_count( delete $params->{legs} || 2 );
  }

  ...
  
  package My::Implementation;
  use base qw( Froody::Implementation );
  
  __PACKAGE__->register_plugin('My::Plugin');
  
  sub my_method {
    my ($self, $params) = @_;
    return $self->leg_count()." legs found.\n";
  }

=head1 DESCRIPTION

Froody plugins let you extend an implementation and add functionality without
scary messing around with superclasses. They have a chance to get involved
in the pre_process step of the request, and can add accessors to the importing
class and instance.

=head1 METHODS

=over

=item new( plugin class, implementation class, arguments... )
  
  sub new {
    my ($class, $impl, @args) = @_;
    my $self = $class->SUPER::new($impl, @args);
    $impl->mk_accessors( 'leg_count' );
    return $self;
  }

Constructor, called as a class method. 'implementation class' here is the
class doing the requiring of the plugin, and 'arguments' are all the remaining
args passed to the require_plugin call.

=cut

sub new {
    my ($class, $impl, @arg) = @_;

    $impl->plugin_methods( [] ) unless $impl->plugin_methods;

    my $self = bless {}, $class;
    
    $self->init($impl, @arg);
    
    my $inv = Froody::Invoker::PluginService->new
      ->delegate_class($class)->plugin_impl($impl);

    foreach my $method ($self->get_plugin_methods($impl)) {
      $method->invoker($inv) unless $method->invoker;
      push @{$impl->plugin_methods}, $method;
    }
    
    return $self;
}

=item init( implementation, args )

the place to initialize your object. The return value is ignored.

=cut

sub init { return }

=item get_plugin_methods( implementation class )

plugins should override this method to return froody methods provided
by the plugin.  The methods will then be registered.

=cut

sub get_plugin_methods { () }

=item pre_process( implementation class, method, params )

This is where your plugin gets to do interesting things to the request.
See the docs for pre_process in L<Froody::Invoker::Implementation> for
details on what you can do here. Importantly, this is before parameter
validation. For instance, a session management plugin could remove a
'session_id' param from the request here, and load a session:

  sub pre_process {
    my ($self, $method, $param) = @_;
    my $session_id = delete $param->{session_id};
    $self->session( $session_id );
  }

and the method signature of the implementation wouldn't need to include
it.

Note that the method is called with the first parameter being the
implementation class, not the plugin class. If you need access to the
plugin object, override L<plugin_pre_process> (see below).

=cut

# pre_process is documented
sub pre_process {
    return undef;
}

=item plugin_pre_process(self, implementation class, method, params)

If you need access to your plugin instance, override this method. Its
default behaviour (in Froody::Plugin) is to call pre_process, and not
pass the plugin instance. Override this method I<or> pre_process.

=cut

sub plugin_pre_process {
    my $self = shift;
    # first arg to actual pre_process is not the plugin itself
    $self->can('pre_process')->(@_);
}

=item post_process( implementation, method, args )

By overriding this method, you can preform actions after the
implementation has done its work. See the docs for post_process in
L<Froody::Invoker::Implementation> for details on what you can do here.
The 'args' param here is the hash returned from the implementation,
before it is interpolated into the XML by the path walker, so you can
change the returned XML, but only within the spec of the API.

=cut

sub post_process { return undef }

=item plugin_post_process

If you need access to your plugin instance, override this method. Its
default behaviour (in Froody::Plugin) is to call post_process, and not
pass the plugin instance. Override this method I<or> post_process.

=cut

sub plugin_post_process {
    my $self = shift;
    # first arg to actual post_process is not the plugin itself
    $self->can('post_process')->(@_);
}


=item error_handler( implementation, method, args )

By overriding this method, you can preform actions after the
implementation has done it's work. See the docs for error_handler in
L<Froody::Invoker::Implementation> for details on what you can do here.
The 'args' param here is the hash returned from the implementation,
before it is interpolated into the XML by the path walker, so you can
change the returned XML, but only within the spec of the API.

=cut

sub error_handler { return undef }

=item plugin_error_handler

If you need access to your plugin instance, override this method. Its
default behaviour (in Froody::Plugin) is to call error_handler, and not
pass the plugin instance. Override this method I<or> error_handler.

=cut

sub plugin_error_handler {
    my $self = shift;
    # first arg to actual error_handler is not the plugin itself
    $self->can('error_handler')->(@_);
}


=back

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
