package Log::Mini;

use strict;
use warnings;

our $VERSION = "0.1.0";

use Log::Mini::LoggerFILE;
use Log::Mini::LoggerSTDERR;

sub new {
    my $class = shift;
    my ( $type, @args ) = @_;

    $type = 'stderr' unless defined $type;

    if ( $type eq 'file' ) {
        return Log::Mini::LoggerFILE->new(@args);
    }
    else {
        return Log::Mini::LoggerSTDERR->new(@args);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Mini - It's a very simple logger which can log your messages to a file or STDERR.

=head1 SYNOPSIS

    use Log::Mini;

    my $logger = Log::Mini->get_logger(); #STDERR logger used by default. Error is default log level
    $logger->error('Error message');

    my $debug_logger = Log::Mini->get_logger('stderr', level => 'debug'); #STDERR logger used by default
    $debug_logger->error('Error message');

    my $file_logger = Log::Mini->get_logger(file => 'log_file.log');
    $file_logger->info('message to log file');

    #prevent buffered output. May slow down your application!
    my $synced_file_logger = Log::Mini->get_logger(file => 'log_file.log', synced => 1);

    #format message with sprintf
    $logger->info('Message with %s %s', 'some', 'additional info');

    #log method for better compatibility
    $logger->log('info', 'information message');


=head1 DESCRIPTION

Log::Mini is a very simple logger which can log your messages to a file or STDERR.
You can have a number of loggers for various log files.

=head1 LICENSE

Copyright (C) Denis Fedoseev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Denis Fedoseev <denis.fedoseev@gmail.com>
