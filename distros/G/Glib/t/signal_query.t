#!/usr/bin/perl -w

#
# Test querying signal information with Glib::Type::list_signals and
# Glib::Object::signal_query (g_signal_query).
#

use strict;
use Glib;
use Test::More tests => 24;

my $quuxed_reg_info = {
	flags => [ 'run-last', 'action' ],
	return_type => 'Glib::Float',
	param_types => [ 'Glib::Int', 'Glib::Boolean' ],
};

Glib::Type->register_object
	('Glib::Object' => 'Foo',
	 signals => {
	 	fooed => {}, # all defaults
		barred => {
			flags => 'run-last',
			return_type => 'Glib::Boolean',
		},
		quuxed => $quuxed_reg_info,
	 });
Glib::Type->register_object
	('Foo' => 'Bar',
	 signals => {
		bazzed => {
			flags => 'run-last',
			return_type => 'Glib::Int',
		},
	});

my @foo_signals = Glib::Type->list_signals ('Foo');
my @bar_signals = Glib::Type->list_signals ('Bar');

is (scalar (@foo_signals), 3);
is (scalar (@bar_signals), 1);

# signal_query and list_signals should give back the same data structures.
# as a special test, we should be able to get all of the signals from Bar,
# as they are inherited from Foo -- list_signals, on the other hand, doesn't
# do inheritance.
foreach my $sig (@foo_signals, @bar_signals) {
	is_deeply (Bar->signal_query ($sig->{signal_name}),
		   $sig, "$sig->{signal_name}");
	# keys that should always exist
	ok (exists $sig->{signal_flags});
	ok ($sig->{itype});
	isa_ok ($sig->{param_types}, 'ARRAY');
}


# let's verify that querying a specific signal gives back the expected values.
my $info = Bar->signal_query ('quuxed');
is ($info->{signal_name}, 'quuxed', 'name');
# we asked Bar for the info, but the signal comes from Foo.
is ($info->{itype}, 'Foo', 'instance type');
# don't use is to test flags -- some Test::Mores disable overloading.
ok ($info->{signal_flags} == $quuxed_reg_info->{flags}, 'signal_flags');
is_deeply ($info->{param_types}, $quuxed_reg_info->{param_types}, 'param_types');
is ($info->{return_type}, $quuxed_reg_info->{return_type}, 'return_type');


# querying a non-existent signal should return undef
is (Bar->signal_query ('non-existent'), undef, 'non-existent signal');
