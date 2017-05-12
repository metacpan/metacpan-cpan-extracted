# NAME

Log::Any::Adapter::Handler

# SYNOPSIS

    use Log::Handler;
    use Log::Any::Adapter;

    my $lh = Log::Handler->new(screen => {log_to => 'STDOUT'});
    Log::Any::Adapter->set('Handler', logger => $lh);
    my $log = Log::Any->get_logger();

    $log->warn('aaargh!');

# DESCRIPTION

This is a [Log::Any](https://metacpan.org/pod/Log::Any) adapter for [Log::Handler](https://metacpan.org/pod/Log::Handler). Log::Handler should be
initialized before calling `set`, otherwise your log messages will end up
nowhere. The Log::Handler object is passed via the `logger` parameter.

Log levels are translated 1:1. Log::Handler's special logging methods are not
implemented.

# SEE ALSO

[Log::Any](https://metacpan.org/pod/Log::Any), [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter), [Log::Handler](https://metacpan.org/pod/Log::Handler)

# AUTHOR

Gelu Lupaş <gvl@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2013-2014 the Log::Any::Adapter::Handler ["AUTHOR"](#author) as listed
above.

This is free software, licensed under:

    The MIT License (MIT)
