

=encoding utf-8

=head1 NAME

t/integration/autobox.t - initial tests for Hydrogen::Autobox

=head1 PURPOSE

Proof of concept test for currying.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use strict;
use warnings;
use Test2::V0;

use Hydrogen::Autobox;

my $number = 600;

$number->add( 66 );

ok $number->eq( 666 );
ok $number->ne( 667 );

ok $number->curry_eq->execute( 666 );

done_testing;
