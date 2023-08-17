package Fluent::LibFluentBit;
our $VERSION = '0.03'; # VERSION
use strict;
use warnings;
use Carp;
use Scalar::Util;
use Exporter;

# ABSTRACT: Perl interface to libfluent-bit.so


require XSLoader;
XSLoader::load('Fluent::LibFluentBit', $Fluent::LibFluentBit::VERSION);

our @EXPORT_OK= qw(
  flb_create flb_service_set flb_input flb_input_set flb_filter flb_filter_set
  flb_output flb_output_set flb_start flb_stop flb_destroy
  flb_lib_push flb_lib_config_file
  FLB_LIB_ERROR FLB_LIB_NONE FLB_LIB_OK FLB_LIB_NO_CONFIG_MAP
);

sub import {
   # handle the -config option.
   for (my $i= 1; $i < @_; $i++) {
      if ($_[$i] eq '-config') {
         ref $_[$i+1] eq 'HASH'
            or croak "-config must be followed by a hashref";
         __PACKAGE__->default_instance->configure($_[$i+1]);
         splice(@_, $i, 2);
         --$i;
      }
   }
   goto \&Exporter::import;
}

our ( %instances, $default_instance );
sub default_instance {
   $default_instance //= Fluent::LibFluentBit->new();
}
# Before program exit, try to cleanly flush all messages
sub END {
   defined $_ && $_->{started} && $_->stop
      for values %instances;
   %instances= ();
}

# constructor registers the instance
sub new {
   my $class= shift;
   my $self= Fluent::LibFluentBit::flb_create();
   bless $self, $class if $class ne 'Fluent::LibFluentBit';
   Scalar::Util::weaken( $instances{0+$self}= $self );
   $self->configure((@_ == 1 && ref $_[0] eq 'HASH')? %{$_[0]} : @_);
}

# destructor flushes cached messages and unregisters the instance
sub DESTROY {
   my $self= shift;
   delete $instances{0+$self};
   $self->stop;
   # XS calls flb_destroy when the hash goes out of scope
}

sub _ctx {
   ref $_[0]? $_[0] : $_[0]->default_instance
}


sub inputs { _ctx(shift)->{inputs} }
sub filters { _ctx(shift)->{filters} }
sub outputs { _ctx(shift)->{outputs} }
sub started { !!_ctx(shift)->{started} }


sub configure {
   my $self= _ctx(shift);
   my %conf= @_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_;

   my $inputs= delete $conf{inputs};
   my $filters= delete $conf{filters};
   my $outputs= delete $conf{outputs};
   for (keys %conf) {
      if ($self->flb_service_set($_, $conf{$_}) >= 0) {
         $self->{$_}= $conf{$_};
      } else {
         carp "Invalid fluent-bit context attribute '$_' = '$conf{$_}'";
      }
   }
   if ($inputs) {
      $self->add_input($_) for @$inputs;
   }
   if ($outputs) {
      $self->add_output($_) for @$outputs;
   }
   if ($filters) {
      $self->add_filter($_) for @$filters;
   }
   return $self;
}


sub _collect_subobject_config {
   my %cfg;
   $cfg{name}= shift if @_ && !ref $_[0];
   my @attrs= (ref $_[0] eq 'HASH')? %{$_[0]} : @_;
   for (my $i= 0; $i < @attrs; $i+= 2) {
      # Make all keys lowercase
      $cfg{lc $attrs[$i]}= $attrs[$i+1];
   }
   # name must be defined
   defined $cfg{name} or croak "Missing ->{name} in object config";
   \%cfg;
}

sub add_input {
   my $self= _ctx(shift);
   my $config= &_collect_subobject_config;
   $config->{context}= $self;
   my $obj= Fluent::LibFluentBit::Input->new($config);
   push @{ $self->{inputs} }, $obj;
   $self->{lib_input} //= $obj if $obj->name eq 'lib';
   $obj;
}

sub add_filter {
   my $self= _ctx(shift);
   my $config= &_collect_subobject_config;
   $config->{context}= $self;
   my $obj= Fluent::LibFluentBit::Filter->new($config);
   push @{ $self->{filters} }, $obj;
   $obj;
}

sub add_output {
   my $self= _ctx(shift);
   my $config= &_collect_subobject_config;
   $config->{context}= $self;
   my $obj= Fluent::LibFluentBit::Output->new($config);
   push @{ $self->{outputs} }, $obj;
   $obj;
}


sub start {
   my $self= _ctx(shift);
   unless ($self->{started}) {
      my $ret= $self->flb_start;
      $ret >= 0 or croak "flb_start failed: $ret";
      $self->{started}= 1;
   }
}

sub stop {
   my $self= _ctx(shift);
   if ($self->{started}) {
      my $ret= $self->flb_stop;
      $ret >= 0 or croak "flb_stop failed: $ret";
      $self->{started}= 0;
   }
}


sub new_logger {
   my $self= _ctx(shift);
   if (!defined $self->{lib_input}) {
      croak "Can't create 'lib' input after engine is started" if $self->started;
      $self->{lib_input}= $self->add_input('lib');
   }
   require Fluent::LibFluentBit::Logger;
   Fluent::LibFluentBit::Logger->new(
      context => $self,
      input_id => $self->{lib_input}->id,
      (@_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_)
   );
}

require Fluent::LibFluentBit::Input;
require Fluent::LibFluentBit::Filter;
require Fluent::LibFluentBit::Output;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Fluent::LibFluentBit - Perl interface to libfluent-bit.so

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Fluent::LibFluentBit -config => {
    log_level => 'trace',
    outputs => [{
      name => 'datadog',
      match => '*',
      host => "http-intake.logs.datadoghq.com",
      tls => 'on',
      compress => 'gzip',
      apikey => $ENV{DATADOG_API_KEY},
      dd_service => 'example',
      dd_source => 'perl-fluentbit',
    }]
  );
  my $logger= Fluent::LibFluentBit->new_logger;
  $logger->info("Message");
  $logger->error({ log => "Message", key1 => "value1", key2 => "value2" });

=head1 DESCRIPTION

Fluent is a software tool that collects log data from a wide variety of sources and delivers
them to a wide variety of destinations (with 1000+ plugins that cover just about any conceivable
source or destination) and buffers them in a server "fluentd" to act as a central point of
configuration and to smooth over any network interruptions.

Fluent-Bit is a smaller single-process implementation of the same idea.  It is written in C,
for performance and low overhead, and available as both a standalone program and a C library.
It supports fewer plugins (but still an impressive 100+) but does not need an intermediate
server for the buffering.  When used as a C library, the main application gets to write log
data un-blocked while a background thread in libfluent-bit does the work of writing to remote
destinations.

To integrate fluent-bit with a Perl application, you have several options, including:

=over

=item *

Write to log files, then run fluent-bit as a log processor that watches for new lines in the
files.

=item *

Pipe the perl process output into stdin of fluent-bit, as either JSON or parsed plaintext.

=item *

Use this module to feed data directly into fluent-bit within the same process (but separate
thread)

=back

There are a time and a place for each of these options.  The main use case for this module
(as I see it) is when it would be inconvenient to direct the output of the process into
a pipe, and where you trust the perl script to do its logging via an API and not accidentally
via stdout (which wouldn't be seen by libfluent-bit).

=head1 CONSTRUCTOR

=head2 default_instance

You probably only want one instance of fluent-bit running per program, so all the methods of
this package can be called as class methods and they will operate on this default instance.
The instance gets created the first time you call C<default_instance> or if you pass C<-config>
to the 'use' line.

=head2 new

This creates a non-default instance of the library.  You probably don't need this; see
L</default_instance> above.

Arguments to new get passed to L</configure>.

=head1 ATTRIBUTES

All attributes are read-only and should be modified using L</configure>

=over

=item inputs

Arrayref of L<Fluent::LibFluentBit::Input>.

=item outputs

Arrayref of L<Fluent::LibFluentBit::Output>.

=item filters

Arrayref of L<Fluent::LibFluentBit::Filter>.

=item started

Boolean, whether the background thread is running.

=back

=head1 METHODS

All methods may be called on the class, in which case they will use L</default_instance>.

=head2 configure

  $flb->configure( $key => $value, ... );

This accepts any attribute (case-insensitive) that you could write in the [SERVICE] section
of the fluent-bit config file.  Invalid attributes generate warnings instead of exceptions.

You may also pass a list of C<< inputs => [...] >>, C<< outputs => [...] >>, and
C<< filters => [...] >> which will generate calls to L</add_input>, L</add_output>, and
L</add_filter> respectively.

=head2 add_input

  $inp= $flb->add_input($type => \%config);
  $inp= $flb->add_input({ name => $type, %config... });

Create and configure a new input.  You probably don't need this if you are only using the
loggers from this library as input.  C<%config> Attributes are not case-sensitive, and are
the same keys and values you would write in the [INPUT] sections of the config file.

Returns an instance of L<Fluent::LibFluentBit::Input> which is also added to the L</inputs>
attribute.

=head2 add_filter

Same as add_input, for filters.

=head2 add_output

Same as add_input, for outputs.

=head2 start

Start the fluent-bit engine.  This should probably only occur after all configurations of
inputs and filters and outputs.

This is a no-op if the engine is already started.  It can die if flb_start returns an error.

=head2 stop

Stop the fluent-bit engine, if it is started.  This relies on the L</started> attribute and
does not consult the library.  (maybe that's a bug?)

=head2 new_logger

Return a new instance of L<Fluent::LibFluentBit::Logger> which feeds messages to the 'lib'
input of the library.  Currently these all use the same input handle, creted the first time
the logger gets used, and which triggers a call to L</start>.

=head1 EXPORTS

The following can be exported into your namespace for a more C-like experience:

=head2 libfluent-bit API

=over

=item flb_create

=item flb_service_set

=item flb_input

=item flb_input_set

=item flb_filter

=item flb_filter_set

=item flb_output

=item flb_output_set

=item flb_start

=item flb_stop

=item flb_destroy

=item flb_lib_push

=item flb_lib_config_file

=back

=head2 Constants

=over

=item FLB_LIB_ERROR

=item FLB_LIB_NONE

=item FLB_LIB_OK

=item FLB_LIB_NO_CONFIG_MAP

=back

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
