=pod

=encoding utf-8

=head1 PURPOSE

Test C<augment> modifier.

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
	package Document;
	use Moose;
	use Kavorka -all;
	
	has recipient => (is => 'ro');
	method as_xml { sprintf "<document>%s</document>", (scalar(inner)//'') }
}

{
	package Greeting;
	use Moose;
	use Kavorka -all;
	
	extends 'Document';
	
	augment as_xml {
		sprintf "<greet>%s</greet>", (scalar(inner)//'')
	}
}

{
	package Greeting::English;
	use Moose;
	use Kavorka -all;
	
	extends 'Greeting';
	
	augment as_xml {
		sprintf "Hello %s", $self->recipient;
	}
}

my $obj1 = Document->new(recipient => "World");
is(
	$obj1->as_xml,
	"<document></document>",
);

my $obj2 = Greeting->new(recipient => "World");
is(
	$obj2->as_xml,
	"<document><greet></greet></document>",
);

my $obj3 = Greeting::English->new(recipient => "World");
is(
	$obj3->as_xml,
	"<document><greet>Hello World</greet></document>",
);

done_testing();
