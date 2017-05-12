=head1 NAME

Froody::Dispatch - Easily call Froody Methods

=head1 SYNOPSIS

  use Froody::Dispatch;
  my $dispatcher = Froody::Dispatch->new();
  my $response = $dispatcher->call( "foo.bar.baz",
    fred => "wilma" 
  );

or, as a client:

  $client = Froody::Dispatch->new;

  # uses reflection to load methods from the server
  $client->add_endpoint( "uri" ); 

  # look mah, no arguments!
  $rsp = $invoker->invoke($client, 'service.wibble');

  # ok, take some arguments then.
  $rsp = $invoker->invoke($client, 'service.devide', divisor => 1, dividend => 2);

  # alternatively, args can be passed as a hashref:
  $args = { devisor => 1, devidend => 2 }; 
  $rsp = $invoker->invoke($client, 'service.devide', $args);


=head1 DESCRIPTION

This class handles dispatching Froody Methods.  It's used both from within the
servers where you don't want to have to worry about the little details and as a
client.

=cut

package Froody::Dispatch;
use base qw( Froody::Base );

use warnings;
use strict;

use Params::Validate qw(:all);
use Scalar::Util qw( blessed );

use Froody::Response::Terse;
use Froody::Repository;
use Froody::Response::Error;
use Froody::Invoker::Remote;
use Froody::Error qw(err);
use Froody::Logger;

my $logger = get_logger("froody.dispatch");

__PACKAGE__->mk_accessors(qw{response_class error_class endpoints filters});

=head1 METHODS

=head2 Class Methods

=over 4

=item new

Create a new instance of the dispatcher

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->endpoints({}) unless $self->endpoints;
  $self->error_class('Froody::Response::Error') unless $self->error_class;
  $self;
}

=item parse_cli (@args) 

Parses a list of files, urls, modules, method filter expressions, and paths.

What you're able to do:

=over 4

=item module

-MModule::Name (or just Module::Name) - request that that module is registered.

=item path

-Ipath will inject that path into C<%INC>

=item perl module file name

filename will extract all module names from within the path

=item method filter 

foo.bar.baz will be interpreted as a filter expression.

=back

Returns a hashref of include paths, modules, urls, and filters

=cut

sub parse_cli {
  my ($self, @args) = @_;
  my @urls;
  my @modules;
  my @filters;
  my @includes;
  for (@args) {
    if ($_ =~ s/^-M// || $_ =~ m/::/) {
      push @modules, $_; 
    } elsif ( $_ =~ m/^https?:/) {
      push @urls, $_;
    } elsif ( -f $_ ) {
      # fairly horrible, this.
      my $data;
      {
        open my $fh, "<", $_ or die "can't open $_ for reading: $!";
        local $/;
        $data = <$fh>;
      }
      while ($data =~ /^\s*package (.*?);$/gm) {
        my $module = $1;
        $module =~ s/'/::/g;  # incase of crack
        push @modules, $module;
      }
    } elsif ( $_ =~ s/^-I//) {
      push @includes, $_;
    } elsif ( $_ =~ m/\./) {
      push @filters, $_;
    } else {
      # TODO: Write a real usage doc.
      die "What should I do with $_?  I understand perl modules, URLs, and froody method names";
    }
  }
  return {
    modules => \@modules,
    urls => \@urls,
    filters => \@filters,
    includes => \@includes,
    args => {},
  }
}

=item config ($args)

Configures the dispatcher. Takes { filters => [], modules => [], urls => [], includes => [] } and
ensures that the dispatcher only contains methods that are present in either the modules
list or the urls list, and only if those modules match one or more of the filters in the
filters list.  If the filters list is empty, then all methods will be registered.

=cut

sub config {
  my ($self, $args) = @_;
  unless (ref $self) {
    $self = $self->new; # we should be an instance.
  }
  my $repository = Froody::Repository->new;
  $self->repository($repository);
  for (@{ $args->{includes} }) {
    unshift @INC, $_; #extend the search path
  }
  my @filters = @{ $args->{filters} || [] };
  $self->filters(@filters);
  for (@{ $args->{urls} || [] }) { 
    $self->add_endpoint( $_, @filters );
  }
#  warn Dumper($args->{modules}); use Data::Dumper;

  # implementation has-a api_specification
  # implementation has-a list of filters
  
  my %api;
  for my $module (@{ $args->{modules} || [] }) {
  
    # make sure implementation is loaded for isa-checks etc.
    $module->require;
    $module->import();
    
    my ($module_api, $invoker, @filters);
    if ($module->isa('Froody::API')) {
        $invoker = bless {}, 'Froody::Invoker';
        $module_api = $module;
    } elsif ($module->isa("Froody::Implementation")) {
        ($module_api, @filters) = $module->implements;
        $invoker = $module->new;
    } else {
        Carp::confess "fatal error; $module not a Froody::API or Froody::Implementation";
    }

    push @{ $api{$module_api} }, [ $invoker, @filters ];
  }
  
  @filters = _filter_to_rxs(@filters);

  # Register each API _once_, making sure to bind functions  
  foreach my $api (keys %api) {
    $api->require;
    $api->import();
    my @structures = $api->load;
    foreach my $impl (@{$api{$api}}) {
        my ($invoker, @impl_filters) = @$impl;
        $repository->load($invoker, \@structures, @filters, _filter_to_rxs(@impl_filters));
        if ($invoker->isa("Froody::Implementation")) {
          my @plugin_methods = grep { !eval { $repository->get_method($_->full_name)} }
                               @{ $invoker->plugin_methods || [] };
          for (@plugin_methods) {
            # UGH
            $repository->load($_->invoker, [$_], @filters);
          }
        }
    }
  }
  return $self;
}

sub _filter_to_rxs {
   map { Froody::Method->match_to_regex( $_ ) } @_;
}

=item add_implementation 

Adds an implementation's methods to this dispatcher.

=cut

sub add_implementation {
  my ($self, $module, @filters) = @_;
  return if $self->endpoints->{$module}{loaded};
  
  eval " use $module; 1" or die $@;
  my ($api, $invoker);
  my $repository = $self->repository;
  $invoker = $self->endpoints->{$module}{invoker};
  if ($module->isa('Froody::API')) {
    $api = $module;
    $invoker ||= (bless {}, "Froody::Invoker");  
    $self->repository->register_api( $api, $invoker, @filters );
  } elsif ($module->isa("Froody::Implementation")) {
    my @imp_filters;
    $module->register_in_repository($repository, @filters);
  }
  $self->endpoints->{$module} = { invoker => $invoker, loaded => 1 };
}

=item cli_config

Parses arguments with L<parse_cli|/Froody::Dispatch>, and then calls
config with the arguments. This is intended to be used for parsing command
line options, and directly creating configuration details

Returns a dispatch object, and the parsed options.

=cut

sub cli_config {
  my ($self, @args) = @_;
  my $parsed = $self->parse_cli(@args);

  return ($self->config($parsed), $parsed);
}

=item default_repository

DEPRECATED: This is harmful -- you end up with random methods in your namespaces

The first time this method is called it creates a default repository by
trawling through all loaded modues and checking which are subclasses of
Froody::Implementation.

If you're running this in a mod_perl handler you might want to consider
calling this method at compile time to preload all the classes.

See L<config|/Froody::Dispatch>

=cut

sub default_repository
{
  require Carp;
  Carp::confess "Don't expect the default repo to introspect.";
}

=item call_via ($invoker, $method, [@ARGS, $args])

Calls C<$method> with C<$invoker>.  If $invoker or $method are not
instances of C<Froody::Invoker> and C<Froody::Method> respectively then
this method will attempt to discover them in the registered list of endpoints
and the method repository.

Returns a Froody::Response object.

=cut

sub call_via {
  my ($self, $invoker, $method )  = splice @_, 0, 3; #pull off first three args.
  my $args  = ref $_[0] eq 'HASH' ? $_[0] 
                                  : { @_ };

  Carp::confess "You must provide an invoker" unless $invoker;
  
  if (!UNIVERSAL::isa($invoker, 'Froody::Invoker')) {
    $self->endpoints({}) unless $self->endpoints();
    $invoker = $self->endpoints->{$invoker}{invoker}
  }

  $method = $self->get_method($method, $args)
    unless UNIVERSAL::isa($method, 'Froody::Method');
  
  my $meta = {
    dispatcher => $self,
    method => $method,
    params => $args,
    repository => $self->repository,
  };
  return $invoker->invoke($method, $args, $meta);
}

=item add_endpoint( "url" )

Registers all methods from a remote repository within this one.

TODO:  add regex filtering of methods.

=cut

sub add_endpoint {
  my ($self,$url, @method_filters) = @_;
  die "add_endpoint requires an url" unless $url;
  
  my $endpoints = $self->endpoints;
  if ($endpoints->{$url}{loaded}) {
    $logger->warn("Attempted to add endpoint($url) more than once.");
    return $self;
  }
  $self->endpoints->{ $url }{invoker} ||= Froody::Invoker::Remote->new()->url($url);

  $self->load_specification($url, @method_filters);
 
  return $self;
}

=item load_specification ($name, @method_filters) 

Load method and errortype specifications from a named endpoint

=cut

sub load_specification {
  my ($self, $name, @method_filters) = @_;
  
  my $endpoint = $self->endpoints->{$name};
  my $invoker = $endpoint->{invoker};
  
  my $repo = $self->repository;
  my $response = $self->call_via($invoker, 'froody.reflection.getSpecification' );
  if ($response->as_xml->status eq 'ok') {
    my @structures =  Froody::API::XML->load_spec($response->as_xml->xml);
    $repo->load($invoker, \@structures, @method_filters);
    $endpoint->{$endpoint}{loaded} = time;
  } 
}

=back

=head2 Instance Methods

=over

=item get_method( 'full_name', args )

Retrieve a method

=cut

sub get_method {
  my ($self, $name, $args) = @_;
  Froody::Error->throw("froody.invoke.nomethod", "Missing argument: method")
    unless length($name || "");

  # get the method from the repository and just return it
  my $repo = $self->repository;
  my $method = eval { $repo->get_method($name, $args) };
  return $method if $method;

  # We didn't find it?  Maybe it's been declared in our spec that may have
  # changed since we last loaded it.  Let's look for it in here!
  # TODO: Improve this so it DTRT more (though works for now)
  if (err('froody.invoke.nosuchmethod')) {
    local $@ = $@;
    my $get_info = $repo->get_method("froody.reflection.getMethodInfo", $args);
    for (keys %{$self->endpoints || {}}) {
      my $invoker = $self->endpoints->{$_}{invoker};

      my $info = $self->call_via($invoker, $get_info, { %$args, method_name => $name })->as_xml;
      if ($info->status eq 'ok') {
        $method = Froody::API::XML->load_method( $info->xml->findnodes("/rsp/method") );
        $method->invoker($invoker);
        $repo->register_method($method);
      }
      return $method if $method;
    }
  }

  # if we got this far then, darnit, we had an error so we should throw
  # it again
  die $@;
}

=item dispatch( %args )

Causes a dispatch to a froody method to happen.  At a minimum you need to
pass in a method name:

  my $response = Froody::Dispatch->new->dispatch( method => "foo.bar.bob" );

You can also pass in parameters:

  my $response = Froody::Dispatch->new->dispatch( 
    method => "foo.bar.bob",
    param  => { wibble => "wobble" },
  );

Which repository this class uses and how errors are reported depends on
the methods defined below.

=cut

sub dispatch {
  my $self = shift;
  my $args = { @_ };

  # Strip leading and trailing whitespace in all incomming attribute names.
  if (defined $args->{method}) {
    $args->{method} =~ s/^\s+//;
    $args->{method} =~ s/\s+$//;
  }
  for (keys %{ $args->{params} }) {
    next unless /^\s|\s$/; # if there is any leading or trailing whitespace in the key name
    my $val = delete $args->{params}{$_};
    s/^\s+//;
    s/\s+$//;
    $args->{params}{$_} = $val;
  }

  my $response;
  
  my $method = eval { $self->get_method( $args->{method}, $args->{params} ) };
  
  if (my $e = $@) {
    # something here eats $@. Bah.
    $response = $self->error_class->from_exception( $e, $self->repository );

  } else {
  
    Froody::Error->throw("froody.invoke.noinvoker", "No invoker defined for this method")
      unless $method->invoker;
  
    $response = $self->call_via($method->invoker, $method, $args->{params});
  }
  
  # throw an exception if what we got back wasn't an acceptable
  # Froody::Response object
  $self->_validate_response($response);

  return $self->render_response( $response);
}

=item render_response( $response )

=cut

sub render_response {
  my ($self, $response) = @_;
  
  my $style = $self->error_style;
  my $error = $response->isa("Froody::Response::Error") ? $response : undef;
  
  if ($error && $style eq 'throw') {
    $error->throw;
  }

  my $is_an_error;
  if ($response->can('status')) {
    $is_an_error = $response->status ne 'ok';
  } else {
    $response = $response->as_xml; #Response must be representable as XML for now.

    if ($response->status ne 'ok') {
      my $code = $response->xml->findvalue('/rsp/err/@code');
      $is_an_error = 1;
      # we need to fix our structure
      $response->structure($self->repository->get_closest_errortype($code ? $code : '' ));
    }
  }

  if ($style eq "throw" && $is_an_error)
  {
    $response->as_error->throw;
  }
  
  return $response;
}

# throws an error if the reponse isn't valid
sub _validate_response
{
  my $class    = shift;
  my $response = shift;

  # nothing?  Throw an error
  if ( ! $response ) {
    Froody::Error->throw("froody.invoke.badresponse", "No response");
  }

  # if we didn't get the right sort of response, throw an error.
  unless ( ref($response) && blessed($response)
            && $response->isa("Froody::Response")) {
    Froody::Error->throw("froody.invoke.badresponse", "Bad response $response");
  }
}

=item call( 'method', [ args ] )

Call a method (optionally with arguments) and return a
L<Froody::Response::Terse> response, as described in
L<Froody::DataFormats>.  This is a thin wrapper for the
->dispatch() method. 

=cut

sub call {
  my $self = shift;
  my $method = shift;
  my $args = ref $_[0] eq "HASH" ? shift : { @_ };

  $self->_fix_args($method, $args);

  my $rsp = $self->dispatch( method => $method, params => $args );

  return $rsp->as_terse->{content};
}

sub _fix_args {
  my ($self, $method, $args) = @_;
  for (keys %$args) {
    next unless (ref($args->{$_}) and blessed($args->{$_}));
    next if ($args->{$_}->isa("Froody::Upload"));
    if ($args->{$_}->isa("Class::DBI")) {
      # this is our typical DWIM case
      $args->{$_} = $args->{$_}->id;
    } else {
      # you can't do this.
      Froody::Error->throw(
        'froody.invoke.blessedRef',
        "Can't pass object '".ref($args->{$_})."' as the '$_' param to method $method",
      );
    }
  }
}

=item get_methods ( [@filters] )

Provides a list of L<Froody::Method> objects. Optionally, the methods are filtered
by a list of filter patterns.  If L<Froody::Method::config> was called with 
a list of filters, the methods will be pre-filtered by that list. If you wish
to override the configured filters, call this method with C<undef>, or use
the repository methods directly.

=cut

sub get_methods {
  my ($self, @filters) = @_;

  unless (@_ > 1 ) {
    @filters = $self->filters;
  }
  if (!defined $_[0]) {
    @filters = ();
  }
  return $self->repository->get_methods(@filters);
}


=item repository

Get/set the repository that we're calling methods on.  If this is set
to undef (as it is by default) then we will use the default repository
(see above.)

=cut

sub repository
{
  my $self = shift;

  unless (blessed($self))
   { Froody::Error->throw("perl.methodcall.class", "repository cannot be called as a class method") }
  
  unless (@_)
  {
     return $self->{repository} if defined $self->{repository};
     return $self->default_repository;
  }
  
  unless (!defined($_[0]) || blessed($_[0]) && $_[0]->isa("Froody::Repository"))
   { Froody::Error->throw("perl.methodcall.param", "repository must be passed undef or a Froody::Repository instance") }
  
  $self->{repository} = shift;
  return $self;
}

=item error_style

Get/set chained accessor that sets the style of errors that this should use. By
default this is C<response>, which causes all errors to be converted into valid
responses.  The other option is C<throw> which turns all errors into
Froody::Error objects which are then immediatly thrown.

=cut

sub error_style
{
   my $self = shift;
   return $self->{error_style} || "throw" unless @_;
   
   unless ($_[0] && ($_[0] eq "response" || $_[0] eq "throw"))
    { Froody::Error->throw("perl.methodcall.param", "Invalid error style") }
    
   $self->{error_style} = shift;
   return $self;
}

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

=head1 SEE ALSO

L<Froody>, L<Froody::Method>

=cut

1;
