package Log::Contextual::Role::Router;
use strict;
use warnings;

our $VERSION = '0.009001';

use Moo::Role;

requires 'before_import';
requires 'after_import';
requires 'handle_log_request';

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt

=head1 NAME

Log::Contextual::Role::Router - Abstract interface between loggers and logging code blocks

=head1 VERSION

version 0.009001

=head1 SYNOPSIS

  package MyApp::Log::Router;

  use Moo;
  use Log::Contextual::SimpleLogger;

  with 'Log::Contextual::Role::Router';

  has logger => (is => 'lazy');

  sub _build_logger {
    return Log::Contextual::SimpleLogger->new({ levels_upto => 'debug' });
  }

  sub before_import {
    my ($self, %export_info) = @_;
    my $exporter = $export_info{exporter};
    my $target = $export_info{target};
    print STDERR "Package '$target' will import from '$exporter'\n";
  }

  sub after_import {
    my ($self, %export_info) = @_;
    my $exporter = $export_info{exporter};
    my $target = $export_info{target};
    print STDERR "Package '$target' has imported from '$exporter'\n";
  }

  sub handle_log_request {
    my ($self, %message_info) = @_;
    my $log_code_block = $message_info{message_sub};
    my $args = $message_info{message_args};
    my $log_level_name = $message_info{message_level};
    my $logger = $self->logger;
    my $is_active = $logger->can("is_${log_level_name}");

    return unless defined $is_active && $logger->$is_active;
    my $log_message = $log_code_block->(@$args);
    $logger->$log_level_name($log_message);
  }

  package MyApp::Log::Contextual;

  use Moo;
  use MyApp::Log::Router;

  extends 'Log::Contextual';

  #This example router is a singleton
  sub router {
    our $Router ||= MyApp::Log::Router->new
  }

  package main;

  use strict;
  use warnings;
  use MyApp::Log::Contextual qw(:log);

  log_info { "Hello there" };

=head1 DESCRIPTION

Log::Contextual has three parts

=over 4

=item Export manager and logging method generator

These tasks are handled by the C<Log::Contextual> package.

=item Logger selection and invocation

The logging functions generated and exported by Log::Contextual call a method
on an instance of a log router object which is responsible for invoking any loggers
that should get an opportunity to receive the log message. The C<Log::Contextual::Router>
class implements the set_logger() and with_logger() functions as well as uses the
arg_ prefixed functions to configure itself and provide the standard C<Log::Contextual>
logger selection API.

=item Log message formatting and output

The logger objects themselves accept or reject a log message at a certain log
level with a guard method per level. If the logger is going to accept the
log message the router is then responsible for executing the log message code
block and passing the generated message to the logging object's log method.

=back

=head1 METHODS

=over 4

=item before_import($self, %import_info)

=item after_import($self,  %import_info)

These two required methods are called with identical arguments at two different places
during the import process. The before_import() method is invoked prior to the logging
subroutines being exported into the target package and after_import() is called when the
export is completed but before control returns to the package that imported the API.

The arguments are passed as a hash with the following keys:

=over 4

=item exporter

This is the name of the package that has been imported. It can also be 'Log::Contextual' itself. In
the case of the synopsis the value for exporter would be 'MyApp::Log::Contextual'.

=item target

This is the package name that is importing the logging API. In the case of the synopsis the
value would be 'main'.

=item arguments

This is a hash reference containing the configuration values that were provided for the import.
The key is the name of the configuration item that was specified without the leading hyphen ('-').
For instance if the logging API is imported as follows

  use Log::Contextual qw( :log ), -logger => Custom::Logger->new({ levels => [qw( debug )] });

then $import_info{arguments}->{logger} would contain that instance of Custom::Logger.

=back

=item handle_log_request($self, %message_info)

This method is called by C<Log::Contextual> when a log event happens. The arguments are passed
as a hash with the following keys

=over 4

=item exporter

This is the name of the package that created the logging methods used to generate the log event.

=item caller_package

This is the name of the package that the log event has happened inside of.

=item caller_level

This is an integer that contains the value to pass to caller() that will provide
information about the location the log event was created at.

=item log_level

This is the name of the log level associated with the log event.

=item message_sub

This is the message generating code block associated with the log event passed as a code reference. If
the logger accepts the log request the router should execute the code reference to create
the log message and then pass the message as a string to the logger.

=item message_args

This is an array reference that contains the arguments given to the message generating code block.
When invoking the message generator it will almost certainly be expecting these argument values
as well.

=back

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Log-Contextual/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
