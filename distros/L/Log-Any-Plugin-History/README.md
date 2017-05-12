# SYNOPSIS

    # Set up some kind of logger
    use Log::Any::Adapter;
    Log::Any::Adapter->set( 'SomeAdapter' );

    # Add a log history to the adapter
    use Log::Any::Plugin;
    Log::Any::Plugin->add( 'History', size => 5 );

# DESCRIPTION

Log::Any::Plugin::History adds a history mechanism to your [Log::Adapter](https://metacpan.org/pod/Log::Adapter),
modelled after that of [Mojo::Log](https://metacpan.org/pod/Mojo::Log). The history is an array reference with
the most recent messages that have been logged.

# CONFIGURATION

- **size**

    Sets the maximum number of logged messages to store in the history. This value
    defaults to 10.

    Note that, to more closely mimic the behaviour of [Mojo::Log](https://metacpan.org/pod/Mojo::Log), assigning a
    value lower than the current size of the log history will not immediately
    discard offending values, since the shifting takes place at the time of logging.

- **timestamp**

    The log history stores a timestamp for each logged message. By default, this
    is the return of a call to `time`, but this can be overriden with the
    **timestamp** option.

    This option takes a code reference, the result of which will be saved in the
    history. The subroutine will be called with no arguments, and should return
    something that makes sense as a timestamp for your application.

# METHODS

This plugin adds the following two methods to your adapter:

- **history**
- **history( $arrayref )**

    Sets or gets the current log history. When used as a getter it returns the
    existing value; otherwise it returns the logging object.

- **max\_history\_size**
- **max\_history\_size( $int )**

    Sets or gets the current maximum size of the log history. When used as a getter
    it returns the existing value; otherwise it returns the logging object.

# SEE ALSO

- [Log::Any::Plugin](https://metacpan.org/pod/Log::Any::Plugin)
- [Mojo::Log](https://metacpan.org/pod/Mojo::Log)

# AUTHOR

- José Joaquín Atria ([jjatria@cpan.org](https://metacpan.org/pod/jjatria@cpan.org))

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
