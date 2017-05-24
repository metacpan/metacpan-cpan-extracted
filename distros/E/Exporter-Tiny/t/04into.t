=pod

=encoding utf-8

=head1 PURPOSE

Check the C<< -into >> option works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 2;

use lib qw( examples ../examples );

{
	package Foo;
	use Example::Exporter { into => "Bar" }, qw( fib );
}

{ package Bar; }

ok( not "Foo"->can("fib") );
ok(     "Bar"->can("fib") );
