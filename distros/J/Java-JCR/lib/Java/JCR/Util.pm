package Java::JCR::Util;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw( Java::JCR );

=head1 NAME

Java::JCR::Util - Loads the utilities libraries included with the JCR

=head1 SYNOPSIS

  use Java::JCR::Util;

=head1 DESCRIPTION

Loads the Perl wrappers associated with the C<javax.jcr.util> package.

=cut

Java::JCR::import_my_packages();

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
