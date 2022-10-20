
=pod

=encoding utf-8

=head1 PURPOSE

Test the keywords exported by L<LINQ::DSL>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;

use LINQ::DSL ':default_safe';

my @people = (
	{ name => "Alice", dept => 8 },
	{ name => "Bob",   dept => 7, this_will => 'be ignored' },
	{ name => "Carol", dept => 7 },
	{ name => "Dave",  dept => 8 },
	{ name => "Eve",   dept => 1 },
);

my @depts = (
	{ dept_name => 'Accounts',  id => 1 },
	{ dept_name => 'IT',        id => 7 },
	{ dept_name => 'Marketing', id => 8 },
);

my @collection = Linq {
	From \@people;
	SelectX 'name', 'dept';
	LeftJoin \@depts, field('dept'), field('id'), HashSmush;
	OrderBy -string, field('name');
	Cast AutoObject;
	ToList;
};

is( scalar(@collection), 5 );

is $collection[1]->name, 'Bob';
is $collection[1]->dept_name, 'IT';

done_testing;
