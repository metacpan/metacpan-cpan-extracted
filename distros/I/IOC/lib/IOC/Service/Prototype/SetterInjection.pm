
package IOC::Service::Prototype::SetterInjection;

use strict;
use warnings;

our $VERSION = '0.01';

use IOC::Exceptions;

use base 'IOC::Service::SetterInjection', 'IOC::Service::Prototype';

# make sure we use the prototype version
*instance = \&IOC::Service::Prototype::instance;

1;

__END__

=head1 NAME

IOC::Service::Prototype::SetterInjection - An IOC Service object which returns a prototype instance

=head1 SYNOPSIS

  use IOC::Service::Prototype::SetterInjection;

=head1 DESCRIPTION

This class essentially can be used just like IOC::Service::SetterInjection, the only difference is that it will return a new instance of the component each time rather than a singleton instance.

                        +--------------+
                        | IOC::Service |
                        +--------------+
                                |
                                ^
                                |
               +----------------+----------------+
               |                                 |
   +-------------------------+  +-------------------------------+
   | IOC::Service::Prototype |  | IOC::Service::SetterInjection |
   +-------------------------+  +-------------------------------+
               |                                 |   
               +----------------+----------------+
                                |
                                ^
                                |
            +------------------------------------------+ 
            | IOC::Service::Prototype::SetterInjection |
            +------------------------------------------+   

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

=item Prototype-style components are supported by the Spring Framework.

L<http://www.springframework.com>

=item Non-Prototype-style Setter Injection in the PicoContainer is explained on this page

L<http://docs.codehaus.org/display/PICO/Setter+Injection>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

