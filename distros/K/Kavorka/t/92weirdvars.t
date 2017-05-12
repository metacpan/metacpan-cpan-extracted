=pod

=encoding utf-8

=head1 PURPOSE

Check weird variables like localized globals.

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

use Kavorka;

fun foo (our $x, ${^MYVAR}, $Mellow::Yellow)
{
	bar();
}

sub bar ()
{
	our $x;
	is($x, 42);
	is(${^MYVAR}, 666);
	is($Mellow::Yellow, 999);
}

sub baz ()
{
	our $x;
	is($x, undef);
	is(${^MYVAR}, undef);
	is($Mellow::Yellow, undef);
}

#diag(Kavorka->info(\&foo)->signature->injection);

foo(42, 666, 999);
baz();

done_testing;

