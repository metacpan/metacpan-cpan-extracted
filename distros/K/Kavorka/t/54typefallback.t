=pod

=encoding utf-8

=head1 PURPOSE

Unrecognized type constraints are assumed to be class names.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Test::Requires { 'DateTime' => 0 };

{
	package Example;
	use Kavorka;
	fun foo (DateTime $x) { return $x }
}

my $dt = DateTime->now;
is( Example::foo($dt), $dt );

like(
	exception { Example::foo(42) },
	qr{^Value "42" did not pass type constraint \(not isa DateTime\)},
);

done_testing;

