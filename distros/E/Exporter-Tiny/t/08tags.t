=pod

=encoding utf-8

=head1 PURPOSE

Test that tag expansion works sanely.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More tests => 17;

BEGIN {
	package Local::Foo;
	use Exporter::Shiny qw(foo bar);
	our @EXPORT = qw(foo);
	our %EXPORT_TAGS = (
		first  => [ 'foo' => { xxx => 41 }, 'bar' ],
		second => [ 'foo', 'bar' ],
		upper  => [
			'foo' => { -as => 'O', -prefix => 'F', -suffix => 'O' },
			'bar' => { -as => 'A', -prefix => 'B', -suffix => 'R' },
		],
	);
	sub _generate_foo {
		my $me = shift;
		my ($name, $args) = @_;
		$args->{xxx} ||= 'foo';
		return sub () { $args->{xxx} };
	}
	sub _generate_bar {
		my $me = shift;
		my ($name, $args) = @_;
		$args->{xxx} ||= 'bar';
		return sub () { $args->{xxx} };
	}
};

use Local::Foo
	-first  => { -prefix => 'first_' },
	-second => { -prefix => 'second_', xxx => 666 },
	-first  => { -prefix => 'third_', xxx => 42 };

is(first_foo, 41);
is(first_bar, 'bar');

is(second_foo, 666);
is(second_bar, 666);

is(third_foo, 42);
is(third_bar, 42);

use Local::Foo -upper => { -prefix => 'MY', xxx => 999 };

is(MYFOO, 999);

{
	package Local::Bar;
	use Local::Foo;
}

ok(  Local::Bar->can('foo')    );
ok( !Local::Bar->can('bar')    );
is(  Local::Bar::foo(), 'foo'  );

{
	package Local::Baz;
	use Local::Foo -default;
}

ok(  Local::Baz->can('foo')    );
ok( !Local::Baz->can('bar')    );
is(  Local::Baz::foo(), 'foo'  );

{
	package Local::Xyzzy;
	use Local::Foo -all;
}

ok(  Local::Xyzzy->can('foo')    );
ok(  Local::Xyzzy->can('bar')    );
is(  Local::Xyzzy::foo(), 'foo'  );
is(  Local::Xyzzy::bar(), 'bar'  );
