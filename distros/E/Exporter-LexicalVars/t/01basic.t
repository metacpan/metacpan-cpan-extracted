=pod

=encoding utf-8

=head1 PURPOSE

Test that Exporter::LexicalVars works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

BEGIN {
	package MyVars;
	use Exporter::LexicalVars -setup => {
		'$pi'   => 3.14159,
		'$foo'  => sub {
			my $ref = shift;
			$$ref = "Hello world";
		},
		'@bar'  => undef,
		'@baz'  => sub {
			my $ref = shift;
			@$ref = @_;
		},
	};
};

use Data::Dumper;

my $pi = 3;

{
	use MyVars;
	is($pi, 3.14159);
	is($foo, 'Hello world');
	is_deeply(\@bar, []);
	is_deeply(\@baz, ['@baz']);
}

is($pi, 3);

{
	use MyVars qw( $foo );
	is($pi, 3);
	is($foo, 'Hello world');
}

done_testing;
