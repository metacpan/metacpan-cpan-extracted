# NAME

Log::Mini - It's a very simple logger which can log your messages to a file or STDERR.

# SYNOPSIS

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

# DESCRIPTION

Log::Mini is a very simple logger which can log your messages to a file or STDERR.
You can have a number of loggers for various log files.

# LICENSE

Copyright (C) Denis Fedoseev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Denis Fedoseev <denis.fedoseev@gmail.com>
