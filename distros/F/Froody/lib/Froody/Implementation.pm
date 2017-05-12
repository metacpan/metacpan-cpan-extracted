package Froody::Implementation;

use strict;
use warnings;

use base qw(
  Froody::Invoker::Implementation  
  Class::Data::Inheritable
  Class::Accessor
);

use Scalar::Util qw(blessed);
use Froody::Error;
use Froody::Logger;
my $logger = Froody::Logger->get_logger("Froody::Implementation");

our $IMPLEMENTATION_SUPERCLASS = 1;
our $VERSION = "0.01";

# ensure that every context has a new copy of $self, or you'll get nasty
# issues when instance vars hang around and break stuff.
sub create_context {
  my $self = shift;
  $self = $self->new;
  return $self->SUPER::create_context(@_);
}

__PACKAGE__->mk_classdata( 'plugins' );
__PACKAGE__->mk_classdata( 'plugin_methods' );

sub register_plugin {
  my ($class, $plugin, @args) = @_;
  $plugin->require or die $@;
  $class->plugins( [] ) unless $class->plugins;
  my $instance = $plugin->new($class, @args);
  Carp::carp("plugin '$plugin' (of class $plugin) is not a plugin")
      unless $instance->isa('Froody::Plugin');
  push @{$class->plugins}, $instance;
}

sub pre_process {
  my ($self, $method, $params) = @_;
  
  for (@{$self->plugins || []}) {
      $_->plugin_pre_process($self, $method, $params);
  }

  my $ret = $self->SUPER::pre_process($method, $params);

  # ewwww
  for (@{$self->plugins || []}) {
      $_->plugin_post_pre_process($self, $method, $params)
        if $_->can('plugin_post_pre_process');
  }

  return $ret;
}

sub post_process {
  my $self = shift;

  my $ret = $self->SUPER::post_process(@_);
  for (reverse @{$self->plugins || []}) {
      $_->plugin_post_process($self, @_);
  }

  return $ret;
}

sub error_handler {
  my $self = shift;

  my $ret = $self->SUPER::error_handler(@_);
  for (reverse @{$self->plugins || []}) {
      $_->plugin_error_handler($self, @_ );
  }

  return $ret;
}

sub register_in_repository
{
  my $class       = shift;
  my $repository  = shift;
  my @filters     = shift;
  require Froody::Method;
  @filters        = map { Froody::Method->match_to_regex($_) } @filters;

  $repository->register_implementation($class, @filters);

  my @plugin_methods = grep { !eval { $repository->get_method($_->full_name)} }
                       @{ $class->plugin_methods || [] };
  for (@plugin_methods) {
    # UGH
    $repository->load($_->invoker, [$_], @filters);
  }

  return
}

sub implements {
   Froody::Error->throw("perl.methodcall.unimplemented",
                        "You must define an 'implements' method in '$_[0]'")
}

# can is documented
# override 'can' so the invoker gets the right coderef
sub can {
    my $self = shift;
    my $class = ref($self) ? ref($self) : $self;
    no strict 'refs';
    my $map = \%{$class.'::FROODY_METHOD_MAPS'};
    return $map->{$_[0]} if exists $map->{$_[0]};
    # fallback
    return $self->SUPER::can(@_);
}

# MODIFY_CODE_ATTRIBUTES is documented
# in perldoc attributes

sub MODIFY_CODE_ATTRIBUTES {
    my ($pkg, $code, @attr) = @_;
    my @unwanted;
    no strict 'refs';
    no warnings 'once';
    for my $attr (@attr) {
      my ($name, $info) = $attr =~ m/^(\w+)\((.*)\)/
          or warn "unknown attribute $attr";
      if ($name eq 'FroodyMethod') {
          my $map = \%{$pkg.'::FROODY_METHOD_MAPS'};
          $map->{$info} = $code;
      }
      else {
          push @unwanted, $attr;
      }
    }
    return @unwanted;
}

1;

__END__

# Module::Build::Kwalitee wants us to declare =item or =head with our method
# names to show we've documented them, but it doesn't work well with the
# tutorial style of the current pod.  Let's just declare they're documented
# with the magic strings in the following comments:
# register_in_repository is documented

=head1 NAME

Froody::Implementation - define Perl methods to implement Froody::Method 

=head1 SYNOPSIS

  package MyCompany::PerlMethods::Time;
  use base qw(Froody::Implementation);

  # say what api you're implementing, and what subset of those methods
  # should be handled by perl methods in this class
  sub implements { "MyCompany::API" => "mycompany.timequery.*" }

  use DateTime;
 
  # this is mycompany.timequery.gettime
  sub gettime
  {
     my $self = shift;
     my $args = shift;

     $now = DateTime->now;
     $now->set_time_zone($args->{time_zone}) if $args->{time_zone};
     return $now->datetime;
  }

You may also load plugins to do some of the work for you:
  
  __PACKAGE__->register_plugin("Froody::Plugin::Sasquatch", shoe_size => 25 );
  
  sub explore {
    my ($self, $params) = @_;
    return $self->find_bigfoot( $params->{shoe_size} );
  }

=head1 DESCRIPTION

This class is a simple base class that allows you to quickly and simply
provide code for Froody to run when it needs to execute a method.

You can use a plugin if you want some processing for each of the methods (or a
large portion of the methods). Typical plugins will perform functions like
session management and user authentication (see, for instance,
L<Froody::Plugin::Session> and L<Froody::Plugin::Auth>). Plugins have the
ability to add accessors to your implementation class and instance, and can
perform functions in the 'pre_process' stage of your application. (If you
override pre_process yourself, be sure to call $self->SUPER::pre_process for
the plugins to work.)

=head2 How to write your methods

It's fairly straightforward to write methods for Froody, and is best
demonstrated with an example.  Imagine we've got a Froody::Method that's been
defined like so:

  package PerlService::API;
  use base qw(Froody::API::XML);
  1;
  
  sub xml { <<'XML';
  <spec>
   <methods>
    <method name="perlservice.corelist.released">
      <arguments>
        <argument name="module" type="text" optional="0" />
      </arguments>
      <response>
        <module name="">
          <in version=""></in>
        </module>
      </response>
    </method>
   </methods>
  </spec>
  XML

We are now ready to start writing a class implementing this API:

  package MyCompany::PerlMethods;
  use base qw(Froody::Implementation);
  
  sub implements { "MyCompany::API" => "mycompany.timequery.datetime" }

  sub hello {
    ...
  }

  sub some_get_function :FroodyMethod(get) {
    ...
  }

The methods will be called with two parameters: self and a hashref containing
the method arguments.  The arguments will have already been pre-processed to
verify that they are all there and of the right type, for example (all
registerred plugins also have a chance at doing their own pre-processing before
the method is called). 

=head2 Abstract methods

=over

=item implements()

Should return a hash of 

  Namespace => 'method.names.*'

mappings specifying in what modules the given methods are
implemented.

=back

=head2 METHODS

=over

=item register_plugin( plugin_class, [ plugin params ] )

  __PACKAGE__->register_plugin("Froody::Plugin::Session", session_class => "My::Session::Class" );
  
Adds a plugin to this class. The first parameter is the classname of the
plugin to add, all remaining parameters are passed to the plugin class's
constructor, and should be documented in the perldoc for that plugin.
See L<Froody::Plugin> about plugins.

=back

=head1 BUGS

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>

=cut

1;

