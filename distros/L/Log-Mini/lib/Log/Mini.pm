package Log::Mini;

use strict;
use warnings;
use Module::Load qw/load/;

require Carp;

our $VERSION = "0.5.1";

sub new
{
    shift;
    my ($type, @args) = @_;

    @args = () unless @args;

    $type = 'stderr' unless defined $type;

    if ($type eq 'file') {
        unshift(@args, $type);
    }

    my $module_name = sprintf('Log::Mini::Logger::%s', uc($type));
    my $logger;

    eval {
        load $module_name;

        $logger = $module_name->new(@args);
    } or do { Carp::croak(sprintf("Failed to load adapter: %s, %s\n", $type, $@)) };

    return $logger;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Mini - It's a very simple logger which can log your messages to a file or STDERR.

=head1 SYNOPSIS

    use Log::Mini;

    my $logger = Log::Mini->new(); #STDERR logger used by default. Error is default log level
    $logger->error('Error message');

    my $debug_logger = Log::Mini->new('stderr', level => 'debug'); #STDERR logger used by default
    $debug_logger->error('Error message');

    my $debug_logger = Log::Mini->new('stdout', level => 'debug'); #STDOUT logger, error messages too
    $debug_logger->info('Info message');

    my $file_logger = Log::Mini->new(file => 'log_file.log');
    $file_logger->info('message to log file');

    #prevent buffered output. May slow down your application!
    my $synced_file_logger = Log::Mini->new(file => 'log_file.log', synced => 1);

    #format message with sprintf
    $logger->info('Message with %s %s', 'some', 'additional info');

    #log method for better compatibility
    $logger->log('info', 'information message');

    #Null logger - drops all messages to /dev/null
    my $logger = Log::Mini->new('null);
    $logger->error('Error message'); #Message will be dropped

    #Logging with context
    $logger->push_context('order_id=1234');
    $logger->error('something happened');

    # 2024-08-14 21:53:52.267 [error] order_id=1234: something happenned


=head1 DESCRIPTION

Log::Mini is a very simple logger which can log your messages to a file or STDERR.
You can have a number of loggers for various log files.

=head1 LICENSE

Copyright (C) Denis Fedoseev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Denis Fedoseev <denis.fedoseev@gmail.com>
