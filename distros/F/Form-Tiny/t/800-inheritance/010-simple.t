use v5.10;
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use ParentForm;
use ChildForm;

my @wanted_roles = (
	qw(
		Form::Tiny::Meta::Strict
		Form::Tiny::Meta::Filtered
	)
);

subtest 'test intermediate class' => sub {
	my $meta = ParentForm->form_meta;

	is_deeply $meta->meta_roles, \@wanted_roles, 'meta roles ok';
	ok $meta->DOES($_), "meta role $_ really mixed in" for @wanted_roles;

	is scalar @{$meta->fields}, 2, 'fields count ok';
	is scalar keys %{$meta->hooks}, 3, 'hooks categories count ok';
	is scalar @{$meta->hooks->{cleanup}}, 2, 'cleanup hooks count ok';
	is scalar @{$meta->hooks->{before_mangle}}, 1, 'before_mangle hooks categories count ok';
	is scalar @{$meta->hooks->{before_validate}}, 1, 'before_validate hooks categories count ok';
	is scalar @{$meta->filters}, 2, 'filters count ok';
};

subtest 'test child class' => sub {
	my $meta = ChildForm->form_meta;

	is_deeply $meta->meta_roles, \@wanted_roles, 'meta roles ok';
	ok $meta->DOES($_), "meta role $_ really mixed in" for @wanted_roles;

	is scalar @{$meta->fields}, 3, 'fields count ok';
	is scalar keys %{$meta->hooks}, 3, 'hooks categories count ok';
	is scalar @{$meta->hooks->{cleanup}}, 2, 'cleanup hooks count ok';
	is scalar @{$meta->hooks->{before_mangle}}, 1, 'before_mangle hooks categories count ok';
	is scalar @{$meta->hooks->{before_validate}}, 1, 'before_validate hooks categories count ok';
	is scalar @{$meta->filters}, 2, 'filters count ok';
};

done_testing;
