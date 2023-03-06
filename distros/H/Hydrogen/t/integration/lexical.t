=pod

=encoding utf-8

=head1 NAME

t/integration/lexical.t - test lexical exports on Perl 5.37.2+

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2023 by Toby Inkster.

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

BEGIN {
	skip_all 'This test requires Perl 5.37.2+' if $] lt '5.037002';
};

{
	use Hydrogen::Topic::String -lexical, 'append';

	local $_ = 'xxx';
	append( 'foo' );
	append( 'bar' );
	append( 'baz' );
	is $_, 'xxxfoobarbaz', 'append worked!';
	
	ok !__PACKAGE__->can( 'append' ), 'no append function in symbol table';
}

done_testing;
