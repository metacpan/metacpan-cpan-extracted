# NAME

Log::LTSV::Instance - LTSV logger

# SYNOPSIS

    use Log::LTSV::Instance;
    my $logger = Log::LTSV::Instance->new(
        logger => sub { print @_ },
        level  => 'DEBUG',
    );
    $logger->crit(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:CRITICAL      msg:hungup

# DESCRIPTION

Log::LTSV::Instance is LTSV logger.

cf. http://ltsv.org/

# METHODS

## new

- logger
- level

## ( error / crit / warn / info / debug )

    $logger->error(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:ERROR      msg:hungup

    $logger->crit(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:CRITICAL      msg:hungup

    $logger->warn(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:WARN      msg:hungup

    $logger->info(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:INFO      msg:hungup

    $logger->debug(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:INFO      msg:hungup

## sticks

    $logger->sticks(
        id   => 1,
        meta => sub {
            my @caller = caller(2);
            {
                file => $caller[1],
                line => $caller[2],
            }
        },
    );
    $logger->crit(msg => 'hungup');
    # time:2015-03-06T22:27:40      log_level:CRITICAL    id:1      meta.file:t/print.t     meta.line:115       msg:hungup
    $logger->info(msg => 'hungup');
    # time:2015-03-06T22:27:40      log_level:INFO    id:1      meta.file:t/print.t     meta.line:115       msg:hungup

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi &lt;git@hixi-hyi.com>
