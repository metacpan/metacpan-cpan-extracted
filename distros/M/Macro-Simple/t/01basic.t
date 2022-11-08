=pod

=encoding utf-8

=head1 PURPOSE

Test that Macro::Simple works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Macro::Simple {
	'ISA($;$)' => sub {
		my ( $obj, $class ) = @_;
		$class ||= '__PACKAGE__';
		require Scalar::Util;
		return sprintf(
			'Scalar::Util::blessed(%s) and %s->isa(%s)',
			$obj,
			$obj,
			$class,
		);
	},
	'CAN($$)' => 'Scalar::Util::blessed(%1$s) and %1$s->can(%2$s)',
};

sub wxyz { 1 }

my $obj = bless [];

ok( ISA($obj, 'main') );
ok( CAN($obj, 'wxyz') );

if ( not Macro::Simple::DO_CLEAN ) {
	ok( !main->can('ISA') );
}

diag Macro::Simple::DO_MACRO
	? 'macro: real'
	: 'macro: fallback';

diag Macro::Simple::DO_CLEAN
	? 'clean: yes'
	: 'clean: no';

done_testing;

