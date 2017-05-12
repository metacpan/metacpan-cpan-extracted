package Eidolon::Driver;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver.pm - generic driver
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-12 05:58:42

1;

__END__

=head1 NAME

Eidolon::Driver - Eidolon generic driver.

=head1 SYNOPSIS

Example driver:

    package ExampleDriver;
    use base qw/Eidolon::Driver/;

    # ...

Somewhere in application:

    my ($r, $example);

    $r = Eidolon::Core::Registry->get_instance;
    $example = $r->loader->get_object("ExampleDriver");
    $example->wow("It works!");

=head1 DESCRIPTION

The I<Eidolon::Driver> is a base driver for all I<Eidolon> drivers. 

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Core::Loader>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
