# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Module;

use strict;
use warnings;

=head1 NAME

Filesys::POSIX::Module - Export methods to Filesys::POSIX namespace

=head1 SYNOPSIS

    package Foo;

    use Filesys::POSIX::Module;

    my @METHODS = qw(foo bar baz);

    Filesys::POSIX::Module->export_methods(__PACKAGE__, @methods);

=head1 DESCRIPTION

C<Filesys::POSIX::Module> is used to extend C<L<Filesys::POSIX>> by allowing
callers to export methods from their own packages into C<L<Filesys::POSIX>>.

=cut

sub export_methods {
    my ( $class, $from, @methods ) = @_;

    no strict 'refs';

    foreach my $method (@methods) {
        *{"Filesys::POSIX::$method"} = *{"$from\::$method"};
    }

    return;
}

1;

__END__

=head1 AUTHOR

Written by Xan Tronix <xan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
