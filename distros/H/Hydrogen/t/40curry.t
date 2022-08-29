=pod

=encoding utf-8

=head1 NAME

40curry.t - initial tests for Hydrogen::Curry::*

=head1 PURPOSE

Proof of concept test for currying.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

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

use Hydrogen::Curry::String 'curry_append';

my $string = 'xxx';
my $appender = curry_append( $string );

$appender->( 'foo' );
$appender->( 'bar' );
$appender->( 'baz' );

is $string, 'xxxfoobarbaz', 'curry_append worked!';

done_testing;
