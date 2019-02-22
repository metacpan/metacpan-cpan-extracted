# NAME

Log::Mini - It's a very simple logger which can log your messages to a file or STDERR.

# SYNOPSIS

    use Log::Mini;

    my $logger = Log::Mini->get_logger(); #STDERR logger used by default. Error is default log level
    $logger->error('Error message');

    my $debug_logger = Log::Mini->get_logger('stderr', level => 'debug'); #STDERR logger used by default
    $debug_logger->error('Error message');

    my $file_logger = Log::Mini->get_logger(file => 'log_file.log');
    $file_logger->info('message to log file');

    #prevent buffered output. May slow down your application!
    my $synced_file_logger = Log::Mini->get_logger(file => 'log_file.log', synced => 1);

# DESCRIPTION

Log::Mini is a very simple logger which can log your messages to a file or STDERR.
You can have a number of loggers for various log files.

# LICENSE

Copyright (C) Denis Fedoseev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Denis Fedoseev <denis.fedoseev@gmail.com>
