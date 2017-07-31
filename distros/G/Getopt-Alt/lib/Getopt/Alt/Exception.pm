package Getopt::Alt::Exception;

# Created on: 2013-01-10 09:35:30
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use version;
use overload '""' => sub { shift->message };

extends 'Throwable::Error';

our $VERSION = version->new('0.4.4');

has help => (
    is  => 'rw',
    isa => 'Bool',
);
has option => (
    is  => 'rw',
    isa => 'Str',
);
has type => (
    is  => 'rw',
    isa => 'Str',
);

1;

__END__

=head1 NAME

Getopt::Alt::Exception - I have forgotten where I was going with this

=head1 VERSION

This documentation refers to Getopt::Alt::Exception version 0.4.4.


=head1 SYNOPSIS

   use Getopt::Alt::Exception;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (Ivan.Wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (Ivan.Wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Height, NSW 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
