=pod

=encoding utf-8

=head1 PURPOSE

Test C<override> modifier.

=head1 DEPENDENCIES

Requires Moose 2.0000.

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
use Test::Requires { 'Moose' => '2.0000' };

{
	package Local::Class;
	use Moose;
	use Kavorka -all;
	
	my $x = 'a';
	method foo { return $x++ }
}

{
	package Local::Subclass;
	use Moose;
	use Kavorka -all;
	
	extends 'Local::Class';
	
	override foo {
		my $letter = super();
		return uc $letter;
	}
}

{
	package Local::More;
	use Moose;
	use Kavorka -all;
	
	extends 'Local::Subclass';
	
	override foo {
		my $letter = super();
		return "X${letter}X";
	}
}

my $obj = Local::More::->new;
is($obj->foo, "XAX");
is($obj->foo, "XBX");
is($obj->foo, "XCX");

done_testing;
