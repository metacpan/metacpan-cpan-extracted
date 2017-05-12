=head1 PURPOSE

Check the zeroth array element can be selected.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=66232>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2011-2013 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use Test::More tests => 6;
BEGIN { use_ok('JSON::Path') };

use JSON;
my $object = {
	'foo' => [
		{
			'bar' => 1,
		},
		{
			'bar' => 2,
		},
		{
			'bar' => 3,
		},
	]
};

my $jpath1 = JSON::Path->new('$.foo[0]');
my @values1 = $jpath1->values(to_json($object));
is(scalar @values1, 1, 'Only returned a single result.');

my $jpath2 = JSON::Path->new('$.foo[0,1]');
my @values2 = $jpath2->values(to_json($object));
is(scalar @values2, 2, 'Returned two results.');

my $jpath3 = JSON::Path->new('$.foo[1:3]');
my @values3 = $jpath3->values(to_json($object));
is(scalar @values3, 2, 'Returned two results.');

my $jpath4 = JSON::Path->new('$.foo[-1:]');
my @values4 = $jpath4->values(to_json($object));
is(scalar @values4, 1, 'Returned one result.');
is($values4[0]->{bar}, 3, 'Correct result.');
