package LaunchDarkly::Server;

use v5.18.2;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use LaunchDarkly::Server ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&LaunchDarkly::Server::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
    no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
        *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('LaunchDarkly::Server', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

LaunchDarkly::Server - Perl server side SDK for LaunchDarkly

=head1 SYNOPSIS

  use LaunchDarkly::Server;

  my $config_builder = new LaunchDarkly::Server::ConfigBuilder("my-sdk-key");
  my $config = $config_builder->Build();

  my $client = new LaunchDarkly::Server::Client($config);
  my $status = $client->StartAsync()->WaitFor(10000);
  die "Could not connect" unless $status == LaunchDarkly::Status::Ready();

  my $builder = new LaunchDarkly::ContextBuilder();
  my $kind = $builder->Kind("user", "user123");
  $kind->Set("myattribute", LaunchDarkly::Value::NewString("abc"));
  my $context = $builder->Build();

  my $result = $client->StringVariation($context, "myflag", "default-value");

=head1 DESCRIPTION

A minimum implementation of the LaunchDarkly server side SDK in Perl as a wrapper to the official C++ SDK.
See https://launchdarkly.com/docs/sdk/server-side/c-c--

Make sure your LaunchDarkly library is compiled with the LD_BUILD_EXPORT_ALL_SYMBOLS flag so that the C++ symbols are exported.
Tested with version 3.8.x.

=head2 EXPORT

None by default.

=head2 Exportable constants

None.

=head2 Exportable functions

LaunchDarkly::Server::ConfigBuilder *
LaunchDarkly::Server::ConfigBuilder::new(std::string sdk_key)

LaunchDarkly::Server::Config *
LaunchDarkly::Server::ConfigBuilder::Build()

LaunchDarkly::Server::Client *
LaunchDarkly::Server::Client::new(LaunchDarkly::Server::Config *config)

LaunchDarkly::Future *
LaunchDarkly::Server::Client::StartAsync()

bool
LaunchDarkly::Server::Client::BoolVariation(LaunchDarkly::Context *context, std::string key, bool default_value)

std::string
LaunchDarkly::Server::Client::StringVariation(LaunchDarkly::Context *context, std::string key, std::string default_value)

double
LaunchDarkly::Server::Client::DoubleVariation(LaunchDarkly::Context *context, std::string key, double default_value)

int
LaunchDarkly::Server::Client::IntVariation(LaunchDarkly::Context *context, std::string key, int default_value)

void
LaunchDarkly::Future::Wait()

LaunchDarkly::Status
LaunchDarkly::Future::WaitFor(int milliseconds)

int
LaunchDarkly::Status::Ready()

int
LaunchDarkly::Status::Timeout()

int
LaunchDarkly::Status::Deferred()

LaunchDarkly::ContextBuilder *
LaunchDarkly::ContextBuilder::new()

LaunchDarkly::AttributesBuilder *
LaunchDarkly::ContextBuilder::Kind(std::string kind, std::string key)

LaunchDarkly::Context *
LaunchDarkly::ContextBuilder::Build()

void
LaunchDarkly::AttributesBuilder::Set(std::string name, LaunchDarkly::Value *value)

LaunchDarkly::Value *
LaunchDarkly::Value::NewInt(int num)

LaunchDarkly::Value *
LaunchDarkly::Value::NewDouble(double num)

LaunchDarkly::Value *
LaunchDarkly::Value::NewString(std::string str)

LaunchDarkly::Value *
LaunchDarkly::Value::NewBool(bool b)

=head1 SEE ALSO

=head1 AUTHOR

Miklos Tirpak, E<lt>miklos.tirpak@emnify.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by EMnify

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
