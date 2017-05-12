=pod

=head1 PURPOSE

Exercise the basic functionality of Die::Hard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use lib "lib";
use lib "t/lib";

use Test::More tests => 10;
use Test::Exception;

use Die::Hard;
use Local::Test;
my $obj     = Local::Test->new;
my $maclane = Die::Hard->new($obj);

isa_ok $maclane => 'Die::Hard';
isa_ok $maclane => 'Local::Test';
ok !$maclane->isa('Terrorist'), "John Maclane ain't no terrorist!";
can_ok $maclane => qw(isa can DOES VERSION new live die);

lives_and {
	is $obj->live("Foo"), "Foo";
} '$obj->live method returns properly';

lives_and {
	is $maclane->live("Foo"), "Foo";
} '$maclane->live method returns properly';

is $maclane->last_error, undef, 'last_error contains no error';

dies_ok {
	$obj->die("Bar");
} '$obj->die method dies';

lives_and {
	is $maclane->die("Bar"), undef;
} '$maclane->die method lives!';

like $maclane->last_error, qr(^Bar), 'last_error contains last error';

