=pod

=encoding utf-8

=head1 PURPOSE

Test sub redefinition warnings/errors.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

BEGIN {
	eval "use Test::Fatal; use Test::Warnings qw(warning :no_end_test); 1"
		or plan skip_all => "test requires Test::Warnings and Test::Fatal";
	
	plan tests => 4;
};

BEGIN {
	package Local::Exporter;
	use Exporter::Shiny qw(foo bar);
	sub foo { 666 }
	sub bar { 999 }
};

like(
	warning { eval q{
		package Local::Test1;
		sub foo { 42 }
		use Local::Exporter -all;
		1;
	} },
	qr/^Overwriting existing sub 'Local::Test1::foo' with sub 'foo' exported by Local::Exporter/,
	'warning about overwriting sub',
);

like(
	exception { eval q{
		package Local::Test2;
		sub foo { 42 }
		use Local::Exporter { replace => 'die' }, -all;
		1;
	} or die $@ },
	qr/^Refusing to overwrite existing sub 'Local::Test2::foo' with sub 'foo' exported by Local::Exporter/,
	'... which can be fatalized',
);

is_deeply(
	warning { eval q{
		package Local::Test3;
		sub foo { 42 }
		use Local::Exporter { replace => 'die' }, -all;
		1;
	} },
	[],
	'... or suppressed',
);

is_deeply(
	warning { eval q{
		package Local::Test4;
		use Local::Exporter -all;
		use Local::Exporter qw(foo);
		1;
	} },
	[],
	'but importing the exact same sub twice is OK',
);
