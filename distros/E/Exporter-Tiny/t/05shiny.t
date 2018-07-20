=pod

=encoding utf-8

=head1 PURPOSE

Very basic Exporter::Shiny test.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More tests => 3;

{
	package Local::Foo;
	use Exporter::Shiny qw(foo bar);
	sub foo {
		return 42;
	}
	sub bar {
		return 666;
	}
}

{
	package Local::Bar;
	use Exporter::Shiny -setup => { exports => [qw(foo bar)] };
	sub foo {
		return 42;
	}
	sub bar {
		return 666;
	}
}

use Local::Foo qw(foo);
use Local::Bar qw(bar);

is(foo(), 42);
is(bar(), 666);

local $@;
eval q{
	package Local::Baz;
	use Exporter::Shiny -setup => { exports => [qw(foo bar)], jazzy => 42 };
};
my $e = $@;

like($e, qr/Unsupported Sub::Exporter-style options/);
