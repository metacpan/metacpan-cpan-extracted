# SYNOPSIS

    # Set up some kind of logger
    use Log::Any::Adapter;
    Log::Any::Adapter->set( 'SomeAdapter' );

    # Make all logged messages uppercase
    use Log::Any::Plugin;
    Log::Any::Plugin->add( 'Format', formatter => sub { map { uc } @_ } );

# DESCRIPTION

Log::Any::Plugin::Format adds an external formatting subroutine to the current
adapter. This subroutine will be injected into all logging methods as an
argument pre-processor. The called logging method will receive the list
returned by the formatter subroutine as its arguments.

# CONFIGURATION

- **formatter**

    Sets the formatting subroutine. The default subroutine is a no-op.

# METHODS

This plugin adds the following method to your adapter:

- **format**

    Sets or gets the current formatting subroutine history. When used as a getter
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
