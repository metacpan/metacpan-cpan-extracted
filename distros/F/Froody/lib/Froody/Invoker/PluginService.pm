package Froody::Invoker::PluginService;
use strict;
use warnings;
use base qw(Froody::Invoker::Implementation);
use Froody::Implementation;
our $IMPLEMENTATION_SUPERCLASS = 1;

use Froody::Logger;
my $logger = get_logger('froody.invoker.pluginservice');

__PACKAGE__->mk_accessors(qw( delegate_class plugin_impl ));

=head1 NAME

Froody::Invoker::PluginService

=head1 SYNOPSIS

=cut

# Loads the named module off of disk, or throws a nice error if
# it can't for some reason.  Checks to see if the module supports
# the needed method name too.
sub _require_module {
  my $self        = shift;
  my $module_name = shift;
  my $method_name = shift;

  # are we already loaded?  Sweet.
  {
    no strict 'refs';
    return if %{"$module_name\::"};
  }
  # use the UNIVERSAL::require module to require the module
  # this returns false if the require fails, but this can be _both_ because
  # there were errors, _and_ if the file we expected doesn't exist, but
  # handlers _might_ be defined in differently named files.
  $module_name->require;

  if ( $UNIVERSAL::require::ERROR ) {
    $logger->error("Error compiling module $module_name: $UNIVERSAL::require::ERROR");
    Froody::Error->throw("perl.use", "module $module_name not found");
  }

  # now check to see if there is a package of the right name loaded.
  {
    no strict 'refs';
    unless (%{"$module_name\::"}) {
      # no stash defined, thus there's no package with the right name loaded.
      Froody::Error->throw("perl.use", "module $module_name does not exist");
    }
  }

  # if there was a syntax error, it looks like the stash _is_ defined, but
  # the module won't be able to do a method call.
  unless ( $module_name->can($method_name) ) {
    $logger->error("Error compiling module $module_name: $UNIVERSAL::require::ERROR");
    Froody::Error->throw("perl.use", "module $module_name cannot '$method_name'");
  }
}

sub module {
  my ($self, $method) = @_;

  # do a quick module conversion
  my $module = $self->delegate_class;
  $self->_require_module($module, $method->name);

  return $module;
}

sub create_context {
    my $self = shift;
    return bless {  }, $self->{plugin_impl};
}

sub source {
  return "plugin ". shift->SUPER::source()
}

sub pre_process {
    my ($self, $method, $params) = @_;
    Froody::Implementation::pre_process($self->{plugin_impl}, $method, $params);
}

sub post_process {
    my ($self, $method, $params) = @_;
    Froody::Implementation::post_process($self->{plugin_impl}, $method, $params);
}

sub error_handler {
    my ($self, $method, $error) = @_;
    Froody::Implementation::error_handler($self->{plugin_impl}, $method, $error);
}


=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
