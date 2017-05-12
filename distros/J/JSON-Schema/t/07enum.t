=head1 PURPOSE

Test that enumerations work; in particular enumerations of non-references.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=81867>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2012 Toby Inkster.

This file is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use strict;
use warnings;
use Test::More;

use JSON::Schema;

my $male = JSON::Schema->new(
	{
		type => 'object',
		properties => {
			chromosomes => {
				enum => [
					[qw( X Y )],
					[qw( Y X )],
				],
			}
		},
	},
);

my $female = JSON::Schema->new(
	{
		type => 'object',
		properties => {
			chromosomes => {
				enum => [
					[qw( X X )],
				],
			}
		},
	},
);

ok(
	!$male->validate({ name => "Kate", chromosomes => [qw( X X )] }),
	"it's short for Bob",
);

ok(
	$female->validate({ name => "Kate", chromosomes => [qw( X X )] }),
);

ok(
	$male->validate({ name => "Dave", chromosomes => [qw( X Y )] }),
);

ok(
	$male->validate({ name => "Arnie", chromosomes => [qw( Y X )] }),
);

ok(
	!$male->validate({ name => "Eddie", chromosomes => [qw( X Y Y )] }),
);

ok(
	!$male->validate({ name => "Steve", chromosomes => 'XY' }),
);

done_testing;
