#!/usr/bin/env perl

use Test::Most tests => 1;

use Modern::Perl;

use Module::Load;
use Intertangle::API::Glib;

subtest "Testing Glib" => sub {
	eval { load 'Inline::C' } or do {
		my $error = $@;
		plan skip_all => "Inline::C not installed" if $error;
	};

	Inline->import( with => qw(Intertangle::API::Glib) );

	subtest 'Typemap for gchar* works' => sub {
		Inline->bind( C => q|
			size_t get_length(gchar* s) {
				return strlen(s);
			}
		|, ENABLE => AUTOWRAP => );

		is( get_length("foo"), 3, 'Converted Perl scalar to gchar*');
	};

};

done_testing;
