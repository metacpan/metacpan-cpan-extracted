
package IOC::Interfaces;

use strict;
use warnings;

our $VERSION = '0.02';

use Class::Interfaces (
        'IOC::Visitable' => [ 'accept' ],
        'IOC::Visitor'   => [ 'visit'  ],
        );

1;

__END__

=head1 NAME

IOC::Interfaces - Interfaces for the IOC Framework

=head1 SYNOPSIS

  use IOC::Interfaces;

=head1 DESCRIPTION

This module creates a couple of class interfaces which are used in other parts of the IOC framework.

=head1 INTERFACES

=over 4

=item B<IOC::Visitable>

=item B<IOC::Visitor>

=back

=head1 TO DO

=over 4

=item Work on the documentation

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the CODE COVERAGE section of L<IOC> for more information.

=head1 SEE ALSO

=over 4

=item L<Class::Interfaces>

The interfaces are generated inline by another module I wrote called L<Class::Interfaces>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

