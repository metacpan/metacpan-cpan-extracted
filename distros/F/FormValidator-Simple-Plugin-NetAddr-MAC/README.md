# NAME

FormValidator::Simple::Plugin::NetAddr::MAC - MAC Address validation

# SYNOPSIS

    use FormValidator::Simple qw(NetAddr::MAC);

    my $result = FormValidator::Simple->check( $req => [
        mac => [ 'NOT_BLANK', 'NETADDR_MAC' ],
    ] );

# DESCRIPTION

This module adds MAC Address validation commands to FormValidator::Simple.

# VALIDATION COMMANDS

- NETADDR\_MAC

    Checks for a single MAC address format.

- NETADDR\_MAC\_LOCAL

    Checks for a single MAC address format and locally administered.

- NETADDR\_MAC\_UNIVERSAL

    Checks for a single MAC address format and universally administered.

# DEPENDENCY

[NetAddr::MAC](http://search.cpan.org/perldoc?NetAddr::MAC)

# SEE ALSO

[FormValidator::Simple](http://search.cpan.org/perldoc?FormValidator::Simple)

# REPOSITORY

https://github.com/ryochin/p5-formvalidator-simple-plugin-netaddr-mac

# AUTHOR

Ryo Okamoto <ryo@aquahill.net>

# LICENSE

Copyright (C) Ryo Okamoto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
