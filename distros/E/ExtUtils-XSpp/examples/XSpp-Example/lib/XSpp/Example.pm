package XSpp::Example;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('XSpp::Example', $VERSION);

1;
__END__

=head1 NAME

XSpp::Example - A simple example of XS++

=head1 DESCRIPTION

This module just serves as a very basic example distribution using C<ExtUtils::XSpp>
to wrap C++ code for use from Perl. See F<Animal.h> and F<Dog.h> for the
C++ implementation and F<Animal.xsp> and F<Dog.xsp> for the declaration of the
interface.

Types are mapped in F<typemap.xsp> (XS++ type map)
and F<mytype.map> as well as F<perlobject.map> (XS type map).

The classes are used in the test files under F<t/>.

=head1 SEE ALSO

L<ExtUtils::XSpp>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The XSpp::Example module is

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
